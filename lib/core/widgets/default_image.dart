import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';

class DefaultImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double? radius;
  final BoxFit fit;

  const DefaultImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 8.r),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => Container(
                width: width,
                height: height,
                color: ColorManager.shimmerBase,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                width: width,
                height: height,
                color: ColorManager.shimmerBase,
                child: Icon(
                  Icons.image_not_supported,
                  size: 24.sp,
                  color: ColorManager.grey,
                ),
              ),
            )
          : Container(
              width: width,
              height: height,
              color: ColorManager.shimmerBase,
              child: Icon(Icons.image, size: 24.sp, color: ColorManager.grey),
            ),
    );
  }
}
