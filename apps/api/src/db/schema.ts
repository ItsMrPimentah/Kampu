import { sql } from 'drizzle-orm';
import {
  boolean,
  date,
  integer,
  jsonb,
  numeric,
  pgEnum,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  varchar,
} from 'drizzle-orm/pg-core';

export const eligibilityCategory = pgEnum('eligibility_category', ['youth', 'adult']);
export const teamRole = pgEnum('team_role', ['captain', 'manager', 'member']);
export const matchFormat = pgEnum('match_format', ['5v5', '7v7', '11v11', 'futsal', 'futevoley_2v2']);
export const matchStatus = pgEnum('match_status', ['draft', 'open', 'negotiation', 'agreed', 'scheduling', 'confirmed', 'completed', 'cancelled', 'expired']);
export const bookingStatus = pgEnum('booking_status', ['not_requested', 'searching', 'slot_selected', 'pending_payment', 'pending_provider_confirmation', 'externally_declared', 'confirmed', 'failed', 'cancelled', 'refunded']);
export const paymentStatus = pgEnum('payment_status', ['pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded', 'disputed', 'outstanding']);
export const contributionSource = pgEnum('contribution_source', ['provider', 'captain_reported']);
export const disputeStatus = pgEnum('dispute_status', ['open', 'captain_review', 'escalated', 'resolved_paid', 'resolved_unpaid', 'closed']);

const timestamps = {
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
};

export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  externalAuthId: text('external_auth_id').notNull(),
  dateOfBirth: date('date_of_birth'),
  eligibility: eligibilityCategory('eligibility'),
  eligibilityPolicyVersion: varchar('eligibility_policy_version', { length: 64 }),
  ...timestamps,
}, (table) => ({ externalAuthIdIndex: uniqueIndex('users_external_auth_id_idx').on(table.externalAuthId) }));

export const authCredentials = pgTable('auth_credentials', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  email: text('email').notNull().unique(),
  phone: text('phone').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  phoneVerified: boolean('phone_verified').notNull().default(false),
  registrationRole: text('registration_role').notNull().default('player'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const authSessions = pgTable('auth_sessions', {
  tokenHash: text('token_hash').primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const authRateLimits = pgTable('auth_rate_limits', {
  key: text('key').primaryKey(),
  count: integer('count').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
});

export const playerProfiles = pgTable('player_profiles', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id),
  displayName: varchar('display_name', { length: 120 }).notNull(),
  preferredPositions: jsonb('preferred_positions').$type<string[]>().notNull().default(sql`'[]'::jsonb`),
  skillLevel: varchar('skill_level', { length: 32 }),
  availability: jsonb('availability').$type<Record<string, unknown>>().notNull().default(sql`'{}'::jsonb`),
  approximateLocation: jsonb('approximate_location').$type<{ region: string; latitude?: number; longitude?: number }>(),
  ...timestamps,
}, (table) => ({ userIndex: uniqueIndex('player_profiles_user_id_idx').on(table.userId) }));

export const teams = pgTable('teams', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 120 }).notNull(),
  region: varchar('region', { length: 80 }).notNull(),
  description: text('description').notNull().default(''),
  visibility: varchar('visibility', { length: 16 }).notNull().default('public'),
  supportedFormats: jsonb('supported_formats').$type<string[]>().notNull().default(sql`'[]'::jsonb`),
  ...timestamps,
});

export const teamMemberships = pgTable('team_memberships', {
  id: uuid('id').defaultRandom().primaryKey(),
  teamId: uuid('team_id').notNull().references(() => teams.id),
  userId: uuid('user_id').notNull().references(() => users.id),
  role: teamRole('role').notNull().default('member'),
  permissions: jsonb('permissions').$type<string[]>().notNull().default(sql`'[]'::jsonb`),
  active: boolean('active').notNull().default(true),
  position: varchar('position', { length: 32 }),
  ...timestamps,
}, (table) => ({ membershipIndex: uniqueIndex('team_memberships_team_user_idx').on(table.teamId, table.userId) }));

export const matches = pgTable('matches', {
  id: uuid('id').defaultRandom().primaryKey(),
  hostTeamId: uuid('host_team_id').notNull().references(() => teams.id),
  opponentTeamId: uuid('opponent_team_id').references(() => teams.id),
  format: matchFormat('format').notNull(),
  status: matchStatus('status').notNull().default('draft'),
  skillLevel: varchar('skill_level', { length: 32 }),
  scheduledAt: timestamp('scheduled_at', { withTimezone: true }),
  region: varchar('region', { length: 80 }),
  paymentConditions: jsonb('payment_conditions').$type<Record<string, unknown>>().notNull().default(sql`'{}'::jsonb`),
  fieldName: text('field_name'),
  fieldStatus: text('field_status').notNull().default('in_confirmation'),
  fusion: boolean('fusion').notNull().default(false),
  version: integer('version').notNull().default(1),
  ...timestamps,
});

