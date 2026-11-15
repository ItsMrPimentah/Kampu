import type { INestApplication } from '@nestjs/common';
import { SwaggerModule, type OpenAPIObject } from '@nestjs/swagger';
import type { SchemaObject } from '@nestjs/swagger/dist/interfaces/open-api-spec.interface';

const ref = (name: string) => ({ $ref: `#/components/schemas/${name}` });
const str = (extra: Partial<SchemaObject> = {}): SchemaObject => ({ type: 'string', ...extra });
const uuid = () => str({ format: 'uuid' });
const dateTime = () => str({ format: 'date-time' });
const date = () => str({ format: 'date' });
const bool = (): SchemaObject => ({ type: 'boolean' });
const integer = (extra: Partial<SchemaObject> = {}): SchemaObject => ({ type: 'integer', ...extra });
const object = (properties: SchemaObject['properties'], required: string[] = []): SchemaObject => ({ type: 'object', properties, ...(required.length ? { required } : {}) });
const array = (items: SchemaObject | { $ref: string }): SchemaObject => ({ type: 'array', items });
const formats = () => array(ref('Format'));
const timestamps = { created_at: dateTime(), updated_at: dateTime() };

// These schemas describe the HTTP contract, including PostgreSQL's snake_case
// response fields. Domain services without controllers are intentionally omitted.
const schemas: Record<string, SchemaObject> = {
  Format: str({ enum: ['5v5', '7v7', '11v11'] }),
  Error: object({ statusCode: integer(), message: { oneOf: [str(), array(str())] }, error: str() }, ['statusCode', 'message']),
  User: object({ id: uuid(), name: str(), dateOfBirth: date() }, ['id', 'name', 'dateOfBirth']),
  Credentials: object({ token: str(), verified: bool(), phone: str() }, ['token', 'verified', 'phone']),
  RegistrationResult: object({ token: str(), verified: bool(), phone: str(), sent: bool() }, ['token', 'verified', 'phone', 'sent']),
  Session: object({ verified: bool(), phone: str(), user: ref('User') }, ['verified', 'phone', 'user']),
  Register: object({ name: str({ minLength: 2, maxLength: 120 }), email: str({ format: 'email', maxLength: 254 }), phone: str({ description: 'International phone number, e.g. +351912345678; spaces, parentheses and hyphens are accepted.' }), password: str({ format: 'password', minLength: 8, maxLength: 128, description: 'Must contain uppercase, lowercase, a digit and a non-alphanumeric character.' }), dateOfBirth: date(), role: str({ enum: ['player', 'squadCaptain', 'guardian'] }), acceptedTerms: { type: 'boolean', enum: [true] } }, ['name', 'email', 'phone', 'password', 'dateOfBirth', 'role', 'acceptedTerms']),
  Login: object({ identifier: str({ description: 'Email address or phone number.' }), password: str({ format: 'password' }) }, ['identifier', 'password']),
  VerifyPhone: object({ code: str({ pattern: '^\\d{6}$' }) }, ['code']),
  Eligibility: object({ eligible: { type: 'boolean', enum: [true] }, category: str({ enum: ['youth', 'adult'] }), policyVersion: str(), age: integer(), dateOfBirth: date() }, ['eligible', 'category', 'policyVersion', 'age', 'dateOfBirth']),
  EligibilityError: object({ code: str({ enum: ['invalid_date', 'future_date', 'under_minimum_age'] }), message: str() }, ['code', 'message']),
  Team: object({ id: uuid(), name: str(), region: str(), supported_formats: formats(), description: str(), visibility: str({ enum: ['public', 'private'] }), ...timestamps }, ['id', 'name', 'region', 'supported_formats', 'description', 'visibility', 'created_at', 'updated_at']),
  TeamSummary: { allOf: [ref('Team'), object({ my_role: str({ nullable: true, enum: ['captain', 'manager', 'member'] }), member_count: integer() }, ['my_role', 'member_count'])] },
  CreateTeam: { ...object({ name: str({ maxLength: 120 }), region: str({ maxLength: 80 }), format: ref('Format'), formats: formats(), visibility: str({ enum: ['public', 'private'], default: 'public' }), description: str({ description: 'Trimmed and truncated to 1000 characters.' }) }, ['name', 'region']), description: 'Provide formats or a single format. If formats is present it takes precedence.', anyOf: [{ required: ['format'] }, { required: ['formats'] }] },
  TeamFormats: object({ formats: { ...formats(), minItems: 1 } }, ['formats']),
  Member: object({ user_id: uuid(), role: str({ enum: ['captain', 'manager', 'member'] }), position: str({ nullable: true }), display_name: str() }, ['user_id', 'role', 'position', 'display_name']),
  Roster: object({ team: ref('Team'), members: array(ref('Member')), myRole: str({ nullable: true, enum: ['captain', 'manager', 'member'] }) }, ['team', 'members', 'myRole']),
  UpdateMember: object({ role: str({ enum: ['member', 'manager'] }), position: str({ maxLength: 32 }), active: bool() }),
  UpdatedMember: object({ user_id: uuid(), role: str({ enum: ['captain', 'manager', 'member'] }), position: str({ nullable: true }), active: bool() }, ['user_id', 'role', 'position', 'active']),
  JoinRequest: object({ id: uuid(), team_id: uuid(), user_id: uuid(), status: str(), created_at: dateTime(), display_name: str() }, ['id', 'team_id', 'user_id', 'status', 'created_at']),
  Invite: object({ token: str(), expiresInDays: integer() }, ['token', 'expiresInDays']),
  Notification: object({ id: uuid(), type: str(), payload: { type: 'object', additionalProperties: true }, created_at: dateTime() }, ['id', 'type', 'payload', 'created_at']),
  Challenge: object({ id: uuid(), host_team_id: uuid(), opponent_team_id: str({ format: 'uuid', nullable: true }), format: str(), status: str(), skill_level: str({ nullable: true }), scheduled_at: str({ format: 'date-time', nullable: true }), region: str({ nullable: true }), field_name: str({ nullable: true }), field_status: str(), payment_conditions: { type: 'object', additionalProperties: true }, fusion: bool(), version: integer(), host_name: str(), opponent_name: str({ nullable: true }), ...timestamps }, ['id', 'host_team_id', 'opponent_team_id', 'format', 'status', 'version']),
  CreateChallenge: object({ teamId: uuid(), format: ref('Format'), scheduledAt: dateTime(), region: str({ maxLength: 80 }), field: str({ description: 'Trimmed and truncated to 120 characters.' }) }, ['teamId', 'format', 'scheduledAt', 'region']),
  ChallengeAction: object({ teamId: uuid(), scheduledAt: dateTime(), region: str({ maxLength: 80 }), field: str({ maxLength: 120 }), status: str({ enum: ['in_confirmation', 'confirmed'] }) }, ['teamId']),
  ChallengeDetail: object({ match: ref('Challenge'), proposals: array({ type: 'object', additionalProperties: true }), votes: array({ type: 'object', additionalProperties: true }) }, ['match', 'proposals', 'votes']),
  Game: object({ id: uuid(), organizer_id: uuid(), title: str(), format: str(), region: str(), location: str(), scheduled_at: dateTime(), capacity: integer(), approval_required: bool(), visibility: str(), required_positions: array(str()), status: str(), created_at: dateTime(), organizer_name: str(), approved_count: integer(), my_status: str({ nullable: true }), is_organizer: bool() }, ['id', 'organizer_id', 'title', 'format', 'region', 'location', 'scheduled_at', 'capacity', 'approval_required', 'visibility', 'required_positions', 'status', 'created_at']),
  CreateGame: object({ title: str({ maxLength: 120 }), region: str({ maxLength: 80 }), location: str({ maxLength: 120 }), scheduledAt: dateTime(), format: ref('Format'), capacity: integer({ minimum: 1, maximum: 100 }), approvalRequired: bool(), visibility: str({ enum: ['public', 'private'], default: 'public' }), requiredPositions: array(str({ maxLength: 32 })) }, ['title', 'region', 'location', 'scheduledAt', 'format', 'capacity']),
  Application: object({ id: uuid(), game_id: uuid(), user_id: uuid(), position: str({ nullable: true }), status: str(), display_name: str(), ...timestamps }, ['id', 'game_id', 'user_id', 'position', 'status', 'created_at', 'updated_at']),
};

