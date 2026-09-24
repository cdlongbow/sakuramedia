import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/media/app_image_provider.dart';

void main() {
  group('isTransientImage', () {
    test('剧情图 / 媒体点缩略图 / 搜索图为 transient', () {
      expect(
        isTransientImage(
          'https://api.example.com/files/images/movies/aa/AAA-001/plot-0.jpg',
        ),
        isTrue,
      );
      expect(
        isTransientImage(
          'https://api.example.com/files/images/movies/aa/AAA-001/media/x/thumbnails/12.webp',
        ),
        isTrue,
      );
      expect(
        isTransientImage(
          'https://api.example.com/files/images/metadata-search/abc/0.jpg',
        ),
        isTrue,
      );
    });

    test('封面 / 薄封面 / 头像 / 视频封面不 transient', () {
      expect(
        isTransientImage(
          'https://api.example.com/files/images/movies/aa/AAA-001/cover.jpg',
        ),
        isFalse,
      );
      expect(
        isTransientImage(
          'https://api.example.com/files/images/movies/aa/AAA-001/thin-cover.jpg',
        ),
        isFalse,
      );
      expect(
        isTransientImage(
          'https://api.example.com/files/images/actors/abc.jpg',
        ),
        isFalse,
      );
      expect(
        isTransientImage(
          'https://api.example.com/files/images/videos/1/cover/0.webp',
        ),
        isFalse,
      );
    });
  });

  group('stableImageCacheKey', () {
    test('去掉 expires / signature', () {
      expect(
        stableImageCacheKey(
          'https://api.example.com/files/images/movies/aa/AAA-001/cover.jpg?expires=123&signature=abc',
        ),
        'https://api.example.com/files/images/movies/aa/AAA-001/cover.jpg',
      );
    });

    test('同图不同签名得到同一个 key', () {
      const path =
          'https://api.example.com/files/images/movies/aa/AAA-001/cover.jpg';
      expect(
        stableImageCacheKey('$path?expires=1&signature=a'),
        stableImageCacheKey('$path?expires=2&signature=b'),
      );
    });

    test('无 query 时原样返回', () {
      const url = 'https://api.example.com/files/images/actors/abc.jpg';
      expect(stableImageCacheKey(url), url);
    });

    test('保留非签名参数', () {
      expect(
        stableImageCacheKey(
          'https://api.example.com/files/images/a.jpg?size=medium&expires=1&signature=s',
        ),
        'https://api.example.com/files/images/a.jpg?size=medium',
      );
    });
  });
}
