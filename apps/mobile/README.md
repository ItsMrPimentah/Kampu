# Showtime Mobile

Flutter mobile client for the Showtime football community, pinned with [FVM](https://fvm.app/).

## Design system

The current Stitch project-level design system, its component specifications, and its relationship to the existing Midnight theme are documented in [DESIGN.md](DESIGN.md). Flutter token constants live in `lib/shared/ui/pitch_pulse_tokens.dart`.

## Onboarding policy

Registration enforces the product's 13+ minimum age on the client and server. An account must verify its phone number before entering the app. Existing youth-specific restrictions elsewhere in the prototype still need alignment with the product brief.

## Login and SMS verification

The API uses PostgreSQL for accounts and sessions and Twilio Verify for SMS verification. Copy `apps/api/.env.example` to `apps/api/.env`, fill in `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_VERIFY_SERVICE_SID`, start PostgreSQL, and run `npm --workspace apps/api run db:migrate`. Create a Twilio Verify service configured for six-digit SMS codes. Twilio trial accounts can only send to verified recipient numbers.

Run the API and pass its reachable address to Flutter using `--dart-define=API_BASE_URL=...`. For example:

```sh
fvm flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

`localhost` works for the iOS simulator; Android emulators typically use `http://10.0.2.2:3000`, while physical devices need the development machine's reachable address. Use HTTPS for deployed services. Session tokens are stored in platform secure storage. If SMS delivery fails after account creation, sign in with the same credentials and request another SMS on the verification screen.

This foundation currently uses the API's PostgreSQL-backed credential/session implementation; Better Auth is a project dependency but is not yet integrated into this flow. The login and verification screens follow the Stitch Midnight reference without presenting nonfunctional social, biometric or WhatsApp actions.

## Flutter version

The project is pinned in `.fvmrc` to **Flutter 3.47.9**. Commit `.fvmrc`; the `.fvm/` SDK cache and symlink are local-only.

## Setup

Install FVM once, then from the repository root run:

```sh
cd apps/mobile
fvm install
fvm flutter pub get
```

Or use the root shortcut:

```sh
npm run flutter:setup
```

From the repository root, use Devbox for the shared verification workflows:

```sh
devbox run -q format
devbox run -q test
devbox run -q analyze
```

For a focused test, use `devbox run -q script "cd apps/mobile; ^fvm flutter test test/auth_flow_test.dart"`.
To run the application, use `fvm flutter run` from `apps/mobile`.

VS Code is configured to use `.fvm/flutter_sdk`. Restart the Dart/Flutter extension after changing the SDK.

## Updating Flutter

Change the version deliberately with:

```sh
cd apps/mobile
fvm use <version> --force --skip-pub-get
fvm flutter pub get
```

Then run `fvm flutter analyze` and `fvm flutter test` before committing the updated `.fvmrc`.
