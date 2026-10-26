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
    flutter run --dart-define-from-file=tool/flutter.dev.json
    flutter analyze
    flutter test

Cubit, Dio, GetIt, GoRouter, ScreenUtil, localization and the shared theme/widgets
use the original foundation's dependency versions. The dashboard drawer has a language switch.

## Figma screens

Startup follows Splash → Choose role → Sign In → dashboard preview. The new
screens use local Figma SVGs and Poppins (with Rubik for Arabic); the Poppins
license is in assets/fonts/Poppins-OFL.txt. Android/iOS render their own status
and navigation bars.

Talent login is connected to the real API, with secure token storage, automatic
refresh, session restoration and logout. Successful login opens the account
screen with server user data and requires the returned user type to be talent.
Client sign-in retains the labelled preview and does not call Talent endpoints.

Talent registration now submits first_name, last_name, email, password and
password_confirmation to /auth/talent/register. The UI validates both names,
an eight-character minimum password and matching confirmation, displays server
errors, and parses the observed user + verification_token response. The token is
stored securely, separately from access/refresh tokens, and registration opens a
six-digit email verification screen. Client registration remains a local preview.
Both role choices are retained on the authentication routes; the available dashboard
preview is the Talent Under Review design. Social sign-in,
notifications display an unavailable-service message until
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

Local configuration lives in the Git-ignored tool/flutter.dev.json file:

    {
      "APP_ENV": "dev",
      "API_BASE_URL": "https://test.api.qadereg.com/api/v1",
      "API_KEY": "<your-testing-api-key>"
    }

Run with flutter run --dart-define-from-file=tool/flutter.dev.json and select Talent.
X-Authorization is required. The base URL includes /api/v1. Flutter does not load
.env automatically. Never commit populated configuration or tokens.

Implemented: Talent login, registration submission, GET /auth/me, token refresh
and logout. Login/refresh/me/logout contracts were verified against the test API.
A prior Client session is rejected and cleared when /auth/me reports type client.

Registration requires a valid Talent user and verification_token before opening
/verify-email. PATCH /auth/talent/email-verification sends otp using that token.
A success acknowledgement clears the verification token and offers Talent sign-in;
it does not assume a login session. Verification is covered by mocked tests;
the Talent verification request/response still needs confirmation and a live OTP
test. Resend purpose is not confirmed, so resend is not connected.
The route challenge stays in memory and is not resumable after app restart.
Password recovery retains its separate preview flow.

Auth follows data (source, response models, repository implementation), domain
(user entity, repository contract), and presentation (session Cubit and views).
Production DI uses SecureAppPreferences. Tests inject isolated preferences or mock
the secure-storage platform. HTTP debug logs omit headers and response bodies.
Android minimum API is 23 with backups disabled; Apple targets use Keychain.

Firebase, Google sign-in SDK, push notifications, old business features,
branding and platform credentials were not copied. Configure services separately
for Qader if needed. Native platform projects retain Qader's identity.

## UI organization

- core/resources/qader_design.dart: Qader colors and scoped theme.
- core/widgets: reusable buttons, form fields, SVGs, logo and theme wrapper.
  DefaultButton.compact and DefaultFormField(compact: true) provide the mobile style.
  Existing default styles remain available.
- features/auth/domain/entities/account_role.dart: role shared by auth screens.
- features/auth/presentation/view: screen composition and navigation.
- features/auth/presentation/view/widgets: layout, headings, shared fields,
  password visibility, social buttons and forms. Each form owns and disposes
  its controllers and handles validation/submission; each password field owns
  its visibility state.
- features/home/presentation/view/widgets: header, drawer, application review
  banner, submitted notice, steps, profile card and FAQ.

qader_design.dart in core/widgets is a small compatibility export file.
Import individual components when only one is needed. Keep feature-specific
widgets inside the feature; use core/widgets for components shared across features.

## Password recovery and OTP preview

Forget Password opens the email form, validates the address, and offers an
explicit preview of the five-digit OTP screen. The email and role stay in a
typed in-memory route argument. Opening OTP without that argument redirects
to the email form. The OTP component uses the installed Pinput package and
supports paste, numeric input, autofill, and Arabic/Persian digit normalization;
code order remains left to right in Arabic.

Code delivery, resend and verification are not connected to an API. No email
is sent, no demo code is accepted, no reset token is saved, and no password
is changed. Done validates the input length and explains this limitation.
The reset-password form can be added after verification is implemented.

## Onboarding

The onboarding feature contains the three Figma intro screens: opportunities,
team building, and the dashboard overview. PageView handles swiping; Next
advances and Get Started saves the existing onboarding preference before
opening role selection. Later launches skip onboarding. Direct navigation to
/onboarding remains available for previewing the screens.

Artwork uses the local Figma images and individual portrait/connector assets.
DefaultImage.asset reuses the project's image fitting and clipping component.
The team illustration preserves the original coordinates and portrait crops
inside a proportionally scaled artboard. Content scrolls on shorter screens.
The widget test checks all pages, swiping, persistence, repeat launch, and Arabic
at 320 pixels, and saves screenshots under build/design_review/.
