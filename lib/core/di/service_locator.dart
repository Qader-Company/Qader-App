import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_consumer.dart';
import '../network/network_info.dart';
import '../storage/app_preferences.dart';

final GetIt sl = GetIt.instance;

Future<void> initServiceLocator() async {
  final preferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => preferences);
  sl.registerLazySingleton<AppPreferences>(
    () => AppPreferencesImpl(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<ApiConsumer>(() => DioConsumer());
  // Register Qader feature repositories and cubits here.
}
