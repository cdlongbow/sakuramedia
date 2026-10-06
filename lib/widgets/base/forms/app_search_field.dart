import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';

/// 统一搜索输入：前置放大镜 + 有内容时显示清空按钮。
///
/// 只做输入透传，防抖 / 过滤策略由调用方决定；选择器弹层（[AppPickerHeader]）
/// 与合集 / 播放列表页共用，避免各处重复拼同一条输入框。
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.fieldKey,
    this.hintText = '搜索',
    this.onChanged,
    this.clearKey,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final String hintText;
  final ValueChanged<String>? onChanged;

  /// 清空按钮的测试锚点。
  final Key? clearKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AppTextField(
          fieldKey: fieldKey,
          controller: controller,
          hintText: hintText,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          prefix: Icon(
            Icons.search_rounded,
            size: context.appComponentTokens.iconSizeSm,
            color: context.appTextPalette.muted,
          ),
          suffix: value.text.isEmpty
              ? null
              : AppIconButton(
                  key: clearKey,
                  tooltip: '清空',
                  size: AppIconButtonSize.compact,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        );
      },
    );
  }
}
