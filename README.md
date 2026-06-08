# Project Werewolf

**A 2D multiplayer platformer with a hidden imposter — playable on PC and mobile, in the same room.**

Up to 16 players drop into one shared 2D map and try to make it through together. The world is a hand-built platformer level filled with **enemies** and environmental **traps** — spikes, falling blocks, kill-zones, and hazards scattered between the platforms. Crewmates jump, dodge, and survive their way across the map.

But one of the players isn't a crewmate. **One player is secretly the imposter.** They look identical to everyone else, walk and jump like everyone else, and share the same room. The difference: only the imposter can **silently trigger the traps** as they move through the level — quietly springing a spike floor or releasing a hazard just as a crewmate walks past, trying to take them out without anyone noticing who did it.

The crewmates' job is to survive the map *and* figure out who keeps "happening" to be near the traps right when they fire. The imposter's job is to thin the group out and never get caught.

## How it plays

- **Cross-platform multiplayer** — PC players (keyboard) and mobile players (touch joystick + jump button) join the same room over a Colyseus WebSocket server. A 4-character room code is all you need to share a game.
- **Multiple maps** — pick from **Day** (sunny outdoor platforms), **Night** (underground stone-and-fungus tiles), or **Forest** (a tall vertical map). Each is a tile-built 2D world with floating platforms, walls, and a fall-out kill-zone.
- **Same-map chaos** — every player runs around the same level at the same time. Falling off the bottom or hitting a deadly hazard respawns you. The imposter uses crowded moments to do their work.
- **Single-player mode** — practice maps offline without spinning up the server.

> **Status note:** Networking, movement, the kill-zones, mobile/PC input, and all three maps are implemented. Imposter role assignment, trap entities, and enemy AI are the active gameplay-design track — the platforming and netcode underneath them are stable.

---

