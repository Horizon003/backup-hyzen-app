import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/content/data/content_providers.dart';

/// Opaque floating dock matching the supplied five-destination reference.
/// No blurred glass, no stacked system/navigation padding, no tiny hit areas.
class MainDock extends StatelessWidget {
  const MainDock({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboard) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            key: const ValueKey('main-dock'),
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
            decoration: BoxDecoration(
              color: t.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: t.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: t.colorScheme.primary.withValues(alpha: .12),
                  blurRadius: 22,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _item(
                  context,
                  'Home',
                  Icons.home_rounded,
                  path == '/home',
                  () => context.go('/home'),
                ),
                _item(
                  context,
                  'Study',
                  Icons.menu_rounded,
                  path.startsWith('/study') || path == '/downloads',
                  () => showStudyMenu(context),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'PDF Studio',
                    selected: path.startsWith('/pdf-studio'),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => context.go('/pdf-studio'),
                      child: Container(
                        height: 62,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              t.colorScheme.primary,
                              t.colorScheme.primaryContainer == t.colorScheme.primary ? t.colorScheme.primary : Color.lerp(t.colorScheme.primary, Colors.black, .15)!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: t.colorScheme.primary.withValues(
                                alpha: .24,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: t.colorScheme.onPrimary,
                              size: 25,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: t.colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _item(
                  context,
                  'Shop',
                  Icons.storefront_outlined,
                  path.startsWith('/shop'),
                  () => context.go('/shop'),
                ),
                _item(
                  context,
                  'Settings',
                  Icons.settings_rounded,
                  path == '/settings',
                  () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    final t = Theme.of(context);
    final color = selected
        ? t.colorScheme.primary
        : t.colorScheme.onSurfaceVariant;
    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 62,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.colorScheme.primary.withValues(alpha: .08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: color, size: 25),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showStudyMenu(BuildContext context) {
  final router = GoRouter.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close study menu',
    barrierColor: Colors.black12,
    transitionDuration: const Duration(milliseconds: 160),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    pageBuilder: (c, _, __) => Consumer(
      builder: (c, ref, _) {
        final settings = ref.watch(siteSettingsProvider);
        final t = Theme.of(c);
        var expanded = true;
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: (MediaQuery.sizeOf(c).width * .20).clamp(12, 150),
                bottom: 91,
                right: 16,
              ),
              child: StatefulBuilder(
                builder: (c, setState) => SizedBox(
                  width: 216,
                  child: Material(
                    color: t.colorScheme.surface,
                    elevation: 10,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          180,
                          MediaQuery.sizeOf(c).height - 150,
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (settings.sectionEnabled('notes')) ...[
                              _StudyRow(
                                'Notes',
                                Icons.menu_book_rounded,
                                Theme.of(context).colorScheme.primary,
                                () => setState(() => expanded = !expanded),
                                expanded: expanded,
                              ),
                              if (expanded)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 25,
                                    bottom: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.colorScheme.primary.withValues(
                                      alpha: .07,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      _StudyRow(
                                        'Regular',
                                        Icons.description_outlined,
                                        t.colorScheme.onSurfaceVariant,
                                        () {
                                          Navigator.pop(c);
                                          router.go('/study/notes');
                                        },
                                        small: true,
                                      ),
                                      if (settings.sectionEnabled('special'))
                                        _StudyRow(
                                          'Special',
                                          Icons.auto_stories_outlined,
                                          t.colorScheme.onSurfaceVariant,
                                          () {
                                            Navigator.pop(c);
                                            router.go('/study/special');
                                          },
                                          small: true,
                                        ),
                                    ],
                                  ),
                                ),
                              const Divider(height: 9),
                            ],
                            if (settings.sectionEnabled('mcqs'))
                              _StudyRow(
                                'MCQs',
                                Icons.quiz_rounded,
                                const Color(0xFF1988EA),
                                () {
                                  Navigator.pop(c);
                                  router.go('/study/mcqs');
                                },
                              ),
                            if (settings.sectionEnabled('papers'))
                              _StudyRow(
                                'PPS',
                                Icons.assignment_rounded,
                                const Color(0xFFDB8B22),
                                () {
                                  Navigator.pop(c);
                                  router.go('/study/papers');
                                },
                              ),
                            const Divider(height: 9),
                            _StudyRow(
                              'Downloads',
                              Icons.download_rounded,
                              t.colorScheme.primary,
                              () {
                                Navigator.pop(c);
                                router.go('/downloads');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _StudyRow extends StatelessWidget {
  const _StudyRow(
    this.label,
    this.icon,
    this.color,
    this.onTap, {
    this.small = false,
    this.expanded,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool small;
  final bool? expanded;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: small ? 8 : 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: small ? 20 : 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!small)
            Icon(
              expanded == true
                  ? Icons.expand_more_rounded
                  : Icons.chevron_right_rounded,
              size: 18,
            ),
        ],
      ),
    ),
  );
}
