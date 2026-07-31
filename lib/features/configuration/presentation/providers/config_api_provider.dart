import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/configuration/data/api/config_api.dart';

part 'config_api_provider.g.dart';

/// configuration 域 ConfigApi 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ConfigApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ConfigApi configApi(Ref ref) {
  return ConfigApi(apiClient: ref.watch(apiClientProvider));
}
