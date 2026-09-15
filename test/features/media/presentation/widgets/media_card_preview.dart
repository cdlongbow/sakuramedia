import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_file_group_card.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_card.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/theme.dart';

const _previewDirectory = '/tmp/sakuramedia-media-card-preview-20260915';

void main() {
  setUpAll(_loadPreviewFonts);

  late SessionStore sessionStore;
  late HttpServer imageServer;
  late String coverUrl;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    final imageBytes = await File(
      'wiki/public/images/sakuramedia-home-hero.png',
    ).readAsBytes();
    imageServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    imageServer.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(imageBytes);
      await request.response.close();
    });
    coverUrl = 'http://127.0.0.1:${imageServer.port}/preview-cover.png';
  });

  tearDown(() async {
    await imageServer.close(force: true);
    sessionStore.dispose();
  });

  testWidgets('captures desktop media group and list cards', (tester) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(sessionStore),
          mediaLibrariesProvider.overrideWith(_PreviewMediaLibraries.new),
        ],
        child: MaterialApp(
          theme: _previewTheme(sakuraThemeData, TargetPlatform.macOS),
          home: Scaffold(
            body: ColoredBox(
              color: sakuraThemeData.scaffoldBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: SizedBox(
                    width: 1040,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaFileGroupCard(
                          items: [
                            _previewItem(1, coverUrl: coverUrl),
                            _previewItem(2, coverUrl: coverUrl),
                          ],
                          countLabel: '2 个文件',
                          headerKey: const Key('preview-desktop-group-header'),
                          deleteLabel: '删除',
                          keyPrefix: 'preview-desktop-group',
                          mobile: false,
                          onOpen: () {},
                          onDelete: (_) {},
                          selectedIds: null,
                          onToggle: (_) {},
                        ),
                        const SizedBox(height: 16),
                        MediaListItemCard(
                          keyPrefix: 'preview-desktop-list',
                          item: _previewItem(
                            3,
                            valid: false,
                            coverUrl: coverUrl,
                          ),
                          mobile: false,
                          library: _previewLibrary,
                          onDelete: () {},
                          showUpdatedAt: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await capturePreview(
      tester,
      boundaryKey,
      '$_previewDirectory/desktop-media-group-and-list-1100x760.png',
    );
  });

  testWidgets('captures mobile group and reused invalid media card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(sessionStore),
          mediaLibrariesProvider.overrideWith(_PreviewMediaLibraries.new),
        ],
        child: MaterialApp(
          theme: _previewTheme(sakuraMobileThemeData, TargetPlatform.android),
          home: Scaffold(
            body: ColoredBox(
              color: sakuraMobileThemeData.scaffoldBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaFileGroupCard(
                        items: [
                          _previewItem(1, coverUrl: coverUrl),
                          _previewItem(2, coverUrl: coverUrl),
                        ],
                        countLabel: '2 个文件',
                        headerKey: const Key('preview-mobile-group-header'),
                        deleteLabel: '删除',
                        keyPrefix: 'preview-mobile-group',
                        mobile: true,
                        onOpen: () {},
                        onDelete: (_) {},
                        selectedIds: null,
                        onToggle: (_) {},
                      ),
                      const SizedBox(height: 16),
                      MediaListItemCard(
                        keyPrefix: 'preview-mobile-invalid',
                        item: _previewItem(3, valid: false, coverUrl: coverUrl),
                        mobile: true,
                        onDelete: () {},
                        showUpdatedAt: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await capturePreview(
      tester,
      boundaryKey,
      '$_previewDirectory/mobile-group-and-invalid-390x844.png',
    );
  });
}

ThemeData _previewTheme(ThemeData theme, TargetPlatform platform) {
  return theme.copyWith(
    platform: platform,
    textTheme: theme.textTheme.apply(fontFamily: 'PreviewCjk'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'PreviewCjk'),
  );
}

Future<void> _loadPreviewFonts() async {
  final cjkFont = FontLoader('PreviewCjk');
  final cjkBytes = await File(
    '/System/Library/Fonts/PingFang.ttc',
  ).readAsBytes();
  cjkFont.addFont(Future<ByteData>.value(ByteData.sublistView(cjkBytes)));
  await cjkFont.load();

  final iconFont = FontLoader('MaterialIcons');
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is required to load MaterialIcons');
  }
  final iconBytes = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  iconFont.addFont(Future<ByteData>.value(ByteData.sublistView(iconBytes)));
  await iconFont.load();
}

Future<void> capturePreview(
  WidgetTester tester,
  GlobalKey key,
  String outputPath,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  });
}

class _PreviewMediaLibraries extends MediaLibraries {
  @override
  Future<MediaLibrariesState> build() async {
    return MediaLibrariesState(libraries: [_previewLibrary]);
  }
}

final _previewLibrary = MediaLibraryDto(
  id: 1,
  name: '主媒体库',
  providerKey: 'local',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

MediaListItemDto _previewItem(
  int id, {
  bool valid = true,
  required String coverUrl,
}) {
  final image = MovieImageDto(
    id: id,
    origin: coverUrl,
    small: '',
    medium: '',
    large: '',
  );
  return MediaListItemDto(
    id: id,
    kind: MediaListItemKind.jav,
    movieNumber: valid ? 'ABC-$id' : '失效-$id',
    title: valid ? '影片 $id' : '这是一条需要确认删除的失效媒体记录',
    coverImage: image,
    libraryId: 1,
    libraryName: '主媒体库',
    fileName: valid
        ? 'ABC-$id-1080p.mp4'
        : 'invalid-media-with-a-long-file-name-$id.mp4',
    fileSizeBytes: 1280 * 1024 * 1024,
    durationSeconds: 372,
    resolution: '1920x1080',
    valid: valid,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 13, 12),
  );
}
