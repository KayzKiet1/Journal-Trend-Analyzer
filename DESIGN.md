# DESIGN.md - Journal Trend Analyzer

## System: Heritage (Architectural Minimalism)

This document defines the visual identity and design tokens for the Journal Trend Analyzer, following the Heritage design system.

### 1. Colors (Tokens)
- **primary**: `#1A1C1E` (Deep Ink) - Used for headlines, core body text, and primary icons.
- **secondary**: `#6C7278` (Sophisticated Slate) - Used for borders, captions, and secondary metadata.
- **accent**: `#B8422E` (Boston Clay) - Reserved strictly for primary CTAs, active states, and data visualizations.
- **neutral**: `#F7F5F2` (Warm Limestone) - The main application background.
- **surface**: `#FFFFFF` (Paper White) - Used for cards, modal sheets, and input fields.

### 2. Typography
- **h1**: `Public Sans`, 24px, Bold. Used for main screen titles.
- **h2**: `Public Sans`, 18px, Semi-Bold. Used for section headers and card titles.
- **body-lg**: `Public Sans`, 16px, Regular. Used for primary reading content (e.g., abstracts).
- **label-caps**: `Space Grotesk`, 12px, Bold, Uppercase. Used for metadata, tags, and small labels. Letter spacing: 0.5.

### 3. Layout & Geometry
- **radius-sm**: 4px. Used for small components like chips or tags.
- **radius-md**: 8px. Standard radius for cards, buttons, and input fields.
- **border-width**: 1px. Standard thickness for all Level 1 surfaces.
- **max-content-width**: 900px. The maximum width for content on large screens to maintain "Journalistic Gravitas".

### 4. Design Principles
- **Architectural Depth**: Use 1px borders (`secondary`) instead of elevation shadows for all cards and containers.
- **Editorial Focus**: Prioritize whitespace and typography over decorative elements.
- **Responsive Constraints**: On desktop/web, content must remain centered and constrained to `max-content-width` to ensure readability and a premium broadsheet feel.
- **Contrast**: Maintain high contrast (Deep Ink on Warm Limestone) to ensure accessibility and professional gravitas.
