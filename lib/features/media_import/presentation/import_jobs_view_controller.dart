import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:sakuramedia/features/media_import/data/import_job_dto.dart';

/// 导入作业列表页所需的统一控制器接口。
///
/// JAV `MediaImportController` 与 PornBox `VideoImportController` 各自实现本接口，
/// 让媒体导入页的标签内容用同一套渲染逻辑驱动两类导入作业。
/// 失败源文件的删除/重命名是 JAV 专属能力，不在本接口内
/// （见 `MediaImportController.deleteFailedFile` / `renameFailedFile`）。
abstract class ImportJobsViewController implements Listenable {
  List<ImportJobCardData> get jobs;
  bool get isInitialLoading;
  bool get isLoadingMore;
  String? get initialError;
  String? get loadMoreError;

  TaskRunDto? taskRunFor(int? taskRunId);
  ImportJobCardDetailData? detailFor(int jobId);
  bool isDetailLoading(int jobId);
  String? detailError(int jobId);

  Future<void> loadFirstPage();
  Future<void> refresh();
  Future<void> loadMore();
  Future<void> ensureDetail(int jobId, {bool force});
  Future<String?> retryFailedFiles(int jobId, {List<String>? files});

  /// 按原参数（来源 + 媒体库 + 导入方式）**新建**一个导入作业。
  ///
  /// 用于任务级失败（`kind=job`）作业——它们没有可逐个重导的失败文件，只能整体
  /// 重跑。成功返回 `null`，失败返回中文错误信息。
  Future<String?> reimportJob(int jobId);
}
