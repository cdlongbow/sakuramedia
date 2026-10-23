import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_info_block.dart';

/// 照片下方信息块：标题 + 右信息列 + 左操作列（分体播放 + 六键）。
void main() {
  testWidgets('movie detail info block shows subscription as heart key', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildBlock(isSubscribed: true, onSubscriptionTap: () {}),
    );

    expect(
      find.byKey(const Key('movie-detail-hero-subscription-icon')),
      findsOneWidget,
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
    expect(icon.color, AppColors.defaults().subscriptionHeartIcon);
    expect(icon.size, AppComponentTokens.defaults().iconSizeSm);
  });

  testWidgets(
    'movie detail info block shows outlined subscription key and handles tap',
    (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildBlock(
          isSubscribed: false,
          onSubscriptionTap: () {
            tapped = true;
          },
        ),
      );

      expect(
        find.byKey(const Key('movie-detail-hero-subscription-icon')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('movie-detail-hero-subscription-icon')),
      );
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets('movie detail info block invokes play callback from play half', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _buildBlock(
        onPlayTap: () {
          tapped = true;
        },
      ),
    );

    expect(find.text('播放'), findsOneWidget);
    await tester.tap(find.byKey(const Key('movie-detail-hero-play-button')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('movie detail info block hides play half when unavailable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildBlock());

    expect(
      find.byKey(const Key('movie-detail-hero-play-button')),
      findsNothing,
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('movie detail info block shows info column and action keys', (
    WidgetTester tester,
  ) async {
    var playlistTapped = false;

    await tester.pumpWidget(
      _buildBlock(
        eyebrow: 'ABC-001',
        overlayTitle: 'Sample Title',
        metaItems: const [
          MovieDetailMetaItem(icon: Icons.star_outline_rounded, text: '4.5'),
          MovieDetailMetaItem(
            icon: Icons.chat_bubble_outline_rounded,
            text: '10',
          ),
          MovieDetailMetaItem(text: '厂商 · SOD'),
        ],
        fileSizeLabel: '20.99 GB',
        onPlayTap: () {},
        onPlaylistTap: () {
          playlistTapped = true;
        },
      ),
    );

    expect(
      find.byKey(const Key('movie-detail-hero-overlay-meta')),
      findsOneWidget,
    );
    expect(find.text('Sample Title'), findsOneWidget);
    expect(find.text('ABC-001'), findsOneWidget);
    // 顺序：评分 → 评论 → 厂商；图标段带图标，文字段裸文本。
    final metaRow = find.byKey(const Key('movie-detail-hero-overlay-meta'));
    expect(
      find.descendant(of: metaRow, matching: find.text('4.5')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metaRow, matching: find.text('10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: metaRow, matching: find.text('厂商 · SOD')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: metaRow,
        matching: find.byIcon(Icons.star_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: metaRow,
        matching: find.byIcon(Icons.chat_bubble_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: metaRow,
        matching: find.byIcon(Icons.local_fire_department_rounded),
      ),
      findsNothing,
    );
    // 顺序：评分 → 评论 → 厂商（从左到右）。
    final scoreX = tester
        .getCenter(find.descendant(of: metaRow, matching: find.text('4.5')))
        .dx;
    final commentX = tester
        .getCenter(find.descendant(of: metaRow, matching: find.text('10')))
        .dx;
    final makerX = tester
        .getCenter(
          find.descendant(of: metaRow, matching: find.text('厂商 · SOD')),
        )
        .dx;
    expect(scoreX, lessThan(commentX));
    expect(commentX, lessThan(makerX));
    expect(
      find.byKey(const Key('movie-detail-hero-overlay-size')),
      findsOneWidget,
    );
    expect(find.text('20.99 GB'), findsOneWidget);

    await tester.tap(find.byKey(const Key('movie-detail-playlist-trigger')));
    await tester.pump();

    expect(playlistTapped, isTrue);
  });

  testWidgets('movie detail info block shows merge half beside play', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _buildBlock(
        onPlayTap: () {},
        mergePlaybackLabel: '合并播放 · 2 段',
        onMergePlaybackTap: () {
          tapped = true;
        },
      ),
    );

    final mergeKey = find.byKey(
      const Key('movie-detail-merge-playback-button'),
    );
    expect(mergeKey, findsOneWidget);
    expect(find.byIcon(Icons.merge_rounded), findsOneWidget);
    expect(find.text('合并'), findsOneWidget);
    expect(find.byTooltip('合并播放 · 2 段'), findsOneWidget);

    final playRect = tester.getRect(
      find.byKey(const Key('movie-detail-hero-play-button')),
    );
    final mergeRect = tester.getRect(mergeKey);
    // 同一行：纵向对齐、合并在右。
    expect(mergeRect.top, closeTo(playRect.top, 1.0));
    expect(mergeRect.left, greaterThan(playRect.left));

    await tester.tap(mergeKey);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('movie detail info block toggles favorite from the star key', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _buildBlock(
        isFavorite: true,
        onFavoriteTap: () {
          tapped = true;
        },
      ),
    );

    expect(
      find.byKey(const Key('movie-detail-hero-favorite-icon')),
      findsOneWidget,
    );
    expect(find.byTooltip('取消收藏'), findsOneWidget);
    // 磁力搜索已收进「更多」。
    expect(find.byTooltip('磁力搜索'), findsNothing);

    await tester.tap(find.byKey(const Key('movie-detail-hero-favorite-icon')));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('movie detail info block invokes more actions callback', (
    WidgetTester tester,
  ) async {
    Offset? tappedPosition;

    await tester.pumpWidget(
      _buildBlock(
        onMoreActionsTap: (globalPosition) async {
          tappedPosition = globalPosition;
        },
      ),
    );

    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('movie-detail-hero-more-actions-button')),
    );
    await tester.pump();

    expect(tappedPosition, isNotNull);
  });
  testWidgets('movie detail info block hides the meta row when empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildBlock(overlayTitle: 'ABC-001 Sample Title', onPlayTap: () {}),
    );

    expect(
      find.byKey(const Key('movie-detail-hero-overlay-title')),
      findsOneWidget,
    );
    // 空 meta 不占行。
    expect(
      find.byKey(const Key('movie-detail-hero-overlay-meta')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _buildBlock({
  bool isSubscribed = false,
  bool isFavorite = false,
  String? overlayTitle,
  String? eyebrow,
  List<MovieDetailMetaItem> metaItems = const [],
  String? fileSizeLabel,
  VoidCallback? onPlayTap,
  VoidCallback? onSubscriptionTap,
  VoidCallback? onFavoriteTap,
  VoidCallback? onPlaylistTap,
  Future<void> Function(Offset globalPosition)? onMoreActionsTap,
  String? mergePlaybackLabel,
  VoidCallback? onMergePlaybackTap,
}) {
  return MaterialApp(
    theme: sakuraThemeData,
    home: Scaffold(
      body: SizedBox(
        width: 1200,
        child: MovieDetailInfoBlock(
          isSubscribed: isSubscribed,
          isFavorite: isFavorite,
          overlayTitle: overlayTitle,
          eyebrow: eyebrow,
          metaItems: metaItems,
          fileSizeLabel: fileSizeLabel,
          onPlayTap: onPlayTap,
          onSubscriptionTap: onSubscriptionTap,
          onFavoriteTap: onFavoriteTap,
          onPlaylistTap: onPlaylistTap,
          onMoreActionsTap: onMoreActionsTap,
          mergePlaybackLabel: mergePlaybackLabel,
          onMergePlaybackTap: onMergePlaybackTap,
        ),
      ),
    ),
  );
}
