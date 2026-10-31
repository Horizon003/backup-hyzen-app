import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../downloads/domain/download_record.dart';
import 'home_background.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/rive_mascot.dart';
import '../../academics/domain/models.dart';
import '../../academics/presentation/library_screens.dart';
import '../../academics/presentation/discovery_widgets.dart';
import '../../content/data/content_providers.dart';
import '../../content/domain/site_models.dart';
import '../../shell/app_shell.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../data/recent_controller.dart';
import '../../downloads/data/downloads_controller.dart';
import '../../auth/domain/reference_data.dart';

// A clock function keeps production greetings current and tests deterministic.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
String homeGreeting(DateTime time) => time.hour < 12 ? 'Good morning' : time.hour < 17 ? 'Good afternoon' : 'Good evening';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settings = ref.watch(siteSettingsProvider);
    final ann = ref.watch(boolPrefProvider('pref_announcements')) ? ref.watch(announcementProvider) : null;
    final recent = ref.watch(recentProvider);
    final name = p?.firstName ?? user?.displayName?.split(' ').first ?? 'there';
    final newAccount = ref.watch(lastCreatedProfileProvider)?.uid == user?.uid;
    final downloads = ref.watch(downloadsProvider).values.toList();
    final active = downloads.where((r) => r.status == DownloadStatus.downloading).length;
    final saved = downloads.where((r) => r.isAvailableOffline).length;
    final unopened = downloads.where((r) => r.isAvailableOffline && r.unopened).length;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light, child: TabPage(
      title: 'PHARM D', subtitle: 'WITH HYZEN',
      integratedHeader: true, headerTheme: AppTheme.dark(),
      homeBackground: (child) => HomeAtmosphere(child: child),
      onRefresh: () => refreshContent(ref, ['pw_settings', 'pw_announcement', ...LibraryKind.values.map((k) => k.storageKey)]),
      slivers: [SliverToBoxAdapter(child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          child: _GreetingHero(eyebrow: homeGreeting(ref.watch(homeClockProvider)()),
            title: newAccount ? 'Welcome, $name' : 'Welcome back, $name',
            year: p == null ? null : ReferenceData.yearLabel(p.professionalYear),
            onStudy: () => context.go('/study'))),
        HomeAtmosphere(content: true, child: Padding(
          padding: const EdgeInsets.fromLTRB(HSpace.screen, 18, HSpace.screen, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SearchBar(onTap: () => context.go('/search', extra: true)),
            if (ann != null) ...[const Gap(HSpace.md), _AnnouncementBar(a: ann)],
            const Gap(HSpace.lg), const SectionHeader(title: 'Quick access'), const Gap(4),
            GridView(padding: EdgeInsets.zero, shrinkWrap: true, primary: false,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: scale > 1.3 ? 1 : 2,
                mainAxisExtent: 164 * scale.clamp(1, 2), mainAxisSpacing: 12, crossAxisSpacing: 12),
              children: [
                _QuickTile(icon: Icons.auto_stories_outlined, title: 'Study Library', sub: 'Your academic library', prominent: true, onTap: () => context.go('/study')),
                _QuickTile(icon: Icons.document_scanner_outlined, title: 'Office Workspace', sub: 'Scan, read & create', onTap: () => context.go('/pdf-studio')),
                _QuickTile(icon: Icons.file_download_outlined, title: 'Downloads', sub: active + saved == 0 ? 'Read anywhere, offline' : null,
                  badges: [if (active > 0) '$active Downloading', if (saved > 0) '$saved Saved', if (unopened > 0) '$unopened New'],
                  onTap: () => context.go('/downloads')),
                settings.sectionEnabled('shop')
                  ? _QuickTile(icon: Icons.storefront_outlined, title: 'Shop', sub: settings.shopComingSoon ? 'Coming soon' : 'Study essentials', onTap: () => context.go('/shop'))
                  : _QuickTile(icon: Icons.search_rounded, title: 'Search', sub: 'Find your next topic', onTap: () => context.go('/search', extra: true)),
              ]),
            if (recent.isNotEmpty) ...[
              const Gap(HSpace.lg), SectionHeader(title: 'Continue studying', action: 'Clear', onAction: () async {
                if (await confirmDialog(context, title: 'Clear recent history?', message: 'Only the list of recently opened files will be cleared. Your downloads and original documents stay saved.', confirm: 'Clear history')) {
                  await ref.read(recentProvider.notifier).clear();
                }
              }),
              for (final item in recent.take(3)) FileTile(file: item.file, color: Theme.of(context).colorScheme.primary, compact: true),
            ],
            const Gap(HSpace.md), const SubjectDiscovery(compact: true),
          ]))),
      ]))],
    ));
  }
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.eyebrow, required this.title, required this.onStudy, this.year});
  final String eyebrow, title;
  final String? year;
  final VoidCallback onStudy;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.6;
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow.toUpperCase(), key: const ValueKey('home-greeting'), style: const TextStyle(color: Color(0xFFBEBEC4), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const Gap(10), Tooltip(message: title, child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, height: 1.2, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -.6))),
      if (year != null) ...[const Gap(10), DecoratedBox(decoration: BoxDecoration(color: const Color(0xFF353539), borderRadius: BorderRadius.circular(HRadius.pill)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text(year!, style: const TextStyle(fontSize: 11, color: Colors.white))))],
      const Gap(18), FilledButton.icon(onPressed: onStudy, icon: const Icon(Icons.arrow_forward_rounded, size: 18), label: const Text('Continue to Study', textAlign: TextAlign.center), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: HColors.ink, minimumSize: const Size(48,48), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12))),
    ]);
    final panda = SizedBox(width: large ? 100 : 120, height: large ? 135 : 180, child: const ClipRect(child: HyzenRiveMascot(state: HyzenRiveState.peeking, size: 120, semanticLabel: 'Hyzen panda welcoming you home')));
    return Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: large
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, Align(alignment: Alignment.centerRight, child: panda)])
      : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: text), const Gap(8), panda]));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(button: true, label: 'Search', child: Material(color: t.colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: t.colorScheme.outlineVariant)), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: [Icon(Icons.search_rounded, color: t.colorScheme.onSurfaceVariant, size: 22), const Gap(12), Expanded(child: Text('Search subjects, topics or files', style: t.textTheme.bodyLarge)), const Gap(8), const Icon(Icons.arrow_forward_rounded, size: 18)])))));
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.title, required this.onTap, this.sub, this.prominent = false, this.badges = const []});
  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback onTap;
  final bool prominent;
  final List<String> badges;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final dark = t.brightness == Brightness.dark;
    final ink = prominent ? Colors.white : t.colorScheme.onSurface;
    return HCard(radius: HRadius.xl, color: prominent ? (dark ? const Color(0xFF414145) : HColors.ink) : null, semanticLabel: title, padding: const EdgeInsets.all(14), onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(icon, size: 26, color: ink), const Spacer(), Icon(Icons.arrow_outward_rounded, size: 16, color: ink.withValues(alpha: .65))]),
        const Gap(10),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800)),
        if (sub != null) Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: .72))),
        if (badges.isNotEmpty) Wrap(spacing: 5, runSpacing: 5, children: [for (final label in badges) DecoratedBox(decoration: BoxDecoration(color: t.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text(label, style: t.textTheme.labelSmall?.copyWith(letterSpacing: 0, fontSize: 10, color: t.colorScheme.onSurface))))]),
      ]));
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
