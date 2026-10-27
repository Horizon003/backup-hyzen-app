import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hyzen_pharmd/features/auth/domain/student_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyzen_pharmd/app/app.dart';
import 'package:hyzen_pharmd/app/providers.dart';
import 'package:hyzen_pharmd/app/router.dart';
import 'package:hyzen_pharmd/core/storage/local_store.dart';
import 'package:hyzen_pharmd/features/admin/domain/import_csv.dart';
import 'package:hyzen_pharmd/features/admin/data/admin_repository.dart';
import 'package:hyzen_pharmd/features/content/data/content_source.dart';
import 'package:hyzen_pharmd/features/content/data/content_providers.dart';
import 'package:hyzen_pharmd/features/academics/domain/models.dart';
import 'package:hyzen_pharmd/features/viewer/external_files.dart';
import 'package:hyzen_pharmd/core/widgets/hyzen_art.dart';

class StudentUser extends Fake implements User {
  @override
  String get uid => 'student-test';
  @override
  String? get displayName => 'Test Student';
  @override
  String? get email => 'student@example.org';
  @override
  String? get photoURL => null;
}

void main() {
  late Directory temp;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late List<Map<String, dynamic>> fixtureTree;
  setUpAll(() async {
    final fonts = FontLoader('Manrope');
    for (final weight in [400, 500, 600, 700, 800]) {
      fonts.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
    }
    await fonts.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    temp = await Directory.systemTemp.createTemp('hyzen-widget-test-');
    Hive.init(temp.path);
    for (final box in [
      Boxes.contentCache,
      Boxes.downloads,
      Boxes.recent,
      Boxes.cart,
      Boxes.myOrders,
      Boxes.externalHistory,
      Boxes.pdfStudioHistory,
    ]) {
      await Hive.openBox<String>(box);
    }
    final tree = <Map<String, dynamic>>[];
    var id = 0;
    mergeRows(
      tree,
      validateImport(
        'kind,professional_year,semester,subject,section,topic,title,url,published\nnotes,2nd Professional,Semester 1,Pharmacology,Study Notes,Diabetes,Insulin Notes,https://example.org/a.pdf,true',
        'fixture.csv',
      ).rows,
      () => 'id-${id++}',
    );
    fixtureTree = tree;
    container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => Stream.value(StudentUser())),
        profileProvider.overrideWith(
          (ref) => Stream.value(
            const StudentProfile(
              uid: 'student-test',
              fullName: 'Ali Raza',
              mobile: '+923001234567',
              gender: 'male',
              city: 'Lahore',
              professionalYear: 2,
              institutionName: 'College of Pharmacy',
              affiliationStatus: AffiliationStatus.nonAffiliated,
              email: 'student@example.org',
            ),
          ),
        ),
        adminTreeProvider.overrideWith(
          (ref, kind) async => copyTree(tree, kind),
        ),
        contentProvider.overrideWith(
          (ref, key) => Stream.value(
            ContentSnapshot(
              value: key == 'pw_notes_tree'
                  ? tree
                  : key == 'pw_settings'
                  ? {'shopComingSoon': false}
                  : key == 'pw_about'
                  ? {'about': '<p>Welcome to Hyzen</p>'}
                  : key == 'pw_blogs'
                  ? [
                      {
                        'id': 'b1',
                        'title': 'Student tips',
                        'status': 'published',
                        'contentHtml': '<p>Study consistently.</p>',
                      },
                    ]
                  : [],
              fromCache: false,
            ),
          ),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  Future<void> open(WidgetTester tester, String path) async {
    await tester.runAsync(
      () => Future.wait([
        for (final k in LibraryKind.values)
          container.read(parsedLibraryProvider(k).future),
      ]),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HyzenApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go(path);
    await tester.pumpAndSettle();
  }

  testWidgets('all app sections load real screens', (tester) async {
    for (final path in [
      '/home',
      '/study',
      '/search',
      '/pdf-studio',
      '/downloads',
      '/profile',
    ]) {
      await open(tester, path);
      expect(tester.takeException(), isNull, reason: path);
      expect(find.textContaining('Screen coming soon'), findsNothing);
    }
  });
  testWidgets('reference dock opens the Study popover and Downloads', (
    tester,
  ) async {
    await open(tester, '/home');
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('main-dock')), findsOneWidget);
    await tester.tap(find.byTooltip('Study'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Downloads').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Downloads').last);
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/downloads',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow phone layouts and large text remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final path in [
      '/home',
      '/study',
      '/search',
      '/downloads',
      '/profile',
    ]) {
      await open(tester, path);
      expect(tester.takeException(), isNull, reason: path);
    }
  });
  testWidgets('every library level resolves through the router', (
    tester,
  ) async {
    await open(tester, '/study/notes/id-0/id-1/id-2/id-3/id-4');
    expect(find.text('Insulin Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('blog, about, contact and safe missing viewer render', (
    tester,
  ) async {
    for (final path in [
      '/blog',
      '/blog/b1',
      '/about',
      '/contact',
      '/viewer',
      '/settings',
      '/shop',
      '/cart',
      '/orders',
    ]) {
      await open(tester, path);
      expect(tester.takeException(), isNull, reason: path);
    }
  });
  testWidgets(
    'Android back returns to Home from a tab and pops one library level',
    (tester) async {
      await open(tester, '/study');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/home',
      );
      await open(tester, '/study/notes/id-0/id-1/id-2');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/study/notes/id-0/id-1',
      );
      await open(tester, '/home');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keep studying'), findsOneWidget);
      await tester.tap(find.text('Keep studying'));
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        '/home',
      );
    },
  );
  testWidgets('Android back from Settings stays in the app and returns Home', (
    tester,
  ) async {
    await open(tester, '/settings');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Android back from Create PDF returns to the workspace', (tester) async {
    const camera = MethodChannel('com.hyzen.pharmd/camera_pages');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(camera, (_) async => <String>[]);
    addTearDown(() => messenger.setMockMethodCallHandler(camera, null));
    await open(tester, '/pdf-studio');
    container.read(routerProvider).push('/create-pdf');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).routeInformationProvider.value.uri.path, '/pdf-studio');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'external history id resolves without route extras or a signed-in account',
    (tester) async {
      final guest = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          profileProvider.overrideWith((ref) => Stream.value(null)),
          contentProvider.overrideWith(
            (ref, key) => Stream.value(
              const ContentSnapshot(value: {}, fromCache: false),
            ),
          ),
        ],
      );
      addTearDown(guest.dispose);
      await tester.runAsync(
        () => guest
            .read(externalHistoryProvider.notifier)
            .add(
              ExternalDocument(
                'fixture-id',
                'External lecture.txt',
                '/tmp/external-lecture.txt',
                DateTime.now(),
              ),
            ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(container: guest, child: const HyzenApp()),
      );
      await tester.pumpAndSettle();
      guest.read(routerProvider).go('/imported-viewer?id=fixture-id');
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('External lecture.txt'), findsOneWidget);
      expect(find.text('This page could not be found'), findsNothing);
      expect(
        guest.read(routerProvider).routeInformationProvider.value.uri.path,
        '/imported-viewer',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('compact banner keeps its artwork beside text on a 360px phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, '/home');
    final greeting = find.text('Welcome back, Ali');
    final image = find.byWidgetPredicate(
      (w) => w is HyzenArt && w.name == 'home',
    );
    expect(greeting, findsOneWidget);
    expect(image, findsOneWidget);
    expect(
      tester.getRect(image).left,
      greaterThan(tester.getRect(greeting).left),
    );
    expect(
      tester.getRect(image).top,
      lessThan(tester.getRect(greeting).bottom + 35),
    );
    expect(tester.takeException(), isNull);
  });
  test(
    'academic content switches when a student changes professional year',
    () async {
      final selectedYear = StateProvider<int>((ref) => 2);
      final academic = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) => Stream.value(null)),
          professionalYearProvider.overrideWith(
            (ref) => ref.watch(selectedYear),
          ),
          isAdminProvider.overrideWithValue(false),
          contentProvider.overrideWith(
            (ref, key) => Stream.value(
              ContentSnapshot(
                value: key == 'pw_lectures_tree'
                    ? [
                        {
                          'id': 'year1',
                          'label': '1st Professional',
                          'semesters': [],
                        },
                        {
                          'id': 'year2',
                          'label': '2nd Professional',
                          'semesters': [],
                        },
                      ]
                    : [
                        {
                          'id': 'year1',
                          'label': '1st Professional',
                          'semesters': [],
                        },
                        {
                          'id': 'year2',
                          'label': '2nd Professional',
                          'semesters': [],
                        },
                      ],
                fromCache: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(academic.dispose);
      final subscription = academic.listen(
        libraryProvider(LibraryKind.notes),
        (_, __) {},
      );
      addTearDown(subscription.close);
      await academic.read(parsedLibraryProvider(LibraryKind.notes).future);
      expect(
        academic
            .read(libraryProvider(LibraryKind.notes))
            .value!
            .data
            .years
            .single
            .id,
        'year2',
      );
      await academic.read(contentProvider('pw_lectures_tree').future);
      expect(academic.read(lecturesProvider).value!.data.single.id, 'year2');
      academic.read(selectedYear.notifier).state = 1;
      expect(
        academic
            .read(libraryProvider(LibraryKind.notes))
            .value!
            .data
            .years
            .single
            .id,
        'year1',
      );
    },
  );
  testWidgets(
    'completed student profile is retained without a repeat completion prompt',
    (tester) async {
      await open(tester, '/profile');
      expect(find.text('Ali Raza'), findsWidgets);
      expect(find.text('Complete your profile'), findsNothing);
      expect(find.textContaining('synced on this device'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('student cannot enter admin routes', (tester) async {
    await open(tester, '/admin/import');
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
  });
  testWidgets('small phone home layout supports larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HyzenApp()),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('admin settings, import template and content editor render', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final admin = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authStateProvider.overrideWith((ref) => Stream.value(StudentUser())),
        profileProvider.overrideWith((ref) => Stream.value(null)),
        isAdminProvider.overrideWithValue(true),
        adminValueProvider.overrideWith(
          (ref, key) => Stream.value(
            key == 'pw_credits'
                ? {'cards': [], 'layout': 'stack'}
                : key == 'pw_settings'
                ? {'shopComingSoon': false}
                : key == 'pw_lectures_tree'
                ? fixtureTree
                : key == 'pw_products' ||
                      key == 'pw_orders' ||
                      key == 'pw_messages' ||
                      key == 'pw_blogs' ||
                      key == 'pw_social' ||
                      key == 'pw_import_history'
                ? []
                : {},
          ),
        ),
        contentProvider.overrideWith(
          (ref, key) => Stream.value(
            ContentSnapshot(
              value: key == 'pw_settings' ? {'shopComingSoon': false} : [],
              fromCache: false,
            ),
          ),
        ),
        adminTreeProvider.overrideWith(
          (ref, kind) async => copyTree(fixtureTree, kind),
        ),
      ],
    );
    addTearDown(admin.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: admin, child: const HyzenApp()),
    );
    await tester.pumpAndSettle();
    for (final path in [
      '/admin',
      '/admin/stats',
      '/admin/manage/products',
      '/admin/manage/orders',
      '/admin/manage/messages',
      '/admin/manage/credits',
      '/admin/manage/social',
      '/admin/manage/blogs',
      '/admin/manage/lectures',
      '/admin/manage/settings',
      '/admin/manage/announcement',
      '/admin/manage/notice',
      '/admin/manage/catalog',
      '/admin/manage/delivery',
      '/admin/manage/data',
      '/admin/manage/history',
      '/admin/manage/theme',
      '/admin/manage/connection',
      '/admin/sections',
      '/admin/import',
      '/admin/content/notes',
    ]) {
      admin.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      if (path == '/admin' && const bool.fromEnvironment('HYZEN_CAPTURE_QA')) {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          admin.read(themeModeProvider.notifier).set(mode);
          await tester.pumpAndSettle();
          await expectLater(find.byType(HyzenApp), matchesGoldenFile('../qa/${mode.name}_admin.png'));
        }
        admin.read(themeModeProvider.notifier).set(ThemeMode.system);
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('2nd Professional'), findsOneWidget);
  });
  if (const bool.fromEnvironment('HYZEN_CAPTURE_QA')) {
    testWidgets('representative screens visual QA', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.read(themeModeProvider.notifier).set(mode);
        for (final path in [
          '/home',
          '/study',
          '/pdf-studio',
          '/study/notes/id-0/id-1/id-2/id-3/id-4',
          '/downloads',
          '/profile',
          '/contact',
          '/settings',
          '/about',
        ]) {
          await open(tester, path);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)),
          );
          await tester.pump();
          await expectLater(
            find.byType(HyzenApp),
            matchesGoldenFile(
              '../qa/${mode.name}${path.replaceAll('/', '_')}.png',
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
