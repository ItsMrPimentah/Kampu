# Spec Delta

## Purpose

Provides age-aware identity, privacy, communication, and moderation controls so Football Community can operate safely for eligible users aged 16 and above.

## ADDED Requirements

### Requirement: Enforce minimum account age
The system SHALL prevent users younger than 16 from creating accounts or participating in platform activities.

#### Scenario: User is under the minimum age
- **WHEN** a user submits a date of birth that indicates an age below 16
- **THEN** account creation is rejected and the user cannot access community features

#### Scenario: User reaches the minimum age
- **WHEN** a user submits a date of birth that indicates an age of 16 or older
- **THEN** the system permits onboarding subject to normal authentication and policy checks

### Requirement: Separate youth and adult eligibility
The system SHALL retain whether an eligible user is aged 16–17 or 18+ for policy decisions without requiring a parent or guardian consent workflow.

#### Scenario: Youth user completes onboarding
- **WHEN** an authenticated user is between 16 and 17 years old
- **THEN** the system assigns youth eligibility and does not request guardian authorization

#### Scenario: Adult user completes onboarding
- **WHEN** an authenticated user is at least 18 years old
- **THEN** the system assigns adult eligibility

### Requirement: Protect youth privacy
The system SHALL protect users aged 16–17 from precise public location exposure and unrestricted discovery by unknown adults.

#### Scenario: Youth profile is shown in discovery
- **WHEN** a youth profile appears in an eligible discovery result
- **THEN** the result uses an approximate location and excludes precise address or coordinate data

#### Scenario: Unknown adult attempts prohibited discovery
- **WHEN** an adult user attempts to discover a youth profile outside an authorized team, match, or relationship context
- **THEN** the system withholds the youth profile from that discovery result

### Requirement: Restrict unsafe direct communication
The system SHALL prevent unrestricted private messaging between adults and youth users and SHALL preserve permitted team or match communication contexts.

#### Scenario: Unknown adult starts a private conversation with a youth
- **WHEN** an adult user without an authorized team or match context attempts to initiate a private conversation with a youth
- **THEN** the system prevents the conversation from being created

#### Scenario: Permitted team communication occurs
- **WHEN** eligible users share an authorized team or match context
- **THEN** the system permits only the communication features allowed by the applicable safety policy

### Requirement: Support user safety actions
The system SHALL allow users to block and report other users or content and SHALL make reports available to authorized moderation staff.

#### Scenario: User blocks another user
- **WHEN** a user blocks another user
- **THEN** the blocked user cannot initiate prohibited interactions or appear in restricted discovery surfaces for the blocker

#### Scenario: User submits a report
- **WHEN** a user submits a report with a target and reason
- **THEN** the system records the report, acknowledges submission, and makes it available to authorized moderators

### Requirement: Audit sensitive authorization decisions
The system SHALL record auditable events for age eligibility, safety restrictions, moderation actions, and changes to sensitive access decisions.

#### Scenario: Moderator changes a safety decision
- **WHEN** an authorized moderator changes a user or content safety decision
- **THEN** the system records the actor, action, target, timestamp, and relevant reason without exposing unnecessary personal data
