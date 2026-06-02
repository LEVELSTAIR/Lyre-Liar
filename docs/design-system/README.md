# Lyre & Liar — Design System

> *"Whisper me a betrayal."*

A pixel-art, mobile-first, **2D multiplayer platformer with a hidden imposter**.
Up to 16 players drop into the same hand-built level, dodge enemies and traps —
and try to figure out which of them is silently triggering the deathtraps.

This folder is the **design system** for that game: tokens, type, assets, and a
hi-fi recreation of the in-game UI in HTML/React. Use it to prototype new
screens, marketing pages, store assets, or in-game flows without reaching for
Godot.

---

## What's in this project

- **`README.md`** — you are here. The full brand brief.
- **`colors_and_type.css`** — every color and type token, mirrored 1:1 from the Godot scene files.
- **`SKILL.md`** — agent-ready summary for Claude Code.
- **`assets/`** — sprites, tilesets, backgrounds, the icon. All raw PNGs lifted from the codebase.
  - `logo/` — current placeholder Godot icon (the project has no proper logo yet).
  - `sprites/` — player + monster + enemy + pickup sprites.
  - `tilesets/` — cave + grass + procedural tile textures.
  - `backgrounds/` — parallax layers for the Night (cave) and Day (grass) maps.
- **`preview/`** — small HTML cards that populate the Design System tab.
- **`ui_kits/game/`** — full hi-fi recreation of the main menu, mobile HUD, and overlay menus as React JSX, with a click-through `index.html`.

## Sources

- **Codebase**: the user-attached `lyre-liar/` Godot project (Godot 4.6, mobile preset). Mounted via File System Access — local-only.
- **Origin**: this project is the official continuation of *Project Werewolf*, originally maintained by [LEVELSTAIR](https://github.com/LEVELSTAIR/project-werewolf).
- **No Figma file was provided.** All visuals were extracted directly from `.tscn` scene files (Godot uses INI-style declarations with literal `Color(r,g,b,a)` values — the colors below are exact reproductions, not interpretations).
- **No logo, brand book, or marketing site exists yet.** Identity is implied by the menu's typographic treatment ("LYRE & LIAR" with brass rules + cream parchment text + a brass-deep drop shadow) and by the cozy-pixel sprite world.

---

## Product context

There is **one product** today: the game client. It ships as a single Godot binary that runs on **PC (keyboard)** and **Android (touch joystick + jump button)** off the same build, joining the same Colyseus room. There's no marketing site, store page, or companion app yet.

Flow:

1. **Main Menu** → pick Single Player or Multiplayer.
2. **Map Select** → DAY (sunny outdoor), NIGHT (underground cave), or FOREST (tall vertical).
3. **Multiplayer**: enter server IP + a 4-char room code, host or join.
4. **In-game**: platforming HUD (countdown timer in single-player, mobile controls on touch), pause button top-left.
5. **End states**: PAUSED · YOU DIED · TOO LATE · LEVEL COMPLETE.

---

## CONTENT FUNDAMENTALS

### Voice
**Sparse, theatrical, and slightly menacing.** The brand voice lives in tiny, scene-setting one-liners — not paragraphs. The subtitle *"Whisper me a betrayal"* is the prototype: 4 words, command form, the betrayal is the product. Pair this with utility text that's flatly functional ("Room: ABCD · Your IP: 192.168.1.10 · Waiting for players...") and the whole tone falls into place.

### Casing
- **ALL CAPS** for screen titles, button labels, and state callouts (`LYRE & LIAR`, `SINGLE PLAYER`, `YOU DIED`, `LEVEL COMPLETE`, `TOO LATE`, `PAUSED`, `SELECT MAP`).
- **Sentence case** for taglines, tooltips, and placeholders (`Whisper me a betrayal`, `Enter room code`, `e.g. 192.168.1.10`).
- **lowercase** for ambient status text (`Hosting game...`, `Loading game...`, `Waiting for players...`, `Connection failed`).

### Person
**Second person, command voice.** "Whisper me a betrayal." "Enter room code." "Host game." Never first person, never "we." The game speaks *to* the player.

### Numbers & technical content
- Room codes are 4 characters, drawn from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no ambiguous characters like 0/O, 1/I). Always shown in monospace, uppercase.
- IPs and version strings are flat and unstyled (`v0.1.0 - Alpha`, `192.168.1.10`).
- Time displays use a zero-padded `MM:SS` format.

### Emoji
README files use a small set of emoji as section bullets (🗺 🚀 🛠 🔌 📋 🤝 📄) — that pattern is reserved for *developer-facing docs only*. Player-facing UI has **zero emoji**.

