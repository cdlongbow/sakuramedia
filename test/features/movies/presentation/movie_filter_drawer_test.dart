import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/movies/presentation/pages/mobile/movie_filter_drawer.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_interaction_filter_options_provider.dart';
import 'package:sakuramedia/theme.dart';

import '../../../support/test_api_bundle.dart';

void main() {
  Widget wrapApp(Widget home) {
    return ProviderScope(
      overrides: [
        movieInteractionFilterOptionsProvider.overrideWith(
          (ref) async => testInteractionFilterOptions,
        ),
      ],
      child: MaterialApp(theme: sakuraThemeData, home: home),
    );
  }

  testWidgets('影片筛选抽屉与桌面面板同构且即时生效', (tester) async {
    final applied = <MovieFilterState>[];
    await tester.pumpWidget(
      wrapApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showMobileMovieFilterDrawer(
                  context,
                  current: MovieFilterState.initial,
                  onChanged: applied.add,
                );
              },
              child: const Text('打开筛选'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开筛选'));
    await tester.pumpAndSettle();

    // 抽屉内容与桌面浮层面板同构：只有筛选分节 + footer，没有标题行、
    // 没有快捷筛选、没有确定按钮。
    expect(find.text('状态筛选'), findsOneWidget);
    expect(find.text('合集类型'), findsOneWidget);
    expect(
      find.byKey(const Key('movie-filter-interaction-group-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-filter-heat-section-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-filter-score-section-title')),
      findsOneWidget,
    );
    expect(find.text('0'), findsNWidgets(6));
    expect(find.text('1.1w'), findsOneWidget);
    expect(find.text('2w'), findsOneWidget);
    expect(find.text('1.6w'), findsOneWidget);
    expect(find.byKey(const Key('movie-filter-actor-age-section-title')), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('50+'), findsOneWidget);
    expect(find.text('${DateTime.now().year}'), findsOneWidget);
    expect(find.text('筛选'), findsNothing);
    expect(find.text('确定'), findsNothing);
    expect(find.text('完成'), findsNothing);

    await tester.tap(find.text('4K'));
    await tester.pumpAndSettle();
    expect(applied, isEmpty);
    await tester.tap(find.text('可播放'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4K'));
    await tester.pumpAndSettle();
    expect(applied.last.resolution, PlaylistResolutionFilter.k4k);
    expect(applied.last.triggerLabel, contains('4K'));
    applied.clear();
    await tester.tap(find.text('已订阅'));
    await tester.pumpAndSettle();

    // 点完立刻生效，抽屉不关。
    expect(applied, hasLength(1));
    expect(applied.single.status, MovieStatusFilter.subscribed);
    expect(applied.single.resolution, isNull);
    expect(find.text('状态筛选'), findsOneWidget);

    // 未订阅与已订阅互补相邻，同样是即时生效。
    await tester.tap(find.text('未订阅'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(2));
    expect(applied.last.status, MovieStatusFilter.unsubscribed);

    // 热度双滑块：拖右 thumb 松手才应用，且滑到顶之前传具体上限。
    final slider = find.byKey(const Key('movie-filter-heat-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final rect = tester.getRect(slider);
    await tester.dragFrom(
      Offset(rect.right - 12, rect.center.dy),
      const Offset(-160, 0),
    );
    await tester.pumpAndSettle();

    expect(applied, hasLength(3));
    final heatRange = applied.last.interaction.rangeFor(
      MovieInteractionMetric.heat,
    );
    expect(heatRange?.min, isNull);
    expect(heatRange?.max, isNotNull);
    expect(
      heatRange!.max,
      lessThan(testInteractionFilterOptions.heat.p999!),
    );

    // 左 thumb 同样松手才生效：下限非 0 时映射为具体的 heat_min。
    await tester.dragFrom(
      Offset(rect.left + 12, rect.center.dy),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    expect(applied, hasLength(4));
    final heatMin = applied.last.interaction
        .rangeFor(MovieInteractionMetric.heat)
        ?.min;
    expect(heatMin, isNotNull);
    expect(heatMin, greaterThan(0));

    // 重置在 footer 里，与桌面面板同一个 AppFilterPanelFooter；
    // 重置后热度条件一并清空，滑块回到 0 ~ 2w。
    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(5));
    expect(applied.last.isDefault, isTrue);
    expect(applied.last.interaction.isDefault, isTrue);
  });

  testWidgets('出演年龄双滑块：拖动中不应用，松手才生效且边界映射为不限', (tester) async {
    final applied = <MovieFilterState>[];
    await tester.pumpWidget(
      wrapApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await showMobileMovieFilterDrawer(
                  context,
                  current: MovieFilterState.initial,
                  onChanged: applied.add,
                );
              },
              child: const Text('打开筛选'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开筛选'));
    await tester.pumpAndSettle();

    final slider = find.byKey(const Key('movie-filter-actor-age-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final rect = tester.getRect(slider);

    // 右 thumb 分多步拖离顶端：拖动过程只改面板显示，不产生应用回调。
    final gesture = await tester.startGesture(
      Offset(rect.right - 12, rect.center.dy),
    );
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(applied, isEmpty);
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(applied, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single.actorAgeMin, isNull);
    expect(applied.single.actorAgeMax, isNotNull);
    expect(applied.single.actorAgeMax, lessThan(movieFilterActorAgeSliderMax));
    expect(applied.single.triggerLabel, contains('岁'));

    // 左 thumb 同样松手才生效：拖离底端后传具体 actor_age_min。
    await tester.dragFrom(
      Offset(rect.left + 12, rect.center.dy),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    expect(applied, hasLength(2));
    expect(applied.last.actorAgeMin, isNotNull);
    expect(applied.last.actorAgeMin, greaterThan(movieFilterActorAgeSliderMin));
    expect(applied.last.actorAgeMax, applied.first.actorAgeMax);
  });
}
