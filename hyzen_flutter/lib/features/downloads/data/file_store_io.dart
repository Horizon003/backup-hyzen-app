import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../viewer/office_document.dart';
import '../../academics/data/drive_gateway.dart';
import '../../../core/errors/app_error.dart';
import '../domain/document_type.dart';
import '../domain/drive_confirmation.dart';
import 'file_store.dart';

FileStore createFileStore({
  Directory? testDirectory,
  http.Client Function()? clientFactory,
}) => _IoFileStore(testDirectory, clientFactory);

class _IoFileStore implements FileStore {
  _IoFileStore(this.testDirectory, this.clientFactory);
  final Directory? testDirectory;
  final http.Client Function()? clientFactory;
  @override
  bool get supported => true;

  Future<Directory> _dir() async {
    final base = testDirectory ?? await getApplicationSupportDirectory();
    final d = Directory('${base.path}/offline_docs');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  String _safe(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  @override
  Future<DownloadedFile> download(
    String url,
    String key,
    ProgressCb onProgress, {
    bool Function()? cancelled,
  }) async {
    final source = Uri.tryParse(url);
    if (source == null ||
        source.scheme != 'https' ||
        source.userInfo.isNotEmpty) {
      throw FriendlyException('Use a valid HTTPS document link.');
    }
    var request = await DriveGateway.instance.resolve(url);
    final dir = await _dir();
    final base = '${dir.path}/${_safe(key)}';
    final part = File('$base.part');
    final journal = File('$base.resume.json');
    Map<String, dynamic> previous = {};
    if (await journal.exists()) {
      try {
        previous = (jsonDecode(await journal.readAsString()) as Map)
            .cast<String, dynamic>();
      } catch (_) {}
    }
    var offset = await part.exists() ? await part.length() : 0;
    final hasValidator =
        previous['etag'] != null || (request.version?.isNotEmpty == true);
    if (previous['source'] != url ||
        previous['version'] != request.version ||
        !hasValidator) {
      offset = 0;
    }
    final client = clientFactory?.call() ?? http.Client();
    IOSink? sink;
    var invalid = false;
    final cancelTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (cancelled?.call() == true) client.close();
    });
    try {
      if (cancelled?.call() == true) {
        throw FriendlyException('Download paused.');
      }
      var response = await client
          .send(
            http.Request('GET', request.uri)
              ..headers.addAll({
                ...request.headers,
                'Accept-Encoding': 'identity',
                if (offset > 0) 'Range': 'bytes=$offset-',
                if (offset > 0 && previous['etag'] != null)
                  'If-Range': '${previous['etag']}',
              }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 416 && offset > 0) {
        await response.stream.drain<void>();
        offset = 0;
        response = await client
            .send(
              http.Request('GET', request.uri)
                ..headers.addAll({
                  ...request.headers,
                  'Accept-Encoding': 'identity',
                }),
            )
            .timeout(const Duration(seconds: 30));
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        final body = await response.stream.bytesToString();
        final error = DriveGateway.errorFor(response.statusCode, body);
        if (error.code != 'drive-config' || request.publicFallback) throw error;
        request = DriveGateway.publicRequest(url);
        offset = 0;
        response = await client.send(http.Request('GET', request.uri)
          ..headers['Accept-Encoding'] = 'identity')
            .timeout(const Duration(seconds: 30));
      }
      if (request.publicFallback &&
          (response.headers['content-type'] ?? '').toLowerCase().contains('text/html')) {
        // Drive can return a confirmation page for a large public download.
        // Read a bounded form once; never save HTML or forward auth credentials.
        final form = <int>[];
        await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
          if (form.length + chunk.length > 1024 * 1024) {
            invalid = true;
            throw FriendlyException('This file is not available for offline saving.');
          }
          form.addAll(chunk);
        }
        final confirmed = driveConfirmation(utf8.decode(form, allowMalformed: true), request.uri);
        if (confirmed == null) {
          invalid = true;
          throw FriendlyException('Offline saving is unavailable. Check that this file allows downloading.');
        }
        offset = 0;
        response = await client.send(http.Request('GET', confirmed)
          ..headers['Accept-Encoding'] = 'identity')
            .timeout(const Duration(seconds: 30));
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw DriveGateway.errorFor(response.statusCode);
      }
      final range = RegExp(
        r'^bytes (\d+)-(\d+)/(\d+)$',
      ).firstMatch(response.headers['content-range'] ?? '');
      if (response.statusCode == 206 &&
          (range == null || int.parse(range[1]!) != offset)) {
        invalid = true;
        throw FriendlyException(
          'The server returned an invalid download range. Retry.',
        );
      }
      if (response.statusCode == 200) offset = 0;
      final total = range == null
          ? response.contentLength
          : int.parse(range[3]!);
      const maxBytes = 250 * 1024 * 1024;
      if ((total ?? 0) > maxBytes) {
        throw FriendlyException('This file exceeds the 250 MB limit.');
      }
      final etag = response.headers['etag'];
      if (offset > 0 &&
          previous['etag'] != null &&
          etag != null &&
          etag != previous['etag']) {
        invalid = true;
        throw FriendlyException(
          'This file changed. Retry to save the latest copy.',
        );
      }
      await journal.writeAsString(
        jsonEncode({
          'source': url,
          'version': request.version,
          if (etag != null) 'etag': etag,
          'total': total,
        }),
      );
      sink = part.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var received = offset;
      final head = offset > 0
          ? await part
                .openRead(0, offset < 1024 ? offset : 1024)
                .fold<List<int>>([], (a, b) => a..addAll(b))
          : <int>[];
      onProgress(received, total);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 45),
      )) {
        if (cancelled?.call() == true) {
          throw FriendlyException('Download paused.');
        }
        if (head.length < 1024) head.addAll(chunk.take(1024 - head.length));
        if (head.length >= 16 && documentExtension(head) == null) {
          invalid = true;
          throw FriendlyException('This response is not a supported document.');
        }
        received += chunk.length;
        if (received > maxBytes) {
          invalid = true;
          throw FriendlyException('This file exceeds the 250 MB limit.');
        }
        sink.add(chunk);
        onProgress(received, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (cancelled?.call() == true) {
        throw FriendlyException('Download paused.');
      }
      if (total != null && received != total) {
        throw FriendlyException('Connection interrupted. Tap Resume.');
      }
      final extension = documentExtension(head);
      if (extension == null) {
        invalid = true;
        throw FriendlyException('This is not a valid document.');
      }
      if (extension == 'pdf') {
        final start = received > 2048 ? received - 2048 : 0;
        final tail = await part
            .openRead(start)
            .fold<List<int>>([], (a, b) => a..addAll(b));
        if (!String.fromCharCodes(tail).contains('%%EOF')) {
          invalid = true;
          throw FriendlyException(
            'The PDF is incomplete or damaged. Please retry.',
          );
        }
      }
      if (extension == 'pdf' && Platform.isAndroid) {
        try {
          final pages = await const MethodChannel(
            'com.hyzen.pharmd/pdf_studio',
          ).invokeMethod<int>('pageCount', {'path': part.path});
          if (pages == null || pages < 1) {
            throw const FormatException('Invalid PDF');
          }
        } catch (_) {
          invalid = true;
          throw FriendlyException(
            'This PDF is damaged or password-protected. It was not saved.',
          );
        }
      }
      if (extension == 'office' || extension == 'legacy') {
        if (received > 50 * 1024 * 1024) {
          throw FriendlyException('Office notes exceed the 50 MB limit.');
        }
        try {
          await compute(officePages, await part.readAsBytes());
        } catch (_) {
          invalid = true;
          throw FriendlyException('This Office document could not be read.');
        }
      }
      final target = File('$base.$extension');
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      if (await journal.exists()) await journal.delete();
      return DownloadedFile(target.path, received);
    } on FriendlyException {
      rethrow;
    } catch (_) {
      throw FriendlyException(
        cancelled?.call() == true
            ? 'Download paused.'
            : 'Connection interrupted. Tap Resume.',
      );
    } finally {
      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {}
      cancelTimer.cancel();
      client.close();
      // Network interruptions and pause retain partial bytes. Never mark them ready.
      if (invalid) {
        if (await part.exists()) await part.delete();
        if (await journal.exists()) await journal.delete();
      }
    }
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<DownloadedFile> importPreview(String path, String key) async {
    final directory = await _dir();
    final source = File(path);
    final root = await directory.resolveSymbolicLinks();
    final resolved = await source.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/preview_')) {
      throw FriendlyException('Preview is unavailable.');
    }
    final target = File(
      '${directory.path}/${_safe(key)}.${source.path.split('.').last}',
    );
    await source.copy(target.path);
    return DownloadedFile(target.path, await target.length());
  }

  @override
  Future<void> discardPartial(String key) async {
    final directory = await _dir();
    for (final suffix in ['.part', '.resume.json']) {
      final file = File('${directory.path}/${_safe(key)}$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> delete(String path) async {
    final root = await _dir();
    final file = File(path);
    if (!await file.exists()) return;
    final resolved = await file.resolveSymbolicLinks();
    if (!resolved.startsWith('${await root.resolveSymbolicLinks()}/')) {
      throw FriendlyException('Only app-managed copies can be removed.');
    }
    await file.delete();
  }

  @override
  Future<void> clearAll() async {
    final directory = await _dir();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
