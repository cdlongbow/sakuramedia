import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';

part 'movie_subscriptions_api_provider.g.dart';

/// 订阅管理 API 的 Riverpod 入口。
///
/// 原生装配（组合根反转后）。测试用
/// `overrideWithValue(context.read<MovieSubscriptionsApi>())` 注入。
@Riverpod(keepAlive: true)
MovieSubscriptionsApi movieSubscriptionsApi(Ref ref) {
  return MovieSubscriptionsApi(apiClient: ref.watch(apiClientProvider));
}
