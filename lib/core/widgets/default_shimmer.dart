import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';

class DefaultShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double? radius;

  const DefaultShimmer({super.key, this.width, this.height, this.radius});

  @override
  State<DefaultShimmer> createState() => _DefaultShimmerState();
}

class _DefaultShimmerState extends State<DefaultShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.3,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 20.h,
        decoration: BoxDecoration(
          color: ColorManager.shimmerBase,
          borderRadius: BorderRadius.circular(widget.radius ?? 8.r),
        ),
      ),
    );
  }
}
