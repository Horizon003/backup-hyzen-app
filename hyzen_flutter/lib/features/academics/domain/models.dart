/// Typed read models for the legacy academic trees stored at
/// `settings/{pw_notes_tree|pw_mcqs_tree|pw_special_tree|pw_pastpapers|pw_lectures_tree}.value`.
///
/// CONFIRMED shape (live Firestore probe + v2 source):
/// Year{id,label,order,semesters[]} → Semester{id,label,order,subjects[]}
/// → Subject{id,label,order,sections[],topics[]} → Section{id,title,published,order,topics[]}
/// → Topic{id,title,published,order,files[]} → File{id,title,pdfUrl,downloads,published,order,updatedAt}
/// Lectures: Subject.topics[] = {id,title,youtubeUrl,published,updatedAt}.
///
/// Parsing is read-only and defensive: missing fields never crash.
library;

enum LibraryKind { notes, mcqs, special, papers }

extension LibraryKindX on LibraryKind {
  /// Firestore settings doc key (CONFIRMED). `pw_special_tree` is written by the
  /// website but NOT in PUBLIC_KEYS; currently the doc does not exist (404).
  String get storageKey => switch (this) {
    LibraryKind.notes => 'pw_notes_tree',
    LibraryKind.mcqs => 'pw_mcqs_tree',
    LibraryKind.special => 'pw_special_tree',
    LibraryKind.papers => 'pw_pastpapers',
  };

  /// Key used in `pw_settings.{id}Enabled` (CONFIRMED sectionEnabled()).
  String get sectionId => switch (this) {
    LibraryKind.notes => 'notes',
    LibraryKind.mcqs => 'mcqs',
    LibraryKind.special => 'special',
    LibraryKind.papers => 'papers',
  };

  String get title => switch (this) {
    LibraryKind.notes => 'Notes',
    LibraryKind.mcqs => 'MCQs',
    LibraryKind.special => 'Special Books & Notes',
    LibraryKind.papers => 'Past Papers',
  };

  String get shortTitle => switch (this) {
    LibraryKind.notes => 'Notes',
    LibraryKind.mcqs => 'MCQs',
    LibraryKind.special => 'Special',
    LibraryKind.papers => 'Past Papers',
  };

  String get blurb => switch (this) {
    LibraryKind.notes => 'Topic-wise study notes for every subject',
    LibraryKind.mcqs => 'Practice MCQs, university-wise',
    LibraryKind.special => 'Guide books, special & general notes',
    LibraryKind.papers => 'Arranged past papers by university',
  };

  static LibraryKind? parse(String? s) {
    for (final k in LibraryKind.values) {
      if (k.name == s) return k;
    }
    return null;
  }
}

