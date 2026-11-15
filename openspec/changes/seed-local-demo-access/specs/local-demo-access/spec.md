# Local demo access

## Purpose

Enable developers to explore authenticated community flows using coherent, isolated, schema-backed local demo data.

## ADDED Requirements

### Requirement: Safe local demo seeding
The demo seed SHALL require an explicit local development or test opt-in and an explicitly specified dedicated loopback database target. It SHALL refuse production mode and non-loopback destinations before connecting. The operator SHALL independently verify the listener belongs to the intended local cluster, because loopback addresses can be forwarded.

#### Scenario: Unsafe destination
- **WHEN** opt-in, environment or local dedicated target requirements are not met
- **THEN** the seed stops before opening a database connection

#### Scenario: Repeated invocation
- **WHEN** the seed runs again on the same demo database
- **THEN** it avoids duplicating fixtures and does not overwrite existing user changes or adopt conflicting records

### Requirement: Normal demo authentication
The demo captain SHALL sign in using the normal password authentication and session flow without invoking SMS or weakening production authentication.

#### Scenario: Demo login
- **WHEN** the seeded captain signs in with the documented local credentials
- **THEN** the app receives a verified authenticated session and accesses authorized community data

### Requirement: Coherent representative data
The demo SHALL contain synthetic users, teams, roster memberships, future match activity, completed historical matches and open games with valid schema relationships.

#### Scenario: Explore a seeded team
- **WHEN** the demo captain opens their team and challenges
- **THEN** a populated roster, future activity and completed match records are visible

#### Scenario: Match history
- **WHEN** a completed match is displayed
- **THEN** its completed status and available schema-backed details are shown without fabricated scores

### Requirement: Document demo use and limitations
The demo SHALL document setup, login credentials, data visibility, reset guidance and the limits of schema-backed and in-memory features.

#### Scenario: Local setup
- **WHEN** a developer follows the setup instructions on a disposable local environment
- **THEN** they can seed the data, start the API and app, and discover the demo team and completed matches
