import 'dart:typed_data';
import 'dart:ui';

import 'package:mobx/mobx.dart';

part 'photos_manager.g.dart';

class PhotosManager = PhotosManagerBase with _$PhotosManager;

enum CaptureMode {

  single(0, "Single"),
  collage(1, "Collage");

  // can add more properties or getters/methods if needed
  final int value;
  final String name;

  // can use named parameters if you want
  const CaptureMode(this.value, this.name);

}

/// Class containing global state for photos in the app
abstract class PhotosManagerBase with Store {

  static final PhotosManagerBase instance = PhotosManager._internal();

  @observable
  ObservableList<Uint8List> photos = ObservableList<Uint8List>();

  @observable
  Uint8List? outputImage;

  @observable
  ObservableList<int> chosen = ObservableList<int>();

  @observable
  CaptureMode captureMode = CaptureMode.single;

  @computed
  bool get showLiveViewBackground => photos.isEmpty && captureMode == CaptureMode.single;

  Iterable<Uint8List> get chosenPhotos => chosen.map((choice) => photos[choice]);

  PhotosManagerBase._internal();

  @action
  void reset() {
    photos.clear();
    chosen.clear();
    captureMode = CaptureMode.single;
  }

}
