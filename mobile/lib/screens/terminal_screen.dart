import 'dart:convert';

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

  static const _extraKeys = [
    _ExtraKey('Esc', '\x1b'),
    _ExtraKey('Tab', '\t'),
    _ExtraKey('^C', '\x03'),
    _ExtraKey('^D', '\x04'),
    _ExtraKey('^Z', '\x1a'),
    _ExtraKey('^L', '\x0c'),
    _ExtraKey('^A', '\x01'),
    _ExtraKey('^E', '\x05'),
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
    try {
      final client = await SSHService.connect(widget.profile, password: widget.password);
      final session = await client.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      void handleOutput(String data) {
        terminal.write(data);
        _plainLog.write(data.replaceAll(_ansiEscape, ''));
      }

      session.stdout.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(handleOutput);
      session.stderr.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(handleOutput);

      terminal.onOutput = (data) => session.write(utf8.encode(data));
      terminal.onResize = (w, h, pw, ph) => session.resizeTerminal(w, h, pw, ph);

      setState(() {
        _client = client;
        _session = session;
        _status = 'Connected to ${widget.profile.target}';
      });
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
    }
  }

  void _sendKey(String bytes) {
    _session?.write(utf8.encode(bytes));
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(ClipboardData(text: _plainLog.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session output copied')),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _session?.write(utf8.encode(text));
  }

  @override
  void dispose() {
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
            onPressed: _copyOutput,
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
              itemCount: _extraKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, i) {
                final key = _extraKeys[i];
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
