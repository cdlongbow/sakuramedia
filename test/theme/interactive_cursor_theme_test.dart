import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  test('standard interactive controls use the project click cursor', () {
    for (final theme in [sakuraDesktopThemeData, sakuraMobileThemeData]) {
      expect(
        theme.textButtonTheme.style!.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.elevatedButtonTheme.style!.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.filledButtonTheme.style!.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.outlinedButtonTheme.style!.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.iconButtonTheme.style!.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.popupMenuTheme.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.radioTheme.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.checkboxTheme.mouseCursor!.resolve(const {}),
        SystemMouseCursors.click,
      );
      expect(
        theme.textButtonTheme.style!.mouseCursor!.resolve(const {
          WidgetState.disabled,
        }),
        SystemMouseCursors.basic,
      );
    }
  });

  testWidgets('a standard TextButton uses the themed cursor at runtime', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraDesktopThemeData,
        home: Scaffold(
          body: TextButton(
            key: const Key('themed-text-button'),
            onPressed: () {},
            child: const Text('标记合集'),
          ),
        ),
      ),
    );

    const mousePointer = 1;
    final mouse = await tester.createGesture(
      pointer: mousePointer,
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('themed-text-button'))),
    );

    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(
        mousePointer,
      ),
      SystemMouseCursors.click,
    );

    await mouse.removePointer();
  });
}
