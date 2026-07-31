import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_reviews_api.dart';

part 'hot_reviews_api_provider.g.dart';

/// hot_reviews 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<HotReviewsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。
@Riverpod(keepAlive: true)
HotReviewsApi hotReviewsApi(Ref ref) {
  throw UnimplementedError('Override hotReviewsApiProvider at the app root');
}
