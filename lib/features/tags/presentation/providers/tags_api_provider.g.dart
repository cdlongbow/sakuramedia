// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags_api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// tags 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<TagsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(tagsApi)
final tagsApiProvider = TagsApiProvider._();

/// tags 域 API 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<TagsApi>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class TagsApiProvider
    extends $FunctionalProvider<TagsApi, TagsApi, TagsApi>
    with $Provider<TagsApi> {
  /// tags 域 API 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<TagsApi>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  TagsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsApiHash();

  @$internal
  @override
  $ProviderElement<TagsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagsApi create(Ref ref) {
    return tagsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagsApi>(value),
    );
  }
}

String _$tagsApiHash() => r'0b0f5fcd5931fd45515da1f0a31f5996bb3c3a0d';
