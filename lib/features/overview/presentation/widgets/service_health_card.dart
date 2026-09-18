import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/external_data_source_status_chips.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';

/// 移动端「服务健康」卡：移动端没有组件诊断页，连通性状态收敛在这里，
/// 只保留可操作的项（重建索引 / 检测外部数据源）。
class ServiceHealthCard extends StatelessWidget {
  const ServiceHealthCard({
    super.key,
    required this.imageSearchStatus,
    required this.javdbHealthy,
    required this.isLoading,
    required this.isTestingExternalDataSources,
    required this.isRebuildingIndex,
    this.onTestExternalDataSources,
    this.onRebuildIndex,
  });

  final StatusImageSearchDto? imageSearchStatus;
  final bool? javdbHealthy;
  final bool isLoading;
  final bool isTestingExternalDataSources;
  final bool isRebuildingIndex;
  final VoidCallback? onTestExternalDataSources;
  final VoidCallback? onRebuildIndex;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppContentCard(
        key: const Key('mobile-service-health-card'),
        title: '服务健康',
        padding: EdgeInsets.all(context.appSpacing.lg),
        headerBottomSpacing: context.appSpacing.md,
        child: const OverviewCardLoadingBars(rows: 3),
      );
    }

    final requiresRebuild = imageSearchStatus?.indexSpace.requiresRebuild ?? false;
    final isRebuilding =
        isRebuildingIndex || (imageSearchStatus?.indexSpace.isRebuilding ?? false);

    return AppContentCard(
      key: const Key('mobile-service-health-card'),
      title: '服务健康',
      padding: EdgeInsets.all(context.appSpacing.lg),
      headerBottomSpacing: context.appSpacing.xs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HealthRow(
            label: '嵌入服务',
            value: embeddingServiceHealthLabel(imageSearchStatus),
            valueTone: embeddingServiceHealthTone(imageSearchStatus),
            rowKey: const Key('mobile-service-health-embedding'),
          ),
          const _HealthDivider(),
          _HealthRow(
            label: '图搜索索引',
            value: imageSearchIndexSpaceLabel(imageSearchStatus),
            valueTone: imageSearchIndexSpaceTone(imageSearchStatus),
            rowKey: const Key('mobile-service-health-index'),
            action: requiresRebuild || isRebuilding
                ? AppButton(
                    key: const Key('mobile-service-health-rebuild-button'),
                    label: isRebuilding ? '重建中' : '重建',
                    size: AppButtonSize.small,
                    isLoading: isRebuilding,
                    onPressed: isRebuilding ? null : onRebuildIndex,
                  )
                : null,
          ),
          const _HealthDivider(),
          _HealthRow(
            label: '外部数据源',
            rowKey: const Key('mobile-service-health-external'),
            valueWidget: ExternalDataSourceStatusChips(
              javdbHealthy: javdbHealthy,
              isTesting: isTestingExternalDataSources,
              keyPrefix: 'mobile-service-health',
            ),
            action: AppButton(
              key: const Key('mobile-service-health-test-button'),
              label: isTestingExternalDataSources ? '检测中' : '检测',
              size: AppButtonSize.small,
              isLoading: isTestingExternalDataSources,
              onPressed: isTestingExternalDataSources
                  ? null
                  : onTestExternalDataSources,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.rowKey,
    this.value,
    this.valueWidget,
    this.valueTone = AppTextTone.primary,
    this.action,
  });

  final String label;
  final Key rowKey;
  final String? value;
  final Widget? valueWidget;
  final AppTextTone valueTone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: rowKey,
      padding: EdgeInsets.symmetric(vertical: context.appSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s14,
                weight: AppTextWeight.regular,
                tone: AppTextTone.primary,
              ),
            ),
          ),
          SizedBox(width: context.appSpacing.sm),
          if (valueWidget != null)
            valueWidget!
          else
            Text(
              value ?? '',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s14,
                weight: AppTextWeight.medium,
                tone: valueTone,
              ),
            ),
          if (action != null) ...<Widget>[
            SizedBox(width: context.appSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class _HealthDivider extends StatelessWidget {
  const _HealthDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.appColors.divider,
    );
  }
}
