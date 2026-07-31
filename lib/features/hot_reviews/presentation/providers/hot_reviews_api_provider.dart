import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_reviews_api.dart';

part 'hot_reviews_api_provider.g.dart';

/// hot_reviews 域 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<HotReviewsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
HotReviewsApi hotReviewsApi(Ref ref) {
  return HotReviewsApi(apiClient: ref.watch(apiClientProvider));
}
