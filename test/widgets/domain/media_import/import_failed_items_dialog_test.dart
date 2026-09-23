import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/widgets/domain/media_import/import_failed_items_dialog.dart';

import '../../../support/test_api_bundle.dart';

Map<String, dynamic> _failedItemJson({
  String id = 'failure-1',
  String state = 'pending',
  bool canManualSearch = true,
  String? lastRetryError,
  String reason = 'movie_number_not_found',
  String kind = 'file',
}) {
  return <String, dynamic>{
    'id': id,
    'relative_path': 'release/$id.mp4',
    'size_bytes': 1024,
    'is_video': true,
    'reason': reason,
    'detail': '无法从文件名识别番号',
    'kind': kind,
    'state': state,
    'retry_task_run_id': null,
    'resolved_movie_id': null,
    'resolved_media_id': null,
    'last_retry_error': lastRetryError,
    'can_manual_search': canManualSearch,
  };
}

Map<String, dynamic> _searchResponseJson() {
  return <String, dynamic>{
    'movie_number': 'ABC-001',
    'candidates': <Map<String, dynamic>>[
      <String, dynamic>{
        'candidate_id': 'javdb:ABC-001:javdb-001',
        'source': 'javdb',
        'source_name': 'JavDB',
        'source_id': null,
        'javdb_id': 'javdb-001',
        'movie_number': 'ABC-001',
        'title': 'JavDB 标题',
        'cover_url': null,
        'release_date': '2026-09-01',
        'duration_minutes': 120,
      },
    ],
    'source_errors': const <dynamic>[],
  };
}

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppButton(
          label: '打开失败文件',
          onPressed: () => showImportFailedItemsDialog(
            context: context,
            taskRunId: 7,
            taskName: 'JAV媒体库导入',
          ),
        ),
      ),
    );
  }
}

Future<TestApiBundle> _createBundle() async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-12-31T12:00:00Z'),
  );
  return createTestApiBundle(sessionStore);
}

void main() {
  testWidgets('desktop dialog retries a failed item with a searched candidate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/imports/7/failed-items',
      body: <Map<String, dynamic>>[
        _failedItemJson(),
        _failedItemJson(
          id: 'skipped-1',
          reason: 'file_too_small',
          kind: 'skipped',
          canManualSearch: false,
        ),
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/imports/7/failed-items/failure-1/search',
      body: _searchResponseJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/imports/7/failed-items/failure-1/retry',
      statusCode: 202,
      body: <String, dynamic>{
        'task_run_id': 88,
        'task_key': 'library_import',
        'state': 'pending',
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/imports/7/failed-items',
      body: <Map<String, dynamic>>[_failedItemJson(state: 'queued')],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/imports/7/failed-items',
      body: <Map<String, dynamic>>[_failedItemJson(state: 'resolved')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraDesktopThemeData,
            home: const _DialogLauncher(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开失败文件'));
    await tester.pumpAndSettle();

    expect(find.text('失败与跳过文件'), findsOneWidget);
    expect(find.text('JAV媒体库导入 · 失败 1 个待处理 · 已跳过 1 个'), findsOneWidget);
    expect(find.text('失败文件'), findsOneWidget);
    expect(find.text('failure-1.mp4'), findsOneWidget);
    expect(find.text('未识别番号 · 1.0 KB'), findsOneWidget);
    expect(find.text('待处理'), findsOneWidget);
    expect(find.text('已跳过'), findsNWidgets(2));
    expect(find.text('文件过小 · 1.0 KB'), findsOneWidget);
    expect(
      find.byKey(const Key('import-failed-item-match-skipped-1')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('import-failed-item-match-failure-1')));
    await tester.pumpAndSettle();

    expect(find.text('手动匹配元数据'), findsOneWidget);
    expect(find.byKey(const Key('import-metadata-number-field')), findsOneWidget);
    expect(
      find.byKey(const Key('import-metadata-search-button')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('import-metadata-number-field')),
      'ABC-001',
    );
    await tester.tap(find.byKey(const Key('import-metadata-search-button')));
    await tester.pumpAndSettle();

    expect(find.text('JavDB 标题'), findsOneWidget);
    // 候选封面应为宽图（16:9 左侧缩略图），不是竖条。
    final coverSize = tester.getSize(
      find.descendant(
        of: find.byKey(
          const Key('import-metadata-candidate-javdb:ABC-001:javdb-001'),
        ),
        matching: find.byType(MaskedImage),
      ),
    );
    expect(coverSize.width, greaterThan(coverSize.height));
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('import-metadata-retry-button')))
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const Key('import-metadata-candidate-javdb:ABC-001:javdb-001')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppButton>(find.byKey(const Key('import-metadata-retry-button')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('import-metadata-retry-button')));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    final retryRequest = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/imports/7/failed-items/failure-1/retry',
    );
    expect(retryRequest.body, <String, dynamic>{
      'candidate_id': 'javdb:ABC-001:javdb-001',
    });
    expect(find.text('失败与跳过文件'), findsOneWidget);
    expect(find.text('重试中'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();
    expect(find.text('已导入'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('search field keeps a static icon while searching', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/imports/7/failed-items',
      body: <Map<String, dynamic>>[_failedItemJson()],
    );
    // 搜索请求挂起，停留在加载中状态。
    final searchCompleter = Completer<ResponseBody>();
    bundle.adapter.enqueueResponder(
      method: 'POST',
      path: '/imports/7/failed-items/failure-1/search',
      responder: (_, _) => searchCompleter.future,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraDesktopThemeData,
            home: const _DialogLauncher(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开失败文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-failed-item-match-failure-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('import-metadata-number-field')),
      'SSNI-888',
    );
    await tester.tap(find.byKey(const Key('import-metadata-search-button')));
    await tester.pump();

    // 搜索框后缀保持静态搜索图标，只有结果区中央一个转圈。
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 放行挂起的请求，清掉 dio 的接收超时计时器。
    searchCompleter.complete(
      ResponseBody.fromString(
        jsonEncode(_searchResponseJson()),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('mobile drawer hides the match action for unresolvable files', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/imports/7/failed-items',
      body: <Map<String, dynamic>>[
        _failedItemJson(state: 'resolved', canManualSearch: false),
        _failedItemJson(id: 'failure-2', canManualSearch: false),
        _failedItemJson(
          id: 'skipped-3',
          reason: 'unsupported_format',
          kind: 'skipped',
          canManualSearch: false,
        ),
        _failedItemJson(
          id: 'skipped-4',
          reason: 'already_indexed_path',
          kind: 'skipped',
          canManualSearch: false,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: const AppPlatformScope(
              platform: AppPlatform.mobile,
              child: _DialogLauncher(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开失败文件'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-failed-items-modal')), findsOneWidget);
    expect(find.text('已导入'), findsOneWidget);
    expect(find.text('待处理'), findsOneWidget);
    expect(find.text('不支持的格式 · 1.0 KB'), findsOneWidget);
    expect(find.text('已在库中 · 1.0 KB'), findsOneWidget);
    expect(find.text('已跳过'), findsNWidgets(3));
    expect(find.text('手动匹配'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
