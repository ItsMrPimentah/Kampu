# Spec Delta

## Purpose

Provides a complete, deterministic Home/Discover preview experience for the Flutter mobile client, allowing the Stitch-designed feed to be reviewed with realistic user, team, match, and discovery context before backend services are connected.

## ADDED Requirements

### Requirement: Render the designed Home feed hierarchy
The Home/Discover experience SHALL present the approved Home Feed structure with user context, discovery controls, upcoming activity, challenges, open games, and clear local actions using the project’s established visual language.

#### Scenario: Eligible user opens Home
- **WHEN** an eligible user navigates to Home
- **THEN** the screen shows the designed hierarchy with readable identity/team context, discovery controls, at least one populated activity or discovery section, and the authenticated navigation destination marked active

#### Scenario: Home content exceeds the viewport
- **WHEN** the Home feed is displayed on a supported mobile width
- **THEN** all sections remain reachable by scrolling without horizontal overflow, clipped primary actions, or content hidden behind the navigation dock

### Requirement: Provide complete local preview context
The Home experience SHALL provide deterministic local values for every user-facing data field required by the designed feed, including identity fallback, active team, eligibility/location context, notification summary, fixtures, challenges, open-game capacity, and display timestamps.

#### Scenario: Home renders without backend data
- **WHEN** the Home screen is opened with no authenticated profile, API response, or network connection available
- **THEN** it renders the complete preview using local values and does not show missing-data errors for fields covered by the design

#### Scenario: Preview data is loaded repeatedly
- **WHEN** the Home preview is loaded more than once in the same build
- **THEN** the same identifiers, labels, ordering, capacities, and timestamps are returned unless a user performs a supported local interaction

### Requirement: Expose honest preview and availability states
The Home experience SHALL distinguish cached/offline, loading, empty, filtered, and local-action states without presenting mock data as provider-confirmed or permanently persisted data.

#### Scenario: Cached snapshot is displayed offline
- **WHEN** the local preview is available while network access is absent
- **THEN** the screen labels the content as local or cached context and keeps the available discovery sections usable

#### Scenario: A section has no matching content
- **WHEN** a selected format or discovery filter produces no local results
- **THEN** the affected section shows an actionable empty state while leaving the filter controls and other Home sections usable

#### Scenario: A local action changes presentation state
- **WHEN** the user joins an open game, sends a challenge, or triggers a refresh in the preview
- **THEN** the screen shows immediate local feedback and does not imply server persistence, payment completion, or provider confirmation

### Requirement: Preserve Home discovery interactions
The Home experience SHALL retain the existing navigation and discovery actions for format filtering, challenge details, open-game destinations, team management, notifications, and joining an available open-game slot.

#### Scenario: User filters open games by format
- **WHEN** the user selects a supported football format filter
- **THEN** only matching local open games are shown and the selected filter is exposed accessibly

#### Scenario: User opens a Home action
- **WHEN** the user activates a challenge, open-game, team, or notification action
- **THEN** the application navigates to the corresponding existing destination or shows the defined local feedback without changing route contracts

#### Scenario: User joins an available open game
- **WHEN** the user activates Join for an open game with available capacity
- **THEN** the action becomes locally represented as joined, the game remains visibly identified, and a confirmation message is shown

### Requirement: Keep Home preview accessible at supported widths
The Home experience SHALL expose meaningful semantics for identity, status, filters, cards, and actions, and SHALL maintain usable touch targets and readable content at the supported mobile preview widths.

#### Scenario: Assistive technology reads Home controls
- **WHEN** an accessibility tree is inspected on Home
- **THEN** filters, status indicators, cards, navigation actions, and buttons have meaningful labels and selected/enabled states that do not depend on color alone

#### Scenario: Home is previewed at narrow and standard widths
- **WHEN** Home is rendered at 360dp, 390dp, and 430dp widths
- **THEN** the feed remains legible and interactive with no overflow or unusable control caused by the mocked content
