import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_player_layout.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/media/collapsible_player_split_view.dart';

const Key _handleKey = Key('test-panel-handle');
const Key _rightPanelKey = Key('test-right-panel');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MultiSplitViewController> pumpSplit(
    WidgetTester tester, {
    required bool collapsible,
    bool panelAvailable = true,
  }) async {
    final controller = MultiSplitViewController(
      areas: <Area>[Area(flex: 0.72), Area(flex: 0.28)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: CollapsiblePlayerSplitView(
              controller: controller,
              collapsible: collapsible,
              panelAvailable: panelAvailable,
              handleKey: _handleKey,
              leftBuilder: (context) => const ColoredBox(
                color: Colors.black,
                child: Center(child: Text('left')),
              ),
              rightBuilder: (context) => const ColoredBox(
                key: _rightPanelKey,
                color: Colors.white,
                child: Center(child: Text('right')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('collapsible=false 时不显示开关且保持分栏', (tester) async {
    final controller = await pumpSplit(tester, collapsible: false);

    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
    expect(find.byKey(_handleKey), findsNothing);
    expect(controller.areas[1].flex, 0.28);
  });

  testWidgets('默认展开，右上角开关点击可收起再展开', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
    expect(controller.areas[1].flex, closeTo(0.28, 0.0001));
    expect(find.byKey(_handleKey), findsOneWidget);
    final expandedHandle = tester.getRect(find.byKey(_handleKey));
    expect(expandedHandle.width, closeTo(44, 0.5));
    expect(expandedHandle.right, closeTo(800 - 796 * 0.28 - 4 - 12, 0.5));
    expect(expandedHandle.top, closeTo(24, 0.5));

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsNothing);
    expect(controller.areas[1].flex, 0);
    final collapsedHandle = tester.getRect(find.byKey(_handleKey));
    expect(collapsedHandle.right, closeTo(800 - 4 - 12, 0.5));
    expect(collapsedHandle.top, closeTo(24, 0.5));

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);
    expect(controller.areas[1].flex, closeTo(0.28, 0.0001));
  });

  testWidgets('开关位置跟随播放画面右缘（分隔条）', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    final beforeRight = tester.getRect(find.byKey(_handleKey)).right;

    controller.areas[1].flex = 0.4;
    await tester.pumpAndSettle();
    final afterRight = tester.getRect(find.byKey(_handleKey)).right;
    expect(afterRight, lessThan(beforeRight));
    // available = 800 - 4；面板 flex 0.4 时像素宽 = 796*0.4/1.12。
    final panelWidth = 796 * 0.4 / (0.72 + 0.4);
    expect(afterRight, closeTo(800 - 4 - panelWidth - 12, 0.5));
  });

  testWidgets('开关不吃安全区，保持与顶栏按钮同锚点', (tester) async {
    tester.view.padding = const FakeViewPadding(right: 40);
    addTearDown(tester.view.resetPadding);
    await pumpSplit(tester, collapsible: true);

    final handle = tester.getRect(find.byKey(_handleKey));
    expect(handle.right, closeTo(800 - 796 * 0.28 - 4 - 12, 0.5));
    expect(handle.top, closeTo(24, 0.5));
  });

  testWidgets('面板无内容时不显示开关', (tester) async {
    final controller = await pumpSplit(
      tester,
      collapsible: true,
      panelAvailable: false,
    );

    expect(find.byKey(_handleKey), findsNothing);
    expect(controller.areas[1].flex, 0);
  });

  testWidgets('收起再展开面板像素宽度不变', (tester) async {
    await pumpSplit(tester, collapsible: true);

    final beforeWidth = tester.getRect(find.byKey(_rightPanelKey)).width;
    expect(beforeWidth, greaterThan(0));

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_rightPanelKey), findsNothing);

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    final afterWidth = tester.getRect(find.byKey(_rightPanelKey)).width;
    expect(afterWidth, closeTo(beforeWidth, 0.5));
  });

  testWidgets('收起再展开恢复用户拖过的宽度', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    controller.areas[1].flex = 0.4;
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(controller.areas[1].flex, 0);

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(controller.areas[1].flex, closeTo(0.4, 0.0001));
  });

  testWidgets('动画途中连点不把中间宽度记成记忆宽度', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    controller.areas[1].flex = 0.4;
    await tester.pumpAndSettle();

    // 收起动画进行到一半时立刻反向展开：应回到 0.4，而不是动画中间值。
    await tester.tap(find.byKey(_handleKey));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);
    expect(controller.areas[1].flex, closeTo(0.4, 0.0001));
  });

  testWidgets('收起展开不重建左侧子树', (tester) async {
    final controller = MultiSplitViewController(
      areas: <Area>[Area(flex: 0.72), Area(flex: 0.28)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: CollapsiblePlayerSplitView(
            controller: controller,
            collapsible: true,
            handleKey: _handleKey,
            leftBuilder: (context) => const _KeepAliveProbe(),
            rightBuilder: (context) => const Text('right'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = tester.state<_KeepAliveProbeState>(
      find.byType(_KeepAliveProbe),
    );
    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();

    final after = tester.state<_KeepAliveProbeState>(
      find.byType(_KeepAliveProbe),
    );
    expect(identical(before, after), isTrue);
    expect(before.initCount, 1);
  });

  testWidgets('影片播放器分栏使用专属开关 Key，点击可收起再展开', (tester) async {
    final controller = MultiSplitViewController(
      areas: <Area>[Area(flex: 0.72), Area(flex: 0.28)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: MoviePlayerSplitLayout(
            controller: controller,
            dividerHandleBuffer: 12,
            collapsible: true,
            leftChild: const ColoredBox(color: Colors.black),
            rightChild: const Text('right'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('right'), findsOneWidget);
    await tester.tap(find.byKey(const Key('movie-player-panel-handle')));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsNothing);
    await tester.tap(find.byKey(const Key('movie-player-panel-handle')));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);
  });
}

class _KeepAliveProbe extends StatefulWidget {
  const _KeepAliveProbe();

  @override
  State<_KeepAliveProbe> createState() => _KeepAliveProbeState();
}

class _KeepAliveProbeState extends State<_KeepAliveProbe> {
  int initCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Colors.black);
  }
}
