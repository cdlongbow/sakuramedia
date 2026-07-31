import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/image_search/presentation/desktop_image_search_launcher.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_desktop_dialog.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_panel.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_preview_overlay.dart';

Future<void> showMovieDetailInspectorDialog({
  required BuildContext context,
  required String movieNumber,
  required MovieMediaItemDto? selectedMedia,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final container = ProviderScope.containerOf(dialogContext, listen: false);
      final moviesApi = container.read(moviesApiProvider);
      final downloadsApi = container.read(downloadsApiProvider);
      return AppDesktopDialog(
        dialogKey: const Key('movie-detail-inspector-dialog'),
        contentKey: const Key('movie-detail-inspector-dialog-content'),
        width: dialogContext.appComponentTokens.movieDetailDialogWidth,
        height: dialogContext.appComponentTokens.movieDetailDialogMinHeight,
        child: MovieDetailInspectorPanel(
          movieNumber: movieNumber,
          selectedMedia: selectedMedia,
          fetchMovieReviews: moviesApi.getMovieReviews,
          fetchMediaThumbnails: moviesApi.getMediaThumbnails,
          searchCandidates: downloadsApi.searchCandidates,
          createDownloadRequest: downloadsApi.createDownloadRequest,
          onClose: () => Navigator.of(dialogContext).pop(),
          showCloseButton: false,
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
              context.pushDesktopMoviePlayer(
                movieNumber: movieNumber,
                fallbackPath: buildDesktopMovieDetailRoutePath(movieNumber),
                mediaId: thumbnail.mediaId > 0 ? thumbnail.mediaId : null,
                positionSeconds: thumbnail.offsetSeconds,
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
    builder: (sheetContext) {
      final container = ProviderScope.containerOf(sheetContext, listen: false);
      final moviesApi = container.read(moviesApiProvider);
      final downloadsApi = container.read(downloadsApiProvider);
      return MovieDetailInspectorPanel(
        movieNumber: movieNumber,
        selectedMedia: selectedMedia,
        fetchMovieReviews: moviesApi.getMovieReviews,
        fetchMediaThumbnails: moviesApi.getMediaThumbnails,
        searchCandidates: downloadsApi.searchCandidates,
        createDownloadRequest: downloadsApi.createDownloadRequest,
        onClose: () => Navigator.of(sheetContext).pop(),
        thumbnailPreviewPresentation: MoviePlotPreviewPresentation.bottomDrawer,
        onSearchSimilar: onSearchSimilar,
        onPlay: onPlay,
      );
    },
  );
}
