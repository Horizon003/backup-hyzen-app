import 'dart:async';
import 'profile_promotions.dart';
import '../../academics/data/drive_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../updates/update_ui.dart';
import '../../content/data/content_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/config/brand.dart';
import '../../../core/utils/media_upload.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/palettes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/searchable_picker.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../core/storage/local_store.dart';
import '../../auth/domain/reference_data.dart';
import '../../auth/domain/student_profile.dart';
import '../../auth/presentation/auth_controllers.dart';
import '../../downloads/data/downloads_controller.dart';
import '../../downloads/domain/download_record.dart';
import '../../home/data/recent_controller.dart';
import '../../content/data/content_source.dart';
import '../../shell/app_shell.dart';

Future<void> logout(BuildContext context, WidgetRef ref) async {
  if (!await confirmDialog(
    context,
    title: 'Log out?',
    message: 'Your downloads stay on this device.',
    confirm: 'Log out',
  )) {
    return;
  }
  await DriveGateway.instance.disconnect();
  await ref.read(authRepositoryProvider).signOut();
  ref.read(lastCreatedProfileProvider.notifier).state = null;
  if (context.mounted) context.go('/welcome');
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final admin = ref.watch(isAdminProvider);
    final pa = ref.watch(profileProvider);
    final p = pa.valueOrNull;
    Widget row(IconData i, String k, String? v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(i, size: 20, color: t.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(width: 110, child: Text(k, style: t.textTheme.bodySmall)),
          Expanded(
            child: Text(
              (v ?? '').isEmpty ? '\u2014' : v!,
              style: t.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
    final display = admin
        ? 'Administrator'
        : (p?.fullName ?? user?.displayName ?? 'Student');
    return TabPage(
      title: 'Profile',
      onRefresh: () async {
        ref.invalidate(profileProvider);

        await ref.read(profileProvider.future);
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              SurfacePanel(
                tint: t.brightness == Brightness.light
                    ? t.colorScheme.primaryContainer.withValues(alpha: .4)
                    : t.colorScheme.surfaceContainerHigh,
                radius: HRadius.xl,
                padding: const EdgeInsets.all(HSpace.lg),
                child: Row(
                  children: [
                    ProfileAvatar(
                      photoUrl: p?.photoUrl ?? user?.photoURL,
                      fallback: display,
                    ),
                    const SizedBox(width: HSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            display,
                            style: t.textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          StatusPill(
                            label: admin ? 'Admin' : 'Student',
                            color: HColors.primary,
                            icon: admin
                                ? Icons.verified_user_rounded
                                : Icons.school_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              const ProfilePromotions(),
              const Gap(HSpace.md),
              if (admin)
                ResourceTile(
                  icon: Icons.admin_panel_settings_rounded,
                  color: HColors.primary,
                  title: 'Admin dashboard',
                  subtitle: 'Orders, messages and content status',
                  onTap: () => context.push('/admin'),
                ),
              if (!admin)
                PanelBlock(
                  child: pa.isLoading && p == null
                      ? const SkeletonList(count: 3, height: 28)
                      : p == null
                      ? TextButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Complete your profile'),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Academic details',
                                    style: t.textTheme.titleMedium,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.push('/profile/edit'),
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Edit'),
                                ),
                              ],
                            ),
                            row(
                              Icons.workspace_premium_rounded,
                              'Year',
                              ReferenceData.yearLabel(p.professionalYear),
                            ),
                            row(
                              Icons.apartment_rounded,
                              'Institution',
                              p.institutionName,
                            ),
                            row(
                              Icons.account_balance_rounded,
                              'Affiliation',
                              p.affiliationDisplay ?? 'Non-affiliated',
                            ),
                            row(Icons.badge_rounded, 'Roll no.', p.rollNumber),
                            const Divider(),
                            row(
                              Icons.phone_rounded,
                              'Mobile',
                              p.mobile.isEmpty
                                  ? null
                                  : PkPhone.pretty(p.mobile),
                            ),
                            row(Icons.location_city_rounded, 'City', p.city),
                            row(
                              Icons.person_rounded,
                              'Gender',
                              ReferenceData.genders[p.gender] ?? p.gender,
                            ),
                          ],
                        ),
                ),
              const Gap(HSpace.md),
              ResourceTile(
                icon: Icons.receipt_long_rounded,
                color: HColors.info,
                title: 'My orders',
                subtitle: 'Orders placed from this device',
                onTap: () => context.push('/orders'),
              ),
              ResourceTile(
                icon: Icons.tune_rounded,
                color: HColors.teal,
                title: 'Settings',
                subtitle: 'Theme, storage, notifications',
                onTap: () => context.push('/settings'),
              ),
              ResourceTile(
                icon: Icons.mail_rounded,
                color: HColors.primary,
                title: 'Contact us',
                onTap: () => context.push('/contact'),
              ),
              ResourceTile(
                icon: Icons.favorite_rounded,
                color: HColors.lectures,
                title: 'About PHARM D WITH HYZEN',
                onTap: () => context.push('/about'),
              ),
              const Gap(HSpace.sm),
              HButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                outlined: true,
                onPressed: () => logout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Edit safe fields only (uid/email/role/createdAt immutable — enforced in rules too).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  StudentProfile? _p;
  late TextEditingController _name, _mobile, _inst, _roll, _customUni;
  String? _city;
  int? _year;
  AffiliationStatus? _aff;
  String? _uni;
  bool _busy = false, _photoBusy = false, _saved = false;
  String? _photo;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _p =
        ref.read(profileProvider).valueOrNull ??
        (user == null
            ? null
            : StudentProfile(
                uid: user.uid,
                fullName: user.displayName ?? '',
                mobile: '',
                gender: 'other',
                city: '',
                professionalYear: 1,
                institutionName: '',
                affiliationStatus: AffiliationStatus.nonAffiliated,
                email: user.email ?? '',
              ));
    final p = _p;
    _photo = p?.photoUrl ?? user?.photoURL;
    _name = TextEditingController(text: p?.fullName ?? '');
    _mobile = TextEditingController(
      text: PkPhone.normalize(p?.mobile ?? '') == null
          ? ''
          : '0${PkPhone.normalize(p!.mobile)!.substring(3)}',
    );
    _inst = TextEditingController(text: p?.institutionName ?? '');
    _roll = TextEditingController(text: p?.rollNumber ?? '');
    _customUni = TextEditingController(text: p?.customUniversity ?? '');
    _city = p?.city;
    _year = p?.professionalYear;
    _aff = p?.affiliationStatus;
    _uni =
        p?.affiliatedUniversity?.id ??
        ((p?.customUniversity ?? '').isNotEmpty ? ReferenceData.otherId : null);
  }

  @override
  void dispose() {
    for (final c in [_name, _mobile, _inst, _roll, _customUni]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final p = _p;
    if (p == null || !_form.currentState!.validate()) return;
    if (_aff == AffiliationStatus.affiliated && _uni == null) {
      showHSnack(context, 'Select your affiliated university', error: true);
      return;
    }
    setState(() => _busy = true);
    final known = ReferenceData.universityById(_uni);
    final next = p.copyWith(
      photoUrl: _photo,
      fullName: _name.text.trim(),
      mobile: PkPhone.normalize(_mobile.text),
      city: _city,
      professionalYear: _year,
      institutionName: _inst.text.trim(),
      affiliationStatus: _aff,
      clearUniversity: true,
      affiliatedUniversity: _aff == AffiliationStatus.affiliated ? known : null,
      customUniversity:
          _aff == AffiliationStatus.affiliated && _uni == ReferenceData.otherId
          ? _customUni.text.trim()
          : null,
      rollNumber: _roll.text.trim(),
    );
    try {
      final pending = ref.read(pendingProfileStoreProvider);
      await pending.save(p.uid, next.toWriteMap());
      // The profile stream retries cloud writes; local edits appear immediately.
      ref.invalidate(profileProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      unawaited(() async {
        try {
          await user?.updateDisplayName(next.fullName);
          if (next.photoUrl?.startsWith('https://') == true) {
            await user?.updatePhotoURL(next.photoUrl);
          }
        } catch (_) {}
      }());
      if (mounted) {
        _p = next;
        setState(() => _saved = true);
        showHSnack(context, 'Changes saved');
      }
    } catch (e) {
      if (mounted) {
        showHSnack(
          context,
          'Couldn\u2019t save. Check your connection and try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_p == null) {
      return const Scaffold(
        appBar: HTopBar(title: 'Edit profile'),
        body: EmptyState(
          icon: Icons.person_off_rounded,
          title: 'Profile unavailable',
        ),
      );
    }
    final t = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const HTopBar(title: 'Edit profile'),
      body: HBackground(
        child: SafeArea(
          child: Form(
            key: _form,
            onChanged: () {
              if (_saved) setState(() => _saved = false);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                HSpace.screen,
                80,
                HSpace.screen,
                HSpace.xxl,
              ),
              children: [
                Center(
                  child: Column(
                    children: [
                      ProfileAvatar(
                        photoUrl: _photo,
                        radius: 44,
                        fallback: _name.text,
                      ),
                      TextButton.icon(
                        onPressed: _photoBusy
                            ? null
                            : () async {
                                setState(() => _photoBusy = true);
                                try {
                                  final url = await MediaUpload.pickAndUpload();
                                  if (url != null && mounted) {
                                    setState(() => _photo = url);
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    showHSnack(
                                      context,
                                      'Photo upload failed. Please retry.',
                                      error: true,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _photoBusy = false);
                                  }
                                }
                              },
                        icon: _photoBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Change profile photo'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final avatar in ProfileAvatar.choices)
                            InkWell(
                              onTap: () =>
                                  setState(() => _photo = 'avatar:$avatar'),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: _photo == 'avatar:$avatar' ? 3 : 1,
                                    color: _photo == 'avatar:$avatar'
                                        ? t.colorScheme.primary
                                        : t.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: ProfileAvatar(
                                  photoUrl: 'avatar:$avatar',
                                  radius: 23,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(HSpace.md),
                PanelBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Personal', style: t.textTheme.titleMedium),
                      const Gap(HSpace.md),
                      TextFormField(
                        controller: _name,
                        validator: Validators.fullName,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                      const Gap(HSpace.md),
                      TextFormField(
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onChanged: (_) => setState(() => _saved = false),
                        decoration: const InputDecoration(
                          labelText: 'Mobile',
                          hintText: '0300 1234567',
                        ),
                      ),
                      const Gap(HSpace.md),
                      PickerField(
                        label: 'City',
                        value: _city,
                        icon: Icons.location_city_rounded,
                        onTap: () async {
                          final v = await showSearchablePicker<String>(
                            context: context,
                            title: 'City',
                            options: [
                              for (final c in ReferenceData.cities)
                                PickerOption(value: c, title: c),
                              const PickerOption(
                                value: 'Other',
                                title: 'Enter my city',
                              ),
                            ],
                            selected: _city,
                          );
                          if (v == 'Other' && context.mounted) {
                            final city = TextEditingController(text: _city);
                            final chosen = await showDialog<String>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Your city'),
                                content: TextField(
                                  controller: city,
                                  autofocus: true,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'City, town or village',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(c, city.text.trim()),
                                    child: const Text('Use city'),
                                  ),
                                ],
                              ),
                            );
                            city.dispose();
                            if (chosen != null &&
                                chosen.isNotEmpty &&
                                mounted) {
                              setState(() => _city = chosen);
                            }
                          } else if (v != null && mounted) {
                            setState(() => _city = v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(HSpace.md),
                PanelBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Academic', style: t.textTheme.titleMedium),
                      const Gap(HSpace.md),
                      ChoiceRow<int>(
                        options: ReferenceData.professionalYears.entries
                            .map(
                              (e) => PickerOption(
                                value: e.key,
                                title: e.value.replaceAll(' Professional', ''),
                              ),
                            )
                            .toList(),
                        value: _year,
                        onChanged: (v) => setState(() => _year = v),
                      ),
                      const Gap(HSpace.md),
                      TextFormField(
                        controller: _inst,
                        validator: (v) => Validators.required(v, 'Institution'),
                        decoration: const InputDecoration(
                          labelText: 'College / University',
                        ),
                      ),
                      const Gap(HSpace.md),
                      ChoiceRow<AffiliationStatus>(
                        options: const [
                          PickerOption(
                            value: AffiliationStatus.affiliated,
                            title: 'Affiliated',
                          ),
                          PickerOption(
                            value: AffiliationStatus.nonAffiliated,
                            title: 'Non-affiliated',
                          ),
                        ],
                        value: _aff,
                        onChanged: (v) => setState(() => _aff = v),
                      ),
                      if (_aff == AffiliationStatus.affiliated) ...[
                        const Gap(HSpace.md),
                        PickerField(
                          label: 'Affiliated university',
                          value: _uni == ReferenceData.otherId
                              ? 'Other'
                              : ReferenceData.universityById(_uni)?.name,
                          onTap: () async {
                            final v = await showSearchablePicker<String>(
                              context: context,
                              title: 'Affiliated university',
                              options: [
                                ...ReferenceData.universities.map(
                                  (u) => PickerOption(
                                    value: u.id,
                                    title: '${u.name} (${u.shortName})',
                                    subtitle: u.city,
                                  ),
                                ),
                                const PickerOption(
                                  value: ReferenceData.otherId,
                                  title: 'Other',
                                ),
                              ],
                              selected: _uni,
                            );
                            if (v != null) setState(() => _uni = v);
                          },
                        ),
                        if (_uni == ReferenceData.otherId) ...[
                          const Gap(HSpace.md),
                          TextFormField(
                            controller: _customUni,
                            validator: (v) =>
                                Validators.required(v, 'University name'),
                            decoration: const InputDecoration(
                              labelText: 'University name',
                            ),
                          ),
                        ],
                      ],
                      const Gap(HSpace.md),
                      TextFormField(
                        controller: _roll,
                        decoration: const InputDecoration(
                          labelText: 'Roll number (optional)',
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(HSpace.lg),
                HButton(
                  label: _saved ? 'Changes saved ✓' : 'Save changes',
                  loading: _busy,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
    final notif = ref.watch(boolPrefProvider('pref_announcements'));
    final downloads = ref.watch(downloadsProvider);
    final used = downloads.values
        .where((r) => r.isReady)
        .fold(0, (s, r) => s + r.sizeBytes);
    return TabPage(
      title: 'Settings',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
          sliver: SliverList.list(
            children: [
              PanelBlock(child: Row(children: [
                ProfileAvatar(photoUrl: ref.watch(profileProvider).valueOrNull?.photoUrl,
                  fallback: ref.watch(profileProvider).valueOrNull?.fullName ?? '', radius: 27),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ref.watch(profileProvider).valueOrNull?.fullName ?? 'Your account', style: t.textTheme.titleMedium),
                  const Gap(3), const Text('Make it yours'),
                ])),
                IconButton(tooltip: 'Edit profile', onPressed: () => context.push('/profile/edit'), icon: const Icon(Icons.edit_outlined)),
              ])),
              const Gap(18),
              ResourceTile(
                icon: Icons.system_update_rounded,
                color: HColors.primary,
                title: 'App updates',
                subtitle: 'Check the latest PHARM D WITH HYZEN release',
                onTap: () =>
                    checkForUpdate(context, ref.read(siteSettingsProvider).raw),
              ),
              ResourceTile(
                icon: Icons.school_rounded,
                color: HColors.primary,
                title: 'Professional year & profile',
                subtitle: ReferenceData.yearLabel(
                  ref.watch(professionalYearProvider),
                ),
                onTap: () => context.push('/profile/edit'),
              ),
              const Gap(HSpace.md),
              PanelBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Appearance', style: t.textTheme.titleMedium),
                    const Gap(HSpace.md),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: [for (final entry in brandPalettes.entries)
                        Tooltip(message: entry.value.$1, child: Semantics(
                          label: entry.value.$1, selected: ref.watch(effectivePaletteProvider) == entry.key,
                          button: true,
                          child: InkWell(
                            onTap: () => ref.read(paletteProvider.notifier).set(entry.key),
                            customBorder: const CircleBorder(),
                            child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                              width: 44, height: 44,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: entry.value.$2,
                                border: Border.all(color: ref.watch(effectivePaletteProvider) == entry.key ? t.colorScheme.onSurface : Colors.transparent, width: 3)),
                              child: ref.watch(effectivePaletteProvider) == entry.key ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null),
                          ),
                        )),
                      ],
                    ),
                    const Gap(12),
                    Text(brandPalettes[ref.watch(effectivePaletteProvider)]!.$1, style: t.textTheme.bodySmall),
                    const Gap(16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.phone_android_rounded),
                          label: Text('Auto'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) =>
                          ref.read(themeModeProvider.notifier).set(s.first),
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              PanelBlock(
                padding: const EdgeInsets.symmetric(vertical: HSpace.sm),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: notif,
                      onChanged: (v) => ref
                          .read(boolPrefProvider('pref_announcements').notifier)
                          .set(v),
                      title: const Text('Show announcements'),
                      subtitle: const Text(
                        'Pop-up notices published by PHARM D WITH HYZEN',
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              PanelBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Storage', style: t.textTheme.titleMedium),
                    const Gap(HSpace.sm),
                    Text(
                      'Offline files: ${formatBytes(used)}',
                      style: t.textTheme.bodyMedium,
                    ),
                    if (kIsWeb)
                      Text(
                        'Save Offline is available in the Android app.',
                        style: t.textTheme.bodySmall,
                      ),
                    const Gap(HSpace.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cleaning_services_rounded),
                          label: const Text('Clear content cache'),
                          onPressed: () async {
                            await JsonBox(Boxes.contentCache).clear();
                            for (final key in publicContentKeys) {
                              forcedRefresh.add(key);
                              ref.invalidate(contentProvider(key));
                            }
                            if (context.mounted) {
                              showHSnack(
                                context,
                                'Cache cleared. Content will reload.',
                              );
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('Clear history'),
                          onPressed: () async {
                            await ref.read(recentProvider.notifier).clear();
                            if (context.mounted) {
                              showHSnack(context, 'History cleared');
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Manage downloads'),
                          onPressed: () => context.go('/downloads'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(HSpace.md),
              ResourceTile(
                icon: Icons.description_rounded,
                color: HColors.ink2,
                title: 'Terms of Use',
                onTap: () => context.push('/legal/terms'),
              ),
              ResourceTile(
                icon: Icons.privacy_tip_rounded,
                color: HColors.ink2,
                title: 'Privacy Policy',
                onTap: () => context.push('/legal/privacy'),
              ),
              ResourceTile(
                icon: Icons.info_rounded,
                color: HColors.primary,
                title: 'About ${Brand.shortName}',
                subtitle:
                    '${Brand.appName} · v${ref.watch(appVersionProvider).valueOrNull ?? '1.3.3'}',
                onTap: () => context.push('/about'),
              ),
              const Gap(HSpace.sm),
              HButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                outlined: true,
                onPressed: () => logout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
