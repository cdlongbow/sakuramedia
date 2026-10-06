import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/cast/data/cast_device.dart';
import 'package:sakuramedia/features/cast/data/cast_director.dart';
import 'package:sakuramedia/features/cast/presentation/widgets/cast_device_picker.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';

import '../../support/cast_test_helpers.dart';

class _FakeCastDirector extends CastDirector {
  _FakeCastDirector(this.streams);

  final List<Stream<CastDevice>> streams;
  int discoverCalls = 0;

  @override
  Stream<CastDevice> discover() {
    final index = discoverCalls < streams.length
        ? discoverCalls
        : streams.length - 1;
    discoverCalls += 1;
    return streams[index];
  }
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required CastDirector director,
  required Future<void> Function(CastDevice device) onCast,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showCastDevicePicker(
                context: context,
                onCast: onCast,
                director: director,
              ),
              child: const Text('打开投屏'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开投屏'));
  // 扫描态带无限转圈动画，不能用 pumpAndSettle。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('扫描中展示搜索提示', (tester) async {
    final controller = StreamController<CastDevice>();
    addTearDown(() => unawaited(controller.close()));
    await _pumpPicker(
      tester,
      director: _FakeCastDirector([controller.stream]),
      onCast: (_) async {},
    );

    expect(find.text('投屏到电视'), findsOneWidget);
    expect(find.text('正在搜索附近设备…'), findsOneWidget);
    // 扫描中展示骨架占位，撑住弹层高度避免跳变。
    expect(find.byType(AppSkeletonizer), findsOneWidget);
  });

  testWidgets('从骨架到单台设备，弹层高度保持不变', (tester) async {
    final controller = StreamController<CastDevice>();
    addTearDown(() => unawaited(controller.close()));
    await _pumpPicker(
      tester,
      director: _FakeCastDirector([controller.stream]),
      onCast: (_) async {},
    );

    final skeletonHeight = tester
        .getSize(find.byType(CastDevicePickerBody))
        .height;

    controller.add(buildTestCastDevice(id: 'uuid:living', name: '客厅电视'));
    await tester.pump();
    expect(find.text('客厅电视'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CastDevicePickerBody)).height,
      skeletonHeight,
    );
  });

  testWidgets('从骨架到空态，弹层高度保持不变', (tester) async {
    final controller = StreamController<CastDevice>();
    addTearDown(() => unawaited(controller.close()));
    await _pumpPicker(
      tester,
      director: _FakeCastDirector([controller.stream]),
      onCast: (_) async {},
    );

    final skeletonHeight = tester
        .getSize(find.byType(CastDevicePickerBody))
        .height;

    unawaited(controller.close());
    await tester.pump();
    expect(find.text('未发现可投屏设备'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CastDevicePickerBody)).height,
      skeletonHeight,
    );
  });

  testWidgets('发现设备后展示设备行，点击投送后关闭弹层', (tester) async {
    final controller = StreamController<CastDevice>();
    addTearDown(() => unawaited(controller.close()));
    final castedDevices = <CastDevice>[];
    await _pumpPicker(
      tester,
      director: _FakeCastDirector([controller.stream]),
      onCast: (device) async => castedDevices.add(device),
    );

    controller.add(
      buildTestCastDevice(
        id: 'uuid:living',
        name: '客厅电视',
        address: '192.168.1.100',
      ),
    );
    await tester.pump();

    expect(find.text('客厅电视'), findsOneWidget);
    expect(find.text('192.168.1.100'), findsOneWidget);

    await tester.tap(find.text('客厅电视'));
    await tester.pumpAndSettle();

    expect(castedDevices, hasLength(1));
    expect(castedDevices.single.name, '客厅电视');
    expect(find.text('投屏到电视'), findsNothing);
  });

  testWidgets('投送失败时在弹层内展示错误并保留弹层', (tester) async {
    final controller = StreamController<CastDevice>();
    addTearDown(() => unawaited(controller.close()));
    await _pumpPicker(
      tester,
      director: _FakeCastDirector([controller.stream]),
      onCast: (_) async => throw const CastException('电视无法访问该视频地址'),
    );

    controller.add(buildTestCastDevice(id: 'uuid:bedroom', name: '卧室电视'));
    await tester.pump();
    await tester.tap(find.text('卧室电视'));
    await tester.pumpAndSettle();

    expect(find.text('电视无法访问该视频地址'), findsOneWidget);
    expect(find.text('投屏到电视'), findsOneWidget);
  });

  testWidgets('扫描结束无设备显示空态，重新搜索后恢复', (tester) async {
    final firstController = StreamController<CastDevice>();
    final secondController = StreamController<CastDevice>();
    addTearDown(() => unawaited(firstController.close()));
    addTearDown(() => unawaited(secondController.close()));
    final director = _FakeCastDirector([
      firstController.stream,
      secondController.stream,
    ]);
    await _pumpPicker(tester, director: director, onCast: (_) async {});

    expect(find.text('正在搜索附近设备…'), findsOneWidget);

    // 在测试的假异步环境里 close 的 future 会挂起，这里只触发关闭、交给 pump 派发。
    unawaited(firstController.close());
    await tester.pump();
    expect(find.text('未发现可投屏设备'), findsOneWidget);

    await tester.tap(find.text('重新搜索'));
    await tester.pump();
    expect(director.discoverCalls, 2);
    expect(find.text('正在搜索附近设备…'), findsOneWidget);

    secondController.add(buildTestCastDevice(id: 'uuid:study', name: '书房电视'));
    await tester.pump();
    expect(find.text('书房电视'), findsOneWidget);
  });
}
