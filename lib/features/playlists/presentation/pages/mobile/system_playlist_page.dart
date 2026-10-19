import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/pages/mobile/playlist_detail_page.dart';
import 'package:sakuramedia/features/playlists/presentation/pages/shared/playlist_detail_content.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/system_playlist_provider.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';

/// 系统播放列表（收藏 / 最近播放）的移动端入口页。
class MobileSystemPlaylistPage extends ConsumerWidget {
  const MobileSystemPlaylistPage({super.key, required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(systemPlaylistProvider(kind));
    final playlist = async.value;

    if (async.isLoading && playlist == null) {
      return const PlaylistDetailLoadingContent();
    }

    if (playlist == null) {
      return AppEmptyState(
        icon: _emptyIcon,
        message: async.hasError
            ? apiErrorMessage(async.error!, fallback: '播放列表暂时无法加载，请稍后重试')
            : kind == PlaylistKind.favorites
            ? '收藏列表尚未初始化'
            : '还没有观看记录',
        onRetry: async.hasError
            ? () => ref.invalidate(systemPlaylistProvider(kind))
            : null,
      );
    }

    return MobilePlaylistDetailPage(playlistId: playlist.id);
  }

  IconData get _emptyIcon => kind == PlaylistKind.favorites
      ? Icons.favorite_border_rounded
      : Icons.play_circle_outline_rounded;
}
