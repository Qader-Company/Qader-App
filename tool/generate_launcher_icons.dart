// Run: flutter test --no-pub tool/generate_launcher_icons.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _blue = '#346AE8';
const _centerX = 51.30935;
const _centerY = 26.56655;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate Qader launcher resources from the original vector mark', () async {
    final logo = File('assets/icons/figma/qader_logo.svg').readAsStringSync();
    // These two original paths are the circular brand mark and its dot.
    // Keep the Arabic/English wordmark for in-app use, where it stays readable.
    final paths = RegExp(
      r'<path id="Vector(?:_2)?"[^>]+/>',
    ).allMatches(logo).map((match) => match.group(0)!).toList();
    expect(paths.length, 2);
    final whiteMark = paths.join('\n').replaceAll(_blue, '#FFFFFF');
    final master =
        '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" fill="$_blue"/>
  <g transform="translate(512 512) scale(12.3) translate(-$_centerX -$_centerY)">
    $whiteMark
  </g>
</svg>
''';
    Directory('assets/branding').createSync(recursive: true);
    File('assets/branding/launcher_icon.svg').writeAsStringSync(master);
    final picture = await vg.loadPicture(SvgStringLoader(master), null);
    try {
      await _png(picture, 1024, 'assets/branding/launcher_icon.png');
      for (final density in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries) {
        await _png(
          picture,
          density.value,
          'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png',
        );
      }
      final catalog =
          jsonDecode(
                File(
                  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final sizes = <String, int>{};
      for (final entry in catalog['images'] as List) {
        final size = double.parse((entry['size'] as String).split('x').first);
        final scale = double.parse(
          (entry['scale'] as String).replaceAll('x', ''),
        );
        sizes[entry['filename'] as String] = (size * scale).round();
      }
      for (final entry in sizes.entries) {
        await _png(
          picture,
          entry.value,
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/${entry.key}',
        );
      }
    } finally {
      picture.picture.dispose();
    }

    // 108dp adaptive viewport: the entire mark fits within the central 66dp
    // safe circle, including its detached dot, under every launcher mask.
    final pathData = paths
        .map((path) => RegExp(r'\sd="([^"]+)"').firstMatch(path)!.group(1)!)
        .toList();
    expect(pathData.every((path) => path.startsWith('M')), isTrue);
    final androidPaths = pathData
        .map(
          (data) =>
              '    <path android:fillColor="#FFFFFFFF" android:pathData="$data"/>',
        )
        .join('\n');
    _write(
      'android/app/src/main/res/drawable/ic_launcher_foreground.xml',
      '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
  <group android:translateX="${54 - _centerX * .9}"
      android:translateY="${54 - _centerY * .9}"
      android:scaleX="0.9" android:scaleY="0.9">
$androidPaths
  </group>
</vector>
''',
    );
    _write(
      'android/app/src/main/res/values/launcher_colors.xml',
      '''<?xml version="1.0" encoding="utf-8"?>
<resources>
  <color name="ic_launcher_background">$_blue</color>
</resources>
''',
    );
    for (final version in [26, 33]) {
      _write(
        'android/app/src/main/res/mipmap-anydpi-v$version/ic_launcher.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
${version >= 33 ? '  <monochrome android:drawable="@drawable/ic_launcher_foreground"/>\n' : ''}</adaptive-icon>
''',
      );
    }
  });
}

void _write(String path, String contents) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

Future<void> _png(PictureInfo picture, int size, String path) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(size / 1024);
  canvas.drawPicture(picture.picture);
  final drawing = recorder.endRecording();
  final image = await drawing.toImage(size, size);
  drawing.dispose();
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    expect(file.lengthSync(), greaterThan(64));
  } finally {
    image.dispose();
  }
}
