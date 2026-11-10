import 'package:get_it/get_it.dart';

/// The app-wide service locator. Registrations live in the composition
/// root: `lib/app/di/dependencies.dart` (`initServiceLocator`).
final GetIt sl = GetIt.instance;
