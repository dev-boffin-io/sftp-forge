import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

import '../models/ssh_profile.dart';
import '../services/ssh_service.dart';
import '../theme/app_theme.dart';

class SftpBrowserScreen extends StatefulWidget {
  final SSHProfile profile;
  final String? password;

  const SftpBrowserScreen({super.key, required this.profile, this.password});

  @override
  State<SftpBrowserScreen> createState() => _SftpBrowserScreenState();
}

class _SftpBrowserScreenState extends State<SftpBrowserScreen> {
  SSHClient? _client;
  SftpClient? _sftp;
  String _cwd = '/';
  List<SftpName> _entries = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cwd = widget.profile.path.isEmpty ? '/' : widget.profile.path;
    _init();
  }

  Future<void> _init() async {
    try {
      final client = await SSHService.connect(widget.profile, password: widget.password);
      final sftp = await SSHService.openSftp(client);
      _client = client;
      _sftp = sftp;
      await _list(_cwd);
    } catch (e) {
      setState(() {
        _error = 'Connection failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _list(String path) async {
    setState(() => _loading = true);
    try {
      final items = await _sftp!.listdir(path);
      items.sort((a, b) => a.filename.compareTo(b.filename));
      setState(() {
        _cwd = path;
        _entries = items.where((e) => e.filename != '.' && e.filename != '..').toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Listing failed: $e';
        _loading = false;
      });
    }
  }

  void _goUp() {
    if (_cwd == '/') return;
    final idx = _cwd.lastIndexOf('/');
    final parent = idx <= 0 ? '/' : _cwd.substring(0, idx);
    _list(parent);
  }

  void _open(SftpName entry) {
    if (!entry.attr.isDirectory) return;
    final next = _cwd == '/' ? '/${entry.filename}' : '$_cwd/${entry.filename}';
    _list(next);
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_cwd)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: AppColors.red)),
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (_cwd != '/')
                      ListTile(
                        leading: const Icon(Icons.arrow_upward, color: AppColors.textMuted),
                        title: const Text('..'),
                        onTap: _goUp,
                      ),
                    for (final e in _entries)
                      ListTile(
                        leading: Icon(
                          e.attr.isDirectory ? Icons.folder : Icons.insert_drive_file,
                          color: e.attr.isDirectory ? AppColors.accent : AppColors.textMuted,
                        ),
                        title: Text(e.filename),
                        subtitle: e.attr.isDirectory
                            ? null
                            : Text('${e.attr.size ?? 0} bytes', style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                        onTap: () => _open(e),
                      ),
                  ],
                ),
    );
  }
}
