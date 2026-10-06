import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/cast/data/cast_remote_controller.dart';
import 'package:sakuramedia/features/cast/data/cast_transport.dart';

import '../../support/cast_test_helpers.dart';

CastRemoteController _buildController(
  FakeCastTransport transport, {
  List<({int mediaId, int positionSeconds})>? reports,
  Duration progressReportInterval = const Duration(seconds: 5),
}) {
  final session = buildTestCastSession();
  return CastRemoteController(
    session: session,
    transport: transport,
    pollInterval: const Duration(milliseconds: 60),
    seekDebounce: const Duration(milliseconds: 40),
    seekCooldown: const Duration(milliseconds: 120),
    progressReportInterval: progressReportInterval,
    reportProgress: ({required mediaId, required positionSeconds}) async {
      reports?.add((mediaId: mediaId, positionSeconds: positionSeconds));
    },
  );
}

void main() {
  test('start 立即轮询并进入播放态，时长优先用本地数据', () async {
    final transport = FakeCastTransport()
      ..position = const CastPositionInfo(
        position: Duration(minutes: 10),
        duration: Duration(minutes: 30),
      );
    final controller = _buildController(transport);
    addTearDown(controller.dispose);

    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(controller.state.phase, CastRemotePhase.playing);
    expect(controller.state.position, const Duration(minutes: 10));
    expect(controller.state.duration, const Duration(hours: 1));
    expect(transport.calls, containsAll(<String>['position', 'status']));
  });

  test('连续失败进入断开态，恢复后自动回到播放态', () async {
    final transport = FakeCastTransport()..failure = Exception('offline');
    final controller = _buildController(transport);
    addTearDown(controller.dispose);

    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    expect(controller.state.phase, CastRemotePhase.disconnected);

    transport.failure = null;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    expect(controller.state.phase, CastRemotePhase.playing);
  });

  test('连续快进合并为一次 seek 且位置乐观更新', () async {
    final transport = FakeCastTransport();
    final controller = _buildController(transport);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    unawaited(controller.seekBy(const Duration(seconds: 10)));
    unawaited(controller.seekBy(const Duration(seconds: 10)));
    unawaited(controller.seekBy(const Duration(seconds: 10)));
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(transport.seeks, <Duration>[const Duration(seconds: 30)]);
    expect(controller.state.position, const Duration(seconds: 30));
  });

  test('快进被夹取到影片时长上限', () async {
    final transport = FakeCastTransport();
    final controller = _buildController(transport);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    unawaited(controller.seekBy(const Duration(seconds: 4000)));
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(transport.seeks, <Duration>[const Duration(hours: 1)]);
  });

  test('seek 成功后立即回写一次进度', () async {
    final transport = FakeCastTransport();
    final reports = <({int mediaId, int positionSeconds})>[];
    final controller = _buildController(transport, reports: reports);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    unawaited(controller.seekTo(const Duration(minutes: 2)));
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(reports, contains((mediaId: 7, positionSeconds: 120)));
  });

  test('seek 失败展示可读错误', () async {
    final transport = FakeCastTransport();
    final controller = _buildController(transport);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    transport.failure = Exception('boom');
    unawaited(controller.seekTo(const Duration(minutes: 2)));
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.isSeeking, isFalse);
  });

  test('暂停与播放乐观切换并下发对应指令', () async {
    final transport = FakeCastTransport();
    final controller = _buildController(transport);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    transport.status = CastPlaybackStatus.paused;
    await controller.pause();
    expect(transport.calls, contains('pause'));
    expect(controller.state.phase, CastRemotePhase.paused);

    transport.status = CastPlaybackStatus.playing;
    await controller.play();
    expect(transport.calls, contains('play'));
    expect(controller.state.phase, CastRemotePhase.playing);
  });

  test('stopPlayback 下发 stop 并 flush 进度', () async {
    final transport = FakeCastTransport()
      ..position = const CastPositionInfo(position: Duration(seconds: 50));
    final reports = <({int mediaId, int positionSeconds})>[];
    final controller = _buildController(transport, reports: reports);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await controller.stopPlayback();

    expect(transport.calls, contains('stop'));
    expect(
      reports,
      contains((mediaId: 7, positionSeconds: 50)),
    );
  });

  test('播放中按周期自动回写进度', () async {
    final transport = FakeCastTransport()
      ..position = const CastPositionInfo(position: Duration(seconds: 30));
    final reports = <({int mediaId, int positionSeconds})>[];
    final controller = _buildController(
      transport,
      reports: reports,
      progressReportInterval: const Duration(milliseconds: 50),
    );
    addTearDown(controller.dispose);

    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 180));

    expect(
      reports,
      contains((mediaId: 7, positionSeconds: 30)),
    );
  });

  test('结束与中途停止区分：接近结尾的 STOPPED 视为播放结束', () async {
    final transport = FakeCastTransport()
      ..status = CastPlaybackStatus.stopped
      ..position = const CastPositionInfo(position: Duration(hours: 1));
    final controller = _buildController(transport);
    addTearDown(controller.dispose);
    controller.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(controller.state.phase, CastRemotePhase.finished);

    final midTransport = FakeCastTransport()
      ..status = CastPlaybackStatus.stopped
      ..position = const CastPositionInfo(position: Duration(minutes: 5));
    final midController = _buildController(midTransport);
    addTearDown(midController.dispose);
    midController.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(midController.state.phase, CastRemotePhase.stopped);
  });
}
