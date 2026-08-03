// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clips_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 我的切片首页分页列表（排序筛选驱动）。
///
/// 视觉策略：`FilterReloadStrategy.preserveList`——切排序时**保留旧列表**
/// 直到新数据回来，与迁移前 `ClipsOverviewController.setSort → load()` 一致
/// （旧数据只在成功时被覆盖，失败时清空到 empty）。UI 侧当前无薄进度条，
/// 首屏空态才走整页 spinner。
///
/// autoDispose：离开页面即释放，对齐迁移前控制器随 State 生灭。
///
/// 迁移前对应：`ClipsOverviewController`（含 `_clips` / `_page` / `_total` 手写字段、
/// `removeClip` / `replaceClip` 广播补丁方法）。

@ProviderFor(ClipsOverview)
final clipsOverviewProvider = ClipsOverviewProvider._();

/// 我的切片首页分页列表（排序筛选驱动）。
///
/// 视觉策略：`FilterReloadStrategy.preserveList`——切排序时**保留旧列表**
/// 直到新数据回来，与迁移前 `ClipsOverviewController.setSort → load()` 一致
/// （旧数据只在成功时被覆盖，失败时清空到 empty）。UI 侧当前无薄进度条，
/// 首屏空态才走整页 spinner。
///
/// autoDispose：离开页面即释放，对齐迁移前控制器随 State 生灭。
///
/// 迁移前对应：`ClipsOverviewController`（含 `_clips` / `_page` / `_total` 手写字段、
/// `removeClip` / `replaceClip` 广播补丁方法）。
final class ClipsOverviewProvider
    extends $AsyncNotifierProvider<ClipsOverview, ClipsOverviewState> {
  /// 我的切片首页分页列表（排序筛选驱动）。
  ///
  /// 视觉策略：`FilterReloadStrategy.preserveList`——切排序时**保留旧列表**
  /// 直到新数据回来，与迁移前 `ClipsOverviewController.setSort → load()` 一致
  /// （旧数据只在成功时被覆盖，失败时清空到 empty）。UI 侧当前无薄进度条，
  /// 首屏空态才走整页 spinner。
  ///
  /// autoDispose：离开页面即释放，对齐迁移前控制器随 State 生灭。
  ///
  /// 迁移前对应：`ClipsOverviewController`（含 `_clips` / `_page` / `_total` 手写字段、
  /// `removeClip` / `replaceClip` 广播补丁方法）。
  ClipsOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: kNoAsyncNotifierRetry,
        name: r'clipsOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipsOverviewHash();

  @$internal
  @override
  ClipsOverview create() => ClipsOverview();
}

String _$clipsOverviewHash() => r'930ae41c2a5830153d575ba750251e14585249a3';

/// 我的切片首页分页列表（排序筛选驱动）。
///
/// 视觉策略：`FilterReloadStrategy.preserveList`——切排序时**保留旧列表**
/// 直到新数据回来，与迁移前 `ClipsOverviewController.setSort → load()` 一致
/// （旧数据只在成功时被覆盖，失败时清空到 empty）。UI 侧当前无薄进度条，
/// 首屏空态才走整页 spinner。
///
/// autoDispose：离开页面即释放，对齐迁移前控制器随 State 生灭。
///
/// 迁移前对应：`ClipsOverviewController`（含 `_clips` / `_page` / `_total` 手写字段、
/// `removeClip` / `replaceClip` 广播补丁方法）。

abstract class _$ClipsOverview extends $AsyncNotifier<ClipsOverviewState> {
  FutureOr<ClipsOverviewState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ClipsOverviewState>, ClipsOverviewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ClipsOverviewState>, ClipsOverviewState>,
              AsyncValue<ClipsOverviewState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
