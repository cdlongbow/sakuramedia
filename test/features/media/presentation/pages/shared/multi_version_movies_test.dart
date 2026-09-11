import 'package:sakuramedia/app/app_platform.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/media/presentation/pages/shared/media_management_content.dart';
import 'package:sakuramedia/theme.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  for (final mobile in [false, true]) {
    testWidgets(
      'versions ${mobile ? "mobile" : "desktop"}: lazy loading, details, delete failure and retry',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = mobile
            ? const Size(360, 760)
            : const Size(1100, 760);
        addTearDown(tester.view.reset);
        final session = SessionStore.inMemory();
        await session.saveBaseUrl('https://api.example.com');
        await session.saveTokens(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime(2030),
        );
        final bundle = await createTestApiBundle(session);
        addTearDown(() {
          bundle.dispose();
          session.dispose();
        });
        bundle.adapter.setFallbackJson(
          method: 'GET',
          path: '/media',
          body: _page([]),
        );
        bundle.adapter.setFallbackJson(
          method: 'GET',
          path: '/media-libraries',
          body: [
            {
              'id': 1,
              'name': '本地影视库',
              'provider_key': 'local',
              'provider_config': {},
            },
          ],
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/media/multi-version-movies',
          body: _page([_group()]),
        );
        String? opened;
        await tester.pumpWidget(
          ProviderScope(
            overrides: bundle.riverpodOverrides(),
            child: MaterialApp(
              theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
              builder: (_, child) => AppPlatformScope(
                platform: mobile ? AppPlatform.mobile : AppPlatform.desktop,
                child: child!,
              ),
              home: OKToast(
                child: Scaffold(
                  body: MediaManagementContent(
                    keyPrefix: 'test',
                    rootKey: const Key('page'),
                    mobile: mobile,
                    onOpenMovieDetail: (_, number) => opened = number,
                    onOpenVideoCollectionDetail: (_, __) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          bundle.adapter.hitCount('GET', '/media/multi-version-movies'),
          0,
        );
        await tester.tap(find.byKey(const Key('test-tab-versions')));
        await tester.pumpAndSettle();
        expect(find.text('2 个版本'), findsOneWidget);
        expect(find.text('8.0 GB'), findsOneWidget);
        expect(find.text('2160p'), findsOneWidget);
        expect(find.text('失效'), findsOneWidget);
        expect(find.text('本地影视库'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('test-version-movie-DEMO-001')));
        expect(opened, 'DEMO-001');
        await tester.tap(find.byKey(const Key('test-version-delete-1')));
        await tester.pumpAndSettle();
        expect(find.textContaining('对应文件'), findsOneWidget);
        expect(find.textContaining('保留 1 个版本'), findsOneWidget);
        await tester.tap(find.byKey(const Key('test-version-delete-cancel-1')));
        await tester.pumpAndSettle();
        expect(bundle.adapter.hitCount('DELETE', '/media/1'), 0);
        bundle.adapter.enqueueJson(
          method: 'DELETE',
          path: '/media/1',
          statusCode: 503,
          body: {
            'error': {'code': 'provider_unavailable', 'message': '存储暂不可用'},
          },
        );
        await tester.tap(find.byKey(const Key('test-version-delete-1')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('test-version-delete-confirm-1')),
        );
        await tester.pumpAndSettle();
        expect(find.text('存储暂不可用'), findsOneWidget);
        expect(
          find.byKey(const Key('test-version-group-DEMO-001')),
          findsOneWidget,
        );
        bundle.adapter.enqueueJson(
          method: 'DELETE',
          path: '/media/1',
          statusCode: 204,
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/media/multi-version-movies',
          body: _page([]),
        );
        await tester.tap(
          find.byKey(const Key('test-version-delete-confirm-1')),
        );
        await tester.pumpAndSettle();
        expect(find.text('暂无多版本影片'), findsOneWidget);
        expect(find.text('共 0 部'), findsOneWidget);
        expect(bundle.adapter.hitCount('DELETE', '/media/2'), 0);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }

  testWidgets(
    'initial failure retries and fixed header remains while versions scroll',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = SessionStore.inMemory();
      await session.saveBaseUrl('https://api.example.com');
      await session.saveTokens(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2030),
      );
      final bundle = await createTestApiBundle(session);
      addTearDown(() {
        bundle.dispose();
        session.dispose();
      });
      bundle.adapter.setFallbackJson(
        method: 'GET',
        path: '/media',
        body: _page([]),
      );
      bundle.adapter.setFallbackJson(
        method: 'GET',
        path: '/media-libraries',
        body: [],
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media/multi-version-movies',
        statusCode: 503,
        body: {
          'error': {'message': 'Unavailable'},
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: bundle.riverpodOverrides(),
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            builder: (_, child) =>
                AppPlatformScope(platform: AppPlatform.mobile, child: child!),
            home: OKToast(
              child: Scaffold(
                body: MediaManagementContent(
                  keyPrefix: 'test',
                  rootKey: const Key('page'),
                  mobile: true,
                  onOpenMovieDetail: (_, __) {},
                  onOpenVideoCollectionDetail: (_, __) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('test-tab-versions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test-versions-retry')), findsOneWidget);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media/multi-version-movies',
        body: _page([_group(count: 6)]),
      );
      await tester.tap(find.byKey(const Key('test-versions-retry')));
      await tester.pumpAndSettle();
      final header = find.byKey(const Key('test-versions-total'));
      final top = tester.getTopLeft(header);
      final scroll = find.byKey(const Key('test-versions-scroll'));
      await tester.drag(scroll, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header), top);
      for (var i = 0; i < 5; i++) {
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.getTopLeft(header), top);
      expect(
        find.byKey(const Key('test-version-delete-6')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, dynamic> _page(List<dynamic> items) => {
  'items': items,
  'total': items.length,
  'page': 1,
  'page_size': 20,
};
Map<String, dynamic> _group({int count = 2}) => {
  'movie_number': 'DEMO-001',
  'media_count': count,
  'media_items': List.generate(
    count,
    (i) => {
      'id': i + 1,
      'kind': 'jav',
      'movie_number': 'DEMO-001',
      'title': '用于展示的影片名称',
      'library_id': 1,
      'file_name': 'DEMO-001.${i + 1}.2160p.HEVC.mp4',
      'file_size_bytes': i == 0 ? 8589934592 : 3221225472,
      'duration_seconds': 7200,
      'resolution': i == 0 ? '2160p' : '1080p',
      'valid': i != 1,
    },
  ),
};
