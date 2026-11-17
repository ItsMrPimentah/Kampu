# Product Brief: Sports Community Platform

This document combines the descriptions in the Google Stitch [Sports Community Platform v0.3](https://stitch.withgoogle.com/projects/10729709610488881069) (`ecc7e6f2348342e8b47a215cfe92cf0c`) and Football Community v0.2 (`b79151405d9046439d5d98456952cf42`) briefs, updated with product-owner decisions. It describes product intent, not necessarily implemented behavior. Open decisions are collected at the end.

**Product:** ShowTime  
**Platforms:** iOS & Android (Flutter)  
**Stage:** MVP Definition  
**Initial Sport:** Football  
**Architecture:** Multi-Sport Ready  
**Business Model:** Freemium + Captain Pro + Advertising  

**Pilot:** Lisbon and Setúbal; Portuguese and English; no venue partnership is currently secured.  

---

## 1. Product Vision
Build a community-driven sports platform where anyone can discover players, create teams, organize matches, challenge opponents, and participate in local sporting activities.

The platform should remove the friction of organizing amateur sports by bringing players, captains, teams, matches, venues, and payments into one connected ecosystem.

### Core Value Proposition
**Find your squad. Challenge rivals. Play together.**  
Whether someone wants to join a match, build a competitive team, challenge local opponents, or simply play recreationally, the platform makes connecting and playing easier.

### Product Principles
- **Community First:** Relationships, teams, and participation are the foundation.
- **Sport-Agnostic:** Football launches first, but the platform supports multiple sports.
- **Play Locally:** Match people and activities based on geographical proximity.
- **Simple Organization:** Reduce the number of messages and tools required to organize games.
- **Trust & Fairness:** Encourage reliable attendance, transparent payments, and respectful behavior.
- **Accessible Participation:** Support recreational players, competitive groups, and younger athletes with appropriate protections.

---

## 2. Target Audience

### Individual Players
People looking for games, teammates, or opportunities to participate in local sports.  
*Needs:* Discover matches, join open games, find nearby teams, track participation, and build their sporting identity.

### Team Captains
Users responsible for creating teams, organizing rosters, coordinating matches, and challenging opponents.  
*Needs:* Roster management, availability, invitations, challenges, venue selection, and contribution tracking.

### Match Organizers
People who organize recurring or occasional games without necessarily operating a permanent team.  
*Needs:* Create events, manage participants, fill vacant spots, and coordinate costs.

### Sports Venues
Football pitches and, eventually, other sporting facilities interested in reaching local players and facilitating bookings.  
*Needs:* Venue discoverability, facility descriptions, availability management, and booking integrations.

---

## 3. Core Product Capabilities

### 3.1 Player Identity & Profiles
Every player has a personal sporting identity.

#### MVP Features
- Profile photo, display name, and location.
- Supported sports and preferred playing positions.
- Player availability and preferred playing area.
- Team memberships.
- Upcoming and historical matches.
- Basic participation statistics.
- A player view populated with the player's own data, past-game scores and granular performance statistics.
- Public player profiles during the pilot. Preferred formats and self-declared skill level are not displayed as profile details.

#### Match scores and player ratings
- Players can enter or update match scores; captains or organizers must confirm those entries.
- After each game, every participant can rate other participants' performances from **1 to 5** for each attribute. These ratings form the basis of player statistics: **Defense**, **Vision**, **Ball Control**, **Strength** and **Speed**. Velocity is omitted as redundant with Speed.
- Captains or organizers can confirm both match scores and player ratings, and can rate players themselves. Entries awaiting confirmation must be distinguishable from confirmed entries. Each profile statistic is the average of confirmed ratings for that attribute across past matches.

#### Match media and player gallery
- Images and videos can be uploaded only within temporary matches. Each player present in a match can find that match in their history via **Settings → Matches → Match <id> → List of media**.
- Match images and videos are available only to players who belong to that match, and those players can export them.
- Players can fully manage their own gallery, including editing and deleting their uploads. Match organizers act as administrators and can delete inappropriate match media. The gallery remains match-private even though player profiles are public during the pilot; match media is not published to a public profile.

#### Future Enhancements
- Player reputation and attendance reliability.
- Additional sport-specific performance statistics beyond the player-rated attributes above.
- Achievements, badges, and verified player profiles.
- Personalized sports recommendations.

---

### 3.2 Community & Team Management
Teams are persistent community entities with their own identity, ownership, membership, and sporting history.

#### MVP Features
- Create a team with name, emblem, description, and location.
- Assign a sport and preferred competition formats.
- Invite players through shareable invitation links.
- Request to join an existing team.
- Manage members and membership requests.
- Assign Captain and Co-Captain roles.
- Assign player positions.
- Create public or private teams.
- Display team roster and upcoming matches.
- Allow players to participate in multiple teams.

#### Team Roles
| Role | Responsibilities |
| :--- | :--- |
| **Captain** | Team administration, challenges, match coordination |
| **Co-Captain** | Delegated roster and match management |
| **Player** | Participation, availability, accepting invitations |

#### Sport-Specific Configuration
Each sport defines its own valid formats, positions, and match rules.  
Football initially supports 5v5, 7v7, and 11v11; 8v8 is planned for a later extension. Future sports can introduce their own configurations without requiring changes to the core team-management workflow.

---

### 3.3 Team vs Team Challenges
Teams can find opponents, negotiate match details, and confirm fixtures.

#### MVP Features
- Discover nearby teams.
- Filter opponents by sport, format, location, and approximate skill level.
- Send challenges to other teams.
- Propose a date, time, location, and playing format.
- Submit counteroffers.
- Accept or reject proposals.
- Notify both captains when negotiations change.
- Display confirmed challenges in each team's schedule.
- Allow authorized captains to cancel challenges with notifications.
- Allow captains to mark the field as **confirmed** or **in confirmation** without venue intervention in the challenge workflow.
- Open a vote to decide on another field when the field changes. Only captains manage the vote, and both teams' captains must agree on the replacement field. The deadline is 48 hours before the match starts; the outcome if agreement is not reached remains open.

#### Challenge Lifecycle
`open` → `negotiating` → `agreed` → `confirmed` → `completed`  
*Alternative terminal states:* `rejected`, `cancelled`, or `expired`.

- **Open:** Challenge created and awaiting response.
- **Negotiating:** Captains exchange proposals.
- **Agreed:** Both teams have agreed on the match details.
- **Confirmed:** All required confirmations have been completed.
- **Completed:** The match has taken place.

*Note:* An agreement between captains does not automatically imply that a venue is reserved or a payment has been completed. A challenge can be confirmed while its field is **in confirmation**. Captains can confirm the field themselves when no venue is involved. A captain's field confirmation is a captain-reported match status, distinct from a venue or booking provider's confirmation. The remaining conditions for the challenge's `confirmed` state are an open decision.

---

### 3.4 Open Games & Player Matchmaking
Users can organize matches without requiring a pre-existing team.

#### MVP Features
- Create a public or private open game.
- Specify sport, format, date, location, and skill preference.
- Define maximum participants and available positions.
- Discover games near the player.
- Offer two participation modes: **Open Game**, where eligible players can join freely while slots are available; and **Require Approval**, where players request to join and organizers approve or deny each request. Require Approval is the default for new games.
- Automatically update remaining slots.
- Join a waiting list when a game is full.
- Notify waiting players when a slot becomes available.
- Sort the waiting list by request timestamp, oldest first; the organizer may select any waiting player rather than being required to select the first.
- Allow organizers to manage attendance and remove participants.

#### Example: Football, 7v7, Saturday at 17:00
- Maximum participants: 14
- Confirmed participants: 11
- Remaining spots: 3
- Positions needed: 1 goalkeeper, 2 defenders
- Estimated contribution: €5 per player

The system should prevent duplicate participation and overbooking, including when multiple players request the final available spot simultaneously.

---

### 3.5 Sports Venue Discovery, Hybrid Booking & Smart Scheduler
Players and captains can discover suitable sports facilities and coordinate reservations. The smart scheduler supports location and format filtering, travel distance and slot availability, and distinguishes native booking from external provider links. The venue flow must be provider-agnostic to accommodate different integrations and future AI-assisted automation. Provider bookings await provider confirmation, including when an automated flow is used; captains can separately report the field as confirmed or in confirmation for their match. Specific scheduler recommendations and supported integrations remain open questions.

#### MVP Features
- Map and list-based venue discovery.
- Search by location, sport, date, and supported format.
- Venue details: address, facilities, pricing information, and booking method.
- Estimated travel distance.
- External booking links for third-party booking providers.
- Native reservation requests for integrated venues, when supported.
- Track venue confirmation separately from match confirmation.
- Abstract venue operations across providers, including `check_availability`, `book`, and `change_booking`, with additional operations determined by the workflow.

#### Hybrid Booking Model
- **Native Booking:** The platform manages supported booking requests and receives confirmation from the venue or integration.
- **External Booking:** The platform redirects the organizer to the venue's official booking service. The organizer can subsequently record the reservation details.

Availability should only be presented as verified when supported by a reliable venue integration. No pilot venue partnership is currently secured; do not assume PlayArena or another provider is available. Captain-reported field confirmation is not provider-verified booking confirmation.

#### Future Enhancements
- Live availability synchronization.
- AI-assisted venue booking automation, with provider confirmation still required.
- Calendar-based slot recommendations.
- Venue dashboards and partner management.
- Recurring team reservations.

---

### 3.6 Match Scheduling & Coordination
A unified match calendar enables players to manage their sports activities.

#### MVP Features
- Upcoming and past matches.
- Invitations and attendance responses.
- Automatic reminders.
- Time-zone-aware scheduling.
- Match details: location, format, participants, costs, and instructions.
- Detect overlapping confirmed matches.
- Allow cancellation and rescheduling.
- Notify affected participants when details change.
- Share match invitation links.

#### Notifications
- Team invitations.
- Challenge received or updated.
- Match confirmed, updated, or cancelled.
- Open-game participation accepted.
- Waiting-list spot available.
- Match reminders.
- Contribution status changes.

---

### 3.7 Captain Payments & Split Contributions
Financial coordination should be transparent and understandable for every participant.

#### Payment Modes
- **Captain Pays:** The Captain is responsible for the venue cost and can track contributions collected from participants.
- **Split Payment:** The total cost is allocated among participating players.

The captain guarantees the full venue cost, including when participant contributions remain unpaid.

#### Example
- Total venue cost: €70
- Confirmed players: 14
- Contribution per player: €5

#### MVP Features
- Define total match cost.
- Calculate equal contributions.
- Show the amount expected from each participant.
- Track pending, paid, and waived contributions.
- Provide payment summaries for organizers.
- Allow captains to record manual payments.
- Allow captains to confirm that they have received a player's payment.
- Allow players to indicate that they intend to pay cash at the field. An intention to pay is not confirmation that payment has been received.
- Update the breakdown when participation changes, subject to the agreed payment policy.

*For the initial MVP, contributions are coordinated manually by the captain; in-app match payments are not currently required. A captain's confirmation records their assertion that payment was received.*

Stripe is the initial payment gateway (GPO), for Captain Pro subscriptions during the pilot. In-app match payments are not currently required.

#### Future Enhancements
- In-app payment collection.
- Automated payouts.
- Refund processing.
- Payment-provider reconciliation.
- Secure deposits and cancellation policies.

Payment processing must be integrated with an appropriate provider rather than handled by storing payment-card information directly.

---

### 3.8 Community Discovery & Engagement
The platform should encourage ongoing participation beyond individual matches.

#### MVP Features
- Discover local teams.
- Explore public open games.
- Follow or bookmark preferred teams and activities.
- Share team profiles and match invitations.
- View team history and upcoming fixtures.

#### Future Enhancements
- Team rivalries.
- Community leagues and tournaments.
- Team rankings and seasonal leaderboards.
- Match results and score reporting.
- Team achievements and trophies.
- Local sports communities.
- Rich player and team activity feeds.

---

### 3.9 Monetization
A freemium approach should preserve accessibility while offering additional tools to active organizers.

Captain Pro subscriptions and advertising should be available during the pilot. Stripe is the initial subscription payment gateway.

#### Free Plan
- Player profiles.
- Team membership.
- Basic team creation and roster management.
- Open-game discovery and participation.
- Standard match coordination.
- Limited organizer capabilities where necessary.
- Subtle, non-intrusive advertising.

#### Captain Pro
- Advanced team-management capabilities.
- Extended organizer limits.
- Enhanced scheduling and roster insights.
- Advanced participation and contribution reporting.
- Additional team customization options.
- Reduced or removed advertising in eligible areas.

*Exact subscription prices, limits and entitlements should be validated.*

#### Advertising Principles
- Never interrupt an active booking or payment process.
- Avoid aggressive full-screen advertising.
- Clearly identify sponsored content.
- Do not use behavioral advertising targeted at minors.
- Prefer unobtrusive placements in discovery or community screens.

---

### 3.10 Trust, Safety & Age Protections
Trust is essential when connecting people for real-world physical activities.

#### MVP Requirements
- Age-aware registration and access controls.
- Account and team reporting.
- User blocking.
- Basic abuse-moderation workflows.
- Location privacy: avoid public exposure of precise home locations.
- Consent-based participation and invitation flows.
- Secure authentication and role-based authorization.
- Personal data deletion and privacy controls.
- Clear attendance and payment responsibilities.

The product-owner decision is a minimum age of **13**, with no guardian consent required for now and no additional age-specific restrictions on discovery, messaging or location visibility. The general privacy and safety features above remain part of the brief. Registration eligibility now uses 13+, but the current [`identity-and-safety` specification](../openspec/specs/identity-and-safety/spec.md) and other prototype services still contain the former youth-specific restrictions and need alignment.

---

## 4. Primary User Journeys

### Journey A — Find and Join a Match
1. Player creates an account and selects their sport.
2. Player sets location and preferred positions.
3. Player browses nearby open games.
4. Player reviews game details and available slots.
5. Player joins directly if the game is open and a slot is available, or requests to join if the game requires approval.
6. For approval-required games, the organizer approves or denies the request.
7. Player receives match reminders and participates.  
*Successful outcome:* A player discovers and joins a suitable local match without needing an existing team.

### Journey B — Build a Squad
1. Captain creates a team.
2. Captain selects the sport, format, and team identity.
3. Captain invites members.
4. Players accept invitations.
5. Captain assigns roles and preferred positions.
6. Team becomes available for match organization and challenges.  
*Successful outcome:* A team is ready to organize matches and engage with other teams.

### Journey C — Challenge Another Team
1. Captain searches for nearby opponents.
2. Captain sends a challenge with proposed match details.
3. Opposing captain accepts or submits a counteroffer.
4. Captains agree on format, date, location, and conditions.
5. Captains mark the field confirmed or in confirmation and coordinate the remaining logistics. A provider booking, if used, has its own confirmation status.
6. Both teams receive the confirmed match details.
7. Participants are notified and attendance is coordinated.  
*Successful outcome:* Two teams agree and successfully organize a match with minimal manual coordination.

### Journey D — Organize a Paid Match
1. Organizer creates a match with a venue cost.
2. Organizer selects Captain Pays or Split Payment.
3. Participants join and confirm attendance.
4. The system calculates expected contributions.
5. Payments are recorded and tracked.
6. Organizer verifies the financial status before the match.
7. The match takes place and the financial record is retained.  
*Successful outcome:* A match organizer can transparently coordinate costs and contributions.

---

## 5. Open product decisions

The following questions capture gaps in the briefs. Existing implementation and specifications are context, not answers assumed for this consolidated brief.

1. **MVP priorities:** Which capabilities in section 3 are essential for the first public release, and which should be deferred? Are other sports deferred beyond the initial football formats?
2. **Venue booking and smart scheduling:** What recommendations should the scheduler provide, and how should provider confirmation be received in automated and manual flows? Which additional provider-agnostic operations are needed?
3. **Field-change vote:** What happens if captains do not agree by the 48-hour deadline, or if a field change is needed after that deadline?
4. **Match confirmation:** Besides the captain-managed field status, what conditions move a challenge from `agreed` to `confirmed`?
5. **Payments:** How should fees, cancellations, refunds and late withdrawals affect the captain's guarantee and player contributions?
6. **Joining and waiting lists:** How long does a selected waiting player have to claim a vacant slot? Does selection from the waiting list count as approval in approval-required games?
7. **Monetization:** What are the proposed subscription price, free/paid limits, benefits and permitted ad placements for the pilot?
8. **Team access and communication:** What permissions distinguish captains, co-captains and organizers? Should match or team chat be included in the MVP, and if so who can participate and how long are messages retained?
9. **Success measures:** What launch targets should define success for participation, completed matches, venue bookings and retention?
10. **Player ratings:** Can players change their ratings after confirmation, and who can confirm ratings when a captain or organizer submitted them?
11. **Match media:** What upload limits, retention and moderation rules apply?