export const matchProposals = pgTable('match_proposals', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id),
  version: integer('version').notNull(),
  proposedByUserId: uuid('proposed_by_user_id').notNull().references(() => users.id),
  proposedByTeamId: uuid('proposed_by_team_id').references(() => teams.id),
  acceptedByTeamId: uuid('accepted_by_team_id').references(() => teams.id),
  terms: jsonb('terms').$type<Record<string, unknown>>().notNull(),
  decision: varchar('decision', { length: 32 }),
  ...timestamps,
}, (table) => ({ matchVersionIndex: uniqueIndex('match_proposals_match_version_idx').on(table.matchId, table.version) }));

export const teamJoinRequests = pgTable('team_join_requests', {
  id: uuid('id').defaultRandom().primaryKey(), teamId: uuid('team_id').notNull().references(() => teams.id),
  userId: uuid('user_id').notNull().references(() => users.id), status: text('status').notNull().default('pending'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, table => ({ teamUser: uniqueIndex('team_join_requests_team_user_idx').on(table.teamId, table.userId) }));

export const teamInvites = pgTable('team_invites', {
  id: uuid('id').defaultRandom().primaryKey(), teamId: uuid('team_id').notNull().references(() => teams.id),
  createdBy: uuid('created_by').notNull().references(() => users.id), tokenHash: text('token_hash').notNull().unique(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(), createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const challengeFieldVotes = pgTable('challenge_field_votes', {
  id: uuid('id').defaultRandom().primaryKey(), matchId: uuid('match_id').notNull().references(() => matches.id),
  proposedField: text('proposed_field').notNull(), proposedByTeamId: uuid('proposed_by_team_id').notNull().references(() => teams.id),
  approvedByTeamId: uuid('approved_by_team_id').references(() => teams.id), status: text('status').notNull().default('pending'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, table => ({ pendingVote: uniqueIndex('one_pending_field_vote_per_match').on(table.matchId).where(sql`${table.status} = 'pending'`) }));

export const openGames = pgTable('open_games', {
  id: uuid('id').defaultRandom().primaryKey(), organizerId: uuid('organizer_id').notNull().references(() => users.id),
  title: text('title').notNull(), format: matchFormat('format').notNull(), region: text('region').notNull(), location: text('location').notNull(),
  scheduledAt: timestamp('scheduled_at', { withTimezone: true }).notNull(), capacity: integer('capacity').notNull(),
  approvalRequired: boolean('approval_required').notNull().default(true), visibility: text('visibility').notNull().default('public'),
  status: text('status').notNull().default('open'),
  requiredPositions: jsonb('required_positions').$type<string[]>().notNull().default(sql`'[]'::jsonb`),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const openGameApplications = pgTable('open_game_applications', {
  id: uuid('id').defaultRandom().primaryKey(), gameId: uuid('game_id').notNull().references(() => openGames.id),
  userId: uuid('user_id').notNull().references(() => users.id), position: text('position'), status: text('status').notNull(),
  ...timestamps,
}, table => ({ gameUser: uniqueIndex('open_game_applications_game_user_idx').on(table.gameId, table.userId) }));

export const openGameInvites = pgTable('open_game_invites', {
  id: uuid('id').defaultRandom().primaryKey(), gameId: uuid('game_id').notNull().references(() => openGames.id),
  tokenHash: text('token_hash').notNull().unique(), expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const matchParticipants = pgTable('match_participants', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id),
  userId: uuid('user_id').notNull().references(() => users.id),
  teamId: uuid('team_id').references(() => teams.id),
  position: varchar('position', { length: 32 }),
  ...timestamps,
}, (table) => ({ participantIndex: uniqueIndex('match_participants_match_user_idx').on(table.matchId, table.userId) }));

export const attendance = pgTable('attendance', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id),
  userId: uuid('user_id').notNull().references(() => users.id),
  status: varchar('status', { length: 32 }).notNull().default('requested'),
  respondedAt: timestamp('responded_at', { withTimezone: true }),
  ...timestamps,
}, (table) => ({ attendanceIndex: uniqueIndex('attendance_match_user_idx').on(table.matchId, table.userId) }));

export const venues = pgTable('venues', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 160 }).notNull(),
  region: varchar('region', { length: 80 }).notNull(),
  address: text('address'),
  coordinates: jsonb('coordinates').$type<{ latitude: number; longitude: number }>(),
  supportedFormats: jsonb('supported_formats').$type<string[]>().notNull().default(sql`'[]'::jsonb`),
  bookingMethod: varchar('booking_method', { length: 32 }).notNull(),
  source: varchar('source', { length: 120 }).notNull(),
  verificationLevel: varchar('verification_level', { length: 32 }).notNull(),
  informationValidUntil: timestamp('information_valid_until', { withTimezone: true }),
  ...timestamps,
});

export const bookings = pgTable('bookings', {
  id: uuid('id').defaultRandom().primaryKey(),
  matchId: uuid('match_id').notNull().references(() => matches.id),
  venueId: uuid('venue_id').notNull().references(() => venues.id),
  status: bookingStatus('status').notNull().default('not_requested'),
  authority: varchar('authority', { length: 32 }).notNull(),
  externalUrl: text('external_url'),
  providerReference: text('provider_reference'),
  requestedAt: timestamp('requested_at', { withTimezone: true }),
  confirmedAt: timestamp('confirmed_at', { withTimezone: true }),
  lastProviderUpdateAt: timestamp('last_provider_update_at', { withTimezone: true }),
  ...timestamps,
});

export const paymentOrders = pgTable('payment_orders', {
  id: uuid('id').defaultRandom().primaryKey(),
  bookingId: uuid('booking_id').notNull().references(() => bookings.id),
  guarantorUserId: uuid('guarantor_user_id').notNull().references(() => users.id),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull(),
  status: paymentStatus('status').notNull().default('pending'),
  provider: varchar('provider', { length: 32 }),
  providerReference: text('provider_reference'),
  ...timestamps,
});

export const contributions = pgTable('contributions', {
  id: uuid('id').defaultRandom().primaryKey(),
  paymentOrderId: uuid('payment_order_id').notNull().references(() => paymentOrders.id),
  participantUserId: uuid('participant_user_id').notNull().references(() => users.id),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull(),
  status: paymentStatus('status').notNull().default('outstanding'),
  source: contributionSource('source'),
  providerReference: text('provider_reference'),
  reportedByUserId: uuid('reported_by_user_id').references(() => users.id),
  ...timestamps,
});

export const disputes = pgTable('disputes', {
  id: uuid('id').defaultRandom().primaryKey(),
  contributionId: uuid('contribution_id').notNull().references(() => contributions.id),
  openedByUserId: uuid('opened_by_user_id').notNull().references(() => users.id),
  status: disputeStatus('status').notNull().default('open'),
  reason: text('reason').notNull(),
  resolution: text('resolution'),
  reviewDeadline: timestamp('review_deadline', { withTimezone: true }),
  resolvedByUserId: uuid('resolved_by_user_id').references(() => users.id),
  ...timestamps,
});

export const consents = pgTable('consents', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id),
  purpose: varchar('purpose', { length: 64 }).notNull(),
  granted: boolean('granted').notNull(),
  policyVersion: varchar('policy_version', { length: 64 }).notNull(),
  recordedAt: timestamp('recorded_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => ({ consentIndex: uniqueIndex('consents_user_purpose_version_idx').on(table.userId, table.purpose, table.policyVersion) }));

export const notifications = pgTable('notifications', {
  id: uuid('id').defaultRandom().primaryKey(),
  userId: uuid('user_id').notNull().references(() => users.id),
  type: varchar('type', { length: 80 }).notNull(),
  payload: jsonb('payload').$type<Record<string, unknown>>().notNull(),
  deliveredAt: timestamp('delivered_at', { withTimezone: true }),
  ...timestamps,
});

export const analyticsEvents = pgTable('analytics_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  name: varchar('name', { length: 100 }).notNull(),
  aggregateType: varchar('aggregate_type', { length: 64 }).notNull(),
  aggregateId: uuid('aggregate_id').notNull(),
  aggregateVersion: integer('aggregate_version').notNull(),
  payload: jsonb('payload').$type<Record<string, unknown>>().notNull(),
  eligibilityCategory: eligibilityCategory('eligibility_category'),
  ...timestamps,
});

export const auditLogs = pgTable('audit_logs', {
  id: uuid('id').defaultRandom().primaryKey(),
  actorId: uuid('actor_id').references(() => users.id),
  action: varchar('action', { length: 100 }).notNull(),
  targetType: varchar('target_type', { length: 64 }).notNull(),
  targetId: uuid('target_id'),
  reason: text('reason'),
  metadata: jsonb('metadata').$type<Record<string, unknown>>().notNull().default(sql`'{}'::jsonb`),
  ...timestamps,
});

export const outboxEvents = pgTable('outbox_events', {
  id: uuid('id').defaultRandom().primaryKey(),
  eventType: varchar('event_type', { length: 120 }).notNull(),
  aggregateType: varchar('aggregate_type', { length: 64 }).notNull(),
  aggregateId: uuid('aggregate_id').notNull(),
  aggregateVersion: integer('aggregate_version').notNull(),
  payload: jsonb('payload').$type<Record<string, unknown>>().notNull(),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  ...timestamps,
}, (table) => ({ aggregateVersionIndex: uniqueIndex('outbox_aggregate_version_idx').on(table.aggregateType, table.aggregateId, table.aggregateVersion) }));

export const idempotencyKeys = pgTable('idempotency_keys', {
  id: uuid('id').defaultRandom().primaryKey(),
  key: varchar('key', { length: 200 }).notNull(),
  scope: varchar('scope', { length: 120 }).notNull(),
  requestHash: varchar('request_hash', { length: 128 }).notNull(),
  response: jsonb('response').$type<Record<string, unknown>>(),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  ...timestamps,
}, (table) => ({ keyScopeIndex: uniqueIndex('idempotency_keys_scope_key_idx').on(table.scope, table.key) }));
