import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/taste_profile_provider.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_provider.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_scope.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';

/// 标签页头部的常看标签快捷筛选，不显示标题和数量。
///
/// 偏好里的命中数是样本内口径，标签云里的 movieCount 是全库口径；
/// 两个数字并排会误导，所以这里只保留标签名。
class TasteQuickTags extends ConsumerWidget {
  const TasteQuickTags({super.key, required this.scope});

  final TagSelectionScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(tasteProfileProvider).value;
    if (profile == null ||
        profile.sampleMovieCount < 2 ||
        profile.tags.isEmpty) {
      return const SizedBox.shrink();
    }
    final selection = ref.watch(tagSelectionProvider(scope));
    final notifier = ref.read(tagSelectionProvider(scope).notifier);
    final tags = profile.tags.take(6).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: context.appSpacing.sm),
      child: SingleChildScrollView(
        key: const Key('taste-quick-tags'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (var index = 0; index < tags.length; index++) ...<Widget>[
              if (index > 0) SizedBox(width: context.appSpacing.xs),
              AppTextButton(
                key: Key('taste-quick-tag-${tags[index].tagId}'),
                label: tags[index].name,
                size: AppTextButtonSize.xSmall,
                isSelected: selection.isSelected(tags[index].tagId),
                onPressed: () => notifier.toggle(tags[index].tagId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
