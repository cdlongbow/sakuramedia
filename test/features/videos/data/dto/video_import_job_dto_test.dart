import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/media_import/data/media_import_source.dart';
import 'package:sakuramedia/features/videos/data/dto/video_import_job_dto.dart';

void main() {
  group('VideoImportJobListItemDto.reimportSource', () {
    test('115 目录作业按 source_cid 还原来源', () {
      final job = VideoImportJobListItemDto.fromJson(
        _jobJson(sourceCid: 'cid-1', sourcePath: '根目录/影片目录'),
      );

      expect(job.isCloud115, isTrue);
      expect(job.reimportSource, const MediaImportSource.cloud115('cid-1'));
    });

    test('本地作业按 source_path 还原来源', () {
      final job = VideoImportJobListItemDto.fromJson(
        _jobJson(sourcePath: '/mnt/incoming/videos'),
      );

      expect(job.isCloud115, isFalse);
      expect(
        job.reimportSource,
        const MediaImportSource.local('/mnt/incoming/videos'),
      );
    });

    test('115 单文件（source_fid）作业不可还原——前端没有单文件导入来源形状', () {
      // source_path 是 115 面包屑，当成本地路径回传会被后端白名单拒掉，
      // 所以这类作业必须彻底关掉「重新导入」入口。
      final job = VideoImportJobListItemDto.fromJson(
        _jobJson(sourceFid: 'fid-1', sourcePath: '根目录/影片.mp4'),
      );

      expect(job.reimportSource, isNull);
    });

    test('来源字段全空时不可还原', () {
      final job = VideoImportJobListItemDto.fromJson(_jobJson(sourcePath: ''));

      expect(job.reimportSource, isNull);
    });
  });

  test('VideoImportJobDto 解析 failed_files 的 kind=job 条目', () {
    final job = VideoImportJobDto.fromJson(<String, dynamic>{
      ..._jobJson(sourceCid: 'cid-1'),
      'failed_files': <Map<String, dynamic>>[
        <String, dynamic>{
          'path': '根目录/影片目录',
          'reason': 'import_job_crashed',
          'detail': 'http 405 on GET https://webapi.115.com/files',
          'kind': 'job',
        },
      ],
    });

    expect(job.failedFiles.single.isJobLevel, isTrue);
    expect(job.failedFiles.single.isActionable, isFalse);
    // 任务级条目不进可重导清单——只能整体重新导入。
    expect(job.actionableFailedFiles, isEmpty);
  });
}

Map<String, dynamic> _jobJson({
  String sourcePath = '/mnt/incoming/videos',
  String? sourceCid,
  String? sourceFid,
}) {
  return <String, dynamic>{
    'id': 1,
    'source_path': sourcePath,
    if (sourceCid != null) 'source_cid': sourceCid,
    if (sourceFid != null) 'source_fid': sourceFid,
    'library_id': 2,
    'collection_id': 3,
    'task_run_id': 4,
    'state': 'failed',
    'transfer_mode': 'copy',
    'imported_count': 0,
    'skipped_count': 0,
    'failed_count': 1,
    'created_at': '2026-07-27 18:00:00',
    'updated_at': '2026-07-27 18:05:00',
  };
}
