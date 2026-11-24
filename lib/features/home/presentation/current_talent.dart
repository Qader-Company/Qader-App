import 'package:flutter/widgets.dart';
import '../../../core/di/maybe_read.dart';
import '../../../core/storage/app_preferences.dart';
import '../../auth/presentation/cubit/auth_session_cubit.dart';

/// The signed-in talent's name: the session's, otherwise the one saved at
/// sign-in; empty when unknown (signed out or a preview).
String currentTalentName(BuildContext context) {
  final user = context.maybeRead<AuthSessionCubit>()?.state.user;
  if (user != null && user.fullName.isNotEmpty) return user.fullName;
  return context.maybeRead<AppPreferences>()?.getUserName() ?? '';
}

/// The signed-in talent's email, from the session or the saved one.
String currentTalentEmail(BuildContext context) =>
    context.maybeRead<AuthSessionCubit>()?.state.user?.email ??
    context.maybeRead<AppPreferences>()?.getUserEmail() ??
    '';
