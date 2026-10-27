import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:archive/archive.dart';
import 'package:hyzen_pharmd/features/downloads/data/file_store_io.dart';
import 'package:hyzen_pharmd/features/downloads/domain/document_type.dart';
import 'package:hyzen_pharmd/features/viewer/office_document.dart';
import 'package:hyzen_pharmd/features/updates/update_manifest.dart';
import 'package:hyzen_pharmd/features/academics/domain/drive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Drive Office notes use PDF export and retain resource keys', () {
    final url = DriveLinks.downloadUrl(
      'https://drive.google.com/file/d/test-file/view?resourcekey=abc',
      title: 'HLB system.pptx',
    );
    expect(
      url,
      contains('docs.google.com/presentation/d/test-file/export/pdf'),
    );
    expect(Uri.parse(url).queryParameters['resourcekey'], 'abc');
    expect(DriveLinks.offlineKey(url), 'drive_test-file');
  });
  test('types are selected from bytes, HTML is never a document', () {
    expect(documentExtension(utf8.encode('%PDF-1.7\n')), 'pdf');
    expect(documentExtension([137, 80, 78, 71, 13, 10, 26, 10]), 'png');
    expect(documentExtension([255, 216, 255, 0]), 'jpg');
    expect(documentExtension(utf8.encode('<html>Sign in</html>')), isNull);
  });
  test('Office text reader handles slide number order and Word paragraphs', () {
    final a = Archive();
    for (final i in [10, 2, 1]) {
      final xml = utf8.encode('<root><p><t>Slide $i</t></p></root>');
      a.addFile(ArchiveFile('ppt/slides/slide$i.xml', xml.length, xml));
    }
    expect(officePages(Uint8List.fromList(ZipEncoder().encode(a)!)), [
      'Slide 1',
      'Slide 2',
      'Slide 10',
    ]);
    final b = Archive();
    final xml = utf8.encode('<root><p><t>Diabetes notes</t></p></root>');
    b.addFile(ArchiveFile('word/document.xml', xml.length, xml));
    expect(officePages(Uint8List.fromList(ZipEncoder().encode(b)!)), [
      'Diabetes notes',
    ]);
  });
  test(
    'update config rejects missing hash, HTTP, credentials, impossible version',
    () {
      final m = <String, dynamic>{
        'androidLatestVersionCode': 4,
        'androidVersionName': '1.2.1',
        'androidApkUrl': 'https://example.com/app.apk',
        'androidSha256': 'a' * 64,
        'androidMinVersionCode': 3,
      };
      expect(UpdateManifest.parse(m)!.requiredFor(2), isTrue);
      expect(UpdateManifest.parse(m)!.requiredFor(3), isFalse);
      expect(
        UpdateManifest.parse({...m, 'androidLatestVersionCode': 4.0})!.code,
        4,
      );
      for (final bad in [
        <String, dynamic>{'androidSha256': 'wrong'},
        <String, dynamic>{'androidApkUrl': 'http://example.com/a.apk'},
        <String, dynamic>{
          'androidApkUrl': 'https://user:pass@example.com/a.apk',
        },
        <String, dynamic>{'androidMinVersionCode': 5},
      ]) {
        expect(UpdateManifest.parse({...m, ...bad}), isNull);
      }
    },
  );
  test(
    'PDF download finalized and reopens from disk after client is gone',
    () async {
      final dir = await Directory.systemTemp.createTemp('hyzen-test-');
      try {
        final store = createFileStore(
          testDirectory: dir,
          clientFactory: () => MockClient(
            (r) async => http.Response(
              '%PDF-1.7\nfixture\n%%EOF',
              200,
              headers: {'content-type': 'application/pdf'},
            ),
          ),
        );
        final result = await store.download(
          'https://example.com/file',
          'id',
          (r, t) {},
        );
        expect(await File(result.path).readAsString(), startsWith('%PDF-'));
        expect(result.path, endsWith('.pdf'));
        expect(await store.exists(result.path), isTrue);
        expect(
          dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.part')),
          isEmpty,
        );
        await store.delete(result.path);
        expect(await store.exists(result.path), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'JPG saves with image renderer extension rather than forced PDF',
    () async {
      final dir = await Directory.systemTemp.createTemp('hyzen-test-');
      try {
        final store = createFileStore(
          testDirectory: dir,
          clientFactory: () => MockClient(
            (r) async =>
                http.Response.bytes([255, 216, 255, 0, 0, 0, 0, 0, 0], 200),
          ),
        );
        expect(
          (await store.download(
            'https://example.com/x',
            'image',
            (r, t) {},
          )).path,
          endsWith('.jpg'),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test(
    'HTML, unsupported bytes and cancellation never leave ready files',
    () async {
      final dir = await Directory.systemTemp.createTemp('hyzen-test-');
      try {
        for (final body in ['<html>Login</html>', 'not-a-file']) {
          final store = createFileStore(
            testDirectory: dir,
            clientFactory: () =>
                MockClient((r) async => http.Response(body, 200)),
          );
          await expectLater(
            store.download('https://example.com/x', 'bad', (r, t) {}),
            throwsA(anything),
          );
        }
        final store = createFileStore(
          testDirectory: dir,
          clientFactory: () =>
              MockClient((r) async => http.Response('%PDF-1.7', 200)),
        );
        await expectLater(
          store.download(
            'https://example.com/x',
            'cancel',
            (r, t) {},
            cancelled: () => true,
          ),
          throwsA(anything),
        );
        expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
