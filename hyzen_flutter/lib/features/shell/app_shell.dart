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
            content: const Column(mainAxisSize: MainAxisSize.min, children: [
              ProfileAvatar(photoUrl: 'avatar:male_1', radius: 44),
              SizedBox(height: 16), Text('Ready to take a break? Your study progress and downloads are saved.'),
            ]),
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
                    'PDF Studio',
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.headlineMedium?.copyWith(
                        color: title == 'PHARM D'
                            ? t.colorScheme.primary
                            : null,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              ...actions,
              const NotificationBell(),
              Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(profileProvider).valueOrNull;
                  return IconButton(
                    tooltip: 'Profile',
                    onPressed: () => context.go('/profile'),
                    icon: ProfileAvatar(
                      photoUrl: profile?.photoUrl,
                      radius: 14,
                      fallback: profile?.firstName ?? 'H',
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
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
