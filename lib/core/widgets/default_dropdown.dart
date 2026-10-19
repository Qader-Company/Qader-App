import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

class DefaultDropdown<T> extends StatelessWidget {
  final T? initialValue;
  final List<T> items;
  final String? hint;
  final String? label;
  final String Function(T item) itemLabel;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const DefaultDropdown({
    super.key,
    this.initialValue,
    required this.items,
    this.hint,
    this.label,
    required this.itemLabel,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: getMediumStyle(
              fontSize: 14.sp,
              color: ColorManager.textColor,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        DropdownButtonFormField<T>(
          hint: hint != null
              ? Text(
                  hint!,
                  style: getRegularStyle(
                    fontSize: 12.sp,
                    color: ColorManager.grey,
                  ),
                )
              : null,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: getRegularStyle(
                      fontSize: 14.sp,
                      color: ColorManager.textColor,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ColorManager.grey,
            size: 24.sp,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }
}
