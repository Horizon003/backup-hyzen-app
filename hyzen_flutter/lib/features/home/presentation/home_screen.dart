import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/mascot_motion.dart';
import '../../academics/domain/models.dart';
import '../../academics/presentation/library_screens.dart';
import '../../academics/presentation/discovery_widgets.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_models.dart';
import '../../shell/app_shell.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../data/recent_controller.dart';
import '../../pdf_studio/data/pdf_studio_repository.dart';
import '../../downloads/data/downloads_controller.dart';
import '../../auth/domain/reference_data.dart';

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

    final libraryCount = kinds.isEmpty
        ? null
        : kinds
              .map(
                (k) =>
                    ref.watch(libraryProvider(k)).valueOrNull?.data.fileCount,
              )
              .whereType<int>()
              .fold<int>(0, (a, b) => a + b);
    final studioCount = ref.watch(pdfStudioHistoryProvider).length;
    final saved = ref
        .watch(downloadsProvider)
        .values
        .where((r) => r.isReady)
        .length;

    return TabPage(
      title: 'PHARM D',
      subtitle: 'WITH HYZEN',
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
              HEntrance(
                child: _GreetingHero(
                  eyebrow: _greet(),
                  title: newAccount ? 'Welcome, $name' : 'Welcome back, $name',
                  year: p == null
                      ? null
                      : ReferenceData.yearLabel(p.professionalYear),
                  onStudy: () => context.go('/study'),
                ),
              ),
              const Gap(HSpace.md),
              _SearchBar(onTap: () => context.go('/search', extra: true)),
              if (ann != null) ...[
                const Gap(HSpace.md),
                _AnnouncementBar(a: ann),
              ],
              const Gap(HSpace.lg),
              const SectionHeader(title: 'Quick access'),
              const Gap(4),
              GridView(
                padding: EdgeInsets.zero,
                primary: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: HSpace.sm,
                  crossAxisSpacing: HSpace.sm,
                  mainAxisExtent:
                      88 *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
                ),
                children: [
                  _QuickTile(
                    icon: Icons.local_library_rounded,
                    color: HColors.primary,
                    title: 'Study Library',
                    sub: libraryCount == null
                        ? 'Notes, MCQs, PPS'
                        : '$libraryCount files',
                    onTap: () => context.go('/study'),
                  ),
                  _QuickTile(
                    icon: Icons.document_scanner_rounded,
                    color: HColors.info,
                    title: 'PDF Studio',
                    sub: studioCount == 0
                        ? 'Scan & create'
                        : '$studioCount documents',
                    onTap: () => context.go('/pdf-studio'),
                  ),
                  _QuickTile(
                    icon: Icons.download_done_rounded,
                    color: HColors.papers,
                    title: 'Downloads',
                    sub: saved == 0 ? 'Read offline' : '$saved saved',
                    onTap: () => context.go('/downloads'),
                  ),
                  if (shopOn)
                    _QuickTile(
                      icon: Icons.storefront_rounded,
                      color: HColors.special,
                      title: 'Shop',
                      sub: settings.shopComingSoon
                          ? 'Coming soon'
                          : 'Study essentials',
                      onTap: () => context.go('/shop'),
                    )
                  else
                    _QuickTile(
                      icon: Icons.search_rounded,
                      color: HColors.special,
                      title: 'Search',
                      sub: 'Find any topic',
                      onTap: () => context.go('/search', extra: true),
                    ),
                ],
              ),
              if (recent.isNotEmpty) ...[
                const Gap(HSpace.lg),
                SectionHeader(
                  title: 'Continue studying',
                  action: 'Clear',
                  onAction: () => ref.read(recentProvider.notifier).clear(),
                ),
                for (final r in recent.take(3))
                  FileTile(file: r.file, color: kindColor(r.file.kind)),
              ],
              const Gap(HSpace.md),
              const SubjectDiscovery(),
              const Gap(HSpace.md),
              const SectionHeader(title: 'More from Hyzen'),
              const Gap(4),
              HCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (settings.sectionEnabled('blog'))
                      _LinkRow(
                        icon: Icons.article_outlined,
                        title: 'Blog',
                        subtitle: 'Articles & study updates',
                        onTap: () => context.push('/blog'),
                      ),
                    if (settings.sectionEnabled('about'))
                      _LinkRow(
                        icon: Icons.info_outline_rounded,
                        title: 'About Hyzen',
                        subtitle: 'The people behind your journey',
                        onTap: () => context.push('/about'),
                      ),
                    _LinkRow(
                      icon: Icons.mail_outline_rounded,
                      title: 'Contact us',
                      subtitle: 'Send a message to the team',
                      onTap: () => context.push('/contact'),
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.eyebrow,
    required this.title,
    required this.onStudy,
    this.year,
  });
  final String eyebrow, title;
  final String? year;
  final VoidCallback onStudy;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final hideArt = MediaQuery.textScalerOf(context).scale(1) > 1.6;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: hSlateGradient,
        borderRadius: BorderRadius.circular(HRadius.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          if (!hideArt)
            const Positioned(
              right: -24,
              bottom: -28,
              child: HyzenMascot(
                state: HyzenMascotState.peeking,
                size: 150,
                semanticLabel: 'Hyzen panda welcoming you home',
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, hideArt ? 20 : 140, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: t.textTheme.labelSmall?.copyWith(
                    color: HColors.mint,
                    letterSpacing: 1.1,
                  ),
                ),
                const Gap(6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (year != null) ...[
                  const Gap(8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(HRadius.pill),
                    ),
                    child: Text(
                      year!,
                      style: t.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ],
                const Gap(14),
                FilledButton.icon(
                  onPressed: onStudy,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HColors.slate,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(HRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Continue to Study'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Search',
      child: Material(
        color: t.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HRadius.md),
          side: BorderSide(color: t.colorScheme.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(HRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: t.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search subjects, topics or files',
                    style: t.textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: t.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: t.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: IconBadge(icon: icon, color: HColors.primary, size: 38),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!last) const Divider(indent: 70, height: 1),
      ],
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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color, size: 32),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: t.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(fontSize: 10.5),
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
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .25),
        ),
        borderRadius: BorderRadius.circular(HRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.campaign_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              a.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (a.linkUrl.isNotEmpty)
            TextButton(
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
