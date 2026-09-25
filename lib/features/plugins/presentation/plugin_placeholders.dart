import 'package:sakuramedia/features/plugins/data/dto/plugin_dto.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 插件页加载态占位状态：真实 [PluginsState] + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实插件行同形的静态骨架。
PluginsState pluginsPlaceholderState({int count = 3}) {
  return PluginsState(
    plugins: List<PluginSummaryDto>.generate(
      count,
      (index) => PluginSummaryDto(
        pluginId: 'plugin-$index',
        displayName: BoneMock.words(2),
        version: '1.0.0',
        hostApiVersion: 1,
        enabled: true,
        loadStatus: 'ok',
      ),
      growable: false,
    ),
  );
}
