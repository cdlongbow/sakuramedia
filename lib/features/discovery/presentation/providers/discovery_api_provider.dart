import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/discovery/data/discovery_api.dart';

part 'discovery_api_provider.g.dart';

/// discovery 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<DiscoveryApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
DiscoveryApi discoveryApi(Ref ref) {
  return DiscoveryApi(apiClient: ref.watch(apiClientProvider));
}
