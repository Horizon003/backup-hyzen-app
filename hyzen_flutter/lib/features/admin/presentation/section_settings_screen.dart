import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../content/data/content_providers.dart';
import '../../shell/app_shell.dart';
import '../data/admin_repository.dart';

class SectionSettingsScreen extends ConsumerStatefulWidget {
  const SectionSettingsScreen({super.key});
  @override
  ConsumerState<SectionSettingsScreen> createState() =>
      _SectionSettingsScreenState();
}

class _SectionSettingsScreenState extends ConsumerState<SectionSettingsScreen> {
  String? _saving;
  Future<void> _set(String key, bool value) async {
    if (_saving != null) return;
    setState(() => _saving = key);
    try {
      await ref.read(adminRepositoryProvider).updateSections({key: value});
      await refreshContent(ref, ['pw_settings']);
      if (mounted) showHSnack(context, 'Section updated');
    } on FriendlyException catch (e) {
      if (mounted) showHSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showHSnack(
          context,
          'Could not save. Check your connection and admin access.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isAdminProvider)) {
      return const Scaffold(
        body: EmptyState(icon: Icons.lock_rounded, title: 'Admins only'),
      );
    }
    final settings = ref.watch(siteSettingsProvider);
    final loaded = ref.watch(settingsProvider);
    return TabPage(
      title: 'Section visibility',
      onRefresh: () => refreshContent(ref, ['pw_settings']),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              const HeroPanel(
                eyebrow: 'Admin',
                title: 'Choose what students see',
                subtitle:
                    'These settings apply to the app and the connected website.',
                icon: Icons.toggle_on_rounded,
              ),
              const Gap(HSpace.lg),
              if (!loaded.hasValue && loaded.isLoading) const SkeletonList(),
              if (loaded.hasError && !loaded.hasValue)
                ErrorState(
                  message: 'Could not load settings.',
                  onRetry: () => refreshContent(ref, ['pw_settings']),
                ),
              for (final entry in [
                ('notes', 'Notes'),
                ('mcqs', 'MCQs'),
                ('special', 'Special Books & Notes'),
                ('papers', 'Past Papers'),
                ('lectures', 'Lectures'),
                ('shop', 'Shop'),
                ('blog', 'Blog'),
                ('about', 'About'),
              ])
                SwitchListTile(
                  title: Text(entry.$2),
                  subtitle: Text(
                    settings.sectionEnabled(entry.$1) ? 'Visible' : 'Hidden',
                  ),
                  value: settings.sectionEnabled(entry.$1),
                  onChanged: _saving != null || !loaded.hasValue
                      ? null
                      : (v) => _set('${entry.$1}Enabled', v),
                ),
              const Divider(),
              SwitchListTile(
                title: const Text('Shop coming soon'),
                subtitle: const Text(
                  'Show the coming soon page instead of products',
                ),
                value: settings.shopComingSoon,
                onChanged: _saving != null || !loaded.hasValue
                    ? null
                    : (v) => _set('shopComingSoon', v),
              ),
              if (_saving != null) const LinearProgressIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}
