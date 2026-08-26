import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

import '../models/ssh_profile.dart';

class SSHService {
  /// Opens a connected [SSHClient] for [profile].
  /// If the profile has a key path, it's used for auth; otherwise
  /// [password] is used. Throws on connect/auth failure.
  static Future<SSHClient> connect(SSHProfile profile, {String? password}) async {
    final socket = await SSHSocket.connect(profile.host, profile.port);

    List<SSHKeyPair>? identities;
    if (profile.key.isNotEmpty) {
      final pem = await File(profile.key).readAsString();
      identities = SSHKeyPair.fromPem(pem, password);
    }

    return SSHClient(
      socket,
      username: profile.user,
      identities: identities,
      onPasswordAuth: identities == null ? () => password ?? '' : null,
    );
  }

  static Future<SftpClient> openSftp(SSHClient client) => client.sftp();
}
