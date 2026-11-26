import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/route_args.dart';
import '../domain/entities/account_role.dart';
import '../domain/entities/auth_user.dart';

/// Where a signed-in account lands. Talents resume profile setup (which
/// moves on by itself once the profile is done); clients open their account
/// until the client workspace screens exist.
void goToSignedInHome(BuildContext context, AuthUser user) {
  if (user.role == AccountRole.client) {
    context.go(AppRouter.account);
    return;
  }
  context.go(
    AppRouter.profileSetup,
    extra: ProfileSetupSeed(name: user.fullName, email: user.email),
  );
}
