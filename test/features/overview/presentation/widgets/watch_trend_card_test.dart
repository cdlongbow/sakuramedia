import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/watch_trend_card.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('展示窗口摘要与图表', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: _trend(),
        range: WatchTrendRange.last30Days,
        onRangeChanged: (_) {},
      ),
    );

    expect(find.text('近 30 天看过 3 部'), findsOneWidget);
    expect(
      find.byKey(const Key('overview-watch-trend-chart')),
      findsOneWidget,
    );
    expect(find.text('09-01'), findsOneWidget);
    expect(find.text('09-03'), findsOneWidget);
  });

  testWidgets('纵轴标出量程上限与 0', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: _trend(),
        range: WatchTrendRange.last30Days,
        onRangeChanged: (_) {},
      ),
    );

    // 峰值 2，量程即 2。
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('量程上限取整到 1/2/5 的倍数', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: StatusWatchTrendDto(
          range: WatchTrendRange.last30Days,
          granularity: 'day',
          watchedMovieCount: 43,
          buckets: const <WatchTrendBucketDto>[
            WatchTrendBucketDto(period: '2026-09-01', count: 43),
          ],
        ),
        range: WatchTrendRange.last30Days,
        onRangeChanged: (_) {},
      ),
    );

    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('切换时间窗口回调新值', (WidgetTester tester) async {
    final selected = <WatchTrendRange>[];
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: _trend(),
        range: WatchTrendRange.last30Days,
        onRangeChanged: selected.add,
      ),
    );

    await tester.tap(
      find.byKey(const Key('overview-watch-trend-range-7d')),
    );
    await tester.pump();

    expect(selected, <WatchTrendRange>[WatchTrendRange.last7Days]);
  });

  testWidgets('区间无观看记录时给出空态文案', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: StatusWatchTrendDto(
          range: WatchTrendRange.last7Days,
          granularity: 'day',
          watchedMovieCount: 0,
          buckets: const <WatchTrendBucketDto>[
            WatchTrendBucketDto(period: '2026-09-01', count: 0),
            WatchTrendBucketDto(period: '2026-09-02', count: 0),
          ],
        ),
        range: WatchTrendRange.last7Days,
        onRangeChanged: (_) {},
      ),
    );

    expect(find.text('该区间暂无观看记录'), findsOneWidget);
    expect(find.byKey(const Key('overview-watch-trend-chart')), findsNothing);
  });

  testWidgets('加载 / 空态 / 有数据态的卡片高度一致', (WidgetTester tester) async {
    Future<double> cardHeight(WidgetTester tester, Widget card) async {
      await _pumpCard(tester, card);
      return tester
          .getSize(find.byKey(const Key('overview-watch-trend-card')))
          .height;
    }

    final loadingHeight = await cardHeight(
      tester,
      WatchTrendCard(
        trend: null,
        range: WatchTrendRange.last30Days,
        isLoading: true,
        onRangeChanged: (_) {},
      ),
    );
    final emptyHeight = await cardHeight(
      tester,
      WatchTrendCard(
        trend: StatusWatchTrendDto(
          range: WatchTrendRange.last30Days,
          granularity: 'day',
          buckets: const <WatchTrendBucketDto>[],
        ),
        range: WatchTrendRange.last30Days,
        onRangeChanged: (_) {},
      ),
    );
    final dataHeight = await cardHeight(
      tester,
      WatchTrendCard(
        trend: _trend(),
        range: WatchTrendRange.last30Days,
        onRangeChanged: (_) {},
      ),
    );

    expect(emptyHeight, loadingHeight);
    expect(dataHeight, loadingHeight);
  });

  testWidgets('窄卡片把分段控件换到标题下方', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      WatchTrendCard(
        trend: _trend(),
        range: WatchTrendRange.last30Days,
        compactSelector: true,
        onRangeChanged: (_) {},
      ),
    );

    expect(
      find.byKey(const Key('overview-watch-trend-range-1y')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('overview-watch-trend-range-90d')), findsNothing);
  });
}

StatusWatchTrendDto _trend() {
  return StatusWatchTrendDto(
    range: WatchTrendRange.last30Days,
    granularity: 'day',
    watchedMovieCount: 3,
    buckets: const <WatchTrendBucketDto>[
      WatchTrendBucketDto(period: '2026-09-01', count: 1),
      WatchTrendBucketDto(period: '2026-09-02', count: 0),
      WatchTrendBucketDto(period: '2026-09-03', count: 2),
    ],
  );
}

Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
}
