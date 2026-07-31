import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/app/app_page_state_cache.dart';

part 'app_page_state_cache_provider.g.dart';

/// 全局 [AppPageStateCache] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<AppPageStateCache>())` 注入——
/// `maybeReadAppPageStateCache` 经 `ProviderScope.containerOf` 读它，
/// 读不到（无 ProviderScope / 未 override）时页面降级为 owned state。
@Riverpod(keepAlive: true)
AppPageStateCache appPageStateCache(Ref ref) {
  final cache =
      AppPageStateCache()..bindSessionStore(ref.watch(sessionStoreProvider));
  ref.onDispose(cache.dispose);
  return cache;
}
