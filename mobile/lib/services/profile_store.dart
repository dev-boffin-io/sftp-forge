import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/ssh_profile.dart';

/// Stores profiles as a single JSON file, same shape as the desktop
/// app's ~/.config/sftp-forge.json — { "name": {user, host, port, key, path} }.
class ProfileStore {
  Map<String, SSHProfile> _profiles = {};

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sftp-forge.json');
  }

  Future<void> load() async {
    final f = await _file();
    if (!await f.exists()) {
      _profiles = {};
      return;
    }
    final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    _profiles = raw.map(
      (name, v) => MapEntry(name, SSHProfile.fromJson(name, v as Map<String, dynamic>)),
    );
  }

  Future<void> _persist() async {
    final f = await _file();
    final raw = _profiles.map((name, p) => MapEntry(name, p.toJson()));
    await f.writeAsString(jsonEncode(raw));
  }

  List<String> names() => _profiles.keys.toList()..sort();

  SSHProfile? get(String name) => _profiles[name];

  Future<void> set(SSHProfile profile) async {
    _profiles[profile.name] = profile;
    await _persist();
  }

  Future<void> delete(String name) async {
    _profiles.remove(name);
    await _persist();
  }
}
