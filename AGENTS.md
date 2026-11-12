# Qader — rules for AI agents

These rules are mandatory for every change in this repository. Follow them
without being reminded. If a task seems to need breaking a rule, stop and ask
the user first; never break one silently.

Talk to the user in Egyptian Arabic. Write code, comments, commit messages and
identifiers in English.

## 1. Architecture (feature-first Clean Architecture, "lite")

```
lib/
├── main.dart
├── app/            composition root: app.dart, app_providers.dart, di/, router/
├── core/           shared, feature-agnostic: network, storage, resources, router (paths only), env, widgets
└── features/<feature>/
    ├── domain/         entities + repository interfaces (pure Dart)
    ├── data/           repositories/api_<name>_repository.dart (implements domain)
    └── presentation/   cubit/, view/, widgets/, preview/
```

Dependency rules (never violate):
- `domain` imports no Flutter, Dio, `data` or `presentation` code. Only Dart, `core/network/either.dart` and `core/network/failure.dart`.
- `data` never imports `presentation`.
- `core` never imports `app` or any feature.
- Features never import each other in a cycle. Shared UI goes to `core/widgets`; cross-feature navigation goes through route paths in `core/router/app_router.dart`, and route arguments go in `core/router/route_args.dart`.
- Only `lib/app/` knows every feature: routes in `app/router/app_routes.dart`, registrations in `app/di/dependencies.dart`, providers in `app/app_providers.dart`.
- No use-case layer: a cubit calls its repository interface directly.

A new feature needs:
1. Entity and repository interface in `domain/`.
2. `Api…Repository` in `data/repositories/`.
3. Cubit and state in `presentation/cubit/`.
4. Registration in `app/di/dependencies.dart` and `app/app_providers.dart`.
5. Tests in `test/features/<feature>/`.

## 2. State management and dependency injection

- Screen and server state uses **Cubit** (`flutter_bloc`) with an immutable state class and `copyWith`.
- `setState` is only for local UI details: visibility toggles, expanded tiles, selected tab or slot, pickers.
- Widgets never call `sl<…>()`. Read dependencies with `context.read<T>()`; use `context.maybeRead<T>()` (`core/di/maybe_read.dart`) when a widget must also work without the provider. `sl` is used only in `lib/app/` and `core/network`.
- Cubits created by a screen are closed by it (`BlocProvider(create:)`, or `close()` in `dispose`). Never emit after close: guard async work with `isClosed`.
- App-wide singletons (`AuthSessionCubit`) are provided with `RepositoryProvider` so the tree never closes them.

## 3. Data and networking

- Every API call goes through `ApiConsumer` and returns `Either<Failure, T>`. Repositories never throw to the UI.
- Validate response shape (`success`, `data`, types) before using it; return a `ServerFailure` with a translation key when it is invalid.
- Parse JSON defensively in `fromJson`: tolerate missing or `null` fields; never crash on an unexpected value.
- The backend drives the UI (`screen_state`, `actions`, `faqs`, `status_label`, `visible_fields`). Follow it; don't re-derive it in the app. Never invent a backend field or enum value: if the shape is unknown, ask for an Apidog example.
- Retry only idempotent or read-only requests (e.g. CV parse), and only on `NetworkFailure`.
- After any action (POST), reload the source of truth instead of updating local state optimistically.

## 4. UI, design and copy

- Match the Figma file. Compare with the frame before calling UI work done.
- Colors: only `AppColors` (`core/resources/app_colors.dart`). Never write `Color(0x…)` outside that file; add a named token instead.
- One theme: `ThemeManager.getTheme(locale)`. Don't wrap screens in extra `Theme`/`QaderTheme`.
- Text: every user-facing string is a key in BOTH `assets/translations/en-US.json` and `ar-SA.json`, used with `.tr(context: context)` (with `namedArgs` for variables). Never put English/Arabic pairs inline in Dart.
- Arabic is RTL: for anything one-sided (padding, alignment, positioning) use `EdgeInsetsDirectional`, `AlignmentDirectional` and `start`/`end`, never left/right. Symmetric values (same left and right) and gradient directions are fine.
- Sample or mock data lives only in `presentation/preview/` and is used only when there is no real data (logged out or preview routes). Never show sample data to a logged-in user.

## 5. Performance

- Use `const` constructors and widgets wherever possible (the lints enforce it).
- Rebuild the smallest subtree: narrow `BlocBuilder`/`BlocSelector` with `buildWhen`; don't rebuild a whole screen for one field.
- Long or unbounded lists use `ListView.builder`/`SliverList`, never `Column` + `map`.
- No heavy work in `build()`: no parsing, sorting, date formatting loops or I/O. Compute in the cubit or once in state.
- Dispose every `TextEditingController`, `ScrollController`, `Timer`, `StreamSubscription` and `AnimationController`.
- Network images use `cached_network_image` with sized placeholders. Local images and SVGs are sized explicitly.
- No synchronous file or disk work on the UI thread. Uploads build `MultipartFile` asynchronously.
- Avoid unnecessary rebuild triggers: no new closures or objects inside hot paths, no `setState` in loops, and no polling. Use timers for time-based UI (e.g. the join window).

## 6. Code quality

- Keep files small: about 400 lines is the soft limit. Split screens into widget files and cubits into focused files (e.g. payload builders) before they grow past it.
- Private (`_`) by default; public only what other files use.
- No dead code: remove unused files, members, imports, packages and translation keys in the same change.
- Imports: relative inside `lib/` with the correct depth (never `../` past `lib`). Tests import with `package:qader/…`.
- Comments explain *why*, not *what*. Doc-comment public APIs and non-obvious decisions.

## 7. Security

- Never put secrets in code, tests, logs or chat output. API keys come from `--dart-define-from-file=tool/flutter.dev.json` (git-ignored).
- Tokens live in secure storage only.
- `DebugNetworkLogger` runs only in debug builds and non-prod environments, and must redact credentials. Keep it that way.
- Never print or paste the contents of `tool/flutter.dev.json` or any `.env` file.

## 8. Testing and verification (required before saying "done")

1. `dart format lib test`
2. `flutter analyze`: must print "No issues found!"
3. `flutter test`: all tests pass.
4. New logic gets tests in `test/features/<feature>/` (or `test/core/`, `test/app/`), mirroring `lib/`. Use `Fake implements …` for repositories and `ApiConsumer`. Build fixtures from real Apidog examples.
5. UI changes: compare the screenshots that tests render in `build/design_review/` before and after; unchanged screens must stay pixel-identical.
6. Report honestly what was not verified (e.g. not run on a device, not tried against the real server).

## 9. Environment and workflow

- Windows. Run `flutter` and `dart` from PowerShell. Long builds and test runs go in the background.
- Run: `flutter run --dart-define-from-file=tool/flutter.dev.json`
- Release APK: `flutter build apk --release --dart-define-from-file=tool/flutter.dev.json`. Never build without the defines.
- Never run two Flutter or Gradle builds at the same time on this project.
- Git: never commit, push or rewrite history unless the user asks. Commits are small, one topic each, in Conventional Commits style (`feat:`, `fix:`, `refactor:`, `test:`).
- Before deleting anything outside the project, list it and get the user's approval.
