import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/image_search/presentation/actions/image_search_launcher.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_playback_launcher.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_panel.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_preview_overlay.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_desktop_dialog.dart';

Future<void> showMovieDetailInspectorDialog({
  required BuildContext context,
  required String movieNumber,
  required MovieMediaItemDto? selectedMedia,
  required MovieDetailInspectorPane pane,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AppDesktopDialog(
        dialogKey: const Key('movie-detail-inspector-dialog'),
        contentKey: const Key('movie-detail-inspector-dialog-content'),
        width: dialogContext.appComponentTokens.movieDetailDialogWidth,
        height: dialogContext.appComponentTokens.movieDetailDialogMinHeight,
        child: MovieDetailInspectorPanel(
          movieNumber: movieNumber,
          selectedMedia: selectedMedia,
          pane: pane,
          onSearchSimilar: (thumbnail, imageUrl, fileName) async {
            if (!context.mounted || !dialogContext.mounted) {
              return;
            }
            final navigator = Navigator.of(dialogContext);
            if (navigator.canPop()) {
              navigator.pop();
            }
            Future<void>.microtask(() async {
              if (!context.mounted) {
                return;
              }
              await launchDesktopImageSearchFromUrl(
                context,
                imageUrl: imageUrl,
                fallbackPath: buildDesktopMovieDetailRoutePath(movieNumber),
                fileName: fileName,
              );
            });
          },
          onPlay: (thumbnail) {
            if (!context.mounted || !dialogContext.mounted) {
              return;
            }
            final navigator = Navigator.of(dialogContext);
            if (navigator.canPop()) {
              navigator.pop();
            }
            Future<void>.microtask(() {
              if (!context.mounted) {
                return;
              }
              unawaited(
                launchMoviePlayback(
                  context,
                  movieNumber: movieNumber,
                  mediaId: thumbnail.mediaId > 0 ? thumbnail.mediaId : null,
                  positionSeconds: thumbnail.offsetSeconds,
                ),
              );
            });
          },
        ),
      );
    },
  );
}

Future<void> showMobileMovieDetailInspectorBottomSheet({
  required BuildContext context,
  required String movieNumber,
  required MovieMediaItemDto? selectedMedia,
  required MovieDetailInspectorPane pane,
  required Future<void> Function(
    MovieMediaThumbnailDto thumbnail,
    String imageUrl,
    String fileName,
  )
  onSearchSimilar,
  required void Function(MovieMediaThumbnailDto thumbnail) onPlay,
}) {
  return showAppBottomDrawer<void>(
    context: context,
    drawerKey: const Key('movie-detail-inspector-bottom-sheet'),
    maxHeightFactor: 0.7,
    ignoreTopSafeArea: true,
    builder: (_) {
      return MovieDetailInspectorPanel(
        movieNumber: movieNumber,
        selectedMedia: selectedMedia,
        pane: pane,
        thumbnailPreviewPresentation: MoviePlotPreviewPresentation.bottomDrawer,
        onSearchSimilar: onSearchSimilar,
        onPlay: onPlay,
      );
    },
  );
}

/// 磁力搜索的独立入口（订阅列表等只有番号的场景）：自适应壳 + 同一个面板。
///
/// 内容、标题与 KeepAliveLink 收编都由 [MovieDetailInspectorPanel] 承担，
/// 这里只负责选壳（桌面弹窗 / 移动底部抽屉）。
Future<void> showMovieMagnetSearchDialog({
  required BuildContext context,
  required String movieNumber,
}) {
  return showAppAdaptiveModal<void>(
    context: context,
    modalKey: const Key('movie-magnet-search-dialog'),
    desktopWidth: context.appComponentTokens.movieDetailDialogWidth,
    desktopHeight: context.appComponentTokens.movieDetailDialogMinHeight,
    builder: (_) => MovieDetailInspectorPanel(
      movieNumber: movieNumber,
      selectedMedia: null,
      pane: MovieDetailInspectorPane.magnetSearch,
    ),
  );
}
