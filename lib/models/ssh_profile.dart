class SSHProfile {
  final String name;
  final String user;
  final String host;
  final int port;
  final String key; // absolute path to a private key file on-device, blank = password auth
  final String path; // remote start path

  const SSHProfile({
    required this.name,
    required this.user,
    required this.host,
    this.port = 22,
    this.key = '',
    this.path = '/',
  });

  String get target => user.isEmpty ? host : '$user@$host';

  Map<String, dynamic> toJson() => {
        'user': user,
        'host': host,
        'port': port,
        'key': key,
        'path': path,
      };

  factory SSHProfile.fromJson(String name, Map<String, dynamic> json) {
    return SSHProfile(
      name: name,
      user: json['user'] as String? ?? '',
      host: json['host'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 22,
      key: json['key'] as String? ?? '',
      path: json['path'] as String? ?? '/',
    );
  }

  SSHProfile copyWith({
    String? name,
    String? user,
    String? host,
    int? port,
    String? key,
    String? path,
  }) {
    return SSHProfile(
      name: name ?? this.name,
      user: user ?? this.user,
      host: host ?? this.host,
      port: port ?? this.port,
      key: key ?? this.key,
      path: path ?? this.path,
    );
  }
}
