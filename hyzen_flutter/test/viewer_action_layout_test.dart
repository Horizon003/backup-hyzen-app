import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'the preview save action leaves readable text on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Keep this note for offline reading'),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('Keep this note for offline reading')).width,
        greaterThan(80),
      );
    },
  );
}
