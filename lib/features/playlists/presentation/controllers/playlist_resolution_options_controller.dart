import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';

/// 播放列表内分辨率档位的加载状态。
///
/// 单独抽成 `ChangeNotifier` 是为了让**桌面就地浮层**与**移动底部抽屉**共用同
/// 一份可订阅的状态：抽屉是 modal route，State 快照式挂载不会被父级 `setState`
/// 唤醒，如果把这些字段散在页面 State 里，「弹开抽屉之后重试拿数据」的路径
/// 就不生效（重试后父级更新，抽屉那份完全看不到）。用 `ChangeNotifier` 让两
/// 端 UI 都通过 `AnimatedBuilder`/`ListenableBuilder` 订阅同一份状态即可。
///
/// 首次加载**惰性触发**：只在筛选面板首次打开时调 [ensureLoaded]。刷新页面时
/// 若已经加载过则调 [refresh]（`force: true`），未加载过就不打扰。
class PlaylistResolutionOptionsController extends ChangeNotifier {
  PlaylistResolutionOptionsController({
    required PlaylistsApi playlistsApi,
    required this.playlistId,
  }) : _playlistsApi = playlistsApi;

  /// 测试用：直接种下当前状态，不打网络。
  ///
  /// 生产代码请用默认构造 + [ensureLoaded] / [refresh] / [retry]。
  @visibleForTesting
  PlaylistResolutionOptionsController.seeded({
    required PlaylistsApi playlistsApi,
    required this.playlistId,
    List<PlaylistResolutionOptionDto> options =
        const <PlaylistResolutionOptionDto>[],
    bool isLoading = false,
    String? errorMessage,
    bool hasLoaded = false,
  }) : _playlistsApi = playlistsApi,
       _options = options,
       _isLoading = isLoading,
       _errorMessage = errorMessage,
       _hasLoaded = hasLoaded;

  final PlaylistsApi _playlistsApi;
  final int playlistId;

  List<PlaylistResolutionOptionDto> _options =
      const <PlaylistResolutionOptionDto>[];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoaded = false;
  bool _isDisposed = false;

  List<PlaylistResolutionOptionDto> get options => _options;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 是否至少完成过一次成功加载。用于「刷新时是否顺带重取」的判断——
  /// 从未加载过（用户没点开筛选面板）就不打扰。
  bool get hasLoaded => _hasLoaded;

  /// 未加载过则触发一次加载；已加载或正在加载则原地返回。
  Future<void> ensureLoaded() async {
    if (_hasLoaded || _isLoading) {
      return;
    }
    await _load();
  }

  /// 已经加载过再强制重取（如下拉刷新）。未加载过 no-op。
  Future<void> refresh() async {
    if (!_hasLoaded || _isLoading) {
      return;
    }
    await _load();
  }

  /// 用户点「重试」按钮时无条件重取。
  Future<void> retry() async {
    if (_isLoading) {
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final result = await _playlistsApi.getPlaylistResolutions(
        playlistId: playlistId,
      );
      if (_isDisposed) {
        return;
      }
      _options = result;
      _hasLoaded = true;
    } catch (_) {
      if (_isDisposed) {
        return;
      }
      // 失败不清空已有 _options：让 UI 可以继续展示上一批 chips + 行内错误提示。
      _errorMessage = '分辨率加载失败';
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
