import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 合集横滑区的轻量提示条：用于空态与加载失败的文案占位。
///
/// 切片 / 视频 / 时刻三个合集横滑区共用，避免各页面各写一份同构容器。
class CollectionHintBox extends StatelessWidget {
  const CollectionHintBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.appSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Text(
        message,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.secondary,
        ),
      ),
    );
  }
}
