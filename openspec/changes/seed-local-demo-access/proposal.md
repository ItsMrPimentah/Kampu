# Proposal

## Why

The existing development fixtures cannot sign in and lack match history, making it difficult to explore a realistic authenticated application. A safe, repeatable local demo should use the current persisted schema and normal authentication flow.

## What Changes

- Add an isolated, explicitly opted-in local demo seed with a real verified demo captain, teams, rosters, upcoming matches, completed match history, open games, and representative related schema data.
- Document setup, credentials, navigation, safety boundaries, and schema limitations.
- Make completed matches identifiable in the existing authenticated challenge experience without inventing score data.
- Verify local-only guards, transactional repeatability, login and data visibility where a local PostGIS database is available.

## Capabilities

### New Capabilities
- `local-demo-access`: Isolated, safely seeded demo access to real schema-backed community data.

### Modified Capabilities

None in the current working tree.

## Impact

API local development scripts and tests, documentation, and existing mobile community presentation. No production auth bypass, production data changes, external SMS, real payments, or invented score schema.
