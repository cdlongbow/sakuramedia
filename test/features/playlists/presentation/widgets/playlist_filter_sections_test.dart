import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_resolution_options_controller.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/playlist_filter_sections.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late ApiClient apiClient;
  late PlaylistsApi playlistsApi;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    apiClient = ApiClient(sessionStore: sessionStore);
    playlistsApi = PlaylistsApi(apiClient: apiClient);
  });

  tearDown(() {
    apiClient.dispose();
  });

  PlaylistResolutionOptionsController seededController({
    List<PlaylistResolutionOptionDto> options =
        const <PlaylistResolutionOptionDto>[],
    bool isLoading = false,
    String? errorMessage,
    bool hasLoaded = false,
  }) {
    return PlaylistResolutionOptionsController.seeded(
      playlistsApi: playlistsApi,
      playlistId: 8,
      options: options,
      isLoading: isLoading,
      errorMessage: errorMessage,
      hasLoaded: hasLoaded,
    );
  }

  Future<void> pumpSections(
    WidgetTester tester, {
    PlaylistFilterState filterState = PlaylistFilterState.initial,
    required PlaylistResolutionOptionsController resolutionOptions,
    required ValueChanged<PlaylistFilterState> onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Material(
          child: SingleChildScrollView(
            child: PlaylistFilterSectionGroup(
              filterState: filterState,
              onChanged: onChanged,
              resolutionOptions: resolutionOptions,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('渲染分辨率分节：全部 + 后端档位（带命中数）', (tester) async {
    final controller = seededController(
      options: const <PlaylistResolutionOptionDto>[
        PlaylistResolutionOptionDto(resolution: '8K', count: 3),
        PlaylistResolutionOptionDto(resolution: '4K', count: 42),
        PlaylistResolutionOptionDto(resolution: '1080P', count: 120),
      ],
      hasLoaded: true,
    );
    addTearDown(controller.dispose);

    await pumpSections(
      tester,
      resolutionOptions: controller,
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
    final loadingController = seededController(isLoading: true);
    addTearDown(loadingController.dispose);
    await pumpSections(
      tester,
      resolutionOptions: loadingController,
      onChanged: (_) {},
    );
    expect(find.text('分辨率加载中'), findsOneWidget);

    final errorController = seededController(errorMessage: '分辨率加载失败');
    addTearDown(errorController.dispose);
    await pumpSections(
      tester,
      resolutionOptions: errorController,
      onChanged: (_) {},
    );
    expect(find.text('分辨率加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('已有 chips 时刷新失败：chips 保留，错误降级为行内提示 + 重试', (tester) async {
    final controller = seededController(
      options: const <PlaylistResolutionOptionDto>[
        PlaylistResolutionOptionDto(resolution: '4K', count: 42),
      ],
      hasLoaded: true,
      errorMessage: '分辨率加载失败',
    );
    addTearDown(controller.dispose);

    await pumpSections(
      tester,
      resolutionOptions: controller,
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
    final controller = seededController(
      options: const <PlaylistResolutionOptionDto>[
        PlaylistResolutionOptionDto(resolution: '4K', count: 42),
      ],
      hasLoaded: true,
      isLoading: true,
    );
    addTearDown(controller.dispose);

    await pumpSections(
      tester,
      resolutionOptions: controller,
      onChanged: (_) {},
    );

    expect(
      find.byKey(const Key('playlist-filter-resolution-4K')),
      findsOneWidget,
    );
    expect(find.text('分辨率刷新中'), findsOneWidget);
  });

  testWidgets('渲染全部排序字段 chip 且 sortField 为 null 时隐藏方向分节',
      (tester) async {
    final controller = seededController();
    addTearDown(controller.dispose);
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial,
      resolutionOptions: controller,
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
    final controller = seededController();
    addTearDown(controller.dispose);
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.heat,
      ),
      resolutionOptions: controller,
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
    final controller = seededController();
    addTearDown(controller.dispose);
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial,
      resolutionOptions: controller,
      onChanged: (state) => sortFields.add(state.sortField),
    );

    await tester.tap(find.byKey(const Key('playlist-filter-sort-heat')));
    await tester.tap(find.byKey(const Key('playlist-filter-sort-recent')));

    expect(
      sortFields,
      <PlaylistSortField?>[PlaylistSortField.heat, null],
    );
  });

  testWidgets('点击方向 chip 回传对应升降序', (tester) async {
    SortDirection? lastDirection;
    final controller = seededController();
    addTearDown(controller.dispose);
    await pumpSections(
      tester,
      filterState: PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.addedAt,
      ),
      resolutionOptions: controller,
      onChanged: (state) => lastDirection = state.sortDirection,
    );

    await tester.tap(
      find.byKey(const Key('playlist-filter-sort-direction-asc')),
    );

    expect(lastDirection, SortDirection.asc);
  });

  testWidgets('点击分辨率 chip 回传对应档位，点击全部回传 null', (tester) async {
    final resolutions = <PlaylistResolutionFilter?>[];
    final controller = seededController(
      options: const <PlaylistResolutionOptionDto>[
        PlaylistResolutionOptionDto(resolution: '4K', count: 42),
      ],
      hasLoaded: true,
    );
    addTearDown(controller.dispose);
    await pumpSections(
      tester,
      resolutionOptions: controller,
      onChanged: (state) => resolutions.add(state.resolution),
    );

    await tester.tap(find.byKey(const Key('playlist-filter-resolution-4K')));
    await tester.tap(
      find.byKey(const Key('playlist-filter-resolution-all')),
    );

    expect(
      resolutions,
      <PlaylistResolutionFilter?>[
        PlaylistResolutionFilter.k4k,
        null,
      ],
    );
  });
}
