import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';
import 'package:sakuramedia/features/shared/presentation/providers/session_scoped_invalidation.dart';

/// 模拟一个「会话级常驻列表」：每次 build 返回一个自增的批次号，用它判断
/// provider 有没有被重建。
class _SessionScopedNotifier extends AsyncNotifier<int> {
  int buildCount = 0;

  @override
  Future<int> build() async {
    invalidateOnSignOut(ref);
    return ++buildCount;
  }
}

final _provider = AsyncNotifierProvider<_SessionScopedNotifier, int>(
  _SessionScopedNotifier.new,
  retry: kNoAsyncNotifierRetry,
);

Future<SessionStore> _signedInStore() async {
  final store = SessionStore.inMemory();
  await store.saveBaseUrl('https://api.example.com');
  await store.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-08-05T12:00:00Z'),
  );
  return store;
}

void main() {
  test('登出边沿触发 invalidateSelf，旧会话的数据不会留下', () async {
    final store = await _signedInStore();
    addTearDown(store.dispose);
    final container = ProviderContainer(
      overrides: [sessionStoreProvider.overrideWithValue(store)],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    // 常驻列表在真实场景里总有页面在监听；挂一个监听者让重建立即发生。
    container.listen(_provider, (_, _) {});

    expect(await container.read(_provider.future), 1);

    await store.clearSession();
    await container.read(_provider.future);

    expect(container.read(_provider.notifier).buildCount, 2);
  });

  test('会话未变化（同为已登录）不触发重建', () async {
    final store = await _signedInStore();
    addTearDown(store.dispose);
    final container = ProviderContainer(
      overrides: [sessionStoreProvider.overrideWithValue(store)],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    container.listen(_provider, (_, _) {});

    expect(await container.read(_provider.future), 1);

    // 只换 baseUrl / 续签 token：hasSession 始终为 true，不应重建。
    await store.saveBaseUrl('https://api2.example.com');
    await store.saveTokens(
      accessToken: 'access-token-2',
      refreshToken: 'refresh-token-2',
      expiresAt: DateTime.parse('2026-08-06T12:00:00Z'),
    );
    await container.read(_provider.future);

    expect(container.read(_provider.notifier).buildCount, 1);
  });

  test('provider 释放后摘掉监听者，登出不再回调', () async {
    final store = await _signedInStore();
    addTearDown(store.dispose);
    final container = ProviderContainer(
      overrides: [sessionStoreProvider.overrideWithValue(store)],
      retry: (_, _) => null,
    );
    container.listen(_provider, (_, _) {});
    await container.read(_provider.future);

    container.dispose();

    // 已 dispose 的 provider 再收到会话变更不应抛（listener 必须已摘掉）。
    await expectLater(store.clearSession(), completes);
  });
}
