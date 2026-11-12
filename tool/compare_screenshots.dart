// Compares the screenshots that widget tests render, before and after a
// change, so UI that should not change stays pixel-identical.
//
//   dart run tool/compare_screenshots.dart save      # before the change
//   flutter test                                     # after the change
//   dart run tool/compare_screenshots.dart compare
//
// Tests write PNGs to build/design_review and build/phone-preview; `save`
// copies them to build/screenshot_baseline. Exits with code 1 when any
// screenshot changed or disappeared.
import 'dart:io';

const _sources = ['build/design_review', 'build/phone-preview'];
const _baseline = 'build/screenshot_baseline';

void main(List<String> args) {
  switch (args.firstOrNull) {
    case 'save':
      _save();
    case 'compare':
      exit(_compare());
    default:
      stdout.writeln(
        'usage: dart run tool/compare_screenshots.dart save|compare',
      );
      exit(2);
  }
}

Map<String, File> _current() => {
  for (final source in _sources)
    if (Directory(source).existsSync())
      for (final file in Directory(source).listSync(recursive: true))
        if (file is File && file.path.endsWith('.png')) _rel(file.path): file,
};

String _rel(String path) => path.replaceAll(r'\', '/');

void _save() {
  final baseline = Directory(_baseline);
  if (baseline.existsSync()) baseline.deleteSync(recursive: true);
  final files = _current();
  if (files.isEmpty) {
    stdout.writeln('No screenshots found. Run `flutter test` first.');
    exit(1);
  }
  for (final entry in files.entries) {
    final target = File('$_baseline/${entry.key}');
    target.parent.createSync(recursive: true);
    entry.value.copySync(target.path);
  }
  stdout.writeln('Saved ${files.length} screenshots to $_baseline.');
}

int _compare() {
  final baseline = Directory(_baseline);
  if (!baseline.existsSync()) {
    stdout.writeln('No baseline. Run `save` before the change.');
    return 2;
  }
  final before = {
    for (final file in baseline.listSync(recursive: true))
      if (file is File) _rel(file.path).substring(_baseline.length + 1): file,
  };
  final after = _current();
  final changed = <String>[];
  final missing = <String>[];
  for (final entry in before.entries) {
    final now = after[entry.key];
    if (now == null) {
      missing.add(entry.key);
    } else if (!_same(entry.value, now)) {
      changed.add(entry.key);
    }
  }
  final added = after.keys.where((key) => !before.containsKey(key)).toList();
  stdout.writeln(
    'identical: ${before.length - changed.length - missing.length}, '
    'changed: ${changed.length}, missing: ${missing.length}, new: ${added.length}',
  );
  for (final path in changed) {
    stdout.writeln('  changed  $path');
  }
  for (final path in missing) {
    stdout.writeln('  missing  $path');
  }
  for (final path in added) {
    stdout.writeln('  new      $path');
  }
  return changed.isEmpty && missing.isEmpty ? 0 : 1;
}

bool _same(File a, File b) {
  final x = a.readAsBytesSync();
  final y = b.readAsBytesSync();
  if (x.length != y.length) return false;
  for (var i = 0; i < x.length; i++) {
    if (x[i] != y[i]) return false;
  }
  return true;
}
