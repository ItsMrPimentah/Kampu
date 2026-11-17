# Spec Delta

## Purpose

Provides a verifiable venue-booking workflow that supports football-pitch discovery, external reservations, and native booking through an authorized pilot partner without overstating availability or confirmation.

## ADDED Requirements

### Requirement: Maintain format-aware venue catalog
The system SHALL maintain venues with location, supported football formats, booking method, source, verification level, and current information timestamp.

#### Scenario: User searches venues
- **WHEN** a user searches for a venue with location and football-format criteria
- **THEN** the system returns venues that match the criteria and displays their booking method and information source

#### Scenario: Venue information expires
- **WHEN** a venue’s availability information exceeds its configured validity period
- **THEN** the system labels the information stale and does not present it as current provider availability

### Requirement: Expose booking status and authority
The system SHALL expose booking state separately from challenge state and SHALL identify whether information is user-declared, provider-confirmed, or unavailable.

#### Scenario: User views an external booking
- **WHEN** a user opens a booking declared from an external provider
- **THEN** the system displays the declaration source, verification level, external reference when available, and last update time

#### Scenario: Provider confirmation is absent
- **WHEN** a reservation lacks sufficient provider confirmation
- **THEN** the system does not label it provider-confirmed

### Requirement: Support external booking declarations
The system SHALL allow an authorized match participant to open an external booking flow and record a venue, requested time, external URL, reference, user declaration, and supporting receipt when supplied.

#### Scenario: Participant declares an external reservation
- **WHEN** an authorized participant submits valid external reservation details
- **THEN** the system records the booking as externally declared and not provider-verified

#### Scenario: External declaration lacks required details
- **WHEN** a user submits an external declaration without a venue, time, or source URL
- **THEN** the system rejects the declaration and identifies the missing information

### Requirement: Support native booking with an authorized partner
The system SHALL support availability lookup, slot selection, reservation creation, provider confirmation, and cancellation for at least one authorized native venue partner.

#### Scenario: Native slot is confirmed
- **WHEN** the provider confirms a selected slot after a valid reservation request
- **THEN** the system stores the provider reference and marks the booking provider-confirmed

#### Scenario: Native provider rejects a request
- **WHEN** the provider rejects or cannot complete a reservation request
- **THEN** the system marks the request failed, does not confirm the match booking, and presents an actionable alternative

### Requirement: Model booking lifecycle states
The system SHALL represent booking states including not requested, searching, slot selected, pending payment, pending provider confirmation, externally declared, confirmed, failed, cancelled, and refunded where applicable.

#### Scenario: Booking awaits provider confirmation
- **WHEN** payment or reservation processing has started but provider confirmation is not complete
- **THEN** the system marks the booking pending provider confirmation and prevents a confirmed-booking claim

#### Scenario: Booking is cancelled
- **WHEN** an authorized actor or provider cancels a booking
- **THEN** the system records cancellation, updates affected match conditions, and initiates applicable refund handling

### Requirement: Protect provider authority and idempotency
The system SHALL accept booking confirmation or modification only from an authorized venue operator, provider integration, or permitted booking workflow and SHALL make repeated provider events idempotent.

#### Scenario: Unauthorized actor attempts confirmation
- **WHEN** a user without venue or booking authority attempts to mark a booking provider-confirmed
- **THEN** the system rejects the operation and retains the prior verification state

#### Scenario: Provider repeats a reservation event
- **WHEN** the same signed provider event is delivered more than once
- **THEN** the system processes one state transition and records duplicate delivery without creating another reservation
