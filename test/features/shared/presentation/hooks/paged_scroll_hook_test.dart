import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';

void main() {
  testWidgets('内容不足一屏时在布局完成后自动触发 onReachBottom', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      _HookHarness(
        itemCount: 1,
        itemExtent: 40,
        onReachBottom: () => calls++,
      ),
    );

    expect(calls, 1);
  });

  testWidgets('内容可滚动时不自动触发，滚到底才触发', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      _HookHarness(
        itemCount: 40,
        itemExtent: 100,
        onReachBottom: () => calls++,
      ),
    );
    expect(calls, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pump();

    expect(calls, greaterThanOrEqualTo(1));
  });

  testWidgets('enabled 为 false 时不触发也不绑滚动监听', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      _HookHarness(
        itemCount: 1,
        itemExtent: 40,
        enabled: false,
        onReachBottom: () => calls++,
      ),
    );
    expect(calls, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('内容变短后重新检查视口并触发', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      _HookHarness(
        itemCount: 40,
        itemExtent: 100,
        onReachBottom: () => calls++,
      ),
    );
    expect(calls, 0);

    await tester.pumpWidget(
      _HookHarness(
        itemCount: 1,
        itemExtent: 40,
        onReachBottom: () => calls++,
      ),
    );

    expect(calls, 1);
  });
}

class _HookHarness extends HookWidget {
  const _HookHarness({
    required this.itemCount,
    required this.itemExtent,
    required this.onReachBottom,
    this.enabled = true,
  });

  final int itemCount;
  final double itemExtent;
  final VoidCallback onReachBottom;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final controller = usePagedLoadMoreScroll(
      onReachBottom: onReachBottom,
      triggerOffset: 300,
      enabled: enabled,
    );
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          controller: controller,
          itemCount: itemCount,
          itemBuilder: (context, index) =>
              SizedBox(height: itemExtent, child: const SizedBox.shrink()),
        ),
      ),
    );
  }
}
