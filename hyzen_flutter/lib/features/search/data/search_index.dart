import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academics/domain/models.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_models.dart';

enum HitType { subject, section, topic, file, lecture, product, blog }

/// One searchable entry. Mirrors the legacy search index (subjects/sections/topics/files
/// of enabled libraries + visible products + published blogs).
class SearchHit {
  SearchHit({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
    this.kind,
    this.url,
    this.trail = const [],
    this.studioFileId,
    this.page,
  }) : _hay = '${title.toLowerCase()} ${subtitle.toLowerCase()}';
  final HitType type;
  final String title;
  final String subtitle;
  final String route;
  final LibraryKind? kind;
  final String? url;
  final List<String> trail;
  final String? studioFileId;
  final int? page;
  final String _hay;

  int score(List<String> terms) {
    var s = 0;
    final t = title.toLowerCase();
    for (final term in terms) {
      if (!_hay.contains(term)) return 0;
      s += t.startsWith(term) ? 6 : (t.contains(term) ? 3 : 1);
    }
    return s + (type == HitType.subject ? 2 : 0);
  }
}

List<SearchHit> buildLibraryIndex(Library lib) {
  final out = <SearchHit>[];
  final k = lib.kind;
  for (final y in lib.years) {
    for (final se in y.semesters) {
      for (final su in se.subjects) {
        final base = '/study/${k.name}/${y.id}/${se.id}/${su.id}';
        out.add(
          SearchHit(
            type: HitType.subject,
            title: su.label,
            subtitle: '${k.shortTitle} · ${y.label} · ${se.label}',
            route: base,
            kind: k,
          ),
        );
        for (final sec in su.sections) {
          out.add(
            SearchHit(
              type: HitType.section,
              title: sec.title,
              subtitle: '${k.shortTitle} · ${su.label}',
              route: '$base/${sec.id}',
              kind: k,
            ),
          );
          for (final tp in sec.topics) {
            out.add(
              SearchHit(
                type: HitType.topic,
                title: tp.title,
                subtitle: '${su.label} · ${sec.title}',
                route: '$base/${sec.id}/${tp.id}',
                kind: k,
              ),
            );
            for (final f in tp.files) {
              if (f.url.isEmpty) continue;
              out.add(
                SearchHit(
                  type: HitType.file,
                  title: f.displayTitle,
                  subtitle: '${k.shortTitle} · ${su.label} · ${tp.title}',
                  route: '$base/${sec.id}/${tp.id}',
                  kind: k,
                  url: f.url,
                  trail: [y.label, se.label, su.label, sec.title, tp.title],
                ),
              );
            }
          }
        }
      }
    }
  }
  return out;
}

final searchIndexProvider = Provider<List<SearchHit>>((ref) {
  final out = <SearchHit>[];
  for (final k in LibraryKind.values) {
    if (!ref.watch(sectionEnabledProvider(k.sectionId))) {
      continue;
    }
    final lib = ref.watch(libraryProvider(k)).valueOrNull?.data;
    if (lib != null) out.addAll(buildLibraryIndex(lib));
  }
  if (ref.watch(sectionEnabledProvider('lectures'))) {
    for (final y
        in ref.watch(lecturesProvider).valueOrNull?.data ??
            const <LectureYear>[]) {
      for (final se in y.semesters) {
        for (final su in se.subjects) {
          for (final l in su.lectures) {
            out.add(
              SearchHit(
                type: HitType.lecture,
                title: l.title,
                subtitle: 'Lecture · ${su.label}',
                route: '/lectures',
                url: l.uri?.toString(),
              ),
            );
          }
        }
      }
    }
  }
  final settings = ref.watch(siteSettingsProvider);
  if (settings.sectionEnabled('shop') && !settings.shopComingSoon) {
    for (final p
        in ref.watch(productsProvider).valueOrNull?.data ?? const <Product>[]) {
      out.add(
        SearchHit(
          type: HitType.product,
          title: p.name,
          subtitle: 'Shop · ${p.category}',
          route: '/shop/p/${p.id}',
        ),
      );
    }
  }
  if (settings.sectionEnabled('blog')) {
    for (final b
        in ref.watch(blogsProvider).valueOrNull?.data ?? const <BlogPost>[]) {
      out.add(
        SearchHit(
          type: HitType.blog,
          title: b.title,
          subtitle: 'Blog · ${b.author}',
          route: '/blog/${b.id}',
        ),
      );
    }
  }
  return out;
});

List<SearchHit> runSearch(
  List<SearchHit> index,
  String query, {
  HitType? only,
  int limit = 80,
}) {
  final terms = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (terms.isEmpty) return const [];
  final scored = <(int, SearchHit)>[];
  for (final h in index) {
    if (only != null && h.type != only) continue;
    final s = h.score(terms);
    if (s > 0) scored.add((s, h));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return scored.take(limit).map((e) => e.$2).toList();
}
