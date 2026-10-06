import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/downloads/data/download_candidate_dto.dart';
import 'package:sakuramedia/features/downloads/data/download_request_dto.dart';
import 'package:sakuramedia/features/downloads/data/download_task_file_dto.dart';

class DownloadsApi {
  const DownloadsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// `POST /download-tasks/imports` 的单次受理上限（对应后端请求体的
  /// `max_length=100`）。
  static const int _batchImportChunkSize = 100;

  Future<List<DownloadCandidateDto>> searchCandidates({
    required String movieNumber,
    String? indexerKind,
  }) async {
    final queryParameters = <String, dynamic>{'movie_number': movieNumber};
    if (indexerKind != null && indexerKind.trim().isNotEmpty) {
      queryParameters['indexer_kind'] = indexerKind.trim();
    }

    final response = await _apiClient.getList(
      '/download-candidates',
      queryParameters: queryParameters,
    );
    return response.map(DownloadCandidateDto.fromJson).toList(growable: false);
  }

  Future<DownloadRequestResponseDto> createDownloadRequest({
    required String movieNumber,
    required int clientId,
    required DownloadCandidateDto candidate,
  }) async {
    final response = await _apiClient.post(
      '/download-requests',
      data: <String, dynamic>{
        'client_id': clientId,
        'movie_number': movieNumber,
        'candidate': candidate.toCreatePayloadJson(),
      },
      receiveTimeout: const Duration(minutes: 2),
    );
    return DownloadRequestResponseDto.fromJson(response);
  }

  Future<PaginatedResponseDto<DownloadTaskDto>> getDownloadTasks({
    int page = 1,
    int pageSize = 20,
    int? clientId,
    String? movieNumber,
    List<String>? states,
    String? sort,
  }) async {
    final response = await _apiClient.get(
      '/download-tasks',
      queryParameters: <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (clientId != null) 'client_id': clientId,
        if (movieNumber != null && movieNumber.trim().isNotEmpty)
          'movie_number': movieNumber,
        if (states != null && states.isNotEmpty) 'state': states,
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort,
      },
    );
    return PaginatedResponseDto<DownloadTaskDto>.fromJson(
      response,
      DownloadTaskDto.fromJson,
    );
  }

  /// 删除下载任务；`deleteFiles=true` 时把双确认 `confirm_delete_files`
  /// 一起塞进 query，避免调用点漏传 422。
  Future<void> deleteDownloadTask(
    int taskId, {
    bool deleteFiles = false,
  }) async {
    await _apiClient.deleteNoContent(
      '/download-tasks/$taskId',
      queryParameters: <String, dynamic>{
        'delete_files': deleteFiles,
        if (deleteFiles) 'confirm_delete_files': true,
      },
    );
  }

  /// 列出下载任务源内的文件；仅已完成任务可用，后端从 provider 实时扫描。
  Future<List<DownloadTaskFileDto>> getDownloadTaskFiles(int taskId) async {
    final response = await _apiClient.getList('/download-tasks/$taskId/files');
    return response.map(DownloadTaskFileDto.fromJson).toList(growable: false);
  }

  /// 重新触发该下载任务的导入；受理后由后台导入队列执行。
  Future<void> triggerDownloadTaskImport(int taskId) async {
    await _apiClient.post('/download-tasks/$taskId/import');
  }

  /// 批量重新导入失败/跳过的下载任务；后端按媒体库分组入队、串行执行。
  ///
  /// 后端单次最多受理 [_batchImportChunkSize] 个任务，这里分批提交并合并结果。
  Future<DownloadTaskBatchImportResultDto> triggerDownloadTaskBatchImport(
    List<int> taskIds,
  ) async {
    var acceptedCount = 0;
    final skippedTaskIds = <int>[];
    for (var start = 0; start < taskIds.length; start += _batchImportChunkSize) {
      final end = start + _batchImportChunkSize <= taskIds.length
          ? start + _batchImportChunkSize
          : taskIds.length;
      final response = await _apiClient.post(
        '/download-tasks/imports',
        data: <String, dynamic>{'task_ids': taskIds.sublist(start, end)},
      );
      final result = DownloadTaskBatchImportResultDto.fromJson(response);
      acceptedCount += result.acceptedCount;
      skippedTaskIds.addAll(result.skippedTaskIds);
    }
    return DownloadTaskBatchImportResultDto(
      acceptedCount: acceptedCount,
      skippedTaskIds: skippedTaskIds,
    );
  }
}
