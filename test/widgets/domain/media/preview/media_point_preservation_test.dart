import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_preview_launcher.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore session;
  late TestApiBundle bundle;
  setUp(() async {
    session = SessionStore.inMemory();
    await session.saveBaseUrl('https://api.example.com');
    bundle = await createTestApiBundle(session);
  });
  tearDown(() {
    bundle.dispose();
    session.dispose();
  });

  Future<void> openPreview(
    WidgetTester tester, {
    required bool video,
    required bool mobile,
    required bool saved,
    ValueChanged<MediaPreviewAction?>? onAction,
    VoidCallback? onRemoved,
  }) async {
    tester.view.physicalSize = mobile
        ? const Size(390, 844)
        : const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (!video) {
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/movies/ABC-001',
        body: {'movie_number': 'ABC-001', 'title': '保存的影片'},
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: AppPlatformScope(
          platform: mobile ? AppPlatform.mobile : AppPlatform.desktop,
          child: OKToast(
            child: MaterialApp(
              theme: mobile ? sakuraMobileThemeData : sakuraThemeData,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    child: const Text('打开'),
                    onPressed: () async {
                      final action = await showMomentPreviewOverlay(
                        context: context,
                        item: MomentListItem(
                          pointId: 12,
                          mediaId: saved ? 0 : 34,
                          movieNumber: video ? null : 'ABC-001',
                          videoItemId: video ? 7 : null,
                          thumbnailId: saved ? 0 : 56,
                          offsetSeconds: 90,
                          image: null,
                        ),
                        pointId: saved ? 12 : null,
                        presentation: MediaPreviewPresentation.auto,
                        allowAddToCollection: true,
                        closeOnPointRemoved: true,
                        onPointRemoved: onRemoved,
                      );
                      onAction?.call(action);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  for (final video in [false, true]) {
    for (final mobile in [false, true]) {
      testWidgets(
        'orphan ${video ? 'video' : 'JAV'} ${mobile ? 'mobile' : 'desktop'} can join collections and delete',
        (tester) async {
          MediaPreviewAction? action;
          var removed = 0;
          await openPreview(
            tester,
            video: video,
            mobile: mobile,
            saved: true,
            onAction: (value) => action = value,
          );
          expect(find.textContaining('来源已删除'), findsOneWidget);
          expect(find.text('删除标记'), findsOneWidget);
          expect(find.text('播放'), findsNothing);
          expect(
            find.byKey(const Key('media-preview-center-play')),
            findsNothing,
          );
          expect(find.text('当前结果缺少媒体标识'), findsNothing);
          expect(
            bundle.adapter.requests.where((r) => r.path.startsWith('/media/')),
            isEmpty,
          );
          await tester.tap(find.text('加入合集'));
          await tester.pumpAndSettle();
          expect(action, MediaPreviewAction.addToCollection);
          await openPreview(
            tester,
            video: video,
            mobile: mobile,
            saved: true,
            onRemoved: () => removed++,
          );
          bundle.adapter.enqueueJson(
            method: 'DELETE',
            path: '/media-points/12',
            statusCode: 204,
            body: null,
          );
          await tester.tap(find.text('删除标记'));
          await tester.pumpAndSettle();
          expect(bundle.adapter.hitCount('DELETE', '/media-points/12'), 1);
          expect(removed, 1);
          expect(find.byType(MediaPreviewDialog), findsNothing);
          dismissAllToast(showAnim: false);
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('recommendation id is not treated as a saved point id', (
    tester,
  ) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/media/34/points',
      body: <dynamic>[],
    );
    await openPreview(tester, video: false, mobile: false, saved: false);
    expect(bundle.adapter.hitCount('GET', '/media/34/points'), 1);
    expect(find.text('添加标记'), findsOneWidget);
    expect(find.text('删除标记'), findsNothing);
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/media/34/points',
      statusCode: 201,
      body: {
        'point_id': 99,
        'media_id': 34,
        'thumbnail_id': 56,
        'offset_seconds': 90,
      },
    );
    await tester.tap(find.text('添加标记'));
    await tester.pumpAndSettle();
    expect(find.text('删除标记'), findsOneWidget);
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/media-points/99',
      statusCode: 204,
      body: null,
    );
    await tester.tap(find.text('删除标记'));
    await tester.pumpAndSettle();
    expect(bundle.adapter.hitCount('DELETE', '/media-points/99'), 1);
    expect(bundle.adapter.hitCount('DELETE', '/media-points/12'), 0);
    dismissAllToast(showAnim: false);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