### Examples — verbatim from the game
| Surface | Copy |
| --- | --- |
| Wordmark | `LYRE & LIAR` |
| Tagline | `Whisper me a betrayal` |
| Mode header | `SELECT MAP` |
| Map labels | `DAY` · `NIGHT` · `FOREST (LVL 4)` |
| Primary actions | `SINGLE PLAYER` · `MULTIPLAYER` · `HOST GAME` · `JOIN GAME` · `QUIT` |
| Placeholders | `Room Code` · `e.g. 192.168.1.10` · `Enter room code` |
| Status (success) | `Room: ABCD\nYour IP: 192.168.1.10\nWaiting for players...` |
| Status (busy) | `Hosting game...` · `Loading game...` · `Waiting for room code...` |
| Status (failure) | `Failed: <reason> (Check room code and try again)` · `Room code must be 4 characters` |
| Overlay titles | `PAUSED` · `YOU DIED` · `TOO LATE` · `LEVEL COMPLETE` |
| Overlay actions | `Resume` · `Restart` · `Replay` · `Next Level` · `Main Menu` · `Quit` |
| Footer | `v0.1.0 - Alpha` |

---

## VISUAL FOUNDATIONS

### The 30-second pitch
Cozy-pixel platformer dressed in stage-lit fantasy. Everything *gameplay* — sprites, tiles, backgrounds — is hand-painted pixel art at 16–32 px. Everything *UI* — menus, HUD, overlays — is high-contrast Godot-default chrome with a single brass accent rule above and below the wordmark. The result reads as "arcade cabinet running an indie fantasy game", not "modern app".

### Color
A **near-black green void** (`#080F08`) is the canvas. A single **brass rule** (`#C78D2E`) brackets the wordmark. Text is **parchment cream** (`#F2E5D9`) with a **brass-deep drop shadow** (`#522E0F`, 3 px offset). Every other accent is a single mood color stamped onto its button or overlay:
- **Day** is sun-gold (`#FFBF33`).
- **Night** is moon-blue (`#99BFFF`).
- **Forest** is forest-green (`#33CC66`).
- **YOU DIED** is alarm red (`#FF3333`) on a `rgba(64,0,0,0.7)` overlay.
- **TOO LATE** is ember orange (`#FF9933`) on `rgba(0,0,0,0.7)`.
- **LEVEL COMPLETE** is acid lime (`#99FF66`) on `rgba(0,38,13,0.7)`.
- **PAUSED** is honey (`#FFD94D`) on `rgba(0,0,0,0.6)`.
- **Countdown timer** is butter (`#FFE666`).

Every color is reproduced 1:1 from the Godot `Color(r,g,b,a)` declarations. See `colors_and_type.css` for the full mapping.

### Type
The shipped game uses **Godot's default theme font** (a Noto Sans hybrid). This system substitutes:
- **Cinzel** (display, 900) for the `LYRE & LIAR` wordmark — medieval Roman caps that match the lyre/instrument framing.
- **Jersey 25** (UI) for buttons, overlay titles, and state callouts — chunky, arcade-stadium feel.
- **VT323** (mono) for the room-code input and countdown timer — pixel display that pairs with the in-game sprites.
- **Inter** (body) for help text, placeholders, and dev docs.

> ⚠ **Font substitution flagged.** The Godot project ships no `.ttf` files. If you want pixel-perfect parity with what players see in-game, swap all four families above back to system sans or import Godot's bundled font. Ask the user for guidance.

Type rules:
- Wordmark is always **52 px**, all caps, with the brass-deep 3 px drop shadow and tight letter-spacing.
- Button labels are **22 px**, all caps, with a 1 px shadow underneath.
- Overlay titles range **32–40 px** — `PAUSED` is the smallest, `YOU DIED` / `TOO LATE` the largest.
- Status / version / mode labels are **12–14 px** and always one of the muted greens.

### Layout
- **Base viewport: 360 × 640 portrait.** Mobile is the design canvas; desktop and tablet scale up via `ResponsiveUI` (`min(vp.x / 360, vp.y / 640)`, clamped 0.7×–2.5×).
- **Stretch mode: `canvas_items` + `keep_height`.** Width can grow; vertical fit is sacred.
- **Center-stack layout.** The main menu, every overlay, and the death/complete panels are vertical `VBoxContainer`s anchored to the screen center, separated by **18 px** between buttons, **16 px** inside overlays.
- **Buttons are full-width within the stack:** 280×56 on the main menu, 240×50 inside overlays.
- **Title block** sits at 8% from the top, has a 6 px brass rule above and below, and a 600 px max width.
- **HUD overlays** are anchored: pause "II" button top-left (12 px inset), timer top-right (12 px inset).
- **Mobile controls** are absolutely positioned: 100 px joystick bottom-right, 100 px JUMP button bottom-left, 20 px padding from the viewport edges.

### Backgrounds
- The main menu uses a **single parallax cave background image** (`background1.png`) stretched full-bleed with a **green color overlay** (`modulate Color(0.6, 0.85, 0.6, 0.32)`) — this is what gives the menu its alien green wash. The void color (`#080F08`) lives behind it.
- In-game backgrounds are **multi-layered parallax PNGs** painted in a cozy pixel style — mountain silhouettes, cave stalactites, grass meadows.
- Overlay backgrounds are **flat, low-alpha color washes** (`0.6α` to `0.7α`) — no blur, no gradient, no texture. Crisp tinted vignettes.

