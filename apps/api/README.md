# Local demo database

This is a disposable, synthetic dataset for the PostgreSQL-backed auth and
community API. Never use real credentials, an existing database, a port forward,
or a remote/PostGIS service. **Loopback is not proof of locality**: an SSH
tunnel, proxy, or other local forward could lead to a remote server whose own
`inet_server_addr()` is loopback. The guard cannot detect every forward or
prove server identity. Before migration, seeding, tests, or API startup, you must
independently verify that the listener belongs to the freshly created local
PostgreSQL cluster below. Never point it at a listener you did not create.

The command accepts only `NODE_ENV=development` or
`test`, `SEED_LOCAL_DEMO=yes`, and an explicit `DEMO_DATABASE_URL` with the
literal address `127.0.0.1` or `[::1]`, an explicit port, and database, user and
password all exactly `showtime_demo`. It rejects URL parameters, socket paths and
all `PG*` environment variables. After connecting it also requires PostgreSQL's
`current_database()` to be `showtime_demo` and `inet_server_addr()` to be the
literal loopback address. A container using a bridge/NAT address will fail this
last check; use a native loopback PostGIS server for these instructions.

## Set up an isolated database

From the repository root, install Node dependencies with `npm install`. Install
PostgreSQL and a matching PostGIS extension locally, with `initdb`, `pg_ctl`,
`createdb`, and `psql` on `PATH`. The following example makes a **new standalone
cluster**, not the project's Compose database. First verify that port 55432 is
unused (`lsof -nP -iTCP:55432 -sTCP:LISTEN` should show no listener), and that
`$HOME/showtime-demo-pg` and `$HOME/showtime-demo-password` do not already
exist. Stop if either exists; don't reuse an existing cluster.

```sh
umask 077
printf '%s\n' showtime_demo > "$HOME/showtime-demo-password"
initdb -D "$HOME/showtime-demo-pg" -U showtime_demo -A scram-sha-256 --pwfile="$HOME/showtime-demo-password"
pg_ctl -D "$HOME/showtime-demo-pg" -l "$HOME/showtime-demo-pg/server.log" -o '-h 127.0.0.1 -p 55432' start
PGPASSWORD=showtime_demo createdb -h 127.0.0.1 -p 55432 -U showtime_demo showtime_demo
```

Before proceeding, check that `pg_ctl -D "$HOME/showtime-demo-pg" status`
reports a running local PostgreSQL process and note its PID. Run
`lsof -nP -iTCP:55432 -sTCP:LISTEN` and verify that the listener is that same
PostgreSQL PID, not `ssh` or another proxy. Check the server's data directory:

```sh
PGPASSWORD=showtime_demo psql -h 127.0.0.1 -p 55432 -U showtime_demo -d showtime_demo -c 'SHOW data_directory'
```

It must resolve to the cluster directory just created. Stop if anything differs.
These independent checks reduce mistakes; they do not prove safety against a
malicious local process. Repeat them whenever the listener might have changed.

The cluster superuser is restricted to this throwaway local cluster; PostGIS
must be installed for this PostgreSQL version. Run the checked-in migrations and
then the separate guarded seed (do **not** use `db:seed`):

```sh
env -i HOME="$HOME" PATH="$PATH" DOTENV_CONFIG_PATH=/dev/null NODE_ENV=development DATABASE_URL='postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' npm --workspace apps/api run db:migrate
env -i HOME="$HOME" PATH="$PATH" NODE_ENV=development SEED_LOCAL_DEMO=yes DEMO_DATABASE_URL='postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' npm --workspace apps/api run db:seed:demo
```

The seed takes a transaction-wide lock, refuses pre-existing public application
table data on first use (PostGIS-owned extension tables are excluded), and
inserts the complete fixture graph atomically. It stores a
versioned ownership marker; subsequent runs leave *all* data untouched, including
edits, removals, new records and previously generated dates. It does not repair
deleted fixtures or update older fixture versions, eligibility policies or
timestamps. Use a fresh cluster to pick up seed changes. No provider, SMS,
payment or outbox requests are created.

## Sign in and explore

