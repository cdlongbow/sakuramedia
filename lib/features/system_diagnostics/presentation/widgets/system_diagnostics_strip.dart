import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/core/format/relative_time_label.dart';
import 'package:sakuramedia/features/system_diagnostics/data/diagnostic_item_status.dart';
import 'package:sakuramedia/features/system_diagnostics/presentation/controllers/system_diagnostics_controller.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';

/// 概览页顶部的组件诊断状态行。
///
/// 不再占一张卡：未检测 / 正常时只占一行，异常时才升级为带语义底色的提示条。
/// 详情和分项结果都在独立的诊断页，这里只保留一眼可读的状态与两个动作
/// （重新检测 / 进入诊断页）。
///
/// Strip 通过 autoDispose family provider 持有自己的诊断会话；诊断页使用另一
/// host 参数，所以两处状态互不共享。用户可以在 strip 看一眼，再进入诊断页运行
/// 独立的一次完整检测。
class SystemDiagnosticsStrip extends ConsumerStatefulWidget {
  const SystemDiagnosticsStrip({super.key});

  @override
  ConsumerState<SystemDiagnosticsStrip> createState() =>
      _SystemDiagnosticsStripState();
}

enum _StripAlertTone { none, warning, error }

class _SystemDiagnosticsStripState
    extends ConsumerState<SystemDiagnosticsStrip> {
  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final controller = ref.watch(
      systemDiagnosticsProvider(SystemDiagnosticsHost.overviewStrip),
    );
    final alertTone = _alertTone(controller);

    return Container(
      key: const Key('system-diagnostics-strip'),
      padding: alertTone == _StripAlertTone.none
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
      decoration: switch (alertTone) {
        _StripAlertTone.none => null,
        _StripAlertTone.warning => BoxDecoration(
          color: context.appColors.warningSurface,
          borderRadius: context.appRadius.mdBorder,
          border: Border.all(
            color: context.appTextPalette.warning.withValues(alpha: 0.18),
          ),
        ),
        _StripAlertTone.error => BoxDecoration(
          color: context.appColors.errorSurface,
          borderRadius: context.appRadius.mdBorder,
          border: Border.all(
            color: context.appTextPalette.error.withValues(alpha: 0.18),
          ),
        ),
      },
      child: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, SystemDiagnosticsState c) {
    final spacing = context.appSpacing;
    if (c.isRunning) {
      return Row(
        children: [
          SizedBox(
            width: context.appComponentTokens.iconSizeSm,
            height: context.appComponentTokens.iconSizeSm,
            child: CircularProgressIndicator.adaptive(
              strokeWidth:
                  context.appComponentTokens.movieCardLoaderStrokeWidth,
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              '正在检测组件 ${c.completedItemCount}/${c.totalItemCount}…',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                weight: AppTextWeight.regular,
                tone: AppTextTone.secondary,
              ),
            ),
          ),
        ],
      );
    }

    final status = _statusPresentation(context, c);
    final actions = <Widget>[
      if (c.lastRunAt != null)
        AppIconButton(
          key: const Key('system-diagnostics-strip-refresh'),
          tooltip: '重新检测',
          semanticLabel: '重新检测',
          size: AppIconButtonSize.mini,
          icon: const Icon(Icons.refresh),
          onPressed: _runAll,
        ),
      SizedBox(width: spacing.xs),
      AppIconButton(
        key: const Key('system-diagnostics-strip-open'),
        tooltip: '打开组件诊断页',
        semanticLabel: '打开组件诊断页',
        size: AppIconButtonSize.mini,
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => context.pushDesktopSystemDiagnostics(),
      ),
    ];

    return Row(
      children: [
        Icon(
          status.icon,
          size: context.appComponentTokens.iconSizeSm,
          color: status.color,
        ),
        SizedBox(width: spacing.sm),
        Text(
          '组件诊断',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.medium,
            tone: AppTextTone.secondary,
          ),
        ),
        SizedBox(width: spacing.sm),
        Text(
          status.label,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.semibold,
          ).copyWith(color: status.color),
        ),
        if (c.lastRunAt != null) ...[
          SizedBox(width: spacing.sm),
          Text(
            '· ${formatRelativeTimeLabel(c.lastRunAt!, suffix: '检测')}',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.regular,
              tone: AppTextTone.muted,
            ),
          ),
        ],
        const Spacer(),
        if (c.lastRunAt == null) ...[
          SizedBox(width: spacing.md),
          AppButton(
            key: const Key('system-diagnostics-strip-start'),
            label: '开始检测',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.xSmall,
            onPressed: _runAll,
          ),
        ],
        ...actions,
      ],
    );
  }

  void _runAll() {
    ref
        .read(
          systemDiagnosticsProvider(
            SystemDiagnosticsHost.overviewStrip,
          ).notifier,
        )
        .runAll();
  }

  _StripAlertTone _alertTone(SystemDiagnosticsState c) {
    if (c.isRunning || c.lastRunAt == null) {
      return _StripAlertTone.none;
    }
    if (c.unhealthyCount > 0 ||
        c.overallStatus == DiagnosticItemStatus.unhealthy) {
      return _StripAlertTone.error;
    }
    if (c.overallStatus == DiagnosticItemStatus.warning ||
        c.overallStatus == DiagnosticItemStatus.blocked) {
      return _StripAlertTone.warning;
    }
    return _StripAlertTone.none;
  }

  ({IconData icon, Color color, String label}) _statusPresentation(
    BuildContext context,
    SystemDiagnosticsState c,
  ) {
    if (c.lastRunAt == null) {
      return (
        icon: Icons.radio_button_unchecked,
        color: context.appTextPalette.muted,
        label: '未检测',
      );
    }
    if (c.unhealthyCount > 0 ||
        c.overallStatus == DiagnosticItemStatus.unhealthy) {
      return (
        icon: Icons.error_outline,
        color: context.appTextPalette.error,
        label: '${c.unhealthyCount > 0 ? c.unhealthyCount : 1} 项异常',
      );
    }
    if (c.overallStatus == DiagnosticItemStatus.warning ||
        c.overallStatus == DiagnosticItemStatus.blocked) {
      return (
        icon: Icons.warning_amber_rounded,
        color: context.appTextPalette.warning,
        label: '有警告',
      );
    }
    if (c.overallStatus == DiagnosticItemStatus.disabled ||
        c.overallStatus == DiagnosticItemStatus.notTested) {
      return (
        icon: Icons.radio_button_unchecked,
        color: context.appTextPalette.muted,
        label: '部分未检测',
      );
    }
    return (
      icon: Icons.check_circle_outline,
      color: context.appTextPalette.success,
      label: '全部通过',
    );
  }
}
