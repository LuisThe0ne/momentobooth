// ignore_for_file: invalid_annotation_target

import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:toml/toml.dart';

part 'project_settings.freezed.dart';
part 'project_settings.g.dart';

const defaultThemeColor = Color(0xFF0078C8);

// ///////////// //
// Root ProjectSettings //
// ///////////// //

@Freezed(fromJson: true, toJson: true)
class ProjectSettings with _$ProjectSettings implements TomlEncodableValue {

  const ProjectSettings._();

  const factory ProjectSettings({
    @Default(defaultThemeColor) @ColorColorCodeConverter() Color primaryColor,
    @Default(true) bool displayConfetti,
    @Default(false) bool customColorConfetti,
    @Default("") String introScreenTouchToStartOverrideText,
    @Default(true) bool singlePhotoIsCollage,
  }) = _ProjectSettings;

  factory ProjectSettings.withDefaults() => ProjectSettings.fromJson({});

  factory ProjectSettings.fromJson(Map<String, Object?> json) => _$ProjectSettingsFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}
