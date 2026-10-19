import 'package:flutter/material.dart';
import '../../../../../core/resources/assets_manager.dart';
import '../../../../../core/widgets/default_image.dart';
import '../../../../../core/widgets/qader_asset.dart';

/// Figma's seven portraits and connector SVGs, on a 390 x 349 artboard.
class OnboardingTeamArtwork extends StatelessWidget {
  const OnboardingTeamArtwork({super.key});
  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      // Connector positions include the half-pixel stroke bounds from Figma.
      Positioned(left: 193.5, top: 65.5, child: QaderAsset('intro_line_10')),
      Positioned(left: 80, top: 115.5, child: QaderAsset('intro_line_11')),
      Positioned(left: 72, top: 244.5, child: QaderAsset('intro_line_11')),
      Positioned(left: 73, top: 115.556, child: QaderAsset('intro_line_13')),
      Positioned(
        left: 81.255,
        top: 115.565,
        child: QaderAsset('intro_line_14'),
      ),
      Positioned(
        left: 223.23,
        top: 249.579,
        child: QaderAsset('intro_line_15'),
      ),
      Positioned(
        left: 72.212,
        top: 247.091,
        child: QaderAsset('intro_line_16'),
      ),
      Positioned(left: 342, top: 142, child: QaderAsset('intro_line_17')),
      Positioned(left: 45, top: 150.5, child: QaderAsset('intro_line_18')),
      Positioned(left: 67.73, top: 30.579, child: QaderAsset('intro_line_19')),
      Positioned(left: 227.26, top: 29.062, child: QaderAsset('intro_line_20')),
      _Portrait(
        index: 0,
        left: 163,
        top: 0,
        imageHeight: 96.1024,
        offset: Offset(.1216, -3.3536),
      ),
      _Portrait(
        index: 1,
        left: 163,
        top: 285,
        imageHeight: 80,
        offset: Offset(.3712, -.2816),
      ),
      _Portrait(
        index: 2,
        left: 318,
        top: 84,
        imageHeight: 96,
        offset: Offset(0, -5.1712),
      ),
      _Portrait(index: 3, left: 16, top: 84),
      _Portrait(
        index: 4,
        left: 310,
        top: 213,
        imageHeight: 75.8784,
        offset: Offset(-.0256, -3.3856),
      ),
      _Portrait(index: 5, left: 163, top: 143),
      _Portrait(index: 6, left: 16, top: 213),
    ],
  );
}

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.index,
    required this.left,
    required this.top,
    this.imageHeight = 64,
    this.offset = Offset.zero,
  });
  final int index;
  final double left;
  final double top;
  final double imageHeight;
  final Offset offset;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: 64,
    height: 64,
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB4CBF6)),
      ),
      child: ClipOval(
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: 64,
              height: imageHeight,
              child: DefaultImage.asset(
                assetPath: ImageAssets.introAvatars[index],
                radius: 0,
                fit: imageHeight == 64 ? BoxFit.cover : BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