type OperationOptions = { body?: SchemaObject | { $ref: string }; bodyDescription?: string; response?: SchemaObject | { $ref: string }; errors?: number[]; description?: string; params?: Record<string, SchemaObject> };
type Paths = OpenAPIObject['paths'];
const paths: Paths = {};
function route(method: 'get' | 'post' | 'patch', path: string, tag: string, summary: string, options: OperationOptions = {}) {
  const protectedRoute = path.startsWith('/community/') || ['/auth/phone/resend', '/auth/phone/verify', '/auth/session', '/auth/logout'].includes(path);
  const status = method === 'post' ? '201' : '200';
  const params = [...path.matchAll(/\{([^}]+)\}/g)].map(([, name]) => ({ name, in: 'path' as const, required: true, schema: options.params?.[name] ?? (name === 'token' ? str({ pattern: '^[A-Za-z0-9_-]{32}$' }) : uuid()) }));
  const errors = [...new Set([...(protectedRoute ? [401, ...(path.startsWith('/community/') ? [403] : [])] : []), ...(options.errors ?? [])])];
  const responses: Record<string, any> = { [status]: { description: 'Successful response', ...(options.response ? { content: { 'application/json': { schema: options.response } } } : {}) } };
  for (const error of errors) responses[error] = { description: ({ 400: 'Invalid request', 401: 'Invalid or missing session', 403: 'Authentication or permission required', 404: 'Resource not found', 409: 'Conflict with current state', 429: 'Rate limit exceeded', 503: 'Service unavailable' } as Record<number, string>)[error], content: { 'application/json': { schema: ref('Error') } } };
  paths[path] ??= {};
  paths[path][method] = { tags: [tag], summary, ...(options.description ? { description: options.description } : {}), ...(protectedRoute ? { security: [{ bearerAuth: [] }] } : {}), ...(params.length ? { parameters: params } : {}), ...(options.body ? { requestBody: { required: true, ...(options.bodyDescription ? { description: options.bodyDescription } : {}), content: { 'application/json': { schema: options.body } } } } : {}), responses };
}

