import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:sakuramedia/features/media_import/data/import_job_dto.dart';
import 'package:sakuramedia/features/media_import/presentation/import_jobs_view_controller.dart';

const Object _unsetImportJobsField = Object();

/// JAV / PornBox 导入作业共用的不可变页面状态。
@immutable
class ImportJobsViewState<
  TJob extends ImportJobCardData,
  TDetail extends ImportJobCardDetailData
>
    implements ImportJobsViewData {
  ImportJobsViewState({
    List<TJob> jobs = const [],
    this.nextPage = 1,
    this.hasMore = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isReconciling = false,
    this.initialError,
    this.loadMoreError,
    Map<int, TDetail> details = const {},
    Set<int> detailLoading = const {},
    Map<int, String> detailErrors = const {},
    Map<int, TaskRunDto> taskRunsById = const {},
  }) : jobs = List<TJob>.unmodifiable(jobs),
       details = Map<int, TDetail>.unmodifiable(details),
       detailLoading = Set<int>.unmodifiable(detailLoading),
       detailErrors = Map<int, String>.unmodifiable(detailErrors),
       taskRunsById = Map<int, TaskRunDto>.unmodifiable(taskRunsById);

  @override
  final List<TJob> jobs;
  final int nextPage;
  final bool hasMore;
  @override
  final bool isInitialLoading;
  @override
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isReconciling;
  @override
  final String? initialError;
  @override
  final String? loadMoreError;
  final Map<int, TDetail> details;
  final Set<int> detailLoading;
  final Map<int, String> detailErrors;
  final Map<int, TaskRunDto> taskRunsById;

  bool get isEmpty => !isInitialLoading && initialError == null && jobs.isEmpty;

  @override
  TaskRunDto? taskRunFor(int? taskRunId) {
    return taskRunId == null ? null : taskRunsById[taskRunId];
  }

  @override
  TDetail? detailFor(int jobId) => details[jobId];

  @override
  bool isDetailLoading(int jobId) => detailLoading.contains(jobId);

  @override
  String? detailError(int jobId) => detailErrors[jobId];

  ImportJobsViewState<TJob, TDetail> copyWith({
    List<TJob>? jobs,
    int? nextPage,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isReconciling,
    Object? initialError = _unsetImportJobsField,
    Object? loadMoreError = _unsetImportJobsField,
    Map<int, TDetail>? details,
    Set<int>? detailLoading,
    Map<int, String>? detailErrors,
    Map<int, TaskRunDto>? taskRunsById,
  }) {
    return ImportJobsViewState<TJob, TDetail>(
      jobs: jobs ?? this.jobs,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isReconciling: isReconciling ?? this.isReconciling,
      initialError:
          identical(initialError, _unsetImportJobsField)
              ? this.initialError
              : initialError as String?,
      loadMoreError:
          identical(loadMoreError, _unsetImportJobsField)
              ? this.loadMoreError
              : loadMoreError as String?,
      details: details ?? this.details,
      detailLoading: detailLoading ?? this.detailLoading,
      detailErrors: detailErrors ?? this.detailErrors,
      taskRunsById: taskRunsById ?? this.taskRunsById,
    );
  }
}
