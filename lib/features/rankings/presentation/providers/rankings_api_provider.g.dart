// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rankings_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// rankings 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<RankingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(rankingsApi)
final rankingsApiProvider = RankingsApiProvider._();

/// rankings 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<RankingsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class RankingsApiProvider
    extends $FunctionalProvider<RankingsApi, RankingsApi, RankingsApi>
    with $Provider<RankingsApi> {
  /// rankings 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<RankingsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  RankingsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rankingsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rankingsApiHash();

  @$internal
  @override
  $ProviderElement<RankingsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RankingsApi create(Ref ref) {
    return rankingsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RankingsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RankingsApi>(value),
    );
  }
}

String _$rankingsApiHash() => r'c940ae5de2e0fd2fa21038fafcf31fad9f024e22';
