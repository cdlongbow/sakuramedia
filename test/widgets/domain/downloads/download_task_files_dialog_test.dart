import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/downloads/download_task_files_dialog.dart';

import '../../../support/test_api_bundle.dart';

void main() {
  testWidgets('desktop dialog lists task files with path and size', (
    tester,
  ) async {
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks/1/files',
      body: [
        {
          'name': 'zh.srt',
          'relative_path': 'TEST-001/subs/zh.srt',
          'size_bytes': 2048,
          'is_video': false,
        },
        {
          'name': 'TEST-001.mkv',
          'relative_path': 'TEST-001/TEST-001.mkv',
          'size_bytes': 1572864,
          'is_video': true,
        },
      ],
    );

    await tester.pumpWidget(_buildApp(bundle, AppPlatform.desktop));
    await tester.tap(find.text('打开文件'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('download-task-files-modal')), findsOneWidget);
    expect(find.text('任务文件'), findsOneWidget);
    // 头部番号为主、影片标题为次。
    expect(find.text('ABP-123'), findsOneWidget);
    expect(find.text('示例影片标题'), findsOneWidget);
    expect(find.text('TEST-001.mkv'), findsOneWidget);
    expect(find.text('TEST-001/TEST-001.mkv'), findsOneWidget);
    expect(find.text('1.5 MB'), findsOneWidget);
    expect(find.text('zh.srt'), findsOneWidget);
    expect(find.text('TEST-001/subs/zh.srt'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    // 前端按大小降序展示：大文件在响应里靠后也应排在上面。
    expect(
      tester.getTopLeft(find.text('TEST-001.mkv')).dy,
      lessThan(tester.getTopLeft(find.text('zh.srt')).dy),
    );

    final request = bundle.adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, '/download-tasks/1/files');
  });

  testWidgets('shows empty state when the task source has no files', (
    tester,
  ) async {
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks/1/files',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(_buildApp(bundle, AppPlatform.desktop));
    await tester.tap(find.text('打开文件'));
    await tester.pumpAndSettle();

    expect(find.text('该任务源内没有文件'), findsOneWidget);
  });

  testWidgets('retries after a load failure and then shows files', (
    tester,
  ) async {
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks/1/files',
      statusCode: 502,
      body: {
        'error': {'code': 'download_task_files_failed', 'message': 'boom'},
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks/1/files',
      body: [
        {
          'name': 'TEST-001.mkv',
          'relative_path': 'TEST-001.mkv',
          'size_bytes': 1024,
          'is_video': true,
        },
      ],
    );

    await tester.pumpWidget(_buildApp(bundle, AppPlatform.desktop));
    await tester.tap(find.text('打开文件'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('download-task-files-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('download-task-files-retry')));
    await tester.pumpAndSettle();

    expect(find.text('TEST-001.mkv'), findsOneWidget);
    expect(bundle.adapter.requests, hasLength(2));
  });

  testWidgets('opens as a mobile drawer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bundle = await _createBundle();
    addTearDown(bundle.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks/1/files',
      body: [
        {
          'name': 'TEST-001.mkv',
          'relative_path': 'TEST-001.mkv',
          'size_bytes': 1024,
          'is_video': true,
        },
      ],
    );

    await tester.pumpWidget(_buildApp(bundle, AppPlatform.mobile));
    await tester.tap(find.text('打开文件'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('download-task-files-modal')), findsOneWidget);
    expect(find.text('TEST-001.mkv'), findsOneWidget);
  });
}

Widget _buildApp(TestApiBundle bundle, AppPlatform platform) {
  return ProviderScope(
    overrides: bundle.riverpodOverrides(),
    child: MaterialApp(
      theme: platform == AppPlatform.mobile
          ? sakuraMobileThemeData
          : sakuraDesktopThemeData,
      home: AppPlatformScope(
        platform: platform,
        child: const _DialogLauncher(),
      ),
    ),
  );
}

class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => unawaited(
            showDownloadTaskFilesDialog(
              context: context,
              taskId: 1,
              movieNumber: 'ABP-123',
              title: '示例影片标题',
            ),
          ),
          child: const Text('打开文件'),
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
    expiresAt: DateTime.parse('2026-03-08T10:00:00Z'),
  );
  return createTestApiBundle(sessionStore);
}
