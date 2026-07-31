// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 桌面壳层折叠状态控制器的桥。
///
/// 原生装配：body 直接构造，组合根不再 override。

@ProviderFor(appShellController)
final appShellControllerProvider = AppShellControllerProvider._();

/// 桌面壳层折叠状态控制器的桥。
///
/// 原生装配：body 直接构造，组合根不再 override。

final class AppShellControllerProvider
    extends
        $FunctionalProvider<
          AppShellController,
          AppShellController,
          AppShellController
        >
    with $Provider<AppShellController> {
  /// 桌面壳层折叠状态控制器的桥。
  ///
  /// 原生装配：body 直接构造，组合根不再 override。
  AppShellControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appShellControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appShellControllerHash();

  @$internal
  @override
  $ProviderElement<AppShellController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppShellController create(Ref ref) {
    return appShellController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppShellController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppShellController>(value),
    );
  }
}

String _$appShellControllerHash() =>
    r'6a01e5940099dc3a595bf85ac41b13d8cc9e55a1';

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
