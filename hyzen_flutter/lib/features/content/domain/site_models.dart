/// Read models for public site content (CONFIRMED keys/shapes from the v2 source
/// and the live Firestore probe). All parsing is defensive.
library;

String _s(Object? v, [String fb = '']) =>
    v is String ? v : (v == null ? fb : '$v');
bool _truthy(Object? v) => v == true || v == 'true';
bool _notFalse(Object? v) => v != false && v != 'false';
int _int(Object? v, [int fb = 0]) =>
    v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? fb;
num _num(Object? v, [num fb = 0]) =>
    v is num ? v : num.tryParse('${v ?? ''}') ?? fb;

class SiteSettings {
  SiteSettings(this.raw);
  final Map<String, dynamic> raw;

  /// CONFIRMED legacy `sectionEnabled(id)`:
  /// lectures → only when true/"true"; everything else → unless false/"false".
  bool sectionEnabled(String id) {
    final v = raw['${id}Enabled'];
    if (id == 'lectures') return _truthy(v);
    return _notFalse(v);
  }

  /// CONFIRMED `shopIsComing()` — default true.
  bool get shopComingSoon => _notFalse(raw['shopComingSoon']);

  String get websiteName => _s(raw['websiteName'], 'PHARM D WITH HYZEN');
  String get heroTitle => _s(raw['heroTitle']);
  String get heroSubtitle => _s(raw['heroSubtitle']);
  String get email => _s(raw['email']);
  String get whatsapp => _s(raw['whatsapp']);
  String get contactNumber => _s(raw['contactNumber']);
  String get footerText => _s(raw['footerText']);
  String get currency => _s(raw['currency'], 'PKR');
  String get logoUrl => _s(raw['logoUrl']);

  FullScreenNotice? get notice {
    final n = raw['fullScreenNotice'];
    return n is Map ? FullScreenNotice(n.cast<String, dynamic>()) : null;
  }
}

/// CONFIRMED `settings/pw_settings.value.fullScreenNotice`.
/// Eligibility = legacy `Notices.eligible`: enabled && id && not expired && not seen.
class FullScreenNotice {
  FullScreenNotice(this.raw);
  final Map<String, dynamic> raw;
  String get id => _s(raw['id']);
  bool get enabled => _truthy(raw['enabled']);
  DateTime? get expires => DateTime.tryParse(_s(raw['expires']));
  String get title => _s(raw['title'], 'Notice');
  String get body => _s(raw['body']);
  String get eyebrow => _s(raw['eyebrow']);
  String get primaryText => _s(raw['primaryText']);
  String get primaryUrl => _s(raw['primaryUrl']);
  String get secondaryText => _s(raw['secondaryText']);
  String get secondaryUrl => _s(raw['secondaryUrl']);
  String get dismissText => _s(raw['dismissText'], 'Maybe later');
  String get image => _s(raw['image']);
  String get type => _s(raw['type'], 'info');

  /// 'once' (persist) | 'session' (per app run).
  String get repeat => _s(raw['repeat'], 'once');
  DateTime? get publishedAt => DateTime.tryParse(_s(raw['publishedAt']));

  bool eligible({
    required DateTime now,
    required bool Function(String id) seen,
  }) {
    if (!enabled || id.isEmpty) return false;
    final e = expires;
    if (e != null && e.isBefore(now)) return false;
    return !seen(id);
  }
}

/// CONFIRMED `pw_announcement`.
class Announcement {
  Announcement(this.raw);
  final Map<String, dynamic> raw;
  bool get enabled => _truthy(raw['enabled']);
  String get text => _s(raw['text']).trim();
  String get linkText => _s(raw['linkText']);
  String get linkUrl => _s(raw['linkUrl']);
  bool get visible => enabled && text.isNotEmpty;
}

/// CONFIRMED `pw_about` — HTML strings.
class AboutContent {
  AboutContent(this.raw);
  final Map<String, dynamic> raw;
  String get about => _s(raw['about']);
  String get founder => _s(raw['founder']);
  String get vision => _s(raw['vision']);
  String get mission => _s(raw['mission']);
}

class CreditCard {
  CreditCard(this.raw);
  final Map<String, dynamic> raw;
  String get name => _s(raw['name']);
  String get role => _s(raw['role']);
  String get designation => _s(raw['designation']);
  String get description => _s(raw['description']);
  String get photo => _s(raw['photo']);
  bool get featured => _truthy(raw['featured']);
  int get order => _int(raw['order']);
}

