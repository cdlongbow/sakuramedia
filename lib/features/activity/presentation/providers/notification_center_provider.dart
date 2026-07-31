import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/activity/presentation/notification_center_controller.dart';

part 'notification_center_provider.g.dart';

/// 常驻通知中心控制器的桥。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 组合根
/// `overrideWith` 工厂注入（工厂内 `bindSessionStore` 会话生命周期 +
/// `ref.onDispose` 配对销毁，见 app.dart）。
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
