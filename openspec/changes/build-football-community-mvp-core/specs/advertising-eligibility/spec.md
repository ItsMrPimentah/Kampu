# Spec Delta

## Purpose

Controls advertising according to age eligibility, consent, privacy policy, and product safety so monetization does not interfere with critical football workflows or personalize ads for youth users.

## ADDED Requirements

### Requirement: Enforce age-aware advertising eligibility
The system SHALL prevent personalized advertising for users aged 16–17 and for users whose age eligibility is not established.

#### Scenario: Youth user opens a discovery surface
- **WHEN** an authenticated user aged 16–17 views an ad-eligible surface
- **THEN** the system does not request or serve personalized advertising for that user

#### Scenario: Age eligibility is unknown
- **WHEN** a user has not established an eligible age category
- **THEN** the system blocks advertising until the configured eligibility policy permits a non-personalized experience

### Requirement: Require adult advertising consent
The system SHALL obtain and record applicable advertising consent before serving consent-dependent advertising to an eligible adult.

#### Scenario: Adult grants advertising consent
- **WHEN** an eligible adult grants the required consent
- **THEN** the system records the consent version and permits the corresponding ad configuration

#### Scenario: Adult declines advertising consent
- **WHEN** an eligible adult declines or withdraws consent
- **THEN** the system does not serve consent-dependent personalized advertising

### Requirement: Keep ads off critical workflows
The system SHALL exclude advertising from booking checkout, payment confirmation, safety reporting, and important challenge negotiation or confirmation surfaces.

#### Scenario: User completes payment
- **WHEN** a user is viewing booking checkout or payment confirmation
- **THEN** the system does not render an advertisement that could interrupt or obscure the transaction

#### Scenario: User submits a safety report
- **WHEN** a user is completing a blocking or reporting flow
- **THEN** the system does not display an advertisement within that flow

### Requirement: Control advertising remotely
The system SHALL allow authorized operators to disable or change advertising behavior through remotely controlled configuration without requiring a client release.

#### Scenario: Operator disables advertising
- **WHEN** an authorized operator disables advertising through configuration
- **THEN** clients stop requesting new advertisements after the configuration is received

#### Scenario: Advertising configuration is unavailable
- **WHEN** the client cannot obtain a valid advertising configuration
- **THEN** the client uses the conservative no-ad behavior
