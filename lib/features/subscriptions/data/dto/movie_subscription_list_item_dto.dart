import 'package:sakuramedia/core/json/json_parse.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_status.dart';

/// `GET /movie-subscriptions` 的单条订阅影片。
///
/// 字段构成与 `MovieListItemDto` 差别很大——它描述的是「这部订阅片的资源查询走到
/// 哪一步了」，而不是影片资料本身，因此后端也独立成一套 schema。复用
/// [MovieImageDto] 只是因为封面结构相同。
class MovieSubscriptionListItemDto {
  const MovieSubscriptionListItemDto({
    required this.movieNumber,
    required this.title,
    required this.titleZh,
    required this.status,
    this.coverImage,
    this.releaseDate,
    this.subscribedAt,
    this.isFresh = false,
    this.attemptCount = 0,
    this.attemptLimit = 0,
    this.lastSearchedAt,
    this.lastError,
    this.deadDownloadTaskCount = 0,
    this.mediaCount = 0,
    this.importOperation,
  });

  final String movieNumber;
  final String title;
  final String titleZh;
  final MovieImageDto? coverImage;

  /// 后端按 `YYYY-MM-DD` 下发，保持字符串原样展示（无需时区换算）。
  final String? releaseDate;
  final DateTime? subscribedAt;
  final MovieSubscriptionStatus status;

  /// 是否算新片（`release_date` 在 90 天内，含未来日期）。
  ///
  /// 新片**每轮都查、不计次数、永不放弃**，所以为 `true` 时 [attemptCount] 恒为 0，
  /// UI 该展示「持续查询中」而不是次数进度。
  final bool isFresh;

  /// 老片已查次数 / 上限（默认上限 3）。[isFresh] 为 true 时这对值无意义。
  final int attemptCount;
  final int attemptLimit;

  final DateTime? lastSearchedAt;

  /// 仅 `status == failed` 时有值，为索引器调用的错误详情。
  final String? lastError;

  /// 该影片已判死的下载任务数：试过几个种子都失败了。
  final int deadDownloadTaskCount;

  final int mediaCount;

  /// `import_failed` 档的可操作上下文：最新导入作业与后端计算的可用动作。
  final MovieSubscriptionImportOperationDto? importOperation;

  factory MovieSubscriptionListItemDto.fromJson(Map<String, dynamic> json) {
    final coverImage = asMapOrNull(json['cover_image']);
    return MovieSubscriptionListItemDto(
      movieNumber: asStringOrNull(json['movie_number']) ?? '',
      title: asStringOrNull(json['title']) ?? '',
      titleZh: asStringOrNull(json['title_zh']) ?? '',
      coverImage:
          coverImage == null ? null : MovieImageDto.fromJson(coverImage),
      releaseDate: asStringOrNull(json['release_date'], trim: true),
      subscribedAt: asDateTime(json['subscribed_at']),
      status: MovieSubscriptionStatusX.fromWire(json['status']),
      isFresh: json['is_fresh'] as bool? ?? false,
      attemptCount: asInt(json['attempt_count']),
      attemptLimit: asInt(json['attempt_limit']),
      lastSearchedAt: asDateTime(json['last_searched_at']),
      lastError: asStringOrNull(json['last_error'], trim: true),
      deadDownloadTaskCount: asInt(json['dead_download_task_count']),
      mediaCount: asInt(json['media_count']),
      importOperation: MovieSubscriptionImportOperationDto.fromJsonOrNull(
        asMapOrNull(json['import_operation']),
      ),
    );
  }

  /// 列表主标题：中文标题优先，回落原标题，再回落番号。
  String get displayTitle {
    final zh = titleZh.trim();
    if (zh.isNotEmpty) {
      return zh;
    }
    final original = title.trim();
    return original.isNotEmpty ? original : movieNumber;
  }

  /// 重置查询状态对该条目是否有意义。
  ///
  /// 已入库的片不再参与资源查询，重置它只会平白多打一轮索引器；下载中的片已经
  /// 找到种子，重置同样无意义；**导入失败的片文件已经在盘上，卡的是入库那一步，
  /// 让它去重新找种子只会白下一遍**。其余四态（缺资源 / 已放弃 / 查询出错 / 待查）
  /// 都允许重置——「待查」重置是空操作但无害，保持规则简单。
  bool get canResetSearch =>
      status != MovieSubscriptionStatus.imported &&
      status != MovieSubscriptionStatus.importFailed &&
      status != MovieSubscriptionStatus.downloading;

  /// 重置资源查询状态后的本地投影，供列表就地打补丁、不整页重拉。
  ///
  /// 后端的重置就是**删掉这条影片的 `ResourceTaskState` 行**，让它回到「从未查
  /// 过」——所以这里精确对齐那个终态：状态回 `pending`、次数归零、上次查询与
  /// 错误清空。[deadDownloadTaskCount] **保留不动**：重置不放开选种黑名单，已判
  /// 死的种子仍然是死的。
  MovieSubscriptionListItemDto afterSearchReset() {
    return MovieSubscriptionListItemDto(
      movieNumber: movieNumber,
      title: title,
      titleZh: titleZh,
      coverImage: coverImage,
      releaseDate: releaseDate,
      subscribedAt: subscribedAt,
      status: MovieSubscriptionStatus.pending,
      isFresh: isFresh,
      attemptCount: 0,
      attemptLimit: attemptLimit,
      deadDownloadTaskCount: deadDownloadTaskCount,
      mediaCount: mediaCount,
    );
  }
}


/// `import_failed` 档的最新导入作业上下文；`availableActions` 由后端计算，
/// 前端只按枚举渲染（open_import_job / retry_failed_files / rerun_import）。
class MovieSubscriptionImportOperationDto {
  const MovieSubscriptionImportOperationDto({
    required this.importJobId,
    required this.state,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.failedCount = 0,
    this.retryableFileCount = 0,
    this.availableActions = const <String>[],
  });

  final int importJobId;
  final String state;
  final int importedCount;
  final int skippedCount;
  final int failedCount;

  /// 可重导（kind=file）失败条目数：为 0 时后端不会下发 retry_failed_files。
  final int retryableFileCount;
  final List<String> availableActions;

  bool get canRetryFailedFiles => availableActions.contains('retry_failed_files');
  bool get canRerun => availableActions.contains('rerun_import');

  static MovieSubscriptionImportOperationDto? fromJsonOrNull(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return MovieSubscriptionImportOperationDto(
      importJobId: asInt(json['import_job_id']),
      state: asStringOrNull(json['state']) ?? '',
      importedCount: asInt(json['imported_count']),
      skippedCount: asInt(json['skipped_count']),
      failedCount: asInt(json['failed_count']),
      retryableFileCount: asInt(json['retryable_file_count']),
      availableActions:
          (json['available_actions'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }
}
