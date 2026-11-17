import 'dotenv/config';
import { Client } from 'pg';
import { seedFixtures, seedIds, seedTimestamp } from './seed-fixtures';

async function main(): Promise<void> {
  const client = new Client({ connectionString: process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime' });
  await client.connect();
  try {
    await client.query('BEGIN');

    for (const user of seedFixtures.users) {
      await client.query(
        `INSERT INTO users (id, external_auth_id, date_of_birth, eligibility, eligibility_policy_version, created_at, updated_at)
         VALUES ($1, $2, $3, $4, 'age-16-v1', $5, $5)
         ON CONFLICT (id) DO UPDATE SET external_auth_id = excluded.external_auth_id, date_of_birth = excluded.date_of_birth,
           eligibility = excluded.eligibility, eligibility_policy_version = excluded.eligibility_policy_version, updated_at = excluded.updated_at`,
        [user.id, user.externalAuthId, user.dateOfBirth, user.eligibility, seedTimestamp],
      );
    }

    await client.query(
      `INSERT INTO player_profiles (id, user_id, display_name, preferred_positions, skill_level, availability, approximate_location, created_at, updated_at)
       VALUES
       ('00000000-0000-4000-8000-000000000121', $1, 'Seed Captain', '["midfielder"]', 'intermediate', '{"weekends":true}', '{"region":"Lisbon"}', $4, $4),
       ('00000000-0000-4000-8000-000000000122', $2, 'Seed Youth Player', '["forward"]', 'beginner', '{"weekends":true}', '{"region":"Lisbon"}', $4, $4),
       ('00000000-0000-4000-8000-000000000123', $3, 'Seed Operator', '[]', null, '{}', '{"region":"Setúbal"}', $4, $4)
       ON CONFLICT (user_id) DO UPDATE SET display_name = excluded.display_name, approximate_location = excluded.approximate_location, updated_at = excluded.updated_at`,
      [seedIds.adultCaptain, seedIds.youthPlayer, seedIds.operator, seedTimestamp],
    );

    for (const team of seedFixtures.teams) {
      await client.query(
        `INSERT INTO teams (id, name, region, supported_formats, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $5)
         ON CONFLICT (id) DO UPDATE SET name = excluded.name, region = excluded.region, supported_formats = excluded.supported_formats, updated_at = excluded.updated_at`,
        [team.id, team.name, team.region, JSON.stringify(team.formats), seedTimestamp],
      );
    }

    await client.query(
      `INSERT INTO team_memberships (id, team_id, user_id, role, permissions, active, created_at, updated_at)
       VALUES
       ('00000000-0000-4000-8000-000000000131', $1, $3, 'captain', '[]', true, $4, $4),
       ('00000000-0000-4000-8000-000000000132', $1, $2, 'member', '[]', true, $4, $4),
       ('00000000-0000-4000-8000-000000000133', $5, $6, 'captain', '[]', true, $4, $4)
       ON CONFLICT (team_id, user_id) DO UPDATE SET role = excluded.role, active = true, updated_at = excluded.updated_at`,
      [seedIds.lisbonTeam, seedIds.youthPlayer, seedIds.adultCaptain, seedTimestamp, seedIds.setubalTeam, seedIds.operator],
    );

    await client.query(
      `INSERT INTO matches (id, host_team_id, opponent_team_id, format, status, skill_level, scheduled_at, region, payment_conditions, fusion, version, created_at, updated_at)
       VALUES ($1, $2, $3, '5v5', 'agreed', 'intermediate', '2026-06-20T15:00:00.000Z', 'Lisbon', '{"currency":"EUR","amount":"50.00"}', true, 2, $4, $4)
       ON CONFLICT (id) DO UPDATE SET status = excluded.status, fusion = excluded.fusion, version = excluded.version, updated_at = excluded.updated_at`,
      [seedIds.match, seedIds.lisbonTeam, seedIds.setubalTeam, seedTimestamp],
    );

    for (const participant of [
      [seedIds.adultCaptain, seedIds.lisbonTeam, 'captain'],
      [seedIds.youthPlayer, seedIds.lisbonTeam, 'forward'],
      [seedIds.operator, seedIds.setubalTeam, 'captain'],
    ]) {
      await client.query(
        `INSERT INTO match_participants (id, match_id, user_id, team_id, position, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $6)
         ON CONFLICT (match_id, user_id) DO UPDATE SET team_id = excluded.team_id, position = excluded.position, updated_at = excluded.updated_at`,
        [`00000000-0000-4000-8000-00000000014${participant[0] === seedIds.adultCaptain ? '1' : participant[0] === seedIds.youthPlayer ? '2' : '3'}`, seedIds.match, participant[0], participant[1], participant[2], seedTimestamp],
      );
    }

    for (const venue of seedFixtures.venues) {
      await client.query(
        `INSERT INTO venues (id, name, region, address, coordinates, supported_formats, booking_method, source, verification_level, information_valid_until, created_at, updated_at)
         VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326)::geography, $7, 'native', 'PlayArena', 'operator_verified', $8, $9, $9)
         ON CONFLICT (id) DO UPDATE SET name = excluded.name, region = excluded.region, coordinates = excluded.coordinates, supported_formats = excluded.supported_formats, information_valid_until = excluded.information_valid_until, updated_at = excluded.updated_at`,
        [venue.id, venue.name, venue.region, `${venue.region} pilot venue`, venue.longitude, venue.latitude, JSON.stringify(venue.formats), venue.validUntil, seedTimestamp],
      );
    }

    await client.query(
      `INSERT INTO bookings (id, match_id, venue_id, status, authority, provider_reference, requested_at, confirmed_at, last_provider_update_at, created_at, updated_at)
       VALUES ($1, $2, $3, 'confirmed', 'provider', 'playarena_seed_reference', $4, $4, $4, $4, $4)
       ON CONFLICT (id) DO UPDATE SET status = excluded.status, authority = excluded.authority, provider_reference = excluded.provider_reference, confirmed_at = excluded.confirmed_at, updated_at = excluded.updated_at`,
      [seedIds.booking, seedIds.match, seedIds.lisbonVenue, seedTimestamp],
    );

    await client.query(
      `INSERT INTO payment_orders (id, booking_id, guarantor_user_id, amount, currency, status, provider, provider_reference, created_at, updated_at)
       VALUES ($1, $2, $3, 50.00, 'EUR', 'succeeded', 'stripe_sandbox', 'pi_seed_sandbox_payment', $4, $4)
       ON CONFLICT (id) DO UPDATE SET status = excluded.status, provider = excluded.provider, provider_reference = excluded.provider_reference, updated_at = excluded.updated_at`,
      [seedIds.paymentOrder, seedIds.booking, seedIds.adultCaptain, seedTimestamp],
    );

    await client.query(
      `INSERT INTO contributions (id, payment_order_id, participant_user_id, amount, currency, status, source, reported_by_user_id, created_at, updated_at)
       VALUES ($1, $2, $3, 25.00, 'EUR', 'disputed', 'captain_reported', $4, $5, $5)
       ON CONFLICT (id) DO UPDATE SET status = excluded.status, source = excluded.source, reported_by_user_id = excluded.reported_by_user_id, updated_at = excluded.updated_at`,
      [seedIds.contribution, seedIds.paymentOrder, seedIds.youthPlayer, seedIds.adultCaptain, seedTimestamp],
    );

    await client.query(
      `INSERT INTO disputes (id, contribution_id, opened_by_user_id, status, reason, review_deadline, created_at, updated_at)
       VALUES ($1, $2, $3, 'captain_review', 'Seed dispute for local development', '2026-06-25T00:00:00.000Z', $4, $4)
       ON CONFLICT (id) DO UPDATE SET status = excluded.status, reason = excluded.reason, updated_at = excluded.updated_at`,
      [seedIds.dispute, seedIds.contribution, seedIds.youthPlayer, seedTimestamp],
    );

    await client.query(
      `INSERT INTO consents (id, user_id, purpose, granted, policy_version, recorded_at)
       VALUES ($1, $2, 'advertising', false, 'ads-v1', $3)
       ON CONFLICT (user_id, purpose, policy_version) DO UPDATE SET granted = excluded.granted`,
      ['00000000-0000-4000-8000-000000000151', seedIds.adultCaptain, seedTimestamp],
    );

    await client.query(
      `INSERT INTO outbox_events (id, event_type, aggregate_type, aggregate_id, aggregate_version, payload, created_at, updated_at)
       VALUES ($1, $2, 'payment_order', $3, 1, $4, $5, $5)
       ON CONFLICT (aggregate_type, aggregate_id, aggregate_version) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at`,
      [seedIds.outboxEvent, seedFixtures.stripeSandboxEvent.eventType, seedIds.paymentOrder, JSON.stringify({ provider: 'stripe_sandbox', eventId: seedFixtures.stripeSandboxEvent.id, providerReference: seedFixtures.stripeSandboxEvent.providerReference }), seedTimestamp],
    );

    await client.query(
      `INSERT INTO analytics_events (id, name, aggregate_type, aggregate_id, aggregate_version, payload, eligibility_category, created_at, updated_at)
       VALUES ($1, 'match.completed', 'match', $2, 1, $3, 'youth', $4, $4)
       ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at`,
      [seedIds.analyticsEvent, seedIds.match, JSON.stringify({ source: 'seed', format: '5v5' }), seedTimestamp],
    );

    await client.query(
      `INSERT INTO notifications (id, user_id, type, payload, delivered_at, created_at, updated_at)
       VALUES ($1, $2, 'booking.failed', $3, NULL, $4, $4)
       ON CONFLICT (id) DO UPDATE SET payload = excluded.payload, updated_at = excluded.updated_at`,
      [seedIds.notification, seedIds.youthPlayer, JSON.stringify({ matchLabel: 'Seed Saturday match', region: 'Lisbon', status: 'failed' }), seedTimestamp],
    );

    await client.query(
      `INSERT INTO audit_logs (id, actor_id, action, target_type, target_id, reason, metadata, created_at, updated_at)
       VALUES ($1, $2, 'seed.fixture_created', 'match', $3, 'development fixture', '{"source":"seed"}', $4, $4)
       ON CONFLICT (id) DO UPDATE SET metadata = excluded.metadata, updated_at = excluded.updated_at`,
      [seedIds.audit, seedIds.operator, seedIds.match, seedTimestamp],
    );

    await client.query('COMMIT');
    console.log('Seeded deterministic development fixtures (no production secrets).');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
