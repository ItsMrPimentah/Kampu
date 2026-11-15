# Pitch Pulse — mobile design system

Source: Google Stitch project `10729709610488881069`, **Amateur Football Community Platform**, project-level `designTheme.designMd` and theme tokens, retrieved 2026-11-14. This is a local transcription of the current project-level system, not a claim that every existing screen uses it. Flutter constants are in `lib/shared/ui/pitch_pulse_tokens.dart`.

## Applying the source

- The active application theme (`lib/shared/ui/midnight_theme.dart`) and the registration theme (`lib/shared/ui/registration_theme.dart`) currently implement an older purple **Midnight** screen style. Some Stitch screens also explicitly use Midnight SRE. The registration class name alone does not make its values the current Pitch Pulse system. Consult the specific Stitch screen as well as this project-level system when implementing or reviewing a screen.
- The project-level Material `primary` is `#6FFF9A`, while the custom `electric-lime` and `primary-container` are `#10E575`. The component guidance explicitly uses `#10E575` for primary actions. Do not silently substitute one for the other.
- The generated Material `background` and `surface` are `#101417`; the component guidance specifies `pitch-dark` `#070A0C` for the canvas and `#0B0F12` for recessed inputs. These are distinct roles.
- The source shape scale says `sm` is 4px; its format badge description calls `rounded-sm` 6px. Both values are preserved as separate scale and component tokens.
- Dimensions below use Flutter logical pixels; `1rem` in Stitch is interpreted as 16 logical pixels. Stitch's em tracking is converted to logical pixels in the Flutter text styles. The mobile app uses locally bundled Inter for all non-monospace typography.

## Brand and style

**Tactile Dark Athleticism**: deep stadium-midnight surfaces, tactical pitch greens, electric lime accents, structured data chips, strong typographic hierarchy and status beacons. The design is mobile-first for 360–430dp screens, with compact match organization and one-handed interactions. Avoid heavy generic shadows; use surface tiers and fine borders for depth.

## Colors

The complete generated Material palette and named colors are transcribed in `PitchPulseColors`. Important custom roles:

| Role                             | Value                             | Use                                          |
| -------------------------------- | --------------------------------- | -------------------------------------------- |
| Pitch dark                       | `#070A0C`                         | Canvas, primary-button text                  |
| Card                             | `#12181D`                         | Cards and lists                              |
| Elevated                         | `#1A232A`                         | Floating panels and sticky footers           |
| Subtle border                    | `#222E37`                         | Card, field and ghost-button borders         |
| Electric lime                    | `#10E575`                         | Primary actions, selections, confirmed state |
| Text primary / secondary / muted | `#F9FAFB` / `#94A3B8` / `#64748B` | Text hierarchy                               |
| Format background / text         | `#15241C` / `#34D399`             | Match-format badge                           |
| Payment background / text        | `#212015` / `#FACC15`             | Split-payment badge                          |

The project theme's seed overrides are primary `#10E575`, secondary `#10B981`, tertiary `#059669`, neutral `#0B0F12`. These are seed/override values, not the generated Material secondary and tertiary roles (`#4EDEA3` and `#86FAC5`).

### Challenge lifecycle

| State       | Text / beacon | Background in Stitch CSS `#RRGGBBAA` | Flutter `Color` `0xAARRGGBB` |
| ----------- | ------------- | ------------------------------------ | ---------------------------- |
| Open        | `#38BDF8`     | `#0284C71A`                          | `0x1A0284C7`                 |
| Negotiating | `#FBBF24`     | `#D977061A`                          | `0x1AD97706`                 |
| Agreed      | `#A78BFA`     | `#7C3AED1A`                          | `0x1A7C3AED`                 |
| Confirmed   | `#10E575`     | `#05966926`                          | `0x26059669`                 |

## Typography

Use Inter for display, headlines, labels and numeral badges; Inter for body and titles. Labels and tags are uppercase. Values are size / line height in logical pixels; tracking is the original em value.

| Token          | Font  | Weight | Size / line height | Tracking |
| -------------- | ----- | ------ | ------------------ | -------- |
| display-lg     | Inter | 700    | 36 / 44            | -0.03em  |
| display-mobile | Inter | 700    | 28 / 36            | -0.02em  |
| headline-lg    | Inter | 700    | 24 / 32            | -0.02em  |
| headline-md    | Inter | 600    | 20 / 28            | -0.01em  |
| headline-sm    | Inter | 600    | 18 / 24            | —        |
| title-md       | Inter | 600    | 16 / 22            | —        |
| body-lg        | Inter | 400    | 16 / 24            | —        |
| body-md        | Inter | 400    | 14 / 20            | —        |
| body-sm        | Inter | 400    | 12 / 16            | —        |
| label-lg       | Inter | 700    | 13 / 16            | 0.04em   |
| label-md       | Inter | 700    | 11 / 14            | 0.06em   |
| label-sm       | Inter | 600    | 10 / 12            | 0.08em   |
| numeral-badge  | Inter | 700    | 14 / 16            | —        |

## Layout, shape and depth

- Spacing: `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24; gutter 16, mobile gutter 12, margin and mobile margin 16. Use 12–16 for card padding and 24 between sections.
- Radius scale: `sm` 4, default 8, `md` 12, `lg` 16, `xl` 24, full 9999. Standard cards and modals use 16; micro surfaces use 6–8; buttons and lifecycle pills use full radius.
- Level 0 canvas: `#070A0C`; level 1 cards: `#12181D` with 1px `#222E37` border; level 2 floating sheets: `#1A232A` with 1px `#10E57526` border (CSS alpha; Flutter `0x2610E575`).
- Primary glow: offset `(0, 4)`, blur 16, `rgba(16, 229, 117, 0.20)`.

## Components

- **Primary button:** `#10E575` fill, `#070A0C` bold text, full pill, minimum height 48, subtle primary glow.
- **Secondary / ghost:** `#12181D` fill, 1px `#222E37` border, white text; pressed border `#10E575`. Destructive/dispute uses a dark wine container and crimson text; the source does not specify exact component colors.
- **Format:** `#15241C` background, `#34D399` bold Inter, 6px corners, e.g. `5V5`, `7V7`, `11V11`.
- **Booking:** native instant uses an electric-lime pill with dark icons/text; external uses `#1A232A`, `#94A3B8` text and a lightning/link icon.
- **Challenge status:** compact capsule with leading 6px pulsing beacon; use the lifecycle colors above. State must also be communicated in text.
- **Payment:** split-payment badge uses `#212015` and `#FACC15`, with a segmented paid-slots progress bar; captain-pays uses muted charcoal, a shield icon and `#F9FAFB` text. The source does not give a precise captain-pays background.
- **Match card:** card surface and 1px border; top row format, status and countdown; center teams or roster counts; bottom venue, booking type, per-person price and right-aligned action.
- **Inputs:** recessed `#0B0F12`, 1px `#222E37` border; focused border `#10E575` without blur. The source does not specify an input radius.

Use the named constants rather than introducing new hex values for these roles. Screen-specific variations should be traced to their Stitch screen rather than inferred from the project-level system.
