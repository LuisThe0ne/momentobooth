import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' hide Action, RawImage;
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loggy/loggy.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/managers/photos_manager.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/rust_bridge/library_api.generated.dart';
import 'package:momento_booth/rust_bridge/library_bridge.dart';
import 'package:momento_booth/theme/momento_booth_theme_data.dart';
import 'package:momento_booth/views/custom_widgets/image_with_loader_fallback.dart';
import 'package:path/path.dart';
import 'package:screenshot/screenshot.dart';

enum TemplateKind {

  front(0, "front"),
  back(1, "back");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const TemplateKind(this.value, this.name);

}

class PhotoCollage extends StatefulWidget {

  final double aspectRatio;
  final double padding;
  final bool showLogo;
  final bool showBackground;
  final bool showForeground;
  final bool singleMode;
  final int? debug;
  final VoidCallback? decodeCallback;
  final bool isVisible;

  const PhotoCollage({
    super.key,
    required this.aspectRatio,
    this.padding = 0,
    this.showLogo = false,
    this.singleMode = false,
    this.showBackground = true,
    this.showForeground = true,
    this.debug,
    this.decodeCallback,
    this.isVisible = true,
  });

  @override
  State<PhotoCollage> createState() => PhotoCollageState();

}

class PhotoCollageState extends State<PhotoCollage> with UiLoggy {

  @override
  void initState() {
    super.initState();
    setInitialized = Action(_setInitialized);
    findTemplates();
  }

  void _setInitialized(int value) => _initialized.value = value;

  final Observable<int> _initialized = Observable(0);
  int get initialized => _initialized.value;
  late Action setInitialized;

  ScreenshotController screenshotController = ScreenshotController();

  MomentoBoothThemeData get theme => MomentoBoothThemeData.defaults();
  static const double gap = 20.0;

  ObservableList<int> get chosen => PhotosManager.instance.chosen;
  ObservableList<Uint8List> get photos => PhotosManager.instance.photos;
  Iterable<Uint8List> get chosenPhotos => PhotosManager.instance.chosenPhotos;
  int get nChosen => widget.debug ?? chosen.length;
  int get rotation => [0, 1, 4].contains(nChosen) ? 1 : 0;
  bool firstImageDecoded = false;

  String get templatesFolder => SettingsManager.instance.settings.templatesFolder;

  var templates = {
    TemplateKind.front: <int, File?>{},
    TemplateKind.back: <int, File?>{},
  };

