/// Centralised brand configuration.
///
/// Product name and app mark used across native entry points.
class Brand {
  Brand._();
  static const appName = 'PHARM D WITH HYZEN';
  static const shortName = 'PHARM D';
  static const tagline = 'Your pharmacy journey';

  /// Full wordmark logo (used on splash / welcome / auth).
  static const logoAsset = 'assets/brand/hyzen_icon_square.png';

  /// White mark only (used on coloured backgrounds).
  static const markWhiteAsset = 'assets/brand/hyzen_mark_white.png';
}
