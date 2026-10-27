import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_rail.dart';

const MovieListItemDto _movie = MovieListItemDto(
  javdbId: 'test-javdb-id',
  movieNumber: 'ABP-123',
  title: 'Test Movie',
  coverImage: null,
  releaseDate: null,
  durationMinutes: 0,
  heat: 0,
  canPlay: false,
  isSubscribed: false,
);

void main() {
  testWidgets('桌面 rail 卡宽与「相似影片」同规格', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraDesktopThemeData,
        home: const Scaffold(
          body: SizedBox(width: 800, child: MovieSummaryRail(items: [_movie])),
        ),
      ),
    );

    final cardSize = tester.getSize(
      find.byKey(const Key('movie-summary-card-ABP-123')),
    );
    expect(
      cardSize.width,
      AppComponentTokens.defaults().movieCardTargetWidth * 0.75,
    );
  });

  testWidgets('移动端 rail 卡宽与首页「最近添加」一致', (tester) async {
    await tester.pumpWidget(
      AppPlatformScope(
        platform: AppPlatform.mobile,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
          theme: sakuraMobileThemeData,
          home: const Scaffold(
            body: SizedBox(
              width: 390,
              child: MovieSummaryRail(items: [_movie]),
            ),
          ),
        ),
      ),
    );

    final cardSize = tester.getSize(
      find.byKey(const Key('movie-summary-card-ABP-123')),
    );
    expect(
      cardSize.width,
      AppComponentTokens.mobile().mobileLatestMovieCardWidth,
    );
  });

  testWidgets('错误态显示重试按钮并回调', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraThemeData,
        home: Scaffold(
          body: MovieSummaryRail(
            items: const [],
            errorMessage: '最近添加影片加载失败，请稍后重试',
            onErrorRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('最近添加影片加载失败，请稍后重试'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retried, isTrue);
  });

  testWidgets('空态显示调用方文案', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: <Locale>[Locale('zh'), Locale('en')],
        home: Scaffold(
          body: MovieSummaryRail(items: [], emptyMessage: '暂无入库影片，去搜索看看吧'),
        ),
      ),
    );

    expect(find.text('暂无入库影片，去搜索看看吧'), findsOneWidget);
  });
}
