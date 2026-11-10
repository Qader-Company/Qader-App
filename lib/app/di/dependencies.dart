import '../../core/di/service_locator.dart';
import '../router/app_routes.dart';
import '../../core/widgets/app_drawer.dart';
import '../../features/home/presentation/view/widgets/home_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_consumer.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/storage/secure_app_preferences.dart';
import '../../features/auth/data/datasources/talent_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/talent_auth_repository.dart';
import '../../features/auth/data/repositories/password_recovery_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_session_cubit.dart';
import '../../features/auth/presentation/cubit/registration_cubit.dart';
import '../../features/profile_setup/domain/repositories/professional_fields_repository.dart';
import '../../features/profile_setup/data/repositories/api_professional_fields_repository.dart';
import '../../features/profile_setup/domain/repositories/onboarding_steps_repository.dart';
import '../../features/profile_setup/data/repositories/api_onboarding_steps_repository.dart';
import '../../features/profile_setup/domain/repositories/profile_lookups_repository.dart';
import '../../features/profile_setup/data/repositories/api_profile_lookups_repository.dart';
import '../../features/profile_setup/domain/repositories/onboarding_progress_repository.dart';
import '../../features/profile_setup/data/repositories/api_onboarding_progress_repository.dart';

import '../../features/home/data/application_repository.dart';
import '../../features/home/presentation/cubit/application_cubit.dart';

export '../../core/di/service_locator.dart';

/// Composition root: registers every dependency and wires the
/// cross-feature slots (side drawer, router).
Future<void> initServiceLocator({AppPreferences? preferencesOverride}) async {
  final preferences = await SharedPreferences.getInstance();
  AppRouter.configure(buildAppRouter);
  // Features build the side drawer through this slot (no cross imports).
  AppDrawer.register(
    (current, preview) => HomeDrawer(current: current, preview: preview),
  );
  sl.registerLazySingleton<SharedPreferences>(() => preferences);
  sl.registerSingleton<AppPreferences>(
    preferencesOverride ?? await SecureAppPreferences.create(preferences),
  );
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer());
  sl.registerLazySingleton<ProfessionalFieldsRepository>(
    () => ApiProfessionalFieldsRepository(sl<ApiConsumer>()),
  );
  sl.registerLazySingleton<OnboardingProgressRepository>(
    () => ApiOnboardingProgressRepository(sl<ApiConsumer>()),
  );
  sl.registerLazySingleton<OnboardingStepsRepository>(
    () => ApiOnboardingStepsRepository(sl<ApiConsumer>()),
  );
  sl.registerLazySingleton<ProfileLookupsRepository>(
    () => ApiProfileLookupsRepository(sl<ApiConsumer>()),
  );
  sl.registerLazySingleton<TalentAuthRemoteDataSource>(
    () => TalentAuthRemoteDataSource(sl<ApiConsumer>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => TalentAuthRepository(
      sl<TalentAuthRemoteDataSource>(),
      sl<AppPreferences>(),
    ),
  );
  sl.registerLazySingleton<PasswordRecoveryRepository>(
    () => PasswordRecoveryRepository(
      sl<TalentAuthRemoteDataSource>(),
      sl<AppPreferences>(),
    ),
  );
  sl.registerLazySingleton<ApplicationRepository>(
    () => ApplicationRepository(sl<ApiConsumer>()),
  );
  sl.registerFactory<ApplicationCubit>(
    () => ApplicationCubit(sl<ApplicationRepository>()),
  );
  sl.registerFactory<RegistrationCubit>(
    () => RegistrationCubit(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AuthSessionCubit>(
    () => AuthSessionCubit(sl<AuthRepository>(), sl<AppPreferences>()),
    dispose: (cubit) => cubit.close(),
  );
}
