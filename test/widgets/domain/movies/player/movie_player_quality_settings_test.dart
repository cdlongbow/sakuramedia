import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/widgets/base/media/video/mpv_video_quality_settings.dart';

void main() {
  group('MpvVideoQualitySettings', () {
    test('enable writes every enhancement property', () async {
      final writes = <String, String>{};
      await MpvVideoQualitySettings.enable((key, value) async {
        writes[key] = value;
      });

      expect(writes, MpvVideoQualitySettings.enhancements);
      expect(writes['deband'], 'yes');
      expect(writes['dither-depth'], 'auto');
      expect(writes['cscale'], 'spline36');
    });

    test('a rejected property does not stop the remaining writes', () async {
      final writes = <String, String>{};
      await MpvVideoQualitySettings.enable((key, value) async {
        if (key == 'deband') {
          throw StateError('unsupported property');
        }
        writes[key] = value;
      });

      expect(writes.containsKey('deband'), isFalse);
      expect(writes['sharpen'], '0.5');
      expect(writes, hasLength(MpvVideoQualitySettings.enhancements.length - 1));
    });

    test('disable restores captured values and falls back to neutral', () async {
      final writes = <String, String>{};
      await MpvVideoQualitySettings.disable((key, value) async {
        writes[key] = value;
      }, const <String, String>{'deband': 'no', 'cscale': 'ewa_lanczos'});

      expect(writes['cscale'], 'ewa_lanczos');
      expect(writes['deband'], 'no');
      expect(
        writes['sharpen'],
        MpvVideoQualitySettings.neutralValues['sharpen'],
      );
      expect(writes, hasLength(MpvVideoQualitySettings.enhancements.length));
    });

    test('captureCurrent keeps usable values and skips failures', () async {
      final snapshot = await MpvVideoQualitySettings.captureCurrent((
        key,
      ) async {
        if (key == 'sharpen') {
          throw StateError('unavailable');
        }
        if (key == 'cscale') {
          return '   ';
        }
        return 'lanczos';
      });

      expect(snapshot['deband'], 'lanczos');
      expect(snapshot['dither-depth'], 'lanczos');
      expect(snapshot.containsKey('cscale'), isFalse);
      expect(snapshot.containsKey('sharpen'), isFalse);
    });
  });
}
