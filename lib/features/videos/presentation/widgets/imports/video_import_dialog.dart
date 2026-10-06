import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media_import/data/media_import_source.dart';
import 'package:sakuramedia/features/videos/data/dto/video_collection_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_collections_overview_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/create_video_collection_dialog.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/pick_video_collection_single_dialog.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/domain/media_import/media_import_source_picker.dart';
import 'package:sakuramedia/widgets/domain/media_import/media_library_selector_field.dart';

/// Provider-neutral 视频导入表单结果。
class VideoImportRequest {
  const VideoImportRequest({
    required this.libraryId,
    required this.source,
    required this.sourceDisposition,
    required this.collectionId,
  });

  final int libraryId;
  final MediaImportSource source;
  final SourceDisposition sourceDisposition;
  final int? collectionId;
}

/// 打开视频导入对话框；用户确认后返回 [VideoImportRequest]，取消返回 `null`。
Future<VideoImportRequest?> showVideoImportDialog(BuildContext context) {
  return showAppAdaptiveModal<VideoImportRequest>(
    context: context,
    modalKey: const Key('video-import-modal'),
    builder: (_) => const VideoImportDialog(),
  );
}

class VideoImportDialog extends ConsumerStatefulWidget {
  const VideoImportDialog({super.key});

  @override
  ConsumerState<VideoImportDialog> createState() => _VideoImportDialogState();
}

class _VideoImportDialogState extends ConsumerState<VideoImportDialog> {
  MediaLibraryDto? _selectedLibrary;
  MediaImportSource? _source;
  SourceDisposition _sourceDisposition = SourceDisposition.keep;

  List<VideoCollectionDto> _collections = const <VideoCollectionDto>[];
  int? _collectionId;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      // 与合集列表页共用 overview 缓存，减少一次全量拉取。
      final collections = await ref.read(
        videoCollectionsOverviewProvider.future,
      );
      if (mounted) {
        setState(() => _collections = collections);
      }
    } catch (_) {
      // 合集加载失败不阻塞浏览，用户仍可现场「新建合集」后再导入。
    }
  }

  Future<void> _pickCollection() async {
    final result = await showPickVideoCollectionSingleDialog(
      context,
      selectedCollectionId: _collectionId,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _collectionId = result.collectionId);
  }

  Future<void> _createCollection() async {
    final created = await showVideoCollectionDialog(
      context,
      presentation: AppPlatformScope.maybeOf(context) == AppPlatform.mobile
          ? VideoCollectionEditPresentation.bottomDrawer
          : VideoCollectionEditPresentation.dialog,
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      _collections = <VideoCollectionDto>[..._collections, created];
      _collectionId = created.id;
    });
    // 同步 overview 缓存：其后打开的单选弹层复用同一份缓存，才不会漏掉刚建的合集。
    await ref.read(videoCollectionsOverviewProvider.notifier).refresh();
  }

  void _handleLibraryChanged(MediaLibraryDto? library) {
    setState(() {
      _selectedLibrary = library;
      _source = null;
      _sourceDisposition = SourceDisposition.keep;
    });
  }

  void _submit() {
    final library = _selectedLibrary;
    final source = _source;
    if (library == null || source == null) {
      return;
    }
    Navigator.of(context).pop(
      VideoImportRequest(
        libraryId: library.id,
        source: source,
        sourceDisposition: _sourceDisposition,
        collectionId: _collectionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 维持合集 overview 存活：嵌套的单选弹层复用同一份缓存，不重复全量拉取。
    ref.listen(videoCollectionsOverviewProvider, (_, _) {});
    final spacing = context.appSpacing;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入视频',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s16,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.primary,
            ),
          ),
          SizedBox(height: spacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MediaLibrarySelectorField(
                    selectedLibraryId: _selectedLibrary?.id,
                    onLibraryChanged: _handleLibraryChanged,
                  ),
                  if (_selectedLibrary != null) ...[
                    SizedBox(height: spacing.md),
                    MediaImportSourcePicker(
                      selectedLibrary: _selectedLibrary,
                      sourceDisposition: _sourceDisposition,
                      allowFileSource: true,
                      onSourceChanged: (source) {
                        if (source == _source) {
                          return;
                        }
                        setState(() => _source = source);
                      },
                      onSourceDispositionChanged: (disposition) {
                        if (disposition == _sourceDisposition) {
                          return;
                        }
                        setState(() => _sourceDisposition = disposition);
                      },
                    ),
                  ],
                  SizedBox(height: spacing.lg),
                  _buildCollectionField(context),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '取消',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: AppButton(
                  key: const Key('video-import-submit-button'),
                  label: '开始导入',
                  variant: AppButtonVariant.primary,
                  onPressed: _selectedLibrary != null && _source != null
                      ? _submit
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionField(BuildContext context) {
    String? selectedName;
    if (_collectionId != null) {
      selectedName = '已选合集';
      for (final collection in _collections) {
        if (collection.id == _collectionId) {
          selectedName = collection.name;
          break;
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '加入合集（可选）',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.secondary,
              ),
            ),
            const Spacer(),
            AppTextButton(
              key: const Key('video-import-create-collection-button'),
              label: '新建合集',
              size: AppTextButtonSize.small,
              onPressed: _createCollection,
            ),
          ],
        ),
        SizedBox(height: context.appSpacing.sm),
        _CollectionPickerField(
          valueLabel: selectedName,
          onTap: _pickCollection,
        ),
      ],
    );
  }
}

/// 只读合集选择触发条：外观对齐 `AppSelectField`，点击打开可搜索单选弹层。
class _CollectionPickerField extends StatelessWidget {
  const _CollectionPickerField({required this.valueLabel, required this.onTap});

  final String? valueLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final formTokens = context.appFormTokens;
    final label = valueLabel?.trim() ?? '';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const Key('video-import-collection-field'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: formTokens.fieldHorizontalPadding,
            vertical: formTokens.fieldVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: context.appRadius.smBorder,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.isEmpty ? '不加入合集' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s14,
                    tone: label.isEmpty
                        ? AppTextTone.muted
                        : AppTextTone.primary,
                  ),
                ),
              ),
              SizedBox(width: context.appSpacing.sm),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: context.appComponentTokens.iconSizeSm,
                color: context.appTextPalette.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
