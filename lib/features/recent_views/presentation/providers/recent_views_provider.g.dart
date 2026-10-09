// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_views_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 最近浏览列表（最新在前，最多后端保留上限条）。
///
/// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
/// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。

@ProviderFor(RecentViews)
final recentViewsProvider = RecentViewsFamily._();

/// 最近浏览列表（最新在前，最多后端保留上限条）。
///
/// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
/// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。
final class RecentViewsProvider
    extends $AsyncNotifierProvider<RecentViews, List<RecentViewEntryDto>> {
  /// 最近浏览列表（最新在前，最多后端保留上限条）。
  ///
  /// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
  /// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。
  RecentViewsProvider._({
    required RecentViewsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recentViewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recentViewsHash();

  @override
  String toString() {
    return r'recentViewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RecentViews create() => RecentViews();

  @override
  bool operator ==(Object other) {
    return other is RecentViewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recentViewsHash() => r'ce5fdc4a9a68ec65046aca9ff2728b24b5cff98b';

/// 最近浏览列表（最新在前，最多后端保留上限条）。
///
/// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
/// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。

final class RecentViewsFamily extends $Family
    with
        $ClassFamilyOverride<
          RecentViews,
          AsyncValue<List<RecentViewEntryDto>>,
          List<RecentViewEntryDto>,
          FutureOr<List<RecentViewEntryDto>>,
          int
        > {
  RecentViewsFamily._()
    : super(
        retry: null,
        name: r'recentViewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 最近浏览列表（最新在前，最多后端保留上限条）。
  ///
  /// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
  /// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。

  RecentViewsProvider call(int limit) =>
      RecentViewsProvider._(argument: limit, from: this);

  @override
  String toString() => r'recentViewsProvider';
}

/// 最近浏览列表（最新在前，最多后端保留上限条）。
///
/// - 按 `limit` 分实例：概览区块看 `limit: 20`，更多页看 `limit: 200`。
/// - 订阅变更广播到达时就地补丁订阅心状态，不整页重拉（浏览历史不因订阅状态变化而增删）。

abstract class _$RecentViews extends $AsyncNotifier<List<RecentViewEntryDto>> {
  late final _$args = ref.$arg as int;
  int get limit => _$args;

  FutureOr<List<RecentViewEntryDto>> build(int limit);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<RecentViewEntryDto>>,
              List<RecentViewEntryDto>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<RecentViewEntryDto>>,
                List<RecentViewEntryDto>
              >,
              AsyncValue<List<RecentViewEntryDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
