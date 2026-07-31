// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_center_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(notificationCenterController)
final notificationCenterControllerProvider =
    NotificationCenterControllerProvider._();

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

final class NotificationCenterControllerProvider
    extends
        $FunctionalProvider<
          NotificationCenterController,
          NotificationCenterController,
          NotificationCenterController
        >
    with $Provider<NotificationCenterController> {
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
  NotificationCenterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCenterControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCenterControllerHash();

  @$internal
  @override
  $ProviderElement<NotificationCenterController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationCenterController create(Ref ref) {
    return notificationCenterController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationCenterController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationCenterController>(value),
    );
  }
}

String _$notificationCenterControllerHash() =>
    r'd17263fabf67f697efb28fe6b2ae23a38a073793';
