import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlist_resolution_options_state.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/playlist_filter_sections.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PlaylistResolutionOptionsState seed({
    List<PlaylistResolutionOptionDto> options =
        const <PlaylistResolutionOptionDto>[],
    bool isLoading = false,
    String? errorMessage,
    bool hasLoaded = false,
  }) {
    return PlaylistResolutionOptionsState(
      options: options,
      isLoading: isLoading,
      errorMessage: errorMessage,
      hasLoaded: hasLoaded,
    );
  }

  Future<void> pumpSections(
    WidgetTester tester, {
    PlaylistFilterState filterState = PlaylistFilterState.initial,
    required PlaylistResolutionOptionsState resolutionState,
    required ValueChanged<PlaylistFilterState> onChanged,
    VoidCallback? onResolutionRetry,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Material(
          child: SingleChildScrollView(
            child: PlaylistFilterSectionGroup(
              filterState: filterState,
              onChanged: onChanged,
              resolutionState: resolutionState,
              onResolutionRetry: onResolutionRetry ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('渲染分辨率分节：全部 + 后端档位（带命中数）', (tester) async {
    await pumpSections(
      tester,
      resolutionState: seed(
        options: const <PlaylistResolutionOptionDto>[
          PlaylistResolutionOptionDto(resolution: '8K', count: 3),
          PlaylistResolutionOptionDto(resolution: '4K', count: 42),
          PlaylistResolutionOptionDto(resolution: '1080P', count: 120),
        ],
        hasLoaded: true,
      ),
      onChanged: (_) {},
    );

    expect(find.text('分辨率'), findsOneWidget);
    expect(
      find.byKey(const Key('playlist-filter-resolution-all')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('playlist-filter-resolution-8K')),
      findsOneWidget,
    );
    expect(find.text('8K(3)'), findsOneWidget);
    expect(find.text('4K(42)'), findsOneWidget);
    expect(find.text('1080P(120)'), findsOneWidget);
  });

  testWidgets('分辨率加载中 / 失败态：无数据时独占内容区', (tester) async {
    await pumpSections(
      tester,
      resolutionState: seed(isLoading: true),
      onChanged: (_) {},
    );
    expect(find.text('分辨率加载中'), findsOneWidget);

    await pumpSections(
      tester,
      resolutionState: seed(errorMessage: '分辨率加载失败'),
      onChanged: (_) {},
    );
    expect(find.text('分辨率加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('已有 chips 时刷新失败：chips 保留，错误降级为行内提示 + 重试', (tester) async {
    await pumpSections(
      tester,
      resolutionState: seed(
        options: const <PlaylistResolutionOptionDto>[
          PlaylistResolutionOptionDto(resolution: '4K', count: 42),
        ],
        hasLoaded: true,
        errorMessage: '分辨率加载失败',
      ),
      onChanged: (_) {},
    );

    // 已有档位 chips 不被抹掉。
    expect(
      find.byKey(const Key('playlist-filter-resolution-4K')),
      findsOneWidget,
    );
    // 错误行内展示，可重试。
    expect(find.text('分辨率加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('已有 chips 时后台刷新：chips 保留 + 底部 spinner', (tester) async {
    await pumpSections(
      tester,
      resolutionState: seed(
        options: const <PlaylistResolutionOptionDto>[
          PlaylistResolutionOptionDto(resolution: '4K', count: 42),
        ],
        hasLoaded: true,
        isLoading: true,
      ),
      onChanged: (_) {},
    );

    expect(
      find.byKey(const Key('playlist-filter-resolution-4K')),
      findsOneWidget,
    );
    expect(find.text('分辨率刷新中'), findsOneWidget);
  });

  testWidgets('渲染全部排序字段 chip 且 sortField 为 null 时隐藏方向分节', (tester) async {
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial,
      resolutionState: seed(),
      onChanged: (_) {},
    );

    expect(
      find.byKey(const Key('playlist-filter-sort-recent')),
      findsOneWidget,
    );
    for (final field in PlaylistSortField.values) {
      expect(
        find.byKey(Key('playlist-filter-sort-${field.apiValue}')),
        findsOneWidget,
      );
    }
    expect(find.text('升降序'), findsNothing);
  });

  testWidgets('选了排序字段后展示方向分节', (tester) async {
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.heat,
      ),
      resolutionState: seed(),
      onChanged: (_) {},
    );

    expect(find.text('升降序'), findsOneWidget);
    expect(
      find.byKey(const Key('playlist-filter-sort-direction-desc')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('playlist-filter-sort-direction-asc')),
      findsOneWidget,
    );
  });

  testWidgets('点击排序 chip 回传该字段，点击最近触达回传 null', (tester) async {
    final sortFields = <PlaylistSortField?>[];
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial,
      resolutionState: seed(),
      onChanged: (state) => sortFields.add(state.sortField),
    );

    await tester.tap(find.byKey(const Key('playlist-filter-sort-heat')));
    await tester.tap(find.byKey(const Key('playlist-filter-sort-recent')));

    expect(sortFields, <PlaylistSortField?>[PlaylistSortField.heat, null]);
  });

  testWidgets('点击方向 chip 回传对应升降序', (tester) async {
    SortDirection? lastDirection;
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.addedAt,
      ),
      resolutionState: seed(),
      onChanged: (state) => lastDirection = state.sortDirection,
    );

    await tester.tap(
      find.byKey(const Key('playlist-filter-sort-direction-asc')),
    );

    expect(lastDirection, SortDirection.asc);
  });

  testWidgets('点击分辨率 chip 回传对应档位，点击全部回传 null', (tester) async {
    final resolutions = <PlaylistResolutionFilter?>[];
    await pumpSections(
      tester,
      resolutionState: seed(
        options: const <PlaylistResolutionOptionDto>[
          PlaylistResolutionOptionDto(resolution: '4K', count: 42),
        ],
        hasLoaded: true,
      ),
      onChanged: (state) => resolutions.add(state.resolution),
    );

    await tester.tap(find.byKey(const Key('playlist-filter-resolution-4K')));
    await tester.tap(find.byKey(const Key('playlist-filter-resolution-all')));

    expect(resolutions, <PlaylistResolutionFilter?>[
      PlaylistResolutionFilter.k4k,
      null,
    ]);
  });
}
