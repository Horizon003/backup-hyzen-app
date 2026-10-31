import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/profile_avatar.dart';

/// The approved account surfaces are always dark, independently of study theme.
abstract final class AccountStyle {
  static const background = Color(0xFF000000);
  static const card = Color(0xFF29292D);
  static const raised = Color(0xFF38383D);
  static const secondary = Color(0xFFA7A7AE);
  static const destructive = Color(0xFFFF6053);
  static const link = Color(0xFF72BEF1);
  static const divider = Color(0xFF454549);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    const scheme = ColorScheme.dark(
      primary: link,
      onPrimary: Colors.black,
      surface: card,
      onSurface: Colors.white,
      onSurfaceVariant: secondary,
      outlineVariant: divider,
      primaryContainer: Color(0xFF1D1D20),
      onPrimaryContainer: secondary,
      error: destructive,
    );
    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      dividerColor: divider,
      cardTheme: const CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: const TextStyle(color: secondary),
        labelStyle: const TextStyle(color: secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AccountTheme extends StatelessWidget {
  const AccountTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: AccountStyle.theme(context),
    child: child,
  );
}

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.title,
    required this.children,
    required this.onBack,
    this.close = false,
    this.onRefresh,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback onBack;
  final bool close;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => AccountTheme(
    child: Builder(builder: (context) {
      final scroll = ListView(
        key: PageStorageKey('account-$title'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          Row(children: [
            if (!close) ...[
              CircularNavigationButton(onPressed: onBack),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(title, style: TextStyle(
                fontSize: close ? 23 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
              )),
            ),
            if (close) CircularNavigationButton(
              onPressed: onBack,
              close: true,
            ),
          ]),
          SizedBox(height: close ? 32 : 28),
          ...children,
        ],
      );
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.black,
          systemNavigationBarColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: AccountStyle.background,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: onRefresh == null ? scroll : RefreshIndicator(
                  onRefresh: onRefresh!, child: scroll,
                ),
              ),
            ),
          ),
        ),
      );
    }),
  );
}

class CircularNavigationButton extends StatelessWidget {
  const CircularNavigationButton({
    super.key, required this.onPressed, this.close = false,
  });
  final VoidCallback onPressed;
  final bool close;
  @override
  Widget build(BuildContext context) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AccountStyle.raised, Color(0xFF1D1D20)],
      ),
      border: Border.all(color: const Color(0xFF464649)),
    ),
    child: IconButton(
      tooltip: close ? 'Close account' : 'Back',
      onPressed: onPressed,
      color: const Color(0xFFE5E5E8),
      icon: Icon(close ? Icons.close_rounded : Icons.chevron_left_rounded,
        size: close ? 31 : 36),
    ),
  );
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children, this.raised = false});
  final List<Widget> children;
  final bool raised;
  @override
  Widget build(BuildContext context) => Material(
    color: raised ? AccountStyle.raised : AccountStyle.card,
    borderRadius: BorderRadius.circular(30),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Divider(height: 1, thickness: .7),
          ),
          children[i],
        ],
      ],
    ),
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key, required this.title, this.value, this.subtitle,
    this.onTap, this.trailing, this.destructive = false,
  });
  final String title;
  final String? value, subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(children: [
          Expanded(
            flex: value == null ? 1 : 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                color: destructive ? AccountStyle.destructive : Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16,
              )),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(
                  color: AccountStyle.secondary, fontSize: 12, height: 1.5,
                )),
              ],
            ]),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Expanded(flex: 5, child: Text(value!, textAlign: TextAlign.end,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AccountStyle.secondary,
                fontSize: 15, fontWeight: FontWeight.w600),
            )),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 12), trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF77777C), size: 25),
          ],
        ]),
      ),
    ),
  );
}

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({
    super.key, required this.name, required this.subtitle,
    required this.photoUrl, required this.onTap,
  });
  final String name, subtitle;
  final String? photoUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SettingsCard(
    raised: true,
    children: [InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ProfileAvatar(photoUrl: photoUrl, fallback: name, radius: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AccountStyle.secondary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          )),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
            color: Color(0xFF77777C), size: 26),
        ]),
      ),
    )],
  );
}

class AccountSectionHeader extends StatelessWidget {
  const AccountSectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
    child: Text(title, style: const TextStyle(
      color: AccountStyle.secondary, fontSize: 13, fontWeight: FontWeight.w600,
    )),
  );
}

class RoundedPrimaryButton extends StatelessWidget {
  const RoundedPrimaryButton({
    super.key, required this.label, required this.onPressed, this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 58),
      backgroundColor: Colors.white, foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    onPressed: loading ? null : onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: loading ? const SizedBox(width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
    ),
  );
}

class DestructiveActionButton extends StatelessWidget {
  const DestructiveActionButton({
    super.key, required this.label, required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SettingsCard(children: [
    SettingsRow(title: label, destructive: true, onTap: onPressed,
      trailing: const SizedBox.shrink()),
  ]);
}

/// Controlled switch: the owner persists the value. Keyboard and screen reader
/// activation use the same callback as touch, with a full 60x48 hit target.
class AccountToggle extends StatelessWidget {
  const AccountToggle({
    super.key, required this.value, required this.onChanged, required this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  @override
  Widget build(BuildContext context) {
    void activate() => onChanged?.call(!value);
    return Semantics(
      label: label, toggled: value, enabled: onChanged != null,
      onTap: onChanged == null ? null : activate,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: onChanged != null,
          mouseCursor: onChanged == null ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) { activate(); return null; },
            ),
          },
          child: Builder(builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : activate,
            child: SizedBox(width: 60, height: 48,
              child: Center(child: Container(
                width: 56, height: 34,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AccountStyle.raised,
                  borderRadius: BorderRadius.circular(22),
                  border: Focus.of(context).hasFocus
                    ? Border.all(color: AccountStyle.link, width: 2) : null,
                ),
                child: Stack(children: [
                  Positioned(
                    top: 7, left: value ? 7 : null, right: value ? null : 6,
                    child: value
                      ? const SizedBox(height: 14, child: VerticalDivider(
                          width: 3, thickness: 2, color: AccountStyle.secondary))
                      : Container(width: 14, height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: AccountStyle.secondary))),
                  ),
                  AnimatedAlign(
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Container(width: 30, height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                  ),
                ]),
              )),
            ),
          )),
        ),
      ),
    );
  }
}
