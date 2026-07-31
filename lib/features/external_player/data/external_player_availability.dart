import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sakuramedia/features/external_player/data/external_player_channel.dart';
import 'package:sakuramedia/features/external_player/data/external_player_store.dart';

/// 外部播放器是否就绪（设置了默认外部播放器且当前平台支持）。
///
/// 详情页用它决定是否展示「合并播放」模式选项；未注入 Provider 的局部上下文
/// 返回 false（降级为不展示）。桌面端通道不支持，恒为 false。
bool isExternalPlayerReady(BuildContext context) {
  try {
    final store = context.read<ExternalPlayerStore>();
    return store.hasExternalPlayer &&
        const ExternalPlayerChannel().isSupported;
  } on ProviderNotFoundException {
    return false;
  }
}
