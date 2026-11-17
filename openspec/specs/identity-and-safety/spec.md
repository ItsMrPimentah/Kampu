# identity-and-safety Specification

## Purpose

Provides a safe, accessible registration experience for eligible Showtime participants while preserving the product’s 16+ age policy and clearly communicating youth-protection state. The capability defines the observable registration behavior independently of the eventual authentication provider.

## Requirements

### Requirement: Render the Stitch registration experience
The mobile client SHALL provide a registration screen that presents the current Pitch Pulse visual hierarchy and the complete player-pass flow on supported mobile widths.

#### Scenario: Registration screen opens
- **WHEN** an unauthenticated user opens registration
- **THEN** the client shows the Pitch Pulse dark surface, top bar with back/help controls and “Step 1 of 2”, identity header, role cards, registration fields, consent, primary CTA, and login handoff

#### Scenario: Content remains usable on a narrow device
- **WHEN** the registration screen is rendered between 360dp and 430dp wide
- **THEN** content remains readable, controls remain reachable, and no required field or action is clipped horizontally

### Requirement: Select a registration role accessibly
The mobile client SHALL expose Player, Squad Captain, and Guardian as mutually exclusive registration roles, with Player selected by default and the selected state communicated visually and semantically.

#### Scenario: Player is the default role
- **WHEN** registration opens without a previously selected role
- **THEN** Player is selected and its radio semantics expose a checked state while the other roles are unchecked

#### Scenario: User changes role
- **WHEN** the user taps or activates a different role card
- **THEN** the previously selected role becomes unchecked, the new role becomes checked, and only the new role receives the selected border, glow, and indicator

#### Scenario: Role selection is keyboard or assistive-technology reachable
- **WHEN** a user navigates role cards using a supported accessibility interaction
- **THEN** each role has an understandable label, selected state, and actionable focus/activation behavior

### Requirement: Validate registration inputs before continuation
The registration flow SHALL validate required identity and contact fields, reject invalid values with field-associated feedback, and block continuation until all required inputs are valid and terms are accepted.

#### Scenario: Required fields are incomplete
- **WHEN** the user activates “CONTINUE TO VERIFY” with a missing name, date of birth, phone, email, password, or terms consent
- **THEN** the client keeps the user on registration, identifies the invalid or missing fields, and does not invoke the registration-completion callback

#### Scenario: Valid registration data is submitted
- **WHEN** the user provides a non-empty name, valid date of birth, valid phone and email, a password meeting the displayed strength policy, and accepts the Community Code of Conduct and Privacy Policy
- **THEN** the client invokes the registration continuation callback with the selected role and normalized form data

#### Scenario: Password feedback is shown
- **WHEN** the password changes
- **THEN** the client updates a visible strength indicator and provides a visibility toggle without exposing the password in logs or accessibility labels

### Requirement: Preserve age-aware eligibility and youth protection
The registration flow SHALL use the existing age policy: users under 16 cannot continue, ages 16–17 receive youth eligibility, and ages 18+ receive adult eligibility; role selection or UI messaging MUST NOT create a guardian-consent requirement.

#### Scenario: Underage user enters a date of birth
- **WHEN** the entered date of birth calculates to an age below 16
- **THEN** the client rejects continuation, explains the minimum age requirement, and does not invoke the registration-completion callback

#### Scenario: Youth user enters an eligible date of birth
- **WHEN** the entered date of birth calculates to an age from 16 through 17
- **THEN** the client marks the form as youth-protected, shows the youth-protection status affordance, and does not request guardian authorization as a prerequisite

#### Scenario: Adult user enters an eligible date of birth
- **WHEN** the entered date of birth calculates to an age of 18 or older
- **THEN** the client marks the form as adult-eligible and does not show youth-only protection messaging

### Requirement: Support registration navigation handoffs
The registration screen SHALL expose back, help, login, and continuation actions through callbacks or navigation contracts so the view does not own authentication-provider behavior.

#### Scenario: User chooses Log In
- **WHEN** the user activates the “Log In” handoff
- **THEN** the client invokes the login navigation callback and does not discard unsaved data unexpectedly without an explicit navigation decision

#### Scenario: User chooses Continue to Verify
- **WHEN** all registration requirements are valid and the user activates the primary CTA
- **THEN** the client invokes the verification/registration callback exactly once for that activation and shows a pending state if the caller reports work in progress

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
