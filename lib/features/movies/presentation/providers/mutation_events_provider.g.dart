// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 跨页订阅变更广播源（legacy `ChangeNotifier`）的桥。
///
/// 过渡期方案 B：Provider 侧与 Riverpod 侧共用**同一个**
/// [MovieSubscriptionChangeNotifier] 实例，保持「单一广播源」。发起方无论在哪一
/// 侧，都 `reportChange` / `reportBatch` 到它；消费方在 Riverpod 侧走
/// [movieSubscriptionEventsProvider]，**不 `context.read`**。
///
/// 原生装配：body 直接构造 + `ref.onDispose` 配对销毁，组合根不再 override。
///
/// 命名注意：函数名不要以 `Notifier` 结尾——riverpod_generator 会把它从生成的
/// provider 变量名里剥掉，导致 `xxxNotifier` 生成出 `xxxProvider`。

@ProviderFor(movieSubscriptionBroadcaster)
final movieSubscriptionBroadcasterProvider =
    MovieSubscriptionBroadcasterProvider._();

/// 跨页订阅变更广播源（legacy `ChangeNotifier`）的桥。
///
/// 过渡期方案 B：Provider 侧与 Riverpod 侧共用**同一个**
/// [MovieSubscriptionChangeNotifier] 实例，保持「单一广播源」。发起方无论在哪一
/// 侧，都 `reportChange` / `reportBatch` 到它；消费方在 Riverpod 侧走
/// [movieSubscriptionEventsProvider]，**不 `context.read`**。
///
/// 原生装配：body 直接构造 + `ref.onDispose` 配对销毁，组合根不再 override。
///
/// 命名注意：函数名不要以 `Notifier` 结尾——riverpod_generator 会把它从生成的
/// provider 变量名里剥掉，导致 `xxxNotifier` 生成出 `xxxProvider`。

final class MovieSubscriptionBroadcasterProvider
    extends
        $FunctionalProvider<
          MovieSubscriptionChangeNotifier,
          MovieSubscriptionChangeNotifier,
          MovieSubscriptionChangeNotifier
        >
    with $Provider<MovieSubscriptionChangeNotifier> {
  /// 跨页订阅变更广播源（legacy `ChangeNotifier`）的桥。
  ///
  /// 过渡期方案 B：Provider 侧与 Riverpod 侧共用**同一个**
  /// [MovieSubscriptionChangeNotifier] 实例，保持「单一广播源」。发起方无论在哪一
  /// 侧，都 `reportChange` / `reportBatch` 到它；消费方在 Riverpod 侧走
  /// [movieSubscriptionEventsProvider]，**不 `context.read`**。
  ///
  /// 原生装配：body 直接构造 + `ref.onDispose` 配对销毁，组合根不再 override。
  ///
  /// 命名注意：函数名不要以 `Notifier` 结尾——riverpod_generator 会把它从生成的
  /// provider 变量名里剥掉，导致 `xxxNotifier` 生成出 `xxxProvider`。
  MovieSubscriptionBroadcasterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'movieSubscriptionBroadcasterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movieSubscriptionBroadcasterHash();

  @$internal
  @override
  $ProviderElement<MovieSubscriptionChangeNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MovieSubscriptionChangeNotifier create(Ref ref) {
    return movieSubscriptionBroadcaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MovieSubscriptionChangeNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MovieSubscriptionChangeNotifier>(
        value,
      ),
    );
  }
}

String _$movieSubscriptionBroadcasterHash() =>
    r'30d9a1ff0aefd67626874d360b36c47efdc519eb';

/// 订阅变更事件流：把 [MovieSubscriptionChangeNotifier] 的 `notifyListeners`
/// 翻译成一条条「本次广播的变更列表」。
///
/// 消费方 `ref.listen(movieSubscriptionEventsProvider, ...)` 后对自己的列表做
/// **就地补丁**（移除 / 改字段），语义与 Provider 侧监听方一致——不要
/// `invalidate` 触发整页重拉。
///
/// 单条 `reportChange` 与批量 `reportBatch` 在这里被统一成列表形式（复用
/// notifier 自己的 `consumePendingChanges` 分派），下游不必再区分两条路径。

@ProviderFor(movieSubscriptionEvents)
final movieSubscriptionEventsProvider = MovieSubscriptionEventsProvider._();

/// 订阅变更事件流：把 [MovieSubscriptionChangeNotifier] 的 `notifyListeners`
/// 翻译成一条条「本次广播的变更列表」。
///
/// 消费方 `ref.listen(movieSubscriptionEventsProvider, ...)` 后对自己的列表做
/// **就地补丁**（移除 / 改字段），语义与 Provider 侧监听方一致——不要
/// `invalidate` 触发整页重拉。
///
/// 单条 `reportChange` 与批量 `reportBatch` 在这里被统一成列表形式（复用
/// notifier 自己的 `consumePendingChanges` 分派），下游不必再区分两条路径。

