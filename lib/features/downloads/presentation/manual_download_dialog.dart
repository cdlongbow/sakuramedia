import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/configuration/data/dto/download_client_dto.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/configuration_tab_request_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/download_clients_provider.dart';
import 'package:sakuramedia/features/downloads/data/download_request_dto.dart';
import 'package:sakuramedia/features/downloads/data/downloads_api.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/series_import/movie_search_stream_update.dart';
import 'package:sakuramedia/features/movies/data/movie_number_matcher.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/shared/presentation/file_picker_with_bytes.dart';
import 'package:sakuramedia/features/videos/data/dto/video_collection_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_collections_overview_provider.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/create_video_collection_dialog.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/pick_video_collection_single_dialog.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_switch.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_error_banner.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_spinner.dart';
import 'package:sakuramedia/widgets/base/forms/app_select_field.dart';
import 'package:sakuramedia/widgets/base/forms/app_text_field.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';

enum _ManualDownloadSource { magnet, torrent }

/// 手动提交成功后的返回值；`clientName` 用于页面 toast。
class ManualDownloadResult {
  const ManualDownloadResult({
    required this.response,
    required this.clientName,
  });

  final DownloadRequestResponseDto response;
  final String clientName;
}

/// 打开手动添加下载表单：桌面居中弹窗，移动端底部抽屉。
Future<ManualDownloadResult?> showManualDownloadDialog(
  BuildContext hostContext,
) {
  return showAppAdaptiveModal<ManualDownloadResult>(
    context: hostContext,
    modalKey: const Key('manual-download-modal'),
    desktopWidth: hostContext.appLayoutTokens.dialogWidthMd,
    mobileHeightFactor: 0.9,
    builder: (_) => _ManualDownloadDialog(hostContext: hostContext),
  );
}

enum _MovieResolutionPhase { idle, resolving, resolved, failed }

enum _MovieResolutionSource { local, online }

@immutable
class _MovieResolution {
  const _MovieResolution.idle({this.rawInput = ''})
    : phase = _MovieResolutionPhase.idle,
      parsedNumber = null,
      message = null,
      movie = null,
      source = null;

  const _MovieResolution.resolving({
    required this.rawInput,
    this.parsedNumber,
    required this.message,
  }) : phase = _MovieResolutionPhase.resolving,
       movie = null,
       source = null;

  const _MovieResolution.resolved({
    required this.rawInput,
    required this.parsedNumber,
    required this.movie,
    required this.source,
  }) : phase = _MovieResolutionPhase.resolved,
       message = null;

  const _MovieResolution.failed({
    required this.rawInput,
    required this.message,
    this.parsedNumber,
  }) : phase = _MovieResolutionPhase.failed,
       movie = null,
       source = null;

  final _MovieResolutionPhase phase;

  /// 发起查询时的输入文本（trim 后），用于判断结果是否已过期。
  final String rawInput;

  /// parse-number 返回的查找键；可能不是最终规范番号。
  final String? parsedNumber;

  /// 进度或错误文案。
  final String? message;

  /// 仅在 resolved 阶段有值。
  final MovieListItemDto? movie;

  final _MovieResolutionSource? source;

  bool get isResolving => phase == _MovieResolutionPhase.resolving;

  bool get isResolved =>
      phase == _MovieResolutionPhase.resolved && movie != null;
}

class _ManualDownloadDialog extends ConsumerStatefulWidget {
  const _ManualDownloadDialog({required this.hostContext});

  /// 打开弹层的页面 context；弹层自身 context 在 pop 后失效，导航要用它。
  final BuildContext hostContext;

  @override
  ConsumerState<_ManualDownloadDialog> createState() =>
      _ManualDownloadDialogState();
}

