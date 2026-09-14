import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sakuramedia/widgets/base/media/video/throttling_player.dart';

final movieMergedPlaybackFactoryProvider =
    Provider<({Player player, VideoController videoController}) Function()>(
      (ref) => () {
        final player = ThrottlingPlayer();
        return (
          player: player,
          videoController: VideoController(
            player,
            configuration: const VideoControllerConfiguration(hwdec: 'auto'),
          ),
        );
      },
    );
