import 'package:flutter/material.dart';
import '../resources/app_colors.dart';

/// Runs one shimmer sweep for every [SkeletonBox] below it, while a screen
/// loads. With reduced motion the boxes stay still.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  static Animation<double>? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    // One announcement for the whole placeholder, not one per box.
    label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
    child: ExcludeSemantics(
      child: _ShimmerScope(animation: _controller, child: widget.child),
    ),
  );
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});
  final Animation<double> animation;
  @override
  bool updateShouldNotify(_ShimmerScope old) => animation != old.animation;
}

/// A grey placeholder bar, box or circle that shimmers under a [Shimmer].
///
/// Repaints on each animation frame without rebuilding.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.radius = 6,
  }) : circle = false;

  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 0,
      circle = true;

  final double width, height, radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: _BonePainter(
        animation: Shimmer._of(context),
        radius: radius,
        circle: circle,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    ),
  );
}

class _BonePainter extends CustomPainter {
  _BonePainter({
    required this.animation,
    required this.radius,
    required this.circle,
    required this.rtl,
  }) : super(repaint: animation);
  final Animation<double>? animation;
  final double radius;
  final bool circle, rtl;

  static const _base = AppColors.neutral200;
  static const _highlight = AppColors.neutral100;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..color = _base;
    final t = animation?.value;
    if (t != null) {
      // The highlight travels from the reading start to the reading end.
      final center = -0.4 + t * 1.8;
      paint.shader = LinearGradient(
        begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
        end: rtl ? Alignment.centerLeft : Alignment.centerRight,
        colors: const [_base, _highlight, _base],
        stops: [
          (center - 0.35).clamp(0.0, 1.0),
          center.clamp(0.0, 1.0),
          (center + 0.35).clamp(0.0, 1.0),
        ],
      ).createShader(rect);
    }
    if (circle) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BonePainter old) =>
      old.animation != animation ||
      old.radius != radius ||
      old.circle != circle ||
      old.rtl != rtl;
}

/// A white rounded card with a light border, for skeleton layouts.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(12),
    this.gap = 10,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double gap;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.neutral200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    ),
  );
}

/// "Label" bar above an input-sized box, like a form field.
class SkeletonField extends StatelessWidget {
  const SkeletonField({super.key, this.labelWidth = 90, this.height = 40});
  final double labelWidth, height;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBox(width: labelWidth, height: 10),
      const SizedBox(height: 8),
      SkeletonBox(height: height, radius: 8),
    ],
  );
}
