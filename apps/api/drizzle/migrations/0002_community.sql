ALTER TABLE teams ADD COLUMN IF NOT EXISTS description text NOT NULL DEFAULT '';
ALTER TABLE teams ADD COLUMN IF NOT EXISTS visibility varchar(16) NOT NULL DEFAULT 'public';
ALTER TABLE team_memberships ADD COLUMN IF NOT EXISTS position varchar(32);
CREATE TABLE IF NOT EXISTS team_join_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), team_id uuid NOT NULL REFERENCES teams(id),
  user_id uuid NOT NULL REFERENCES users(id), status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(team_id, user_id)
);
CREATE TABLE IF NOT EXISTS team_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), team_id uuid NOT NULL REFERENCES teams(id),
  created_by uuid NOT NULL REFERENCES users(id), token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE matches ADD COLUMN IF NOT EXISTS field_name text;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS field_status text NOT NULL DEFAULT 'in_confirmation';
ALTER TABLE match_proposals ADD COLUMN IF NOT EXISTS proposed_by_team_id uuid REFERENCES teams(id);
ALTER TABLE match_proposals ADD COLUMN IF NOT EXISTS accepted_by_team_id uuid REFERENCES teams(id);
CREATE TABLE IF NOT EXISTS challenge_field_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), match_id uuid NOT NULL REFERENCES matches(id),
  proposed_field text NOT NULL, proposed_by_team_id uuid NOT NULL REFERENCES teams(id),
  approved_by_team_id uuid REFERENCES teams(id), status text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS one_pending_field_vote_per_match ON challenge_field_votes(match_id) WHERE status = 'pending';
CREATE TABLE IF NOT EXISTS open_games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organizer_id uuid NOT NULL REFERENCES users(id),
  title text NOT NULL, format match_format NOT NULL, region text NOT NULL, location text NOT NULL,
  scheduled_at timestamptz NOT NULL, capacity integer NOT NULL CHECK (capacity > 0 AND capacity <= 100),
  approval_required boolean NOT NULL DEFAULT true, visibility text NOT NULL DEFAULT 'public',
  required_positions jsonb NOT NULL DEFAULT '[]', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS open_game_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), game_id uuid NOT NULL REFERENCES open_games(id),
  user_id uuid NOT NULL REFERENCES users(id), position text, status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(game_id, user_id)
);
ALTER TABLE open_games ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'open';
CREATE TABLE IF NOT EXISTS open_game_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), game_id uuid NOT NULL REFERENCES open_games(id),
  token_hash text NOT NULL UNIQUE, expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
