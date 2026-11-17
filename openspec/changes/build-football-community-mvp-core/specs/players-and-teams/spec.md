# Spec Delta

## Purpose

Provides the player and team identity layer required for users to discover compatible teammates, form teams, manage membership, and represent teams in football challenges.

## ADDED Requirements

### Requirement: Maintain player profiles
The system SHALL allow eligible users to maintain a player profile containing a display identity, preferred positions, skill level, availability preferences, and approximate location.

#### Scenario: User completes a player profile
- **WHEN** an eligible user saves valid profile information
- **THEN** the system stores the profile and exposes only fields permitted by the user’s privacy and age policy

#### Scenario: User updates profile information
- **WHEN** a user changes a profile field
- **THEN** the system validates the change and applies it to future discovery results

### Requirement: Create and manage teams
The system SHALL allow any eligible user aged 16 or older to create and manage a team.

#### Scenario: Eligible user creates a team
- **WHEN** a user aged 16 or older submits valid team details
- **THEN** the system creates the team and assigns the creator the captain role

#### Scenario: Ineligible user attempts team creation
- **WHEN** a user under 16 attempts to create a team
- **THEN** the system rejects the operation

### Requirement: Support team-scoped membership
The system SHALL allow an eligible player to belong to multiple teams and SHALL keep membership, roles, and permissions scoped to each team.

#### Scenario: Player joins a second team
- **WHEN** an eligible player accepts a valid invitation to another team
- **THEN** the system creates a separate membership without removing the player from existing teams

#### Scenario: Team membership ends
- **WHEN** an authorized captain removes a member or a member leaves a team
- **THEN** the system ends that team membership without changing memberships in other teams

### Requirement: Control team administration
The system SHALL restrict team membership and team-management actions to the captain or another role explicitly granted the corresponding team permission.

#### Scenario: Captain invites a player
- **WHEN** a captain sends an invitation to an eligible player
- **THEN** the system creates a pending invitation and notifies the invited player

#### Scenario: Unauthorized member changes team settings
- **WHEN** a member without the required team permission attempts to change team settings
- **THEN** the system rejects the operation and records the authorization failure

### Requirement: Represent team readiness
The system SHALL expose team format support and roster readiness so challenges can distinguish teams that meet required player counts from teams needing additional players.

#### Scenario: Team supports a football format
- **WHEN** an authorized captain configures a supported format for a team
- **THEN** the team becomes discoverable for that format subject to eligibility and location filters

#### Scenario: Team lacks required players
- **WHEN** a team has fewer eligible starting players than its selected format requires
- **THEN** the system marks the team as requiring additional players and prevents it from being treated as complete for that format
