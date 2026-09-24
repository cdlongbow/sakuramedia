import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';

/// 合集详情 / 成员列表顶栏的「网格 / 列表」视图切换按钮。
///
/// [isList] 是当前布局：`true`（列表）时按钮切回网格，点击触发 [onPressed]。
class AppViewModeToggleButton extends StatelessWidget {
  const AppViewModeToggleButton({
    super.key,
    required this.isList,
    required this.onPressed,
    this.buttonKey,
  });

  final bool isList;
  final VoidCallback? onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      key: buttonKey,
      tooltip: isList ? '网格视图' : '列表视图',
      onPressed: onPressed,
      icon: Icon(
        isList ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
        size: context.appComponentTokens.iconSizeSm,
      ),
    );
  }
}
