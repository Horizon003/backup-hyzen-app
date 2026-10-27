import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/viewer/reader_chrome.dart';

void main() {
  testWidgets('page taps toggle header while pinch and pan keep reader gestures', (tester) async {
    var scales = 0;
    await tester.pumpWidget(MaterialApp(home: ReaderScaffold(
      title: 'Notes.pdf', actions: const [],
      child: GestureDetector(onScaleUpdate: (_) => scales++, child: const ColoredBox(color: Colors.white)),
    )));
    expect(find.text('Notes.pdf'), findsOneWidget);
    final page = find.byKey(const ValueKey('reader-page-surface'));
    expect(tester.getSize(page).height, greaterThan(400));
    expect(tester.getSize(page).width, greaterThan(600));
    await tester.tapAt(tester.getCenter(page)); await tester.pumpAndSettle();
    expect(find.text('Notes.pdf'), findsNothing);
    await tester.tapAt(tester.getCenter(page)); await tester.pumpAndSettle();
    expect(find.text('Notes.pdf'), findsOneWidget);
    final center = tester.getCenter(page);
    final a = await tester.startGesture(center - const Offset(25, 0), pointer: 1);
    final b = await tester.startGesture(center + const Offset(25, 0), pointer: 2);
    await a.moveTo(center - const Offset(70, 0));
    await b.moveTo(center + const Offset(70, 0));
    await tester.pump(); await a.up(); await b.up(); await tester.pumpAndSettle();
    expect(scales, greaterThan(0));
    expect(find.text('Notes.pdf'), findsOneWidget);
  });
  testWidgets('file actions execute after the options sheet closes', (tester) async {
    var saved = false;
    await tester.pumpWidget(MaterialApp(home: ReaderScaffold(
      title: 'Notes.pdf', onShare: () {},
      actions: [ReaderAction('Save As', Icons.save_alt, () => saved = true)],
      child: const SizedBox.expand(),
    )));
    await tester.tap(find.byTooltip('File options')); await tester.pumpAndSettle();
    await tester.tap(find.text('Save As')); await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(find.text('File options'), findsNothing);
  });
}
