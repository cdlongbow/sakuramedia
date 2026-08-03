// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 桌面壳侧边栏折叠状态。
///
/// 迁移前形态:`AppShellController extends ChangeNotifier`(仅一个 bool)
/// + 桥 provider。keepAlive:折叠偏好在会话内跨路由存续(与旧常驻控制器
/// 语义一致)。

@ProviderFor(AppShellSidebarCollapsed)
final appShellSidebarCollapsedProvider = AppShellSidebarCollapsedProvider._();

/// 桌面壳侧边栏折叠状态。
///
/// 迁移前形态:`AppShellController extends ChangeNotifier`(仅一个 bool)
/// + 桥 provider。keepAlive:折叠偏好在会话内跨路由存续(与旧常驻控制器
/// 语义一致)。
final class AppShellSidebarCollapsedProvider
    extends $NotifierProvider<AppShellSidebarCollapsed, bool> {
  /// 桌面壳侧边栏折叠状态。
  ///
  /// 迁移前形态:`AppShellController extends ChangeNotifier`(仅一个 bool)
  /// + 桥 provider。keepAlive:折叠偏好在会话内跨路由存续(与旧常驻控制器
  /// 语义一致)。
  AppShellSidebarCollapsedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellSidebarCollapsedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellSidebarCollapsedHash();

  @$internal
  @override
  AppShellSidebarCollapsed create() => AppShellSidebarCollapsed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appShellSidebarCollapsedHash() =>
    r'96b9b66c1b4d5c41aeafe05d7c1eec34f35fd3e2';

/// 桌面壳侧边栏折叠状态。
///
/// 迁移前形态:`AppShellController extends ChangeNotifier`(仅一个 bool)
/// + 桥 provider。keepAlive:折叠偏好在会话内跨路由存续(与旧常驻控制器
/// 语义一致)。

abstract class _$AppShellSidebarCollapsed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 前后端版本信息控制器的桥（懒加载：首次被 read/watch 才触发请求，
/// 与旧 MultiProvider 的 create 懒语义一致——真源由 `lib/app/app.dart` 的
/// 组合根 `overrideWith` 工厂注入，这里 body 保持抛 [UnimplementedError]）。
///
/// 消费方（sidebar / 移动抽屉）在 try/catch 里取：未 override 的测试
/// 得到 null、版本行隐藏，与旧 `ProviderNotFoundException` 降级一致。

@ProviderFor(appVersionInfoController)
final appVersionInfoControllerProvider = AppVersionInfoControllerProvider._();

/// 前后端版本信息控制器的桥（懒加载：首次被 read/watch 才触发请求，
/// 与旧 MultiProvider 的 create 懒语义一致——真源由 `lib/app/app.dart` 的
/// 组合根 `overrideWith` 工厂注入，这里 body 保持抛 [UnimplementedError]）。
///
/// 消费方（sidebar / 移动抽屉）在 try/catch 里取：未 override 的测试
/// 得到 null、版本行隐藏，与旧 `ProviderNotFoundException` 降级一致。

final class AppVersionInfoControllerProvider
    extends
        $FunctionalProvider<
          AppVersionInfoController,
          AppVersionInfoController,
          AppVersionInfoController
        >
    with $Provider<AppVersionInfoController> {
  /// 前后端版本信息控制器的桥（懒加载：首次被 read/watch 才触发请求，
  /// 与旧 MultiProvider 的 create 懒语义一致——真源由 `lib/app/app.dart` 的
  /// 组合根 `overrideWith` 工厂注入，这里 body 保持抛 [UnimplementedError]）。
  ///
  /// 消费方（sidebar / 移动抽屉）在 try/catch 里取：未 override 的测试
  /// 得到 null、版本行隐藏，与旧 `ProviderNotFoundException` 降级一致。
  AppVersionInfoControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionInfoControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionInfoControllerHash();

  @$internal
  @override
  $ProviderElement<AppVersionInfoController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppVersionInfoController create(Ref ref) {
    return appVersionInfoController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppVersionInfoController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppVersionInfoController>(value),
    );
  }
}

String _$appVersionInfoControllerHash() =>
    r'3b807fca512e94357696fcc360fc70f1a27a2f72';