bool _published(Object? v) => v != false && v != 'false';
int _order(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String _s(Object? v, [String fb = '']) =>
    v is String ? v : (v == null ? fb : '$v');
List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

List<T> _sorted<T extends Ordered>(Iterable<T> it) {
  final l = it.toList();
  // Stable sort by (order||0) — matches legacy (a.order||0)-(b.order||0).
  final idx = {for (var i = 0; i < l.length; i++) l[i]: i};
  l.sort((a, b) {
    final c = a.order.compareTo(b.order);
    return c != 0 ? c : idx[a]!.compareTo(idx[b]!);
  });
  return l;
}

abstract class Ordered {
  int get order;
}

class StudyFile implements Ordered {
  StudyFile({
    required this.id,
    required this.title,
    required this.url,
    required this.order,
    required this.downloads,
    this.updatedAt,
  });
  final String id;
  final String title;
  final String url;
  @override
  final int order;
  final int downloads;
  final DateTime? updatedAt;

  static StudyFile? fromMap(Map<String, dynamic> m) {
    if (!_published(m['published'])) return null;
    final url = _s(m['pdfUrl']).trim();
    return StudyFile(
      id: _s(m['id'], url),
      title: _s(m['title'], 'Untitled file').trim().isEmpty
          ? 'Untitled file'
          : _s(m['title']).trim(),
      url: url,
      order: _order(m['order']),
      downloads: _order(m['downloads']),
      updatedAt: DateTime.tryParse(_s(m['updatedAt'])),
    );
  }

  /// Display title without a trailing ".pdf".
  String get displayTitle =>
      title.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
}

class Topic implements Ordered {
  Topic({
    required this.id,
    required this.title,
    required this.order,
    required this.files,
  });
  final String id;
  final String title;
  @override
  final int order;
  final List<StudyFile> files;

  static Topic? fromMap(Map<String, dynamic> m) {
    if (!_published(m['published'])) return null;
    return Topic(
      id: _s(m['id']),
      title: _s(m['title'], 'Topic'),
      order: _order(m['order']),
      files: _sorted(
        _list(m['files']).map(StudyFile.fromMap).whereType<StudyFile>(),
      ),
    );
  }
}

class Section implements Ordered {
  Section({
    required this.id,
    required this.title,
    required this.order,
    required this.topics,
  });
  final String id;
  final String title;
  @override
  final int order;
  final List<Topic> topics;
  int get fileCount => topics.fold(0, (s, t) => s + t.files.length);

  static Section? fromMap(Map<String, dynamic> m) {
    if (!_published(m['published'])) return null;
    return Section(
      id: _s(m['id']),
      title: _s(m['title'], 'Section'),
      order: _order(m['order']),
      topics: _sorted(_list(m['topics']).map(Topic.fromMap).whereType<Topic>()),
    );
  }
}

class Subject implements Ordered {
  Subject({
    required this.id,
    required this.label,
    required this.order,
    required this.sections,
  });
  final String id;
  final String label;
  @override
  final int order;
  final List<Section> sections;
  int get fileCount => sections.fold(0, (s, x) => s + x.fileCount);
  int get topicCount => sections.fold(0, (s, x) => s + x.topics.length);

  static Subject fromMap(Map<String, dynamic> m) => Subject(
    id: _s(m['id']),
    label: _s(m['label'], 'Subject'),
    order: _order(m['order']),
    sections: _sorted(
      _list(m['sections']).map(Section.fromMap).whereType<Section>(),
    ),
  );
}

class Semester implements Ordered {
  Semester({
    required this.id,
    required this.label,
    required this.order,
    required this.subjects,
  });
  final String id;
  final String label;
  @override
  final int order;
  final List<Subject> subjects;
  int get fileCount => subjects.fold(0, (s, x) => s + x.fileCount);

  static Semester fromMap(Map<String, dynamic> m) => Semester(
    id: _s(m['id']),
    label: _s(m['label'], 'Semester'),
    order: _order(m['order']),
    subjects: _sorted(
      _list(
        m['subjects'],
      ).where((m) => _published(m['published'])).map(Subject.fromMap),
    ),
  );
}

class ProfYear implements Ordered {
  ProfYear({
    required this.id,
    required this.label,
    required this.order,
    required this.semesters,
  });
  final String id;
  final String label;
  @override
  final int order;
  final List<Semester> semesters;
  int get fileCount => semesters.fold(0, (s, x) => s + x.fileCount);
  int get subjectCount => semesters.fold(0, (s, x) => s + x.subjects.length);

  static ProfYear fromMap(Map<String, dynamic> m) => ProfYear(
    id: _s(m['id']),
    label: _s(m['label'], 'Professional Year'),
    order: _order(m['order']),
    semesters: _sorted(
      _list(
        m['semesters'],
      ).where((m) => _published(m['published'])).map(Semester.fromMap),
    ),
  );

  /// Best-effort 1..5 from label ("1st Professional" → 1).
  int? get yearNumber => professionalNumber(label) ?? professionalNumber(id);
}

class Library {
  Library(this.kind, this.years);
  final LibraryKind kind;
  final List<ProfYear> years;
  int get fileCount => years.fold(0, (s, y) => s + y.fileCount);
  bool get isEmpty => fileCount == 0;

  ProfYear? year(String id) => years.where((y) => y.id == id).firstOrNull;

  /// Parse raw `value` (List) from Firestore, applying legacy normalisers.
  factory Library.parse(LibraryKind kind, Object? raw) {
    final tree = kind == LibraryKind.papers
        ? normalizePastPapers(raw)
        : ensureNestedTree(raw, kind);
    return Library(
      kind,
      _sorted(
        tree.where((m) => _published(m['published'])).map(ProfYear.fromMap),
      ),
    );
  }
}

// ---------------- Lectures ----------------
class Lecture implements Ordered {
  Lecture({
    required this.id,
    required this.title,
    required this.url,
    required this.order,
  });
  final String id;
  final String title;
  final String url;
  @override
  final int order;

  static Lecture? fromMap(Map<String, dynamic> m) {
    if (!_published(m['published'])) return null;
    return Lecture(
      id: _s(m['id']),
      title: _s(m['title'], 'Lecture'),
      url: _s(m['youtubeUrl'] ?? m['playlistUrl'] ?? m['externalUrl']).trim(),
      order: _order(m['order']),
    );
  }

  /// Normalised https URL (live data contains bare "youtube.com").
  Uri? get uri {
    var u = url;
    if (u.isEmpty) return null;
    if (!u.startsWith('http')) u = 'https://$u';
    return Uri.tryParse(u);
  }
}

class LectureSubject implements Ordered {
  LectureSubject({
    required this.id,
    required this.label,
    required this.order,
    required this.lectures,
  });
  final String id;
  final String label;
  @override
  final int order;
  final List<Lecture> lectures;
}

class LectureSemester {
  LectureSemester({
    required this.id,
    required this.label,
    required this.subjects,
  });
  final String id;
  final String label;
  final List<LectureSubject> subjects;
}

class LectureYear implements Ordered {
  LectureYear({
    required this.id,
    required this.label,
    required this.order,
    required this.semesters,
  });
  final String id;
  final String label;
  @override
  final int order;
  final List<LectureSemester> semesters;
  int get count => semesters.fold(
    0,
    (s, se) => s + se.subjects.fold(0, (a, b) => a + b.lectures.length),
  );

  static List<LectureYear> parseAll(Object? raw) {
    return _sorted(
      _list(raw).map(
        (y) => LectureYear(
          id: _s(y['id']),
          label: _s(y['label'], 'Year'),
          order: _order(y['order']),
          semesters: _sortedMaps(_list(y['semesters']))
              .map(
                (se) => LectureSemester(
                  id: _s(se['id']),
                  label: _s(se['label'], 'Semester'),
                  subjects: _sorted(
                    _list(se['subjects']).map(
                      (su) => LectureSubject(
                        id: _s(su['id']),
                        label: _s(su['label'], 'Subject'),
                        order: _order(su['order']),
                        lectures: _sorted(
                          _list(
                            su['topics'],
                          ).map(Lecture.fromMap).whereType<Lecture>(),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _sortedMaps(List<Map<String, dynamic>> l) {
  final c = [...l];
  c.sort((a, b) => _order(a['order']).compareTo(_order(b['order'])));
  return c;
}

// ---------------- Legacy normalisers (CONFIRMED, read-only ports) ----------------
String rid(Object? v) {
  final s = '${v ?? 'item'}'
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final cut = s.length > 42 ? s.substring(0, 42) : s;
  return cut.isEmpty ? 'item' : cut;
}

/// Port of `__ensureNestedResourceTree`: legacy subjects that stored PDFs directly
/// in `subject.topics[]` (with pdfUrl) get one synthetic section. Never mutates input.
List<Map<String, dynamic>> ensureNestedTree(Object? raw, LibraryKind kind) {
  final years = _list(raw);
  return years.map((y) {
    final sems = _list(y['semesters']).map((se) {
      final subs = _list(se['subjects']).map((su) {
        final sections = _list(su['sections']);
        final topics = _list(su['topics']);
        if ((kind == LibraryKind.mcqs || kind == LibraryKind.notes) &&
            sections.isEmpty &&
            topics.isNotEmpty) {
          var i = 0;
          final synth = {
            'id': 'mcqsec-${rid(su['id'] ?? su['label'])}',
            'title': kind == LibraryKind.notes ? 'Study Notes' : 'MCQs',
            'published': true,
            'order': 1,
            'topics': topics.map((old) {
              final n = i++;
              final url = old['pdfUrl'];
              return {
                'id': 'mcqtp-${rid(old['id'] ?? old['title'] ?? n)}',
                'title': old['title'] ?? 'Topic ${n + 1}',
                'published': _published(old['published']),
                'order': n + 1,
                'files': url != null && '$url'.isNotEmpty
                    ? [
                        {
                          'id': 'mcqfile-${rid(old['id'] ?? n)}',
                          'title': old['title'] ?? 'MCQ File ${n + 1}',
                          'pdfUrl': url,
                          'downloads': old['downloads'] ?? 0,
                          'published': _published(old['published']),
                          'order': 1,
                          'updatedAt': old['updatedAt'],
                        },
                      ]
                    : <Map<String, dynamic>>[],
              };
            }).toList(),
          };
          return {
            ...su,
            'sections': [synth],
          };
        }
        return {...su, 'sections': sections};
      }).toList();
      return {...se, 'subjects': subs};
    }).toList();
    return {...y, 'semesters': sems};
  }).toList();
}

/// Port of `__normalizePastPapers`: supports the new nested tree and the legacy
/// University → years → subjects → papers format.
List<Map<String, dynamic>> normalizePastPapers(Object? raw) {
  final list = _list(raw);
  if (list.isEmpty || list.any((x) => x['semesters'] is List)) {
    return ensureNestedTree(list, LibraryKind.papers);
  }
  if (!list.any((x) => x['years'] is List)) return list;
  final years = <Map<String, dynamic>>[];
  Map<String, dynamic> getYear(String label) {
    for (final y in years) {
      if (y['label'] == label) return y;
    }
    final y = <String, dynamic>{
      'id': 'ppyear-${rid(label)}',
      'label': label,
      'order': years.length + 1,
      'semesters': [
        {
          'id': 'ppsem-${rid(label)}-1',
          'label': 'Semester 1',
          'order': 1,
          'subjects': <Map<String, dynamic>>[],
        },
        {
          'id': 'ppsem-${rid(label)}-2',
          'label': 'Semester 2',
          'order': 2,
          'subjects': <Map<String, dynamic>>[],
        },
      ],
    };
    years.add(y);
    return y;
  }

  for (var ui = 0; ui < list.length; ui++) {
    final u = list[ui];
    final oys = _list(u['years']);
    for (var yi = 0; yi < oys.length; yi++) {
      final oy = oys[yi];
      final y = getYear(_s(oy['label'], 'Professional ${yi + 1}'));
      final se = (y['semesters'] as List).first as Map<String, dynamic>;
      final subs = se['subjects'] as List<Map<String, dynamic>>;
      final osubs = _list(oy['subjects']);
      for (var si = 0; si < osubs.length; si++) {
        final osu = osubs[si];
        var su = subs.where((x) => x['label'] == osu['label']).firstOrNull;
        if (su == null) {
          su = {
            'id': 'ppsub-${rid(osu['id'] ?? osu['label'] ?? si)}',
            'label': osu['label'] ?? 'Subject ${si + 1}',
            'order': subs.length + 1,
            'topics': <Map<String, dynamic>>[],
            'sections': <Map<String, dynamic>>[],
          };
          subs.add(su);
        }
        final secs = su['sections'] as List<Map<String, dynamic>>;
        final papers = _list(osu['papers']);
        final files = <Map<String, dynamic>>[];
        for (var pi = 0; pi < papers.length; pi++) {
          final pp = papers[pi];
          var title = _s(pp['title']);
          if (title.isEmpty) {
            title = '${_s(pp['year'])} ${_s(pp['session'], 'Paper')}'.trim();
          }
          if (title.isEmpty) title = 'Past Paper ${pi + 1}';
          files.add({
            'id': 'ppfile-${rid(pp['id'] ?? title)}',
            'title': title,
            'pdfUrl': pp['pdfUrl'] ?? '',
            'downloads': pp['downloads'] ?? 0,
            'published': _published(pp['published']),
            'order': pi + 1,
            'updatedAt': pp['updatedAt'],
          });
        }
        secs.add({
          'id':
              'ppsec-${rid('${u['id'] ?? u['label'] ?? ui}-${osu['id'] ?? si}')}',
          'title': u['label'] ?? 'Imported Papers',
          'published': true,
          'order': secs.length + 1,
          'topics': [
            {
              'id': 'pptp-${rid('${u['id'] ?? ui}-${osu['id'] ?? si}')}',
              'title': 'Past Papers',
              'published': true,
              'order': 1,
              'files': files,
            },
          ],
        });
      }
    }
  }
  return years;
}

int? professionalNumber(String value) {
  final number = RegExp(r'[1-5]').firstMatch(value)?.group(0);
  if (number != null) return int.parse(number);
  final s = value.toLowerCase();
  const words = ['first', 'second', 'third', 'fourth', 'fifth'];
  for (var i = 0; i < words.length; i++) {
    if (s.contains(words[i])) return i + 1;
  }
  return null;
}
