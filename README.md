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

## Mobile launcher icon

The mobile launcher uses the original Qader circular mark and dot in white on
the brand blue background. Source artwork is in assets/branding/launcher_icon.svg
with a 1024px PNG preview beside it. Android includes legacy density PNGs, adaptive
icons and a monochrome layer for themed launchers. iOS uses opaque icons for all
sizes in its existing AppIcon catalog; the OS applies the corner mask.

Regenerate from the original logo with:

    flutter test --no-pub tool/generate_launcher_icons.dart

Launcher resources require a fresh build/install; hot reload or restart does not
update them. If the launcher caches the old icon, restart the launcher or device.
Native startup screens stay white without an icon; Android 12+ explicitly uses
a transparent splash drawable in light and dark mode. The Flutter splash screen
and the home-screen launcher icon remain separate from this native startup screen.

## Add a feature

Copy lib/features/_feature_template, rename its files/classes, add models,
implement its repository and Cubit, register dependencies in
lib/core/di/service_locator.dart and routes in lib/core/router/app_router.dart.

## API configuration

### Talent professional field

Signed-in users can open Complete talent profile from the account screen. The
first setup step loads active fields from GET /talent/master-data/professional-fields
and preserves server IDs, names, descriptions and ordering. Continue is disabled
until a field is selected, then PATCH /talent/onboarding/professional-field sends
professional_field_id using the current access token and existing API-key headers.
After the selection acknowledgement, GET /talent/onboarding/form-fields receives
the selected professional_field_id as a query parameter. Both requests must succeed
before Basic Info opens; failures keep the selected card available for retry.
Basic Info, Skills & Experience and Work Preferences only render keys returned
by this endpoint. Entire sections and their validators are omitted when no
corresponding key is returned; projects and experiences use their parent array keys.
Changing the professional field invalidates the previous field set.
There is no preset field in the connected flow. Names and
descriptions are shown as supplied by the backend, including new/untranslated fields.
The signed-out drawer preview retains its local sample fields and job titles.
Basic Info Next validates the visible fields and POSTs multipart data to
/talent/onboarding/personal-information. Phone and WhatsApp country codes are
entered separately. Selected lookup IDs/codes are used directly, languages use
languages[index][language_id] and languages[index][proficiency_level], and CV
is uploaded from file bytes or its device path. Email is not submitted. The
request uses the existing access-token/API-key headers and a generated multipart
boundary. Only success:true opens Skills & Experience; errors preserve the draft
for retry. Duplicate submits and navigation/editing while saving are blocked.
Live genders and religions load value/label options; countries and languages
load id/name options; currencies retain their server IDs while displaying codes
and names. Nationality and residence share the country list. City requests include
country_id and clear the previous selection on a country change; stale responses
cannot overwrite the new country results. Lists load only when their form fields
are visible, with loading, empty and retry states. All use the current access token.
Entering a connected setup step also retries missing or failed lists while reusing
successful cached options and in-flight requests.
Language proficiencies load value/label options from GET
/talent/master-data/language-proficiencies when languages are visible, retaining
lowercase API codes such as b1 and native. Jobs, skills and tools send the selected
professional_field_id; changing professions clears their cached options/selections
and invalidates pending requests. Industries use their own master-data list.
Seniority, work types and work modes use API value/label options. Skills, tools,
industries, work types and modes support multiple selections.
Skills & Experience Next POSTs multipart data to
/talent/onboarding/skills-and-experiences, including indexed experience/project
records and projects[index][images][index] file uploads (up to 5 MB per image).
Work Preferences saves JSON to /talent/onboarding/work-preferences with API enum
arrays, boolean relocation, notice days (0–365), numeric salary ranges and currency
IDs. Both whitelist visible step keys, await success:true, preserve failed drafts
for retry and block duplicate requests. The final connected screen confirms saving
and returns to Account; it does not claim an application review status.
The signed-out wizard remains a local preview. Talent sign-in and authenticated
Splash launches now GET /talent/onboarding using the supplied progress contract.
The server's current_step chooses the resumed screen; required_steps_completed
routes returning completed accounts to Account. Missing professional fields open
field selection. All three steps restore their saved values, nested IDs, dates,
languages, CV metadata and project media metadata. Existing CVs are retained by
omitting the upload unless replaced; project/experience updates include server IDs.
Every successful save re-reads progress, so completed later steps can be skipped.
A failed progress read blocks editing with retry, preserving the draft without
repeating a successful POST. Session expiry exits the connected wizard.
Only server-saved data survives restarting; unsaved typing is not auto-saved.
These flows are covered by mocked tests and still need live verification,
including retaining an existing CV when the upload is omitted on an update.

### Local environment

Local configuration lives in the Git-ignored tool/flutter.dev.json file:

    {
      "APP_ENV": "dev",
      "API_BASE_URL": "https://test.api.qadereg.com/api/v1",
      "API_KEY": "<your-testing-api-key>"
    }

Run with flutter run --dart-define-from-file=tool/flutter.dev.json and select Talent.
In VS Code, select Qader (Dev API) in Run and Debug and press F5; this launch
configuration loads the same local file. Stop and relaunch after changing build
defines; hot reload and hot restart do not load new build-time values.
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
test. Resend is connected to POST /auth/talent/email-verification/send-otp
with the registration email and the configured API key (no session Bearer).
It requires a success acknowledgement, retains the verification credential unless
the response provides a replacement, and prevents overlapping resend/verify requests.
The resend headers and response schema still need live API confirmation.
The route challenge stays in memory and is not resumable after app restart.
Talent password recovery now has a separate API flow; Client recovery retains its preview.

Auth follows data (source, response models, repository implementation), domain
(user entity, repository contract), and presentation (session Cubit and views).
Production DI uses SecureAppPreferences. Tests inject isolated preferences or mock
the secure-storage platform. HTTP debug logs show response status, redacted JSON
bodies and network error types. Request bodies, headers and URL queries are omitted;
token, password, OTP and other credential fields are redacted recursively.
Non-JSON text bodies are omitted. HTTP logging is disabled outside debug builds.
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

## Password recovery

Talent recovery sends the email to POST /auth/talent/password-reset/send-otp
(the existing password-reset purpose still needs live confirmation), then sends
email and a six-digit otp to POST /auth/talent/reset-password-verification.
Both requests use X-Authorization and Accept with no session Bearer.
The verification parser expects success: true and data.reset_password_token,
as a nonempty string or an object containing token. This response shape is
inferred from the reset_password_token variable and the existing auth responses;
it still needs confirmation against a live response. Missing tokens block reset.
The reset credential is stored separately in secure storage and sent as Bearer
to POST /auth/talent/reset-password with password and password_confirmation.
Successful acknowledgement clears the reset credential and offers sign-in;
it never creates a login session. The UI validates eight-character passwords and
matching confirmation, displays server errors, supports resend, and prevents
overlapping requests. Recovery progress stays in memory and restarts after closing
the screen or restarting the app. Tests mock the backend; live OTP delivery and
password change have not been tested.

### Client recovery preview

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
The team illustration uses the original Connected Team Network image from Figma
node 4731:77358 in its 382 × 303 slot at (4, 25) within the illustration artboard.
The dashboard image matches the original asset in Figma node 4707:77303.
Content scrolls on shorter screens.
The widget test checks all pages, swiping, persistence, repeat launch, and Arabic
at 320 pixels, and saves screenshots under build/design_review/.
