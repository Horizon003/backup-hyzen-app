import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/media_upload.dart';
import '../../../core/widgets/common.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_file_item.dart';
import '../data/studio_pdf_engine.dart';

enum StudioTool { open, merge, split, organize, images, document }

class StudioToolsScreen extends ConsumerStatefulWidget {
  const StudioToolsScreen({super.key, required this.tool, this.initialFile});
  final StudioTool tool;
  final StudioFileItem? initialFile;

  @override
  ConsumerState<StudioToolsScreen> createState() => _StudioToolsScreenState();
}

class _StudioToolsScreenState extends ConsumerState<StudioToolsScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _range = TextEditingController();
  final _chunk = TextEditingController(text: '5');
  final _sources = <PickedStudioFile>[];
  final _pages = <StudioPage>[];
  bool _busy = false;

  String get _heading => switch (widget.tool) {
    StudioTool.open => 'Open PDF or document',
    StudioTool.merge => 'Merge PDFs',
    StudioTool.split => 'Split or extract pages',
    StudioTool.organize => 'Organize pages',
    StudioTool.images => 'Images to PDF',
    StudioTool.document => 'Document writer',
  };

  @override
  void initState() {
    super.initState();
    final file = widget.initialFile;
    if (file != null) {
      _title.text = file.displayName.replaceFirst(RegExp(r'\.[^.]+$'), ' copy');
      WidgetsBinding.instance.addPostFrameCallback((_) => _work(() async {
        if (widget.tool == StudioTool.document) {
          final text = await StudioPdfEngine.readText(file.internalFilePath);
          if (mounted) _text.text = text;
        } else {
          await _addPaths([PickedStudioFile(file.displayName, file.internalFilePath)]);
        }
      }));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _range.dispose();
    _chunk.dispose();
    super.dispose();
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showHSnack(context, 'Could not complete PDF operation: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() => _work(() async {
    final picked = await StudioPdfEngine.pickFiles();
    if (picked.isNotEmpty) await _addPaths(picked);
  });

  Future<void> _addPaths(List<PickedStudioFile> picked, {bool replace = false}) async {
    if (!mounted) return;
    if (widget.tool == StudioTool.open) {
      final chosen = picked.first;
      final item = await ref.read(pdfStudioHistoryProvider.notifier).importFile(
        chosen.path, originalFileName: chosen.name,
      );
      if (mounted) _openSaved(item.id);
      return;
    }
    final selected = !replace && (widget.tool == StudioTool.merge || widget.tool == StudioTool.images)
        ? [..._sources, ...picked]
        : [picked.first];
    if (widget.tool == StudioTool.images) {
      if (selected.any((f) => !RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(f.name))) {
        throw const FormatException('Select images only.');
      }
      setState(() => _sources..clear()..addAll(selected));
      return;
    }
    if (selected.any((f) => !f.name.toLowerCase().endsWith('.pdf'))) {
      throw const FormatException('Select PDF files only.');
    }
    final pages = <StudioPage>[];
    for (final source in selected) {
      final count = await StudioPdfEngine.pageCount(source.path);
      if (count > 150 || count + pages.length > 150) {
        throw const FormatException('The maximum is 150 pages per operation.');
      }
      for (var index = 0; index < count; index++) {
        pages.add(StudioPage(source.path, index));
      }
    }
    if (mounted) setState(() { _sources..clear()..addAll(selected); _pages..clear()..addAll(pages); });
  }

  Future<StudioFileItem> _save(String path, String name, String badge) => ref
      .read(pdfStudioHistoryProvider.notifier)
      .importFile(path, originalFileName: name, sourceType: badge, operationBadge: badge);

  Future<void> _finish(String path, String name, String badge) async {
    final item = await _save(path, name, badge);
    if (name.toLowerCase().endsWith('.pdf')) {
      final count = await StudioPdfEngine.pageCount(item.internalFilePath);
      await ref.read(pdfStudioHistoryProvider.notifier).updatePageCount(item.id, count);
    }
    if (mounted) _openSaved(item.id);
  }

  void _openSaved(String id) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/pdf-studio/viewer/$id');
  }

  List<int> _parseRange(String input, int count) {
    final result = <int>{};
    for (final part in input.split(',')) {
      final match = RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+)\s*)?$').firstMatch(part);
      if (match == null) throw const FormatException('Use page numbers such as 1-3, 5, 8-10.');
      final first = int.parse(match.group(1)!);
      final last = int.tryParse(match.group(2) ?? '') ?? first;
      if (first < 1 || last > count || last < first) throw const FormatException('Page range is outside this PDF.');
      for (var page = first; page <= last; page++) result.add(page - 1);
    }
    return result.toList()..sort();
  }

  Future<void> _create() => _work(() async {
    final name = _title.text.trim().isEmpty ? 'Studio document' : _title.text.trim();
    switch (widget.tool) {
      case StudioTool.open:
        await _pick();
        break;
      case StudioTool.merge:
        if (_sources.length < 2) throw const FormatException('Select at least two PDFs.');
        await _finish(await StudioPdfEngine.compose(_pages), '$name.pdf', 'MERGED');
        break;
      case StudioTool.organize:
        if (_pages.isEmpty) throw const FormatException('Select pages first.');
        await _finish(await StudioPdfEngine.compose(_pages), '$name.pdf', 'EDITED');
        break;
      case StudioTool.split:
        if (_pages.isEmpty) throw const FormatException('Select a PDF first.');
        final selected = _parseRange(_range.text, _pages.length);
        await _finish(await StudioPdfEngine.compose([for (final i in selected) _pages[i]]), '$name.pdf', 'SPLIT');
        break;
      case StudioTool.images:
        if (_sources.isEmpty) throw const FormatException('Choose images first.');
        await _finish(await StudioPdfEngine.imagesToPdf([for (final file in _sources) file.path]), '$name.pdf', 'CREATED');
        break;
      case StudioTool.document:
        if (_text.text.trim().isEmpty) throw const FormatException('Write some text first.');
        final path = await StudioPdfEngine.textFile(_text.text);
        await _finish(path, '$name.txt', 'CREATED');
        break;
    }
  });

  Future<void> _splitEvery() => _work(() async {
    final n = int.tryParse(_chunk.text);
    if (_pages.isEmpty || n == null || n < 1 || n > 150) throw const FormatException('Choose a PDF and a valid page count.');
    final name = _title.text.trim().isEmpty ? 'Extract' : _title.text.trim();
    var part = 0;
    for (var start = 0; start < _pages.length; start += n) {
      part++;
      final end = start + n > _pages.length ? _pages.length : start + n;
      final output = await StudioPdfEngine.compose(_pages.sublist(start, end));
      await _save(output, '$name $part.pdf', 'SPLIT');
    }
    if (mounted) { showHSnack(context, '$part PDFs saved in Studio'); Navigator.pop(context); }
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_heading)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Create a private workspace copy', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Originals stay untouched. Merge and page edits render a new visual PDF; text selection in those exported pages is not preserved.'),
        const SizedBox(height: 16),
        if (widget.tool != StudioTool.document) ...[
          FilledButton.tonalIcon(onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_rounded), label: Text(widget.tool == StudioTool.images ? 'Choose images' : 'Choose from device')),
          if (_sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${_sources.length} files · ${_pages.length} pages', style: theme.textTheme.titleMedium),
            if (widget.tool != StudioTool.merge && widget.tool != StudioTool.images)
            for (var index = 0; index < _sources.length; index++)
              ListTile(
                leading: const Icon(Icons.description_rounded),
                title: Text(_sources[index].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: widget.tool == StudioTool.merge || widget.tool == StudioTool.images
                    ? IconButton(icon: const Icon(Icons.close), tooltip: 'Remove file', onPressed: _busy ? null : () async {
                        final updated = [..._sources]..removeAt(index);
                        if (updated.isEmpty) setState(() { _sources.clear(); _pages.clear(); });
                        else await _work(() => _addPaths(updated, replace: true));
                      }) : null,
              ),
          ],
        ],
        if (widget.tool != StudioTool.open) ...[
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'New file name')),
        ],
        if (widget.tool == StudioTool.document) ...[
          const SizedBox(height: 12),
          TextField(controller: _text, minLines: 12, maxLines: 24,
            decoration: const InputDecoration(labelText: 'Document text', alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _busy ? null : () => _work(() async {
            if (_text.text.trim().isEmpty) throw const FormatException('Write some text first.');
            final name = _title.text.trim().isEmpty ? 'Document' : _title.text.trim();
            await _finish(await StudioPdfEngine.textToPdf(_text.text), '$name.pdf', 'CREATED');
          }), icon: const Icon(Icons.picture_as_pdf), label: const Text('Save as PDF in Studio')),
          OutlinedButton.icon(onPressed: _busy ? null : () => _work(() async {
            if (_text.text.trim().isEmpty) throw const FormatException('Write some text first.');
            final name = _title.text.trim().isEmpty ? 'Document' : _title.text.trim();
            await _finish(await StudioPdfEngine.textToDocx(_text.text), '$name.docx', 'CREATED');
          }), icon: const Icon(Icons.description_outlined), label: const Text('Save plain DOCX in Studio')),
          OutlinedButton.icon(onPressed: _busy ? null : () => _work(() async {
            final name = _title.text.trim().isEmpty ? 'Document' : _title.text.trim();
            await MediaUpload.exportText('$name.txt', _text.text);
          }), icon: const Icon(Icons.save_alt), label: const Text('Export text to device')),
        ],
        if (widget.tool == StudioTool.split && _pages.isNotEmpty) ...[
          TextField(controller: _range, decoration: InputDecoration(labelText: 'Pages to extract', hintText: '1-3, 5, 8-10', helperText: 'From 1 to ${_pages.length}')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _chunk, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pages per PDF'))),
            const SizedBox(width: 10),
            OutlinedButton(onPressed: _busy ? null : _splitEvery, child: const Text('Split every N')),
          ]),
        ],
        if (widget.tool == StudioTool.organize && _pages.isNotEmpty) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: () => setState(() => _pages.add(StudioPage.blank())), icon: const Icon(Icons.note_add_outlined), label: const Text('Add blank page')),
          const Text('Drag to reorder. Rotate or remove pages below.'),
        ],
        if (widget.tool == StudioTool.merge || widget.tool == StudioTool.organize || widget.tool == StudioTool.images)
          SizedBox(height: (_pages.isNotEmpty || _sources.isNotEmpty) ? 260 : 0,
            child: ReorderableListView.builder(
              itemCount: widget.tool == StudioTool.images ? _sources.length : widget.tool == StudioTool.merge ? _sources.length : _pages.length,
              onReorder: (from, to) => setState(() {
                if (widget.tool == StudioTool.organize) {
                  final moved = _pages.removeAt(from); _pages.insert(to > from ? to - 1 : to, moved);
                } else {
                  final moved = _sources.removeAt(from); _sources.insert(to > from ? to - 1 : to, moved);
                  if (widget.tool == StudioTool.merge) {
                    final groups = {for (final file in _sources) file.path: _pages.where((p) => p.path == file.path).toList()};
                    _pages..clear()..addAll([for (final file in _sources) ...?groups[file.path]]);
                  }
                }
              }),
              itemBuilder: (_, i) => ListTile(
                key: ValueKey(widget.tool == StudioTool.organize ? 'page-${_pages[i].id}' : 'file-${_sources[i].path}-$i'),
                title: Text(widget.tool == StudioTool.organize ? (_pages[i].blank ? 'Blank page' : 'Page ${_pages[i].index + 1}') : _sources[i].name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: widget.tool == StudioTool.organize ? Text('${_pages[i].rotation}°') : null,
                trailing: widget.tool == StudioTool.organize ? Wrap(children: [
                  IconButton(icon: const Icon(Icons.rotate_right), tooltip: 'Rotate 90 degrees', onPressed: () => setState(() => _pages[i] = _pages[i].rotate())),
                  IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Remove page', onPressed: () => setState(() => _pages.removeAt(i))),
                  const Icon(Icons.drag_handle),
                ]) : Wrap(children: [
                  IconButton(icon: const Icon(Icons.close), tooltip: 'Remove file', onPressed: _busy ? null : () async {
                    final updated = [..._sources]..removeAt(i);
                    if (updated.isEmpty) setState(() { _sources.clear(); _pages.clear(); });
                    else await _work(() => _addPaths(updated, replace: true));
                  }),
                  const Icon(Icons.drag_handle),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 16),
        if (widget.tool != StudioTool.open)
          FilledButton.icon(onPressed: _busy ? null : _create,
            icon: const Icon(Icons.check_rounded),
            label: Text(switch (widget.tool) {
              StudioTool.split => 'Extract selected pages',
              StudioTool.document => 'Save text in Studio',
              _ => 'Create PDF in Studio',
            })),
        if (_busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
      ]),
    );
  }
}
