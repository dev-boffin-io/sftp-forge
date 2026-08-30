import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/xterm.dart';

import '../models/ssh_profile.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

/// Strips common ANSI CSI escape sequences (cursor movement, color codes)
/// so the "Copy output" action produces clean, pasteable plain text.
final _ansiEscape = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

class _ExtraKey {
  final String label;
  final String bytes;
  const _ExtraKey(this.label, this.bytes);
}

class TerminalScreen extends StatefulWidget {
  final SSHProfile profile;
  final String? password;

  const TerminalScreen({super.key, required this.profile, this.password});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final terminal = Terminal(maxLines: 10000);
  final terminalController = TerminalController();

  // Plain-text transcript of everything written to the terminal, kept in
  // parallel to the rendered buffer, purely so "Copy output" has something
  // reliable to hand to the clipboard without depending on the renderer's
  // internal selection state.
  final StringBuffer _plainLog = StringBuffer();

  SSHClient? _client;
  SSHSession? _session;
  String _status = 'Connecting…';

  bool _ctrlActive = false;
  bool _disposed = false;
  bool _reconnectScheduled = false;
  int _reconnectAttempt = 0;

  // A stable per-profile tmux session name, so reconnecting re-attaches to
  // the same running shell (scrollback, running programs) instead of
  // starting a fresh one. Falls back to a plain login shell automatically
  // if tmux isn't installed on the remote host.
  late final String _tmuxSession =
      'sftpforge_${widget.profile.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';

  static const _fixedKeys = [
    _ExtraKey('Esc', '\x1b'),
    _ExtraKey('Tab', '\t'),
    _ExtraKey('^C', '\x03'),
    _ExtraKey('^D', '\x04'),
    _ExtraKey('^Z', '\x1a'),
    _ExtraKey('^L', '\x0c'),
    _ExtraKey('↑', '\x1b[A'),
    _ExtraKey('↓', '\x1b[B'),
    _ExtraKey('←', '\x1b[D'),
    _ExtraKey('→', '\x1b[C'),
    _ExtraKey('Home', '\x1b[H'),
    _ExtraKey('End', '\x1b[F'),
    _ExtraKey('PgUp', '\x1b[5~'),
    _ExtraKey('PgDn', '\x1b[6~'),
    _ExtraKey('/', '/'),
    _ExtraKey('-', '-'),
    _ExtraKey('|', '|'),
    _ExtraKey('~', '~'),
  ];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    _client?.close();
    _session = null;

    try {
      final client = await SSHService.connect(widget.profile, password: widget.password);
      // Try to attach to (or create) a tmux session so the shell survives
      // a dropped connection; fall back to a plain login shell if tmux
      // isn't available on the remote host.
      final session = await client.execute(
        "tmux new -A -s $_tmuxSession 2>/dev/null || exec \$SHELL -l",
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      void handleOutput(String data) {
        terminal.write(data);
        _plainLog.write(data.replaceAll(_ansiEscape, ''));
      }

      session.stdout.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(
            handleOutput,
            onDone: _handleDisconnect,
          );
      session.stderr.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(handleOutput);

      terminal.onOutput = (data) => _handleTerminalOutput(session, data);
      terminal.onResize = (w, h, pw, ph) => session.resizeTerminal(w, h, pw, ph);

      if (_disposed) {
        session.close();
        client.close();
        return;
      }

      setState(() {
        _client = client;
        _session = session;
        _status = 'Connected to ${widget.profile.target}';
        _reconnectAttempt = 0;
      });
    } catch (e) {
      if (_disposed) return;
      setState(() => _status = 'Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleTerminalOutput(SSHSession session, String data) {
    if (_ctrlActive && data.isNotEmpty) {
      session.write(Uint8List.fromList([_ctrlByte(data.codeUnitAt(0))]));
      setState(() => _ctrlActive = false);
      return;
    }
    session.write(utf8.encode(data));
  }

  /// Maps a letter to its Ctrl-modified control byte (Ctrl+A -> 0x01, etc).
  /// Falls back to the character's own code unit for anything outside
  /// A-Z/a-z so an unexpected key with Ctrl held still sends *something*
  /// rather than being silently dropped.
  int _ctrlByte(int codeUnit) {
    final upper = (codeUnit >= 0x61 && codeUnit <= 0x7a) ? codeUnit - 32 : codeUnit;
    if (upper >= 0x40 && upper <= 0x5f) return upper - 0x40;
    return codeUnit & 0xff;
  }

  void _handleDisconnect() {
    if (_disposed) return;
    setState(() {
      _session = null;
      _status = 'Connection lost — reconnecting…';
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectScheduled) return;
    _reconnectScheduled = true;
    _reconnectAttempt++;
    final delay = Duration(seconds: _reconnectAttempt.clamp(1, 10));
    Future.delayed(delay, () {
      _reconnectScheduled = false;
      if (_disposed) return;
      _connect();
    });
  }

  void _sendKey(String bytes) {
    _session?.write(utf8.encode(bytes));
  }

  void _toggleCtrl() {
    setState(() => _ctrlActive = !_ctrlActive);
  }

  Future<void> _copy() async {
    final selection = terminalController.selection;
    final String text;
    final bool wasSelection;
    if (selection != null) {
      text = terminal.buffer.getText(selection);
      terminalController.clearSelection();
      wasSelection = true;
    } else {
      // Nothing selected — fall back to the full session transcript.
      text = _plainLog.toString();
      wasSelection = false;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(wasSelection ? 'Selection copied' : 'Session output copied')),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    terminal.paste(text);
  }

  @override
  void dispose() {
    _disposed = true;
    _session?.close();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          IconButton(
            onPressed: _copy,
            icon: const Icon(Icons.copy),
            tooltip: 'Copy session output',
          ),
          IconButton(
            onPressed: _paste,
            icon: const Icon(Icons.content_paste),
            tooltip: 'Paste from clipboard',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.sidebar,
            child: Text(_status, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: TerminalView(
              terminal,
              controller: terminalController,
              autofocus: true,
              backgroundOpacity: 1,
            ),
          ),
          // Termux-style row of extra keys the on-screen keyboard doesn't have.
          Container(
            color: AppColors.sidebar,
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              itemCount: _fixedKeys.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, i) {
                if (i == 0) {
                  // A real, general-purpose Ctrl modifier: tap to arm it,
                  // then the next key typed on the on-screen keyboard is
                  // sent as its Ctrl-modified byte instead of itself.
                  return OutlinedButton(
                    onPressed: _toggleCtrl,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _ctrlActive ? AppColors.accentStrong : AppColors.border,
                      foregroundColor: _ctrlActive ? Colors.white : AppColors.textSecondary,
                      side: BorderSide(color: _ctrlActive ? AppColors.accent : AppColors.borderStrong),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Ctrl', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }
                final key = _fixedKeys[i - 1];
                return OutlinedButton(
                  onPressed: () => _sendKey(key.bytes),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.border,
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderStrong),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(key.label, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
