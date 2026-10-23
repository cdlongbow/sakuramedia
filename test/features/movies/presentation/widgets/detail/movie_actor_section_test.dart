import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_actor_section.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/pump_with_providers.dart';
import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('管理态可移除演员并刷新详情', (tester) async {
    final bundle = await _createBundle();
    var changes = 0;
    bundle.adapter.enqueueJson(
      method: 'DELETE',
      path: '/movies/ABC-001/actors/1',
      statusCode: 204,
    );

    await _pumpSection(
      tester,
      bundle: bundle,
      actors: <MovieActorDto>[_movieActor(1, '山田杏奈')],
      onActorsChanged: () async => changes++,
    );

    await tester.tap(find.byKey(const Key('movie-actors-manage-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-actors-finish-button')), findsOneWidget);
    expect(find.byKey(const Key('movie-actor-add-tile')), findsOneWidget);
    expect(find.byKey(const Key('movie-actors-edit-hint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('movie-actor-1')));
    await tester.pumpAndSettle();

    expect(changes, 1);
    final request = bundle.adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/movies/ABC-001/actors/1');
    await _drainToast(tester);
  });

  testWidgets('空演员表可通过搜索添加已有演员', (tester) async {
    final bundle = await _createBundle();
    var changes = 0;
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      statusCode: 200,
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[_actorJson(id: 9, name: '新人女优')],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/movies/ABC-001/actors/9',
      statusCode: 204,
    );

    await _pumpSection(
      tester,
      bundle: bundle,
      actors: const <MovieActorDto>[],
      onActorsChanged: () async => changes++,
    );

    expect(find.text('暂无演员'), findsOneWidget);
    expect(find.text('添加后将改为手动管理，刷新元数据不再覆盖。'), findsOneWidget);
    await tester.tap(find.byKey(const Key('movie-actors-add-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-actor-picker')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('movie-actor-picker-search-field')),
      '新人',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('movie-actor-picker-candidate-9')),
      findsOneWidget,
    );
    expect(find.text('本地女优'), findsOneWidget);

    await tester.tap(find.byKey(const Key('movie-actor-picker-candidate-9')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('movie-actor-picker-confirm')));
    await tester.pumpAndSettle();

    expect(changes, 1);
    final request = bundle.adapter.requests
        .where((request) => request.method == 'PUT')
        .single;
    expect(request.path, '/movies/ABC-001/actors/9');
    await _drainToast(tester);
  });

  testWidgets('搜索无结果时可新建本地女优并加入影片', (tester) async {
    final bundle = await _createBundle();
    var changes = 0;
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      statusCode: 200,
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/actors',
      statusCode: 201,
      body: _actorJson(id: 12, name: '本地新人'),
    );
    bundle.adapter.enqueueJson(
      method: 'PUT',
      path: '/movies/ABC-001/actors/12',
      statusCode: 204,
    );

    await _pumpSection(
      tester,
      bundle: bundle,
      actors: const <MovieActorDto>[],
      onActorsChanged: () async => changes++,
    );

    await tester.tap(find.byKey(const Key('movie-actors-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('movie-actor-picker-search-field')),
      '本地新人',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('movie-actor-picker-create-entry')));
    await tester.pumpAndSettle();
    expect(find.text('新建本地女优'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('movie-actor-create-name-field')),
          )
          .controller
          ?.text,
      '本地新人',
    );

    await tester.tap(find.byKey(const Key('movie-actor-create-confirm')));
    await tester.pumpAndSettle();

    expect(changes, 1);
    final createRequest = bundle.adapter.requests
        .where((request) => request.method == 'POST')
        .single;
    expect(createRequest.path, '/actors');
    expect(createRequest.body, <String, dynamic>{'name': '本地新人', 'gender': 1});
    final addRequest = bundle.adapter.requests
        .where((request) => request.method == 'PUT')
        .single;
    expect(addRequest.path, '/movies/ABC-001/actors/12');
    await _drainToast(tester);
  });

  testWidgets('添加弹窗在搜索状态切换和新建模式下保持固定高度', (tester) async {
    final bundle = await _createBundle();
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      statusCode: 200,
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[_actorJson(id: 9, name: '新人女优')],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      statusCode: 200,
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
    );

    await _pumpSection(tester, bundle: bundle, actors: const <MovieActorDto>[]);
    await tester.tap(find.byKey(const Key('movie-actors-add-button')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('movie-actor-picker'));
    final initialHeight = tester.getSize(dialog).height;

    await tester.enterText(
      find.byKey(const Key('movie-actor-picker-search-field')),
      '新人',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('movie-actor-picker-candidate-9')),
      findsOneWidget,
    );
    expect(tester.getSize(dialog).height, closeTo(initialHeight, 0.5));

    await tester.tap(find.byKey(const Key('movie-actor-picker-candidate-9')));
    await tester.pump();
    expect(
      find.byKey(const Key('movie-actor-picker-selection-summary')),
      findsOneWidget,
    );
    expect(tester.getSize(dialog).height, closeTo(initialHeight, 0.5));

    await tester.enterText(
      find.byKey(const Key('movie-actor-picker-search-field')),
      '无人',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-actor-picker-empty')), findsOneWidget);
    expect(tester.getSize(dialog).height, closeTo(initialHeight, 0.5));

    await tester.tap(find.byKey(const Key('movie-actor-picker-create-entry')));
    await tester.pumpAndSettle();
    expect(find.text('新建本地女优'), findsOneWidget);
    expect(tester.getSize(dialog).height, closeTo(initialHeight, 0.5));
  });

  testWidgets('手动管理状态展示提示且不提供恢复入口', (tester) async {
    final bundle = await _createBundle();

    await _pumpSection(
      tester,
      bundle: bundle,
      actors: <MovieActorDto>[_movieActor(1, '山田杏奈')],
      isActorsManuallyManaged: true,
    );

    expect(find.byKey(const Key('movie-actors-manual-notice')), findsOneWidget);
    expect(find.text('演员表已手动管理，刷新元数据不会覆盖。'), findsOneWidget);
    expect(find.textContaining('恢复'), findsNothing);
  });
}

