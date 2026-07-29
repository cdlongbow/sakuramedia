import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/activity/data/resource_task_action_result_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_menu.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/detail/movie_detail_controller.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_subscription_change_notifier.dart';

class MovieDetailRemoteActionSpec {
  const MovieDetailRemoteActionSpec({
    required this.request,
    required this.successMessage,
    required this.failureMessage,
    this.resetPreview = false,
  });

  // 返回 null 表示排队型动作（202）：只提示已提交，不回填影片详情。
  final Future<MovieDetailDto?> Function(MoviesApi api) request;
  final String successMessage;
  final String failureMessage;
  final bool resetPreview;
}

class MovieDetailApplyResult {
  const MovieDetailApplyResult({
    required this.selectedMediaId,
    this.isSubscribedOverride,
    this.isCollectionOverride,
  });

  final int? selectedMediaId;
  final bool? isSubscribedOverride;
  final bool? isCollectionOverride;
}

class MovieSubscriptionNotifierBinding {
  const MovieSubscriptionNotifierBinding({
    required this.notifier,
    required this.ownsNotifier,
  });

  final MovieSubscriptionChangeNotifier notifier;
  final bool ownsNotifier;
}

MovieSubscriptionNotifierBinding resolveMovieSubscriptionNotifier(
  BuildContext context,
) {
  try {
    return MovieSubscriptionNotifierBinding(
      notifier: context.read<MovieSubscriptionChangeNotifier>(),
      ownsNotifier: false,
    );
  } on ProviderNotFoundException {
    return MovieSubscriptionNotifierBinding(
      notifier: MovieSubscriptionChangeNotifier(),
      ownsNotifier: true,
    );
  }
}

/// 翻译 / 互动同步走统一 action（整数 movie id 寻址）；[movieId] 缺省 0 表示
/// 详情还没加载出 id（或老后端不下发），这两个动作会以失败 toast 兜底。
MovieDetailRemoteActionSpec? movieDetailRemoteActionSpecFor({
  required MovieDetailActionType action,
  required String movieNumber,
  int movieId = 0,
}) {
  switch (action) {
    // 本地动作:只开检查器,不发请求,由页面自行接管。
    case MovieDetailActionType.openInspector:
      return null;
    case MovieDetailActionType.toggleSubscription:
      return null;
    case MovieDetailActionType.refreshMetadata:
      return MovieDetailRemoteActionSpec(
        request: (api) => api.refreshMovieMetadata(movieNumber: movieNumber),
        successMessage: '影片元数据已刷新',
        failureMessage: '刷新影片元数据失败',
        resetPreview: true,
      );
    case MovieDetailActionType.recomputeHeat:
      return MovieDetailRemoteActionSpec(
        request: (api) => api.recomputeMovieHeat(movieNumber: movieNumber),
        successMessage: '影片热度已更新',
        failureMessage: '计算影片热度失败',
      );
    case MovieDetailActionType.syncInteraction:
      return MovieDetailRemoteActionSpec(
        request: (api) async {
          await api.syncMovieInteraction(movieId: _requireMovieId(movieId));
          return null;
        },
        successMessage: '互动数同步任务已提交，完成后刷新可见',
        failureMessage: '提交互动数同步失败',
      );
    case MovieDetailActionType.translateDescription:
      return MovieDetailRemoteActionSpec(
        request: (api) async {
          await api.translateMovieDescription(
            movieId: _requireMovieId(movieId),
          );
          return null;
        },
        successMessage: '翻译任务已提交，完成后刷新可见',
        failureMessage: '提交翻译任务失败',
      );
  }
}

int _requireMovieId(int movieId) {
  if (movieId <= 0) {
    // 详情响应没带 id（老后端）——让 catch 走 failureMessage 兜底，而不是
    // 拿 0 去打统一 action 端点。
    throw StateError('movie detail is missing an integer id');
  }
  return movieId;
}

Future<bool> executeMovieDetailRemoteAction({
  required BuildContext context,
  required MovieDetailActionType action,
  required String movieNumber,
  required bool isLocked,
  required MovieDetailController controller,
  required int? selectedMediaId,
  required void Function(MovieDetailActionType? action) onActiveActionChanged,
  required void Function(MovieDetailApplyResult result) onMovieApplied,
}) async {
  final spec = movieDetailRemoteActionSpecFor(
    action: action,
    movieNumber: movieNumber,
    movieId: controller.movie?.id ?? 0,
  );
  if (spec == null || isLocked) {
    return false;
  }

  onActiveActionChanged(action);
  try {
    final movie = await spec.request(context.read<MoviesApi>());
    if (!context.mounted) {
      return false;
    }
    if (movie != null) {
      final applyResult = applyReturnedMovieDetail(
        controller: controller,
        movie: movie,
        selectedMediaId: selectedMediaId,
        resetPreview: spec.resetPreview,
      );
      onMovieApplied(applyResult);
    }
    showToast(spec.successMessage);
    return true;
  } catch (error) {
    if (context.mounted) {
      showToast(
        isResourceTaskActionConflict(error)
            ? '已有相同操作在执行中，请稍后再试'
            : apiErrorMessage(error, fallback: spec.failureMessage),
      );
    }
    return false;
  } finally {
    onActiveActionChanged(null);
  }
}

MovieDetailApplyResult applyReturnedMovieDetail({
  required MovieDetailController controller,
  required MovieDetailDto movie,
  required int? selectedMediaId,
  required bool resetPreview,
}) {
  final resolvedSelectedMediaId =
      selectedMediaId != null &&
              movie.mediaItems.any((item) => item.mediaId == selectedMediaId)
          ? selectedMediaId
          : (movie.mediaItems.isNotEmpty
              ? movie.mediaItems.first.mediaId
              : null);
  controller.applyMovie(movie, resetPreview: resetPreview);
  return MovieDetailApplyResult(
    selectedMediaId: resolvedSelectedMediaId,
    isSubscribedOverride: null,
    isCollectionOverride: null,
  );
}
