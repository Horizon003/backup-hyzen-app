/// Parse Google's public large-file confirmation form. Never follow an arbitrary form.
Uri? driveConfirmation(String html, Uri original) {
  if (original.host != 'drive.usercontent.google.com' &&
      original.host != 'drive.google.com') {
    return null;
  }
  final form = RegExp(
    r"""<form[^>]*action=["']([^"']+)["'][^>]*>([\s\S]*?)</form>""",
    caseSensitive: false,
  ).firstMatch(html);
  if (form == null) return null;
  String decode(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"');
  final uri = original.resolve(decode(form.group(1)!));
  if (uri.scheme != 'https' ||
      !{
        'drive.google.com',
        'drive.usercontent.google.com',
      }.contains(uri.host)) {
    return null;
  }
  final params = {...uri.queryParameters};
  for (final input in RegExp(
    r'<input[^>]+>',
    caseSensitive: false,
  ).allMatches(form.group(2)!)) {
    final name = RegExp(
      r"""name=["']([^"']+)["']""",
      caseSensitive: false,
    ).firstMatch(input.group(0)!);
    final value = RegExp(
      r"""value=["']([^"']*)["']""",
      caseSensitive: false,
    ).firstMatch(input.group(0)!);
    if (name != null && value != null) {
      params[name.group(1)!] = decode(value.group(1)!);
    }
  }
  if (params['id'] != original.queryParameters['id'] ||
      !params.containsKey('confirm')) {
    return null;
  }
  return uri.replace(queryParameters: params);
}
