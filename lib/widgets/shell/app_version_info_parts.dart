import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/providers/external_url_provider.dart';
import 'package:sakuramedia/config/app_release_channels.dart';
import 'package:sakuramedia/core/platform/clipboard_copy.dart';
import 'package:sakuramedia/theme.dart';

/// 版本信息的一行（label + 右对齐值），版本卡片与侧栏版本弹窗共用。
class AppVersionRow extends StatelessWidget {
  const AppVersionRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(width: context.appSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.medium,
              tone: AppTextTone.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 「发现可用更新」提示块（客户端 / 服务端 / 插件数量），版本卡片与侧栏
/// 版本弹窗共用，避免两处维护同一段文案与样式。
class AppVersionUpdateNotice extends ConsumerWidget {
  const AppVersionUpdateNotice({
    super.key,
    required this.frontendUpdateVersion,
    required this.backendUpdateVersion,
    required this.pluginUpdateCount,
  });

  final String? frontendUpdateVersion;
  final String? backendUpdateVersion;
  final int pluginUpdateCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = <String>[
      if (frontendUpdateVersion != null) '客户端 $frontendUpdateVersion',
      if (backendUpdateVersion != null) '服务端 $backendUpdateVersion',
      if (pluginUpdateCount > 0) '$pluginUpdateCount 个插件',
    ].join(' · ');

    return Container(
      key: const Key('sidebar-update-notice'),
      padding: EdgeInsets.all(context.appSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.selectionSurface,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.accent,
              ),
              SizedBox(width: context.appSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现可用更新',
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s12,
                        weight: AppTextWeight.medium,
                        tone: AppTextTone.accent,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.xs),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s10,
                        tone: AppTextTone.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (frontendUpdateVersion != null) ...[
            SizedBox(height: context.appSpacing.sm),
            _ReleaseLink(
              key: const Key('version-release-link-frontend'),
              label: '客户端发布页',
              onTap: () => unawaited(
                _openRelease(context, ref, AppReleaseChannels.frontendPageUrl),
              ),
            ),
          ],
          if (backendUpdateVersion != null) ...[
            SizedBox(height: context.appSpacing.xs),
            _ReleaseLink(
              key: const Key('version-release-link-backend'),
              label: '服务端发布页',
              onTap: () => unawaited(
                _openRelease(context, ref, AppReleaseChannels.backendPageUrl),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openRelease(
  BuildContext context,
  WidgetRef ref,
  String url,
) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  final opened = await ref.read(externalUrlOpenerProvider)(uri);
  if (opened || !context.mounted) {
    return;
  }
  final copied = await copyTextToClipboard(url);
  if (!context.mounted) {
    return;
  }
  showToast(copied ? '无法打开浏览器，链接已复制' : '无法打开浏览器');
}

class _ReleaseLink extends StatelessWidget {
  const _ReleaseLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Semantics(
      link: true,
      label: '打开$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: context.appRadius.smBorder,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: context.appColors.surfaceCard,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xs),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.accent,
                  ),
                ),
              ),
              SizedBox(width: spacing.xs),
              Icon(
                Icons.open_in_new_rounded,
                size: context.appComponentTokens.iconSize3xs,
                color: context.appTextPalette.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
