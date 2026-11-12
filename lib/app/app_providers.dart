import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/service_locator.dart';
import '../core/storage/app_preferences.dart';
import '../features/auth/data/repositories/password_recovery_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_session_cubit.dart';
import '../features/home/domain/repositories/application_repository.dart';
import '../features/profile_setup/domain/repositories/onboarding_progress_repository.dart';
import '../features/profile_setup/domain/repositories/onboarding_steps_repository.dart';
import '../features/profile_setup/domain/repositories/professional_fields_repository.dart';
import '../features/profile_setup/domain/repositories/profile_lookups_repository.dart';
import '../features/talent_profile/domain/repositories/talent_profile_repository.dart';

/// Hands the registered dependencies to the widget tree, so screens use
/// `context.read<T>()` instead of the service locator. Providers are lazy:
/// a dependency is looked up only when a screen first reads it.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AppPreferences>(create: (_) => sl()),
      // App-wide session; RepositoryProvider so the tree never closes it.
      RepositoryProvider<AuthSessionCubit>(create: (_) => sl()),
      RepositoryProvider<AuthRepository>(create: (_) => sl()),
      RepositoryProvider<PasswordRecoveryRepository>(create: (_) => sl()),
      RepositoryProvider<ApplicationRepository>(create: (_) => sl()),
      RepositoryProvider<ProfessionalFieldsRepository>(create: (_) => sl()),
      RepositoryProvider<ProfileLookupsRepository>(create: (_) => sl()),
      RepositoryProvider<OnboardingStepsRepository>(create: (_) => sl()),
      RepositoryProvider<TalentProfileRepository>(create: (_) => sl()),
      // Optional: profile setup works without saved-progress restore.
      if (sl.isRegistered<OnboardingProgressRepository>())
        RepositoryProvider<OnboardingProgressRepository>(create: (_) => sl()),
    ],
    child: child,
  );
}
