import 'package:flutter/material.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/spaced_column.dart';

/// White drawer page, centered up to 430 wide, scrolling [header] and
/// [children] with the design's 16 px gaps.
class OffersScaffold extends StatelessWidget {
  const OffersScaffold({
    super.key,
    required this.header,
    required this.children,
    this.current = AppDrawerItem.offers,
  });
  final Widget header;
  final List<Widget> children;
  final AppDrawerItem current;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    drawer: AppDrawer.build(current: current),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: SpacedColumn(children: [header, ...children]),
          ),
        ),
      ),
    ),
  );
}
