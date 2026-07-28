import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';

part 'movie_subscriptions_api_provider.g.dart';

/// 订阅管理 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MovieSubscriptionsApi>())` 注入。
@Riverpod(keepAlive: true)
MovieSubscriptionsApi movieSubscriptionsApi(Ref ref) {
  throw UnimplementedError(
    'Override movieSubscriptionsApiProvider at the app root',
  );
}
