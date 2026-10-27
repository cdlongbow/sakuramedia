import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_filter_options_dto.dart';
import 'package:sakuramedia/features/actors/presentation/controllers/listing/actor_filter_state.dart';
import 'package:sakuramedia/features/actors/presentation/pages/mobile/actor_filter_drawer.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actor_filter_options_provider.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_filter_sections.dart';

void main() {
  testWidgets('女优筛选抽屉与桌面面板同构且即时生效', (tester) async {
    final applied = <ActorFilterState>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          actorFilterOptionsProvider(
            const ActorFilterOptionsScope(
              subscriptionStatus: ActorSubscriptionStatus.subscribed,
              gender: ActorGender.all,
            ),
          ).overrideWith(
            (ref) async => const ActorFilterOptionsDto(
              age: ActorFilterRangeDto(min: 20, max: 40, populatedCount: 2),
              heightCm: ActorFilterRangeDto(
                min: 150,
                max: 170,
                populatedCount: 2,
              ),
              cups: [
                ActorCupFilterOptionDto(value: 'B', count: 1),
                ActorCupFilterOptionDto(value: 'C', count: 1),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          theme: sakuraThemeData,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  await showMobileActorFilterDrawer(
                    context,
                    current: ActorFilterState.initial,
                    onChanged: applied.add,
                  );
                },
                child: const Text('打开筛选'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开筛选'));
    await tester.pumpAndSettle();

    // 抽屉内容与桌面浮层面板同构：只有筛选分节 + footer。
    expect(find.text('订阅筛选'), findsOneWidget);
    expect(find.text('性别筛选'), findsOneWidget);
    expect(find.text('播放筛选'), findsOneWidget);
    expect(find.byKey(const Key('actor-filter-年龄-slider')), findsOneWidget);
    expect(find.byKey(const Key('actor-filter-身高-slider')), findsOneWidget);
    expect(find.text('快捷筛选'), findsNothing);
    expect(find.text('确定'), findsNothing);
    expect(find.text('完成'), findsNothing);

    await tester.ensureVisible(find.text('B (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B (1)'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single.cups, ['B']);
    expect(find.text('订阅筛选'), findsOneWidget);

    await tester.ensureVisible(find.text('有可播放影片'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('有可播放影片'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(2));
    expect(applied.last.hasPlayableMovies, isTrue);
    expect(applied.last.cups, ['B']);

    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(3));
    expect(applied.last.hasActiveFilters, isFalse);
  });

  testWidgets('切换订阅筛选加载新选项时资料筛选区保持同形不塌陷', (tester) async {
    const options = ActorFilterOptionsDto(
      age: ActorFilterRangeDto(min: 20, max: 40, populatedCount: 2),
      heightCm: ActorFilterRangeDto(min: 150, max: 170, populatedCount: 2),
      cups: [
        ActorCupFilterOptionDto(value: 'B', count: 1),
        ActorCupFilterOptionDto(value: 'C', count: 1),
      ],
    );
    final pending = Completer<ActorFilterOptionsDto>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          actorFilterOptionsProvider(
            const ActorFilterOptionsScope(
              subscriptionStatus: ActorSubscriptionStatus.subscribed,
              gender: ActorGender.all,
            ),
          ).overrideWith((ref) async => options),
          actorFilterOptionsProvider(
            const ActorFilterOptionsScope(
              subscriptionStatus: ActorSubscriptionStatus.all,
              gender: ActorGender.all,
            ),
          ).overrideWith((ref) => pending.future),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          theme: sakuraThemeData,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showMobileActorFilterDrawer(
                  context,
                  current: ActorFilterState.initial,
                  onChanged: (_) {},
                ),
                child: const Text('打开筛选'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开筛选'));
    await tester.pumpAndSettle();

    final anchorTopBefore = tester.getTopLeft(find.text('身高')).dy;

    final subscriptionSection = find.byWidgetPredicate(
      (widget) => widget is MovieFilterChoiceSection<ActorSubscriptionStatus>,
    );
    await tester.tap(
      find.descendant(of: subscriptionSection, matching: find.text('全部')),
    );
    await tester.pump();

    // 新 scope 仍在加载：年龄 / 身高滑块由占位数据撑住，不再整块消失。
    expect(find.text('正在加载资料筛选选项'), findsNothing);
    expect(find.byKey(const Key('actor-filter-年龄-slider')), findsOneWidget);
    expect(find.byKey(const Key('actor-filter-身高-slider')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('身高')).dy,
      closeTo(anchorTopBefore, 0.5),
    );

    pending.complete(options);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actor-filter-年龄-slider')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('身高')).dy,
      closeTo(anchorTopBefore, 0.5),
    );
  });
}