class _ManualDownloadDialogState extends ConsumerState<_ManualDownloadDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _magnetController = TextEditingController();
  final TextEditingController _movieNumberController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  _ManualDownloadSource _source = _ManualDownloadSource.magnet;
  ManualDownloadMediaKind _mediaKind = ManualDownloadMediaKind.jav;
  int? _clientId;
  int? _collectionId;
  PickedFileWithBytes? _torrentFile;
  String? _fileError;
  String? _submitError;
  bool _deleteSourceAfterImport = false;
  bool _isSubmitting = false;

  _MovieResolution _movieResolution = const _MovieResolution.idle();
  int _movieQueryVersion = 0;
  StreamSubscription<MovieSearchStreamUpdate>? _activeMovieSearch;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _movieQueryVersion++;
    final active = _activeMovieSearch;
    _activeMovieSearch = null;
    if (active != null) {
      unawaited(active.cancel());
    }
    _magnetController.dispose();
    _movieNumberController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  DownloadClientDto? _selectedClient(List<DownloadClientDto> clients) {
    for (final client in clients) {
      if (client.id == _clientId) return client;
    }
    return clients.isEmpty ? null : clients.first;
  }

  String? _validateMagnet(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请粘贴磁力链接';
    if (text.contains('\n') || text.contains('\r')) {
      return '一次只能提交一条磁力链接';
    }
    if (!text.toLowerCase().startsWith('magnet:')) {
      return '仅支持 magnet: 开头的磁力链接';
    }
    return null;
  }

  String? _validateMovieNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写番号';
    final resolution = _movieResolution;
    if (resolution.isResolving) return '番号查询中，请稍候';
    if (!resolution.isResolved || resolution.rawInput != text) {
      return '请先点击「查询」并匹配影片';
    }
    return null;
  }

  bool get _canQueryMovieNumber =>
      !_isSubmitting &&
      !_movieResolution.isResolving &&
      _movieNumberController.text.trim().isNotEmpty;

  int _invalidateMovieQuery() {
    final version = ++_movieQueryVersion;
    final active = _activeMovieSearch;
    _activeMovieSearch = null;
    if (active != null) {
      unawaited(active.cancel());
    }
    return version;
  }

  bool _isCurrentMovieQuery(int version) =>
      mounted && version == _movieQueryVersion;

  void _onMovieNumberChanged(String value) {
    final text = value.trim();
    if (text == _movieResolution.rawInput) return;
    _invalidateMovieQuery();
    setState(() {
      _movieResolution = _MovieResolution.idle(rawInput: text);
    });
  }

  void _onMediaKindChanged(ManualDownloadMediaKind value) {
    if (value == _mediaKind) return;
    _invalidateMovieQuery();
    setState(() {
      _mediaKind = value;
      _movieResolution = const _MovieResolution.idle();
    });
  }

  Future<void> _resolveMovieNumber() async {
    if (_isSubmitting || _movieResolution.isResolving) return;
    final raw = _movieNumberController.text.trim();
    if (raw.isEmpty) return;
    final version = _invalidateMovieQuery();
    setState(() {
      _movieResolution = _MovieResolution.resolving(
        rawInput: raw,
        message: '正在识别番号…',
      );
    });
    try {
      final parsed = await ref
          .read(moviesApiProvider)
          .parseMovieNumber(query: raw);
      if (!_isCurrentMovieQuery(version)) return;
      final number = parsed.movieNumber?.trim() ?? '';
      if (!parsed.parsed || number.isEmpty) {
        _setMovieResolutionFailed(version, raw, '无法识别番号，请输入完整番号（如 SSNI-888）');
        return;
      }
      setState(() {
        _movieResolution = _MovieResolution.resolving(
          rawInput: raw,
          parsedNumber: number,
          message: '已识别为 $number，正在本地查询…',
        );
      });
      final page = await ref
          .read(moviesApiProvider)
          .getMovies(query: number, pageSize: 50);
      if (!_isCurrentMovieQuery(version)) return;
      final local = _findExactLocalMovie(page.items, number);
      if (local != null) {
        _setMovieResolved(
          version,
          raw,
          number,
          local,
          _MovieResolutionSource.local,
        );
        return;
      }
      _startOnlineMovieSearch(version, raw, number);
    } catch (error) {
      if (!_isCurrentMovieQuery(version)) return;
      _setMovieResolutionFailed(
        version,
        raw,
        apiErrorMessage(error, fallback: '番号查询失败，请稍后重试'),
      );
    }
  }

  MovieListItemDto? _findExactLocalMovie(
    List<MovieListItemDto> items,
    String query,
  ) {
    final matches = items
        .where(
          (movie) => isExactMovieNumberMatch(
            storedMovieNumber: movie.movieNumber,
            query: query,
          ),
        )
        .toList(growable: false);
    if (matches.isEmpty) return null;
    final queryUpper = query.trim().toUpperCase();
    for (final movie in matches) {
      if (movie.movieNumber.trim().toUpperCase() == queryUpper) {
        return movie;
      }
    }
    return matches.first;
  }

  void _startOnlineMovieSearch(int version, String raw, String parsed) {
    setState(() {
      _movieResolution = _MovieResolution.resolving(
        rawInput: raw,
        parsedNumber: parsed,
        message: '本地未找到，正在在线搜索并入库…',
      );
    });
    var settled = false;
    late final StreamSubscription<MovieSearchStreamUpdate> subscription;
    subscription = ref
        .read(moviesApiProvider)
        .searchOnlineMoviesStream(movieNumber: parsed)
        .listen(
          (update) {
            if (!_isCurrentMovieQuery(version) || settled) return;
            if (!update.isComplete) {
              setState(() {
                _movieResolution = _MovieResolution.resolving(
                  rawInput: raw,
                  parsedNumber: parsed,
                  message: update.message.isEmpty
                      ? '正在在线搜索并入库…'
                      : update.message,
                );
              });
              return;
            }
            settled = true;
            final movie = update.results
                .where((item) => item.movieNumber.trim().isNotEmpty)
                .firstOrNull;
            if (update.success == true && movie != null) {
              _setMovieResolved(
                version,
                raw,
                parsed,
                movie,
                _MovieResolutionSource.online,
              );
            } else if (update.reason == 'movie_not_found' ||
                update.reason == 'movie_number_not_found') {
              _setMovieResolutionFailed(
                version,
                raw,
                '本地和在线均未找到 $parsed',
                parsed,
              );
            } else {
              _setMovieResolutionFailed(version, raw, '在线搜索失败，请稍后重试', parsed);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!_isCurrentMovieQuery(version) || settled) return;
            settled = true;
            _setMovieResolutionFailed(
              version,
              raw,
              apiErrorMessage(error, fallback: '在线搜索失败，请稍后重试'),
              parsed,
            );
          },
          onDone: () {
            if (_isCurrentMovieQuery(version) && !settled) {
              _setMovieResolutionFailed(version, raw, '在线搜索未返回结果，请重试', parsed);
            }
            if (identical(_activeMovieSearch, subscription)) {
              _activeMovieSearch = null;
            }
          },
          cancelOnError: false,
        );
    _activeMovieSearch = subscription;
  }

  void _setMovieResolved(
    int version,
    String raw,
    String? parsed,
    MovieListItemDto movie,
    _MovieResolutionSource source,
  ) {
    if (!_isCurrentMovieQuery(version)) return;
    setState(() {
      _movieResolution = _MovieResolution.resolved(
        rawInput: raw,
        parsedNumber: parsed,
        movie: movie,
        source: source,
      );
    });
    if (_hasAttemptedSubmit) {
      _formKey.currentState?.validate();
    }
  }

  void _setMovieResolutionFailed(
    int version,
    String raw,
    String message, [
    String? parsed,
  ]) {
    if (!_isCurrentMovieQuery(version)) return;
    setState(() {
      _movieResolution = _MovieResolution.failed(
        rawInput: raw,
        parsedNumber: parsed,
        message: message,
      );
    });
    if (_hasAttemptedSubmit) {
      _formKey.currentState?.validate();
    }
  }

  Future<void> _pickTorrentFile() async {
    final isMobile = AppPlatformScope.maybeOf(context) == AppPlatform.mobile;
    try {
      final picked = await pickFileWithBytes(
        type: isMobile ? FileType.any : FileType.custom,
        allowedExtensions: isMobile ? null : const <String>['torrent'],
        unreadableMessage: '无法读取所选种子文件，请换一个文件再试',
        pickerUnavailableMessage: '文件选择器尚未加载，请完整重启应用后再试',
        openFailureMessage: '打开文件选择器失败，请稍后再试',
      );
      if (picked == null || !mounted) return;
      setState(() {
        _torrentFile = picked;
        _fileError = picked.bytes.length > DownloadsApi.maxManualTorrentBytes
            ? '种子文件不能超过 10 MB'
            : null;
      });
    } on FilePickerWithBytesException catch (error) {
      if (mounted) {
        setState(() => _fileError = error.message);
      }
    }
  }

  Future<void> _pickCollection() async {
    final result = await showPickVideoCollectionSingleDialog(
      context,
      selectedCollectionId: _collectionId,
    );
    if (result == null || !mounted) return;
    setState(() => _collectionId = result.collectionId);
  }

  Future<void> _createCollection() async {
    final created = await showVideoCollectionDialog(
      context,
      presentation: AppPlatformScope.maybeOf(context) == AppPlatform.mobile
          ? VideoCollectionEditPresentation.bottomDrawer
          : VideoCollectionEditPresentation.dialog,
    );
    if (created == null || !mounted) return;
    // 先选中，避免随后 refresh 失败时丢掉选择。
    setState(() => _collectionId = created.id);
    await ref.read(videoCollectionsOverviewProvider.notifier).refresh();
  }

  void _goConfigureClients() {
    final isMobile = AppPlatformScope.maybeOf(context) == AppPlatform.mobile;
    if (!isMobile) {
      // 配置页是常驻路由分支，用一次性信号让它落到「下载器」分类。
      ref
          .read(configurationTabRequestProvider.notifier)
          .request('configuration-tab-downloads');
    }
    Navigator.of(context).pop();
    if (!widget.hostContext.mounted) return;
    if (isMobile) {
      const MobileSettingsDownloadersRouteData().push(widget.hostContext);
    } else {
      widget.hostContext.goPrimaryRoute(desktopConfigurationPath);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _movieResolution.isResolving) return;
    final clients =
        ref.read(downloadClientsProvider).value ?? const <DownloadClientDto>[];
    final client = _selectedClient(clients);
    if (client == null) return;

    _hasAttemptedSubmit = true;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_source == _ManualDownloadSource.torrent) {
      final file = _torrentFile;
      if (file == null) {
        setState(() => _fileError = '请选择 .torrent 文件');
        return;
      }
      if (file.bytes.length > DownloadsApi.maxManualTorrentBytes) {
        setState(() => _fileError = '种子文件不能超过 10 MB');
        return;
      }
    }
    if (!formValid) return;

    if (_mediaKind == ManualDownloadMediaKind.jav) {
      final resolution = _movieResolution;
      final text = _movieNumberController.text.trim();
      if (!resolution.isResolved || resolution.rawInput != text) {
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _fileError = null;
    });

    final movieNumber = _mediaKind == ManualDownloadMediaKind.jav
        ? _movieResolution.movie!.movieNumber
        : null;
    final collectionId = _mediaKind == ManualDownloadMediaKind.video
        ? _collectionId
        : null;
    final displayName = _displayNameController.text.trim();

    try {
      final api = ref.read(downloadsApiProvider);
      final response = _source == _ManualDownloadSource.magnet
          ? await api.createManualDownloadRequest(
              clientId: client.id,
              mediaKind: _mediaKind,
              sourceUri: _magnetController.text.trim(),
              movieNumber: movieNumber,
              collectionId: collectionId,
              displayName: displayName,
              deleteSourceAfterImport: _deleteSourceAfterImport,
            )
          : await api.createManualTorrentDownloadRequest(
              clientId: client.id,
              mediaKind: _mediaKind,
              torrentBytes: _torrentFile!.bytes,
              fileName: _torrentFile!.fileName,
              movieNumber: movieNumber,
              collectionId: collectionId,
              displayName: displayName,
              deleteSourceAfterImport: _deleteSourceAfterImport,
            );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(ManualDownloadResult(response: response, clientName: client.name));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = apiErrorMessage(error, fallback: '创建下载任务失败，请重试');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final clientsAsync = ref.watch(downloadClientsProvider);
    final clients = clientsAsync.value ?? const <DownloadClientDto>[];
    final selectedClient = _selectedClient(clients);
    final canSubmit =
        !_isSubmitting &&
        !_movieResolution.isResolving &&
        selectedClient != null;

    return PopScope(
      canPop: !_isSubmitting,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '手动添加下载',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s16,
                weight: AppTextWeight.semibold,
                tone: AppTextTone.primary,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              '粘贴磁力链接或上传 .torrent 文件，提交到下载器。',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.secondary,
              ),
            ),
            SizedBox(height: spacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FormSectionLabel('资源'),
                      SizedBox(height: spacing.sm),
                      _buildChoiceRow<_ManualDownloadSource>(
                        options: const [
                          (_ManualDownloadSource.magnet, '磁力链接'),
                          (_ManualDownloadSource.torrent, '种子文件'),
                        ],
                        selected: _source,
                        keyOf: (value) =>
                            Key('manual-download-source-${value.name}'),
                        onChanged: (value) => setState(() => _source = value),
                      ),
                      SizedBox(height: spacing.md),
                      if (_source == _ManualDownloadSource.magnet)
                        AppTextField(
                          fieldKey: const Key('manual-download-magnet-field'),
                          controller: _magnetController,
                          label: '磁力链接',
                          hintText: 'magnet:?xt=urn:btih:...',
                          helperText:
                              '只接受 magnet: 链接；HTTP 种子地址请下载 .torrent 后上传。',
                          minLines: 2,
                          maxLines: 3,
                          keyboardType: TextInputType.url,
                          enabled: !_isSubmitting,
                          validator: _validateMagnet,
                        )
                      else
                        _buildTorrentField(context),
                      SizedBox(height: spacing.xl),
                      const _FormSectionLabel('下载设置'),
                      SizedBox(height: spacing.sm),
                      _buildClientField(clientsAsync, selectedClient),
                      SizedBox(height: spacing.md),
                      _buildChoiceRow<ManualDownloadMediaKind>(
                        options: const [
                          (ManualDownloadMediaKind.jav, 'JAV 影片'),
                          (ManualDownloadMediaKind.video, 'PornBox'),
                        ],
                        selected: _mediaKind,
                        keyOf: (value) =>
                            Key('manual-download-kind-${value.apiValue}'),
                        onChanged: _onMediaKindChanged,
                      ),
                      SizedBox(height: spacing.md),
                      if (_mediaKind == ManualDownloadMediaKind.jav)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              fieldKey: const Key(
                                'manual-download-movie-number-field',
                              ),
                              controller: _movieNumberController,
                              label: '番号',
                              hintText: '例如 ABC-123 或 FC2-PPV-123',
                              helperText: '点「查询」或回车解析并匹配；本地没有时会在线搜索并入库。',
                              enabled: !_isSubmitting,
                              textInputAction: TextInputAction.search,
                              onFieldSubmitted: (_) =>
                                  unawaited(_resolveMovieNumber()),
                              onChanged: _onMovieNumberChanged,
                              validator: _validateMovieNumber,
                              // 紧凑按钮后缀：保留 tightSuffix 以维持 32/36 的
                              // token 高度，不被默认 48px 后缀最小约束拉伸；
                              // 左右留白与输入文字、边框拉开距离。
                              tightSuffix: true,
                              suffix: Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: spacing.xs,
                                  end: spacing.sm,
                                ),
                                child: AppTextButton(
                                  key: const Key(
                                    'manual-download-movie-number-query-button',
                                  ),
                                  label: _movieResolution.isResolving
                                      ? '查询中'
                                      : '查询',
                                  icon: const Icon(Icons.search_rounded),
                                  size: AppTextButtonSize.small,
                                  emphasis: AppTextButtonEmphasis.accent,
                                  isLoading: _movieResolution.isResolving,
                                  onPressed: _canQueryMovieNumber
                                      ? () => unawaited(_resolveMovieNumber())
                                      : null,
                                ),
                              ),
                            ),
                            _buildMovieResolutionStatus(context),
                          ],
                        )
                      else
                        _VideoCollectionField(
                          collectionId: _collectionId,
                          onTap: _isSubmitting ? null : _pickCollection,
                          onCreate: _isSubmitting ? null : _createCollection,
                        ),
                      SizedBox(height: spacing.md),
                      AppTextField(
                        fieldKey: const Key(
                          'manual-download-display-name-field',
                        ),
                        controller: _displayNameController,
                        label: '显示名称（可选）',
                        helperText: '优先显示在下载任务列表；留空时使用影片标题或资源名称。',
                        enabled: !_isSubmitting,
                      ),
                      SizedBox(height: spacing.md),
                      _buildDeleteSourceRow(context),
                      if (_submitError != null) ...[
                        SizedBox(height: spacing.md),
                        _InlineErrorPanel(
                          key: const Key('manual-download-submit-error'),
                          message: _submitError!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const Key('manual-download-cancel-button'),
                    label: '取消',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: AppButton(
                    key: const Key('manual-download-submit-button'),
                    label: '提交下载',
                    variant: AppButtonVariant.primary,
                    isLoading: _isSubmitting,
                    onPressed: canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceRow<T>({
    required List<(T, String)> options,
    required T selected,
    required ValueChanged<T> onChanged,
    Key Function(T value)? keyOf,
  }) {
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) SizedBox(width: context.appSpacing.sm),
          Expanded(
            child: AppButton(
              key: keyOf?.call(options[index].$1),
              label: options[index].$2,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              isSelected: options[index].$1 == selected,
              onPressed: _isSubmitting
                  ? null
                  : () => onChanged(options[index].$1),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientField(
    AsyncValue<List<DownloadClientDto>> clientsAsync,
    DownloadClientDto? selectedClient,
  ) {
    final spacing = context.appSpacing;
    if (clientsAsync.isLoading && !clientsAsync.hasValue) {
      return Row(
        children: [
          const AppInlineSpinner(),
          SizedBox(width: spacing.sm),
          Text(
            '正在加载下载器…',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.muted,
            ),
          ),
        ],
      );
    }
    if (clientsAsync.hasError && !clientsAsync.hasValue) {
      return AppInlineErrorBanner(
        message: apiErrorMessage(clientsAsync.error!, fallback: '下载器加载失败'),
        retryKey: const Key('manual-download-clients-retry'),
        onRetry: () => ref.read(downloadClientsProvider.notifier).reload(),
      );
    }

    final clients = clientsAsync.value ?? const <DownloadClientDto>[];
    if (clients.isEmpty) {
      return Container(
        key: const Key('manual-download-no-clients'),
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: context.appColors.surfaceMuted,
          borderRadius: context.appRadius.mdBorder,
          border: Border.all(color: context.appColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '还没有可用的下载器',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s14,
                tone: AppTextTone.primary,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              '请先在系统设置中配置并启用下载器，然后再提交下载。',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
            SizedBox(height: spacing.sm),
            AppButton(
              key: const Key('manual-download-configure-clients-button'),
              label: '去配置下载器',
              size: AppButtonSize.xSmall,
              onPressed: _isSubmitting ? null : _goConfigureClients,
            ),
          ],
        ),
      );
    }

    return AppSelectField<int?>(
      key: const Key('manual-download-client-field'),
      label: '下载器',
      value: selectedClient?.id,
      placeholder: '请选择下载器',
      items: clients
          .map(
            (client) => DropdownMenuItem<int?>(
              value: client.id,
              child: Text(client.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _clientId = value),
    );
  }

  Widget _buildTorrentField(BuildContext context) {
    final spacing = context.appSpacing;
    final file = _torrentFile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: context.appColors.surfaceMuted,
            borderRadius: context.appRadius.mdBorder,
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: context.appComponentTokens.iconSizeMd,
                color: context.appTextPalette.secondary,
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file?.fileName ?? '未选择种子文件',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s14,
                        tone: file == null
                            ? AppTextTone.muted
                            : AppTextTone.primary,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      file == null
                          ? '选择 .torrent 文件，最大 10 MB'
                          : formatFileSize(file.bytes.length),
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s12,
                        tone: AppTextTone.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              AppButton(
                key: const Key('manual-download-pick-torrent-button'),
                label: file == null ? '选择文件' : '重新选择',
                size: AppButtonSize.xSmall,
                onPressed: _isSubmitting ? null : _pickTorrentFile,
              ),
            ],
          ),
        ),
        if (_fileError != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            _fileError!,
            key: const Key('manual-download-file-error'),
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

  Widget _buildDeleteSourceRow(BuildContext context) {
    final spacing = context.appSpacing;
    return AppInteractiveSurface(
      key: const Key('manual-download-delete-source-row'),
      onTap: _isSubmitting
          ? null
          : () => setState(
              () => _deleteSourceAfterImport = !_deleteSourceAfterImport,
            ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '导入后删除源文件',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s14,
                      tone: AppTextTone.primary,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    '导入成功后删除下载器中的源文件，不可恢复',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.md),
            AppSwitch(
              key: const Key('manual-download-delete-source-switch'),
              value: _deleteSourceAfterImport,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _deleteSourceAfterImport = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieResolutionStatus(BuildContext context) {
    final spacing = context.appSpacing;
    final resolution = _movieResolution;
    switch (resolution.phase) {
      case _MovieResolutionPhase.idle:
        return const SizedBox.shrink();
      case _MovieResolutionPhase.resolving:
        return Padding(
          padding: EdgeInsets.only(top: spacing.sm),
          child: Row(
            key: const Key('manual-download-movie-resolution-loading'),
            children: [
              const AppInlineSpinner(),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  resolution.message ?? '正在查询番号…',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.muted,
                  ),
                ),
              ),
            ],
          ),
        );
      case _MovieResolutionPhase.failed:
        return Padding(
          padding: EdgeInsets.only(top: spacing.sm),
          child: _InlineErrorPanel(
            key: const Key('manual-download-movie-resolution-error'),
            message: resolution.message ?? '番号查询失败',
          ),
        );
      case _MovieResolutionPhase.resolved:
        final movie = resolution.movie;
        if (movie == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: spacing.sm),
          child: _ResolvedMovieCard(
            movie: movie,
            source: resolution.source ?? _MovieResolutionSource.local,
          ),
        );
    }
  }
}

class _InlineErrorPanel extends StatelessWidget {
  const _InlineErrorPanel({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: context.appColors.errorSurface,
        borderRadius: context.appRadius.mdBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.appComponentTokens.iconSizeMd,
            color: context.appTextPalette.error,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              message,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedMovieCard extends StatelessWidget {
  const _ResolvedMovieCard({required this.movie, required this.source});

  final MovieListItemDto movie;
  final _MovieResolutionSource source;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final thinCover = movie.thinCoverImage?.origin.trim() ?? '';
    final wideCover = movie.coverImage?.origin.trim() ?? '';
    final coverUrl = thinCover.isNotEmpty ? thinCover : wideCover;
    return Container(
      key: const Key('manual-download-movie-resolution-card'),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceMuted,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: context.appRadius.xsBorder,
            child: SizedBox(
              width: 48,
              height: 64,
              child: coverUrl.isEmpty
                  ? Container(
                      color: context.appColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: context.appComponentTokens.iconSizeMd,
                        color: context.appTextPalette.muted,
                      ),
                    )
                  : MaskedImage(url: coverUrl, fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        movie.movieNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s14,
                          weight: AppTextWeight.semibold,
                          tone: AppTextTone.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.xs),
                    AppBadge(
                      key: const Key('manual-download-movie-resolution-source'),
                      label: source == _MovieResolutionSource.local
                          ? '本地'
                          : '在线',
                      tone: source == _MovieResolutionSource.local
                          ? AppBadgeTone.neutral
                          : AppBadgeTone.info,
                      size: AppBadgeSize.compact,
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                Text(
                  movie.title.trim().isEmpty ? '未知标题' : movie.title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  const _FormSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: resolveAppTextStyle(
        context,
        size: AppTextSize.s12,
        weight: AppTextWeight.medium,
        tone: AppTextTone.secondary,
      ),
    );
  }
}

/// 视频合集只读触发条：外观对齐 [AppTextField]，点击打开可搜索单选弹层。
class _VideoCollectionField extends ConsumerWidget {
  const _VideoCollectionField({
    required this.collectionId,
    required this.onTap,
    required this.onCreate,
  });

  final int? collectionId;
  final VoidCallback? onTap;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections =
        ref.watch(videoCollectionsOverviewProvider).value ??
        const <VideoCollectionDto>[];
    String? name;
    if (collectionId != null) {
      for (final collection in collections) {
        if (collection.id == collectionId) {
          name = collection.name;
          break;
        }
      }
    }
    return _CollectionPickerField(
      valueLabel: name,
      onTap: onTap,
      onCreate: onCreate,
    );
  }
}

class _CollectionPickerField extends StatelessWidget {
  const _CollectionPickerField({
    required this.valueLabel,
    required this.onTap,
    required this.onCreate,
  });

  final String? valueLabel;
  final VoidCallback? onTap;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final formTokens = context.appFormTokens;
    final label = valueLabel?.trim() ?? '';
    final enabled = onTap != null;
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
              key: const Key('manual-download-create-collection-button'),
              label: '新建合集',
              size: AppTextButtonSize.small,
              onPressed: onCreate,
            ),
          ],
        ),
        SizedBox(height: formTokens.labelGap),
        MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            key: const Key('manual-download-collection-field'),
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
        ),
      ],
    );
  }
}
