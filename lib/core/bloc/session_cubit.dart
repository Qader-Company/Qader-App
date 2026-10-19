import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/service_locator.dart';
import '../storage/app_preferences.dart';

/// Discards async results after disposal or a change of signed-in user.
abstract class SessionCubit<S> extends Cubit<S> {
  SessionCubit(super.initialState)
    : _revision = sl<AppPreferences>().sessionRevision.value;

  final int _revision;

  bool get isSessionActive =>
      !isClosed && sl<AppPreferences>().sessionRevision.value == _revision;

  @override
  void emit(S state) {
    if (isSessionActive) super.emit(state);
  }
}
