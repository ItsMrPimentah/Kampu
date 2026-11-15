# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

- Amateur players looking for local games, teammates, or teams, whether recreational or competitive.
- Team captains and co-captains managing squads and arranging matches against other teams.
- Match organizers coordinating occasional or recurring games, participants, and costs.
- Sports venues seeking discovery and booking opportunities are a further audience in the product brief.

## Product Purpose

ShowTime helps people find their squad, challenge rivals, and play together. It reduces the friction of coordinating amateur sport by connecting players, teams, games, venues, and match costs. Football is the initial sport; the product is intended to support other sports later.

Successful journeys include joining a suitable local game without an existing team, building a squad, agreeing a match with another team, and transparently coordinating match contributions. Launch targets and success metrics remain open.

## Positioning

The product brings community discovery and practical match organization into one connected workflow: players can find games and teams, while organizers can coordinate rosters, challenges, venues, and costs. It is designed for local participation rather than only permanent teams or competitive play.

## Operating Context

- The planned pilot covers Lisbon and Setúbal in Portuguese and English.
- Football initially supports 5v5, 7v7, and 11v11. Other sports and 8v8 are future extensions.
- Players discover and join open games; approval-required games default to organizer approval. Captains manage teams and negotiate challenges with other teams.
- Captains can report a field as confirmed or in confirmation. This is distinct from a venue or booking provider confirming a reservation. Availability is verified only when supported by a reliable integration.
- For the initial MVP, match contributions are coordinated manually. A captain's confirmation records their assertion that payment was received; an intention to pay cash is not receipt of payment.
- The product brief says no pilot venue partnership is secured, while the repository README identifies PlayArena as an initial partner. The pilot partnership is undecided; do not assume provider availability.

## Capabilities and Constraints

- ShowTime is a Flutter app for both iOS and Android, using a shared cross-platform design. Use iOS as the primary platform guidance while supporting Android.
- The product brief describes intended capabilities, not a guarantee of implementation. MVP release priorities remain open.
- Registration has a minimum age of 13, and phone verification is required before entering the app. The brief specifies no guardian consent for now; existing youth-specific prototype restrictions still need alignment.
- Team and game invitations currently use shareable, seven-day codes entered in the app. Community notifications are stored in an in-app inbox; push delivery is not yet connected.
- Full geospatial discovery, match reminders, team emblem upload, attendance responses, and automated field-vote deadline outcomes remain follow-up work. Venue previews and other integrations have additional limitations documented in `IMPLEMENTATION_NOTES.md`.
- The brief calls for freemium access, Captain Pro, and advertising during the pilot. Subscription pricing, entitlements, and permitted ad placements are open decisions; Stripe is the initial subscription payment gateway.
- Do not represent captain-reported field status, proposed reservations, payment intentions, or pending match scores and ratings as independently confirmed facts.
- Mobile screens must use bundled presentation resources rather than runtime-hosted fonts, images, or icons.

## Brand Commitments

The product is named ShowTime. Its existing product proposition is “Find your squad. Challenge rivals. Play together.”

## Evidence on Hand

- `../../docs/product-brief.md` records product-owner decisions, intended workflows, and open questions.
- `IMPLEMENTATION_NOTES.md` records the present mobile implementation, deferred integrations, and screen references.
- `../../README.md` and `README.md` document development and current deployment constraints; the pilot venue-partner statement conflicts with the product brief as noted above.
- The product's Stitch project is `10729709610488881069`.

## Product Principles

- Put community, participation, and team relationships first.
- Make finding and organizing local games simpler for players and organizers.
- Support football first without precluding other sports.
- Make attendance, contributions, and confirmation statuses understandable and trustworthy.
- Support recreational and competitive participation while respecting privacy and safety.

## Accessibility & Inclusion

Support safe areas and text scaling, and layouts at 360–430 logical pixels. Label interactive icons, communicate status in text as well as color, and maintain contrast of at least 4.5:1 for normal text and 3:1 for large text, as specified in `FLUTTER_GUIDELINES.md`.
