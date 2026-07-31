import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/network/api_client.dart';

part 'api_client_provider.g.dart';

/// 全局 [ApiClient] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ApiClient>())` 注入——迁移过渡期 Provider
/// 侧是真源，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final client = ApiClient(sessionStore: ref.watch(sessionStoreProvider));
  ref.onDispose(client.dispose);
  return client;
}
