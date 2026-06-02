---
name: lyre-and-liar-design
description: Use this skill to generate well-branded interfaces and assets for Lyre & Liar (a 2D multiplayer platformer with a hidden imposter, originally "Project Werewolf"), either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.
If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.
If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

## Quick orientation

- **Lyre & Liar** is a cozy-pixel 2D multiplayer platformer with a hidden imposter mechanic. The brand voice is **sparse, theatrical, slightly menacing** ("Whisper me a betrayal"). All caps for titles and buttons, sentence case for taglines, lowercase for status text. Second person only.
- **Base viewport is 360×640 portrait** — mobile is the design canvas. Scale clamped 0.7×–2.5× via ResponsiveUI.
- **Color foundation**: shell-void (`#080F08`), brass-rule (`#C78D2E`), parchment (`#F2E5D9`) text. Title carries a brass-deep (`#522E0F`) drop shadow.
- **Map mood colors**: Day = sun gold `#FFBF33`, Night = moon blue `#99BFFF`, Forest = green `#33CC66`.
- **State colors**: died `#FF3333`, timeout `#FF9933`, complete `#99FF66`, paused `#FFD94D`, timer `#FFE666`, mode `#8CC773`, status `#8CD98C`, version `#59874D`.
- **Type**: Cinzel (display), Jersey 25 (UI), VT323 (mono), Inter (body). *Substituted* — Godot ships engine default; flag if pixel-perfect parity is required.
- **No real logo yet** — the shipped icon is Godot's default. Flag and ask before designing around it.
- **No icon system** — Lucide CDN is the documented stand-in.
- **Square corners everywhere** except mobile controls (full pill).
- **Hard cuts, no animations.** Hover = +15% brightness, press = -15% + 1px down.

## Files in this skill

| Path | What it has |
| --- | --- |
| `README.md` | Full content + visual foundations, voice rules, iconography notes, copy examples. |
| `colors_and_type.css` | All design tokens as CSS custom properties + utility classes. Drop into any HTML page. |
| `preview/*.html` | Small card-sized examples of every token / component / brand asset. |
| `ui_kits/game/` | Hi-fi React click-through of the game UI: main menu, map select, multiplayer flow, in-game HUD, four overlay states. |
| `assets/sprites/` | Player + monster + enemy + pickup PNGs (pixel art, render with `image-rendering: pixelated`). |
| `assets/tilesets/`, `assets/backgrounds/` | Cave, grass, forest world art. |
| `assets/logo/godot-icon.svg` | Placeholder. Flag before reusing as a logo. |

## When prototyping

- Always start from `colors_and_type.css`. Use the CSS variables — do not hand-pick hex codes.
- For game-feeling surfaces, default to the 360×640 portrait shell and a centered VBox stack with 18 px gaps and 280×56 buttons.
- For overlays, use the 240×50 button size and 16 px gaps.
- Render sprite PNGs with `image-rendering: pixelated; image-rendering: crisp-edges;`.
- Match the engine's hard-cut motion language — no fades, no slides, no bouncing.
- If you need an icon, link Lucide from CDN and document the substitution in a comment.

## When generating new copy

- Titles & buttons: ALL CAPS.
- Taglines & placeholders: sentence case.
- Status text: lowercase, ends with `...` if pending.
- Second person, command voice. No "we." No emoji in player-facing UI.
- Keep one-liners *short and slightly ominous* — the game is about betrayal.
