import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/features/content/data/content_providers.dart';
import 'package:hyzen_pharmd/features/content/domain/site_models.dart';
import 'package:hyzen_pharmd/features/notifications/notice_host.dart';
import 'package:hyzen_pharmd/features/viewer/document_flow.dart';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyzen_pharmd/core/storage/local_store.dart';
import 'package:hyzen_pharmd/core/widgets/ui_kit.dart';
import 'package:hyzen_pharmd/features/admin/presentation/admin_management.dart';
import 'package:hyzen_pharmd/features/auth/domain/student_profile.dart';
import 'package:hyzen_pharmd/features/auth/domain/reference_data.dart';
import 'package:hyzen_pharmd/features/auth/presentation/register_screens.dart';
import 'package:hyzen_pharmd/features/admin/data/admin_repository.dart';
import 'package:hyzen_pharmd/features/admin/domain/import_csv.dart';
import 'package:hyzen_pharmd/features/admin/domain/import_formats.dart';
import 'package:hyzen_pharmd/features/academics/domain/drive.dart';
import 'package:hyzen_pharmd/features/downloads/domain/drive_confirmation.dart';

class NoticeTestUser extends Fake implements User {
  @override
  String get uid => 'notice-student';
}

void main() {
  test(
    'profile survives pending-sync clear and a new store instance; isolated per account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PendingProfileStore(prefs);
      final profile = {
        'fullName': 'Ali Raza',
        'professionalYear': 3,
        'city': 'Daska',
      };
      await store.save('ali', profile);
      await store.clear('ali');
      final afterRestart = PendingProfileStore(prefs);
      expect(afterRestart.read('ali'), isNull);
      expect(afterRestart.cached('ali'), profile);
      expect(afterRestart.cached('different-student'), isNull);
      await store.save('ali', {...profile, 'professionalYear': 4});
      expect(afterRestart.cached('ali')!['professionalYear'], 4);
    },
  );
  test(
    'profile university remains selected when affiliation fields are replaced',
    () {
      final p = StudentProfile(
        uid: '1',
        fullName: 'Ali',
        mobile: '',
        gender: 'male',
        city: 'Lahore',
        professionalYear: 2,
        institutionName: 'College',
        affiliationStatus: AffiliationStatus.nonAffiliated,
        email: 'a@b.co',
      );
      final changed = p.copyWith(
        clearUniversity: true,
        affiliationStatus: AffiliationStatus.affiliated,
        affiliatedUniversity: ReferenceData.universities.first,
        photoUrl: 'https://example.org/photo.jpg',
      );
      expect(changed.affiliatedUniversity!.id, 'pu');
      expect(
        StudentProfile.fromMap('1', changed.toWriteMap()).photoUrl,
        'https://example.org/photo.jpg',
      );
    },
  );
  test('duplicate order inbox retry reduces stock once', () {
    final orders = <Map<String, dynamic>>[],
        products = <Map<String, dynamic>>[
          {'id': 'p', 'stockCount': 9, 'stockStatus': 'in_stock'},
        ];
    final inbox = [
      {
        'id': 'o1',
        'items': [
          {'productId': 'p', 'qty': 4},
        ],
      },
    ];
    expect(mergeOrderInbox(orders, products, inbox), 1);
    expect(products.single['stockCount'], 5);
    expect(products.single['stockStatus'], 'low_stock');
    expect(mergeOrderInbox(orders, products, inbox), 0);
    expect(products.single['stockCount'], 5);
    expect(orders.single['stockApplied'], true);
  });
  test('Drive resource key persists in preview and download endpoints', () {
    const url =
        'https://drive.google.com/file/d/abc123/view?resourcekey=key-123';
    expect(
      Uri.parse(DriveLinks.previewUrl(url)).queryParameters['resourcekey'],
      'key-123',
    );
    expect(
      Uri.parse(DriveLinks.downloadUrl(url)).queryParameters['resourcekey'],
      'key-123',
    );
  });
  test(
    'Drive confirmation accepts same public file and rejects hostile form or different ID',
    () {
      final uri = Uri.parse(
        'https://drive.usercontent.google.com/download?id=abc&export=download',
      );
      const body =
          '<form action="https://drive.usercontent.google.com/download"><input name="id" value="abc"><input name="confirm" value="t"><input name="uuid" value="123"></form>';
      expect(driveConfirmation(body, uri)!.queryParameters['uuid'], '123');
      expect(
        driveConfirmation(
          body.replaceAll('drive.usercontent.google.com', 'evil.example.org'),
          uri,
        ),
        isNull,
      );
      expect(
        driveConfirmation(
          body.replaceAll('value="abc"', 'value="different"'),
          uri,
        ),
        isNull,
      );
    },
  );
  test(
    'website header aliases and lectures import preserve hierarchy and skip repeats',
    () {
      final preview = validateImport(
        'Resource Type,Professional Year,Semester,Subject,Section,Topic,File Name,Link\nlectures,2nd Professional,Semester 1,Pharmacology,,ANS,Intro,https://youtu.be/abc',
        'lectures.csv',
      );
      expect(preview.errors, isEmpty);
      expect(preview.rows.single.lecture, true);
      expect(preview.rows.single.storageKey, 'pw_lectures_tree');
      final tree = <Map<String, dynamic>>[];
      var id = 0;
      expect(mergeLectureRows(tree, preview.rows, () => 'id${id++}').added, 1);
      expect(
        mergeLectureRows(tree, preview.rows, () => 'id${id++}').skipped,
        1,
      );
    },
  );
  test('JSON and XLSX parser normalize text and shared-string cells', () {
    final json = Uint8List.fromList(
      utf8.encode(
        '[{"kind":"notes","professional_year":"2nd Professional","semester":"Semester 1","subject":"Pharmacology","section":"Notes","topic":"ANS","title":"Intro","url":"https://example.org/a.pdf"}]',
      ),
    );
    expect(
      validateImport(dataFileCsv('rows.json', json), 'rows.json').valid,
      true,
    );
    final archive = Archive();
    void add(String n, String text) {
      final bytes = utf8.encode(text);
      archive.addFile(ArchiveFile(n, bytes.length, bytes));
    }

    add(
      'xl/sharedStrings.xml',
      '<sst><si><t>Subject</t></si><si><t>Pharmacology</t></si></sst>',
    );
    add(
      'xl/worksheets/sheet1.xml',
      '<worksheet><sheetData><row r="1"><c r="A1" t="s"><v>0</v></c></row><row r="2"><c r="A2" t="s"><v>1</v></c></row></sheetData></worksheet>',
    );
    final xlsx = Uint8List.fromList(ZipEncoder().encode(archive)!);
    expect(parseCsv(dataFileCsv('rows.xlsx', xlsx)), [
      ['Subject'],
      ['Pharmacology'],
    ]);
  });
  testWidgets('signup typing, keyboard resize and scroll retain field focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterPersonalScreen())),
    );
    final name = find.widgetWithText(TextField, 'Full name');
    await tester.showKeyboard(name);
    await tester.enterText(name, 'Ali Raza');
    await tester.pump();
    expect(tester.testTextInput.isVisible, true);
    expect(FocusManager.instance.primaryFocus!.hasFocus, true);
    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -90));
    await tester.pump();
    expect(tester.testTextInput.isVisible, true);
    expect((tester.widget<TextField>(name).controller!).text, 'Ali Raza');
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-width remote images have bounded finite decode sizes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: NetImage(
              'https://example.org/photo.jpg',
              width: double.infinity,
              height: 130,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'admin retries keep edits and submit only fields the admin touched',
    (tester) async {
      final saves = <Map<String, dynamic>>[];
      Widget form(String title) => MaterialApp(
        home: Scaffold(
          body: AdminForm(
            key: const ValueKey('form'),
            onlyChanged: true,
            fields: const [
              AdminField('title', 'Title'),
              AdminField('enabled', 'Enabled', type: 'bool'),
              AdminField('radius', 'Radius', type: 'number', fallback: 28),
            ],
            initial: {'title': title, 'enabled': true},
            onSave: (m) async {
              saves.add(m);
            },
          ),
        ),
      );
      await tester.pumpWidget(form('Original'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated by admin',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saves.single, {'title': 'Updated by admin'});
      await tester.pumpWidget(form('Remote change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saves.last, {'title': 'Updated by admin'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android Back dismisses a full-screen notice and keeps the app page',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPrefsProvider.overrideWithValue(prefs),
            authStateProvider.overrideWith(
              (ref) => Stream.value(NoticeTestUser()),
            ),
            isAdminProvider.overrideWithValue(false),
            documentHandoffProvider.overrideWith((ref) => false),
            siteSettingsProvider.overrideWithValue(
              SiteSettings({
                'fullScreenNotice': {
                  'id': 'back-test',
                  'enabled': true,
                  'title': 'Study update',
                  'body': 'New notes are available',
                  'repeat': 'once',
                },
              }),
            ),
          ],
          child: const MaterialApp(
            home: NoticeHost(child: Scaffold(body: Text('Study home'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Study update'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Study update'), findsNothing);
      expect(find.text('Study home'), findsOneWidget);
      expect(prefs.getBool('hyzen_notice_notice-student:back-test'), true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'product options retain structured choices and empty stock stays unlimited',
    (tester) async {
      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminForm(
              fields: const [
                AdminField('stockCount', 'Available stock', type: 'number'),
                AdminField('variants', 'Product options', type: 'variants'),
              ],
              initial: const {
                'stockCount': null,
                'variants': [
                  {
                    'name': 'Size',
                    'options': ['Small', 'Large'],
                  },
                ],
              },
              onSave: (v) async {
                saved = v;
              },
            ),
          ),
        ),
      );
      expect(find.text('Size: Small, Large'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(saved!['stockCount'], isNull);
      expect(saved!['variants'], [
        {
          'name': 'Size',
          'options': ['Small', 'Large'],
        },
      ]);
      await tester.enterText(
        find.byType(TextFormField).last,
        'Missing options separator',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Use one option per line'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
