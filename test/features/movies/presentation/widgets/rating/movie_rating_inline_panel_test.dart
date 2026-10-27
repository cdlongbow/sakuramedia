import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/rating/movie_rating_inline_panel.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  void enqueueRatingData() {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movie-rating-dimensions',
      body: _dimensionsJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/ABC-001/rating',
      body: _ratingJson(total: 3.5, looks: 4, plot: 3),
    );
  }

  testWidgets('内联面板展示维度分值，点星即自动保存', (tester) async {
    enqueueRatingData();
    await tester.pumpWidget(
      wrap(const MovieRatingInlinePanel(movieNumber: 'ABC-001')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-rating-score-1-4')), findsOneWidget);
    expect(find.byKey(const Key('movie-rating-score-2-3')), findsOneWidget);
    expect(
      _starIcon(tester, const Key('movie-rating-score-1-4')),
      Icons.star_rounded,
    );
    expect(
      _starIcon(tester, const Key('movie-rating-score-1-5')),
      Icons.star_border_rounded,
    );

    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/movies/ABC-001/rating',
      body: _ratingJson(total: 4.0, looks: 5, plot: 3),
    );
    await tester.tap(find.byKey(const Key('movie-rating-score-1-5')));
    await tester.pumpAndSettle();

    final saveRequest = bundle.adapter.requests.lastWhere(
      (request) => request.method == 'PUT',
    );
    expect(saveRequest.body, <String, dynamic>{
      'values': <String, dynamic>{'1': 5, '2': 3},
    });
    expect(
      _starIcon(tester, const Key('movie-rating-score-1-5')),
      Icons.star_rounded,
    );
  });

  testWidgets('评分加载失败后重试，再打分不会覆盖其它维度', (tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movie-rating-dimensions',
      body: _dimensionsJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/ABC-001/rating',
      statusCode: 500,
      body: <String, dynamic>{'detail': 'boom'},
    );
    await tester.pumpWidget(
      wrap(const MovieRatingInlinePanel(movieNumber: 'ABC-001')),
    );
    await tester.pumpAndSettle();
    expect(find.text('评分加载失败'), findsOneWidget);

    // 重试成功：真实评分必须回填，不能停留在空手状态。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies/ABC-001/rating',
      body: _ratingJson(total: 3.5, looks: 4, plot: 3),
    );
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(
      _starIcon(tester, const Key('movie-rating-score-1-4')),
      Icons.star_rounded,
    );

    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/movies/ABC-001/rating',
      body: _ratingJson(total: 4.0, looks: 5, plot: 3),
    );
    await tester.tap(find.byKey(const Key('movie-rating-score-1-5')));
    await tester.pumpAndSettle();

    final saveRequest = bundle.adapter.requests.lastWhere(
      (request) => request.method == 'PUT',
    );
    expect(saveRequest.body, <String, dynamic>{
      'values': <String, dynamic>{'1': 5, '2': 3},
    });
  });

  testWidgets('再次点击已选分值可清除，全部清空后删除评分', (tester) async {
    enqueueRatingData();
    await tester.pumpWidget(
      wrap(const MovieRatingInlinePanel(movieNumber: 'ABC-001')),
    );
    await tester.pumpAndSettle();

    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/movies/ABC-001/rating',
      body: _ratingJson(total: 3.0, looks: null, plot: 3),
    );
    await tester.tap(find.byKey(const Key('movie-rating-score-1-4')));
    await tester.pumpAndSettle();
    expect(
      bundle.adapter.requests.lastWhere((r) => r.method == 'PUT').body,
      <String, dynamic>{
        'values': <String, dynamic>{'2': 3},
      },
    );

    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/movies/ABC-001/rating',
      statusCode: 204,
    );
    await tester.tap(find.byKey(const Key('movie-rating-score-2-3')));
    await tester.pumpAndSettle();

    expect(
      bundle.adapter.requests.any((request) => request.method == 'DELETE'),
      isTrue,
    );
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('一行放得下就并排，放不下自动换行', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    enqueueRatingData();
    await tester.pumpWidget(
      wrap(const MovieRatingInlinePanel(movieNumber: 'ABC-001')),
    );
    await tester.pumpAndSettle();

    double topOf(int dimensionId) => tester
        .getTopLeft(find.byKey(Key('movie-rating-score-$dimensionId-1')))
        .dy;

    expect(topOf(2), topOf(1));

    tester.view.physicalSize = const Size(260, 800);
    await tester.pumpAndSettle();
    expect(topOf(2), greaterThan(topOf(1)));
  });
}

IconData _starIcon(WidgetTester tester, Key key) {
  return tester
      .widget<Icon>(
        find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
      )
      .icon!;
}

List<Map<String, dynamic>> _dimensionsJson() => <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 1,
    'name': '颜值',
    'min_value': 1,
    'max_value': 5,
    'weight': 1.0,
  },
  <String, dynamic>{
    'id': 2,
    'name': '剧情',
    'min_value': 1,
    'max_value': 5,
    'weight': 1.0,
  },
];

Map<String, dynamic> _ratingJson({
  required double total,
  required int? looks,
  required int? plot,
}) => <String, dynamic>{
  'movie_number': 'ABC-001',
  'rated': looks != null || plot != null,
  'total_score': looks == null && plot == null ? null : total,
  'updated_at': '2026-10-20T10:00:00',
  'values': <Map<String, dynamic>>[
    if (looks != null)
      <String, dynamic>{
        'dimension_id': 1,
        'name': '颜值',
        'value': looks,
        'min_value': 1,
        'max_value': 5,
      },
    if (plot != null)
      <String, dynamic>{
        'dimension_id': 2,
        'name': '剧情',
        'value': plot,
        'min_value': 1,
        'max_value': 5,
      },
  ],
};
