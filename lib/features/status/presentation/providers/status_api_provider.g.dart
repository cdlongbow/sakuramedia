// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// status 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<StatusApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(statusApi)
final statusApiProvider = StatusApiProvider._();

/// status 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<StatusApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class StatusApiProvider
    extends $FunctionalProvider<StatusApi, StatusApi, StatusApi>
    with $Provider<StatusApi> {
  /// status 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<StatusApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  StatusApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusApiHash();

  @$internal
  @override
  $ProviderElement<StatusApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatusApi create(Ref ref) {
    return statusApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatusApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatusApi>(value),
    );
  }
}

String _$statusApiHash() => r'14a99ae5390dc38d481fac67a4308cbc62209914';
