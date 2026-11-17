# Spec Delta

## Purpose

Defines a consistent, accessible Midnight/SRE presentation language for the mobile client so discovery, negotiation, scheduling, onboarding, and squad workflows feel like one Stitch-designed product without changing their domain behavior.

## ADDED Requirements

### Requirement: Use the approved Midnight visual language
Supported mobile surfaces SHALL use the Stitch Midnight palette, typography hierarchy, spacing rhythm, rounded shapes, and tonal elevation consistently.

#### Scenario: User moves between supported screens
- **WHEN** an eligible user navigates between Home, Challenges, Pitches, Squad, registration, and existing hubs
- **THEN** surfaces, text hierarchy, controls, borders, and status colors present as one coherent Midnight/SRE system

#### Scenario: User views a primary action
- **WHEN** a screen presents its main action
- **THEN** the action uses the approved iris-to-periwinkle treatment, readable contrast, and a touch target of at least 44dp

### Requirement: Present the authenticated shell as a shared mobile console
The authenticated experience SHALL expose the same compact header, content rhythm, safe-area handling, and four-destination navigation dock across primary destinations and detail flows.

#### Scenario: User opens a primary destination
- **WHEN** the current route is Home, Challenges, Pitches, or Squad
- **THEN** the shell shows the corresponding active dock destination with inactive destinations visibly distinct

#### Scenario: User opens a detail route
- **WHEN** the user opens a challenge or pitch detail flow
- **THEN** the detail content retains the shared shell context and provides an accessible back action

### Requirement: Make visual states explicit
Discovery, negotiation, venue, booking, payment, safety, and eligibility states SHALL use distinct labels, badges, and signal colors that do not overstate authority or completion.

#### Scenario: User views venue availability
- **WHEN** a venue is native, external, cached, pending, confirmed, or sold out
- **THEN** the UI identifies that state with the corresponding Stitch-style badge and action without claiming provider confirmation when it is absent

#### Scenario: User views a negotiation
- **WHEN** a challenge has pending, countered, accepted, or declined status
- **THEN** the status, latest terms, changed terms, and available actions remain visually distinguishable and readable

### Requirement: Preserve usable mobile layout and accessibility
Supported screens SHALL remain usable from 360dp through 430dp widths, respect safe-area insets, maintain readable contrast, and expose meaningful labels and selected states to assistive technologies.

#### Scenario: Screen renders on a narrow device
- **WHEN** a supported screen is rendered at 360dp width with bottom system insets
- **THEN** required content, actions, and navigation remain reachable without horizontal clipping or unsafe overlap

#### Scenario: User navigates with accessibility services
- **WHEN** an assistive technology inspects navigation, filters, status badges, or primary actions
- **THEN** controls have meaningful labels and state changes are communicated without relying on color alone

### Requirement: Keep the presentation offline-safe
The supported mobile experience SHALL render its visual shell, icons, fonts, and optional imagery without requiring runtime access to remote font, icon, or image URLs.

#### Scenario: Device has no network connection
- **WHEN** a user opens a supported screen offline
- **THEN** local icons and bundled/fallback imagery render, while cached or local content remains usable

#### Scenario: Optional imagery is unavailable
- **WHEN** a referenced local image is missing or cannot be decoded
- **THEN** the UI shows a stable placeholder or icon treatment without breaking layout or interaction

### Requirement: Preserve existing workflow contracts during restyling
Visual refinement SHALL not alter existing route locations, eligibility rules, youth-safety messaging, local interaction outcomes, booking authority labels, or callback behavior.

#### Scenario: User completes an existing action after restyling
- **WHEN** a user joins a game, changes a challenge offer, reserves a native slot, opens an external provider, registers, or enters an existing hub
- **THEN** the same route, local state transition, feedback, and authority wording remain available as before the visual refinement