/// CONFIRMED `pw_social` entries `{id,platform,url,enabled,order}`.
class SocialLink {
  SocialLink(this.raw);
  final Map<String, dynamic> raw;
  String get platform => _s(raw['platform']);
  String get url => _s(raw['url']);
  bool get enabled => _notFalse(raw['enabled']);
  int get order => _int(raw['order']);
}

/// CONFIRMED `pw_blogs` entries.
class BlogPost {
  BlogPost(this.raw);
  final Map<String, dynamic> raw;
  String get id => _s(raw['id']);
  String get slug => _s(raw['slug'], id);
  String get title => _s(raw['title'], 'Untitled');
  String get coverImage => _s(raw['coverImage']);
  String get excerpt => _s(raw['excerpt']);
  String get contentHtml => _s(raw['contentHtml']);
  String get author => _s(raw['author']);
  String get status => _s(raw['status']);
  bool get published => status == 'published';
  DateTime? get publishedAt => DateTime.tryParse(_s(raw['publishedAt']));
}

/// CONFIRMED `pw_products` entries.
class Product {
  Product(this.raw);
  final Map<String, dynamic> raw;
  String get id => _s(raw['id']);
  String get name => _s(raw['name'], 'Product');
  String get category => _s(raw['category']);
  num get price => _num(raw['price']);
  num? get compareAtPrice {
    final v = _num(raw['compareAtPrice'], -1);
    return v > 0 ? v : null;
  }

  String get shortDesc => _s(raw['shortDesc']);
  String get fullDescHtml => _s(raw['fullDescHtml']);
  String get stockStatus => _s(raw['stockStatus'], 'in_stock');
  Object? get stockCount => raw['stockCount'];
  bool get hidden => _truthy(raw['hidden']);
  bool get featured => _truthy(raw['featured']);
  List<String> get images => raw['images'] is List
      ? (raw['images'] as List)
            .map((e) => '$e')
            .where((e) => e.isNotEmpty)
            .toList()
      : const [];
  String? get image => images.isEmpty ? null : images.first;
  List<ProductVariant> get variants => raw['variants'] is List
      ? (raw['variants'] as List)
            .whereType<Map>()
            .map((m) => ProductVariant(m.cast<String, dynamic>()))
            .toList()
      : const [];

  /// CONFIRMED legacy `availStock(p)`.
  int get availStock {
    if (stockStatus == 'out_of_stock') return 0;
    final c = stockCount;
    if (c == null || c == '') return 9999;
    final n = c is num ? c.toInt() : int.tryParse('$c') ?? 0;
    return n < 0 ? 0 : n;
  }
}

class ProductVariant {
  ProductVariant(this.raw);
  final Map<String, dynamic> raw;
  String get name => _s(raw['name'], 'Option');
  List<String> get options => raw['options'] is List
      ? (raw['options'] as List).map((e) => '$e').toList()
      : const [];
}

/// CONFIRMED `pw_delivery` (doc currently absent → legacy defaults).
class DeliverySettings {
  DeliverySettings({
    required this.defaultCharge,
    required this.freeDeliveryThreshold,
    required this.provinceRates,
  });
  final num defaultCharge;
  final num freeDeliveryThreshold;
  final Map<String, num> provinceRates;

  static const provinces = [
    'Punjab',
    'Sindh',
    'KPK',
    'Balochistan',
    'GB',
    'AJK',
    'ICT',
  ];
  static const defaultRates = {
    'Punjab': 200,
    'Sindh': 250,
    'KPK': 300,
    'Balochistan': 400,
    'GB': 450,
    'AJK': 350,
    'ICT': 200,
  };

  /// Port of `Repo.delivery.get()` — defaults merged with stored values.
  factory DeliverySettings.fromRaw(Object? v) {
    final m = v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
    final rates = <String, num>{...defaultRates};
    final pr = m['provinceRates'];
    if (pr is Map) {
      pr.forEach((k, val) {
        final n = val is num ? val : num.tryParse('$val');
        if (n != null) rates['$k'] = n;
      });
    }
    return DeliverySettings(
      defaultCharge: _num(m['defaultCharge'], 250),
      freeDeliveryThreshold: _num(m['freeDeliveryThreshold'], 10000),
      provinceRates: rates,
    );
  }

  /// CONFIRMED `sub>=threshold?0:(provinceRates[prov]??defaultCharge)`.
  num chargeFor(num subtotal, String? province) {
    if (subtotal >= freeDeliveryThreshold) return 0;
    return provinceRates[province] ?? defaultCharge;
  }
}

/// "Rs 1,234" — matches legacy `money()` (en-PK grouping).
String money(num n) {
  final neg = n < 0;
  final s = n.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'Rs ${neg ? '-' : ''}$b';
}
