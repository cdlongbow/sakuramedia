import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/data/dto/series_import/movie_search_stream_update.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/series_import_state.dart';

part 'series_import_provider.g.dart';

/// 每次系列导入弹窗独占一个 autoDispose 流状态机。
@riverpod
class SeriesImport extends _$SeriesImport {
  StreamSubscription<MovieSearchStreamUpdate>? _subscription;
  int _requestVersion = 0;
  bool _isDisposed = false;

  @override
  SeriesImportState build(int seriesId) {
    ref.onDispose(() {
      _isDisposed = true;
      _requestVersion += 1;
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return const SeriesImportState();
  }

  Future<void> startImport() async {
    if (state.isRunning) {
      return;
    }
    final requestVersion = ++_requestVersion;
    state = state.copyWith(
      isRunning: true,
      isCompleted: false,
      hasFailed: false,
      hasNewMovies: false,
      statusMessage: '正在连接服务器...',
      current: null,
      total: null,
      stats: null,
      errorMessage: null,
    );

    _subscription = ref
        .read(moviesApiProvider)
        .importSeriesMoviesStream(seriesId: seriesId)
        .listen(
          (update) => _applyUpdate(update, requestVersion),
          onError: (Object error, StackTrace _) {
            if (!_isCurrent(requestVersion)) {
              return;
            }
            state = state.copyWith(
              isRunning: false,
              hasFailed: true,
              errorMessage: apiErrorMessage(error, fallback: '导入失败，请稍后重试'),
            );
          },
          onDone: () {
            if (!_isCurrent(requestVersion)) {
              return;
            }
            if (state.isRunning && !state.isCompleted) {
              state = state.copyWith(
                isRunning: false,
                hasFailed: true,
                errorMessage: '连接意外断开，请重试',
              );
            }
          },
          cancelOnError: false,
        );
  }

  void _applyUpdate(MovieSearchStreamUpdate update, int requestVersion) {
    if (!_isCurrent(requestVersion)) {
      return;
    }
    var next = state.copyWith(
      statusMessage: update.message,
      current: update.current ?? state.current,
      total: update.total ?? state.total,
      stats: update.stats ?? state.stats,
    );
    if (update.isComplete) {
      final stats = update.stats;
      next = next.copyWith(
        isRunning: false,
        isCompleted: true,
        hasNewMovies: stats != null && stats.createdCount > 0,
        hasFailed: update.success == false,
        errorMessage:
            update.success == false
                ? _resolveFailureMessage(update.reason)
                : null,
      );
    }
    state = next;
  }

  String _resolveFailureMessage(String? reason) {
    return switch (reason) {
      'series_not_found' => '库内系列不存在',
      'javdb_series_not_found' => '未能在 JAVDB 找到匹配的系列，请确认系列名称',
      _ => '导入失败，请稍后重试',
    };
  }

  Future<void> cancel() async {
    final requestVersion = ++_requestVersion;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    if (!_isDisposed && requestVersion == _requestVersion && state.isRunning) {
      state = state.copyWith(isRunning: false);
    }
  }

  bool _isCurrent(int requestVersion) =>
      !_isDisposed && requestVersion == _requestVersion;
}
