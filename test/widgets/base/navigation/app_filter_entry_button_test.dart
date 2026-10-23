import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 600, height: 44, child: child),
        ),
      ),
    );
  }

  testWidgets('有界宽度下保持胶囊自身宽度，不横向铺满', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Align(
          alignment: Alignment.topLeft,
          child: AppFilterEntryButton(label: '全部媒体', onTap: _noop),
        ),
      ),
    );

    final size = tester.getSize(find.byType(AppFilterEntryButton));
    expect(size.width, lessThan(200));
    expect(size.height, 44);
  });

  testWidgets('Wrap 里的筛选与排序入口保持同一行', (tester) async {
    await tester.pumpWidget(
      wrap(
        Wrap(
          spacing: 8,
          children: const [
            SizedBox(
              height: 44,
              child: AppFilterEntryButton(
                key: Key('first-entry'),
                label: '全部媒体',
                onTap: _noop,
              ),
            ),
            SizedBox(
              height: 44,
              child: AppFilterEntryButton(
                key: Key('second-entry'),
                icon: Icons.swap_vert_rounded,
                label: '默认排序',
                onTap: _noop,
              ),
            ),
          ],
        ),
      ),
    );

    final first = tester.getCenter(find.byKey(const Key('first-entry')));
    final second = tester.getCenter(find.byKey(const Key('second-entry')));
    expect(first.dy, second.dy);
    expect(first.dx, lessThan(second.dx));
  });
}

void _noop() {}
