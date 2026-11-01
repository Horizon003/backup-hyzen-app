import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/media_upload.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/surfaces.dart';
import '../../downloads/domain/download_record.dart';
import '../../shell/app_shell.dart';
import '../../viewer/external_files.dart';
import '../../viewer/offline_pdf.dart';
import '../../viewer/reader_chrome.dart';
import '../data/pdf_studio_repository.dart';
import '../data/studio_file_item.dart';
import 'studio_tools_screen.dart';
import 'studio_export_sheet.dart';
import 'studio_annotation_screen.dart';

enum _StudioFilter { all, scanned, edited, mergedSplit, docs, external }

String _studioMime(String path) => switch (path.split('.').last.toLowerCase()) {
  'pdf' => 'application/pdf',
  'doc' => 'application/msword',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'ppt' => 'application/vnd.ms-powerpoint',
  'pptx' =>
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'xls' => 'application/vnd.ms-excel',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'txt' => 'text/plain',
  'md' => 'text/markdown',
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'application/octet-stream',
};

class PdfStudioScreen extends ConsumerStatefulWidget {
  const PdfStudioScreen({super.key});

  @override
  ConsumerState<PdfStudioScreen> createState() => _PdfStudioScreenState();
}

class _PdfStudioScreenState extends ConsumerState<PdfStudioScreen> {
  _StudioFilter _filter = _StudioFilter.all;
  String _query = '';
  bool _matches(StudioFileItem file) {
    final filterMatch = switch (_filter) {
      _StudioFilter.all => true,
      _StudioFilter.scanned =>
        file.sourceType.contains('SCAN') || file.operationBadge == 'SCANNED',
      _StudioFilter.edited => file.operationBadge == 'EDITED',
      _StudioFilter.mergedSplit =>
        file.operationBadge == 'MERGED' || file.operationBadge == 'SPLIT',
      _StudioFilter.docs => file.fileCategory == 'DOC',
      _StudioFilter.external => file.sourceType == 'EXTERNAL_INTENT',
    };
    return filterMatch &&
        (_query.isEmpty ||
            '${file.displayName} ${file.originalFileName}'
                .toLowerCase()
                .contains(_query.toLowerCase()));
  }

