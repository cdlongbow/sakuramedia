import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_ranking_list.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('movie ranking list renders one honor badge per placement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: MovieRankingList(
            rankings: <MovieRankingDto>[
              MovieRankingDto(
                sourceKey: 'javdb',
                sourceName: 'JavDB',
                boardKey: 'playback_all',
                boardName: '热播',
                period: 'daily',
                rank: 40,
              ),
              MovieRankingDto(
                sourceKey: 'javdb',
                sourceName: 'JavDB',
                boardKey: 'top250',
                boardName: 'TOP250',
                period: 'all',
                rank: 18,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('热播 · 日榜'), findsOneWidget);
    expect(find.text('TOP250 · 总榜'), findsOneWidget);
    expect(find.text('#40'), findsOneWidget);
    expect(find.text('#18'), findsOneWidget);
    // 每条上榜记录都用同一套荣誉徽章（奖杯 + 奶油金底 + 标签同款圆角）。
    expect(find.byIcon(Icons.emoji_events_rounded), findsNWidgets(2));
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text('#40'), matching: find.byType(Container))
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.defaults().warningSurface);
    expect(decoration.borderRadius, AppRadius.defaults().xsBorder);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movie ranking list skips an empty period segment', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const Scaffold(
          body: MovieRankingList(
            rankings: <MovieRankingDto>[
              MovieRankingDto(
                sourceKey: 'minnano',
                sourceName: '更多影片榜单',
                boardKey: 'daily_pick',
                boardName: '每日精选',
                period: '',
                rank: 9,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('每日精选'), findsOneWidget);
    expect(find.text('#9'), findsOneWidget);
  });

  testWidgets('movie ranking list keeps long labels on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: MovieRankingList(
              rankings: <MovieRankingDto>[
                MovieRankingDto(
                  sourceKey: 'minnano',
                  sourceName: '更多影片榜单',
                  boardKey: 'minnano_av',
                  boardName: 'Minnano AV 每日人气排行榜',
                  period: 'monthly',
                  rank: 128,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 超长榜单名收窄成省略号，名次始终完整可见。
    expect(find.text('#128'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
