import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/pdf_studio/presentation/scan_pdf_screen.dart';
import 'package:hyzen_pharmd/features/pdf_studio/presentation/scan_review_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.hyzen.pharmd/camera_pages');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  test(
    'perspective corners are independent and crossed quads are rejected',
    () {
      const points = [
        Offset(.08, .18),
        Offset(.86, .05),
        Offset(.98, .9),
        Offset(.2, .98),
      ];
      expect(validCropQuad(points), isTrue);
      expect(
        validCropQuad([points[0], points[2], points[1], points[3]]),
        isFalse,
      );
      expect(
        validCropQuad([
          const Offset(.5, .5),
          const Offset(.51, .5),
          const Offset(.51, .51),
          const Offset(.5, .51),
        ]),
        isFalse,
      );
    },
  );
  testWidgets(
    'auto detect reads original and waits for Apply before mutating',
    (tester) async {
      final calls = <MethodCall>[];
      const detected = [.1, .2, .9, .1, .8, .9, .2, .8];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'pageInfo' => {
            'original': '/tmp/raw.jpg',
            'quad': [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0],
          },
          'detect' => detected,
          _ => ['/tmp/rendered.jpg'],
        };
      });
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ScanPdfScreen())),
      );
      await tester.pumpAndSettle();
      expect(find.text('File name'), findsNothing);
      await tester.tap(find.text('Auto detect'));
      await tester.pumpAndSettle();
      expect(
        calls.singleWhere((c) => c.method == 'detect').arguments['path'],
        '/tmp/raw.jpg',
      );
      expect(calls.where((c) => c.method == 'adjust'), isEmpty);
      final canvas = tester.widget<ScanReviewCanvas>(
        find.byType(ScanReviewCanvas),
      );
      expect(canvas.path, '/tmp/raw.jpg');
      expect(canvas.quad[0], const Offset(.1, .2));
      // Changing just the top-left corner must leave the other three untouched.
      canvas.onQuad([const Offset(.14, .24), ...canvas.quad.skip(1)]);
      await tester.pump();
      await tester.tap(find.text('Apply crop'));
      await tester.pumpAndSettle();
      expect(calls.singleWhere((c) => c.method == 'adjust').arguments['quad'], [
        .14,
        .24,
        .9,
        .1,
        .8,
        .9,
        .2,
        .8,
      ]);
      expect(find.text('Save PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'cancel naming keeps pages and does not compose or clear draft',
    (tester) async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return ['/tmp/one.jpg'];
      });
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ScanPdfScreen())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save PDF'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('File name'))).pop();
      await tester.pumpAndSettle();
      expect(calls, isNot(contains('clear')));
      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
