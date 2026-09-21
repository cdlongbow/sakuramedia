import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/features/image_search/presentation/actions/image_search_launcher.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_playback_launcher.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_dialog.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';

/// 列表入口打开详情检查器（评论 / 磁力 / 缩略图）前，先取默认媒体。
///
/// 列表数据只有番号，没有 mediaId；不取详情的话缩略图页签会是空态。
/// 取详情失败返回 null——弹窗仍可打开，评论 / 磁力不受影响。
///
/// 不走 movieDetailProvider：它是 keepAlive 的页面级 provider，列表入口
/// 不该留下常驻实例，这里直接走 API。
Future<MovieMediaItemDto?> fetchDefaultInspectorMedia(
  BuildContext context, {
  required String movieNumber,
}) async {
  try {
    final detail = await ProviderScope.containerOf(context, listen: false)
        .read(moviesApiProvider)
        .getMovieDetail(movieNumber: movieNumber);
    return detail.mediaItems.isEmpty ? null : detail.mediaItems.first;
  } catch (_) {
    return null;
  }
}

/// 打开影片详情检查器：移动端底部抽屉 / 桌面对话框，与详情页保持同一形态。
void showMovieInspector(
  BuildContext context, {
  required String movieNumber,
  MovieMediaItemDto? selectedMedia,
}) {
  if (AppPlatformScope.maybeOf(context) == AppPlatform.mobile) {
    unawaited(
      showMobileMovieDetailInspectorBottomSheet(
        context: context,
        movieNumber: movieNumber,
        selectedMedia: selectedMedia,
        onSearchSimilar: (thumbnail, imageUrl, fileName) =>
            launchImageSearchFromUrl(
              context,
              imageUrl: imageUrl,
              routePath: mobileImageSearchPath,
              fileName: fileName,
              currentMovieNumber: movieNumber,
            ),
        onPlay: (thumbnail) => launchMoviePlayback(
          context,
          movieNumber: movieNumber,
          mediaId: thumbnail.mediaId > 0
              ? thumbnail.mediaId
              : selectedMedia?.mediaId,
          positionSeconds: thumbnail.offsetSeconds,
        ),
      ),
    );
    return;
  }
  unawaited(
    showMovieDetailInspectorDialog(
      context: context,
      movieNumber: movieNumber,
      selectedMedia: selectedMedia,
    ),
  );
}
