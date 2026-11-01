import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/core/utils/validators.dart';
import 'package:hyzen_pharmd/features/academics/domain/drive.dart';
import 'package:hyzen_pharmd/features/academics/domain/models.dart';
import 'package:hyzen_pharmd/features/content/domain/site_models.dart';
import 'package:hyzen_pharmd/features/downloads/domain/download_record.dart';

void main() {
  group('PkPhone', () {
    test('normalizes accepted formats', () {
      for (final s in [
        '03001234567',
        '3001234567',
        '+923001234567',
        '923001234567',
        '0092 300-1234567',
      ]) {
        expect(PkPhone.normalize(s), '+923001234567', reason: s);
      }
    });
    test('rejects invalid', () {
      for (final s in ['', '0300123', '04001234567', 'abc', '+9230012345678']) {
        expect(PkPhone.normalize(s), isNull, reason: s);
      }
    });
  });

  group('Validators', () {
    test('password needs 8 chars, letter and number', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('abcd1234'), isNull);
    });
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
    });
  });

  group('DriveLinks (legacy parity)', () {
    test('file id regex order', () {
      expect(
        DriveLinks.fileId(
          'https://drive.google.com/file/d/AbC_12-x/view?usp=drivesdk',
        ),
        'AbC_12-x',
      );
      expect(
        DriveLinks.fileId('https://drive.google.com/open?id=XYZ9'),
        'XYZ9',
      );
      expect(
        DriveLinks.fileId('https://docs.google.com/presentation/d/PRES1/edit'),
        'PRES1',
      );
      expect(DriveLinks.fileId('https://example.com/a.pdf'), '');
    });
    test('preview + download + offline key', () {
      const u = 'https://drive.google.com/file/d/ID1/view';
      expect(
        DriveLinks.previewUrl(u),
        'https://drive.google.com/file/d/ID1/preview',
      );
      expect(
        DriveLinks.downloadUrl(u),
        'https://drive.usercontent.google.com/download?id=ID1&export=download&confirm=t',
      );
      expect(DriveLinks.offlineKey(u), 'drive_ID1');
      expect(
        DriveLinks.offlineKey('https://example.com/a.pdf'),
        startsWith('url_'),
      );
    });
    test('FNV-1a matches JS reference values', () {
      // JS: fnv("") = 2166136261 -> base36 "zqlbx1"? computed: (2166136261).toString(36)
      expect(DriveLinks.fnv1a36(''), 2166136261.toRadixString(36));
      // JS fnv("a") = 0xe40c292c
      expect(DriveLinks.fnv1a36('a'), 0xe40c292c.toRadixString(36));
    });
  });

  group('Academic models', () {
    test('publish filter + order sort', () {
      final lib = Library.parse(LibraryKind.notes, [
        {
          'id': 'y1',
          'label': '1st Professional',
          'order': 1,
          'semesters': [
            {
              'id': 's1',
              'label': 'Semester 1',
              'order': 1,
              'subjects': [
                {
                  'id': 'su1',
                  'label': 'English',
                  'order': 1,
                  'sections': [
                    {'id': 'b2', 'title': 'Second', 'order': 2, 'topics': []},
                    {
                      'id': 'b1',
                      'title': 'First',
                      'order': 1,
                      'topics': [
                        {
                          'id': 't1',
                          'title': 'T',
                          'files': [
                            {
                              'id': 'f1',
                              'title': 'a.pdf',
                              'pdfUrl': 'x',
                              'order': 2,
                            },
                            {
                              'id': 'f0',
                              'title': 'b.pdf',
                              'pdfUrl': 'y',
                              'order': 1,
                            },
                            {
                              'id': 'fh',
                              'title': 'hidden',
                              'pdfUrl': 'z',
                              'published': false,
                            },
                          ],
                        },
                      ],
                    },
                    {
                      'id': 'bh',
                      'title': 'Hidden',
                      'published': 'false',
                      'topics': [],
                    },
                  ],
                },
              ],
            },
          ],
        },
      ]);
      final secs = lib.years.first.semesters.first.subjects.first.sections;
      expect(secs.map((s) => s.id), ['b1', 'b2']);
      expect(secs.first.topics.first.files.map((f) => f.id), ['f0', 'f1']);
      expect(lib.fileCount, 2);
    });
    test('legacy subject.topics -> synthetic section', () {
      final t = ensureNestedTree([
        {
          'semesters': [
            {
              'subjects': [
                {
                  'id': 'm',
                  'label': 'Maths',
                  'topics': [
                    {
                      'id': 'o1',
                      'title': 'Old',
                      'pdfUrl': 'https://drive.google.com/file/d/Q/view',
                    },
                  ],
                },
              ],
            },
          ],
        },
      ], LibraryKind.mcqs);
      final sec = t.first['semesters'][0]['subjects'][0]['sections'][0];
      expect(sec['title'], 'MCQs');
      expect(sec['topics'][0]['files'][0]['pdfUrl'], contains('/d/Q/'));
    });
    test('legacy past papers University->years normalised', () {
      final t = normalizePastPapers([
        {
          'id': 'pu',
          'label': 'PU',
          'years': [
            {
              'label': '1st Professional',
              'subjects': [
                {
                  'id': 'e',
                  'label': 'English',
                  'papers': [
                    {'year': '2022', 'pdfUrl': 'u'},
                  ],
                },
              ],
            },
          ],
        },
      ]);
      final lib = Library.parse(LibraryKind.papers, t);
      expect(lib.years.single.label, '1st Professional');
      expect(lib.fileCount, 1);
      expect(
        lib.years.single.semesters.first.subjects.single.sections.single.title,
        'PU',
      );
    });
  });

  group('Settings / commerce (legacy parity)', () {
    test('sectionEnabled semantics', () {
      final s = SiteSettings({'mcqsEnabled': 'false'});
      expect(s.sectionEnabled('notes'), isTrue);
      expect(s.sectionEnabled('mcqs'), isFalse);
      expect(s.sectionEnabled('lectures'), isFalse);
      expect(
        SiteSettings({'lecturesEnabled': 'true'}).sectionEnabled('lectures'),
        isTrue,
      );
      expect(s.shopComingSoon, isTrue);
    });
    test('delivery defaults + calc', () {
      final d = DeliverySettings.fromRaw(null);
      expect(d.chargeFor(500, 'Punjab'), 200);
      expect(d.chargeFor(500, 'GB'), 450);
      expect(d.chargeFor(500, 'Unknown'), 250);
      expect(d.chargeFor(10000, 'GB'), 0);
    });
    test('availStock', () {
      expect(
        Product({'stockStatus': 'out_of_stock', 'stockCount': 5}).availStock,
        0,
      );
      expect(Product({'stockCount': ''}).availStock, 9999);
      expect(Product({'stockCount': '7'}).availStock, 7);
    });
    test('money format', () => expect(money(12345), 'Rs 12,345'));
  });

  test('PdfSniffer', () {
    expect(PdfSniffer.isPdf('%PDF-1.7'.codeUnits), isTrue);
    expect(PdfSniffer.isPdf('<!DOCTYPE html>'.codeUnits), isFalse);
    expect(PdfSniffer.looksLikeHtml('<!DOCTYPE html><html>'.codeUnits), isTrue);
  });
}
