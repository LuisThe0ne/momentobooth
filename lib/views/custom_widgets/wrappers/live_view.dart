import 'dart:ui' as ui;
import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/_all.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/views/base/stateless_widget_base.dart';
import 'package:momento_booth/views/custom_widgets/wrappers/rotate_flip_crop_container.dart';

class LiveView extends StatelessWidgetBase {

  final BoxFit fit;
  final bool blur;

  const LiveView({
    super.key,
    required this.fit,
    required this.blur,
  });

  ui.FilterQuality get _filterQuality => getIt<SettingsManager>().settings.ui.liveViewFilterQuality.toUiFilterQuality();
  int? get _textureId => getIt<LiveViewManager>().textureId;

  Rotate get _rotate => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureRotate;
  Flip get _flip => getIt<SettingsManager>().settings.hardware.liveViewFlip;
  double get _aspectRatio => getIt<SettingsManager>().settings.hardware.liveViewAndCaptureAspectRatio;

  @override
  Widget build(BuildContext context) {
    Widget box = FittedBox(
      fit: fit,
      child: Observer(
        builder: (_) {
          if (_textureId == null) return const SizedBox.shrink();

          return RotateFlipCropContainer(
            rotate: _rotate,
            flip: _flip,
            aspectRatio: _aspectRatio,
            child: SizedBox(
              width: getIt<LiveViewManager>().textureWidth?.toDouble(),
              height: getIt<LiveViewManager>().textureHeight?.toDouble(),
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  // For some reason, we get unconstrained width and height when the application has just started.
                  // This is a workaround to prevent errors.
                  if (boxConstraints == const BoxConstraints()) return const SizedBox.shrink();
                  return Texture(textureId: _textureId!, filterQuality: _filterQuality);
                }
              ),
            ),
          );
        },
      ),
    );

    if (blur) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: box,
      );
    } else {
      return box;
    }
  }

}