route('get', '/health', 'Health', 'Check API health', { response: object({ status: str(), service: str() }, ['status', 'service']) });
route('post', '/identity/eligibility', 'Identity', 'Evaluate age eligibility', { body: object({ dateOfBirth: date() }, ['dateOfBirth']), response: ref('Eligibility'), errors: [400] });
// Eligibility errors use a domain-specific shape instead of Nest's standard error.
paths['/identity/eligibility'].post!.responses['400'] = { description: 'Invalid or ineligible date of birth', content: { 'application/json': { schema: ref('EligibilityError') } } };
route('post', '/auth/register', 'Authentication', 'Register and request phone verification', { body: ref('Register'), response: ref('RegistrationResult'), errors: [400, 409, 429], description: 'A session is created even when SMS delivery fails; check sent and use the resend endpoint.' });
route('post', '/auth/login', 'Authentication', 'Sign in', { body: ref('Login'), response: ref('Credentials'), errors: [401, 429] });
route('post', '/auth/phone/resend', 'Authentication', 'Resend verification code', { response: object({ sent: bool() }, ['sent']), errors: [400, 429, 503] });
route('post', '/auth/phone/verify', 'Authentication', 'Verify phone number', { body: ref('VerifyPhone'), response: object({ verified: bool(), user: ref('User') }, ['verified', 'user']), errors: [400, 429] });
route('get', '/auth/session', 'Authentication', 'Get current session', { response: ref('Session') });
route('post', '/auth/logout', 'Authentication', 'Sign out', { response: object({ signedOut: bool() }, ['signedOut']) });

