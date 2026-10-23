import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/actors/presentation/controllers/listing/actor_filter_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_form_sheet.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_avatar.dart';

/// 影片演员表的添加弹层：搜索女优库、多选，或原地新建本地女优。
///
/// 返回值只包含用户选中的演员；真正写入影片关联由调用方统一处理。
Future<List<ActorListItemDto>?> showMovieActorPickerSheet(
  BuildContext context, {
  required ActorsApi actorsApi,
  required Set<int> existingActorIds,
}) {
  return showAppAdaptiveModal<List<ActorListItemDto>>(
    context: context,
    modalKey: const Key('movie-actor-picker'),
    desktopWidth: context.appLayoutTokens.dialogWidthMd,
    builder: (_) => MovieActorPickerSheet(
      actorsApi: actorsApi,
      existingActorIds: existingActorIds,
    ),
  );
}

enum _PickerMode { pick, create }

/// 搜索态与新建态共用固定主体高度，避免搜索状态切换时弹窗上下跳动。
const double _pickerBodyHeight = 380;

class MovieActorPickerSheet extends StatefulWidget {
  const MovieActorPickerSheet({
    super.key,
    required this.actorsApi,
    required this.existingActorIds,
  });

  final ActorsApi actorsApi;
  final Set<int> existingActorIds;

  @override
  State<MovieActorPickerSheet> createState() => _MovieActorPickerSheetState();
}

