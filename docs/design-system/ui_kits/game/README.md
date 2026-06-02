# Lyre & Liar — Game UI Kit

Hi-fi recreation of the Lyre & Liar game client UI, modeled directly from the Godot `.tscn` scene files and `.gd` scripts. Renders the 360×640 mobile-first viewport with portrait scaling, click-through navigation between menu states, and the full set of in-game overlays.

## Surfaces recreated

1. **Main menu screen 1** — Single Player / Multiplayer / Quit. Title block + brass rule + tagline.
2. **Main menu screen 2** — Map select (Day / Night / Forest).
3. **Main menu screen 3** — Multiplayer options (server address, room code, Host / Join).
4. **In-game HUD** — pause button top-left, countdown timer top-right (single-player only), mobile controls bottom (joystick + JUMP).
5. **Paused overlay** — `PAUSED` + Resume / Main Menu / Quit.
6. **You Died overlay** — Restart / Quit on the crimson wash.
7. **Too Late overlay** — single-player timeout, Restart / Quit on black.
8. **Level Complete overlay** — stats + Replay / Next Level / Main Menu on forest wash.

## How to use this kit

- Open `index.html` in a browser. It opens on the main menu.
- Click any button to advance state. The state machine mirrors `main_menu.gd` exactly.
- Tap the pause `II` button in-game to surface the pause overlay.
- A debug bar at the top right lets you jump straight to Died / Timeout / Complete overlays for art review.

## Components

The kit is split across five `.jsx` files (loaded in order by `index.html`). Related components are consolidated into `Primitives.jsx` and `Overlays.jsx` rather than one file each.

| File | Components | Purpose |
| --- | --- | --- |
| `Primitives.jsx` | `GameFrame`, `TitleBlock`, `MenuButton`, `StatusLine` | 360×640 portrait shell, LYRE & LIAR wordmark + brass rules, Godot-default stylebox buttons, and multiline status text. |
| `MainMenu.jsx` | `MainMenu` | Composes the three menu screens (initial / map-select / multiplayer), including the inline room-code and server-address inputs. |
| `GameView.jsx` | `GameView`, `PauseButton`, `TimerHud`, `MobileControls` | In-game canvas (parallax background + sprites), top-left pause button, top-right countdown, and the joystick + JUMP controls. |
| `Overlays.jsx` | `Overlay`, `OverlayTitle`, `OverlayPaused`, `OverlayDied`, `OverlayTimeout`, `OverlayComplete` | Generic centered overlay frame/title plus the four overlay states. |
| `App.jsx` | `App` | Root state machine — mirrors `main_menu.gd::_update_ui_state` and the in-game overlay flow. |

## Notes & limitations

- The actual game has live sprite animation, parallax, and a 16-player networked world. This kit shows the **menu chrome and overlays only**, with a single still parallax frame standing in for the in-game playfield.
- Fonts are substituted (see root `README.md`). Set `--font-display`, `--font-ui`, `--font-mono` to the engine default to revert.
- Logo is the Godot placeholder — flagged.
