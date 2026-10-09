import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_provider.dart';

import '../../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;
  late ProviderContainer container;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
    container = ProviderContainer(
      overrides: bundle.riverpodOverrides(),
      retry: null,
    );
  });

  tearDown(() {
    container.dispose();
    bundle.dispose();
  });

  test('load 上报浏览；refresh 不上报，页面手势 reportView 才补报', () async {
    bundle.adapter
      ..enqueueJson(method: 'GET', path: '/movies/ABC-001', body: _movieJson())
      ..enqueueJson(
        method: 'GET',
        path: '/movies/ABC-001/similar',
        body: const <String, dynamic>{'items': <dynamic>[]},
      )
      ..enqueueJson(method: 'GET', path: '/movies/ABC-001', body: _movieJson())
      ..enqueueJson(
        method: 'GET',
        path: '/movies/ABC-001/similar',
        body: const <String, dynamic>{'items': <dynamic>[]},
      );
    final subscription = container.listen(
      movieDetailProvider('ABC-001'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(movieDetailProvider('ABC-001').notifier).load();
    await _waitForViewHistoryPosts(bundle, 1);
    expect(bundle.adapter.hitCount('POST', '/view-history'), 1);
    expect(_lastViewHistoryBody(bundle), <String, dynamic>{
      'entity_type': 'movie',
      'entity_id': 5,
    });

    // refresh 也服务后台同步（媒体管理页删版本），不能顺带上报。
    await container.read(movieDetailProvider('ABC-001').notifier).refresh();
    await _settle();
    expect(bundle.adapter.hitCount('POST', '/view-history'), 1);

    // 页面手势刷新成功后由页面显式补报。
    container.read(movieDetailProvider('ABC-001').notifier).reportView();
    await _waitForViewHistoryPosts(bundle, 2);
    expect(_lastViewHistoryBody(bundle), <String, dynamic>{
      'entity_type': 'movie',
      'entity_id': 5,
    });
  });
}

Map<String, dynamic> _lastViewHistoryBody(TestApiBundle bundle) {
  return bundle.adapter.requests
          .lastWhere(
            (request) =>
                request.method == 'POST' && request.path == '/view-history',
          )
          .body
      as Map<String, dynamic>;
}

Future<void> _waitForViewHistoryPosts(
  TestApiBundle bundle,
  int expected,
) async {
  for (
    var attempt = 0;
    attempt < 100 &&
        bundle.adapter.hitCount('POST', '/view-history') < expected;
    attempt++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Map<String, dynamic> _movieJson() => <String, dynamic>{
  'id': 5,
  'javdb_id': 'MovieA1',
  'movie_number': 'ABC-001',
  'title': 'Movie 1',
  'cover_image': null,
  'release_date': '2024-01-02',
  'duration_minutes': 120,
  'is_collection': false,
  'is_subscribed': true,
  'can_play': true,
  'summary': '',
  'actors': const <Map<String, dynamic>>[],
  'tags': const <Map<String, dynamic>>[],
  'plot_images': const <Map<String, dynamic>>[],
  'media_items': const <Map<String, dynamic>>[],
  'playlists': const <Map<String, dynamic>>[],
};
