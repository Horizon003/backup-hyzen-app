import 'package:flutter/material.dart';

/// An optional original Hyzen avatar is stored as `avatar:<id>` in photoUrl.
/// Remote gallery photos keep their normal HTTPS URL.
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

  static const choices = [
    'male_1',
    'male_2',
    'male_3',
    'female_1',
    'female_2',
    'female_3',
  ];

  static ImageProvider? imageFor(String? value) {
    if (value == null) return null;
    if (value.startsWith('avatar:') &&
        choices.contains(value.substring('avatar:'.length))) {
      return AssetImage(
        'assets/avatars/${value.substring('avatar:'.length)}.webp',
      );
    }
    final uri = Uri.tryParse(value);
    return uri?.scheme == 'https' ? NetworkImage(value) : null;
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    foregroundImage: imageFor(photoUrl),
    onForegroundImageError: imageFor(photoUrl) == null ? null : (_, __) {},
    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    child: Text(
      fallback.isEmpty ? 'H' : fallback[0].toUpperCase(),
      style: TextStyle(
        fontSize: radius * .8,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );
}
