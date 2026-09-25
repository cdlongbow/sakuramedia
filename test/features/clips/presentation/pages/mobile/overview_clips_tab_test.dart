import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/clip_collections/data/dto/clip_collection_dto.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_overview_provider.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/clips/presentation/pages/mobile/overview_clips_tab.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_provider.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/domain/clips/clip_cover_card.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_card.dart';

void main() {
  testWidgets('initial loading uses collection and clip grid skeletons', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
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
          theme: sakuraMobileThemeData,
          home: const Scaffold(body: MobileOverviewClipsTab()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppSkeletonizer), findsNWidgets(2));
    expect(find.text('切片合集'), findsOneWidget);
    expect(find.text('我的合集'), findsNothing);
    // 加载态渲染的是真实卡片（占位数据），骨架即真实布局。
    expect(
      find.byKey(const Key('mobile-clips-collections-row')),
      findsOneWidget,
    );
    expect(find.byType(CollectionCard), findsWidgets);
    expect(find.byType(ClipCoverCard), findsWidgets);
  });

  testWidgets('进入选择保留合集横滑区且网格位置不变', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clipsOverviewProvider.overrideWith(_PopulatedClipsOverview.new),
          clipCollectionsOverviewProvider.overrideWith(
            _PopulatedClipCollectionsOverview.new,
          ),
        ],
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: const Scaffold(body: MobileOverviewClipsTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardTop = tester
        .getTopLeft(find.byKey(const Key('mobile-clip-grid-card-1')))
        .dy;

    await tester.tap(
      find.byKey(const Key('mobile-clips-enter-selection-button')),
    );
    await tester.pumpAndSettle();

    // 选择态原地改写顶栏：合集横滑区保留，网格位置不变。
    expect(find.byKey(const Key('mobile-clips-collections-row')), findsOneWidget);
    expect(find.text('已选 0 个'), findsOneWidget);
    expect(find.byKey(const Key('mobile-clips-select-all-button')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-clips-batch-bottom-bar')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('mobile-clip-grid-card-1'))).dy,
      closeTo(cardTop, 0.1),
    );

    await tester.tap(
      find.byKey(const Key('mobile-clips-exit-selection-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-clips-batch-bottom-bar')), findsNothing);
    expect(
      find.byKey(const Key('mobile-clips-enter-selection-button')),
      findsOneWidget,
    );
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

class _PopulatedClipCollectionsOverview extends ClipCollectionsOverview {
  @override
  Future<List<ClipCollectionDto>> build() async {
    return const <ClipCollectionDto>[
      ClipCollectionDto(
        id: 7,
        name: '我的合集',
        description: '',
        clipCount: 1,
        coverImage: null,
        createdAt: null,
        updatedAt: null,
      ),
    ];
  }
}