final class MovieSubscriptionEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MovieSubscriptionChange>>,
          List<MovieSubscriptionChange>,
          Stream<List<MovieSubscriptionChange>>
        >
    with
        $FutureModifier<List<MovieSubscriptionChange>>,
        $StreamProvider<List<MovieSubscriptionChange>> {
  /// 订阅变更事件流：把 [MovieSubscriptionChangeNotifier] 的 `notifyListeners`
  /// 翻译成一条条「本次广播的变更列表」。
  ///
  /// 消费方 `ref.listen(movieSubscriptionEventsProvider, ...)` 后对自己的列表做
  /// **就地补丁**（移除 / 改字段），语义与 Provider 侧监听方一致——不要
  /// `invalidate` 触发整页重拉。
  ///
  /// 单条 `reportChange` 与批量 `reportBatch` 在这里被统一成列表形式（复用
  /// notifier 自己的 `consumePendingChanges` 分派），下游不必再区分两条路径。
  MovieSubscriptionEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'movieSubscriptionEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movieSubscriptionEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<MovieSubscriptionChange>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MovieSubscriptionChange>> create(Ref ref) {
    return movieSubscriptionEvents(ref);
  }
}

String _$movieSubscriptionEventsHash() =>
    r'4fce409ea30347ff968decfee2b0028fff0f79f8';

/// 跨页合集类型（单体/合集）变更广播源的桥——与
/// [movieSubscriptionBroadcasterProvider] 同一范式：两侧共用同一实例，
/// 保持「单一广播源」。原生装配，组合根不再 override。

@ProviderFor(collectionTypeBroadcaster)
final collectionTypeBroadcasterProvider = CollectionTypeBroadcasterProvider._();

/// 跨页合集类型（单体/合集）变更广播源的桥——与
/// [movieSubscriptionBroadcasterProvider] 同一范式：两侧共用同一实例，
/// 保持「单一广播源」。原生装配，组合根不再 override。

final class CollectionTypeBroadcasterProvider
    extends
        $FunctionalProvider<
          MovieCollectionTypeChangeNotifier,
          MovieCollectionTypeChangeNotifier,
          MovieCollectionTypeChangeNotifier
        >
    with $Provider<MovieCollectionTypeChangeNotifier> {
  /// 跨页合集类型（单体/合集）变更广播源的桥——与
  /// [movieSubscriptionBroadcasterProvider] 同一范式：两侧共用同一实例，
  /// 保持「单一广播源」。原生装配，组合根不再 override。
  CollectionTypeBroadcasterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'collectionTypeBroadcasterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$collectionTypeBroadcasterHash();

  @$internal
  @override
  $ProviderElement<MovieCollectionTypeChangeNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MovieCollectionTypeChangeNotifier create(Ref ref) {
    return collectionTypeBroadcaster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MovieCollectionTypeChangeNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MovieCollectionTypeChangeNotifier>(
        value,
      ),
    );
  }
}

String _$collectionTypeBroadcasterHash() =>
    r'e1ecae7d05b9c1554b6ea735d47a982cfebf1f75';

/// 合集类型变更事件流：把 `notifyListeners` 翻译成一条条 [MovieCollectionTypeChange]。
///
/// 消费方 `ref.listen(movieCollectionTypeEventsProvider, ...)` 后做就地补丁，
/// 语义与 Provider 侧监听方一致，不 invalidate 整页重拉。

@ProviderFor(movieCollectionTypeEvents)
final movieCollectionTypeEventsProvider = MovieCollectionTypeEventsProvider._();

/// 合集类型变更事件流：把 `notifyListeners` 翻译成一条条 [MovieCollectionTypeChange]。
///
/// 消费方 `ref.listen(movieCollectionTypeEventsProvider, ...)` 后做就地补丁，
/// 语义与 Provider 侧监听方一致，不 invalidate 整页重拉。

final class MovieCollectionTypeEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MovieCollectionTypeChange>,
          MovieCollectionTypeChange,
          Stream<MovieCollectionTypeChange>
        >
    with
        $FutureModifier<MovieCollectionTypeChange>,
        $StreamProvider<MovieCollectionTypeChange> {
  /// 合集类型变更事件流：把 `notifyListeners` 翻译成一条条 [MovieCollectionTypeChange]。
  ///
  /// 消费方 `ref.listen(movieCollectionTypeEventsProvider, ...)` 后做就地补丁，
  /// 语义与 Provider 侧监听方一致，不 invalidate 整页重拉。
  MovieCollectionTypeEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'movieCollectionTypeEventsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movieCollectionTypeEventsHash();

  @$internal
  @override
  $StreamProviderElement<MovieCollectionTypeChange> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MovieCollectionTypeChange> create(Ref ref) {
    return movieCollectionTypeEvents(ref);
  }
}

String _$movieCollectionTypeEventsHash() =>
    r'd57ec78682ed37bebc5e98ec4a755bbdd25f14bf';
