# Spec Delta

## Purpose

Defines the Midnight mobile discovery experience for finding matches, teams, pickup games, pitches, and scheduling options using clear availability, booking, and offline-state presentation.

## ADDED Requirements

### Requirement: Present Discover as the authenticated Home
The app SHALL present the Stitch Discover screen as Home with an upcoming fixture, team challenges, and open games.

#### Scenario: User opens Home
- **WHEN** an authenticated user opens the Discover destination
- **THEN** the app shows the next fixture and mocked discovery content without requiring a network request

#### Scenario: User views an actionable discovery item
- **WHEN** the user selects Challenge Team or Join Match
- **THEN** the app opens the corresponding challenge or open-game flow with the selected item preserved

### Requirement: Support local mock discovery data
The discovery surfaces SHALL render deterministic local data for fixtures, challenges, open games, venues, slots, and negotiation history when backend data is unavailable.

#### Scenario: Backend data is unavailable
- **WHEN** the discovery surface is opened without a usable backend response
- **THEN** the app renders the local snapshot and does not show a blank or blocking error state

#### Scenario: User interacts with mocked data
- **WHEN** the user joins a game, challenges a team, reserves a slot, or changes an offer
- **THEN** the app updates the local presentation state and communicates the result to the user

### Requirement: Provide pitch scheduling filters
The Pitches destination SHALL allow users to filter local pitch results by date, football format, surface type, and approximate distance.

#### Scenario: User changes pitch filters
- **WHEN** the user changes a date, format, surface, or distance filter
- **THEN** the displayed venue cards and slot summaries reflect the selected filters using the local dataset

#### Scenario: User selects a slot
- **WHEN** the user selects an available pitch slot
- **THEN** the selected slot is visibly distinguished and can be submitted through the reserve action

### Requirement: Represent venue availability truthfully
The Pitches destination SHALL distinguish native instant booking, external provider availability, stale/offline snapshots, and sold-out states without claiming unavailable provider confirmation.

#### Scenario: User views a native venue
- **WHEN** a venue has a mocked native booking state
- **THEN** the card identifies it as native, displays its available slots, and exposes a reserve action

#### Scenario: User views an external venue
- **WHEN** a venue uses an external provider
- **THEN** the card identifies the external source and offers provider navigation instead of claiming native confirmation

#### Scenario: No slots are available
- **WHEN** the selected filters produce no available slots
- **THEN** the app shows the sold-out state with alternative dates or a notify-on-drop action

### Requirement: Show offline snapshot status
The Pitches destination SHALL identify when the displayed venue and slot information comes from a locally cached snapshot.

#### Scenario: Cached snapshot is displayed
- **WHEN** the venue feed is rendered from local data
- **THEN** the app displays an offline or snapshot status with the last-sync context and avoids implying live availability

#### Scenario: User retries availability
- **WHEN** the user activates the retry action
- **THEN** the app presents a local retry result while retaining usable cached content

### Requirement: Present challenge negotiation state
The challenge detail view SHALL show the participating teams, negotiation status, ordered offer changes, changed terms, and available decision actions.

#### Scenario: User opens a negotiation
- **WHEN** the user opens a challenge with a pending counter-offer
- **THEN** the app displays the latest offer, changed kickoff/venue/cost terms, negotiation message, and revision status

#### Scenario: User accepts the latest offer
- **WHEN** the user selects the accept-and-lock action
- **THEN** the app updates the mocked negotiation state to accepted/locked and shows the resulting status

#### Scenario: User declines or proposes a counter
- **WHEN** the user selects Decline or Counter
- **THEN** the app updates the mocked interaction state and communicates the next pending action without contacting a backend
