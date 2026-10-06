import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sakuramedia/features/cast/data/cast_device.dart';
import 'package:sakuramedia/features/cast/data/cast_didl.dart';
import 'package:sakuramedia/features/cast/data/multicast_lock_channel.dart';
import 'package:upnp_client/upnp_client.dart';

/// 当前平台是否支持投屏（iOS 受系统组播限制，暂不提供设备发现）。
bool get isCastPlatformSupported => switch (defaultTargetPlatform) {
  TargetPlatform.android ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => true,
  _ => false,
};

/// 投屏流程中的业务错误，[message] 面向用户可读。
class CastException implements Exception {
  const CastException(this.message);

  final String message;

  @override
  String toString() => 'CastException: $message';
}

/// DLNA 投屏：局域网设备发现 + 播放地址推送。
class CastDirector {
  const CastDirector();

  final MulticastLockChannel _multicastLock = const MulticastLockChannel();

  /// 单轮发现的等待窗口：电视的 SSDP 响应通常在 1-3 秒内到达。
  static const Duration _discoveryWindow = Duration(seconds: 5);

  /// 发现可投屏设备。
  ///
  /// 结果流式产出（设备逐个可用），窗口结束自动关闭；取消订阅会同步
  /// 停止扫描并释放组播锁。
  Stream<CastDevice> discover() {
    final controller = StreamController<CastDevice>();
    final seen = <String>{};
    DeviceDiscoverer? discoverer;
    StreamSubscription<Device>? subscription;
    var lockAcquired = false;
    var cleanedUp = false;

    Future<void> cleanUp() async {
      if (cleanedUp) {
        return;
      }
      cleanedUp = true;
      await subscription?.cancel();
      discoverer?.dispose();
      if (lockAcquired) {
        lockAcquired = false;
        await _multicastLock.release();
      }
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    Future<void> run() async {
      try {
        lockAcquired = await _multicastLock.acquire();
        final localDiscoverer = DeviceDiscoverer();
        discoverer = localDiscoverer;
        subscription = localDiscoverer.devices.listen((device) {
          final castDevice = castDeviceFromRenderer(device);
          if (castDevice != null && seen.add(castDevice.id)) {
            if (!controller.isClosed) {
              controller.add(castDevice);
            }
          }
        });
        await localDiscoverer.start(
          addressTypes: const [InternetAddressType.IPv4],
        );
        // getDevices 负责发出 M-SEARCH；设备响应由上面的监听流式转发，
        // 这里只等窗口结束，不使用其返回值。
        unawaited(
          localDiscoverer.getDevices(
            timeout: _discoveryWindow,
            searchTarget: UpnpDeviceType.mediaRenderer.urn(),
          ),
        );
        await Future<void>.delayed(
          _discoveryWindow + const Duration(milliseconds: 500),
        );
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        await cleanUp();
      }
    }

    controller.onCancel = cleanUp;
    unawaited(run());
    return controller.stream;
  }

  /// 把媒体地址推给设备开始播放。
  Future<void> cast({
    required CastDevice device,
    required String url,
    required String title,
    String? contentType,
  }) async {
    final transport = device.renderer.avTransport;
    if (transport == null) {
      throw const CastException('该设备不支持播放视频');
    }
    await transport.setAVTransportURI(
      url,
      metadata: buildVideoDidl(
        url: url,
        title: title,
        contentType: contentType,
      ),
    );
    await transport.play();
  }
}

/// 把 upnp_client 设备映射为投屏设备；非媒体渲染器或不带 AVTransport 时返回 null。
@visibleForTesting
CastDevice? castDeviceFromRenderer(Device device) {
  if (device is! MediaRenderer || device.avTransport == null) {
    return null;
  }
  final location = device.url;
  if (location == null || location.isEmpty) {
    return null;
  }
  final friendlyName = device.description?.friendlyName?.trim() ?? '';
  final host = Uri.tryParse(location)?.host ?? '';
  return CastDevice(
    id: device.description?.uuid ?? location,
    name: friendlyName.isEmpty ? '未命名设备' : friendlyName,
    address: host.isEmpty ? location : host,
    renderer: device,
  );
}

/// 将投屏过程中的异常映射为用户可读文案。
String castErrorMessage(Object error, {String fallback = '投屏失败，请重试'}) {
  if (error is CastException) {
    return error.message;
  }
  if (error is UPnPException) {
    return switch (error.errorCode) {
      701 => '电视暂时无法开始播放，请稍后重试',
      704 => '电视不支持播放该视频格式',
      715 || 716 => '电视无法访问该视频地址',
      _ => fallback,
    };
  }
  if (error is TimeoutException) {
    return '电视未响应，请确认设备处于开机状态';
  }
  if (error is SocketException) {
    return '连接电视失败，请确认设备与电视在同一网络';
  }
  return fallback;
}
