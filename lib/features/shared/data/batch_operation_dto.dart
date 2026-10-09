import 'package:sakuramedia/core/json/json_parse.dart';

/// 后端批量操作任务的操作类型；`wireValue` 与后端 `BatchOperationType` 枚举一致。
enum BatchOperationType {
  mediaDelete('media_delete'),
  clipDelete('clip_delete'),
  mediaPointDelete('media_point_delete'),
  videoDelete('video_delete'),
  clipCollectionAdd('clip_collection_add'),
  clipCollectionRemove('clip_collection_remove'),
  momentCollectionAdd('moment_collection_add'),
  momentCollectionRemove('moment_collection_remove'),
  videoCollectionAdd('video_collection_add'),
  videoCollectionRemove('video_collection_remove'),
  downloadTaskDelete('download_task_delete');

  const BatchOperationType(this.wireValue);

  final String wireValue;
}

/// `POST /batch-operations` 的受理结果：任务已进入后端队列。
class BatchOperationAcceptedDto {
  const BatchOperationAcceptedDto({
    required this.taskRunId,
    required this.taskKey,
    required this.state,
  });

  final int taskRunId;
  final String taskKey;
  final String state;

  factory BatchOperationAcceptedDto.fromJson(Map<String, dynamic> json) {
    return BatchOperationAcceptedDto(
      taskRunId: asInt(json['task_run_id']),
      taskKey: json['task_key'] as String? ?? '',
      state: json['state'] as String? ?? '',
    );
  }
}
