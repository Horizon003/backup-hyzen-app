import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyzen_pharmd/features/profile/presentation/widgets/account_widgets.dart';

void main() {
  testWidgets('custom toggle supports keyboard and accessible on/off states', (
    tester,
  ) async {
    var enabled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AccountToggle(
              label: 'Announcements',
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(AccountToggle)),
      matchesSemantics(
        label: 'Announcements',
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(enabled, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(enabled, isFalse);
    semantics.dispose();
  });
}
