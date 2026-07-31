import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/activity/presentation/notification_center_controller.dart';

part 'notification_center_provider.g.dart';

/// 常驻通知中心控制器的桥。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 组合根
/// `overrideWithValue(context.read<NotificationCenterController>())` 注入
/// （构造即 bindSessionStore 的会话生命周期仍由 Provider 侧负责，组合根
/// 反转时改为原生装配 + ref.onDispose 配对）。
///
/// 消费方（角标）在 try/catch 里 `ref.watch`：未 override（部分测试）时抛
/// [UnimplementedError] 被捕获、角标隐藏——与旧 `ProviderNotFoundException`
/// 降级语义一致，也避免测试里隐式触发 SSE/bootstrap 请求。
@Riverpod(keepAlive: true)
NotificationCenterController notificationCenterController(Ref ref) {
  throw UnimplementedError(
    'Override notificationCenterControllerProvider at the app root',
  );
}
