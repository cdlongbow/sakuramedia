// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_page_state_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局 [AppPageStateCache] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<AppPageStateCache>())` 注入——
/// `maybeReadAppPageStateCache` 经 `ProviderScope.containerOf` 读它，
/// 读不到（无 ProviderScope / 未 override）时页面降级为 owned state。

@ProviderFor(appPageStateCache)
final appPageStateCacheProvider = AppPageStateCacheProvider._();

/// 全局 [AppPageStateCache] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<AppPageStateCache>())` 注入——
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
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<AppPageStateCache>())` 注入——
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

String _$appPageStateCacheHash() => r'6eea613c557ffebcaf1b7a822ed11a09064cf2b9';
