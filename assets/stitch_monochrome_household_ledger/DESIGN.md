---
name: Monochrome Soft-Tactile
colors:
  surface: '#faf9f9'
  surface-dim: '#dadada'
  surface-bright: '#faf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f3'
  surface-container: '#eeeeee'
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
  tertiary-container: '#1b1b1b'
  on-tertiary-container: '#848484'
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
  tertiary-fixed-dim: '#c6c6c6'
  on-tertiary-fixed: '#1b1b1b'
  on-tertiary-fixed-variant: '#474747'
  background: '#faf9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e3e2e2'
  surface-light: '#FFFFFF'
  surface-shadow: '#D1D1D1'
  surface-bg: '#F0F0F0'
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
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: Hanken Grotesk
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 12px
  lg: 20px
  xl: 32px
  gutter: 16px
  grid-gap: 8px
---

## Brand & Style

The design system evolves into a **Soft Neomorphic** aesthetic while retaining its disciplined, monochrome roots. It targets a sophisticated audience that values precision but prefers a more approachable, tactile interface. The personality is "Quietly Premium"—moving away from rigid architectural sharp edges toward a sculpted, physical feel.

The design evokes a sense of calm and order. By utilizing soft shadows and highlights instead of high-contrast borders, the UI feels like a single, cohesive surface where elements are molded rather than placed. This "tactile minimalism" reduces visual noise, making the dense grid of icons feel organized and integrated rather than cluttered.

## Colors

The palette is strictly achromatic, relying on the interplay of light and shadow rather than hue.

- **Primary (#000000):** Reserved for high-contrast text and essential focal points.
- **Secondary (#626262):** Used for supporting text and iconography where full black would be too aggressive.
- **Neutral / Background (#F4F3F3):** The base canvas for the neomorphic effect. It is a warm, near-white that allows both white highlights and soft gray shadows to be visible.

Neomorphic depth is achieved using two specific tones:
1. **Highlight:** `#FFFFFF` (Top-left light source).
2. **Shadow:** `#D1D1D1` (Bottom-right occlusion).

## Typography

Typography is optimized for a dense grid environment. **Hanken Grotesk** serves as the primary typeface for its modern, clean proportions. **JetBrains Mono** is utilized for all quantitative data, ensuring that numerical values remain legible and perfectly aligned within small components.

To support the dense information architecture, label sizes have been slightly reduced and letter-spacing increased to maintain clarity even when components are tightly packed. Use `label-mono` for any icon-adjacent metadata to emphasize the data-driven nature of the interface.

## Layout & Spacing

This design system utilizes a **Fluid Grid** with a high-density spacing rhythm. To accommodate a dense grid of icons, the primary gutter is reduced to 16px, and the internal grid-gap for icon clusters is set to 8px.

The layout adapts from a **12-column desktop grid** to a **2-column icon grid on mobile** for data entry screens. Vertical padding in lists is tightened (using `md` - 12px) to maximize information visibility without sacrificing the neomorphic breathing room required for shadows to "bloom."

## Elevation & Depth

Hierarchy is established through **extrusion and indentation** rather than traditional elevation.

- **Extruded (Raised):** Used for interactive buttons and cards. Created using a dual shadow: `-4px -4px 10px #FFFFFF` (top-left) and `4px 4px 10px #D1D1D1` (bottom-right).
- **Inverted (Sunken):** Used for input fields, search bars, and active states. Created with an inner shadow: `inset -2px -2px 5px #FFFFFF` and `inset 2px 2px 5px #D1D1D1`.
- **Flat (Base):** The #F4F3F3 background. Elements that are not interactive or secondary information should remain flush with this surface.

## Shapes

The shape language is **Rounded (2)**. 

To achieve the "soft" neomorphic look, all primary components use an **8px (0.5rem)** radius. This corner treatment allows the neomorphic shadows to wrap smoothly around the edges, creating the illusion of a molded plastic or soft-touch surface. Large containers and dashboard cards scale up to **16px (1rem)** to emphasize their structural importance. 

Icons within the dense grid should be housed in 8px rounded containers to maintain a consistent silhouette across the board.

## Components

- **Buttons:** Neomorphic "extruded" surfaces. The primary action button uses a slightly more pronounced shadow depth. On "press," the button transitions to an "inverted" sunken state.
- **Icon Grid:** Each icon sits inside a 40x40px or 48x48px container with an 8px radius. Use "extruded" for selectable icons and "flat" for static ones.
- **Input Fields:** These are strictly "inverted" (sunken) rectangles. The text is vertically centered using `body-md`.
- **Chips:** Small 8px rounded pill shapes. Unlike cards, these use a simple low-contrast outline (#D1D1D1) to keep them from competing with the primary neomorphic elements.
- **Cards:** 16px rounded corners with soft neomorphic shadows. Avoid borders entirely; let the shadow define the edge.
- **Progress Bars:** An inverted "trough" with an extruded "fill" bar. For the "Savings Goal," use a solid black fill to provide a strong visual anchor against the soft gray background.
- **Lists:** Instead of line separators, use subtle changes in surface height or simply `md` spacing to group items.