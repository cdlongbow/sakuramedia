import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/clip_collections/data/api/clip_collections_api.dart';

part 'clip_collections_api_provider.g.dart';

/// clip_collections 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<ClipCollectionsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
ClipCollectionsApi clipCollectionsApi(Ref ref) {
  return ClipCollectionsApi(apiClient: ref.watch(apiClientProvider));
}
