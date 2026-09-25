import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('骨架容器统一中性化为 surfaceCard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const AppSkeletonizer(child: SizedBox()),
      ),
    );

    final skeletonizer = tester.widget<Skeletonizer>(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
    );
    expect(
      skeletonizer.containersColor,
      sakuraThemeData.appColors.surfaceCard,
    );
  });

  testWidgets('sliver 骨架容器统一中性化为 surfaceCard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const CustomScrollView(
          slivers: [
            AppSkeletonizer.sliver(
              child: SliverToBoxAdapter(child: SizedBox()),
            ),
          ],
        ),
      ),
    );

    final skeletonizer = tester.widget<Skeletonizer>(
      // sliver 在 viewport 内被视作 offstage，默认 finder 找不到。
      find.byWidgetPredicate(
        (widget) => widget is Skeletonizer,
        skipOffstage: false,
      ),
    );
    expect(
      skeletonizer.containersColor,
      sakuraThemeData.appColors.surfaceCard,
    );
  });
}
