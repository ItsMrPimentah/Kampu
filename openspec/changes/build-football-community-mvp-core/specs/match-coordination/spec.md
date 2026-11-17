# Spec Delta

## Purpose

Coordinates the full community match journey from format-aware discovery and team negotiation through player attendance and recording a successfully played football match.

## ADDED Requirements

### Requirement: Support approved football formats
The system SHALL support five-a-side, seven-a-side, and eleven-a-side formats with required starting rosters of 5, 7, and 11 players per team.

#### Scenario: Captain creates a supported challenge
- **WHEN** a captain selects five-a-side, seven-a-side, or eleven-a-side
- **THEN** the system accepts exactly one of those formats and applies its starting-roster requirement

#### Scenario: Unsupported format is submitted
- **WHEN** a client submits a format outside the supported set
- **THEN** the system rejects the request and does not create the challenge

### Requirement: Manage challenge lifecycle
The system SHALL represent challenge states from draft through open, negotiation, agreement, scheduling, confirmation, completion, cancellation, and expiry.

#### Scenario: Captain publishes a challenge
- **WHEN** an authorized captain submits a valid challenge
- **THEN** the system publishes it as open with its format, skill, schedule, location, and payment conditions

#### Scenario: Challenge is cancelled
- **WHEN** an authorized actor cancels an open, negotiating, agreed, or scheduled challenge
- **THEN** the system records cancellation and prevents new acceptance or enrollment

### Requirement: Enforce one selected opponent
The system SHALL allow at most one opposing team to be selected for a challenge and SHALL prevent a team from challenging itself.

#### Scenario: Host accepts an opposing team
- **WHEN** the host captain approves a valid opposing team
- **THEN** the system selects that team and rejects incompatible competing selections

#### Scenario: Team challenges itself
- **WHEN** a captain attempts to select the host team as the opposing team
- **THEN** the system rejects the operation

### Requirement: Preserve challenge negotiation history
The system SHALL record each challenge proposal, counteroffer, acceptance, rejection, and material change as an ordered versioned history.

#### Scenario: Opposing captain submits a counteroffer
- **WHEN** an opposing captain changes a negotiable condition
- **THEN** the system creates a new proposal version and notifies affected captains

#### Scenario: Agreed condition changes
- **WHEN** a material date, venue, format, or payment condition changes after agreement
- **THEN** the system records the change and requires the affected parties to approve it again before confirmation

### Requirement: Provide eligible discovery
The system SHALL filter challenge and Open Game discovery by approximate location, football format, eligibility, availability, and configured search criteria.

#### Scenario: Player searches for an Open Game
- **WHEN** an eligible player searches with a format and location range
- **THEN** the system returns only eligible games matching the requested criteria and available capacity

#### Scenario: Youth user views discovery
- **WHEN** a user aged 16–17 views challenge or game discovery
- **THEN** the system applies youth privacy and communication restrictions to the results

### Requirement: Coordinate Open Games
The system SHALL allow an organizer to publish an Open Game with player slots, applications, approvals, waiting-list behavior, and required positions.

#### Scenario: Player applies to an Open Game
- **WHEN** an eligible player requests an available slot
- **THEN** the system records the application and exposes it to the organizer for approval

#### Scenario: Game reaches capacity
- **WHEN** approved participants fill all configured starting and substitute slots
- **THEN** the system prevents additional approvals and places eligible applicants on a waiting list when enabled

### Requirement: Manage attendance and completion
The system SHALL allow authorized organizers to request attendance confirmation, record participant status, and mark whether an agreed match was played.

#### Scenario: Participant confirms attendance
- **WHEN** an enrolled participant confirms attendance
- **THEN** the system records the confirmation and notifies the organizer of the roster update

#### Scenario: Organizer records a completed match
- **WHEN** an authorized organizer records that a scheduled match was played
- **THEN** the system marks the match completed and emits a completion event for analytics

### Requirement: Prevent incompatible concurrent actions
The system SHALL use server-side validation so concurrent challenge, roster, booking, and confirmation operations cannot create incompatible opponents, duplicate enrollment, or duplicate match completion events.

#### Scenario: Two captains select competing opponents concurrently
- **WHEN** concurrent operations attempt to select different opposing teams for one challenge
- **THEN** only one valid selection succeeds and the other receives a conflict response

#### Scenario: Duplicate completion event is received
- **WHEN** the same completion operation is submitted more than once
- **THEN** the system records one completion transition and treats subsequent submissions as idempotent
