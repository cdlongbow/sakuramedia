import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/clip_collections/data/dto/clip_collection_dto.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_overview_provider.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/clips/presentation/pages/desktop/clips_page.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_provider.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/domain/clips/clip_grid_card.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_card.dart';

void main() {
  testWidgets('initial loading keeps the desktop clips layout as skeletons', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clipsOverviewProvider.overrideWith(_LoadingClipsOverview.new),
          clipCollectionsOverviewProvider.overrideWith(
            _LoadingClipCollectionsOverview.new,
          ),
        ],
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopClipsPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppSkeletonizer), findsNWidgets(2));
    expect(find.text('切片合集'), findsOneWidget);
    expect(find.text('我的合集'), findsNothing);
    // 加载态渲染的是真实卡片（占位数据），骨架即真实布局。
    expect(find.byKey(const Key('clips-collections-row')), findsOneWidget);
    expect(find.byType(CollectionCard), findsWidgets);
    expect(find.byType(ClipGridCard), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tapping a clip opens the actions dialog instead of playing', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clipsOverviewProvider.overrideWith(_PopulatedClipsOverview.new),
          clipCollectionsOverviewProvider.overrideWith(
            _EmptyClipCollectionsOverview.new,
          ),
        ],
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopClipsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('clip-grid-card-tap-1')),
    );
    await tester.tap(find.byKey(const Key('clip-grid-card-tap-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clip-actions-dialog')), findsOneWidget);
    expect(find.byKey(const Key('clip-action-play')), findsOneWidget);
    expect(find.byKey(const Key('clip-action-movie')), findsOneWidget);
    expect(
      find.byKey(const Key('clip-action-add-to-collection')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('clip-action-rename')), findsOneWidget);
    expect(find.byKey(const Key('clip-action-delete')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LoadingClipsOverview extends ClipsOverview {
  @override
  Future<ClipsOverviewState> build() => Completer<ClipsOverviewState>().future;
}

class _LoadingClipCollectionsOverview extends ClipCollectionsOverview {
  @override
  Future<List<ClipCollectionDto>> build() =>
      Completer<List<ClipCollectionDto>>().future;
}

class _PopulatedClipsOverview extends ClipsOverview {
  @override
  Future<ClipsOverviewState> build() async {
    return ClipsOverviewState(
      paged: PagedListState<MediaClipDto>(
        items: <MediaClipDto>[
          const MediaClipDto(
            clipId: 1,
            mediaId: 1,
            movieNumber: 'ABC-001',
            startOffsetSeconds: 120,
            endOffsetSeconds: 300,
            title: '精彩片段',
            durationSeconds: 180,
            fileSizeBytes: 15728640,
            coverImage: null,
            streamUrl: '/media-clips/1/stream',
            createdAt: null,
          ),
        ],
        currentPage: 1,
        total: 1,
      ),
    );
  }
}

class _EmptyClipCollectionsOverview extends ClipCollectionsOverview {
  @override
  Future<List<ClipCollectionDto>> build() async =>
      const <ClipCollectionDto>[];
}
