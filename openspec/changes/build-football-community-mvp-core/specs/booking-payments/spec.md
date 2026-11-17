# Spec Delta

## Purpose

Coordinates booking payment responsibility and participant contribution status without operating a wallet, while preserving reliable provider events, captain guarantees, dispute handling, and financial reconciliation.

## ADDED Requirements

### Requirement: Make the captain the booking guarantor
The system SHALL allow an eligible captain aged 16 or older to accept financial responsibility for the full booking amount and SHALL not require every participant contribution before a provider-confirmed booking can remain active.

#### Scenario: Captain accepts booking responsibility
- **WHEN** a captain reviews and accepts the total price and disclosed fees
- **THEN** the system records the captain as guarantor and the amount they are responsible for

#### Scenario: Participant share is unpaid
- **WHEN** a participant has not paid an assigned share
- **THEN** the system keeps the captain guarantee and records the participant contribution as outstanding without falsely changing the provider booking state

### Requirement: Support captain-paid and participant-contribution models
The system SHALL support full captain payment and assigned participant contributions while keeping booking payment, contribution, and attendance states separate.

#### Scenario: Captain pays the venue
- **WHEN** the captain chooses the full-payment model and a valid payment succeeds
- **THEN** the booking payment records the provider result and participant contributions remain separate records

#### Scenario: Organizer assigns contributions
- **WHEN** an organizer selects participant contributions and assigns amounts
- **THEN** the system records each contribution and validates that assigned amounts equal the collectable amount after configured rounding and fees

### Requirement: Track payment status and financial records
The system SHALL track pending, processing, succeeded, failed, cancelled, refunded, disputed, and outstanding payment-related states with booking, participant, amount, currency, and provider references.

#### Scenario: Payment fails
- **WHEN** a payment attempt is rejected or expires
- **THEN** the system records the failure, does not mark the booking payment succeeded, and exposes the next permitted action

#### Scenario: Refund is issued
- **WHEN** an authorized refund is completed or confirmed by the provider
- **THEN** the system records the refund amount, reason, reference, and affected booking or contribution

### Requirement: Process verified provider events safely
The system SHALL verify provider webhook signatures, deduplicate events by provider event identity, and apply payment transitions idempotently.

#### Scenario: Signed success webhook arrives
- **WHEN** a valid signed webhook reports a successful payment
- **THEN** the system records the event once and updates the related payment state to succeeded

#### Scenario: Duplicate webhook arrives
- **WHEN** an already processed webhook is delivered again
- **THEN** the system does not create another charge, booking, transfer, or financial record

### Requirement: Record direct payments as captain-reported
The system SHALL allow a captain to record that a participant paid directly to the captain and SHALL label that status as captain-reported rather than provider-confirmed.

#### Scenario: Captain records direct payment
- **WHEN** a captain marks an assigned participant contribution as received directly
- **THEN** the system records the captain, amount, timestamp, source, and contribution status as paid_to_captain_reported

#### Scenario: Participant views payment source
- **WHEN** a participant views their contribution
- **THEN** the system identifies whether it is provider-confirmed, captain-reported, pending, outstanding, or disputed

### Requirement: Allow participant payment disputes
The system SHALL allow a participant to dispute a captain-reported contribution and SHALL preserve the booking and attendance states independently while the dispute is reviewed.

#### Scenario: Participant disputes a direct payment
- **WHEN** a participant disputes a captain-reported contribution with a reason
- **THEN** the system creates an auditable dispute, notifies the captain, and leaves booking confirmation unchanged

#### Scenario: Dispute is resolved as unpaid
- **WHEN** an authorized resolver determines that a reported contribution was not received
- **THEN** the system marks the contribution outstanding and retains the captain’s booking guarantee

### Requirement: Use captain-first dispute resolution with escalation
The system SHALL route a direct-payment dispute to the captain first and SHALL automatically escalate it to platform support when the captain does not resolve it within the configured review deadline or the participant requests escalation.

#### Scenario: Captain resolves a dispute
- **WHEN** the captain reviews a dispute and records a resolution
- **THEN** the system records the resolution, actor, timestamp, and resulting contribution state and notifies the participant

#### Scenario: Captain misses the review deadline
- **WHEN** the configured captain review deadline expires without resolution
- **THEN** the system creates or updates a platform-support case and notifies the participant and captain

### Requirement: Avoid funds custody through contribution tracking
The system SHALL not represent direct participant-to-captain payments as platform-held funds, wallet balances, or guaranteed transfers by the platform.

#### Scenario: Direct payment is recorded
- **WHEN** a captain records an off-platform participant payment
- **THEN** the system records an informational contribution assertion and does not create platform custody, wallet, or escrow balance

#### Scenario: Provider payment is reconciled
- **WHEN** a provider payment is settled or reversed
- **THEN** the system reconciles the provider transaction against the booking and financial records without treating unrelated direct payments as provider transactions
