import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';
import '../resources/qader_design.dart';
import '../resources/styles_manager.dart';

class DefaultButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final double? radius;
  final bool isOutlined;
  final bool isLoading;
  final Widget? icon;
  final TextStyle? textStyle;
  final Widget? child;
  final bool expand;
  final EdgeInsetsGeometry? padding;

  const DefaultButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
    this.radius,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.textStyle,
    this.child,
    this.expand = true,
    this.padding,
  });

  /// Compact style for Qader's forms and dashboard cards.
  const DefaultButton.compact({
    super.key,
    this.text = '',
    this.onPressed,
    this.color = QaderDesign.primary,
    this.textColor,
    this.width,
    this.height = 40,
    this.fontSize = 14,
    this.radius = 8,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.textStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    this.child,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? ColorManager.primary;
    final borderRadius = BorderRadius.circular(radius ?? 12.r);

    if (isOutlined) {
      return SizedBox(
        width: width ?? (expand ? double.infinity : null),
        height: height ?? 50.h,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            side: BorderSide(color: buttonColor),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
          ),
          child: _buildChild(textColor ?? buttonColor),
        ),
      );
    }

    return SizedBox(
      width: width ?? (expand ? double.infinity : null),
      height: height ?? 50.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: buttonColor,
          foregroundColor: ColorManager.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: _buildChild(textColor ?? ColorManager.white),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20.h,
        width: 20.h,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }

    if (child != null) return child!;

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          SizedBox(width: 8.w),
          Text(
            text,
            style:
                (textStyle ??
                        getBoldStyle(fontSize: fontSize ?? 15.sp, color: color))
                    .copyWith(color: color),
          ),
        ],
      );
    }

    return Text(
      text,
      style:
          (textStyle ?? getBoldStyle(fontSize: fontSize ?? 15.sp, color: color))
              .copyWith(color: color),
    );
  }
}
