// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_search_draft_store_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 图搜草稿仓 [ImageSearchDraftStore] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ImageSearchDraftStore>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

@ProviderFor(imageSearchDraftStore)
final imageSearchDraftStoreProvider = ImageSearchDraftStoreProvider._();

/// 图搜草稿仓 [ImageSearchDraftStore] 的 Riverpod 入口。
///
/// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
/// `overrideWithValue(context.read<ImageSearchDraftStore>())` 注入——与 `moviesApiProvider`
/// 同一范式，组合根反转后改为原生装配。

final class ImageSearchDraftStoreProvider
    extends
        $FunctionalProvider<
          ImageSearchDraftStore,
          ImageSearchDraftStore,
          ImageSearchDraftStore
        >
    with $Provider<ImageSearchDraftStore> {
  /// 图搜草稿仓 [ImageSearchDraftStore] 的 Riverpod 入口。
  ///
  /// body 抛 [UnimplementedError]，实例由 `lib/app/app.dart` 的组合根用
  /// `overrideWithValue(context.read<ImageSearchDraftStore>())` 注入——与 `moviesApiProvider`
  /// 同一范式，组合根反转后改为原生装配。
  ImageSearchDraftStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageSearchDraftStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageSearchDraftStoreHash();

  @$internal
  @override
  $ProviderElement<ImageSearchDraftStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageSearchDraftStore create(Ref ref) {
    return imageSearchDraftStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageSearchDraftStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageSearchDraftStore>(value),
    );
  }
}

String _$imageSearchDraftStoreHash() =>
    r'111a764dc51171e9e7523428f939df2c5f4cae8e';
