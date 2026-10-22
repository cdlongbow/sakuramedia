import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/activity/presentation/providers/notification_center_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/l10n/app_l10n.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/shell/app_version_info_card.dart';

/// 概览分支的侧滑抽屉：菜单分组 + 未读消息徽标 + 版本卡片。
///
/// 只负责展示与收起；点选后把菜单 key 交给 [onMenuSelected]（路由映射由
/// `lib/routes/mobile_routes.dart` 注入），避免壳层反向依赖具体路由。
class MobileOverviewDrawer extends ConsumerWidget {
  const MobileOverviewDrawer({
    super.key,
    required this.hostContext,
    required this.onMenuSelected,
  });

  /// 壳的宿主 context：抽屉关闭动画先于路由跳转，postFrame 里的跳转、
  /// 主题读取都以它为准。
  final BuildContext hostContext;
  final void Function(String key) onMenuSelected;

  static _MobileOverviewDrawerMenuItem _overviewItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'overview',
        icon: Icons.space_dashboard_outlined,
        label: l10n.shellNavOverview,
      );

  static _MobileOverviewDrawerMenuItem _favoritesItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'favorites',
        icon: Icons.favorite_border_rounded,
        label: l10n.shellNavFavorites,
      );

  static _MobileOverviewDrawerMenuItem _recentlyPlayedItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'recently-played',
    icon: Icons.play_circle_outline_rounded,
    label: l10n.shellNavRecentlyPlayed,
  );

  static _MobileOverviewDrawerMenuItem _recentViewsItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'recent-views',
    icon: Icons.visibility_outlined,
    label: l10n.shellNavRecentViews,
  );

  static _MobileOverviewDrawerMenuItem _ratingsItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'ratings',
        icon: Icons.star_outline_rounded,
        label: l10n.shellNavMyRatings,
      );

  static _MobileOverviewDrawerMenuItem _tagsItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'tags',
        icon: Icons.sell_outlined,
        label: l10n.shellNavTags,
      );

  static List<_MobileOverviewDrawerMenuItem> _libraryItems(
    AppLocalizations l10n,
  ) => <_MobileOverviewDrawerMenuItem>[
    _MobileOverviewDrawerMenuItem(
      key: 'media-libraries',
      icon: Icons.video_library_outlined,
      label: l10n.shellNavMediaLibraries,
    ),
    _MobileOverviewDrawerMenuItem(
      key: 'downloaders',
      icon: Icons.download_outlined,
      label: l10n.shellNavDownloaders,
    ),
    _MobileOverviewDrawerMenuItem(
      key: 'indexers',
      icon: Icons.travel_explore_outlined,
      label: l10n.shellNavIndexers,
    ),
  ];

  static _MobileOverviewDrawerMenuItem _mediaManagementItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'media-management',
    icon: Icons.video_settings_outlined,
    label: l10n.shellNavMediaManagement,
  );

  static _MobileOverviewDrawerMenuItem _mediaImportItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'media-import',
    icon: Icons.drive_folder_upload_outlined,
    label: l10n.shellNavMediaImport,
  );

  static _MobileOverviewDrawerMenuItem _downloadTasksItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'download-tasks',
    icon: Icons.download_for_offline_outlined,
    label: l10n.shellNavDownloadTasks,
  );

  static _MobileOverviewDrawerMenuItem _activityItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'activity',
        icon: Icons.bolt_outlined,
        label: l10n.shellNavTaskCenter,
      );

  static _MobileOverviewDrawerMenuItem _movieSubscriptionsItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'movie-subscriptions',
    icon: Icons.bookmark_added_outlined,
    label: l10n.shellNavSubscriptions,
  );

  static _MobileOverviewDrawerMenuItem _systemMaintenanceItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'system-maintenance',
    icon: Icons.build_outlined,
    label: l10n.shellNavSystemMaintenance,
  );

  static _MobileOverviewDrawerMenuItem _pluginsItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'plugins',
        icon: Icons.extension_outlined,
        label: l10n.shellNavPlugins,
      );

  static _MobileOverviewDrawerMenuItem _externalPlayerItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'external-player',
    icon: Icons.open_in_new_rounded,
    label: l10n.shellNavExternalPlayer,
  );

  static _MobileOverviewDrawerMenuItem _appearanceItem(AppLocalizations l10n) =>
      _MobileOverviewDrawerMenuItem(
        key: 'appearance',
        icon: Icons.palette_outlined,
        label: l10n.shellNavAppearance,
      );

  // 调用外部播放器仅在 Android 原生实现，其它平台不展示该入口。
  static bool get _supportsExternalPlayer =>
      defaultTargetPlatform == TargetPlatform.android;

  static _MobileOverviewDrawerMenuItem _accountSecurityItem(
    AppLocalizations l10n,
  ) => _MobileOverviewDrawerMenuItem(
    key: 'account-security',
    icon: Icons.security_rounded,
    label: l10n.shellNavAccountSecurity,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationCenterProvider.select((value) => value.unreadCount),
    );
    return _buildDrawer(context, unreadCount: unreadCount);
  }

  Widget _buildDrawer(BuildContext context, {required int unreadCount}) {
    final l10n = appL10n(context);
    final spacing = hostContext.appSpacing;

    return Drawer(
      key: const Key('mobile-overview-drawer'),
      backgroundColor: hostContext.appColors.surfacePage,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            spacing.lg,
            spacing.lg,
            spacing.lg,
            spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-overview-section',
                        ),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _overviewItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-collection-section',
                        ),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _favoritesItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _recentlyPlayedItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _recentViewsItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _ratingsItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-notifications-section',
                        ),
                        items: <Widget>[
                          _MobileOverviewDrawerItem(
                            key: const Key(
                              'mobile-overview-drawer-notifications',
                            ),
                            icon: Icons.notifications_none_rounded,
                            label: l10n.shellNavNotifications,
                            trailing: unreadCount > 0
                                ? AppBadge(
                                    key: const Key(
                                      'mobile-overview-drawer-notifications-badge',
                                    ),
                                    label: unreadCount > 99
                                        ? '99+'
                                        : '$unreadCount',
                                    tone: AppBadgeTone.error,
                                    size: AppBadgeSize.compact,
                                  )
                                : null,
                            onTap: () => _selectMenu(context, 'notifications'),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key('mobile-overview-drawer-tags-section'),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _tagsItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      if (_supportsExternalPlayer) ...[
                        _MobileOverviewDrawerSection(
                          key: const Key(
                            'mobile-overview-drawer-external-player-section',
                          ),
                          items: <Widget>[
                            _buildMenuEntry(
                              context: context,
                              item: _externalPlayerItem(l10n),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.md),
                      ],
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-library-section',
                        ),
                        items: _libraryItems(l10n)
                            .map(
                              (item) =>
                                  _buildMenuEntry(context: context, item: item),
                            )
                            .toList(growable: false),
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-management-section',
                        ),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _mediaManagementItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _mediaImportItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _downloadTasksItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _activityItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _movieSubscriptionsItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _systemMaintenanceItem(l10n),
                          ),
                          _buildMenuEntry(
                            context: context,
                            item: _pluginsItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-appearance-section',
                        ),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _appearanceItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      _MobileOverviewDrawerSection(
                        key: const Key(
                          'mobile-overview-drawer-account-section',
                        ),
                        items: <Widget>[
                          _buildMenuEntry(
                            context: context,
                            item: _accountSecurityItem(l10n),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.md),
                      const AppVersionInfoCard(
                        cardKey: Key('mobile-overview-drawer-version-card'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacing.md),
              _MobileOverviewDrawerSection(
                key: const Key('mobile-overview-drawer-bottom-actions'),
                items: <Widget>[
                  _MobileOverviewDrawerItem(
                    key: const Key('mobile-overview-drawer-logout'),
                    icon: Icons.logout_rounded,
                    label: l10n.shellLogout,
                    onTap: () => _selectMenu(context, 'logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuEntry({
    required BuildContext context,
    required _MobileOverviewDrawerMenuItem item,
  }) {
    return _MobileOverviewDrawerItem(
      key: Key('mobile-overview-drawer-${item.key}'),
      icon: item.icon,
      label: item.label,
      onTap: () => _selectMenu(context, item.key),
    );
  }

  /// 先收起抽屉，下一帧再交给宿主跳转（宿主 context 仍在时）。
  void _selectMenu(BuildContext context, String key) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hostContext.mounted) {
        return;
      }
      onMenuSelected(key);
    });
  }
}

class _MobileOverviewDrawerSection extends StatelessWidget {
  const _MobileOverviewDrawerSection({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final componentTokens = context.appComponentTokens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.lgBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.xs),
        child: Column(
          children: items
              .expand((item) {
                final itemIndex = items.indexOf(item);
                return <Widget>[
                  item,
                  if (itemIndex < items.length - 1)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start:
                            spacing.md +
                            componentTokens.iconSizeXl +
                            spacing.sm +
                            spacing.md,
                        end: spacing.md,
                      ),
                      child: Divider(
                        height: spacing.xs,
                        thickness: 1,
                        color: colors.borderSubtle.fadedBy(0.56),
                      ),
                    ),
                ];
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _MobileOverviewDrawerMenuItem {
  const _MobileOverviewDrawerMenuItem({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

class _MobileOverviewDrawerItem extends StatelessWidget {
  const _MobileOverviewDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final componentTokens = context.appComponentTokens;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: context.appRadius.lgBorder,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: componentTokens.iconSizeXl + spacing.sm,
                height: componentTokens.iconSizeXl + spacing.sm,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: context.appRadius.smBorder,
                ),
                child: Icon(
                  icon,
                  size: componentTokens.iconSizeMd,
                  color: context.appTextPalette.primary,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Text(
                  label,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s14,
                    weight: AppTextWeight.medium,
                    tone: AppTextTone.primary,
                  ),
                ),
              ),
              if (trailing != null) ...[SizedBox(width: spacing.sm), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
