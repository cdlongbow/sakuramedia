import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/data/dto/rating/rating_dimension_dto.dart';
import 'package:sakuramedia/features/movies/presentation/providers/rating_dimensions_provider.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';

Future<void> showRatingDimensionsDialog(BuildContext context) {
  return showAppAdaptiveModal<void>(
    context: context,
    desktopWidth: context.appLayoutTokens.dialogWidthSm,
    mobileMaxHeightFactor: 0.9,
    builder: (_) => const RatingDimensionsDialog(),
  );
}

/// 评分维度管理：名称 + 分值范围；权重暂不开放编辑。
class RatingDimensionsDialog extends ConsumerStatefulWidget {
  const RatingDimensionsDialog({super.key});

  @override
  ConsumerState<RatingDimensionsDialog> createState() =>
      _RatingDimensionsDialogState();
}

class _RatingDimensionsDialogState
    extends ConsumerState<RatingDimensionsDialog> {
  final _nameController = TextEditingController();

  int? _editingId;
  double _editingWeight = 1;
  bool _showForm = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _editingId = null;
      _editingWeight = 1;
      _showForm = true;
      _nameController.clear();
    });
  }

  void _startEdit(RatingDimensionDto dimension) {
    setState(() {
      _editingId = dimension.id;
      _editingWeight = dimension.weight;
      _showForm = true;
      _nameController.text = dimension.name;
    });
  }

  void _cancelForm() {
    setState(() {
      _showForm = false;
      _editingId = null;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(
        AppLocalizations.of(context).movieWidgetDimensionNameRequired,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(ratingDimensionsProvider.notifier);
      if (_editingId == null) {
        await notifier.create(name: name);
      } else {
        await notifier.edit(
          dimensionId: _editingId!,
          name: name,
          // 权重暂不开放编辑，但编辑其它字段时不能把已有权重重置为默认值。
          weight: _editingWeight,
        );
      }
      if (!mounted) return;
      setState(() {
        _showForm = false;
        _editingId = null;
      });
    } catch (error) {
      if (!mounted) return;
      showToast(
        apiErrorMessage(
          error,
          fallback: AppLocalizations.of(
            context,
          ).movieWidgetRatingDimensionSaveFailed,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(RatingDimensionDto dimension) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.movieWidgetDeleteRatingDimensionTitle,
      message: l10n.movieWidgetDeleteRatingDimensionMessage(dimension.name),
      confirmLabel: l10n.commonDelete,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(ratingDimensionsProvider.notifier).delete(dimension.id);
    } catch (error) {
      if (!mounted) return;
      showToast(
        apiErrorMessage(
          error,
          fallback: AppLocalizations.of(
            context,
          ).movieWidgetRatingDimensionDeleteFailed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = ref.watch(ratingDimensionsProvider);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.movieWidgetRatingDimensionsTitle,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s16,
            weight: AppTextWeight.medium,
          ),
        ),
        SizedBox(height: context.appSpacing.xs),
        Text(
          l10n.movieWidgetRatingScaleHint,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(height: context.appSpacing.md),
        if (dimensions.isLoading && !dimensions.hasValue)
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.appSpacing.xl),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (dimensions.hasError && !dimensions.hasValue)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.movieWidgetRatingDimensionsLoadFailed,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s14,
                    tone: AppTextTone.error,
                  ),
                ),
              ),
              AppTextButton(
                label: l10n.commonRetry,
                onPressed: () => ref.invalidate(ratingDimensionsProvider),
              ),
            ],
          )
        else
          _buildDimensionBlock(
            context,
            dimensions.value ?? const <RatingDimensionDto>[],
          ),
        if (_showForm) ...[
          SizedBox(height: context.appSpacing.md),
          _buildForm(context),
        ],
      ],
    );
  }

  Widget _buildDimensionBlock(
    BuildContext context,
    List<RatingDimensionDto> dimensions,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
      ),
      child: Column(
        children: [
          for (final dimension in dimensions) ...[
            _buildDimensionRow(context, dimension),
            Padding(
              padding: EdgeInsets.only(left: context.appSpacing.lg),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.appColors.borderSubtle,
              ),
            ),
          ],
          AppInteractiveSurface(
            key: const Key('rating-dimension-add'),
            onTap: _startCreate,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.lg,
                vertical: context.appSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: context.appComponentTokens.iconSizeSm,
                    color: context.appTextPalette.accent,
                  ),
                  SizedBox(width: context.appSpacing.xs),
                  Text(
                    l10n.movieWidgetAddDimension,
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s14,
                      weight: AppTextWeight.medium,
                      tone: AppTextTone.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(
    BuildContext context,
    RatingDimensionDto dimension,
  ) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: Key('rating-dimension-${dimension.id}'),
      padding: EdgeInsets.symmetric(
        horizontal: context.appSpacing.lg,
        vertical: context.appSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dimension.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: resolveAppTextStyle(context, size: AppTextSize.s14),
            ),
          ),
          AppIconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            size: AppIconButtonSize.mini,
            onPressed: () => _startEdit(dimension),
          ),
          AppIconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: l10n.commonDelete,
            size: AppIconButtonSize.mini,
            onPressed: () => _delete(dimension),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingId == null
              ? l10n.movieWidgetAddDimension
              : l10n.movieWidgetEditDimension,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.medium,
          ),
        ),
        SizedBox(height: context.appSpacing.sm),
        AppTextField(
          fieldKey: const Key('rating-dimension-name-field'),
          controller: _nameController,
          hintText: l10n.movieWidgetDimensionNameHint,
        ),
        SizedBox(height: context.appSpacing.md),
        Row(
          children: [
            AppButton(
              label: l10n.commonSave,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.small,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            SizedBox(width: context.appSpacing.sm),
            AppTextButton(
              label: l10n.commonCancel,
              onPressed: _saving ? null : _cancelForm,
            ),
          ],
        ),
      ],
    );
  }
}
