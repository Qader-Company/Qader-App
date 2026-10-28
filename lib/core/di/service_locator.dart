import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_consumer.dart';
import '../network/network_info.dart';
import '../storage/app_preferences.dart';
import '../storage/secure_app_preferences.dart';
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

final GetIt sl = GetIt.instance;

Future<void> initServiceLocator({AppPreferences? preferencesOverride}) async {
  final preferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => preferences);
  sl.registerSingleton<AppPreferences>(
    preferencesOverride ?? await SecureAppPreferences.create(preferences),
  );
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer());
  sl.registerLazySingleton<ProfessionalFieldsRepository>(
    () => ApiProfessionalFieldsRepository(sl<ApiConsumer>()),
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
  sl.registerFactory<RegistrationCubit>(
    () => RegistrationCubit(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AuthSessionCubit>(
    () => AuthSessionCubit(sl<AuthRepository>(), sl<AppPreferences>()),
    dispose: (cubit) => cubit.close(),
  );
}
