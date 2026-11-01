import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'studio_storage_contract.dart';

StudioStorage createStudioStorage() => _IoStudioStorage();

class _IoStudioStorage implements StudioStorage {
  Future<Directory> _workspace() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/pdf_studio/workspace');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _stateDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/pdf_studio/state');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<StoredStudioFile> importCopy(String sourcePath, String id) async {
    final source = File(sourcePath);
    if (!await source.exists()) throw FileSystemException('Source file missing');
    final ext = source.uri.pathSegments.last.split('.').length > 1
        ? source.uri.pathSegments.last.split('.').last.toLowerCase()
        : 'pdf';
    if (!{
      'pdf', 'ppt', 'pptx', 'pptm', 'doc', 'docx', 'xls', 'xlsx',
      'txt', 'md', 'rtf', 'jpg', 'jpeg', 'png', 'webp', 'office', 'legacy',
    }.contains(ext)) {
      throw const FormatException('Unsupported document extension.');
    }
    final workspace = await _workspace();
    final destination = File('${workspace.path}/$id.$ext');
    final partial = File('${destination.path}.part');
    final stateDirectory = await _stateDirectory();
    final state = File('${stateDirectory.path}/${id}_state.json');
    IOSink? sink;
    try {
      sink = partial.openWrite();
      var size = 0;
      await for (final chunk in source.openRead()) {
        size += chunk.length;
        if (size > 250 * 1024 * 1024) {
          throw const FileSystemException('File must be smaller than 250 MB.');
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (size <= 0) throw const FileSystemException('File is empty.');
      await partial.rename(destination.path);
      if (!await state.exists()) await state.writeAsString(jsonEncode(<String, Object?>{}));
      return StoredStudioFile(
        path: destination.path,
        editStatePath: state.path,
        sizeBytes: size,
        extension: ext,
      );
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<bool> _insideWorkspace(String path) async {
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/pdf_studio').absolute.path;
    final target = File(path).absolute.path;
    return target.startsWith('$root${Platform.pathSeparator}');
  }

  @override
  Future<void> deleteStored({
    required String path,
    required String editStatePath,
  }) async {
    if (await _insideWorkspace(path)) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    if (editStatePath.isNotEmpty && await _insideWorkspace(editStatePath)) {
      final state = File(editStatePath);
      if (await state.exists()) await state.delete();
    }
  }

  @override
  Future<bool> exists(String path) => File(path).exists();
}
