import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_cover_hover_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHoverInfo(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              height: 320,
              child: AppCoverHoverInfo(
                cover: const ColoredBox(color: Color(0xFF202020)),
                collapsedOverlay: const SizedBox.shrink(),
                infoBuilder: (context) =>
                    const AppCoverHoverInfoRow(label: 'ABC-001'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('快速 hover 往返不会在过渡层产生重复 key', (tester) async {
    await pumpHoverInfo(tester);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final center = tester.getCenter(find.byType(AppCoverHoverInfo));

    for (var i = 0; i < 2; i += 1) {
      await mouse.moveTo(center);
      await tester.pump(const Duration(milliseconds: 20));
      await mouse.moveTo(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await mouse.moveTo(center);
    await tester.pump(const Duration(milliseconds: 20));

    expect(tester.takeException(), isNull);
  });
}
