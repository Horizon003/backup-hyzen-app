import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class PickerOption<T> {
  const PickerOption({required this.value, required this.title, this.subtitle});
  final T value;
  final String title;
  final String? subtitle;
}

/// Opens a searchable bottom sheet and returns the chosen value.
Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  T? selected,
  String hint = 'Search',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
      hint: hint,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    this.selected,
    required this.hint,
  });
  final String title;
  final List<PickerOption<T>> options;
  final T? selected;
  final String hint;
  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final q = _q.toLowerCase();
    final list = widget.options
        .where(
          (o) =>
              q.isEmpty ||
              o.value == 'Other' ||
              o.title.toLowerCase().contains(q) ||
              (o.subtitle ?? '').toLowerCase().contains(q),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HSpace.screen,
                0,
                HSpace.screen,
                HSpace.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.title, style: t.textTheme.titleLarge),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: HSpace.screen),
              child: TextField(
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            const SizedBox(height: HSpace.xs),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No matches', style: t.textTheme.bodyMedium),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final o = list[i];
                        final sel = o.value == widget.selected;
                        return ListTile(
                          minTileHeight: 56,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: HSpace.screen,
                          ),
                          title: Text(o.title, style: t.textTheme.titleSmall),
                          subtitle: o.subtitle == null
                              ? null
                              : Text(o.subtitle!, style: t.textTheme.bodySmall),
                          trailing: sel
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: t.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, o.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Form-field looking tap target that opens a picker.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
    this.icon,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;
  final String? errorText;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label${value != null ? ': $value' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(HRadius.md),
        onTap: onTap,
        child: InputDecorator(
          isEmpty: value == null || value!.isEmpty,
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            prefixIcon: icon == null ? null : Icon(icon),
            suffixIcon: const Icon(Icons.expand_more_rounded),
          ),
          child: Text(
            value ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Segmented choice chips with good touch targets.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
  });
  final List<PickerOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? errorText;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: HSpace.xs,
          runSpacing: HSpace.xs,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Text(o.title),
                ),
                selected: value == o.value,
                showCheckmark: false,
                selectedColor: t.colorScheme.primary.withValues(alpha: 0.14),
                labelStyle: t.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: value == o.value
                      ? t.colorScheme.primary
                      : t.colorScheme.onSurface,
                ),
                side: BorderSide(
                  color: value == o.value
                      ? t.colorScheme.primary
                      : t.colorScheme.outlineVariant,
                ),
                onSelected: (_) => onChanged(o.value),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(errorText!, style: t.inputDecorationTheme.errorStyle),
          ),
      ],
    );
  }
}