[![Godot Engine](https://img.shields.io/badge/Godot-4.6-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Networking](https://img.shields.io/badge/Network-Colyseus-9b59b6)](https://colyseus.io)
![Platforms](https://img.shields.io/badge/Platforms-PC%20%7C%20Android-2ecc71)

Built with **Godot 4.6** and a **Colyseus** authoritative server. This is the official repository for **Project Werewolf**, originally maintained by [LEVELSTAIR](https://github.com/LEVELSTAIR/project-werewolf).

## 🗺️ Maps

Selected from the main menu after choosing single-player or multiplayer:

| Mode    | Scene                  | Style                                            |
| ------- | ---------------------- | ------------------------------------------------ |
| Day     | `scenes/level_2.tscn`  | Bright outdoor platforms over grass/dirt terrain |
| Night   | `scenes/level_1.tscn`  | Tile-based underground (grass/dirt/stone/fungus) |
| Forest  | `scenes/level_4.tscn`  | Tall forest map with a vertical camera           |
| Forest  | `scenes/level_3.tscn`  | Developing                                       |

Every map has a `KillZone` Area2D — touching it triggers `player.respawn()` and snaps the player back to spawn.

## 🚀 Key Features

- **🟣 Colyseus Multiplayer** — Authoritative WebSocket server (`@colyseus/core`) with `MapSchema`-based room state. Room codes are 4 characters; host collisions auto-retry.
- **📱 PC + Mobile in one room** — Same build runs on desktop and Android. Touch controls auto-hide on desktop (`scripts/mobile_controls.gd`).
- **📐 Responsive UI** — `ResponsiveUI` autoload scales everything from a 360×640 portrait base across phone, tablet, and desktop viewports.
- **🧮 Client-side prediction + remote interpolation** — Local player is authoritative on its own movement, sends position at 15 Hz, remote players lerp smoothly toward incoming state (`scripts/player.gd`).
- **🧱 Code-driven tile worlds** — Levels are built from 2D arrays of tile IDs in GDScript, then instanced as `StaticBody2D` + `Sprite2D` at load. Easy to read, easy to edit.
- **🎯 Single-player mode** — Skips Colyseus entirely (`MultiplayerManager.start_single_player`) so you can prototype maps offline.

## 🛠️ Getting Started

### Prerequisites
- **Godot 4.6+** (Mobile preset enabled in `project.godot`)
- **Node.js 18+** for the Colyseus server

### 1. Start the Colyseus server

```bash
cd colyseus_server
npm install
npm start
```

The server listens on `ws://localhost:2567` by default (override with `PORT=...`).

### 2. Open the Godot project

1. Open `project.godot` in **Godot 4.6** or later.
2. Press **F5** to run, or build an APK for Android via *Project → Export* (presets in `export_presets.cfg`).

### 3. Play

From the main menu:

1. Choose **Single Player** or **Multiplayer**.
2. Pick a map: **Day**, **Night**, or **Forest**.
3. For multiplayer, enter the server address (defaults to `localhost`, remembered between sessions) and either:
   - **Host** — generates a 4-character room code, shows it to share.
   - **Join** — enter a 4-character room code from another player.

Mobile and PC players can join the same room as long as they can reach the same server IP.

### Controls

| Action      | PC                     | Mobile                       |
| ----------- | ---------------------- | ---------------------------- |
| Move left/right | `←` / `→` (`ui_left`/`ui_right`) | Left-side virtual joystick |
| Jump        | `Space` (`ui_accept`)  | Right-side jump button       |

## 📂 Project Structure

```text
Lyre-Liar/
├── colyseus_server/        # Authoritative Node.js server (Colyseus)
│   └── index.js            #   WerewolfRoom: state, join, move messages
├── scripts/
│   ├── multiplayer_manager.gd   # Autoload — host/join/single-player flow
│   ├── werewolf_room_state.gd   # Mirrors server room schema
│   ├── werewolf_player_state.gd # Mirrors server player schema
│   ├── player.gd                # Movement, animation, RPC send/receive
│   ├── main_menu.gd             # Mode select → map select → host/join
│   ├── mobile_controls.gd       # Touch joystick + jump button
│   ├── responsive_ui.gd         # Autoload — viewport-based scaling
│   ├── level_1.gd, level_2.gd, level_4.gd  # Per-map level scripts
│   └── bake_level3.gd, bake_level4.gd      # One-shot scene baking helper
├── scenes/
│   ├── main.tscn, main_menu.tscn
│   ├── player.tscn, mobile_controls.tscn
│   └── level_1.tscn, level_2.tscn, level_4.tscn
├── addons/
│   ├── colyseus/           # Pure-GDScript Colyseus client SDK
│   └── godot_mcp/          # Editor-side MCP tooling
├── asset/
│   ├── terrain/generated/  # Procedural tile textures (grass, dirt, stone…)
│   └── charectors/         # Player & monster sprite sheets
├── android/                # Android build template
└── project.godot           # Godot 4.6 Mobile project
```

## 🔌 Networking Overview

- **Transport**: `@colyseus/ws-transport` WebSocket, single room type `"werewolf"` filtered by `roomCode`.
- **Server state** (`colyseus_server/index.js`):
  - `WerewolfRoomState { players: MapSchema<PlayerState>, roomCode, mode, hostSessionId }`
  - `PlayerState { x, y, vx, vy, tick }`
- **Client mirror**: `WerewolfRoomState` / `WerewolfPlayerState` GDScript classes match field order with the server schema.
- **Messages**: clients send `"move"` at ~15 Hz with `{ x, y, vx, vy, tick }`; the server validates each field is finite before writing it to room state.
- **Room codes**: 4 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no ambiguous chars). Host conflicts return `409` and the client auto-regenerates (up to 3 retries).
- **Disconnects**: `MultiplayerManager` distinguishes "never joined" (→ `connection_failed`) from "joined then dropped" (→ `server_disconnected`).

## 📋 Development Notes

- **Autoloads** (configured in `project.godot`):
  - `ResponsiveUI` — emits `scale_changed` whenever the viewport resizes; UI scripts subscribe and re-layout.
  - `MultiplayerManager` — single source of truth for room state, exposes signals (`room_code_ready`, `player_connected`, `player_state_changed`, …) consumed by `main_menu.gd` and every `level_*.gd`.
- **Mobile-first viewport**: 360×640 base size, `keep_height` stretch — content scales horizontally but preserves vertical fit.
- **Adding a map**: drop a new `level_N.tscn` with a `KillZone: Area2D`, write a `level_N.gd` following the pattern in `level_4.gd` (connect `player_connected`/`player_disconnected`, spawn from `MultiplayerManager.active_players`), then wire it up in `main_menu.gd::_on_connected_to_game`.
- **Server config persistence**: the last server IP is saved to `user://server_config.cfg` so players don't retype it.

## 🤝 Contributing

Contributions welcome — see [CONTRIBUTING.md](./CONTRIBUTING.md) for workflow and coding standards.

## 📄 License

Licensed under the terms in [LICENSE.md](./LICENSE.md). Credits in [Dev Credits.md](./Dev%20Credits.md).

---
*Built with Godot 4.6 and Colyseus.*
