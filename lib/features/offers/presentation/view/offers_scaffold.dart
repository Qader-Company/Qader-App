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
    this.onRefresh,
  });
  final Widget header;
  final List<Widget> children;

  /// Enables pull to refresh.
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      child: SpacedColumn(children: [header, ...children]),
    );
    final refresh = onRefresh;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer.build(current: AppDrawerItem.offers),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: refresh == null
                ? scroll
                : RefreshIndicator(onRefresh: refresh, child: scroll),
          ),
        ),
      ),
    );
  }
}
