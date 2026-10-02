import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_player_layout.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/media/collapsible_player_split_view.dart';

const Key _handleKey = Key('test-panel-handle');

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
              leftBuilder:
                  (context) => const ColoredBox(
                    color: Colors.black,
                    child: Center(child: Text('left')),
                  ),
              rightBuilder:
                  (context) => const ColoredBox(
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

  testWidgets('桌面模式固定分栏且不显示把手', (tester) async {
    final controller = await pumpSplit(tester, collapsible: false);

    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsOneWidget);
    expect(find.byKey(_handleKey), findsNothing);
    expect(controller.areas[1].flex, 0.28);
  });

  testWidgets('移动端默认收起，把手点击可展开再收起', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    expect(find.text('left'), findsOneWidget);
    expect(find.text('right'), findsNothing);
    expect(controller.areas[1].flex, 0);
    expect(find.byKey(_handleKey), findsOneWidget);
    final collapsedHandle = tester.getRect(find.byKey(_handleKey));
    expect(collapsedHandle.right, closeTo(800, 0.5));
    expect(collapsedHandle.center.dy, closeTo(200, 1));

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsOneWidget);
    expect(controller.areas[1].flex, closeTo(0.28, 0.0001));
    final expandedHandle = tester.getRect(find.byKey(_handleKey));
    expect(expandedHandle.center.dx, closeTo(800 - 796 * 0.28 - 2, 2));

    await tester.tap(find.byKey(_handleKey));
    await tester.pumpAndSettle();
    expect(find.text('right'), findsNothing);
    expect(controller.areas[1].flex, 0);
  });

  testWidgets('面板无内容时不显示把手', (tester) async {
    final controller = await pumpSplit(
      tester,
      collapsible: true,
      panelAvailable: false,
    );

    expect(find.byKey(_handleKey), findsNothing);
    expect(controller.areas[1].flex, 0);
  });

  testWidgets('把手横拖可从右缘拉出面板', (tester) async {
    final controller = await pumpSplit(tester, collapsible: true);

    await tester.drag(find.byKey(_handleKey), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(controller.areas[1].flex, greaterThan(0.05));
    expect(find.text('right'), findsOneWidget);
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

  testWidgets('影片播放器分栏在移动端使用专属把手 Key', (tester) async {
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
