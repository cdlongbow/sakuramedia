import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/overlays/app_anchored_popover.dart';

void main() {
  testWidgets('aboveEnd 向上展开并右对齐触发器', (WidgetTester tester) async {
    await _pumpPopover(
      tester,
      placement: AppPopoverPlacement.aboveEnd,
      alignment: Alignment.bottomRight,
      panelWidth: 204,
    );

    await _open(tester);

    final triggerRect = tester.getRect(find.byKey(const Key('trigger')));
    final panelRect = tester.getRect(find.byKey(const Key('panel')));

    expect(panelRect.width, 204);
    expect(panelRect.right, closeTo(triggerRect.right, 0.01));
    expect(panelRect.bottom, closeTo(triggerRect.top - 8, 0.01));
  });

  testWidgets('belowStart 向下展开并左对齐触发器', (WidgetTester tester) async {
    AppPopoverLayout? layout;
    await _pumpPopover(
      tester,
      placement: AppPopoverPlacement.belowStart,
      alignment: Alignment.topLeft,
      panelWidth: 300,
      onLayout: (value) => layout = value,
    );

    await _open(tester);

    final triggerRect = tester.getRect(find.byKey(const Key('trigger')));
    final panelRect = tester.getRect(find.byKey(const Key('panel')));

    expect(panelRect.width, 300);
    expect(panelRect.left, closeTo(triggerRect.left, 0.01));
    expect(panelRect.top, closeTo(triggerRect.bottom + 8, 0.01));
    expect(layout?.maxHeight, isNotNull);
    expect(layout!.maxHeight!, greaterThan(0));
  });

  testWidgets('点外部与 controller 都能关闭浮层', (WidgetTester tester) async {
    final controller = await _pumpPopover(
      tester,
      placement: AppPopoverPlacement.belowStart,
      alignment: Alignment.topLeft,
      panelWidth: 200,
    );

    await _open(tester);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel')), findsNothing);

    await _open(tester);
    controller.close();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel')), findsNothing);
  });

  testWidgets('focusOnOpen 时 Esc 关闭浮层', (WidgetTester tester) async {
    await _pumpPopover(
      tester,
      placement: AppPopoverPlacement.aboveStart,
      alignment: Alignment.bottomRight,
      panelWidth: 200,
      focusOnOpen: true,
    );

    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('panel')), findsNothing);
  });

  testWidgets('disabled 时不展开', (WidgetTester tester) async {
    await _pumpPopover(
      tester,
      placement: AppPopoverPlacement.belowStart,
      alignment: Alignment.topLeft,
      panelWidth: 200,
      enabled: false,
    );

    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('panel')), findsNothing);
  });
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('trigger')));
  await tester.pumpAndSettle();
}

Future<AppPopoverController> _pumpPopover(
  WidgetTester tester, {
  required AppPopoverPlacement placement,
  required Alignment alignment,
  required double panelWidth,
  bool focusOnOpen = false,
  bool enabled = true,
  ValueChanged<AppPopoverLayout>? onLayout,
}) async {
  final controller = AppPopoverController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: AppAnchoredPopover(
            controller: controller,
            placement: placement,
            animate: false,
            focusOnOpen: focusOnOpen,
            enabled: enabled,
            panelWidthBuilder: (_, _, _) => panelWidth,
            triggerBuilder: (context, isOpen, toggle) => GestureDetector(
              key: const Key('trigger'),
              onTap: toggle,
              child: const SizedBox(
                width: 64,
                height: 28,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
            panelBuilder: (context, layout, close) {
              onLayout?.call(layout);
              return SizedBox(
                key: const Key('panel'),
                width: layout.width,
                height: 100,
              );
            },
          ),
        ),
      ),
    ),
  );
  return controller;
}
