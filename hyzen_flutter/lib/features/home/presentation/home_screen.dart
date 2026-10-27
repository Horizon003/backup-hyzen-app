import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/hyzen_art.dart';
import '../../academics/domain/models.dart';
import '../../academics/presentation/library_screens.dart';
import '../../academics/presentation/discovery_widgets.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_models.dart';
import '../../shell/app_shell.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../data/recent_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greet() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : (h < 17 ? 'Good afternoon' : 'Good evening');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final p = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settings = ref.watch(siteSettingsProvider);
    final ann = ref.watch(boolPrefProvider('pref_announcements'))
        ? ref.watch(announcementProvider)
        : null;
    final recent = ref.watch(recentProvider);
    final name = p?.firstName ?? user?.displayName?.split(' ').first ?? 'there';
    final newAccount = ref.watch(lastCreatedProfileProvider)?.uid == user?.uid;
    final kinds = LibraryKind.values
        .where((k) => settings.sectionEnabled(k.sectionId))
        .toList();
    final shopOn = settings.sectionEnabled('shop');

    return TabPage(
      title: 'PHARM D',
      subtitle: 'WITH HYZEN · Your pharmacy journey',
      onRefresh: () => refreshContent(ref, [
        'pw_settings',
        'pw_announcement',
        ...LibraryKind.values.map((k) => k.storageKey),
      ]),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              if (ann != null) ...[
                _AnnouncementBar(a: ann),
                const Gap(HSpace.md),
              ],
              HyzenBanner(
                eyebrow: _greet(),
                title: newAccount
                    ? 'Welcome to PHARM D,\n$name'
                    : 'Welcome back,\n$name',
                subtitle: 'Your next chapter in Pharm-D starts here.',
                art: 'home',
                actionLabel: 'Let’s study',
                action: () => context.go('/study'),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HRadius.lg),
                  border: Border.all(color: t.colorScheme.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: t.colorScheme.primary.withValues(alpha: .20),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: HCard(
                  onTap: () => context.go('/search', extra: true),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: t.colorScheme.primary),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'Find a subject, topic or file',
                          style: t.textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const Gap(16),
              const SectionHeader(title: 'Quick access'),
              const Gap(HSpace.sm),
              GridView(
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width < 340 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.2
                      ? 2
                      : 4,
                  mainAxisSpacing: HSpace.sm,
                  crossAxisSpacing: HSpace.sm,
                  mainAxisExtent:
                      114 *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
                ),
                children: [for (final k in kinds) _QuickCard(kind: k)],
              ),
              if (recent.isNotEmpty) ...[
                const Gap(HSpace.lg),
                SectionHeader(
                  title: 'Continue studying',
                  action: 'Clear',
                  onAction: () => ref.read(recentProvider.notifier).clear(),
                ),
                const Gap(HSpace.sm),
                for (final r in recent.take(2))
                  FileTile(file: r.file, color: kindColor(r.file.kind)),
              ],
              const Gap(HSpace.lg),
              const SubjectDiscovery(),
              const Gap(HSpace.sm),
              if (shopOn)
                ResourceTile(
                  icon: Icons.storefront_rounded,
                  color: HColors.special,
                  title: 'Pharm-D essentials',
                  subtitle: settings.shopComingSoon
                      ? 'Coming soon'
                      : 'Lab essentials & study companions',
                  onTap: () => context.push('/shop'),
                ),
              if (settings.sectionEnabled('blog'))
                ResourceTile(
                  icon: Icons.article_rounded,
                  color: HColors.info,
                  title: 'Blog',
                  subtitle: 'Articles & updates',
                  onTap: () => context.push('/blog'),
                ),
              if (settings.sectionEnabled('about'))
                ResourceTile(
                  icon: Icons.favorite_rounded,
                  color: HColors.lectures,
                  title: 'About us',
                  subtitle: 'The people behind your journey',
                  onTap: () => context.push('/about'),
                ),
              ResourceTile(
                icon: Icons.mail_rounded,
                color: HColors.primary,
                title: 'Contact us',
                subtitle: 'Send a message to the team',
                onTap: () => context.push('/contact'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends ConsumerWidget {
  const _QuickCard({required this.kind});
  final LibraryKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(libraryProvider(kind)).valueOrNull?.data.fileCount;
    return _QuickTile(
      icon: kindIcon(kind),
      color: kindColor(kind),
      title: kind.shortTitle,
      sub: n == null ? '\u2026' : '$n files',
      onTap: () => context.push('/study/${kind.name}'),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return HCard(
      onTap: onTap,
      semanticLabel: title,
      color: t.brightness == Brightness.light
          ? Color.alphaBlend(color.withValues(alpha: .07), Colors.white)
          : null,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconBadge(icon: icon, color: color, size: 44),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.textTheme.labelSmall?.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub,
                style: t.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar({required this.a});
  final Announcement a;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.lerp(Theme.of(context).colorScheme.primary, Colors.black, .18)!, Theme.of(context).colorScheme.primary],
        ),
        borderRadius: BorderRadius.circular(HRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              a.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (a.linkUrl.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => openLink(context, a.linkUrl),
              child: Text(a.linkText.isEmpty ? 'Open' : a.linkText),
            ),
        ],
      ),
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});
  final String doc;
  @override
  Widget build(BuildContext context) {
    final title = doc == 'privacy' ? 'Privacy Policy' : 'Terms of Use';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HTopBar(title: title),
      body: HBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HSpace.screen,
              80,
              HSpace.screen,
              HSpace.screen,
            ),
            child: PanelBlock(
              child: Text(
                'The official $title has not been supplied yet. The Hyzen owner must provide the final text before public release.\n\n'
                'Summary of current practice: your password is handled only by Firebase Authentication; your profile '
                '(name, mobile, city, professional year, institution) is stored in your private students record; '
                'offline files stay on your device.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
