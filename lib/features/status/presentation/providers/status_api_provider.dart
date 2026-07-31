import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/status/data/status_api.dart';

part 'status_api_provider.g.dart';

/// status 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<StatusApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
StatusApi statusApi(Ref ref) {
  return StatusApi(apiClient: ref.watch(apiClientProvider));
}
