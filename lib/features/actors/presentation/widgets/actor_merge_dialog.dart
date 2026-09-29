import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_detail_dto.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/actors/presentation/controllers/listing/actor_filter_state.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_form_sheet.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_avatar.dart';

class ActorMergeResult {
  const ActorMergeResult({required this.actor, required this.sourceActorIds});

  final ActorDetailDto actor;
  final List<int> sourceActorIds;
}

Future<ActorMergeResult?> showActorMergeDialog(
  BuildContext context, {
  required ActorDetailDto actor,
  required ActorsApi api,
}) {
  return showAppAdaptiveModal<ActorMergeResult>(
    context: context,
    modalKey: const Key('actor-merge-dialog'),
    desktopWidth: context.appLayoutTokens.dialogWidthMd,
    builder: (_) => ActorMergeDialog(actor: actor, api: api),
  );
}

class ActorMergeDialog extends StatefulWidget {
  const ActorMergeDialog({super.key, required this.actor, required this.api});

  final ActorDetailDto actor;
  final ActorsApi api;

  @override
  State<ActorMergeDialog> createState() => _ActorMergeDialogState();
}

class _ActorMergeDialogState extends State<ActorMergeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final Map<int, ActorListItemDto> _selected = <int, ActorListItemDto>{};

  Timer? _debounce;
  List<ActorListItemDto> _candidates = const <ActorListItemDto>[];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _isSubmitting = false;
  String? _searchErrorMessage;
  String? _submitErrorMessage;

  int get _targetActorId => widget.actor.summary.id;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
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
    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });
    try {
      final page = await widget.api.getActors(
        query: query,
        pageSize: 20,
        subscriptionStatus: ActorSubscriptionStatus.all,
        gender: ActorGender.all,
      );
      if (!mounted) return;
      setState(() {
        _candidates = page.items
            .where((item) => item.id != _targetActorId)
            .toList(growable: false);
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _hasSearched = true;
        _isSearching = false;
        _searchErrorMessage = apiErrorMessage(
          error,
          fallback: '搜索女优失败，请稍后重试',
        );
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

  Future<void> _submit() async {
    if (_isSubmitting || _selected.isEmpty) return;
    final sourceActorIds = List<int>.unmodifiable(_selected.keys);
    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = null;
    });
    try {
      final merged = await widget.api.mergeActors(
        actorId: _targetActorId,
        sourceActorIds: sourceActorIds,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        ActorMergeResult(actor: merged, sourceActorIds: sourceActorIds),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitErrorMessage = apiErrorMessage(
          error,
          fallback: '合并女优失败，请稍后重试',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomFormSheet(
      key: const Key('actor-merge-form'),
      formKey: _formKey,
      title: '合并女优',
      subtitle: '当前女优作为保留方；所选女优的影片、订阅与别名将并入当前女优，且不可撤销。',
      submitKey: const Key('actor-merge-confirm-button'),
      submitLabel: _selected.isEmpty ? '合并' : '合并 ${_selected.length} 位女优',
      isSubmitting: _isSubmitting,
      submitDisabled: _selected.isEmpty,
      onSubmit: () => unawaited(_submit()),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          fieldKey: const Key('actor-merge-search-field'),
          controller: _searchController,
          label: '搜索要合并进来的女优',
          hintText: '输入名字，从下方结果中勾选',
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onFieldSubmitted: (value) {
            _debounce?.cancel();
            final query = value.trim();
            if (query.isNotEmpty) {
              unawaited(_search(query));
            }
          },
        ),
        SizedBox(height: spacing.md),
        _buildResults(context),
        if (_selected.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          Text(
            '已选 ${_selected.length} 位：${_selected.values.map((item) => item.displayName).join('、')}',
            key: const Key('actor-merge-selection-summary'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.secondary,
            ),
          ),
        ],
        if (_submitErrorMessage != null) ...[
          SizedBox(height: spacing.sm),
          Text(
            _submitErrorMessage!,
            key: const Key('actor-merge-error'),
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_isSearching) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_searchErrorMessage != null) {
      return Text(
        _searchErrorMessage!,
        key: const Key('actor-merge-search-error'),
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          tone: AppTextTone.secondary,
        ),
      );
    }
    if (!_hasSearched) {
      return const SizedBox.shrink();
    }
    if (_candidates.isEmpty) {
      return Text(
        '未找到匹配的女优',
        key: const Key('actor-merge-empty'),
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          tone: AppTextTone.muted,
        ),
      );
    }
    return SizedBox(
      height: 260,
      child: ListView.builder(
        itemCount: _candidates.length,
        itemBuilder: (context, index) {
          final candidate = _candidates[index];
          final isSelected = _selected.containsKey(candidate.id);
          return CheckboxListTile(
            key: Key('actor-merge-candidate-${candidate.id}'),
            value: isSelected,
            onChanged: (value) => _toggleCandidate(candidate, value),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding: EdgeInsets.zero,
            secondary: ActorAvatar(
              imageUrl: candidate.profileImage?.origin,
              size: context.appComponentTokens.iconSize2xl,
              placeholderKey: Key(
                'actor-merge-candidate-avatar-placeholder-${candidate.id}',
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
            subtitle: Text(
              candidate.javdbId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
          );
        },
      ),
    );
  }
}
