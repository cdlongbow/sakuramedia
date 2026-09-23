import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    this.fieldKey,
    this.searchButtonKey,
    this.imageSearchButtonKey,
    this.textImageSearchButtonKey,
    this.onlineToggleKey,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.onSearchTap,
    this.onImageSearchTap,
    this.onTextImageSearchTap,
    this.showSearchButton = true,
    this.showImageSearchButton = false,
    this.showTextImageSearchButton = false,
    this.showOnlineToggle = false,
    this.isOnlineSearchEnabled = false,
    this.onOnlineSearchToggle,
    this.isSearching = false,
    this.showSearchingIndicator = true,
    this.searchButtonTooltip = '搜索影片或女优',
    this.fillColor,
  });

  final Key? fieldKey;
  final Key? searchButtonKey;
  final Key? imageSearchButtonKey;
  final Key? textImageSearchButtonKey;
  final Key? onlineToggleKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchTap;
  final VoidCallback? onImageSearchTap;
  final VoidCallback? onTextImageSearchTap;
  final bool showSearchButton;
  final bool showImageSearchButton;
  final bool showTextImageSearchButton;
  final bool showOnlineToggle;
  final bool isOnlineSearchEnabled;
  final ValueChanged<bool>? onOnlineSearchToggle;

  /// 搜索请求进行中：禁用后缀搜索按钮避免重复提交。
  final bool isSearching;

  /// 搜索进行中是否把后缀搜索图标换成转圈。
  ///
  /// 当页面已有独立的加载指示（如结果区中央 spinner）时，可传 `false` 保持
  /// 图标不转圈，只做置灰禁用。
  final bool showSearchingIndicator;

  /// 后缀搜索图标的 tooltip / 语义标签。
  final String searchButtonTooltip;

  /// 覆盖默认的填充色；用于把搜索框放到比 `surfaceMuted` 更暗的面板（如侧边栏）上时提升对比。
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      hintText: hintText,
      textInputAction: TextInputAction.search,
      onFieldSubmitted: onSubmitted,
      fillColor: fillColor,
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTextImageSearchButton)
            AppIconButton(
              key: textImageSearchButtonKey,
              tooltip: '文字搜图',
              semanticLabel: '文字搜图',
              iconColor: context.appTextPalette.primary,
              icon: const Icon(Icons.text_fields_rounded),
              onPressed: onTextImageSearchTap,
            ),
          if (showImageSearchButton)
            AppIconButton(
              key: imageSearchButtonKey,
              tooltip: '以图搜图',
              semanticLabel: '以图搜图',
              iconColor: context.appTextPalette.primary,
              icon: const Icon(Icons.image_search_outlined),
              onPressed: onImageSearchTap,
            ),
          if (showOnlineToggle)
            AppIconButton(
              key: onlineToggleKey,
              tooltip: '联网搜索',
              semanticLabel: '联网搜索',
              icon: const Icon(Icons.public_rounded),
              isSelected: isOnlineSearchEnabled,
              onPressed: onOnlineSearchToggle == null
                  ? null
                  : () => onOnlineSearchToggle!(!isOnlineSearchEnabled),
            ),
          if (showSearchButton)
            AppIconButton(
              key: searchButtonKey,
              tooltip: searchButtonTooltip,
              semanticLabel: searchButtonTooltip,
              iconColor: context.appTextPalette.primary,
              icon: isSearching && showSearchingIndicator
                  ? SizedBox(
                      width: context.appComponentTokens.iconSizeMd,
                      height: context.appComponentTokens.iconSizeMd,
                      child: const CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              onPressed: isSearching ? null : onSearchTap,
            ),
        ],
      ),
    );
  }
}
