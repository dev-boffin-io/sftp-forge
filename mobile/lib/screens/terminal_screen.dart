import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm2/xterm.dart';

import '../models/ssh_profile.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

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

  SSHClient? _client;
  SSHSession? _session;
  String _status = 'Connecting…';

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

      session.stdout.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(terminal.write);
      session.stderr.cast<List<int>>().transform(const Utf8Decoder(allowMalformed: true)).listen(terminal.write);

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

  @override
  void dispose() {
    _session?.close();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.profile.name)),
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
        ],
      ),
    );
  }
}
