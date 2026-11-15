# Kampu

Greenfield Flutter + NestJS modular monolith for amateur football coordination.

The consolidated [product brief](docs/product-brief.md) combines the Google Stitch descriptions and tracks open product decisions.

## Local development

Requirements:

- Node.js 20+
- Docker with Compose
- FVM 3.2+ for Flutter version management
- Flutter 3.47.9 (installed through FVM) for mobile development

Start local infrastructure:

```sh
docker compose -f infra/docker-compose.yml up -d
```

Install backend dependencies and run the API:

```sh
npm install
test -f apps/api/.env || cp apps/api/.env.example apps/api/.env
npm --workspace apps/api run db:migrate
npm run dev:api
```

If `apps/api/.env` already exists, preserve it and check that `DATABASE_URL`
matches the PostgreSQL instance you intend to use. For the Compose database, the
default is `postgres://showtime:showtime@localhost:5432/showtime`. Environment
variables exported in your shell take precedence over `.env`. Run the migration
after PostgreSQL is accepting connections and before using login or registration.

If login reports `ECONNREFUSED` on port 5432, ensure your Docker runtime is
running, check `docker compose -f infra/docker-compose.yml ps`, and start the
database with `docker compose -f infra/docker-compose.yml up -d postgres`. If
the connection is accepted but authentication fails, check the database
credentials in `DATABASE_URL`. Changing Compose credentials does not update an
existing PostgreSQL volume.

The API health check is available at `http://localhost:3000/health`; it does not
check database connectivity. Login currently uses the API's own PostgreSQL-backed
credentials and sessions. Better Auth is a dependency but is not integrated into
this flow; `BETTER_AUTH_SECRET` is required by configuration validation but does
not configure login. Registration requires Twilio Verify credentials for phone
verification. See [`apps/mobile/README.md`](apps/mobile/README.md#login-and-sms-verification)
and the [isolated demo setup](apps/api/README.md#local-demo-database).

Every `npm run dev:api` seeds the Compose database with the local demo login
`captain@showtimedemo.invalid` / `LocalDemo123!`, preserving an existing demo
account on subsequent runs. Migrations must run first. This seed accepts only
the default local Compose database and development environment; the API binds to
`127.0.0.1`. For the complete demo fixture dataset, use the separate
[isolated demo setup](apps/api/README.md#local-demo-database). Check for port conflicts with
`lsof -nP -iTCP:3000 -sTCP:LISTEN`: on macOS, different IPv4 and IPv6
listeners can make `localhost` and `127.0.0.1` reach different applications.
Choose a free port with `PORT=3001 npm run dev:api` and set the mobile app's
`API_BASE_URL` to `http://127.0.0.1:3001` for the iOS simulator.
For Android, run `adb reverse tcp:3001 tcp:3001` and use the same URL.

Run the scaffold verification:

```sh
npm run verify
```

Set up and run the mobile app through the pinned FVM SDK:

```sh
npm run flutter:setup
cd apps/mobile
fvm flutter test
fvm flutter run
```

Static analysis is also pinned to the same SDK:

```sh
npm run flutter:analyze
```

See [`apps/mobile/README.md`](apps/mobile/README.md) for FVM upgrade instructions and Twilio Verify login setup.

## Verification and release safety

Run the complete local verification suite:

```sh
npm run verify
npm run test:security
npm run flutter:analyze
npm run flutter:test
```

The API test suite covers authorization, idempotency, privacy projections, audit sanitization, provider-event deduplication, notification safety, advertising policy, and the primary in-process vertical slice. Tests that require PostgreSQL are skipped when the database is unavailable; run the Compose stack and `npm --workspace apps/api run db:migrate` to exercise migration-backed checks.

Payments are sandbox-only for the MVP. Keep `STRIPE_MODE=test` and use an `sk_test_` key; live mode is rejected outside production and production payment enablement requires a separately reviewed rollout.

The pilot is restricted to Lisbon and Setúbal with PlayArena as the initial native venue partner. Use `FEATURE_NATIVE_BOOKING`, `FEATURE_PAYMENTS`, and `FEATURE_ADVERTISING` as rollback switches. Disable a feature before changing or removing its provider configuration; historical booking, payment, dispute, audit, notification, and analytics records must remain append-only or available for review.

Advertising defaults to no ads when policy configuration is unavailable. Personalized advertising requires current adult consent, is unavailable to youth or unknown-age users, and is excluded from booking checkout, payment confirmation, challenge confirmation/negotiation, and safety-reporting flows.

CI runs API typecheck/tests, targeted security/privacy/idempotency checks, PostGIS migration application, and Flutter analysis/tests through `.github/workflows/ci.yml`.

Local infrastructure is PostgreSQL/PostGIS, Redis, and MinIO. Stripe is intentionally restricted to test mode for the MVP.
