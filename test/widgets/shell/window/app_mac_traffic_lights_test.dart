import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/shell/window/app_mac_traffic_lights.dart';

void main() {
  Future<void> pumpTrafficLights(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppMacTrafficLights())),
      ),
    );
  }

  testWidgets('renders three traffic lights with native sizes and spacing', (
    tester,
  ) async {
    await pumpTrafficLights(tester);

    expect(find.byKey(const Key('mac-traffic-lights')), findsOneWidget);
    expect(find.byKey(const Key('mac-traffic-light-close')), findsOneWidget);
    expect(find.byKey(const Key('mac-traffic-light-minimize')), findsOneWidget);
    expect(find.byKey(const Key('mac-traffic-light-zoom')), findsOneWidget);

    final closeRect = tester.getRect(
      find.byKey(const Key('mac-traffic-light-close')),
    );
    final minimizeRect = tester.getRect(
      find.byKey(const Key('mac-traffic-light-minimize')),
    );
    final zoomRect = tester.getRect(
      find.byKey(const Key('mac-traffic-light-zoom')),
    );
    expect(closeRect.width, appMacTrafficLightButtonSize);
    expect(
      minimizeRect.center.dx - closeRect.center.dx,
      appMacTrafficLightSpacing,
    );
    expect(
      zoomRect.center.dx - minimizeRect.center.dx,
      appMacTrafficLightSpacing,
    );
    expect(
      tester.getSize(find.byKey(const Key('mac-traffic-lights'))).width,
      appMacTrafficLightsWidth,
    );
  });

  testWidgets('shows glyphs while hovered and hides them after leaving', (
    tester,
  ) async {
    await pumpTrafficLights(tester);

    expect(
      find.byKey(const Key('mac-traffic-light-glyph-close')),
      findsNothing,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('mac-traffic-lights'))),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('mac-traffic-light-glyph-close')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mac-traffic-light-glyph-minimize')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mac-traffic-light-glyph-zoomExpand')),
      findsOneWidget,
    );

    await gesture.moveTo(const Offset(-10, -10));
    await tester.pump();
    expect(
      find.byKey(const Key('mac-traffic-light-glyph-close')),
      findsNothing,
    );
  });

  testWidgets('zoom glyph switches to plus while option is held', (
    tester,
  ) async {
    await pumpTrafficLights(tester);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('mac-traffic-lights'))),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('mac-traffic-light-glyph-zoomExpand')),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(
      find.byKey(const Key('mac-traffic-light-glyph-zoomPlus')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mac-traffic-light-glyph-zoomExpand')),
      findsNothing,
    );

    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  });
}
