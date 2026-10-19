import 'package:flutter/material.dart';
import '../resources/color_manager.dart';

class DefaultLoading extends StatelessWidget {
  final Color? color;
  const DefaultLoading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: color ?? ColorManager.primary),
    );
  }
}
