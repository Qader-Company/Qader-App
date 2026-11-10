/// Environment configuration supplied at build time.
///
/// Example:
/// `flutter build appbundle --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com/api/v1 --dart-define=API_KEY=...`
enum Environment { dev, staging, prod }

class AppEnv {
  static late AppEnv _instance;
  static AppEnv get instance => _instance;

  final Environment environment;
  final String baseUrl;
  final String appName;
  final String apiKey;
  final Duration splashDuration;

  AppEnv._({
    required this.environment,
    required this.baseUrl,
    required this.appName,
    required this.apiKey,
    this.splashDuration = Duration.zero,
  });

  static void init(Environment env, {Duration splashDuration = Duration.zero}) {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    const configuredApiKey = String.fromEnvironment('API_KEY');
    final baseUrl = configuredBaseUrl.isNotEmpty
        ? configuredBaseUrl
        : 'https://api.example.com/api/v1';
    switch (env) {
      case Environment.dev:
        _instance = AppEnv._(
          environment: Environment.dev,
          baseUrl: baseUrl,
          appName: 'Qader (Dev)',
          apiKey: configuredApiKey,
          splashDuration: splashDuration,
        );
        break;
      case Environment.staging:
        _instance = AppEnv._(
          environment: Environment.staging,
          baseUrl: baseUrl,
          appName: 'Qader (Staging)',
          apiKey: configuredApiKey,
          splashDuration: splashDuration,
        );
        break;
      case Environment.prod:
        _instance = AppEnv._(
          environment: Environment.prod,
          baseUrl: baseUrl,
          appName: 'Qader',
          apiKey: configuredApiKey,
          splashDuration: splashDuration,
        );
        break;
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
  bool get hasApiKey => apiKey.trim().isNotEmpty;
}
