import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/search/data/catalog_search_stream_stats.dart';

const Object _unsetSeriesImportValue = Object();

@immutable
class SeriesImportState {
  const SeriesImportState({
    this.isRunning = false,
    this.isCompleted = false,
    this.hasFailed = false,
    this.hasNewMovies = false,
    this.statusMessage = '准备就绪',
    this.current,
    this.total,
    this.stats,
    this.errorMessage,
  });

  final bool isRunning;
  final bool isCompleted;
  final bool hasFailed;
  final bool hasNewMovies;
  final String statusMessage;
  final int? current;
  final int? total;
  final CatalogSearchStreamStats? stats;
  final String? errorMessage;

  bool get canDismiss => isCompleted || hasFailed;

  double? get progress {
    final currentValue = current;
    final totalValue = total;
    if (currentValue == null || totalValue == null || totalValue == 0) {
      return null;
    }
    return (currentValue / totalValue).clamp(0.0, 1.0);
  }

  SeriesImportState copyWith({
    bool? isRunning,
    bool? isCompleted,
    bool? hasFailed,
    bool? hasNewMovies,
    String? statusMessage,
    Object? current = _unsetSeriesImportValue,
    Object? total = _unsetSeriesImportValue,
    Object? stats = _unsetSeriesImportValue,
    Object? errorMessage = _unsetSeriesImportValue,
  }) {
    return SeriesImportState(
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      hasFailed: hasFailed ?? this.hasFailed,
      hasNewMovies: hasNewMovies ?? this.hasNewMovies,
      statusMessage: statusMessage ?? this.statusMessage,
      current:
          identical(current, _unsetSeriesImportValue)
              ? this.current
              : current as int?,
      total:
          identical(total, _unsetSeriesImportValue)
              ? this.total
              : total as int?,
      stats:
          identical(stats, _unsetSeriesImportValue)
              ? this.stats
              : stats as CatalogSearchStreamStats?,
      errorMessage:
          identical(errorMessage, _unsetSeriesImportValue)
              ? this.errorMessage
              : errorMessage as String?,
    );
  }
}
