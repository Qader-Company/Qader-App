# Qader App

Flutter app for Qader talents: sign-up and sign-in, profile setup (onboarding)
and the application / interview status flow.

Architecture, coding rules and the verification checklist are in
**[AGENTS.md](AGENTS.md)**. Read it before changing code; humans and AI agents
follow the same rules.

## Setup

1. Install Flutter (stable, the version pinned in `.github/workflows/ci.yml`).
2. Create the Git-ignored `tool/flutter.dev.json`:

   ```json
   {
     "APP_ENV": "dev",
     "API_BASE_URL": "https://test.api.qadereg.com/api/v1",
     "API_KEY": "<your-testing-api-key>"
   }
   ```

   Never commit this file or paste its contents anywhere. Flutter does not read
   `.env`; build-time values need a full restart (not hot reload) to change.
3. `flutter pub get`

## Run and build

| Task | Command |
|---|---|
| Run (debug) | `flutter run --dart-define-from-file=tool/flutter.dev.json` |
| Profile performance | `flutter run --profile --dart-define-from-file=tool/flutter.dev.json` |
| Release APK | `flutter build apk --release --dart-define-from-file=tool/flutter.dev.json` |

In VS Code, the **Qader (Dev API)** launch configuration loads the same file.
Don't run two builds of this project at the same time. If a build fails with
"file in use" errors, run `cd android; ./gradlew --stop` and `flutter clean`.

## Verify a change

```
dart format lib test tool
flutter analyze
dart run tool/check_rules.dart
flutter test
```

CI runs the same four steps on every push and pull request. For UI or refactor
work, also compare screenshots before and after:

```
flutter test; dart run tool/compare_screenshots.dart save      # before
flutter test; dart run tool/compare_screenshots.dart compare   # after
```

Widget tests write review screenshots to `build/design_review/`.

## Project layout

```
lib/
├── main.dart
├── app/        composition root: app, providers, dependency registration, routes
├── core/       network, storage, colors/theme, route paths, env, shared widgets
└── features/
    ├── auth/           sign-up, email verification, sign-in, password recovery, session
    ├── profile_setup/  onboarding steps, master-data lookups, CV autofill
    ├── home/           application status and interview actions
    ├── talent_profile/ profile screens (sample data; API not connected yet)
    └── onboarding/     intro screens
test/           mirrors lib/ (app/, core/, features/<feature>/)
tool/           check_rules.dart, compare_screenshots.dart, launcher icon generator
```

## Feature status

| Feature | Status |
|---|---|
| Auth (talent) | Connected: register, verify email, sign in, refresh, `/auth/me`, logout, password recovery. Google/Apple sign-in and client accounts are not connected yet. |
| Profile setup | Connected: professional field, form fields, three steps, progress restore, master data, CV autofill (`onboarding/resume/parse`). |
| Home / status | Connected: `GET /talent/application`, select slot, reject all slots, cancel interview. |
| Talent profile | Sample data only (`presentation/preview/`). |

Sample data shown when logged out or on preview routes lives only in each
feature's `presentation/preview/` folder.

## Design

- Figma: https://www.figma.com/design/Ey9gKqsJd8qx1aBMgefEQB/qader-app
- Colors come from `lib/core/resources/app_colors.dart` (Figma/Tailwind scale).
- Fonts: Poppins (Rubik for Arabic). The Poppins license is in `assets/fonts/Poppins-OFL.txt`.
- Translations: `assets/translations/en-US.json` and `ar-SA.json`.

## Mobile launcher icon

Source artwork is `assets/branding/launcher_icon.svg`. Regenerate the Android and
iOS icons with:

```
flutter test --no-pub tool/generate_launcher_icons.dart
```

Launcher icons need a fresh install; hot reload or restart does not update them.