### Animation
The game tweens almost nothing. UI state changes are **hard cuts**:
- Menu navigation toggles visibility instantly.
- Pause / death / level-complete overlays appear instantly (`visible = true`).
- The only continuous animation is **sprite frame cycling** (player 6–10 fps depending on state) and **remote-player position lerp** at `REMOTE_LERP_SPEED = 12.0` (`global_position.lerp(target, clamp(12.0 * delta, 0, 1))`).
- Recommended easing for new web-side motion: **none, or 90 ms linear**. Stay snappy and discrete to match the engine's behavior.

### Hover & press states
- **Hover**: lighten by ~15% brightness (Godot default stylebox does this implicitly).
- **Press**: darken by ~15% **and** push 1 px down. The mobile JUMP button modulates to `Color.GRAY` while held and back to `Color.WHITE` on release (`scripts/mobile_controls.gd`).
- **Disabled**: 60% brightness + slight desaturation. Buttons remain visible but read clearly unavailable.

### Borders, shadows, radii
- **Borders**: none on menu buttons (Godot default stylebox).
- **Radii**: square corners *everywhere except mobile controls*. The joystick base + handle and the JUMP button are **fully round pills** (corner radius = half their side length, set dynamically in `mobile_controls.gd`).
- **Outer shadows**: not used.
- **Inner shadows**: not used.
- **Text shadows**: every screen title carries one — solid, no blur, 2–3 px offset, ~80% opacity. This is the closest the system gets to depth.

### Transparency & blur
- **Transparency**: reserved for overlay washes (40–70% alpha) and the main-menu background modulate (32% green tint). Never used for cards, buttons, or panels.
- **Blur**: never used. The aesthetic is crisp pixel sprites + flat color overlays.

### Cards
There are no card surfaces in the game today. If you need to add one (e.g. a leaderboard row, a roster tile), the closest analog is the **overlay panel pattern**: vertical stack, centered, ~240–280 px wide, no card frame, no border, no shadow — just spacing and text alignment. If a frame is required, use a **6 px brass rule** above and below the content, mirroring the title block.

### Imagery vibe
Cozy, slightly melancholic pixel art. The Pink Monster is a fluffy magenta blob with eyes. The Owlet is a baby owl. The Dude is a beige blob with bandit eyes. The hermit is an orange crab-creature with a yellow shock of hair. Caves are dark teal-black with stone purple, plus glowing red lava pits and warm wood crates. Grass maps are warm green with sandy-yellow paths.

The palette of player-facing imagery is **warm + cool + acid**: warm browns and ambers in the world, cool teals in the void, and acid pinks/greens on the characters that pop against both.

---

## ICONOGRAPHY

**There is no icon system in the codebase today.** This is a current gap, not an intentional design choice. The shipped game uses:

- The **default Godot SVG icon** (`icon.svg`) as the app/window icon — a stylized robot face. It's preserved in `assets/logo/godot-icon.svg` so it doesn't get lost, but **it is not the Lyre & Liar brand mark.** A real wordmark logo should be commissioned.
- A **plain `II` ASCII glyph** as the pause button — no icon, just two pipes set in the button's font (`scripts/pause_menu.gd`).
- Plain **uppercase text** as the JUMP button (`JUMP`), the room code input, and every menu action — no leading or trailing icon, ever.
- **Sprite art** for everything diegetic (pickups: carrot, star; enemies: bee, slug, piranha plant) — these are *gameplay objects*, not UI icons.

**Substitution flagged to the user:** for any UI that needs an icon (settings gear, back arrow, sound toggle, share, share-code copy button, friend roster), this design system links **[Lucide](https://lucide.dev)** from CDN as a stand-in. Stroke weight 2 px, rounded line caps, no fill — closest match to the bold/round mood of the menu buttons. Document the substitution wherever it's used and replace with custom pixel-art icons once the user commissions a set.

Emoji are **never** used in player-facing UI. Unicode glyphs are used only for the pause button (`II`).

---

## Index

| Path | Purpose |
| --- | --- |
| `colors_and_type.css` | All design tokens — colors, type families, scale, spacing. |
| `preview/` | Small HTML cards for the Design System tab. |
| `ui_kits/game/index.html` | Click-through recreation of the game UI: main menu → map select → multiplayer → in-game HUD → overlays. |
| `ui_kits/game/*.jsx` | React components (`TitleBlock`, `MenuButton`, `MainMenu`, `MobileHUD`, `Overlay`, etc). |
| `assets/sprites/` | Player + monster + enemy + pickup PNGs. |
| `assets/tilesets/` | Cave + grass + procedural terrain tiles. |
| `assets/backgrounds/` | Parallax backgrounds (cave, grass). |
| `assets/logo/godot-icon.svg` | Current Godot placeholder icon — flagged as not-the-real-logo. |
| `SKILL.md` | Agent-skill metadata for portable use in Claude Code. |

---

## Status & known gaps

- **No real logo / wordmark.** The brand reads from typography alone.
- **No font files.** Substitutions flagged above.
- **No icon set.** Lucide via CDN as stand-in.
- **No marketing site, store page, or social art** — this system covers only the game client.
- The game itself is **v0.1.0 alpha**; the imposter mechanic, trap entities, and enemy AI are still in active development. The platforming + netcode + UI shell are stable.
