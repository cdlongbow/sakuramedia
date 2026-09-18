/// 画质增强「档 1」：只改 mpv 渲染管线的处理属性，不改渲染尺寸。
///
/// 全部是运行时属性，写入即生效；个别属性在部分平台 / mpv 版本上不可用，
/// 单条失败静默跳过，不影响播放。关闭时按开启前记录的原值恢复，避免覆盖
/// 平台既有默认（例如 Windows 构建的 mpv 默认 `dither-depth` 与 macOS 不同）。
typedef MpvPropertyWriter = Future<void> Function(String key, String value);

typedef MpvPropertyReader = Future<String?> Function(String key);

class MpvVideoQualitySettings {
  const MpvVideoQualitySettings._();

  /// 开启增强时写入的属性。
  ///
  /// - `deband`：抹掉压缩 / 量化在暗部渐变产生的色带，是最直观的一项。
  /// - `dither-depth`：输出 8bit 前的抖动，防止降位深时重新造出新的色带。
  /// - `cscale`：4:2:0 色度上采样到亮度分辨率；这是当前渲染尺寸下唯一
  ///   真正生效的 scaler（其余缩放要等渲染尺寸大于视频分辨率才会发生）。
  /// - `sharpen`：unsharp 锐化，增强已有边缘对比度（不恢复细节）。
  static const Map<String, String> enhancements = <String, String>{
    'deband': 'yes',
    'deband-iterations': '3',
    'dither-depth': 'auto',
    'cscale': 'spline36',
    'sharpen': '0.5',
  };

  /// 关闭增强时读不到原值时的回落值（中性、不放大也不额外处理）。
  static const Map<String, String> neutralValues = <String, String>{
    'deband': 'no',
    'deband-iterations': '1',
    'dither-depth': 'no',
    'cscale': 'bilinear',
    'sharpen': '0.0',
  };

  /// 记录增强会覆盖到的属性当前值，供关闭时恢复。
  static Future<Map<String, String>> captureCurrent(
    MpvPropertyReader reader,
  ) async {
    final snapshot = <String, String>{};
    for (final key in enhancements.keys) {
      try {
        final value = await reader(key);
        final normalized = value?.trim();
        if (normalized != null && normalized.isNotEmpty) {
          snapshot[key] = normalized;
        }
      } catch (_) {
        // 读不到就交给关闭时的中性值兜底。
      }
    }
    return snapshot;
  }

  static Future<void> enable(MpvPropertyWriter writer) {
    return _write(writer, enhancements);
  }

  static Future<void> disable(
    MpvPropertyWriter writer,
    Map<String, String> snapshot,
  ) {
    return _write(writer, <String, String>{
      for (final key in enhancements.keys)
        key: snapshot[key] ?? neutralValues[key]!,
    });
  }

  static Future<void> _write(
    MpvPropertyWriter writer,
    Map<String, String> values,
  ) async {
    for (final entry in values.entries) {
      try {
        await writer(entry.key, entry.value);
      } catch (_) {
        // 属性在该平台不可用时跳过，其余属性继续写入。
      }
    }
  }
}
