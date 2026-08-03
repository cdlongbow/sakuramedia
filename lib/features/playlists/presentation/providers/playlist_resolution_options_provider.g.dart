// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_resolution_options_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 播放列表内分辨率档位（带命中数）。
///
/// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
/// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
/// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
///
/// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
/// 详情页整体走开也会一并释放。
///
/// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
/// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。

@ProviderFor(PlaylistResolutionOptions)
final playlistResolutionOptionsProvider = PlaylistResolutionOptionsFamily._();

/// 播放列表内分辨率档位（带命中数）。
///
/// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
/// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
/// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
///
/// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
/// 详情页整体走开也会一并释放。
///
/// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
/// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。
final class PlaylistResolutionOptionsProvider
    extends
        $NotifierProvider<
          PlaylistResolutionOptions,
          PlaylistResolutionOptionsState
        > {
  /// 播放列表内分辨率档位（带命中数）。
  ///
  /// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
  /// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
  /// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
  ///
  /// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
  /// 详情页整体走开也会一并释放。
  ///
  /// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
  /// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。
  PlaylistResolutionOptionsProvider._({
    required PlaylistResolutionOptionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'playlistResolutionOptionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playlistResolutionOptionsHash();

  @override
  String toString() {
    return r'playlistResolutionOptionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlaylistResolutionOptions create() => PlaylistResolutionOptions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaylistResolutionOptionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaylistResolutionOptionsState>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistResolutionOptionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playlistResolutionOptionsHash() =>
    r'5411c21edd807aed9f042e86a08f9274ba4bc478';

/// 播放列表内分辨率档位（带命中数）。
///
/// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
/// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
/// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
///
/// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
/// 详情页整体走开也会一并释放。
///
/// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
/// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。

final class PlaylistResolutionOptionsFamily extends $Family
    with
        $ClassFamilyOverride<
          PlaylistResolutionOptions,
          PlaylistResolutionOptionsState,
          PlaylistResolutionOptionsState,
          PlaylistResolutionOptionsState,
          int
        > {
  PlaylistResolutionOptionsFamily._()
    : super(
        retry: null,
        name: r'playlistResolutionOptionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 播放列表内分辨率档位（带命中数）。
  ///
  /// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
  /// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
  /// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
  ///
  /// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
  /// 详情页整体走开也会一并释放。
  ///
  /// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
  /// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。

  PlaylistResolutionOptionsProvider call(int playlistId) =>
      PlaylistResolutionOptionsProvider._(argument: playlistId, from: this);

  @override
  String toString() => r'playlistResolutionOptionsProvider';
}

/// 播放列表内分辨率档位（带命中数）。
///
/// **惰性加载**：`build()` 只返回空 state，不打网络——真实加载由 UI 首次打开
/// 筛选面板/抽屉时调 [ensureLoaded] 触发。这与原
/// `PlaylistResolutionOptionsController` 的「面板首次 watch 才 build」语义一致。
///
/// autoDispose family(playlistId)：面板关闭后自动释放，重开自动重取；
/// 详情页整体走开也会一并释放。
///
/// state 复合语义（[hasLoaded] + [isLoading] + [errorMessage] + [options] 四态）
/// AsyncValue 表达不了，故用同步 [Notifier] + [PlaylistResolutionOptionsState]。

abstract class _$PlaylistResolutionOptions
    extends $Notifier<PlaylistResolutionOptionsState> {
  late final _$args = ref.$arg as int;
  int get playlistId => _$args;

  PlaylistResolutionOptionsState build(int playlistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              PlaylistResolutionOptionsState,
              PlaylistResolutionOptionsState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                PlaylistResolutionOptionsState,
                PlaylistResolutionOptionsState
              >,
              PlaylistResolutionOptionsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
