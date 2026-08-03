import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_profile_state.dart';

part 'account_profile_provider.g.dart';

/// 账号资料（用户名/创建时间/上次登录）+ 修改用户名。
///
/// keepAlive：账号资料是全局共享数据（configuration 桌面段 + mobile 改用户名页
/// 都消费）；首次加载后跨页保留，切换 tab 不重拉。登出时随 ProviderScope 拆掉。
///
/// 迁移前对应：`AccountProfileController`（configuration section + mobile
/// change_username page 两处各自 late final 构造）。四态复合（account /
/// isLoading / isSaving / errorMessage）AsyncValue 表达不了，故用同步 Notifier +
/// 显式 [AccountProfileState]（对齐批 2 `OverviewSystemInfo` 样板）。
@Riverpod(keepAlive: true)
class AccountProfile extends _$AccountProfile {
  @override
  AccountProfileState build() {
    // build 完立即触发首次加载；同步返回带 isLoading=true 的初始 state 让 UI 显骨架。
    Future.microtask(load);
    return const AccountProfileState(isLoading: true);
  }

  Future<void> load() async {
    if (state.isLoading && state.account != null) {
      // 已在加载中且有旧数据：避免并发重复。首次 build 完的 microtask 走此分支不短路。
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await ref.read(accountApiProvider).getAccount();
      state = state.copyWith(account: account, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: apiErrorMessage(error, fallback: '账号资料加载失败，请稍后重试'),
      );
    }
  }

  /// 修改用户名。成功返回 true 并更新本地 [AccountProfileState.account]；失败返回
  /// false 并把错误消息写进 [AccountProfileState.errorMessage] 供 UI 展示。
  ///
  /// 空值 / 未变化都是「客户端拒绝」，直接写 [AccountProfileState.errorMessage]
  /// 不发请求，返回 false。
  Future<bool> saveUsername(String username) async {
    if (state.isSaving) {
      return false;
    }

    final normalized = username.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(errorMessage: '请输入用户名');
      return false;
    }
    if (normalized == (state.account?.username.trim() ?? '')) {
      state = state.copyWith(errorMessage: '用户名未变化');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final updated =
          await ref.read(accountApiProvider).updateUsername(normalized);
      state = state.copyWith(account: updated, isSaving: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: accountProfileErrorMessage(error, fallback: '修改用户名失败'),
      );
      return false;
    }
  }
}

/// 把账号资料相关的错误翻译成用户可读文案，特化 `username_conflict`。
String accountProfileErrorMessage(Object error, {required String fallback}) {
  if (error is ApiException && error.error?.code == 'username_conflict') {
    return '用户名已存在，请换一个名称';
  }
  return apiErrorMessage(error, fallback: fallback);
}
