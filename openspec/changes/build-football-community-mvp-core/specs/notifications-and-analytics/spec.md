# Spec Delta

## Purpose

Keeps players, captains, operators, and support staff informed about important lifecycle changes while measuring the difference between intended, agreed, booked, attended, and completed matches.

## ADDED Requirements

### Requirement: Notify important lifecycle changes
The system SHALL notify affected users about challenge proposals, counteroffers, approvals, material changes, booking results, payment failures, dispute escalation, cancellations, and attendance requests.

#### Scenario: Challenge receives a counteroffer
- **WHEN** an opposing captain submits a counteroffer
- **THEN** the host captain receives an actionable notification identifying the changed conditions

#### Scenario: Booking fails
- **WHEN** a provider rejects or fails a booking request
- **THEN** affected captains and participants receive a notification that does not claim the venue is confirmed

### Requirement: Deliver notifications with safe content
The system SHALL avoid exposing precise youth location, sensitive payment details, or private report content in notifications not authorized to contain it.

#### Scenario: Youth participant receives a match notification
- **WHEN** a youth participant receives a notification about a match
- **THEN** the notification contains only the location precision and participant information allowed by the safety policy

#### Scenario: Payment dispute escalates
- **WHEN** a direct-payment dispute is escalated to support
- **THEN** the notification identifies the case status without exposing the other party’s private evidence or financial details

### Requirement: Measure match funnel transitions
The system SHALL record distinct events for challenge publication, opponent agreement, schedule agreement, booking declaration, provider booking confirmation, payment completion, attendance confirmation, match completion, cancellation, and no-show.

#### Scenario: Match is successfully played
- **WHEN** an authorized organizer records a scheduled match as played
- **THEN** the system records a completed-match event linked to the challenge, booking, teams, and participants

#### Scenario: Challenge is cancelled before play
- **WHEN** a challenge is cancelled before completion
- **THEN** the system records cancellation without counting the challenge as a successfully played match

### Requirement: Provide operational metrics
The system SHALL provide authorized operators with metrics that distinguish published challenges, confirmed opponents, venue confirmations, funded bookings, completed matches, cancellations, payment failures, disputes, and no-shows.

#### Scenario: Operator reviews weekly completion
- **WHEN** an authorized operator requests a weekly match report
- **THEN** the report shows completed matches separately from published challenges and agreed matches

#### Scenario: Operator reviews payment reliability
- **WHEN** an authorized operator requests payment metrics
- **THEN** the report separates provider-confirmed payments, captain-reported contributions, failed attempts, refunds, and disputes

### Requirement: Protect analytics privacy
The system SHALL limit analytics collection and reporting according to user age eligibility, consent, access permissions, and data-minimization policy.

#### Scenario: Youth activity is included in aggregate reporting
- **WHEN** an operator views aggregate community metrics containing youth activity
- **THEN** the report does not expose unnecessary individual youth location, profile, or behavioral data

#### Scenario: Analytics consent is absent
- **WHEN** consent is required for an optional analytics purpose but is not available
- **THEN** the system excludes that optional data from collection or processing
