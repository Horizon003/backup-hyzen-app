// Browser-only review entrypoint. Renders the real app/routes with clearly
// labelled sample data; never used by lib/main.dart or Android builds.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'core/storage/local_store.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/student_profile.dart';
import 'features/content/data/content_source.dart';
import 'features/admin/domain/import_csv.dart';
import 'features/academics/domain/models.dart';
import 'features/downloads/data/downloads_controller.dart';
import 'features/downloads/domain/download_record.dart';
import 'features/home/data/recent_controller.dart';
import 'features/pdf_studio/data/pdf_studio_repository.dart';
import 'features/pdf_studio/data/studio_file_item.dart';

const reviewProfile = StudentProfile(
  uid: 'ui-review-student',
  fullName: 'Muhammad Haris',
  mobile: '+923001234567',
  gender: 'male',
  city: 'Pattoki',
  professionalYear: 2,
  institutionName: 'Quaid-e-Azam College of Pharmacy',
  affiliationStatus: AffiliationStatus.nonAffiliated,
  email: 'student@example.com',
  rollNumber: 'DP-2420',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Boxes.init();
  // Review-only URL overrides use the same persisted theme preference as the app.
  final reviewTheme = Uri.base.queryParameters['theme'];
  if (reviewTheme == 'light' || reviewTheme == 'dark') {
    await prefs.setString('theme_mode', reviewTheme!);
  }
  final requestedPath = Uri.base.fragment;
  final initialPath =
      const [
        '/welcome',
        '/login',
        '/forgot-password',
        '/profile',
        '/profile/info',
        '/profile/edit',
        '/settings',
        '/home',
        '/study',
        '/study/notes',
        '/study/special',
        '/study/mcqs',
        '/study/papers',
        '/pdf-studio',
        '/shop',
        '/downloads',
        '/search',
      ].contains(requestedPath)
      ? requestedPath
      : '/profile';
  // Auth previews are signed out only in this isolated sample-data entrypoint.
  final guestPreview = const [
    '/welcome',
    '/login',
    '/forgot-password',
  ].contains(initialPath);
  final emptyHome = Uri.base.queryParameters['scenario'] == 'empty';
  final tree = <Map<String, dynamic>>[];
  var id = 0;
  if (!emptyHome) {
    mergeRows(
      tree,
      validateImport(
        'kind,professional_year,semester,subject,section,topic,title,url,published\n'
            'notes,2nd Professional,Semester 1,Pharmaceutical Chemistry and Medicinal Compounds 2A,Study Notes,Revision,Pharmaceutical Chemistry comprehensive examination revision notes,https://example.org/review-notes.pdf,true\n'
            'notes,2nd Professional,Semester 1,Physical Pharmacy,Study Notes,Revision,Physical Pharmacy,https://example.org/review-physical.pdf,true\n'
            'notes,2nd Professional,Semester 1,Functional English,Study Notes,Revision,Functional English,https://example.org/review-english.pdf,true\n'
            'notes,2nd Professional,Semester 1,Pharmacology,Study Notes,Revision,Pharmacology,https://example.org/review-pharmacology.pdf,true',
        'review.csv',
      ).rows,
      () => 'review-${id++}',
    );
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        downloadsProvider.overrideWith(() => _ReviewDownloads(emptyHome)),
        recentProvider.overrideWith(() => _ReviewRecent(emptyHome)),
        pdfStudioHistoryProvider.overrideWith(() => _ReviewOffice(emptyHome)),
        authStateProvider.overrideWith(
          (ref) => Stream<User?>.value(guestPreview ? null : _ReviewUser()),
        ),
        authRepositoryProvider.overrideWithValue(_ReviewAuth()),
        profileProvider.overrideWith((ref) {
          if (guestPreview) return Stream<StudentProfile?>.value(null);
          final cached = ref
              .read(pendingProfileStoreProvider)
              .cached(reviewProfile.uid);
          return Stream.value(
            cached == null
                ? reviewProfile
                : StudentProfile.fromMap(reviewProfile.uid, cached),
          );
        }),
        contentProvider.overrideWith(
          (ref, key) => Stream.value(
            ContentSnapshot(
              value: key == 'pw_settings'
                  ? <String, dynamic>{}
                  : key == 'pw_notes_tree'
                  ? tree
                  : key == 'pw_announcement' && !emptyHome
                  ? {
                      'enabled': true,
                      'text': 'Made By Haris (Horizon) with pure Love ❤️',
                    }
                  : [],
              fromCache: false,
            ),
          ),
        ),
      ],
      child: _ReviewApp(initialPath: initialPath),
    ),
  );
}

class _ReviewApp extends ConsumerStatefulWidget {
  const _ReviewApp({required this.initialPath});
  final String initialPath;
  @override
  ConsumerState<_ReviewApp> createState() => _ReviewAppState();
}

