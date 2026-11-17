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
cp apps/api/.env.example apps/api/.env
npm run dev:api
```

The API health check is available at `http://localhost:3000/health`.

Run the scaffold verification:

```sh
npm run verify
npm --workspace apps/api run db:migrate
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
