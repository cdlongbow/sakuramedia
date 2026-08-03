import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';

/// 播放列表内分辨率档位状态（含惰性加载标志）。
///
/// [hasLoaded] 表「是否至少成功加载过一次」：用于「刷新时是否顺带重取」的判断
/// ——从未加载过（用户没点开筛选面板）就不打扰。
///
/// AsyncValue 表达不了 `hasLoaded + isLoading + errorMessage + options` 四态
/// 复合，故用同步 Notifier + 显式字段。
@immutable
class PlaylistResolutionOptionsState {
  const PlaylistResolutionOptionsState({
    this.options = const <PlaylistResolutionOptionDto>[],
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false,
  });

  final List<PlaylistResolutionOptionDto> options;
  final bool isLoading;
  final String? errorMessage;
  final bool hasLoaded;

  PlaylistResolutionOptionsState copyWith({
    List<PlaylistResolutionOptionDto>? options,
    bool? isLoading,
    Object? errorMessage = _kSentinel,
    bool? hasLoaded,
  }) {
    return PlaylistResolutionOptionsState(
      options: options ?? this.options,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _kSentinel)
          ? this.errorMessage
          : errorMessage as String?,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

const Object _kSentinel = Object();
