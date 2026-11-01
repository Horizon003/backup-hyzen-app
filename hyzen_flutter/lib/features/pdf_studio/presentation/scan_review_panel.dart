import 'package:flutter/material.dart';
import 'scan_pdf_screen.dart';

class ScanReviewPanel extends StatelessWidget {
  const ScanReviewPanel({
    super.key,
    required this.pages,
    required this.selected,
    required this.onSelected,
  });

  final List<String> pages;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Page ${selected + 1} of ${pages.length}',
                style: theme.textTheme.labelLarge,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous page',
                onPressed: selected > 0 ? () => onSelected(selected - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: selected + 1 < pages.length
                    ? () => onSelected(selected + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -80 && selected + 1 < pages.length) {
                  onSelected(selected + 1);
                }
                if (velocity > 80 && selected > 0) onSelected(selected - 1);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Center(child: ScanPageImage(path: pages[selected])),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) => InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  width: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: index == selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: index == selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ScanPageImage(path: pages[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
