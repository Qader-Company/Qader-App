import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension MaybeRead on BuildContext {
  /// [read] that returns `null` when no provider of [T] is above this
  /// context (e.g. a widget pumped alone in a test or preview).
  T? maybeRead<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
