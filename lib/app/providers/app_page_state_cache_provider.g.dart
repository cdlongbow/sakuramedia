// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_page_state_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 [AppPageStateCache] 的 Riverpod 入口。
///
/// 原生装配：构造即绑定会话（登出自动清空），组合根不再 override——
/// `maybeReadAppPageStateCache` 经 `ProviderScope.containerOf` 读它，
/// 读不到（无 ProviderScope / 未 override）时页面降级为 owned state。

@ProviderFor(appPageStateCache)
final appPageStateCacheProvider = AppPageStateCacheProvider._();

/// 全局 [AppPageStateCache] 的 Riverpod 入口。
///
/// 原生装配：构造即绑定会话（登出自动清空），组合根不再 override——
/// `maybeReadAppPageStateCache` 经 `ProviderScope.containerOf` 读它，
/// 读不到（无 ProviderScope / 未 override）时页面降级为 owned state。

final class AppPageStateCacheProvider
    extends
        $FunctionalProvider<
          AppPageStateCache,
          AppPageStateCache,
          AppPageStateCache
        >
    with $Provider<AppPageStateCache> {
  /// 全局 [AppPageStateCache] 的 Riverpod 入口。
  ///
  /// 原生装配：构造即绑定会话（登出自动清空），组合根不再 override——
  /// `maybeReadAppPageStateCache` 经 `ProviderScope.containerOf` 读它，
  /// 读不到（无 ProviderScope / 未 override）时页面降级为 owned state。
  AppPageStateCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPageStateCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPageStateCacheHash();

  @$internal
  @override
  $ProviderElement<AppPageStateCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppPageStateCache create(Ref ref) {
    return appPageStateCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppPageStateCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppPageStateCache>(value),
    );
  }
}

String _$appPageStateCacheHash() => r'c02f8c0dcd6f08b501c7bebaf8068d28084e01af';
