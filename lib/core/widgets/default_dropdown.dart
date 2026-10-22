import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';
import '../resources/styles_manager.dart';

class DefaultDropdown<T> extends StatelessWidget {
  const DefaultDropdown({
    super.key,
    this.initialValue,
    required this.items,
    this.hint,
    this.label,
    required this.itemLabel,
    this.onChanged,
    this.validator,
    this.compact = false,
    this.icon,
    this.requiredIndicator = false,
  });
  final T? initialValue;
  final List<T> items;
  final String? hint;
  final String? label;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool compact;
  final bool requiredIndicator;
  final Widget? icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text.rich(
          TextSpan(
            text: label!,
            children: [
              if (requiredIndicator)
                const TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          style: compact
              ? const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: Color(0xFF404040),
                )
              : getMediumStyle(fontSize: 14.sp, color: ColorManager.textColor),
        ),
        SizedBox(height: compact ? 6 : 8.h),
      ],
      DropdownButtonFormField<T>(
        initialValue: initialValue,
        isExpanded: true,
        style: compact
            ? Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 20 / 14)
            : null,
        hint: hint == null
            ? null
            : Text(
                hint!,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? const TextStyle(fontSize: 14, color: Color(0xFF737373))
                    : getRegularStyle(
                        fontSize: 12.sp,
                        color: ColorManager.grey,
                      ),
              ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? const TextStyle(fontSize: 14, height: 20 / 14)
                      : getRegularStyle(
                          fontSize: 14.sp,
                          color: ColorManager.textColor,
                        ),
                ),
              ),
            )
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
        validator: validator,
        icon:
            icon ??
            Icon(
              Icons.keyboard_arrow_down,
              color: ColorManager.grey,
              size: compact ? 20 : 24.sp,
            ),
        decoration: InputDecoration(
          filled: compact ? true : null,
          fillColor: compact ? Colors.white : null,
          contentPadding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    ],
  );
}
