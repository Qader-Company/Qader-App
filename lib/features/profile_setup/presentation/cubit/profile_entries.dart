import 'package:file_picker/file_picker.dart';

const _keep = Object();

/// The repeating entries of the profile form. Immutable: the cubit replaces
/// an entry with a changed copy (same [id]) and emits a new state. The [id]
/// is local and stable; it keys the entry's widgets and text fields.

/// A language and its proficiency.
class LanguageEntry {
  const LanguageEntry(this.id, {this.language, this.level});
  final int id;
  final String? language;
  final String? level;

  LanguageEntry copyWith({Object? language = _keep, Object? level = _keep}) =>
      LanguageEntry(
        id,
        language: identical(language, _keep)
            ? this.language
            : language as String?,
        level: identical(level, _keep) ? this.level : level as String?,
      );
}

/// A work experience; its texts live in the cubit's text fields.
class ExperienceEntry {
  const ExperienceEntry(
    this.id, {
    this.serverId,
    this.current = false,
    this.from,
    this.to,
  });
  final int id;

  /// The record id on the server, once saved.
  final int? serverId;
  final bool current;
  final DateTime? from;
  final DateTime? to;

  ExperienceEntry copyWith({
    bool? current,
    Object? from = _keep,
    Object? to = _keep,
  }) => ExperienceEntry(
    id,
    serverId: serverId,
    current: current ?? this.current,
    from: identical(from, _keep) ? this.from : from as DateTime?,
    to: identical(to, _keep) ? this.to : to as DateTime?,
  );
}

/// A project with the images picked on this device and those already saved.
class ProjectEntry {
  const ProjectEntry(
    this.id, {
    this.serverId,
    this.savedImages = const [],
    this.images = const [],
  });
  final int id;

  /// The record id on the server, once saved.
  final int? serverId;
  final List<Map<String, dynamic>> savedImages;
  final List<PlatformFile> images;

  ProjectEntry copyWith({List<PlatformFile>? images}) => ProjectEntry(
    id,
    serverId: serverId,
    savedImages: savedImages,
    images: images == null ? this.images : List.unmodifiable(images),
  );
}
