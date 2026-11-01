import 'package:flutter/material.dart';

/// Student-uploaded photos remain available. Legacy teal avatar selections
/// automatically use the existing Hyzen panda instead of deleted image assets.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 32,
    this.fallback = 'H',
  });

  final String? photoUrl;
  final double radius;
  final String fallback;

  static const pandaAsset = 'assets/mascot/mascot_idle_welcome.png';

  static ImageProvider? imageFor(String? value) {
    if (value != null) {
      final uri = Uri.tryParse(value);
      if (uri?.scheme == 'https') return NetworkImage(value);
    }
    // Decode the large source PNG at avatar resolution to reduce memory use.
    return ResizeImage.resizeIfNeeded(
      160,
      160,
      const AssetImage(pandaAsset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = imageFor(photoUrl);
    return CircleAvatar(
      radius: radius,
      foregroundImage: image,
      onForegroundImageError: (_, __) {},
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        fallback.isEmpty ? 'H' : fallback[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * .8,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
