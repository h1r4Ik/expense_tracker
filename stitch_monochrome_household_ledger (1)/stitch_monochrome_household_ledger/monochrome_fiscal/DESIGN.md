---
name: Monochrome Fiscal
colors:
  surface: '#faf9f9'
  surface-dim: '#dadada'
  surface-bright: '#faf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f3'
  surface-container: '#eeeeed'
  surface-container-high: '#e9e8e8'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#4c4546'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f0f0'
  outline: '#7e7576'
  outline-variant: '#cfc4c5'
  surface-tint: '#5e5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1b1b1b'
  on-primary-container: '#848484'
  inverse-primary: '#c6c6c6'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e1dfdf'
  on-secondary-container: '#626262'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1a1c1c'
  on-tertiary-container: '#838484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474747'
  secondary-fixed: '#e4e2e2'
  secondary-fixed-dim: '#c7c6c6'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#464747'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#faf9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e3e2e2'
typography:
  display:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-caps:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  container-max: 1200px
  gutter: 24px
---

## Brand & Style

The design system is rooted in **Minimalism** with a focus on absolute clarity and executive precision. Designed for a household expense tracker, the personality is disciplined, quiet, and highly functional. It avoids the "gamification" of finance in favor of a utilitarian aesthetic that treats personal data with the respect of a high-end ledger.

The visual language utilizes heavy whitespace to reduce cognitive load when viewing complex financial tables and charts. By removing color as a decorative element, we use contrast, scale, and density to guide the user's eye. The emotional response is one of control and calm—turning the often stressful task of expense tracking into a focused, architectural experience.

## Colors

This design system employs a strict monochrome palette to ensure that the user's financial data remains the sole focus. 

- **Primary (#000000):** Used for headlines, primary actions, and critical data points. It represents the "bottom line."
- **Secondary (#666666):** Used for body text, secondary icons, and labels that require legibility without high visual weight.
- **Tertiary (#F5F5F5):** Used for large structural surfaces, subtle fills, and hover states.
- **Neutral (#A0A0A0):** Used for borders, disabled states, and placeholder text.

Success and error states are communicated through iconography and weight rather than green or red hues, maintaining the system's tonal integrity. For example, a negative balance is indicated by a "minus" glyph and bold weight.

## Typography

The typography strategy differentiates between "Reading" and "Calculating." 

- **Hanken Grotesk** provides a contemporary, sharp sans-serif feel for general UI and storytelling.
- **JetBrains Mono** is used for all numerical data, currency values, and timestamps. Its monospaced nature ensures that columns of numbers align perfectly for easy vertical scanning.

**Hierarchy Rules:**
- Use `display` only for total balance overviews.
- Use `label-caps` (all caps) for category headers to create a structural break in long lists.
- Use `label-mono` for all monetary values to emphasize the "data" aspect of the app.

## Layout & Spacing

The layout is governed by a **12-column fixed grid** on desktop, transitioning to a **fluid single column** on mobile. The system uses a strict 4px baseline rhythm.

- **Margins:** 24px on mobile, 48px on tablet, and auto-centered on desktop with a 1200px max-width.
- **Scanning:** Expense lists should use `md` (16px) vertical padding to maintain a high information density while preventing visual clutter.
- **Whitespace:** Use `xl` (48px) spacing between major sections (e.g., separating the Monthly Summary from the Transaction History) to provide breathing room.

## Elevation & Depth

To maintain the monochrome aesthetic, the design system avoids heavy shadows. Instead, it uses **Low-contrast outlines** and **Tonal layers**.

- **Level 0 (Base):** #FFFFFF background.
- **Level 1 (Cards/Containers):** A 1px border of #F0F0F0 or a solid fill of #F5F5F5.
- **Level 2 (Interactive/Floating):** Use a very subtle, sharp shadow (0px 4px 12px rgba(0,0,0,0.05)) only for elements that sit above the main scroll, such as "Add Expense" modals.
- **Savings Goal Distinction:** To make the Savings Goal feature stand out, use a "Inverted" depth model: a solid #000000 background with white text, or a thick 2px black border to anchor it as a priority.

## Shapes

The shape language is **Sharp (0)**. 

Every UI element—from buttons and input fields to progress bars—features 90-degree corners. This evokes a sense of architectural stability and mathematical precision. Circular elements are strictly reserved for progress "donuts" or user avatars to create a deliberate visual break from the otherwise rigid grid.

- **Progress Bars:** These are flat rectangles. In the "Savings Goal" section, the progress is shown as a solid black fill moving through a light gray container.

## Components

- **Buttons:** 
  - Primary: Solid #000000 background, white text, no radius.
  - Secondary: 1px #000000 border, transparent background.
- **Input Fields:** A simple bottom-border of 1px #A0A0A0. On focus, the border becomes 2px #000000.
- **Chips:** Small, rectangular tags with a #F5F5F5 fill and `label-caps` typography. Use these for expense categories (e.g., HOUSING, FOOD).
- **Transaction Lists:** Use a clean, border-bottom separator of 1px #F0F0F0. The amount should be on the far right in `label-mono`.
- **Savings Progress:** A thick, horizontal bar. Use a "hatching" pattern (diagonal lines) to represent the "projected" growth vs. "actual" growth, maintaining the monochrome theme.
- **Icons:** Use 1px thin-line icons. Avoid filled icons unless it is the active state in the navigation bar.
- **Data Visualization:** Use different patterns (dots, stripes, solids) instead of colors to differentiate segments in pie charts or line graphs.