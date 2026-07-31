// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// activity 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActivityApi>())` 注入——与 `moviesApiProvider`
/// 同一范式。首个消费方是订阅管理页（统一资源任务操作走它）。

@ProviderFor(activityApi)
final activityApiProvider = ActivityApiProvider._();

/// activity 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ActivityApi>())` 注入——与 `moviesApiProvider`
/// 同一范式。首个消费方是订阅管理页（统一资源任务操作走它）。

final class ActivityApiProvider
    extends $FunctionalProvider<ActivityApi, ActivityApi, ActivityApi>
    with $Provider<ActivityApi> {
  /// activity 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ActivityApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式。首个消费方是订阅管理页（统一资源任务操作走它）。
  ActivityApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityApiHash();

  @$internal
  @override
  $ProviderElement<ActivityApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActivityApi create(Ref ref) {
    return activityApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityApi>(value),
    );
  }
}

String _$activityApiHash() => r'd2735d3da948b00941af11648cf37eb62b9c080d';
