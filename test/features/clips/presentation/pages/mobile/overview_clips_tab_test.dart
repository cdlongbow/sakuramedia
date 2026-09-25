import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/clip_collections/data/dto/clip_collection_dto.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_overview_provider.dart';
import 'package:sakuramedia/features/clips/presentation/pages/mobile/overview_clips_tab.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_provider.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_overview_state.dart';
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
