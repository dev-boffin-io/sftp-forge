import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/ssh_profile.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'sftp_browser_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = ProfileStore();

  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '22');
  final _keyCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: '/');

  bool _loading = true;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) => setState(() => _loading = false));
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _userCtrl, _hostCtrl, _portCtrl, _keyCtrl, _pathCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadIntoForm(String name) {
    final p = _store.get(name);
    if (p == null) return;
    setState(() {
      _selected = name;
      _nameCtrl.text = p.name;
      _userCtrl.text = p.user;
      _hostCtrl.text = p.host;
      _portCtrl.text = p.port.toString();
      _keyCtrl.text = p.key;
      _pathCtrl.text = p.path;
    });
  }

  void _clearForm() {
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _userCtrl.clear();
      _hostCtrl.clear();
      _portCtrl.text = '22';
      _keyCtrl.clear();
      _pathCtrl.text = '/';
    });
  }

  SSHProfile? _readForm() {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      _toast('Host is required');
      return null;
    }
    final port = int.tryParse(_portCtrl.text.trim());
    if (port == null || port < 1 || port > 65535) {
      _toast('Port must be 1–65535');
      return null;
    }
    var path = _pathCtrl.text.trim();
    if (path.isEmpty) path = '/';
    if (!path.startsWith('/')) path = '/$path';
    return SSHProfile(
      name: _nameCtrl.text.trim(),
      user: _userCtrl.text.trim(),
      host: host,
      port: port,
      key: _keyCtrl.text.trim(),
      path: path,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final form = _readForm();
    if (form == null) return;
    if (form.name.isEmpty) {
      _toast('Profile name is required');
      return;
    }
    await _store.set(form);
    setState(() => _selected = form.name);
  }

  Future<void> _delete() async {
    if (_selected == null) {
      _toast('No profile selected');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text("Delete '$_selected'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _store.delete(_selected!);
      _clearForm();
      setState(() {});
    }
  }

  Future<void> _browseKey() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _keyCtrl.text = result.files.single.path!);
    }
  }

  Future<String?> _promptPassword() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Password'),
        content: TextField(controller: ctrl, obscureText: true, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Connect')),
        ],
      ),
    );
  }

  Future<void> _openTerminal() async {
    final form = _readForm();
    if (form == null) return;
    String? password;
    if (form.key.isEmpty) {
      password = await _promptPassword();
      if (password == null) return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TerminalScreen(profile: form, password: password)));
  }

  Future<void> _openSftp() async {
    final form = _readForm();
    if (form == null) return;
    String? password;
    if (form.key.isEmpty) {
      password = await _promptPassword();
      if (password == null) return;
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => SftpBrowserScreen(profile: form, password: password)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('SFTP FORGE'),
        actions: [
          IconButton(onPressed: _clearForm, icon: const Icon(Icons.add), tooltip: 'New profile'),
        ],
      ),
      body: Column(
        children: [
          if (_store.names().isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                children: [
                  for (final name in _store.names())
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: _selected == name,
                        onSelected: (_) => _loadIntoForm(name),
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Profile Name', hintText: 'e.g. prod-server')),
                      const SizedBox(height: 12),
                      TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username', hintText: 'e.g. ubuntu')),
                      const SizedBox(height: 12),
                      TextField(controller: _hostCtrl, decoration: const InputDecoration(labelText: 'Host / IP', hintText: '192.168.1.100 or example.com')),
                      const SizedBox(height: 12),
                      TextField(controller: _portCtrl, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keyCtrl,
                              decoration: const InputDecoration(labelText: 'SSH Key Path', hintText: 'blank = password auth'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(onPressed: _browseKey, child: const Text('Browse')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _pathCtrl, decoration: const InputDecoration(labelText: 'Remote Path', hintText: '/home/user')),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openSftp,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentStrong, foregroundColor: Colors.white),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Browse (SFTP)'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openTerminal,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentStrong, foregroundColor: Colors.white),
                            icon: const Icon(Icons.terminal),
                            label: const Text('Open Terminal'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.greenStrong, foregroundColor: Colors.white),
                            icon: const Icon(Icons.save),
                            label: const Text('Save Profile'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _delete,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redStrong, foregroundColor: AppColors.red),
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
