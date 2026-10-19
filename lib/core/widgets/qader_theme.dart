import 'package:flutter/material.dart';
import '../resources/qader_design.dart';

class QaderTheme extends StatelessWidget {
  const QaderTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: QaderDesign.theme(context), child: child);
}
