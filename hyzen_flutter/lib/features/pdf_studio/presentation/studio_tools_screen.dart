import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/media_upload.dart';
import '../../../core/widgets/common.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_file_item.dart';
import '../data/studio_pdf_engine.dart';
import 'studio_page_thumbnail.dart';
import 'page_grid.dart';

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
  final _sources = <PickedStudioFile>[];
  final _pages = <StudioPage>[];
  final _splitSelected = <int>{};
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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _work(() async {
          if (widget.tool == StudioTool.document) {
            final text = await StudioPdfEngine.readText(file.internalFilePath);
            if (mounted) _text.text = text;
          } else {
            await _addPaths([
              PickedStudioFile(file.displayName, file.internalFilePath),
            ]);
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _range.dispose();
    super.dispose();
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showHSnack(
          context,
          e is FormatException
              ? e.message
              : 'Could not complete this operation. Please retry.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseHistory() async {
    final available = ref
        .read(pdfStudioHistoryProvider)
        .where((f) => f.internalFilePath.toLowerCase().endsWith('.pdf'))
        .toList();
    final selected = <String>{};
    final picked = await showModalBottomSheet<List<PickedStudioFile>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(c).height * .7,
            child: Column(
              children: [
                const ListTile(title: Text('Choose from Office Workspace')),
                Expanded(
                  child: available.isEmpty
                      ? const Center(
                          child: Text('No PDFs in your workspace yet.'),
                        )
                      : ListView(
                          children: [
                            for (final file in available)
                              CheckboxListTile(
                                title: Text(file.displayName),
                                value: selected.contains(file.id),
                                onChanged: (v) => update(() {
                                  if (widget.tool != StudioTool.merge) {
                                    selected.clear();
                                  }
                                  if (v == true) {
                                    selected.add(file.id);
                                  } else {
                                    selected.remove(file.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(c, [
                            for (final f in available)
                              if (selected.contains(f.id))
                                PickedStudioFile(
                                  f.displayName,
                                  f.internalFilePath,
                                ),
                          ]),
                    child: const Text('Use selected PDFs'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null && mounted) await _work(() => _addPaths(picked));
  }

  Future<void> _pick() => _work(() async {
    final picked = await StudioPdfEngine.pickFiles();
    if (picked.isNotEmpty) await _addPaths(picked);
  });

  Future<void> _addPaths(
    List<PickedStudioFile> picked, {
    bool replace = false,
  }) async {
    if (!mounted) return;
    if (widget.tool == StudioTool.open) {
      final chosen = picked.first;
      final item = await ref
          .read(pdfStudioHistoryProvider.notifier)
          .importFile(chosen.path, originalFileName: chosen.name);
      if (mounted) _openSaved(item.id);
      return;
    }
    final candidates =
        (widget.tool == StudioTool.merge || widget.tool == StudioTool.images)
        ? (replace ? picked : [..._sources, ...picked])
        : [picked.first];
    final selected = {
      for (final file in candidates) file.path: file,
    }.values.toList();
    if (widget.tool == StudioTool.images) {
      if (selected.any(
        (f) => !RegExp(
          r'\.(jpe?g|png|webp)$',
          caseSensitive: false,
        ).hasMatch(f.name),
      )) {
        throw const FormatException('Select images only.');
      }
      setState(
        () => _sources
          ..clear()
          ..addAll(selected),
      );
      return;
    }
    if (selected.any((f) => !f.path.toLowerCase().endsWith('.pdf'))) {
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
    if (mounted) {
      setState(() {
        _sources
          ..clear()
          ..addAll(selected);
        _pages
          ..clear()
          ..addAll(pages);
        _splitSelected.clear();
      });
    }
  }

  Future<StudioFileItem> _save(String path, String name, String badge) => ref
      .read(pdfStudioHistoryProvider.notifier)
      .importFile(
        path,
        originalFileName: name,
        sourceType: badge,
        operationBadge: badge,
      );

  Future<void> _finish(String path, String name, String badge) async {
    final pdf = name.toLowerCase().endsWith('.pdf');
    final count = pdf ? await StudioPdfEngine.pageCount(path) : 0;
    if (pdf && count < 1) {
      throw const FormatException('The PDF could not be saved. Please retry.');
    }
    final item = await _save(path, name, badge);
    if (pdf) {
      await ref
          .read(pdfStudioHistoryProvider.notifier)
          .updatePageCount(item.id, count);
    }
    if (!mounted) return;
    final destination = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_rounded),
              title: Text('Saved: ${item.displayName}'),
              subtitle: const Text('Your new PDF is in Recent Files'),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_rounded),
              title: const Text('Save As on device'),
              onTap: () => Navigator.pop(c, 'device'),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('Share PDF'),
              onTap: () => Navigator.pop(c, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Open PDF'),
              onTap: () => Navigator.pop(c, 'open'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (destination == 'device') {
      await MediaUpload.exportDocument(
        item.internalFilePath,
        item.displayName,
        pdf ? 'application/pdf' : 'text/plain',
      );
    }
    if (destination == 'share') {
      await MediaUpload.shareDocument(
        item.internalFilePath,
        item.displayName,
        pdf ? 'application/pdf' : 'text/plain',
      );
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
      if (match == null) {
        throw const FormatException('Use page numbers such as 1-3, 5, 8-10.');
      }
      final first = int.parse(match.group(1)!);
      final last = int.tryParse(match.group(2) ?? '') ?? first;
      if (first < 1 || last > count || last < first) {
        throw const FormatException('Page range is outside this PDF.');
      }
      for (var page = first; page <= last; page++) {
        result.add(page - 1);
      }
    }
    return result.toList()..sort();
  }

  Future<void> _create() => _work(() async {
    final name = _title.text.trim().isEmpty
        ? 'Studio document'
        : _title.text.trim();
    switch (widget.tool) {
      case StudioTool.open:
        await _pick();
        break;
      case StudioTool.merge:
        if (_sources.length < 2) {
          throw const FormatException('Select at least two PDFs.');
        }
        await _finish(
          await StudioPdfEngine.compose(_pages),
          '$name.pdf',
          'MERGED',
        );
        break;
      case StudioTool.organize:
        if (_pages.isEmpty) throw const FormatException('Select pages first.');
        await _finish(
          await StudioPdfEngine.compose(_pages),
          '$name.pdf',
          'EDITED',
        );
        break;
      case StudioTool.split:
        if (_pages.isEmpty) throw const FormatException('Select a PDF first.');
        final selected = _splitSelected.isEmpty
            ? _parseRange(_range.text, _pages.length)
            : (_splitSelected.toList()..sort());
        await _finish(
          await StudioPdfEngine.compose([for (final i in selected) _pages[i]]),
          '$name.pdf',
          'SPLIT',
        );
        break;
      case StudioTool.images:
        if (_sources.isEmpty) {
          throw const FormatException('Choose images first.');
        }
        await _finish(
          await StudioPdfEngine.imagesToPdf([
            for (final file in _sources) file.path,
          ]),
          '$name.pdf',
          'CREATED',
        );
        break;
      case StudioTool.document:
        if (_text.text.trim().isEmpty) {
          throw const FormatException('Write some text first.');
        }
        final path = await StudioPdfEngine.textFile(_text.text);
        await _finish(path, '$name.txt', 'CREATED');
        break;
    }
  });

  Future<void> _addSource() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Add PDFs')),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Recent files'),
              onTap: () => Navigator.pop(c, 'recent'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: const Text('From device'),
              onTap: () => Navigator.pop(c, 'device'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'recent') await _chooseHistory();
    if (choice == 'device') await _pick();
  }

  void _movePage(int from, int to) {
    setState(() {
      final selectedIds = {for (final i in _splitSelected) _pages[i].id};
      final page = _pages.removeAt(from);
      _pages.insert(to, page);
      _splitSelected
        ..clear()
        ..addAll([
          for (var i = 0; i < _pages.length; i++)
            if (selectedIds.contains(_pages[i].id)) i,
        ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final split = widget.tool == StudioTool.split;
    final merge = widget.tool == StudioTool.merge;
    final organize = widget.tool == StudioTool.organize;
    final canSave =
        !_busy &&
        (split
            ? _splitSelected.isNotEmpty || _range.text.trim().isNotEmpty
            : merge
            ? _sources.length >= 2
            : widget.tool == StudioTool.document
            ? _text.text.trim().isNotEmpty
            : _pages.isNotEmpty || _sources.isNotEmpty);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(split ? '${_splitSelected.length} Selected' : _heading),
          actions: [
            if (split && _pages.isNotEmpty)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        if (_splitSelected.length == _pages.length) {
                          _splitSelected.clear();
                        } else {
                          _splitSelected.addAll(
                            List.generate(_pages.length, (i) => i),
                          );
                        }
                      }),
                child: Text(
                  _splitSelected.length == _pages.length
                      ? 'Clear'
                      : 'Select all',
                ),
              ),
            if (merge || _pages.isEmpty)
              IconButton(
                tooltip: 'Add PDFs',
                onPressed: _busy ? null : _addSource,
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
        body: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: TextField(
                controller: _title,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'PDF name',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            if (merge)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_sources.length} PDFs · ${_pages.length} pages',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _addSource,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add PDFs'),
                    ),
                  ],
                ),
              ),
            if (split && _pages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _range,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Optional page range, e.g. 1-3, 5',
                    isDense: true,
                  ),
                ),
              ),
            Expanded(
              child: merge
                  ? _sources.isEmpty
                        ? _empty()
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sources.length,
                            onReorder: (from, to) => setState(() {
                              if (to > from) to--;
                              final moved = _sources.removeAt(from);
                              _sources.insert(to, moved);
                              final groups = {
                                for (final f in _sources)
                                  f.path: _pages
                                      .where((p) => p.path == f.path)
                                      .toList(),
                              };
                              _pages
                                ..clear()
                                ..addAll([
                                  for (final f in _sources) ...?groups[f.path],
                                ]);
                            }),
                            itemBuilder: (_, i) => Card(
                              key: ValueKey('${_sources[i].path}-$i'),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                ),
                                title: Text(_sources[i].name, maxLines: 2),
                                subtitle: const Text(
                                  'Hold to change merge order',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove file',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: _busy
                                      ? null
                                      : () => _work(() async {
                                          final next = [..._sources]
                                            ..removeAt(i);
                                          if (next.isEmpty) {
                                            setState(() {
                                              _sources.clear();
                                              _pages.clear();
                                            });
                                          } else {
                                            await _addPaths(
                                              next,
                                              replace: true,
                                            );
                                          }
                                        }),
                                ),
                              ),
                            ),
                          )
                  : widget.tool == StudioTool.document
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _text,
                        onChanged: (_) => setState(() {}),
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Write your document',
                        ),
                      ),
                    )
                  : _pages.isEmpty
                  ? _empty()
                  : PageGrid(
                      count: _pages.length,
                      identity: (i) => _pages[i].id,
                      image: (i) => _pages[i].blank
                          ? const Icon(Icons.description_outlined)
                          : StudioPageThumbnail(page: _pages[i]),
                      selected: _splitSelected,
                      onSelect: split
                          ? (i) => setState(() {
                              if (!_splitSelected.add(i)) {
                                _splitSelected.remove(i);
                              }
                            })
                          : null,
                      onMove: _busy ? (_, __) {} : _movePage,
                      onRotate: organize
                          ? (i) =>
                                setState(() => _pages[i] = _pages[i].rotate())
                          : null,
                      onRemove: organize
                          ? (i) => setState(() => _pages.removeAt(i))
                          : null,
                    ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              key: const ValueKey('save-page-operation'),
              onPressed: canSave ? _create : null,
              icon: const Icon(Icons.save_alt_rounded, size: 20),
              label: Text(
                split
                    ? 'Extract & save PDF'
                    : merge
                    ? 'Merge & save PDF'
                    : 'Save PDF',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: FilledButton.tonalIcon(
      onPressed: _busy ? null : _addSource,
      icon: const Icon(Icons.folder_open_rounded),
      label: const Text('Choose PDF'),
    ),
  );
}
