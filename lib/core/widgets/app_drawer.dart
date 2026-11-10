import 'package:flutter/material.dart';

/// Which drawer entry is highlighted.
enum AppDrawerItem { home, profile }

/// The app's side drawer, as a slot.
///
/// Several features show the same drawer, and the drawer itself links to
/// several features. To keep features from importing each other, they build
/// it through this slot and the composition root (`initServiceLocator`)
/// registers the real drawer.
abstract final class AppDrawer {
  static Widget Function(AppDrawerItem current, bool preview)? _builder;

  static void register(
    Widget Function(AppDrawerItem current, bool preview) builder,
  ) => _builder = builder;

  static Widget build({
    AppDrawerItem current = AppDrawerItem.home,
    bool preview = true,
  }) => _builder?.call(current, preview) ?? const Drawer();
}
