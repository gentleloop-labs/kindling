# Kindling design tokens

Status: Phase 0 baseline, checked 2026-08-10 against WCAG 2.2 contrast thresholds.

The canonical machine-readable tokens live in `design/tokens.css`. The bright Ember, glow, and celebration colors are decorative. They must not be used for text, focus indicators, or essential UI boundaries in the light theme.

## Color tokens

| Role | Light | Dark | Use |
|---|---:|---:|---|
| Background | `#FAF6F1` | `#1C1815` | Page background |
| Surface | `#F1EAE1` | `#262019` | Cards and fields |
| Surface strong | `#E7DDD1` | `#332B23` | Subtle selected/hover surface |
| Primary text | `#2B2420` | `#F2EBE3` | Headings and body |
| Secondary text | `#6B5F55` | `#A69A8C` | Supporting copy |
| Interactive accent | `#A9471C` | `#F0824A` | Links, focus, controls |
| Accent ink | `#FFFFFF` | `#1C1815` | Text on accent fills |
| Ember | `#E8703A` | `#F0824A` | Decorative mascot fill only |
| Glow | `#F2A65C` | `#F5B563` | Decorative glow only |
| Celebration | `#E8B84B` | `#E8B84B` | Decorative bloom only |

The original light accent `#E8703A` has only 2.87:1 contrast on warm paper and 2.58:1 on the surface, so it fails both normal-text (4.5:1) and non-text/UI (3:1) requirements. `#A9471C` is the accessible light interactive accent; the original orange remains the Ember's decorative fill.

## Contrast results

Ratios use sRGB relative luminance. Body text must reach 4.5:1; large text and essential UI boundaries must reach 3:1.

| Foreground | Background | Ratio | Body | Large/UI |
|---|---|---:|:---:|:---:|
| Light primary `#2B2420` | Light background `#FAF6F1` | 14.18:1 | Pass | Pass |
| Light primary `#2B2420` | Light surface `#F1EAE1` | 12.79:1 | Pass | Pass |
| Light secondary `#6B5F55` | Light background `#FAF6F1` | 5.75:1 | Pass | Pass |
| Light secondary `#6B5F55` | Light surface `#F1EAE1` | 5.19:1 | Pass | Pass |
| Light accent `#A9471C` | Light background `#FAF6F1` | 5.41:1 | Pass | Pass |
| Light accent `#A9471C` | Light surface `#F1EAE1` | 4.88:1 | Pass | Pass |
| White `#FFFFFF` | Light accent `#A9471C` | 5.83:1 | Pass | Pass |
| Dark primary `#F2EBE3` | Dark background `#1C1815` | 14.92:1 | Pass | Pass |
| Dark primary `#F2EBE3` | Dark surface `#262019` | 13.64:1 | Pass | Pass |
| Dark secondary `#A69A8C` | Dark background `#1C1815` | 6.40:1 | Pass | Pass |
| Dark secondary `#A69A8C` | Dark surface `#262019` | 5.85:1 | Pass | Pass |
| Dark accent `#F0824A` | Dark background `#1C1815` | 6.72:1 | Pass | Pass |
| Dark accent `#F0824A` | Dark surface `#262019` | 6.14:1 | Pass | Pass |
| Dark background `#1C1815` | Dark accent `#F0824A` | 6.72:1 | Pass | Pass |

Decorative-only pairs are deliberately excluded from meaningful information: light glow on light background is 1.88:1, and light celebration gold on light background is 1.71:1. Any label placed near them still uses a passing text token.

## Layout, type, and motion

- Type: the platform system stack; rounded variants may be used where the platform supplies them.
- Spacing: 8pt base grid (`8`, `16`, `24`, `32`, `40`, `48`).
- Radius: one `18px`/`18pt` radius for fields, cards, and buttons.
- Tap target: minimum `48px`/`48pt` in both dimensions.
- Motion: soft `ease-in-out`, 220ms by default. Under reduced motion, movement and pulsing stop; state changes use an immediate opacity change.
- Focus: a visible two-layer outline using the interactive accent plus background separation. Glow alone is never the only focus indicator.
- Error treatment: primary text and an icon or explicit sentence, never red or color alone.

## Usage rules

1. There is no red state, including the timer's last seconds.
2. The three outcome actions use the same component, size, and emphasis.
3. Ember state always has a text equivalent for assistive technology.
4. Do not lower text opacity; use the tested secondary-text token.
5. Decorative glow may disappear entirely without changing the meaning of a screen.
