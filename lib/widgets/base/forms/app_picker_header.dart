import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';

/// 选择器弹层的统一头部：标题 + 计数 + 搜索 + 筛选 chips。
///
/// 桌面弹窗与移动抽屉共用；移动抽屉会额外显示右侧「完成」文字按钮
/// （桌面弹窗自带右上角关闭）。搜索只做输入透传，防抖由调用方处理。
class AppPickerHeader extends StatelessWidget {
  const AppPickerHeader({
    super.key,
    required this.title,
    this.countLabel,
    this.countKey,
    required this.searchController,
    this.searchFieldKey,
    this.searchHintText = '搜索',
    this.onSearchChanged,
    this.clearSearchKey,
    this.chips = const <Widget>[],
    this.onDone,
    this.doneKey,
  });

  final String title;

  /// 右侧只读计数，例如「已加入 12 · 可添加 86」。
  final String? countLabel;
  final Key? countKey;

  final TextEditingController searchController;
  final Key? searchFieldKey;
  final String searchHintText;
  final ValueChanged<String>? onSearchChanged;
  final Key? clearSearchKey;

  /// 筛选 chips（`AppTextButton(isSelected:)`），横向可滚动。
  final List<Widget> chips;

  /// 仅移动抽屉传；为 null 时不渲染「完成」。
  final VoidCallback? onDone;
  final Key? doneKey;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final count = countLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s16,
                  weight: AppTextWeight.semibold,
                  tone: AppTextTone.primary,
                ),
              ),
            ),
            if (count != null) ...[
              SizedBox(width: spacing.sm),
              Text(
                count,
                key: countKey,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
            ],
            if (onDone != null) ...[
              SizedBox(width: spacing.xs),
              AppTextButton(
                key: doneKey,
                label: '完成',
                size: AppTextButtonSize.small,
                onPressed: onDone,
              ),
            ],
          ],
        ),
        SizedBox(height: spacing.lg),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: searchController,
          builder: (context, value, _) {
            return AppTextField(
              fieldKey: searchFieldKey,
              controller: searchController,
              hintText: searchHintText,
              textInputAction: TextInputAction.search,
              onChanged: onSearchChanged,
              prefix: Icon(
                Icons.search_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.muted,
              ),
              suffix: value.text.isEmpty
                  ? null
                  : AppIconButton(
                      key: clearSearchKey,
                      tooltip: '清空',
                      size: AppIconButtonSize.compact,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged?.call('');
                      },
                    ),
            );
          },
        ),
        if (chips.isNotEmpty) ...[
          SizedBox(height: spacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < chips.length; index++) ...[
                  if (index > 0) SizedBox(width: spacing.sm),
                  chips[index],
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
