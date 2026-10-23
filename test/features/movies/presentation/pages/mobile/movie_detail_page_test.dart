import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/pages/mobile/movie_detail_page.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_page_content.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_bottom_safe_area_sliver.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpPage(
    WidgetTester tester, {
    double bottomInset = 0,
    Size size = const Size(390, 844),
    TargetPlatform? platform,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = FakeViewPadding(bottom: bottomInset);
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewPadding();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: AppPlatformScope(
          platform: AppPlatform.mobile,
          child: OKToast(
            child: MaterialApp(
              theme: platform == null
                  ? sakuraMobileThemeData
                  : sakuraMobileThemeData.copyWith(platform: platform),
              home: const Scaffold(
                body: MobileMovieDetailPage(movieNumber: 'ABC-001'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile movie detail page loads and renders movie info', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester);

    expect(
      find.byKey(const Key('mobile-movie-detail-page-surface')),
      findsOneWidget,
    );
    expect(find.text('Movie 1'), findsOneWidget);
    final content = tester.widget<MovieDetailPageContent>(
      find.byType(MovieDetailPageContent),
    );
    expect(content.surfaceColor, sakuraMobileThemeData.appColors.surfaceCard);
    expect(tester.takeException(), isNull);
  });

  testWidgets('底部安全区在滚动末尾补出，末块内容不被 home indicator 压住', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester, bottomInset: 34);

    final scrollable = find.descendant(
      of: find.byKey(MovieDetailPageContent.scrollViewKey),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    // 滚到底：留白正好占屏幕最后 34pt，最后一块内容停在它上方。
    final insetRect = tester.getRect(find.byKey(bottomSafeAreaScrollInsetKey));
    expect(insetRect.height, moreOrLessEquals(34));
    expect(insetRect.bottom, moreOrLessEquals(844));
  });

  testWidgets('顶部下拉不触发刷新：Android 无刷新指示器也不新增请求', (WidgetTester tester) async {
    _enqueueMovieDetailResponses(bundle);

    await pumpPage(tester, size: const Size(390, 600));

    final position = _scrollPosition(tester);
    expect(position.maxScrollExtent, greaterThan(0));
    final requestsBeforeDrag = bundle.adapter.requests.length;
    final pullDown = await tester.startGesture(
      tester.getCenter(find.byKey(MovieDetailPageContent.scrollViewKey)),
    );
    await pullDown.moveBy(const Offset(0, 320));
    await tester.pump();

    // 顶部继续下拉：页面零位移、零过卷。
    expect(position.pixels, 0);
    expect(position.outOfRange, isFalse);
    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.byType(RefreshProgressIndicator), findsNothing);

    await pullDown.up();
    await tester.pump(const Duration(seconds: 1));

    expect(position.pixels, 0);
    expect(bundle.adapter.requests.length, requestsBeforeDrag);
    expect(tester.takeException(), isNull);
  });

  testWidgets('顶部下拉不触发刷新：iOS 无下拉刷新控件也不新增请求', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      _enqueueMovieDetailResponses(bundle);

      await pumpPage(
        tester,
        size: const Size(390, 600),
        platform: TargetPlatform.iOS,
      );

      final position = _scrollPosition(tester);
      expect(position.maxScrollExtent, greaterThan(0));
      final requestsBeforeDrag = bundle.adapter.requests.length;
      final pullDown = await tester.startGesture(
        tester.getCenter(find.byKey(MovieDetailPageContent.scrollViewKey)),
      );
      await pullDown.moveBy(const Offset(0, 320));
      await tester.pump();

      // 顶部钉住：不回弹、不显示下拉刷新控件。
      expect(position.pixels, 0);
      expect(find.byType(CupertinoSliverRefreshControl), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);

      await pullDown.up();
      await tester.pump(const Duration(seconds: 1));

      expect(bundle.adapter.requests.length, requestsBeforeDrag);

      // 底部上滑的过卷手感保留。
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final pushUp = await tester.startGesture(
        tester.getCenter(find.byKey(MovieDetailPageContent.scrollViewKey)),
      );
      await pushUp.moveBy(const Offset(0, -240));
      await tester.pump();
      expect(position.pixels, greaterThan(position.maxScrollExtent));
      await pushUp.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('tapping a clip opens the actions drawer instead of playing', (
    WidgetTester tester,
  ) async {
    _enqueueMovieDetailResponses(bundle);
    _enqueueMovieClips(bundle);

    await pumpPage(tester);

    final clipCard = find.byKey(const Key('movie-clip-strip-card-1'));
    await tester.scrollUntilVisible(
      clipCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // 卡片滚到视口中央：底部悬浮信息栏会盖住贴边的内容，居中后 tap 才落在卡上。
    await Scrollable.ensureVisible(
      tester.element(clipCard),
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    await tester.tap(clipCard);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movie-detail-clip-action-play')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movie-detail-clip-action-rename')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

ScrollPosition _scrollPosition(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(MovieDetailPageContent.scrollViewKey),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;
}

void _enqueueMovieDetailResponses(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/ABC-001',
    body: <String, dynamic>{
      'javdb_id': 'MovieA1',
      'movie_number': 'ABC-001',
      'title': 'Movie 1',
      'cover_image': null,
      'release_date': '2024-01-02',
      'duration_minutes': 120,
      'score': 4.5,
      'watched_count': 12,
      'want_watch_count': 23,
      'comment_count': 34,
      'score_number': 45,
      'is_collection': false,
      'is_subscribed': true,
      'can_play': true,
      'series_id': 7,
      'series_name': 'Attackers',
      'summary': '',
      'actors': const <Map<String, dynamic>>[],
      'tags': const <Map<String, dynamic>>[],
      'thin_cover_image': null,
      'plot_images': const <Map<String, dynamic>>[],
      'media_items': const <Map<String, dynamic>>[],
    },
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media-libraries',
    body: const <Map<String, dynamic>>[],
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/ABC-001/similar',
    body: const <String, dynamic>{'items': <dynamic>[]},
  );
}

void _enqueueMovieClips(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/media-clips',
    body: <String, dynamic>{
      'items': const <Map<String, dynamic>>[
        <String, dynamic>{
          'clip_id': 1,
          'media_id': 1,
          'movie_number': 'ABC-001',
          'start_offset_seconds': 120,
          'end_offset_seconds': 300,
          'title': '精彩片段',
          'duration_seconds': 180,
          'file_size_bytes': 15728640,
          'cover_image': null,
          'stream_url': '/media-clips/1/stream',
        },
      ],
    },
  );
}
