# Lyre-Liar

**A 2D multiplayer platformer with a hidden imposter — playable on PC and mobile, in the same room.**

Up to 16 players drop into one shared 2D level and try to make it through together. Every level is a hand-built platformer course full of **enemies** and **traps** — spikes, saws, fire, swinging spiked balls, falling platforms, and bottomless pits. Crewmates run, double jump, wall jump, and survive their way to the trophy.

But one of the players isn't a crewmate. **One player is secretly the imposter.** They look identical to everyone else and share the same room — but only the imposter can **silently trigger the traps**, quietly springing a hazard just as a crewmate walks past.

The crewmates' job is to survive the level *and* figure out who keeps "happening" to be near the traps when they fire. The imposter's job is to thin the group out and never get caught.

> **Status:** the single-player campaign (four levels), the platforming controller, traps and enemies, menus, progress saving, and Colyseus multiplayer rooms are implemented. Imposter role assignment and imposter-triggered traps are the next gameplay-design track.

---

[![Godot Engine](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Networking](https://img.shields.io/badge/Network-Colyseus-9b59b6)](https://colyseus.io)
![Platforms](https://img.shields.io/badge/Platforms-PC%20%7C%20Android-2ecc71)

Built with **Godot 4.7** and a **Colyseus** authoritative server. This is the official repository for **Project Lyre-Liar**, maintained by [LEVELSTAIR](https://github.com/LEVELSTAIR/Lyre-Liar).

## 🗺️ Levels

Play them in order from **Play → Select Level**; finishing a level unlocks the next one. Best time and fruits are saved per level.

| # | Level | Teaches |
|---|---|---|
| 1 | **Meadow** | Running, jumping, fruit, pits, checkpoints, stomping a pig |
| 2 | **Canyon** | Double jumps, trampolines, spike corridors, pillar hops |
| 3 | **Sky Ruins** | Moving and falling platforms, saws, fans |
| 4 | **Fortress** | Wall-jump shafts, fire traps, swinging spiked balls |

## 🎮 Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Move | `A` / `D` or `←` / `→` | D-pad / left stick | ◀ ▶ buttons (bottom left) |
| Jump / double jump | `Space`, `W`, or `↑` | A | ▲ button (bottom right) |
| Wall jump | Jump while sliding down a wall | A | ▲ |
| Pause | `Esc` or `P` | Start | `II` button (top right) |

Land on an enemy to stomp it. Touch controls appear automatically on touch screens (change it in **Settings**).

## 🚀 Getting Started

### Prerequisites
- **Godot 4.7+**
- **Node.js 18+** (only for multiplayer)

### Run the game
1. Open `project.godot` in **Godot 4.7** or later.
2. Press **F5**. The game starts on the title screen (`scenes/ui/title_screen.tscn`).

### Multiplayer
Start the Colyseus server:

```bash
cd colyseus_server
npm install
npm start
```

It listens on `ws://localhost:2567` (override with `PORT=...`). In the game choose **Multiplayer**, pick a character, enter the server address (remembered between sessions), then **Host** a room on any level or **Join** with a friend's 4-character room code. PC and mobile players can share a room as long as they reach the same server.

## 🧪 Tests

Both suites run headless and need no addons:

```bash
# Unit tests (level catalog, save data)
godot --headless --path . -s res://tests/run_tests.gd

# End-to-end smoke test: every level, the player controller, every
# gameplay object, and the menu/overlay flow
godot --headless --path . res://tests/smoke/smoke_flow.tscn
```

## 📂 Project Structure

```text
Lyre-Liar/
├── scenes/
│   ├── levels/          # level_base.tscn + meadow, canyon, sky_ruins, fortress
│   ├── objects/         # Traps, pickups, checkpoints, goal, platforms, pig
│   ├── ui/              # Title, level/character select, multiplayer, settings,
│   │                    # HUD, pause/death/complete overlays, touch controls
│   └── player.tscn
├── scripts/
│   ├── autoload/        # Events (signal bus), GameProgress (save), SceneRouter
│   ├── player/          # Player + one script per movement state
│   ├── state_machine/   # Reusable node-based state machine
│   ├── components/      # HealthComponent
│   ├── objects/         # Gameplay object behaviour
│   ├── levels/          # Level base, scrolling background
│   ├── ui/              # Screens, HUD, overlays
│   ├── data/            # LevelInfo/LevelCatalog, CharacterData, LevelResult
│   └── multiplayer_manager.gd  # Autoload — Colyseus host/join/single-player
├── data/                # Level catalog, characters, sprite frames, tileset, UI theme
├── tools/               # Generators for levels, tileset, sprite frames, theme; previews
├── tests/               # Unit tests and the smoke test
├── asset/               # CC0 art packs and OFL fonts (see CREDITS.md)
├── colyseus_server/     # Authoritative Node.js server
└── addons/colyseus/     # Pure-GDScript Colyseus client
```

## 🛠️ Adding or Changing a Level

Levels are generated from text layouts so they are easy to review and reshape:

1. Edit or add a layout in `tools/level_builder/layouts/` — one character per 16 px tile. The legend and file format are documented at the top of `tools/level_builder/build_levels.gd`.
2. Regenerate the scenes:
   ```bash
   godot --headless --path . res://tools/level_builder/build_levels.tscn
   ```
3. For a new level, add a `LevelInfo` resource to `data/levels/` and list it in `data/levels/level_catalog.tres`, then add its id to the allowed modes in `colyseus_server/index.js`.
4. Preview it: `godot --path . res://tools/level_builder/preview_level.tscn -- --level=<id>`

Generated scenes inherit `scenes/levels/level_base.tscn` and stay editable in the Godot editor, but re-running the builder overwrites editor changes.

## 🔌 Networking Overview

- **Transport**: `@colyseus/ws-transport` WebSocket, single room type `"werewolf"` filtered by `roomCode`.
- **Server state** (`colyseus_server/index.js`): `WerewolfRoomState { players, roomCode, mode, hostSessionId }` where `mode` is the level id, and `PlayerState { x, y, vx, vy, tick }`.
- **Client mirror**: `WerewolfRoomState` / `WerewolfPlayerState` GDScript classes match the server schema's field order.
- **Messages**: the local player sends `"move"` at ~15 Hz; remote players interpolate toward the latest state and animate from their velocity (`scripts/player/player_network_sync.gd`).
- **Room codes**: 4 characters from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`; host collisions auto-retry.

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the issue-first workflow, branching model, and code style.

## 📄 License

Code is licensed under [LICENSE.md](./LICENSE.md). Third-party art and fonts are listed in [CREDITS.md](./CREDITS.md). Team credits in [Dev Credits.md](./Dev%20Credits.md).

---
*Built with Godot 4.7 and Colyseus.*
