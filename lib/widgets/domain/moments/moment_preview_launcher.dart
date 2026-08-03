import 'package:flutter/material.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_preview_dialog.dart';

Future<MediaPreviewAction?> showMomentPreviewOverlay({
  required BuildContext context,
  required MomentListItem item,
  required MediaPreviewPresentation presentation,
  Key? drawerKey,
  VoidCallback? onPointRemoved,
  bool closeOnPointRemoved = false,
}) {
  return showMediaPreviewOverlay(
    context: context,
    presentation: presentation,
    drawerKey: drawerKey,
    builder:
        (_) => MomentPreviewDialog(
          item: item,
          onPointRemoved: onPointRemoved,
          closeOnPointRemoved: closeOnPointRemoved,
          presentation: presentation,
        ),
  );
}
