# Mobile auth presentation

## Purpose

Provide truthful and accessible mobile authentication interactions while preserving the existing authentication service behavior.

## ADDED Requirements

### Requirement: Truthful SMS delivery status
The verification screen SHALL describe SMS delivery only to the extent known by the client.

#### Scenario: Login or restored session has unknown delivery
- **WHEN** the user enters verification without a known SMS delivery result
- **THEN** the screen offers neutral instructions without claiming a delivery failure or successful send

#### Scenario: Registration reports delivery failure
- **WHEN** registration reports that sending the SMS failed
- **THEN** the screen communicates the failure and offers a resend action

### Requirement: Verification action feedback
The verification screen SHALL reject incomplete verification codes locally and provide feedback appropriate to the action that fails.

#### Scenario: Incomplete code
- **WHEN** the user submits fewer than six digits
- **THEN** the app explains that six digits are required without making a verification request

#### Scenario: Resend or sign-out fails
- **WHEN** a resend or sign-out request fails
- **THEN** the app reports the failure of that action without incorrectly blaming the verification code

### Requirement: Honest registration presentation
Registration SHALL not imply that an empty or invalid phone number is verified or valid.

#### Scenario: Phone input before validation
- **WHEN** the phone field is empty or invalid
- **THEN** its icon is neutral and does not indicate successful validation

### Requirement: Accessible auth presentation
Authentication screens SHALL preserve accessible, responsive controls and the established Midnight visual identity.

#### Scenario: Registration navigation
- **WHEN** a user invokes registration navigation using an accessible control
- **THEN** the control performs its advertised navigation without depending on a gesture-only target
