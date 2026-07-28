// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movies_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// movies 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MoviesApi>())` 注入——与 `mediaApiProvider` /
/// `downloadsApiProvider` 同一范式。

@ProviderFor(moviesApi)
final moviesApiProvider = MoviesApiProvider._();

/// movies 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<MoviesApi>())` 注入——与 `mediaApiProvider` /
/// `downloadsApiProvider` 同一范式。

final class MoviesApiProvider
    extends $FunctionalProvider<MoviesApi, MoviesApi, MoviesApi>
    with $Provider<MoviesApi> {
  /// movies 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实际实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<MoviesApi>())` 注入——与 `mediaApiProvider` /
  /// `downloadsApiProvider` 同一范式。
  MoviesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moviesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moviesApiHash();

  @$internal
  @override
  $ProviderElement<MoviesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MoviesApi create(Ref ref) {
    return moviesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MoviesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MoviesApi>(value),
    );
  }
}

String _$moviesApiHash() => r'd35306750df86eb37474659a518df51e9375a5bd';
