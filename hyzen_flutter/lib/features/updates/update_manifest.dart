class UpdateManifest {
  const UpdateManifest({
    required this.code,
    required this.name,
    required this.url,
    required this.sha256,
    required this.minimumCode,
    required this.notes,
    required this.force,
  });
  final int code, minimumCode;
  final String name, url, sha256, notes;
  final bool force;
  static UpdateManifest? parse(Map<String, dynamic> m) {
    int? number(Object? v) => v is num
        ? (v.isFinite && v >= 0 && v <= 2147483647 && v % 1 == 0
              ? v.toInt()
              : null)
        : int.tryParse('$v');
    final code = number(m['androidLatestVersionCode']);
    final min = number(m['androidMinVersionCode']) ?? 0;
    final url = '${m['androidApkUrl'] ?? ''}'.trim();
    final uri = Uri.tryParse(url);
    final hash = '${m['androidSha256'] ?? ''}'.trim().toLowerCase();
    if (code == null ||
        code <= 0 ||
        min < 0 ||
        min > code ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      return null;
    }
    return UpdateManifest(
      code: code,
      name: '${m['androidVersionName'] ?? code}',
      url: url,
      sha256: hash,
      minimumCode: min,
      notes:
          '${m['androidReleaseNotes'] ?? 'Improvements and fixes for PHARM D WITH HYZEN.'}',
      force: m['androidForceUpdate'] == true,
    );
  }

  bool requiredFor(int installed) => installed < minimumCode || force;
}
