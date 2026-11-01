import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/core/widgets/profile_avatar.dart';

void main() {
  test('legacy student avatar references resolve to Hyzen panda', () {
    for (final id in [
      'male_1', 'male_2', 'male_3',
      'female_1', 'female_2', 'female_3',
    ]) {
      expect(ProfileAvatar.imageFor('avatar:$id'), isA<ResizeImage>());
    }
    expect(ProfileAvatar.imageFor(null), isA<ResizeImage>());
  });

  test('uploaded HTTPS student photos remain available', () {
    expect(
      ProfileAvatar.imageFor('https://example.org/photo.jpg'),
      isA<NetworkImage>(),
    );
  });
}
