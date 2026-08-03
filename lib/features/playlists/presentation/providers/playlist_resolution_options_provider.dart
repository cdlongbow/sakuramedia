import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlist_resolution_options_state.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';

part 'playlist_resolution_options_provider.g.dart';

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
@riverpod
class PlaylistResolutionOptions extends _$PlaylistResolutionOptions {
  @override
  PlaylistResolutionOptionsState build(int playlistId) {
    return const PlaylistResolutionOptionsState();
  }

  /// 未加载过则触发一次加载；已加载或正在加载则原地返回。
  Future<void> ensureLoaded() async {
    if (state.hasLoaded || state.isLoading) return;
    await _load();
  }

  /// 已加载过再强制重取（如下拉刷新）。未加载过 no-op。
  Future<void> refresh() async {
    if (!state.hasLoaded || state.isLoading) return;
    await _load();
  }

  /// 用户点「重试」按钮时无条件重取。
  Future<void> retry() async {
    if (state.isLoading) return;
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final options = await ref
          .read(playlistsApiProvider)
          .getPlaylistResolutions(playlistId: playlistId);
      state = state.copyWith(
        options: options,
        hasLoaded: true,
        isLoading: false,
      );
    } catch (_) {
      // 失败不清空已有 options：让 UI 可以继续展示上一批 chips + 行内错误提示。
      state = state.copyWith(isLoading: false, errorMessage: '分辨率加载失败');
    }
  }
}
