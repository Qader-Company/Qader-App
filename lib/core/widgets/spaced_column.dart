import 'package:flutter/material.dart';

/// A stretched [Column] with the same [gap] between every child.
class SpacedColumn extends StatelessWidget {
  const SpacedColumn({super.key, required this.children, this.gap = 16});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}