  void _openTool(StudioTool tool) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => StudioToolsScreen(tool: tool)),
      );

  @override
  Widget build(BuildContext context) {
    final history = ref
        .watch(pdfStudioHistoryProvider)
        .where(_matches)
        .toList();
    final external = ref.watch(externalHistoryProvider);
    final knownPaths = ref
        .watch(pdfStudioHistoryProvider)
        .map((item) => item.internalFilePath)
        .toSet();
    final notImported =
        _filter == _StudioFilter.all || _filter == _StudioFilter.external
        ? external
              .where(
                (item) =>
                    !knownPaths.contains(item.path) &&
                    !ref
                        .read(pdfStudioHistoryProvider)
                        .any(
                          (f) =>
                              f.id ==
                              ref
                                  .read(sharedPrefsProvider)
                                  .getString('external_studio_${item.id}'),
                        ),
              )
              .toList()
        : const <ExternalDocument>[];
    final theme = Theme.of(context);

    return TabPage(
      title: 'Office Workspace',
      headerTheme: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          titleLarge: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      subtitle: 'Read · Edit · Study · Succeed',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              const Gap(12),
              Text('CREATE & IMPORT', style: theme.textTheme.labelLarge),
              const Gap(14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _WorkspaceAction(
                      title: 'Scan document',
                      subtitle: 'Use camera',
                      icon: Icons.document_scanner_outlined,
                      filled: true,
                      onTap: () => context.push('/create-pdf?source=camera'),
                    ),
                    _WorkspaceAction(
                      title: 'From images',
                      subtitle: 'Convert gallery photos',
                      icon: Icons.photo_library_outlined,
                      onTap: () => context.push('/create-pdf?source=gallery'),
                    ),
                  ];
                  return MediaQuery.textScalerOf(context).scale(1) > 1.3
                      ? Column(
                          children: [
                            for (final card in cards)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        );
                },
              ),
              const Gap(12),
              HCard(
                radius: 20,
                onTap: () => _openTool(StudioTool.open),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Open PDF', style: theme.textTheme.titleLarge),
                          const Gap(4),
                          const Text('Read or edit an existing file'),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const Gap(24),
              Text('QUICK TOOLS', style: theme.textTheme.labelLarge),
              const Gap(14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tools = [
                    (StudioTool.merge, Icons.copy_outlined, 'Merge PDFs'),
                    (StudioTool.organize, Icons.folder_outlined, 'Organize'),
                    (
                      StudioTool.extract,
                      Icons.document_scanner_outlined,
                      'Extract pages',
                    ),
                  ];
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tool in tools)
                        SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(1) > 1.3
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 16) / 3,
                          child: HCard(
                            radius: 20,
                            onTap: () => _openTool(tool.$1),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 8,
                            ),
                            child: Column(
                              children: [
                                Icon(tool.$2, size: 27),
                                const Gap(10),
                                Text(
                                  tool.$3,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Gap(24),
              SectionHeader(
                title: 'Recent Files',
                action: 'See all',
                onAction: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) => SizedBox(
                    height: MediaQuery.sizeOf(context).height * .75,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'All workspace files',
                          style: theme.textTheme.titleLarge,
                        ),
                        const Gap(16),
                        if (ref.read(pdfStudioHistoryProvider).isEmpty)
                          const Text('No recent documents'),
                        for (final file in ref.read(pdfStudioHistoryProvider))
                          _StudioHistoryTile(file: file),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(10),
              HSearchField(
                hint: 'Search documents',
                onChanged: (value) => setState(() => _query = value),
              ),
              const Gap(HSpace.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _StudioFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text(switch (filter) {
                            _StudioFilter.all => 'All',
                            _StudioFilter.scanned => 'Scanned',
                            _StudioFilter.edited => 'Edited',
                            _StudioFilter.mergedSplit => 'Merged',
                            _StudioFilter.docs => 'Docs',
                            _StudioFilter.external => 'External (saved)',
                          }),
                          selected: _filter == filter,
                          selectedColor: theme.brightness == Brightness.dark
                              ? const Color(0xFF48484C)
                              : const Color(0xFF1C1C1E),
                          labelStyle: TextStyle(
                            color: _filter == filter
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                          checkmarkColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              const Gap(HSpace.sm),
              if (history.isEmpty && notImported.isEmpty)
                HCard(
                  radius: 22,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Gap(12),
                      Icon(
                        Icons.file_copy_outlined,
                        size: 80,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: .45,
                        ),
                      ),
                      const Gap(20),
                      Text(
                        'No recent documents',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Gap(8),
                      const Text(
                        'Your scans and PDFs will appear here',
                        textAlign: TextAlign.center,
                      ),
                      const Gap(20),
                      OutlinedButton.icon(
                        onPressed: () => _openTool(StudioTool.open),
                        icon: const Icon(Icons.folder_outlined),
                        label: const Text('Browse files'),
                      ),
                      const Gap(8),
                    ],
                  ),
                ),
              for (final file in history) _StudioHistoryTile(file: file),
              if (notImported.isNotEmpty) ...[
                const Gap(HSpace.md),
                Text(
                  'Opened with PHARM D WITH HYZEN',
                  style: theme.textTheme.titleMedium,
                ),
                Text('Recent device files', style: theme.textTheme.bodySmall),
                const Gap(HSpace.xs),
                for (final file in notImported)
                  ResourceTile(
                    icon: Icons.file_present_rounded,
                    color: HColors.primary,
                    eyebrow: 'DEVICE IMPORT',
                    title: file.title,
                    subtitle:
                        'Opened ${file.openedAt.toLocal().toString().split('.').first}',
                    trailing: IconButton(
                      tooltip: 'Save to Office Workspace workspace',
                      icon: const Icon(Icons.save_alt_rounded),
                      onPressed: () async {
                        try {
                          final item = await ref
                              .read(pdfStudioHistoryProvider.notifier)
                              .importFile(
                                file.path,
                                originalFileName: file.title,
                                sourceType: 'EXTERNAL_INTENT',
                                operationBadge: 'IMPORTED',
                              );
                          await ref
                              .read(sharedPrefsProvider)
                              .setString('external_studio_${file.id}', item.id);
                          if (context.mounted) {
                            showHSnack(context, 'Saved to Office Workspace');
                            context.push('/pdf-studio/viewer/${item.id}');
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showHSnack(
                              context,
                              'Could not copy this file into Studio.',
                              error: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
              const Gap(HSpace.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudioHistoryTile extends ConsumerWidget {
  const _StudioHistoryTile({required this.file});
  final StudioFileItem file;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResourceTile(
    icon: documentIconForName(file.displayName),
    color: documentColorForName(file.displayName),
    eyebrow: '${file.operationBadge} · ${file.fileCategory}',
    title: file.displayName,
    subtitle:
        '${formatBytes(file.fileSizeBytes)} · ${file.pageCount > 0 ? '${file.pageCount} pages' : 'Document'}',
    badge: file.isStarred
        ? const StatusPill(
            label: 'Starred',
            color: HColors.warning,
            icon: Icons.star_rounded,
          )
        : null,
    onTap: () => context.push('/pdf-studio/viewer/${file.id}'),
    trailing: PopupMenuButton<String>(
      tooltip: 'Document actions',
      onSelected: (action) async {
        if (action == 'star') {
          await ref
              .read(pdfStudioHistoryProvider.notifier)
              .setStarred(file.id, !file.isStarred);
        } else if (action == 'rename') {
          final controller = TextEditingController(text: file.displayName);
          final name = await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Rename document'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          controller.dispose();
          if (name != null) {
            await ref
                .read(pdfStudioHistoryProvider.notifier)
                .rename(file.id, name);
          }
        } else if (action == 'export') {
          await showStudioExportSheet(context, file);
        } else if (action == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Delete workspace copy?'),
              content: Text(
                '“${file.displayName}” will be deleted from Studio.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(pdfStudioHistoryProvider.notifier).delete(file.id);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'star',
          child: Text(file.isStarred ? 'Remove star' : 'Star document'),
        ),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'export', child: Text('Export to device')),
        const PopupMenuItem(value: 'delete', child: Text('Delete from Studio')),
      ],
    ),
  );
}

class PdfStudioFileViewerScreen extends ConsumerStatefulWidget {
  const PdfStudioFileViewerScreen({
    super.key,
    required this.fileId,
    this.initialPage = 1,
  });
  final String fileId;
  final int initialPage;

  @override
  ConsumerState<PdfStudioFileViewerScreen> createState() =>
      _PdfStudioFileViewerScreenState();
}

class _PdfStudioFileViewerScreenState
    extends ConsumerState<PdfStudioFileViewerScreen> {
  bool _recorded = false;
  final _tools = ReaderTools();

  void _tool(StudioTool tool, StudioFileItem file) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => StudioToolsScreen(tool: tool, initialFile: file),
        ),
      );

  Future<void> _rename(StudioFileItem file) async {
    final value = TextEditingController(text: file.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: value, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, value.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    value.dispose();
    if (name != null) {
      await ref.read(pdfStudioHistoryProvider.notifier).rename(file.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(pdfStudioHistoryProvider);
    StudioFileItem? found;
    for (final item in files) {
      if (item.id == widget.fileId) found = item;
    }
    if (found == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Office Workspace')),
        body: const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Document not found',
          message: 'It may have been deleted from the workspace.',
        ),
      );
    }
    final active = found;
    if (!_recorded) {
      _recorded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(pdfStudioHistoryProvider.notifier).recordOpen(active.id);
        }
      });
    }
    void edit() => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => StudioAnnotationScreen(file: active),
      ),
    );
    void export() => showStudioExportSheet(context, active);
    return ReaderScaffold(
      title: active.displayName,
      onShare: () async {
        try {
          await MediaUpload.shareDocument(
            active.internalFilePath,
            active.displayName,
            _studioMime(active.internalFilePath),
          );
        } catch (_) {
          if (context.mounted) {
            showHSnack(context, 'Could not share this file.', error: true);
          }
        }
      },
      actions: [
        ReaderAction(
          active.isStarred ? 'Remove bookmark' : 'Bookmark',
          Icons.bookmark_border_rounded,
          () => ref
              .read(pdfStudioHistoryProvider.notifier)
              .setStarred(active.id, !active.isStarred),
        ),
        ReaderAction('Save As', Icons.save_alt_rounded, export),
        ReaderAction(
          'Pages view',
          Icons.grid_view_rounded,
          () => _tools.run('pages', context),
        ),
        ReaderAction(
          'Search',
          Icons.search_rounded,
          () => _tools.run('search', context),
        ),
        ReaderAction(
          'Rename',
          Icons.drive_file_rename_outline_rounded,
          () => _rename(active),
        ),
        if (active.fileCategory == 'PDF') ...[
          ReaderAction(
            'Edit / highlight',
            Icons.edit_outlined,
            edit,
            group: 'File actions',
          ),
          ReaderAction(
            'Convert / export',
            Icons.description_outlined,
            export,
            group: 'File actions',
          ),
          ReaderAction(
            'Merge PDFs',
            Icons.merge_type_rounded,
            () => _tool(StudioTool.merge, active),
            group: 'File actions',
          ),
          ReaderAction(
            'Sign',
            Icons.draw_outlined,
            edit,
            group: 'File actions',
          ),
          ReaderAction(
            'Extract from PDF',
            Icons.call_split_rounded,
            () => _tool(StudioTool.extract, active),
            group: 'File actions',
          ),
          ReaderAction(
            'Organize / rotate pages',
            Icons.rotate_right_rounded,
            () => _tool(StudioTool.organize, active),
            group: 'Quick edits',
          ),
          ReaderAction(
            'Add Note',
            Icons.note_add_outlined,
            edit,
            group: 'Quick edits',
          ),
        ],
        ReaderAction(
          'Zoom in',
          Icons.zoom_in_rounded,
          () => _tools.run('in', context),
          group: 'View',
        ),
        ReaderAction(
          'Zoom out',
          Icons.zoom_out_rounded,
          () => _tools.run('out', context),
          group: 'View',
        ),
        ReaderAction(
          'Send Feedback',
          Icons.feedback_outlined,
          () => context.push('/contact'),
          group: 'Support',
        ),
      ],
      child: OfflinePdf(
        path: active.internalFilePath,
        tools: _tools,
        initialPage: widget.initialPage,
      ),
    );
  }
}

class _WorkspaceAction extends StatelessWidget {
  const _WorkspaceAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final ink = filled ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return HCard(
      radius: 22,
      color: filled ? const Color(0xFF1C1C1E) : null,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 96 * MediaQuery.textScalerOf(context).scale(1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: ink),
            const Gap(20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: .72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
