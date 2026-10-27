import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyzen_pharmd/core/errors/app_error.dart';
import 'package:hyzen_pharmd/features/academics/data/drive_gateway.dart';
import 'package:hyzen_pharmd/features/downloads/data/file_store_io.dart';
import 'package:hyzen_pharmd/core/utils/validators.dart';

class ScriptClient extends http.BaseClient {
  ScriptClient(this.handler);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('missing Cloud configuration restores public delivery without OAuth', () async {
    final gateway = DriveGateway(apiKey: '', client: MockClient((_) async {
      fail('An unconfigured app must not issue a doomed API request.');
    }));
    final request = await gateway.resolve('https://drive.google.com/file/d/abc/view?resourcekey=shared-key');
    expect(request.publicFallback, isTrue);
    expect(request.headers, isEmpty);
    expect(request.uri.host, 'drive.usercontent.google.com');
    expect(request.uri.queryParameters['id'], 'abc');
    expect(request.uri.queryParameters['resourcekey'], 'shared-key');
  });
  test('disabled Drive API falls back but file permission errors remain enforced', () async {
    var calls = 0;
    final gateway = DriveGateway(apiKey: 'fixture-public-key', client: MockClient((_) async {
      calls++;
      return http.Response('{"error":{"status":"SERVICE_DISABLED"}}', 403);
    }));
    final request = await gateway.resolve('https://drive.google.com/file/d/abc/view');
    expect(request.publicFallback, isTrue);
    expect(request.headers, isEmpty);
    expect(request.uri.queryParameters.containsKey('key'), isFalse);
    await gateway.resolve('https://drive.google.com/file/d/def/view');
    expect(calls, 1);
    final denied = DriveGateway(apiKey: 'fixture-public-key', client: MockClient((_) async => http.Response('{"error":{"reason":"insufficientFilePermissions"}}', 403)));
    await expectLater(denied.resolve('https://drive.google.com/file/d/abc/view'),
      throwsA(isA<FriendlyException>().having((e) => e.code, 'code', 'drive-connect')));
  });
  test('public confirmation streams validated PDF into offline storage', () async {
    final dir = await Directory.systemTemp.createTemp('hyzen-public-');
    addTearDown(() => dir.delete(recursive: true));
    final pdf = utf8.encode('%PDF-1.7\npublic fixture content\n%%EOF');
    var calls = 0;
    final store = createFileStore(testDirectory: dir, clientFactory: () => ScriptClient((request) async {
      calls++;
      expect(request.headers.keys.map((k) => k.toLowerCase()), isNot(contains('authorization')));
      expect(request.url.queryParameters['id'], 'abc');
      if (calls == 1) {
        return http.StreamedResponse(Stream.value(utf8.encode('<form action="https://drive.usercontent.google.com/download"><input name="id" value="abc"><input name="confirm" value="ok"><input name="uuid" value="fixture"></form>')), 200,
          headers: {'content-type': 'text/html'});
      }
      expect(request.url.queryParameters['uuid'], 'fixture');
      return http.StreamedResponse(Stream.value(pdf), 200, contentLength: pdf.length,
        headers: {'content-type': 'application/pdf', 'etag': '"fixture-v1"'});
    }));
    final saved = await store.download('https://drive.google.com/file/d/abc/view', 'drive_abc', (_, __) {});
    expect(await File(saved.path).readAsBytes(), pdf);
    expect(calls, 2);
    await store.delete(saved.path);
    expect(calls, 2, reason: 'Deletion must only touch local storage.');
  });
  test('legacy IDs resolve to Drive v3 media without changing source', () {
    for (final url in [
      'https://drive.google.com/file/d/abc/view',
      'https://drive.google.com/open?id=abc',
      'https://drive.usercontent.google.com/download?id=abc',
    ]) {
      final uri = DriveGateway.endpoint(url);
      expect(uri.path, '/drive/v3/files/abc');
      expect(uri.queryParameters['alt'], 'media');
      expect(uri.toString(), isNot(contains('/preview')));
    }
    expect(
      DriveGateway.endpoint('https://docs.google.com/document/d/abc/edit').path,
      endsWith('/export'),
    );
  });
  test('phone error can recover with the supplied corrected number', () {
    expect(Validators.phone('306692796'), isNotNull);
    expect(Validators.phone('03066973691'), isNull);
    expect(PkPhone.normalize('۰۳۰۶۶۹۷۳۶۹۱'), '+923066973691');
    expect(PkPhone.normalize('+92 306 6973691'), '+923066973691');
  });
  test('interrupted downloads resume from validated offset and ETag', () async {
    final dir = await Directory.systemTemp.createTemp('hyzen-range-');
    addTearDown(() => dir.delete(recursive: true));
    final all = utf8.encode('%PDF-1.7\nfixture data for range test\n%%EOF');
    var calls = 0;
    final store = createFileStore(
      testDirectory: dir,
      clientFactory: () => ScriptClient((request) async {
        calls++;
        if (calls == 1) {
          final stream = Stream<List<int>>.multi((c) {
            c.add(all.sublist(0, 18));
            c.addError(const SocketException('lost'));
            c.close();
          });
          return http.StreamedResponse(
            stream,
            200,
            contentLength: all.length,
            headers: {'etag': '"v1"'},
          );
        }
        expect(request.headers['Range'], 'bytes=18-');
        expect(request.headers['If-Range'], '"v1"');
        return http.StreamedResponse(
          Stream.value(all.sublist(18)),
          206,
          contentLength: all.length - 18,
          headers: {
            'etag': '"v1"',
            'content-range': 'bytes 18-${all.length - 1}/${all.length}',
          },
        );
      }),
    );
    await expectLater(
      store.download('https://example.org/n.pdf', 'resume', (r, t) {}),
      throwsException,
    );
    final saved = await store.download(
      'https://example.org/n.pdf',
      'resume',
      (r, t) {},
    );
    expect(await File(saved.path).readAsBytes(), all);
    expect(calls, 2);
  });
  test('HTML and truncated PDF never become offline files', () async {
    final dir = await Directory.systemTemp.createTemp('hyzen-invalid-');
    addTearDown(() => dir.delete(recursive: true));
    for (final bytes in [
      '<html>Login needed</html>',
      '%PDF-1.7 missing end marker',
    ]) {
      final store = createFileStore(
        testDirectory: dir,
        clientFactory: () => ScriptClient(
          (_) async => http.StreamedResponse(
            Stream.value(utf8.encode(bytes)),
            200,
            contentLength: bytes.length,
          ),
        ),
      );
      await expectLater(
        store.download('https://example.org/n.pdf', 'bad', (r, t) {}),
        throwsException,
      );
    }
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });
}
