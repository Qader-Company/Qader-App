import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

class DefaultTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final EdgeInsetsGeometry? padding;

  const DefaultTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: ColorManager.fillColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: ColorManager.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: ColorManager.white,
        unselectedLabelColor: ColorManager.greyText,
        labelStyle: getSemiBoldStyle(
          fontSize: 13.sp,
          color: ColorManager.white,
        ),
        unselectedLabelStyle: getRegularStyle(
          fontSize: 13.sp,
          color: ColorManager.greyText,
        ),
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