const communityErrors = [400, 403, 404, 409];
const community = (method: 'get' | 'post' | 'patch', path: string, tag: string, summary: string, response: SchemaObject | { $ref: string }, options: OperationOptions = {}) => route(method, `/community${path}`, tag, summary, { errors: communityErrors, ...options, response });
const statusResponse = object({ status: str() }, ['status']);
const activeResponse = object({ active: bool() }, ['active']);
community('get', '/notifications', 'Notifications', 'List notifications', array(ref('Notification')));
community('get', '/teams', 'Teams', 'List visible teams', array(ref('TeamSummary')));
community('post', '/teams', 'Teams', 'Create a team', ref('Team'), { body: ref('CreateTeam') });
community('get', '/teams/{id}', 'Teams', 'Get team and roster', ref('Roster'));
community('patch', '/teams/{id}/formats', 'Teams', 'Update team formats', ref('Team'), { body: ref('TeamFormats') });
community('post', '/teams/{id}/requests', 'Teams', 'Request to join a public team', ref('JoinRequest'));
community('get', '/teams/{id}/requests', 'Teams', 'List pending join requests', array(ref('JoinRequest')));
community('post', '/teams/{id}/requests/{request}/{decision}', 'Teams', 'Approve or reject a join request', statusResponse, { params: { decision: str({ enum: ['approve', 'reject'] }) } });
community('post', '/teams/{id}/invites', 'Teams', 'Create a team invitation', ref('Invite'));
community('post', '/teams/{id}/leave', 'Teams', 'Leave a team', activeResponse);
community('post', '/invites/{token}/accept', 'Teams', 'Accept a team invitation', object({ teamId: uuid() }, ['teamId']));
community('patch', '/teams/{id}/members/{member}', 'Teams', 'Update a team member', ref('UpdatedMember'), { body: ref('UpdateMember') });
community('get', '/challenges', 'Challenges', 'List visible challenges', array(ref('Challenge')));
community('post', '/challenges', 'Challenges', 'Create a challenge', ref('Challenge'), { body: ref('CreateChallenge'), description: 'The scheduled time must be in the future. The caller must be a captain of the selected team.' });
community('get', '/challenges/{id}', 'Challenges', 'Get a challenge, proposals and field votes', ref('ChallengeDetail'));
community('post', '/challenges/{id}/{action}', 'Challenges', 'Perform a challenge action', ref('Challenge'), { body: ref('ChallengeAction'), params: { action: str({ enum: ['join', 'counter', 'accept', 'decline', 'cancel', 'confirm', 'field-status', 'field-proposal', 'field-approve'] }) }, bodyDescription: 'All actions require teamId. counter additionally requires scheduledAt, region and field; field-status requires status; field-proposal requires field.' });
community('get', '/games', 'Games', 'List visible games', array(ref('Game')));
community('get', '/games/{id}', 'Games', 'Get a game', ref('Game'));
community('post', '/games', 'Games', 'Create a game', ref('Game'), { body: ref('CreateGame'), description: 'The scheduled time must be in the future.' });
community('post', '/game-invites/{token}/accept', 'Games', 'Accept a game invitation', ref('Application'));
community('post', '/games/{id}/invites', 'Games', 'Create a game invitation', ref('Invite'));
community('post', '/games/{id}/lifecycle/{action}', 'Games', 'Cancel or complete a game', ref('Game'), { params: { action: str({ enum: ['cancel', 'complete'] }) } });
community('post', '/games/{id}/apply', 'Games', 'Apply to a public game', ref('Application'));
community('post', '/games/{id}/withdraw', 'Games', 'Withdraw from a game', statusResponse);
community('post', '/games/{id}/applications/{application}/remove', 'Games', 'Remove an approved participant', statusResponse);
community('get', '/games/{id}/applications', 'Games', 'List game applications', array(ref('Application')));
community('post', '/games/{id}/applications/{application}/{decision}', 'Games', 'Approve or reject an application', ref('Application'), { params: { decision: str({ enum: ['approve', 'reject'] }) } });

export const openApiDocument: OpenAPIObject = {
  openapi: '3.0.3',
  info: { title: 'Showtime API', version: '0.1.0', description: 'HTTP API for identity, authentication and the football community. Community endpoints require a verified phone and a bearer session token.' },
  paths,
  components: { schemas, securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'session token' } } },
};

export function setupOpenApi(app: INestApplication): void {
  SwaggerModule.setup('docs', app, openApiDocument, { jsonDocumentUrl: 'openapi.json', yamlDocumentUrl: 'openapi.yaml' });
}
