// Enforces the AGENTS.md rules that can be checked mechanically.
//
//   dart run tool/check_rules.dart
//
// Exits with code 1 when a rule is broken. File size is reported as a
// warning only.
import 'dart:io';

const _maxLines = 400;
final _directive = RegExp(
  r'''^\s*(?:import|export|part)\s+'([^']+)';''',
  multiLine: true,
);

void main() {
  final root = Directory.current.path;
  final lib = Directory('$root${Platform.pathSeparator}lib');
  if (!lib.existsSync()) {
    stderr.writeln('Run from the project root.');
    exit(2);
  }
  final files =
      lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => _rel(file.path, root))
          .toList()
        ..sort();

  final errors = <String>[];
  final warnings = <String>[];
  final edges = <String, Set<String>>{};

  for (final path in files) {
    final text = File(path).readAsStringSync();
    final lines = text.split('\n');

    // Colors only from AppColors.
    if (path != 'lib/core/resources/app_colors.dart') {
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Color(0x')) {
          errors.add('$path:${i + 1}: hard-coded Color(0x…); use AppColors.');
        }
      }
    }

    // No service locator in features.
    if (path.startsWith('lib/features/')) {
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\bsl(<|\.)').hasMatch(lines[i]) ||
            lines[i].contains('core/di/service_locator.dart')) {
          errors.add(
            '$path:${i + 1}: service locator in a feature; use context.read.',
          );
        }
      }
    }

    // Imports: resolve, check layering and record module edges.
    final from = _module(path);
    for (final match in _directive.allMatches(text)) {
      final uri = match.group(1)!;
      if (uri.startsWith('dart:')) {
        if (path.contains('/domain/') && uri == 'dart:ui') {
          errors.add('$path: domain imports dart:ui.');
        }
        continue;
      }
      if (uri.startsWith('package:') && !uri.startsWith('package:qader/')) {
        if (path.contains('/domain/') &&
            (uri.startsWith('package:flutter/') ||
                uri.startsWith('package:dio/') ||
                uri.startsWith('package:flutter_bloc/'))) {
          errors.add('$path: domain imports $uri (domain must be pure Dart).');
        }
        continue;
      }
      final target = uri.startsWith('package:qader/')
          ? 'lib/${uri.substring('package:qader/'.length)}'
          : _normalize('${_dir(path)}/$uri');
      if (!target.startsWith('lib/')) {
        errors.add('$path: import "$uri" climbs above lib/.');
        continue;
      }
      if (!File(target).existsSync()) {
        errors.add('$path: import "$uri" not found.');
        continue;
      }
      if (path.contains('/domain/') &&
          (target.contains('/data/') || target.contains('/presentation/'))) {
        errors.add('$path: domain imports $target.');
      }
      if (path.contains('/data/') && target.contains('/presentation/')) {
        errors.add('$path: data imports presentation ($target).');
      }
      final to = _module(target);
      if (to != from) (edges[from] ??= {}).add(to);
    }

    // File size (warning).
    final count = lines.length - (text.endsWith('\n') ? 1 : 0);
    if (count > _maxLines) {
      warnings.add('$path: $count lines (soft limit $_maxLines); split it.');
    }
  }

  // core must not depend on app or features.
  for (final to in edges['core'] ?? const <String>{}) {
    if (to != 'core') {
      errors.add('core imports "$to"; core must stay feature-free.');
    }
  }
  // No cycles between features.
  final features = edges.keys.where((m) => m.startsWith('feature:')).toList();
  for (final a in features) {
    for (final b in edges[a] ?? const <String>{}) {
      if (b.startsWith('feature:') && _reaches(edges, b, a)) {
        errors.add('dependency cycle: $a -> $b -> … -> $a');
      }
    }
  }

  for (final warning in warnings) {
    stdout.writeln('warning: $warning');
  }
  for (final error in errors) {
    stdout.writeln('error: $error');
  }
  stdout.writeln(
    errors.isEmpty
        ? 'Rules OK (${files.length} files, ${warnings.length} warnings).'
        : '${errors.length} rule violation(s).',
  );
  exit(errors.isEmpty ? 0 : 1);
}

String _rel(String path, String root) =>
    path.substring(root.length + 1).replaceAll(r'\', '/');

String _dir(String path) => path.substring(0, path.lastIndexOf('/'));

String _normalize(String path) {
  final out = <String>[];
  for (final part in path.split('/')) {
    if (part == '..') {
      if (out.isEmpty) return '../$path';
      out.removeLast();
    } else if (part != '.' && part.isNotEmpty) {
      out.add(part);
    }
  }
  return out.join('/');
}

/// `feature:<name>`, `core`, `app` or `main`.
String _module(String path) {
  final parts = path.split('/');
  if (parts.length > 2 && parts[1] == 'features') return 'feature:${parts[2]}';
  if (parts.length > 2) return parts[1];
  return 'main';
}

bool _reaches(Map<String, Set<String>> edges, String from, String target) {
  final seen = <String>{};
  final stack = [from];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    if (node == target) return true;
    if (!seen.add(node)) continue;
    // Only walk feature-to-feature edges: app/core are composition layers.
    stack.addAll(
      (edges[node] ?? const <String>{}).where((m) => m.startsWith('feature:')),
    );
  }
  return false;
}
