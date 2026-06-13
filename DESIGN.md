# Heritage Design System for Journal Trend Analyzer

This design system follows the **Heritage** specification from Google Labs. It is designed for high-end academic and research applications, combining architectural minimalism with journalistic gravitas.

## 1. Overview
The Heritage system evokes a premium matte finish, similar to a high-end broadsheet newspaper or a contemporary art gallery. It uses high-contrast neutrals and a single purposeful accent color to maintain focus on complex research data.

## 2. Colors
Our palette is rooted in high-contrast neutrals with one distinct accent for interaction.

### Core Palette
| Token | Hex | Name | Usage |
| :--- | :--- | :--- | :--- |
| `primary` | `#1A1C1E` | Deep Ink | Headlines, core body text, icons |
| `secondary` | `#6C7278` | Sophisticated Slate | Borders, captions, meta-data |
| `accent` | `#B8422E` | Boston Clay | Primary CTAs, active states, chart lines |
| `neutral` | `#F7F5F2` | Warm Limestone | Main application background |
| `surface` | `#FFFFFF` | Paper White | Cards, modal sheets, input fields |

## 3. Typography
We use two distinct typefaces to balance readability and modern character.

- **Main Font:** `Public Sans` (Used for reading and headers)
- **Label Font:** `Space Grotesk` (Used for metadata and technical labels)

### Type Scale
| Style | Font | Size | Weight | Color |
| :--- | :--- | :--- | :--- | :--- |
| **H1** | Public Sans | 24px | Bold | `primary` |
| **H2** | Public Sans | 18px | Semi-Bold | `primary` |
| **Body Large** | Public Sans | 16px | Regular | `primary` |
| **Body Small** | Public Sans | 14px | Regular | `secondary` |
| **Label Caps** | Space Grotesk | 12px | Bold | `secondary` |

## 4. Layout & Spacing
A strict 8px grid system ensures architectural alignment.

- **Base Unit:** 8px
- **Page Padding:** 16px (2 units)
- **Component Gap:** 8px (sm) or 16px (md)

## 5. Elevation & Depth
Heritage avoids heavy drop shadows, opting for subtle layering.

- **Level 0:** `neutral` background.
- **Level 1:** `surface` cards with 1px `secondary` border.
- **Level 2:** Subtlest soft shadow (blur: 4px, opacity: 5%) for active modals.

## 6. Shapes
Corner radii are strictly controlled to maintain a "journalistic" feel.

- **Radius md:** `8px` (Standard for cards, buttons, and inputs)
- **Radius sm:** `4px` (Small tags or chips)

## 7. Components
Specific guidelines for core interaction elements.

### Primary Button
- **Background:** `accent` (#B8422E)
- **Text:** `neutral` (#F7F5F2)
- **Corner Radius:** `8px`

### Research Cards
- **Background:** `surface` (#FFFFFF)
- **Border:** 1px `secondary` (#6C7278)
- **Padding:** 16px

## 8. Do's and Don'ts
- **Do:** Keep the layout spacious and clean.
- **Do:** Use `accent` only for interactive elements.
- **Don't:** Use vibrant blues, greens, or standard "app" colors.
- **Don't:** Use pure black (#000000); always use `primary` (Deep Ink).

