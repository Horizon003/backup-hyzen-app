import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../notifications/notifications_screen.dart';
import '../updates/update_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/main_dock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/widgets/profile_avatar.dart';
import '../auth/domain/reference_data.dart';

/// Authenticated shell: Material navigation with Android back handling.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    final path = GoRouterState.of(context).uri.path;
    final reader = path.startsWith('/pdf-studio/viewer/');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (FocusManager.instance.primaryFocus?.hasFocus == true &&
            MediaQuery.viewInsetsOf(context).bottom > 0) {
          FocusManager.instance.primaryFocus?.unfocus();
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (idx != 0) {
          navigationShell.goBranch(0);
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Close PHARM D WITH HYZEN?'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(photoUrl: 'avatar:male_1', radius: 44),
                SizedBox(height: 16),
                Text(
                  'Ready to take a break? Your study progress and downloads are saved.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Keep studying'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Close app'),
              ),
            ],
          ),
        );
        if (leave == true) await SystemNavigator.pop();
      },
      child: Scaffold(
        extendBody: true,
        body: UpdateGate(child: navigationShell),
        bottomNavigationBar: reader ? null : MainDock(path: path),
      ),
    );
  }
}

/// Standard tab page: persistent opaque top bar + background + bottom padding for nav.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.onRefresh,
    this.subtitle,
    this.drawer,
  });
  final Widget? drawer;
  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 64 + 8),
        ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 92)),
      ],
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: drawer,
      appBar: _Bar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showMenu: drawer != null,
      ),
      body: HBackground(
        child: onRefresh == null
            ? scroll
            : RefreshIndicator(
                onRefresh: onRefresh!,
                edgeOffset: 64,
                child: scroll,
              ),
      ),
    );
  }
}

class _Bar extends StatelessWidget implements PreferredSizeWidget {
  const _Bar({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showMenu = false,
  });
  final bool showMenu;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SurfacePanel(
      radius: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              if (showMenu)
                IconButton(
                  tooltip: 'Admin menu',
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )
              // The root Home page can appear poppable when another tab has a
              // nested route in its retained navigator. Never show a dead
              // back arrow on the Home header.
              else if (!const [
                    'PHARM D',
                    'Study',
                    'Search',
                    'Office Workspace',
                    'Downloads',
                    'Profile',
                    'Settings',
                    'Shop',
                  ].contains(title) &&
                  Navigator.of(context).canPop())
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              else
                const SizedBox(width: HSpace.screen),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title == 'PHARM D')
                      Row(
                        children: [
                          Image.asset(
                            'assets/brand/hyzen_icon_square.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'PHARM D ',
                                    style: TextStyle(
                                      color: t.colorScheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'WITH HYZEN',
                                    style: TextStyle(
                                      color: t.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                        ),
                      ),
                    if (subtitle != null && title != 'PHARM D')
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              ...actions,
              const NotificationBell(),
              Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(profileProvider).valueOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Tooltip(
                      message: 'Profile & settings',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => showAccountMenu(context),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: t.colorScheme.primary,
                              width: 1.6,
                            ),
                          ),
                          child: ProfileAvatar(
                            photoUrl: profile?.photoUrl,
                            radius: 16,
                            fallback: profile?.firstName ?? 'H',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "offline copy" hint shown when content came from cache.
class OfflineHint extends StatelessWidget {
  const OfflineHint({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      HSpace.screen,
      0,
      HSpace.screen,
      HSpace.sm,
    ),
    child: Row(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          'Showing saved copy \u00b7 pull to refresh',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

/// Account sheet behind the top-right avatar (Q03 / Q15): Profile, Settings,
/// Downloads, Orders and Notifications without adding bottom tabs.
Future<void> showAccountMenu(BuildContext context) {
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => Consumer(
      builder: (c, ref, _) {
        final t = Theme.of(c);
        final p = ref.watch(profileProvider).valueOrNull;
        void go(String path) {
          Navigator.pop(c);
          if (path == '/profile' ||
              path == '/settings' ||
              path == '/downloads') {
            router.go(path);
          } else {
            router.push(path);
          }
        }

        Widget row(IconData icon, String label, String path) => ListTile(
          leading: Icon(icon, color: t.colorScheme.primary),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => go(path),
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: hSlateGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        photoUrl: p?.photoUrl,
                        radius: 26,
                        fallback: p?.firstName ?? 'H',
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p?.fullName ?? 'Your account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              p == null
                                  ? 'PHARM D WITH HYZEN'
                                  : ReferenceData.yearLabel(p.professionalYear),
                              style: t.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => go('/profile'),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                row(Icons.settings_outlined, 'Settings', '/settings'),
                row(Icons.download_done_rounded, 'Downloads', '/downloads'),
                row(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  '/notifications',
                ),
                row(Icons.receipt_long_outlined, 'My orders', '/orders'),
              ],
            ),
          ),
        );
      },
    ),
  );
}
