# Spec Delta

## Purpose

Provides a consistent authenticated mobile navigation experience for the Midnight football community app, allowing users to move between discovery, challenges, pitches, and squad features while preserving route context.

## ADDED Requirements

### Requirement: Provide authenticated mobile destinations
The app SHALL provide four authenticated destinations named Discover, Challenges, Pitches, and Squad.

#### Scenario: Authenticated user opens the app
- **WHEN** an eligible authenticated user enters the main app
- **THEN** the app opens on the Discover destination with the Midnight shell visible

#### Scenario: User selects a primary destination
- **WHEN** the user selects Discover, Challenges, Pitches, or Squad
- **THEN** the app navigates to that destination and marks only it as active

### Requirement: Keep navigation state aligned with the route
The app SHALL derive the active primary destination from the current route so direct navigation and tab navigation produce the same selected state.

#### Scenario: User opens a destination through a direct route
- **WHEN** a valid authenticated destination route is opened directly
- **THEN** the corresponding primary destination is selected

#### Scenario: User returns from a detail route
- **WHEN** the user navigates back from a match, challenge, or pitch detail route
- **THEN** the parent destination remains selected and its navigation context is restored

### Requirement: Preserve the shared shell for detail flows
Detail routes SHALL render above the authenticated shell and SHALL provide a back path to their owning primary destination.

#### Scenario: User opens a challenge negotiation
- **WHEN** the user opens a challenge negotiation from Discover or Challenges
- **THEN** the negotiation view is shown as a detail flow while the authenticated shell remains available

#### Scenario: User exits a detail flow
- **WHEN** the user activates the back action from a detail view
- **THEN** the app returns to the originating primary destination without losing the authenticated session

### Requirement: Route existing feature hubs through the authenticated shell
Existing match, team, venue, payment, and safety capabilities SHALL remain reachable from authenticated navigation or from nested detail routes.

#### Scenario: User opens an existing capability
- **WHEN** the user follows an action from a Midnight destination to an existing feature
- **THEN** the feature opens inside the authenticated navigation context rather than replacing the application entry state

#### Scenario: User returns from an existing feature
- **WHEN** the user backs out of an existing feature
- **THEN** the app returns to the relevant Midnight destination or its owning detail route

### Requirement: Support mobile-safe presentation
The authenticated shell SHALL support mobile viewport dimensions and safe-area insets without requiring alternate desktop, web, tablet, or Windows layouts.

#### Scenario: App is rendered on a supported mobile device
- **WHEN** the shell is rendered on a supported mobile viewport
- **THEN** navigation controls and content remain usable within the viewport and safe areas
