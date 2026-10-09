import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/shared/data/batch_operation_dto.dart';
import 'package:sakuramedia/features/shared/presentation/providers/batch_operation_submission_provider.dart';
import 'package:sakuramedia/features/shared/presentation/providers/batch_operations_api_provider.dart';

const Map<BatchOperationType, String> _operationLabels = {
  BatchOperationType.mediaDelete: '批量删除媒体',
  BatchOperationType.clipDelete: '批量删除切片',
  BatchOperationType.mediaPointDelete: '批量删除时刻',
  BatchOperationType.videoDelete: '批量删除视频',
  BatchOperationType.clipCollectionAdd: '批量加入切片合集',
  BatchOperationType.clipCollectionRemove: '批量移出切片合集',
  BatchOperationType.momentCollectionAdd: '批量加入时刻合集',
  BatchOperationType.momentCollectionRemove: '批量移出时刻合集',
  BatchOperationType.videoCollectionAdd: '批量加入视频合集',
  BatchOperationType.videoCollectionRemove: '批量移出视频合集',
  BatchOperationType.downloadTaskDelete: '批量删除下载任务',
};

/// 后端 `BatchOperationRequest.ids` 的上限，超过会被 422 拒绝。
const int maxBatchOperationItems = 1000;

/// 把整批操作提交给后端任务队列；成功与失败都只发一条 toast。
///
/// 任务进度与结果在活动中心查看；提交成功后列表不会即时变化，需用户手动刷新。
/// 返回是否提交成功，调用方据此决定是否退出多选态。
///
/// 同一批操作（类型 + 目标合集 + id 列表一致）在途期间重复调用会被拒绝，
/// 避免连点确认重复提交后端任务。
Future<bool> submitBatchOperation(
  BuildContext context,
  WidgetRef ref, {
  required BatchOperationType operation,
  required List<int> ids,
  int? targetCollectionId,
  bool deleteFiles = false,
}) async {
  final label = _operationLabels[operation] ?? '批量操作';
  if (ids.length > maxBatchOperationItems) {
    if (context.mounted) {
      showToast(
        '$label一次最多提交 $maxBatchOperationItems 项'
        '（当前 ${ids.length} 项），请减少选择后再试',
      );
    }
    return false;
  }
  final submissionKey = batchOperationSubmissionKey(
    operation: operation,
    ids: ids,
    targetCollectionId: targetCollectionId,
  );
  final submissions = ref.read(batchOperationSubmissionProvider.notifier);
  if (!submissions.begin(submissionKey)) {
    if (context.mounted) {
      showToast('$label正在提交中，请稍候');
    }
    return false;
  }
  try {
    await ref
        .read(batchOperationsApiProvider)
        .submit(
          operation: operation,
          ids: ids,
          targetCollectionId: targetCollectionId,
          deleteFiles: deleteFiles,
        );
  } catch (error) {
    if (context.mounted) {
      showToast(apiErrorMessage(error, fallback: '$label提交失败，请稍后重试'));
    }
    return false;
  } finally {
    submissions.end(submissionKey);
  }
  if (context.mounted) {
    showToast(
      '已提交$label（${ids.length} 项），可在活动中心查看进度，完成后请刷新列表',
    );
  }
  return true;
}