Future<void> _drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<TestApiBundle> _createBundle() async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
  );
  final bundle = await createTestApiBundle(sessionStore);
  addTearDown(bundle.dispose);
  addTearDown(sessionStore.dispose);
  return bundle;
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TestApiBundle bundle,
  required List<MovieActorDto> actors,
  Future<void> Function()? onActorsChanged,
  bool isActorsManuallyManaged = false,
}) {
  return pumpWithProviders(
    tester,
    bundle: bundle,
    theme: sakuraThemeData,
    physicalSize: const Size(900, 760),
    home: Scaffold(
      body: SingleChildScrollView(
        child: MovieActorSection(
          movieNumber: 'ABC-001',
          actors: actors,
          isActorsManuallyManaged: isActorsManuallyManaged,
          moviesApi: bundle.moviesApi,
          actorsApi: bundle.actorsApi,
          onActorsChanged: onActorsChanged ?? () async {},
        ),
      ),
    ),
  );
}

MovieActorDto _movieActor(int id, String name) {
  return MovieActorDto(
    id: id,
    javdbId: 'javdb-$id',
    name: name,
    aliasName: '',
    gender: MovieActorDto.femaleGender,
    isSubscribed: false,
    profileImage: null,
    apiDisplayName: name,
  );
}

Map<String, dynamic> _actorJson({required int id, required String name}) {
  return <String, dynamic>{
    'id': id,
    'javdb_id': null,
    'name': name,
    'alias_name': '',
    'display_name': name,
    'profile_image': null,
    'is_subscribed': false,
    'gender': 1,
    'movie_count': 0,
    'mutation_revision': 0,
  };
}