  Future<void> findTemplates() async {
    if (widget.singleMode) {
      templates[TemplateKind.front]?[1] = await _templateResolver(TemplateKind.front, 1);
      templates[TemplateKind.back]?[1] = await _templateResolver(TemplateKind.back, 1);
      setInitialized([1]);
    } else {
      for (int i = 0; i <= 4; i++) {
        final frontTemplate = await _templateResolver(TemplateKind.front, i);
        final backTemplate = await _templateResolver(TemplateKind.back, i);
        templates[TemplateKind.front]?[i] = frontTemplate;
        templates[TemplateKind.back]?[i] = backTemplate;
        setInitialized([i+1]);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Checks if a given template file exists and returns it if it does.
  Future<File?> _templateTest(String fileName) async {
    var template = File(join(templatesFolder, fileName));
    if (template.existsSync()) return template;
    return null;
  }

  /// Resolve the template for a given kind (backtground, foreground) and number of photos.
  Future<File?> _templateResolver(TemplateKind kind, int numPhotos) async {
    final filesToCheck = [
      _templateTest("${kind.name}-template-$numPhotos.png"),
      _templateTest("${kind.name}-template-$numPhotos.jpg"),
      _templateTest("${kind.name}-template.png"),
      _templateTest("${kind.name}-template.jpg"),
    ];
    final checkedFiles = await Future.wait(filesToCheck);
    return checkedFiles.firstWhere((element) => element != null, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    Widget collageBox = FittedBox(
      child: Screenshot(
        controller: screenshotController,
        child: SizedBox(
          height: 1000 + 2 * widget.padding,
          width: 1000 * widget.aspectRatio + 2 * widget.padding,
          child: Observer(builder: (context) => _getLayout(AppLocalizations.of(context)!)),
        ),
      ),
    );

    if (widget.isVisible) return collageBox;

    // We have already tested built in Flutter widgets like Visibility, Opacity, Offstage, but none of them work...
    return Transform.translate(
      offset: Offset(MediaQuery.sizeOf(context).width, 0),
      child: collageBox,
    );
  }

  Widget _getLayout(AppLocalizations localizations) {
    return Stack(fit: StackFit.expand, children: [
      for (int i = 0; i <= 4; i++) ...[
        if (initialized > 0 && templates[TemplateKind.back]?[i] != null)
          Opacity(
            opacity: i == nChosen && widget.showBackground ? 1 : 0,
            child: ImageWithLoaderFallback.file(templates[TemplateKind.back]?[i], fit: BoxFit.cover),
          ),
      ],
      if (widget.debug == null)
        Padding(
          padding: EdgeInsets.all(gap + widget.padding),
          child: _getInnerLayout(localizations),
        ),
      if (widget.debug != null)
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: widget.padding, color: const ui.Color.fromARGB(126, 212, 53, 53)),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: gap, color: const ui.Color.fromARGB(127, 255, 255, 255)),
            ),
            child: _getInnerLayout(localizations),
          ),
        ),
      for (int i = 0; i <= 4; i++) ...[
        if (initialized > 0 && templates[TemplateKind.front]?[i] != null)
          Opacity(
            opacity: i == nChosen && widget.showForeground ? 1 : 0,
            child: ImageWithLoaderFallback.file(templates[TemplateKind.front]?[i], fit: BoxFit.cover),
          ),
      ],
    ]);
  }

  Widget _getInnerLayout(AppLocalizations localizations) {
    return switch (nChosen) {
      0 => _getZeroLayout(localizations),
      1 => _oneLayout,
      2 => _twoLayout,
      3 => _threeLayout,
      4 => _fourLayout,
      _ => const SizedBox.shrink(),
    };
  }

  Widget _getChosenImage(int index, {BoxFit? fit, VoidCallback? decodeCallback}) {
    return widget.debug == null
        ? ImageWithLoaderFallback.memory(photos[chosen[index]], fit: fit, decodeCallback: decodeCallback)
        : ImageWithLoaderFallback.file(File('assets/bitmap/placeholder.png'), fit: fit, decodeCallback: decodeCallback);
  }

  Widget _getZeroLayout(AppLocalizations localizations) {
    return RotatedBox(
      quarterTurns: 1,
      child: Center(
        child: AutoSizeText(
          localizations.photoCollageWidgetSelectPhotos,
          style: theme.titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget get _oneLayout {
    var img = _getChosenImage(0, fit: BoxFit.cover, decodeCallback: widget.decodeCallback);
    return LayoutGrid(
      areas: '''
          l1header
          l1content
        ''',
      rowSizes: [1.fr, 8.fr],
      columnSizes: [1.fr],
      columnGap: gap,
      rowGap: gap,
      children: [
        if (widget.showLogo)
          Center(
            child: SvgPicture.asset(
              "assets/svg/logo.svg",
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ).inGridArea('l1header'),
          ),
        SizedBox.expand(
          child: RotatedBox(
            quarterTurns: 1,
            child: img,
          ),
        ).inGridArea('l1content'),
      ],
    );
  }

  Widget get _twoLayout {
    return LayoutGrid(
      areas: '''
          l2header
          l2content1
          l2content2
        ''',
      rowSizes: [1.fr, auto, auto],
      columnSizes: [1.fr],
      columnGap: gap,
      rowGap: gap,
      children: [
        if (widget.showLogo)
          Center(
            child: SvgPicture.asset(
              "assets/svg/logo.svg",
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ).inGridArea('l2header'),
          ),
        for (int i = 0; i < nChosen; i++) ...[
          _getChosenImage(i).inGridArea('l2content${i+1}'),
        ],
      ],
    );
  }

  Widget get _threeLayout {
    return LayoutGrid(
      areas: '''
          l3header1 l3header2
          l3content1 l3content4
          l3content2 l3content5
          l3content3 l3content6
        ''',
      rowSizes: [1.fr, auto, auto, auto],
      columnSizes: [1.fr, 1.fr],
      columnGap: 2*gap,
      rowGap: gap,
      children: [
        if (widget.showLogo) ...[
          Center(
            child: SvgPicture.asset(
              "assets/svg/logo.svg",
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ).inGridArea('l3header1'),
          Center(
            child: SvgPicture.asset(
              "assets/svg/logo.svg",
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ).inGridArea('l3header2'),
        ],
        for (int i = 0; i < nChosen; i++) ...[
          _getChosenImage(i).inGridArea('l3content${i+1}'),
          _getChosenImage(i).inGridArea('l3content${i+4}'),
        ],
      ],
    );
  }

  Widget get _fourLayout {
    return Stack(
      children: [
        LayoutGrid(
          areas: '''
              l4content3 l4content1
              l4content4 l4content2
            ''',
          rowSizes: const [auto, auto],
          columnSizes: const [auto, auto],
          columnGap: gap,
          rowGap: gap,
          children: [
            for (int i = 0; i < nChosen; i++) ...[
              RotatedBox(
                quarterTurns: 1,
                child: SizedBox.expand(
                  child: _getChosenImage(i, fit: BoxFit.cover),
                ),
              ).inGridArea('l4content${i+1}'),
            ],
          ],
        ),
        if (widget.showLogo)
          Padding(
            padding: const EdgeInsets.all(250),
            child: RotatedBox(
              quarterTurns: 1,
              child: Center(
                child: SvgPicture.asset(
                  "assets/svg/logo.svg",
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<Uint8List?> getCollageImage({required double pixelRatio, ExportFormat format = ExportFormat.jpgFormat, int jpgQuality = 80}) async {
    // Await frame render, should workaround the black image issue
    await waitForPostFrameCallback();
    
    if (format == ExportFormat.pngFormat) {
      return screenshotController.capture(pixelRatio: pixelRatio);
    }

    // Capture widget as RGBA image
    final image = await screenshotController.captureAsUiImage(pixelRatio: pixelRatio);
    final byteData = await image!.toByteData(format: ui.ImageByteFormat.rawRgba);

    // Previously we did the conversion to JPEG like this, but it turned out pretty slow
    //final dartImage = img.Image.fromBytes(width: image.width, height: image.height, bytes: byteData!.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
    //final jpg = img.encodeJpg(dartImage, quality: jpgQuality);

    // Rotate image and encode to JPEG
    final rawImage = RawImage(format: RawImageFormat.Rgba, data: byteData!.buffer.asUint8List(), width: image.width, height: image.height);
    final List<ImageOperation> operationsBeforeEncoding = rotation == 1 ? [const ImageOperation.rotate(Rotation.Rotate270)] : [];

    final stopwatch = Stopwatch()..start();
    final jpegData = await rustLibraryApi.jpegEncode(rawImage: rawImage, quality: jpgQuality, operationsBeforeEncoding: operationsBeforeEncoding);
    loggy.debug('JPEG encoding took ${stopwatch.elapsed}');

    return jpegData;
  }

  Future<void> waitForPostFrameCallback() {
    Completer completer = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }

}
