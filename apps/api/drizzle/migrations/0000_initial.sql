CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;

DO $$ BEGIN CREATE TYPE eligibility_category AS ENUM ('youth', 'adult'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE team_role AS ENUM ('captain', 'manager', 'member'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE match_format AS ENUM ('5v5', '7v7', '11v11', 'futsal', 'futevoley_2v2'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE match_status AS ENUM ('draft', 'open', 'negotiation', 'agreed', 'scheduling', 'confirmed', 'completed', 'cancelled', 'expired'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE booking_status AS ENUM ('not_requested', 'searching', 'slot_selected', 'pending_payment', 'pending_provider_confirmation', 'externally_declared', 'confirmed', 'failed', 'cancelled', 'refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded', 'disputed', 'outstanding'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE contribution_source AS ENUM ('provider', 'captain_reported'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE TYPE dispute_status AS ENUM ('open', 'captain_review', 'escalated', 'resolved_paid', 'resolved_unpaid', 'closed'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  external_auth_id text NOT NULL UNIQUE,
  date_of_birth date,
  eligibility eligibility_category,
  eligibility_policy_version varchar(64),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS player_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL UNIQUE REFERENCES users(id),
  display_name varchar(120) NOT NULL, preferred_positions jsonb NOT NULL DEFAULT '[]', skill_level varchar(32),
  availability jsonb NOT NULL DEFAULT '{}', approximate_location jsonb,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name varchar(120) NOT NULL, region varchar(80) NOT NULL,
  supported_formats jsonb NOT NULL DEFAULT '[]', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS team_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), team_id uuid NOT NULL REFERENCES teams(id), user_id uuid NOT NULL REFERENCES users(id),
  role team_role NOT NULL DEFAULT 'member', permissions jsonb NOT NULL DEFAULT '[]', active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(team_id, user_id)
);
CREATE TABLE IF NOT EXISTS matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), host_team_id uuid NOT NULL REFERENCES teams(id), opponent_team_id uuid REFERENCES teams(id),
  format match_format NOT NULL, status match_status NOT NULL DEFAULT 'draft', skill_level varchar(32), scheduled_at timestamptz,
  region varchar(80), payment_conditions jsonb NOT NULL DEFAULT '{}', fusion boolean NOT NULL DEFAULT false, version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), CHECK (host_team_id <> opponent_team_id)
);
CREATE TABLE IF NOT EXISTS match_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), match_id uuid NOT NULL REFERENCES matches(id), version integer NOT NULL,
  proposed_by_user_id uuid NOT NULL REFERENCES users(id), terms jsonb NOT NULL, decision varchar(32),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(match_id, version)
);
CREATE TABLE IF NOT EXISTS match_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), match_id uuid NOT NULL REFERENCES matches(id), user_id uuid NOT NULL REFERENCES users(id),
  team_id uuid REFERENCES teams(id), position varchar(32), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(match_id, user_id)
);
CREATE TABLE IF NOT EXISTS attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), match_id uuid NOT NULL REFERENCES matches(id), user_id uuid NOT NULL REFERENCES users(id),
  status varchar(32) NOT NULL DEFAULT 'requested', responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(match_id, user_id)
);
CREATE TABLE IF NOT EXISTS venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name varchar(160) NOT NULL, region varchar(80) NOT NULL, address text,
  coordinates geography(Point, 4326), supported_formats jsonb NOT NULL DEFAULT '[]', booking_method varchar(32) NOT NULL,
  source varchar(120) NOT NULL, verification_level varchar(32) NOT NULL, information_valid_until timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS venues_coordinates_gix ON venues USING GIST (coordinates);
CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), match_id uuid NOT NULL REFERENCES matches(id), venue_id uuid NOT NULL REFERENCES venues(id),
  status booking_status NOT NULL DEFAULT 'not_requested', authority varchar(32) NOT NULL, external_url text, provider_reference text,
  requested_at timestamptz, confirmed_at timestamptz, last_provider_update_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS payment_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), booking_id uuid NOT NULL REFERENCES bookings(id), guarantor_user_id uuid NOT NULL REFERENCES users(id),
  amount numeric(12,2) NOT NULL, currency varchar(3) NOT NULL, status payment_status NOT NULL DEFAULT 'pending', provider varchar(32), provider_reference text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), payment_order_id uuid NOT NULL REFERENCES payment_orders(id), participant_user_id uuid NOT NULL REFERENCES users(id),
  amount numeric(12,2) NOT NULL, currency varchar(3) NOT NULL, status payment_status NOT NULL DEFAULT 'outstanding', source contribution_source,
  provider_reference text, reported_by_user_id uuid REFERENCES users(id), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS disputes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), contribution_id uuid NOT NULL REFERENCES contributions(id), opened_by_user_id uuid NOT NULL REFERENCES users(id),
  status dispute_status NOT NULL DEFAULT 'open', reason text NOT NULL, resolution text, review_deadline timestamptz, resolved_by_user_id uuid REFERENCES users(id),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), purpose varchar(64) NOT NULL, granted boolean NOT NULL,
  policy_version varchar(64) NOT NULL, recorded_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id, purpose, policy_version)
);
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id), type varchar(80) NOT NULL, payload jsonb NOT NULL,
  delivered_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS analytics_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name varchar(100) NOT NULL, aggregate_type varchar(64) NOT NULL, aggregate_id uuid NOT NULL,
  aggregate_version integer NOT NULL, payload jsonb NOT NULL, eligibility_category eligibility_category,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), actor_id uuid REFERENCES users(id), action varchar(100) NOT NULL, target_type varchar(64) NOT NULL,
  target_id uuid, reason text, metadata jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS outbox_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), event_type varchar(120) NOT NULL, aggregate_type varchar(64) NOT NULL, aggregate_id uuid NOT NULL,
  aggregate_version integer NOT NULL, payload jsonb NOT NULL, published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(aggregate_type, aggregate_id, aggregate_version)
);
CREATE TABLE IF NOT EXISTS idempotency_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), key varchar(200) NOT NULL, scope varchar(120) NOT NULL, request_hash varchar(128) NOT NULL,
  response jsonb, completed_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(scope, key)
);
