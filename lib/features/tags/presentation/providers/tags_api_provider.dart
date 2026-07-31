import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/tags/data/tags_api.dart';

part 'tags_api_provider.g.dart';

/// tags 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<TagsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
TagsApi tagsApi(Ref ref) {
  return TagsApi(apiClient: ref.watch(apiClientProvider));
}
