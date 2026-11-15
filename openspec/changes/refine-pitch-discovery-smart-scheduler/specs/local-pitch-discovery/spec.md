# Local pitch discovery

## Purpose

Enable users to explore a coherent pitch scheduler using deterministic local demo data and understand the limits of preview interactions.

## ADDED Requirements

### Requirement: Stitch-aligned pitch discovery
The pitches screen SHALL follow the Midnight Stitch reference's search, scheduler, venue feed and empty-state hierarchy while retaining the application's existing navigation shell and branding.

#### Scenario: Populated preview
- **WHEN** the user opens Pitches with matching demo venues
- **THEN** the screen presents local-preview status, search, date/format/surface controls, result count and venue cards with source, location, surface, fixture details and slot choices
- **AND** Pitches is identified as the active navigation destination

### Requirement: Deterministic preview fixtures
The screen SHALL use coherent, deterministic local fixtures with distinct dates, formats, surfaces, distances, native and external source types, and selectable and unavailable slot states.

#### Scenario: Fixture content and dates
- **WHEN** the preview loads repeatedly
- **THEN** venue and slot identifiers, displayed dates, weekdays, times, prices and source labels agree with the fixture values
- **AND** the fixture set supports populated, filtered and empty results without relying on the current clock or network

### Requirement: Combined discovery filters
The user SHALL be able to filter fixture results by case-insensitive search, full date, format, surface and maximum distance, with active filters applied together and an available way to clear each filter.

#### Scenario: Search and filter intersection
- **WHEN** the user enters venue or address text and selects date, format, surface or distance filters
- **THEN** only venues satisfying all active venue filters and having a slot on the selected date are shown
- **AND** only slots on that date are shown for each matching venue

#### Scenario: Clearing and result count
- **WHEN** a filter or the search text is cleared
- **THEN** the result set is recomputed using the remaining criteria and the displayed venue count equals the visible venue count

#### Scenario: Date identity
- **WHEN** fixture slots fall on the same day of different months or years
- **THEN** selecting one date does not match slots on the other date

### Requirement: Scheduler slot selection and cost
The user SHALL be able to select eligible local slots and see the selected slot's time and price accurately reflected in the card's action and any displayed cost estimate.

#### Scenario: Change selection
- **WHEN** the user selects another eligible slot
- **THEN** the selected styling, accessible selection state, displayed total and any per-player estimate reflect that slot and its fixture price

#### Scenario: Stale or unavailable selection
- **WHEN** filtering removes the selected slot, or a slot is unavailable
- **THEN** the removed or unavailable slot cannot be reserved as the current selection

### Requirement: Local-only reservation and provider actions
Native demo reservation actions SHALL update only eligible local preview state; external demo actions SHALL provide truthful feedback without claiming to open a provider or confirm a booking.

#### Scenario: Reserve native demo slot
- **WHEN** the user reserves an eligible native fixture slot
- **THEN** the slot displays local-only confirmation and feedback identifies it as a demo action
- **AND** no provider hold or durable reservation is claimed or created

#### Scenario: External fixture action
- **WHEN** the user invokes the external fixture action
- **THEN** the screen explains that provider access is not connected and does not change the slot to locally confirmed

#### Scenario: Preview state ends
- **WHEN** the preview session is disposed and reopened
- **THEN** session-only reservations are not presented as durable or provider-confirmed bookings

### Requirement: Honest preview status and local actions
The screen SHALL identify its data and actions as a local demo and SHALL not represent fixtures as live, verified, recently synchronized, held, booked by a provider or backed by real notification delivery.

#### Scenario: Retry preview
- **WHEN** the user invokes retry
- **THEN** feedback states that local preview data was retained or reloaded without claiming a network sync

#### Scenario: Request a demo alert
- **WHEN** the user invokes the empty-state notification action
- **THEN** its session-only acknowledgement states that no real alert is registered or delivered

### Requirement: Actionable empty results
The screen SHALL explain when no fixture venues match the active filters and offer relevant actions to change the criteria.

#### Scenario: No matching fixtures
- **WHEN** combined search and filters yield no matching venues
- **THEN** the screen shows a zero count, a local-demo empty message and an accessible way to clear or adjust filters

#### Scenario: Alternative fixture date
- **WHEN** the screen offers an alternative date and the user selects it
- **THEN** the selected date and results update using the same combined filters rather than merely hiding the empty state

### Requirement: Responsive and accessible scheduler
The pitches screen SHALL support safe areas, accessible controls and text scaling, and usable layouts from 360 to 430 logical pixels wide.

#### Scenario: Large text and narrow screens
- **WHEN** the screen is rendered at 360, 390 and 430 logical pixels and at enlarged text scale
- **THEN** controls and content remain reachable without clipping or overflow and the bottom navigation does not obscure the last result

#### Scenario: Assistive technology
- **WHEN** a user navigates scheduler controls using accessibility semantics
- **THEN** icon-only actions have meaningful labels, selected filters and slots expose their state, and statuses are conveyed in text as well as color
- **AND** normal text has at least 4.5:1 contrast and large text at least 3:1