Local-only account: **captain@showtimedemo.invalid** / **LocalDemo123!**.
Its phone number is synthetic and marked verified only in this throwaway database
so login can use the normal scrypt password, session and authorization flow
without sending SMS. Do not register this account or use these credentials in a
real environment.

From the repository root, start the dedicated demo API with an explicit exported
`DATABASE_URL`. The command compiles the demo entrypoint and application with
TypeScript before starting them. Unlike `npm run dev:api`, it binds only
`127.0.0.1:3000`, validates the demo URL and matching `DATABASE_URL`, and clears
Twilio credentials before loading the app. It does not expose the known demo
login on LAN interfaces. Keep the host machine and port trusted; other local
processes can still connect. Do not use a network proxy to expose this API.
The example supplies dummy local service settings and disables optional features;
the app may still load missing settings from `apps/api/.env`, so keep that file
free of live credentials as well.

```sh
env -i HOME="$HOME" PATH="$PATH" NODE_ENV=development SEED_LOCAL_DEMO=yes \
  DEMO_DATABASE_URL='postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' \
  DATABASE_URL='postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' \
  REDIS_URL=redis://127.0.0.1:6379 MINIO_ENDPOINT=127.0.0.1 MINIO_PORT=9000 MINIO_USE_SSL=false \
  MINIO_ACCESS_KEY=demo MINIO_SECRET_KEY=demo MINIO_BUCKET=showtime BETTER_AUTH_SECRET=local-demo-only \
  STRIPE_MODE=test STRIPE_SECRET_KEY=sk_test_demo FEATURE_NATIVE_BOOKING=false FEATURE_PAYMENTS=false FEATURE_ADVERTISING=false \
  npm --workspace apps/api run start:demo
```

Avoid putting live Twilio or provider credentials in `.env`. From `apps/mobile`, run
`fvm flutter run --dart-define=API_BASE_URL=http://localhost:3000` for an iOS
simulator (Android emulator: `http://10.0.2.2:3000`). Sign in with the account
above. Squad/Teams (`/squad`, `/teams`) includes Demo Lisbon Falcons and its
seven-player roster; Challenges (`/challenges`) contains upcoming and completed
fixtures; Games (`/matches`) contains open games and applications. Home's
notification button shows a demo application notification. Challenge cards can
be opened for proposals. The API also exposes `POST /auth/login` with JSON
`{"identifier":"captain@showtimedemo.invalid","password":"LocalDemo123!"}`,
then authenticated `GET /auth/session`, `/community/teams`,
`/community/challenges`, `/community/games`, and `/community/notifications`.

Completed status, date and teams appear in the Challenges **Match history**
section, but the schema has no scores or results. The venue/booking/attendance records are illustrative persisted
records; separate in-memory venue, booking, match, payment and notification
services and mobile preview screens are not populated by this seed. Community
notifications are database-backed, but this does not dispatch notifications.

## Testing and reset

The normal API test suite skips the demo integration test unless explicitly
enabled. To exercise it, use a **fresh, empty, migrated** cluster from the
setup above, before seeding it (the test seeds it and intentionally leaves its
records and an edited team in place):

```sh
env -i HOME="$HOME" PATH="$PATH" NODE_ENV=test SEED_LOCAL_DEMO=yes RUN_LOCAL_DEMO_INTEGRATION=yes DEMO_DATABASE_URL='postgres://showtime_demo:showtime_demo@127.0.0.1:55432/showtime_demo' node --test --import tsx apps/api/test/demo-seed-integration.test.ts
```

To test collision refusal separately, use another fresh migrated database and
the same command with `RUN_LOCAL_DEMO_COLLISION_TEST=yes` in place of
`RUN_LOCAL_DEMO_INTEGRATION=yes`. That test deliberately leaves one conflicting
user in its disposable database; it must not share the database with the login
test.

For fresh dates or another integration run, stop the dedicated cluster with
`pg_ctl -D "$HOME/showtime-demo-pg" stop`, then create a **new** empty cluster
in a different verified-unused directory and port following the steps above;
use a different verified-unused password-file path as well, and update the
`printf`, `initdb --pwfile`, `pg_ctl`, listener verification, both URLs and all
commands accordingly. Only delete the old cluster and password file after
independently confirming they are the disposable demo's
files. No reset or deletion command is provided by the seed.