class _ReviewAppState extends ConsumerState<_ReviewApp> {
  bool _opened = false;
  @override
  Widget build(BuildContext context) {
    if (!_opened && ref.watch(authStateProvider).hasValue) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(routerProvider).go(widget.initialPath);
      });
    }
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: ColoredBox(
              color: Color(0xFF38383D),
              child: Center(
                child: Text(
                  'UI PREVIEW · SAMPLE DATA',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _ReviewScaledApp()),
        ],
      ),
    );
  }
}

// Only fixture adapters live here. No review credentials or cloud writes.
class _ReviewUser implements User {
  @override
  String get uid => reviewProfile.uid;
  @override
  String? get displayName => reviewProfile.fullName;
  @override
  String? get email => reviewProfile.email;
  @override
  String? get photoURL => null;
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewAuth implements AuthRepository {
  @override
  Future<void> sendReset(String email) async => throw UnsupportedError(
    'Use the normal app preview with your own account for authentication actions.',
  );
  @override
  Future<void> signOut() async => throw UnsupportedError(
    'This UI review uses sample data; there is no authenticated session.',
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReviewScaledApp extends StatelessWidget {
  const _ReviewScaledApp();
  @override
  Widget build(BuildContext context) {
    final scale =
        (double.tryParse(Uri.base.queryParameters['textScale'] ?? '') ?? 1)
            .clamp(1.0, 2.0)
            .toDouble();
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations:
                Uri.base.queryParameters['reduceMotion'] == 'true' ||
                MediaQuery.disableAnimationsOf(context),
          ),
          child: const HyzenApp(),
        ),
      ),
    );
  }
}

class _ReviewDownloads extends DownloadsController {
  _ReviewDownloads(this.empty);
  final bool empty;
  @override
  Map<String, DownloadRecord> build() => empty
      ? {}
      : {
          for (var i = 0; i < 5; i++)
            'sample-$i': DownloadRecord(
              key: 'sample-$i',
              kind: LibraryKind.notes,
              title: 'Sample academic document ${i + 1}',
              sourceUrl: 'https://example.org/sample-$i.pdf',
              status: i < 2 ? DownloadStatus.downloading : DownloadStatus.ready,
              progress: i < 2 ? .45 : 1,
              sizeBytes: 450000,
              totalBytes: 1000000,
              localPath: i < 2 ? null : '/sample-data/sample-$i.pdf',
              savedAt: i < 2 ? null : DateTime(2026, 1, 1),
              unopened: i == 2,
            ),
        };
  @override
  Future<void> remove(String key) async =>
      throw UnsupportedError('Sample data preview');
  @override
  Future<void> removeAll() async =>
      throw UnsupportedError('Sample data preview');
  // Sample files cannot be downloaded or deleted from the public UI review.
  @override
  Future<void> save(FileRef file, {String? localPreview}) => Future.error(
    UnsupportedError(
      'Sample data preview; open the Android app to save real files.',
    ),
  );
}

class _ReviewOffice extends PdfStudioRepository {
  _ReviewOffice(this.empty);
  final bool empty;
  @override
  List<StudioFileItem> build() => empty
      ? []
      : [
          for (final (i, title) in [
            'Pharmacology revision notes',
            'Practical notebook · Semester 2',
            'Surgical dressings',
          ].indexed)
            StudioFileItem(
              id: 'review-office-$i',
              originalFileName: '$title.pdf',
              displayName: '$title.pdf',
              internalFilePath: '/sample-data/office-$i.pdf',
              editStateJsonPath: '',
              sourceType: 'IMAGE_SCAN',
              fileCategory: 'PDF',
              fileSizeBytes: 240000 + i * 80000,
              pageCount: 3 + i,
              createdAt: DateTime(2026, 11, 6),
              updatedAt: DateTime(2026, 11, 6),
              operationBadge: 'SCANNED',
            ),
        ];
}

class _ReviewRecent extends RecentController {
  _ReviewRecent(this.empty);
  final bool empty;
  @override
  Future<void> clear() async {
    state = [];
  }

  @override
  List<RecentItem> build() => empty
      ? []
      : [
          RecentItem(
            const FileRef(
              kind: LibraryKind.notes,
              title:
                  'Pharmaceutical Chemistry comprehensive examination revision notes — semester two',
              url: 'https://example.org/review-notes.pdf',
            ),
            DateTime(2026, 1, 3),
          ),
          RecentItem(
            const FileRef(
              kind: LibraryKind.notes,
              title: 'Physical Pharmacy · Surface phenomena',
              url: 'https://example.org/review-physical.pdf',
            ),
            DateTime(2026, 1, 2),
          ),
        ];
}