class _MovieActorPickerSheetState extends State<MovieActorPickerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _createNameController = TextEditingController();
  final _createAliasController = TextEditingController();
  final Map<int, ActorListItemDto> _selected = <int, ActorListItemDto>{};

  _PickerMode _mode = _PickerMode.pick;
  Timer? _debounce;
  int _searchRequestId = 0;
  List<ActorListItemDto> _candidates = const <ActorListItemDto>[];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isCreating = false;
  String? _searchErrorMessage;
  String? _createErrorMessage;

  String get _query => _searchController.text.trim();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _createNameController.dispose();
    _createAliasController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _searchRequestId++;
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _candidates = const <ActorListItemDto>[];
        _hasSearched = false;
        _isSearching = false;
        _searchErrorMessage = null;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search(query)),
    );
  }

  Future<void> _search(String query) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });
    try {
      final page = await widget.actorsApi.getActors(
        query: query,
        pageSize: 20,
        subscriptionStatus: ActorSubscriptionStatus.all,
        gender: ActorGender.all,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _candidates = page.items;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _hasSearched = true;
        _isSearching = false;
        _searchErrorMessage = apiErrorMessage(error, fallback: '搜索演员失败，请稍后重试');
      });
    }
  }

  void _toggleCandidate(ActorListItemDto candidate, bool? selected) {
    setState(() {
      if (selected == true) {
        _selected[candidate.id] = candidate;
      } else {
        _selected.remove(candidate.id);
      }
    });
  }

  void _enterCreate([String? query]) {
    final seed = (query ?? _query).trim();
    _createNameController.text = seed;
    _createAliasController.clear();
    setState(() {
      _mode = _PickerMode.create;
      _createErrorMessage = null;
    });
  }

  void _backToPick() {
    setState(() {
      _mode = _PickerMode.pick;
      _createErrorMessage = null;
    });
  }

  void _submitPick() {
    if (_selected.isEmpty) return;
    Navigator.of(
      context,
    ).pop(List<ActorListItemDto>.unmodifiable(_selected.values));
  }

  Future<void> _submitCreate() async {
    if (_isCreating) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isCreating = true;
      _createErrorMessage = null;
    });
    try {
      final created = await widget.actorsApi.createLocalActor(
        name: _createNameController.text,
        aliasName: _createAliasController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(<ActorListItemDto>[created.summary]);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _createErrorMessage = apiErrorMessage(error, fallback: '新建女优失败，请稍后重试');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = _mode == _PickerMode.create;
    return AppBottomFormSheet(
      key: const Key('movie-actor-picker-form'),
      formKey: _formKey,
      title: isCreate ? '新建本地女优' : '添加演员',
      subtitle: isCreate ? '创建后会自动加入本片演员表。' : '从女优库中选择，或新建一位本地女优。',
      submitKey: Key(
        isCreate ? 'movie-actor-create-confirm' : 'movie-actor-picker-confirm',
      ),
      submitLabel: isCreate
          ? '创建并添加'
          : (_selected.isEmpty ? '添加演员' : '添加 ${_selected.length} 位演员'),
      isSubmitting: _isCreating,
      submitDisabled: !isCreate && _selected.isEmpty,
      onSubmit: () {
        if (isCreate) {
          unawaited(_submitCreate());
        } else {
          _submitPick();
        }
      },
      body: isCreate ? _buildCreateBody(context) : _buildPickBody(context),
    );
  }

  Widget _buildPickBody(BuildContext context) {
    final spacing = context.appSpacing;
    final query = _query;
    return SizedBox(
      height: _pickerBodyHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('movie-actor-picker-search-field'),
            controller: _searchController,
            label: '搜索演员',
            hintText: '输入名字搜索女优库',
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onFieldSubmitted: (value) {
              _debounce?.cancel();
              final normalized = value.trim();
              if (normalized.isNotEmpty) {
                unawaited(_search(normalized));
              }
            },
          ),
          SizedBox(height: spacing.md),
          Expanded(child: _buildResults(context, query)),
          if (_selected.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              '已选 ${_selected.length} 位：${_selected.values.map((item) => item.displayName).join('、')}',
              key: const Key('movie-actor-picker-selection-summary'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.secondary,
              ),
            ),
          ],
          if (_searchErrorMessage != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              _searchErrorMessage!,
              key: const Key('movie-actor-picker-search-error'),
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, String query) {
    final spacing = context.appSpacing;
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchErrorMessage != null) {
      return const SizedBox.shrink();
    }
    if (!_hasSearched) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          '输入名字开始搜索',
          key: const Key('movie-actor-picker-hint'),
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
      );
    }
    if (_candidates.isEmpty) {
      return Column(
        key: const Key('movie-actor-picker-empty'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '未找到匹配的演员',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.muted,
            ),
          ),
          if (query.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            AppButton(
              key: const Key('movie-actor-picker-create-entry'),
              label: '新建本地女优「$query」',
              icon: const Icon(Icons.person_add_alt_1_rounded),
              size: AppButtonSize.small,
              onPressed: () => _enterCreate(query),
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _candidates.length,
            itemBuilder: (context, index) =>
                _buildCandidateTile(context, _candidates[index]),
          ),
        ),
        if (query.isNotEmpty) ...[
          SizedBox(height: spacing.xs),
          AppTextButton(
            key: const Key('movie-actor-picker-create-entry'),
            label: '没找到？新建本地女优',
            size: AppTextButtonSize.xSmall,
            emphasis: AppTextButtonEmphasis.accent,
            onPressed: () => _enterCreate(query),
          ),
        ],
      ],
    );
  }

  Widget _buildCandidateTile(BuildContext context, ActorListItemDto candidate) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final isExisting = widget.existingActorIds.contains(candidate.id);
    final isSelected = _selected.containsKey(candidate.id);
    return CheckboxListTile(
      key: Key('movie-actor-picker-candidate-${candidate.id}'),
      value: isExisting || isSelected,
      onChanged: isExisting
          ? null
          : (value) => _toggleCandidate(candidate, value),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
      secondary: ActorAvatar(
        imageUrl: candidate.profileImage?.origin,
        size: tokens.iconSize2xl,
        placeholderKey: Key(
          'movie-actor-picker-avatar-placeholder-${candidate.id}',
        ),
      ),
      title: Text(
        candidate.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s14,
          tone: AppTextTone.primary,
        ),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              candidate.isLocal ? '本地女优' : candidate.javdbId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
          ),
          if (isExisting) ...[
            SizedBox(width: spacing.xs),
            const AppBadge(label: '已在演员表', size: AppBadgeSize.compact),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateBody(BuildContext context) {
    final spacing = context.appSpacing;
    return SizedBox(
      height: _pickerBodyHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppTextButton(
              key: const Key('movie-actor-create-back'),
              label: '返回选择',
              icon: Icon(
                Icons.arrow_back_rounded,
                size: context.appComponentTokens.iconSizeXs,
              ),
              size: AppTextButtonSize.xSmall,
              onPressed: _isCreating ? null : _backToPick,
            ),
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            fieldKey: const Key('movie-actor-create-name-field'),
            controller: _createNameController,
            label: '姓名',
            hintText: '请输入女优姓名',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return '请输入女优姓名';
              if (name.length > 255) return '姓名不能超过 255 个字符';
              return null;
            },
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            fieldKey: const Key('movie-actor-create-alias-field'),
            controller: _createAliasController,
            label: '别名（可选）',
            hintText: '例如：别名A / 别名B',
            helperText: '多个别名用 / 分隔，可留空',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final alias = value?.trim() ?? '';
              if (alias.length > 1024) return '别名不能超过 1024 个字符';
              return null;
            },
          ),
          if (_createErrorMessage != null) ...[
            SizedBox(height: spacing.sm),
            Text(
              _createErrorMessage!,
              key: const Key('movie-actor-create-error'),
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
