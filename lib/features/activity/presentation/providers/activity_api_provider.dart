import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/activity/data/activity_api.dart';

part 'activity_api_provider.g.dart';

/// activity 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActivityApi>())` 注入——与 `moviesApiProvider`
/// 同一范式。首个消费方是订阅管理页（统一资源任务操作走它）。
@Riverpod(keepAlive: true)
ActivityApi activityApi(Ref ref) {
  throw UnimplementedError('Override activityApiProvider at the app root');
}
