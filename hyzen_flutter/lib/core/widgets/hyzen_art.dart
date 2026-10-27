import 'package:flutter/material.dart';

class HyzenArt extends StatelessWidget {
  const HyzenArt(this.name, {super.key, this.size = 160});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/illustrations/$name.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    cacheWidth: (size * 2).round(),
    excludeFromSemantics: true,
  );
}

class HyzenBanner extends StatelessWidget {
  const HyzenBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.art,
    this.eyebrow,
    this.action,
    this.actionLabel,
  });
  final String title, subtitle, art;
  final String? eyebrow, actionLabel;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [t.colorScheme.surfaceContainerLow, t.colorScheme.primaryContainer.withValues(alpha: .55)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final hideArt = MediaQuery.textScalerOf(context).scale(1) > 1.6;
          final text = Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              hideArt ? 16 : c.maxWidth * .43,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: t.textTheme.labelSmall?.copyWith(
                      color: t.colorScheme.primary,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: c.maxWidth < 350 ? 19 : 21,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: t.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    fontSize: action != null ? 12 : 13,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: action,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            actionLabel ?? 'Explore',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: action == null ? 144 : 188),
            child: Stack(
              children: [
                if (!hideArt)
                  Positioned(
                    right: -3,
                    bottom: 0,
                    child: HyzenArt(
                      art,
                      size: (c.maxWidth * .49).clamp(120, 230),
                    ),
                  ),
                text,
              ],
            ),
          );
        },
      ),
    );
  }
}
