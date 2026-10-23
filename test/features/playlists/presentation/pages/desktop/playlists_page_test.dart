import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/playlists/data/playlist_order_store.dart';
import 'package:sakuramedia/features/playlists/presentation/pages/desktop/playlists_page.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlist_order_store_provider.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_overview_provider.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_overview_scope.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/logged_in_session_store.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = await buildLoggedInSessionStore();
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/playlists',
      body: <Map<String, dynamic>>[
        _playlistJson(id: 1, name: '我的收藏', kind: 'favorites', isSystem: true),
        _playlistJson(
          id: 2,
          name: '最近播放',
          kind: 'recently_played',
          isSystem: true,
        ),
        _playlistJson(id: 10, name: '周末片单'),
        _playlistJson(id: 11, name: '经典收藏'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...bundle.riverpodOverrides(),
          playlistOrderStoreProvider.overrideWithValue(
            InMemoryPlaylistOrderStore(),
          ),
        ],
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopPlaylistsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('splits system and custom playlists into two sections', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('系统列表'), findsOneWidget);
    expect(find.text('我的播放列表'), findsOneWidget);
    expect(find.byKey(const Key('playlists-create-button')), findsOneWidget);
    expect(find.text('我的收藏'), findsOneWidget);
    expect(find.text('最近播放'), findsOneWidget);
    expect(find.text('周末片单'), findsOneWidget);
    expect(find.text('经典收藏'), findsOneWidget);

    // 系统列表在上，用户列表在下。
    expect(
      tester.getTopLeft(find.text('系统列表')).dy,
      lessThan(tester.getTopLeft(find.text('我的播放列表')).dy),
    );
    expect(
      tester.getTopLeft(find.text('我的收藏')).dy,
      lessThan(tester.getTopLeft(find.text('周末片单')).dy),
    );

    // 只有用户列表进入可拖拽排序的 Sliver。
    expect(
      find.descendant(
        of: find.byType(SliverReorderableList),
        matching: find.text('周末片单'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SliverReorderableList),
        matching: find.text('我的收藏'),
      ),
      findsNothing,
    );
  });

  testWidgets('reordering custom playlists leaves system lists in place', (
    tester,
  ) async {
    await pumpPage(tester);

    // 悬停用户列表，露出拖拽把手。
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('周末片单')));
    await tester.pump();
    final handle = find.byKey(const Key('playlist-reorder-handle-10'));
    expect(handle, findsOneWidget);

    await tester.drag(
      handle,
      const Offset(0, 90),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DesktopPlaylistsPage)),
    );
    final state = container
        .read(
          playlistsOverviewProvider(
            PlaylistsOverviewScope(orderScopeKey: sessionStore.baseUrl),
          ),
        )
        .requireValue;
    expect(state.playlists.map((playlist) => playlist.id), <int>[1, 2, 11, 10]);
  });
}

Map<String, dynamic> _playlistJson({
  required int id,
  required String name,
  String kind = 'custom',
  bool isSystem = false,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'kind': kind,
    'description': '',
    'movie_count': 0,
    'is_system': isSystem,
    'is_mutable': !isSystem,
    'is_deletable': !isSystem,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
}
