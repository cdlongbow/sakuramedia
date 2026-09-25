import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSurface(
    WidgetTester tester, {
    bool enabled = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: AppInteractiveSurface(
              enabled: enabled,
              onTap: enabled ? (onTap ?? () {}) : null,
              onLongPress: enabled ? onLongPress : null,
              child: const SizedBox(
                width: 96,
                height: 32,
                child: ColoredBox(color: Color(0xFF3366FF)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AnimatedOpacity surfaceOpacity(WidgetTester tester) => tester.widget(
    find.descendant(
      of: find.byType(AppInteractiveSurface),
      matching: find.byType(AnimatedOpacity),
    ),
  );

  InkWell surfaceInkWell(WidgetTester tester) => tester.widget(
    find.descendant(
      of: find.byType(AppInteractiveSurface),
      matching: find.byType(InkWell),
    ),
  );

  testWidgets('关闭水波纹和所有 ink 叠色，不插额外交互层', (tester) async {
    await pumpSurface(tester);
    final inkWell = surfaceInkWell(tester);

    expect(inkWell.splashFactory, same(NoSplash.splashFactory));
    expect(inkWell.splashColor, Colors.transparent);
    expect(inkWell.highlightColor, Colors.transparent);
    expect(inkWell.hoverColor, Colors.transparent);
    expect(inkWell.focusColor, Colors.transparent);
    expect(
      find.descendant(
        of: find.byType(AppInteractiveSurface),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );
  });

  testWidgets('桌面 hover 不产生任何外观变化', (tester) async {
    await pumpSurface(tester);
    expect(surfaceOpacity(tester).opacity, 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byType(AppInteractiveSurface)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(surfaceOpacity(tester).opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('按下整体变淡，松开恢复', (tester) async {
    await pumpSurface(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppInteractiveSurface)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(surfaceOpacity(tester).opacity, 0.7);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(surfaceOpacity(tester).opacity, 1);
  });

  testWidgets('禁用时不可点，也没有按下反馈', (tester) async {
    var taps = 0;
    await pumpSurface(tester, enabled: false, onTap: () => taps += 1);

    expect(surfaceInkWell(tester).onTap, isNull);
    await tester.tap(find.byType(AppInteractiveSurface), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(surfaceOpacity(tester).opacity, 1);
  });

  testWidgets('长按触发轻触感并回调，普通点击不震', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    var longPresses = 0;
    await pumpSurface(tester, onLongPress: () => longPresses += 1);

    final center = tester.getCenter(find.byType(AppInteractiveSurface));
    final gesture = await tester.startGesture(center);
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pump();

    expect(longPresses, 1);
    expect(
      calls.map((call) => '${call.method}:${call.arguments}'),
      contains('HapticFeedback.vibrate:HapticFeedbackType.selectionClick'),
    );

    calls.clear();
    await tester.tap(find.byType(AppInteractiveSurface));
    await tester.pump();

    expect(
      calls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
  });
}
