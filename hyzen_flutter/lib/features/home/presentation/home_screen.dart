import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/links.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/main_dock.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/theme/app_theme.dart';
import '../../downloads/domain/download_record.dart';
import 'home_background.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../notifications/notifications_screen.dart';
import '../../academics/domain/models.dart';
import '../../academics/presentation/library_screens.dart';
import '../../academics/presentation/discovery_widgets.dart';
import '../../content/data/content_providers.dart';
import '../../shell/app_shell.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../data/recent_controller.dart';
import '../../downloads/data/downloads_controller.dart';

// The reference artwork is decorative; all controls below are live Flutter UI.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
String homeGreeting(DateTime time) => time.hour < 12 ? 'Good morning' : time.hour < 17 ? 'Good afternoon' : 'Good evening';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settings = ref.watch(siteSettingsProvider);
    final recent = ref.watch(recentProvider);
    final ann = ref.watch(boolPrefProvider('pref_announcements')) ? ref.watch(announcementProvider) : null;
    final name = profile?.firstName ?? user?.displayName?.split(' ').first ?? 'there';
    final fresh = ref.watch(lastCreatedProfileProvider)?.uid == user?.uid;
    final counts = ref.watch(downloadsProvider.select((map) => (
      map.values.where((r) => r.status == DownloadStatus.downloading).length,
      map.values.where((r) => r.isAvailableOffline).length,
      map.values.where((r) => r.isAvailableOffline && r.unopened).length,
    )));
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final badges = [if(counts.$1 > 0) '${counts.$1} Downloading', if(counts.$2 > 0) '${counts.$2} Saved', if(counts.$3 > 0) '${counts.$3} New'];
    Widget grid(List<Widget> children, double height) => GridView(
      shrinkWrap: true, primary: false, padding: EdgeInsets.zero, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: scale > 1.3 ? 1 : 2, mainAxisExtent: height * scale.clamp(1, 2), mainAxisSpacing: 12, crossAxisSpacing: 12), children: children);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light,
      child: TabPage(title: 'PHARM D', integratedHeader: true, headerTheme: AppTheme.dark(),
        header: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Tooltip(message: 'Profile & settings', child: InkWell(onTap: () => showAccountMenu(context), customBorder: const CircleBorder(), child: Container(width: 48, height: 48, padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), child: ClipOval(child: profile?.photoUrl != null ? ProfileAvatar(photoUrl: profile!.photoUrl, radius: 20, fallback: name) : Image.asset('assets/brand/hyzen_icon_square.png', fit: BoxFit.cover))))),
          const Spacer(), const NotificationBell(),
        ]))),
        homeBackground: (child) => HomeAtmosphere(child: child),
        onRefresh: () => refreshContent(ref, ['pw_settings', 'pw_announcement', ...LibraryKind.values.map((k) => k.storageKey)]),
        slivers: [SliverToBoxAdapter(child: Column(children: [
          SizedBox(height: scale > 1.5 ? 370 * scale.clamp(1, 2) : 280, child: Stack(children: [
            Positioned.fill(child: Image.asset('assets/home/mountain_panda.webp', key: const ValueKey('home-hero-art'), fit: BoxFit.cover, alignment: Alignment.bottomCenter, semanticLabel: 'Hyzen panda reading above mountains and clouds')),
            Positioned(top: 32, left: 16, right: scale > 1.5 ? 16 : 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(homeGreeting(ref.watch(homeClockProvider)()).toUpperCase(), key: const ValueKey('home-greeting'), style: const TextStyle(color: Color(0xFFE3E3E5), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
              const Gap(8), Tooltip(message: name, child: Text(fresh ? 'Welcome, $name' : 'Welcome back, $name', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.15, fontWeight: FontWeight.w800))),
              const Gap(14), FilledButton.icon(onPressed: () => context.go('/study'), icon: const Icon(Icons.arrow_forward_rounded, size: 20), label: const Text('Continue to Study'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: const Size(48, 48), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: const StadiumBorder())),
            ])),
          ])),
          HomeAtmosphere(content: true, child: Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + MainDock.contentInset(context)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Transform.translate(offset: const Offset(0,-18), child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0,12))]), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(32), clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => context.go('/search', extra: true), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: Row(children: [Icon(Icons.search, color: Colors.black), Gap(10), Expanded(child: Text('Search subjects, topics or files', style: TextStyle(color: Colors.black, fontSize: 13))), Icon(Icons.arrow_forward, color: Colors.black)])))))),
            if(ann != null) Padding(padding: const EdgeInsets.only(bottom: 24), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: dark ? const Color(0xFF29292D) : const Color(0xFFE3E3E5), borderRadius: BorderRadius.circular(24)), child: Row(children: [Icon(Icons.campaign_outlined, color: dark ? Colors.white : Colors.black, size: 20), const Gap(10), Expanded(child: Text(ann.text, style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.w600))), if(ann.linkUrl.isNotEmpty) TextButton(onPressed: () => openLink(context, ann.linkUrl), child: Text(ann.linkText.isEmpty ? 'Open' : ann.linkText))]))),
            grid([
              _ReferenceCard(title: 'Study Library', subtitle: 'Your academic library', icon: Icons.menu_book_outlined, art: 'books', black: !dark, onTap: () => context.go('/study')),
              _ReferenceCard(title: 'Office Workspace', subtitle: 'Scan, read & create', icon: Icons.document_scanner_outlined, art: 'papers', onTap: () => context.go('/pdf-studio')),
            ], 142),
            const Gap(20), Row(children: [Text('Others', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w800)), const Gap(14), Expanded(child: Divider(color: dark ? const Color(0xFF55555A) : const Color(0xFFD0D0D4)))]), const Gap(14),
            grid([
              settings.sectionEnabled('shop') ? _ReferenceCard(title: 'Shop', subtitle: settings.shopComingSoon ? 'Coming soon' : 'Study essentials', icon: Icons.storefront_outlined, art: 'shop', onTap: () => context.go('/shop')) : _ReferenceCard(title: 'Search', subtitle: 'Find your next topic', icon: Icons.search, art: 'books', onTap: () => context.go('/search', extra: true)),
              _ReferenceCard(title: 'Downloads', subtitle: 'Read anywhere, offline', icon: Icons.file_download_outlined, art: 'downloads', badges: badges, onTap: () => context.go('/downloads')),
            ], badges.isEmpty ? 116 : 152),
            if(recent.isNotEmpty) ...[const Gap(24), SectionHeader(title: 'Continue studying', action: 'Clear', onAction: () async { if(await confirmDialog(context, title: 'Clear recent history?', message: 'Only the list of recently opened files will be cleared. Your downloads and original documents stay saved.', confirm: 'Clear history')) { await ref.read(recentProvider.notifier).clear(); } }), for(final item in recent.take(3)) FileTile(file: item.file, color: Theme.of(context).colorScheme.primary, compact: true)],
            const Gap(16), const SubjectDiscovery(compact: true),
          ]))),
        ]))],
      ));
  }
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.title, required this.subtitle, required this.icon, required this.art, required this.onTap, this.black = false, this.badges = const []});
  final String title, subtitle, art;
  final IconData icon;
  final VoidCallback onTap;
  final bool black;
  final List<String> badges;
  @override
  Widget build(BuildContext context) {
    final ink = black ? Colors.white : Colors.black;
    return Semantics(button: true, label: [title, ...badges].join(', '), child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0,9))]), child: Material(color: black ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: BorderRadius.circular(26), clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Stack(children: [
      Positioned(right: -6, bottom: -8, child: ExcludeSemantics(child: Image.asset('assets/home/$art.webp', width: 72, height: 76, fit: BoxFit.contain))),
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: ink, size: 25), const Spacer(), Icon(Icons.arrow_outward, color: ink, size: 17)]), const Spacer(), Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2)), const Gap(9), Padding(padding: const EdgeInsets.only(right: 35), child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink.withValues(alpha: .72), fontSize: 11))), if(badges.isNotEmpty) ...[const Gap(6), Wrap(spacing: 4, runSpacing: 3, children: [for(final badge in badges) Text(badge, style: TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w700))])],
      ])),
    ])))));
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
