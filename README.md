# Qader-App

Independent Flutter project using the shared foundation from ShelfSpot.

## Structure

- lib/app: app root and dev/staging/prod environment configuration.
- lib/core: base_classes, bloc, di, extensions, helpers, locale, network,
  pagination, resources, router, storage, usecase and shared widgets.
- lib/features/auth/presentation/view: splash, role selection, sign-in and account creation screens.
- lib/features/home/presentation/view: Talent dashboard in the Under Review state.
- lib/features/_feature_template: data/models, data/repo, presentation/cubit,
  presentation/view and presentation/view/widgets.
- assets: Rubik fonts, Arabic/English translations, images, icons, json and gifs.

## Run and verify

    flutter pub get
    flutter run
    flutter analyze
    flutter test

Cubit, Dio, GetIt, GoRouter, ScreenUtil, localization and the shared theme/widgets
use the original foundation's dependency versions. The dashboard drawer has a language switch.

## Figma screens

Startup follows Splash → Choose role → Sign In → dashboard preview. The new
screens use local Figma SVGs and Poppins (with Rubik for Arabic); the Poppins
license is in assets/fonts/Poppins-OFL.txt. Android/iOS render their own status
and navigation bars.

Authentication is not connected: submitting valid fields offers a clearly
labelled preview with sample Talent data and never saves a session/token.
Account creation opens from the sign-up link, validates name/email, an eight-character
minimum password and matching confirmation, and supports separate visibility toggles.
Submitting valid details explains that registration is not connected; nothing is sent
or saved. The sign-in link returns to the previous form, retaining the selected role.
Both role choices are retained on the authentication routes; the available dashboard
preview is the Talent Under Review design. Social sign-in,
password reset and notifications display an unavailable-service message until
their services are implemented. Profile editing is locked during review.
FAQ answers beyond the first are provisional copy pending product review.

The widget test checks the complete flow, form validation, password visibility,
FAQ expansion, locale switching, and 320-pixel Arabic layouts. It also writes
review screenshots to build/design_review/.

## Add a feature

Copy lib/features/_feature_template, rename its files/classes, add models,
implement its repository and Cubit, register dependencies in
lib/core/di/service_locator.dart and routes in lib/core/router/app_router.dart.

## API configuration

Startup does not call an API. api.example.com and auth paths are placeholders.
Set Qader's URL with --dart-define=API_BASE_URL=https://your-api.example/api/v1
and environment with --dart-define=APP_ENV=prod (also dev or staging).
Supply API_KEY only if the new backend requires it. .env.example documents
these values; Flutter does not load .env automatically.
Adapt end_points.dart, the token refresh request/response contract and the
session-expired destination in app_interceptors.dart when adding authentication.
GoLoginWidget takes an onLogin callback for the future authentication feature.

Firebase, Google sign-in SDK, push notifications, old business features,
branding and platform credentials were not copied. Configure services separately
for Qader if needed. Native platform projects retain Qader's identity.
