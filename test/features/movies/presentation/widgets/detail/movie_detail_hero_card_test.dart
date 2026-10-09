import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/media/app_image_provider.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_hero_card.dart';

/// Hero 是纯照片：默认完整显示 + 底部化开，不带任何文字按钮
///（标题操作信息在照片下方的 MovieDetailInfoBlock 里）。
/// 移动端传 heroFit cover 铺满裁切。
void main() {
  late SessionStore sessionStore;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
  });

  testWidgets('movie detail hero card contains the full main image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(sessionStore: sessionStore));

    final maskedImages = tester.widgetList<MaskedImage>(
      find.byType(MaskedImage),
    );
    // 前景完整图 contain；模糊底座归页面背景所有，Hero 不再自带。
    expect(
      maskedImages.where(
        (widget) =>
            widget.url == '/covers/main.jpg' && widget.fit == BoxFit.contain,
      ),
      hasLength(1),
    );
    expect(
      maskedImages.where(
        (widget) =>
            widget.url == '/covers/main.jpg' && widget.fit == BoxFit.cover,
      ),
      isEmpty,
    );
  });

  testWidgets('movie detail hero card supports cover fit for mobile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(sessionStore)],
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: MovieDetailHeroCard(
                height: 320,
                mainImageKey: 'cover',
                mainImageUrl: '/covers/main.jpg',
                heroFit: BoxFit.cover,
                veilColor: const Color(0xFF101010),
              ),
            ),
          ),
        ),
      ),
    );

    final maskedImages = tester.widgetList<MaskedImage>(
      find.byType(MaskedImage),
    );
    expect(
      maskedImages.where(
        (widget) =>
            widget.url == '/covers/main.jpg' && widget.fit == BoxFit.cover,
      ),
      hasLength(1),
    );
    // 化开过渡在 cover 下同样保留。
    final shaderMasks = tester.widgetList<ShaderMask>(
      find.byType(ShaderMask),
    );
    expect(shaderMasks, hasLength(1));
    expect(shaderMasks.single.blendMode, BlendMode.dstIn);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movie detail hero melts the cover into the page background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(sessionStore: sessionStore));

    // 清晰图底部用 dstIn 化开，而不是一条硬边。
    final shaderMasks = tester.widgetList<ShaderMask>(
      find.byType(ShaderMask),
    );
    expect(shaderMasks, hasLength(1));
    expect(shaderMasks.single.blendMode, BlendMode.dstIn);
    // Hero 里没有任何文字按钮（搬到下方信息块了）。
    expect(
      find.byKey(const Key('movie-detail-hero-overlay-title')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movie-detail-hero-play-button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movie-detail-hero-subscription-icon')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movie-detail-hero-more-actions-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'movie detail hero feathers cover sides on the first frame when cached',
    (WidgetTester tester) async {
      // 预热内存图片缓存，模拟「重复进入详情页」：封面已经解码好了。
      // key 与 Hero 里 MaskedImage 的解析规则一致：宽度有界 → 只按宽度、上限 1024。
      // 先清一遍：同文件前序用例留下的 pending 项会让 putIfAbsent 直接返回它。
      PaintingBinding.instance.imageCache.clear();
      final image = await _decodeCoverImage(width: 800, height: 538);
      final warmProvider = ResizeImage(
        buildRemoteImageProvider('https://api.example.com/covers/main.jpg'),
        width: (1200 * tester.view.devicePixelRatio).round().clamp(1, 1024),
        allowUpscaling: false,
      );
      PaintingBinding.instance.imageCache.putIfAbsent(
        await warmProvider.obtainKey(ImageConfiguration.empty),
        () => OneFrameImageStreamCompleter(
          SynchronousFuture<ImageInfo>(ImageInfo(image: image)),
        ),
      );
      addTearDown(PaintingBinding.instance.imageCache.clear);

      await tester.pumpWidget(_buildApp(sessionStore: sessionStore));

      // 首帧就该带上左右羽化，不用再 pump 一次等 onImageSized 的帧后回调。
      expect(
        find.byKey(const Key('movie-detail-hero-side-mask')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'movie detail hero card shows placeholder when main image is absent',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sessionStoreProvider.overrideWithValue(sessionStore)],
          child: MaterialApp(
            theme: sakuraThemeData,
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                child: MovieDetailHeroCard(
                  height: 420,
                  mainImageKey: 'placeholder',
                  mainImageUrl: null,
                  veilColor: const Color(0xFF101010),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('movie-detail-main-image-placeholder')),
        findsOneWidget,
      );
      expect(find.byType(MaskedImage), findsNothing);
      // 纯色块占位，无居中图标：骨架态不会被 skeletonizer 画成方块。
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    },
  );
}

Widget _buildApp({required SessionStore sessionStore}) {
  return ProviderScope(
    overrides: [sessionStoreProvider.overrideWithValue(sessionStore)],
    child: MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          child: MovieDetailHeroCard(
            height: 420,
            mainImageKey: 'cover',
            mainImageUrl: '/covers/main.jpg',
            veilColor: const Color(0xFF101010),
          ),
        ),
      ),
    ),
  );
}

/// 纯色测试图：只为给内存图片缓存里放一张已解码的封面。
Future<ui.Image> _decodeCoverImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF6B2D2A),
  );
  return recorder.endRecording().toImage(width, height);
}
