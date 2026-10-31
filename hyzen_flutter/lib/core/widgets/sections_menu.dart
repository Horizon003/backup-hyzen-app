import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../features/content/data/content_providers.dart';

class SectionsButton extends ConsumerWidget {
  const SectionsButton({super.key});
  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => FloatingActionButton.small(
    heroTag: null,
    tooltip: 'Sections',
    child: const Icon(Icons.chevron_left_rounded),
    onPressed: () {
      final router = GoRouter.of(context);
      final settings = ref.read(siteSettingsProvider);
      final entries = <(String, IconData, String, String?)>[
        ('Home', Icons.home_rounded, '/home', null),
        ('Study', Icons.school_rounded, '/study', null),
        ('Search', Icons.search_rounded, '/search', null),
        ('Notes', Icons.menu_book_rounded, '/study/notes', 'notes'),
        ('MCQs', Icons.quiz_rounded, '/study/mcqs', 'mcqs'),
        ('Books', Icons.auto_stories_rounded, '/study/special', 'special'),
        ('Past papers', Icons.assignment_rounded, '/study/papers', 'papers'),
        ('Lectures', Icons.play_circle_rounded, '/lectures', 'lectures'),
        ('Office Workspace', Icons.picture_as_pdf_rounded, '/pdf-studio', null),
        ('Downloads', Icons.download_done_rounded, '/downloads', null),
        ('Shop', Icons.shopping_bag_rounded, '/shop', 'shop'),
        ('Profile', Icons.person_rounded, '/profile', null),
        if (ref.read(isAdminProvider))
          ('Admin', Icons.dashboard_rounded, '/admin', null),
        ('Settings', Icons.settings_rounded, '/settings', null),
      ].where((d) => d.$4 == null || settings.sectionEnabled(d.$4!)).toList();
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close sections',
        barrierColor: Colors.black45,
        transitionDuration: const Duration(milliseconds: 220),
        transitionBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        pageBuilder: (c, _, __) => SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: (MediaQuery.sizeOf(c).width * .87).clamp(220, 360),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Sections'),
                        trailing: IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(c),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 5),
                          itemBuilder: (_, i) {
                            final d = entries[i];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              selected:
                                  router
                                      .routeInformationProvider
                                      .value
                                      .uri
                                      .path ==
                                  d.$3,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              leading: Icon(d.$2),
                              title: Text(
                                d.$1,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                              ),
                              onTap: () {
                                Navigator.pop(c);
                                router.go(d.$3);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
