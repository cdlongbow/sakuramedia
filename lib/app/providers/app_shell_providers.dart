import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/app/app_state.dart';
import 'package:sakuramedia/app/app_version_info_controller.dart';

part 'app_shell_providers.g.dart';

/// 桌面壳层折叠状态控制器的桥。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 组合根
/// `overrideWithValue(context.read<AppShellController>())` 注入。
@Riverpod(keepAlive: true)
AppShellController appShellController(Ref ref) {
  throw UnimplementedError(
    'Override appShellControllerProvider at the app root',
  );
}

/// 前后端版本信息控制器的桥（懒加载：首次被 read/watch 才触发请求，
/// 与旧 MultiProvider 的 create 懒语义一致——真源仍在 Provider 侧）。
///
/// 消费方（sidebar / 移动抽屉）在 try/catch 里取：未 override 的测试
/// 得到 null、版本行隐藏，与旧 `ProviderNotFoundException` 降级一致。
@Riverpod(keepAlive: true)
AppVersionInfoController appVersionInfoController(Ref ref) {
  throw UnimplementedError(
    'Override appVersionInfoControllerProvider at the app root',
  );
}
