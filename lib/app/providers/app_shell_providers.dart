import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/app/app_version_info_controller.dart';

part 'app_shell_providers.g.dart';

/// 桌面壳侧边栏折叠状态。
///
/// 迁移前形态:`AppShellController extends ChangeNotifier`(仅一个 bool)
/// + 桥 provider。keepAlive:折叠偏好在会话内跨路由存续(与旧常驻控制器
/// 语义一致)。
@Riverpod(keepAlive: true)
class AppShellSidebarCollapsed extends _$AppShellSidebarCollapsed {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

/// 前后端版本信息控制器的桥（懒加载：首次被 read/watch 才触发请求，
/// 与旧 MultiProvider 的 create 懒语义一致——真源由 `lib/app/app.dart` 的
/// 组合根 `overrideWith` 工厂注入，这里 body 保持抛 [UnimplementedError]）。
///
/// 消费方（sidebar / 移动抽屉）在 try/catch 里取：未 override 的测试
/// 得到 null、版本行隐藏，与旧 `ProviderNotFoundException` 降级一致。
@Riverpod(keepAlive: true)
AppVersionInfoController appVersionInfoController(Ref ref) {
  throw UnimplementedError(
    'Override appVersionInfoControllerProvider at the app root',
  );
}
