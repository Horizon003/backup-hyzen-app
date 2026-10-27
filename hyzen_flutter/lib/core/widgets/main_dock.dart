import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/content/data/content_providers.dart';
import '../theme/tokens.dart';

/// Opaque floating dock matching the supplied five-destination reference.
/// No blurred glass, no stacked system/navigation padding, no tiny hit areas.
/// Approved compact four-tab dock (Q03): Home / Study / PDF Studio / Shop.
/// Profile and Settings live behind the top-right avatar, never as a tab.
class MainDock extends StatelessWidget {
  const MainDock({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboard) return const SizedBox.shrink();
    final dark = t.brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            key: const ValueKey('main-dock'),
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF10232B) : const Color(0xFF1A3440),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x331A3440),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _DockItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: path == '/home',
                  onTap: () => context.go('/home'),
                ),
                _DockItem(
                  label: 'Study',
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  selected: path.startsWith('/study') || path == '/downloads',
                  onTap: () => showStudyMenu(context),
                ),
                _DockItem(
                  label: 'PDF Studio',
                  icon: Icons.picture_as_pdf_outlined,
                  selectedIcon: Icons.picture_as_pdf_rounded,
                  selected: path.startsWith('/pdf-studio'),
                  onTap: () => context.go('/pdf-studio'),
                ),
                _DockItem(
                  label: 'Shop',
                  icon: Icons.storefront_outlined,
                  selectedIcon: Icons.storefront_rounded,
                  selected: path.startsWith('/shop'),
                  onTap: () => context.go('/shop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon, selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF5FD1C1);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Expanded(
      child: Tooltip(
        message: label,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    color: selected ? active : Colors.white70,
                    size: 23,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: selected ? Colors.white : Colors.white60,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
                left: (MediaQuery.sizeOf(c).width * .16).clamp(12, 150),
                bottom: 92,
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
                                HColors.mcqs,
                                () {
                                  Navigator.pop(c);
                                  router.go('/study/mcqs');
                                },
                              ),
                            if (settings.sectionEnabled('papers'))
                              _StudyRow(
                                'PPS',
                                Icons.assignment_rounded,
                                HColors.special,
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
