---
system: Research Analytics
product: Journal Trend Analyzer
version: 1.1
audience: researchers, students, academic analysts
principles:
  - editorial clarity
  - research-first workflows
  - restrained data density
  - responsive mobile readability
colors:
  primary:
    value: "#14213D"
    role: headlines, body text, primary icons
  secondary:
    value: "#64748B"
    role: borders, captions, metadata
  accent:
    value: "#0F766E"
    role: primary actions, active states, chart emphasis
  background:
    value: "#F5F8FA"
    role: app background
  surface:
    value: "#FFFFFF"
    role: cards, inputs, modal surfaces
  success:
    value: "#15803D"
    role: positive states
  warning:
    value: "#B45309"
    role: warning states
  error:
    value: "#991B1B"
    role: destructive or failed states
typography:
  h1:
    family: Public Sans
    size: 24
    weight: 700
    color: primary
  h2:
    family: Public Sans
    size: 18
    weight: 600
    color: primary
  bodyLarge:
    family: Public Sans
    size: 16
    weight: 400
    color: primary
  bodySmall:
    family: Public Sans
    size: 14
    weight: 400
    color: secondary
  labelCaps:
    family: Space Grotesk
    size: 12
    weight: 700
    color: secondary
    letterSpacing: 0
spacing:
  xs: 4
  sm: 8
  md: 16
  lg: 24
  xl: 32
radii:
  sm: 4
  md: 8
layout:
  maxContentWidth: 900
  pagePadding: 16
  gridBase: 8
components:
  appBar:
    background: background
    foreground: primary
    elevation: 0
    alignment: center
  card:
    background: surface
    borderColor: secondary
    borderWidth: 1
    radius: md
    elevation: 0
  buttonPrimary:
    background: accent
    foreground: background
    radius: md
  input:
    background: surface
    borderColor: secondary
    focusedBorderColor: accent
    radius: md
  chart:
    primarySeries: accent
    neutralAxis: secondary
---

# Journal Trend Analyzer Design System

## Overview

Journal Trend Analyzer uses the Research Analytics design system: a quiet, data-first interface for academic journal discovery and trend analysis. The product should feel like a focused research workspace rather than a marketing page. The first priority is helping users compare journals, inspect publication trends, and return to saved research sources without visual noise.

## Colors

The palette is intentionally restrained and tuned for academic data work. Scholar Ink (`#14213D`) carries primary reading content. Data Slate (`#64748B`) supports metadata, borders, and low-priority text. Citation Teal (`#0F766E`) is reserved for decisive actions, active states, and chart emphasis. Lab Mist (`#F5F8FA`) keeps the app background clean and analytical, while Paper White (`#FFFFFF`) frames cards and controls.

Avoid adding broad gradients, decorative color fields, or extra accent colors unless they encode a real data state. Charts may use additional colors only when multiple series need clear separation.

## Typography

Use Public Sans for research content and Space Grotesk for compact labels. Headings should be compact and readable on mobile. Long journal names must truncate or wrap cleanly, never overflow their container. Label text should stay small and scannable.

## Layout

Content should remain centered and constrained on desktop, with a maximum width of 900px for primary analysis views. Mobile layouts must stack controls vertically when horizontal space is limited. Journal cards, compare controls, and filter bars should use responsive wrapping instead of shrinking text below readable sizes.

Use the 8px spacing system consistently:

- `xs`: 4px
- `sm`: 8px
- `md`: 16px
- `lg`: 24px
- `xl`: 32px

## Shapes

Use 4px radius for small tags and chips. Use 8px radius for cards, buttons, inputs, and analysis panels. Cards should use a 1px border instead of heavy shadows. Nested cards should be avoided.

## Components

Primary buttons use Citation Teal with inverted text. Icon buttons should use familiar Material icons for actions like search, favorite, compare, and navigation. Cards should show the most important research signal first: journal name, publisher or type, citation metadata, and actions.

Analysis components should be direct and data-first:

- Publication trend: line chart
- Citation trend: line chart
- Topic evolution: area or multi-series trend chart
- Author impact: horizontal bar chart
- Author-topic matrix: heatmap
- Journal compare: side-by-side metrics and trend charts

## Do's

- Keep research workflows available from the first screen.
- Preserve bottom navigation when moving between Home, Journal, Keywords, and Profile.
- Cache or persist local UI state when it prevents unnecessary OpenAlex calls.
- Prefer responsive wrapping for dense controls on mobile.
- Use borders and spacing to separate information instead of decorative effects.

## Don'ts

- Do not add landing-page hero sections to the app shell.
- Do not use large decorative gradients or unrelated illustrations.
- Do not let journal names, buttons, or metric badges overflow on mobile.
- Do not place cards inside cards unless the inner element is a repeated item or modal.
- Do not use accent color for low-priority metadata.
