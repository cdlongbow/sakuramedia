import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/media/presentation/pages/shared/media_management_content.dart';
import 'package:sakuramedia/features/media/presentation/providers/multi_version_movies_provider.dart';
import 'package:sakuramedia/theme.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore session;
  late TestApiBundle bundle;
  setUp(() async {
    session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    await session.saveTokens(
      accessToken: 'token',
      refreshToken: 'refresh',
      expiresAt: DateTime(2030),
    );
    bundle = await createTestApiBundle(session);
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
      body: _page([
        _group('A-001', [1, 2, 3]),
        _group('B-001', [4, 5, 6]),
      ]),
    );
  });
  tearDown(() {
    bundle.dispose();
    session.dispose();
  });

  for (final mobile in [false, true]) {
    testWidgets(
      'version filters ${mobile ? "mobile" : "desktop"} send independent options',
      (tester) async {
        await _pump(tester, bundle, mobile: mobile);
        bundle.adapter.setFallbackJson(
          method: 'GET',
          path: '/media/multi-version-movies',
          body: _page([]),
        );
        for (final key in ['vr', 'fc2', 'vr', 'fc2']) {
          await tester.tap(find.byKey(Key('batch-versions-include-$key')));
          await tester.pumpAndSettle();
        }
        final requests = bundle.adapter.requests
            .where((r) => r.path == '/media/multi-version-movies')
            .toList();
        expect(
          requests.map(
            (r) => [
              r.uri.queryParameters['include_vr'],
              r.uri.queryParameters['include_fc2'],
            ],
          ),
          [
            ['false', 'false'],
            ['true', 'false'],
            ['true', 'true'],
            ['false', 'true'],
            ['false', 'false'],
          ],
        );
        expect(
          requests.every((r) => r.uri.queryParameters['page'] == '1'),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'batch ${mobile ? "mobile" : "desktop"}: keep one, show progress, continue on failure and retry',
      (tester) async {
        await _pump(tester, bundle, mobile: mobile);
        await tester.tap(find.byKey(const Key('batch-versions-select')));
        await tester.pumpAndSettle();
        expect(find.text('已选 0 个'), findsOneWidget);
        await _select(tester, 1);
        await _select(tester, 2);
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('batch-version-select-3')))
              .onChanged,
          isNull,
        );
        await tester.tapAt(
          tester.getCenter(find.byKey(const Key('batch-version-row-3'))),
        );
        await tester.pumpAndSettle();
        expect(find.text('已选 2 个'), findsOneWidget);
        await tester.tapAt(
          tester.getCenter(find.byKey(const Key('batch-version-file-1'))),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('batch-version-select-3')))
              .onChanged,
          isNotNull,
        );
        await _select(tester, 1);
        await _select(tester, 4);
        expect(find.text('已选 3 个'), findsOneWidget);
        final first = Completer<ResponseBody>();
        final third = Completer<ResponseBody>();
        bundle.adapter.enqueueResponder(
          method: 'DELETE',
          path: '/media/1',
          responder: (_, __) => first.future,
        );
        bundle.adapter.enqueueJson(
          method: 'DELETE',
          path: '/media/2',
          statusCode: 503,
        );
        bundle.adapter.enqueueResponder(
          method: 'DELETE',
          path: '/media/4',
          responder: (_, __) => third.future,
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/media/multi-version-movies',
          body: _page([
            _group('A-001', [2, 3]),
            _group('B-001', [5, 6]),
          ]),
        );
        await tester.tap(find.byKey(const Key('batch-versions-batch-delete')));
        await tester.pumpAndSettle();
        expect(find.textContaining('每部影片至少保留一个版本'), findsOneWidget);
        await tester.tap(find.byKey(const Key('batch-versions-batch-confirm')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('处理中 0/3'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0,
        );
        first.complete(ResponseBody.fromBytes([], 204));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('处理中 2/3'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          closeTo(2 / 3, 0.001),
        );
        expect(
          bundle.adapter.hitCount('GET', '/media/multi-version-movies'),
          1,
        );
        third.complete(ResponseBody.fromBytes([], 204));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('成功 2 个，失败 1 个'), findsOneWidget);
        await tester.tap(find.byKey(const Key('batch-progress-close-button')));
        await tester.pumpAndSettle();
        expect(
          bundle.adapter.hitCount('GET', '/media/multi-version-movies'),
          2,
        );
        expect(find.text('已选 1 个'), findsOneWidget);
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('batch-version-select-2')))
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<Checkbox>(find.byKey(const Key('batch-version-select-3')))
              .onChanged,
          isNull,
        );
        for (final id in [3, 5, 6]) {
          expect(bundle.adapter.hitCount('DELETE', '/media/$id'), 0);
        }
        bundle.adapter.enqueueJson(
          method: 'DELETE',
          path: '/media/2',
          statusCode: 204,
        );
        bundle.adapter.enqueueJson(
          method: 'GET',
          path: '/media/multi-version-movies',
          body: _page([
            _group('B-001', [5, 6]),
          ]),
        );
        await tester.tap(find.byKey(const Key('batch-versions-batch-delete')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('batch-versions-batch-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('正在删除影片版本'), findsNothing);
        expect(
          find.byKey(const Key('batch-version-group-A-001')),
          findsNothing,
        );
        expect(find.byKey(const Key('batch-versions-select')), findsOneWidget);
        expect(bundle.adapter.hitCount('DELETE', '/media/2'), 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'clear and cancel selection send no delete; changed groups abort confirmation',
    (tester) async {
      await _pump(tester, bundle, mobile: false);
      await tester.tap(find.byKey(const Key('batch-versions-select')));
      await tester.pumpAndSettle();
      await _select(tester, 1);
      await tester.tap(find.byKey(const Key('batch-versions-clear-selection')));
      await tester.pumpAndSettle();
      expect(find.text('已选 0 个'), findsOneWidget);
      await tester.tap(find.byKey(const Key('batch-versions-exit-selection')));
      await tester.pumpAndSettle();
      expect(bundle.adapter.hitCount('DELETE', '/media/1'), 0);
      await tester.tap(find.byKey(const Key('batch-versions-select')));
      await tester.pumpAndSettle();
      await _select(tester, 1);
      await tester.tap(find.byKey(const Key('batch-versions-batch-delete')));
      await tester.pumpAndSettle();
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/media/multi-version-movies',
        body: _page([
          _group('B-001', [4, 5, 6]),
        ]),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MediaManagementContent)),
      );
      final refresh = container
          .read(multiVersionMoviesProvider().notifier)
          .refresh();
      await tester.pumpAndSettle();
      await refresh;
      await tester.tap(find.byKey(const Key('batch-versions-batch-confirm')));
      await tester.pumpAndSettle();
      expect(bundle.adapter.hitCount('DELETE', '/media/1'), 0);
      expect(find.text('影片版本已变化，请重新选择，至少保留一个版本'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  TestApiBundle bundle, {
  required bool mobile,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = mobile
      ? const Size(360, 760)
      : const Size(1100, 760);
  addTearDown(tester.view.reset);
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
              keyPrefix: 'batch',
              rootKey: const Key('page'),
              mobile: mobile,
              onOpenMovieDetail: (_, __) {},
              onOpenVideoCollectionDetail: (_, __) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('batch-tab-versions')));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, int id) async {
  final target = find.byKey(Key('batch-version-row-$id'));
  for (var i = 0; i < 15 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(
      find.byKey(const Key('batch-versions-scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
  }
  await tester.tapAt(tester.getRect(target).centerRight - const Offset(4, 0));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _page(List<dynamic> items) => {
  'items': items,
  'total': items.length,
  'page': 1,
  'page_size': 20,
};
Map<String, dynamic> _group(String number, List<int> ids) => {
  'movie_number': number,
  'media_count': ids.length,
  'media_items': ids
      .map(
        (id) => {
          'id': id,
          'kind': 'jav',
          'movie_number': number,
          'title': '影片标题',
          'file_name': '$number.$id.mp4',
          'valid': true,
        },
      )
      .toList(),
};
