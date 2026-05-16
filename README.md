# Project Werewolf — 2D Multiplayer Social Deduction Platformer

[![Godot Engine](https://img.shields.io/badge/Godot-4.6-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Networking](https://img.shields.io/badge/Network-WebSocket-green)](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)
[![Physics](https://img.shields.io/badge/Physics-Jolt-orange)](https://github.com/godot-jolt/godot-jolt)

A 2D multiplayer platformer built with **Godot 4.6** that blends **co-op platforming** with **social deduction**. A crew of players races to finish the level — but one of them is the **Imposter**, secretly triggering traps and sabotaging progress. The rest must survive enemies, escape hazards, and reach the goal before the saboteur ends the run.

This is the official repository for **Project Werewolf**, originally maintained by [LEVELSTAIR](https://github.com/LEVELSTAIR/project-werewolf).

## 🐺 The Game

A short, fast-paced round plays out across a single level:

* **Crew (Players)** — Run, jump, and cooperate to reach the level's goal.
* **Imposter (Hidden Saboteur)** — Looks like a regular player, but can secretly trigger traps along the path to stall, separate, or eliminate the crew. Their goal is to prevent the crew from finishing.
* **Enemies** — AI-driven hostile creatures that roam the level and attack any player on sight, threatening crew and imposter alike (though the imposter may know how to slip past them).

**Win conditions**

* **Crew wins** if enough players reach the goal alive.
* **Imposter wins** if the crew is wiped out, runs out of time, or fails to escape.

> ⚠️ **Status:** Core multiplayer movement, rooms, and level rendering are implemented. Imposter roles, traps, enemies, and round-flow logic are the next milestone — see `scripts/interactables/` and `scenes/interactables/` (placeholders).

## 🚀 Key Features

* **🔌 Authoritative WebSocket Multiplayer** — A lightweight Node.js server (`colyseus_server/`) manages rooms and relays player state. No peer-to-peer setup, no signaling dance — clients just connect to one URL.
* **🏷️ 4-Character Room Codes** — Hosts generate a short code from a non-ambiguous alphabet (no `0/O`, `1/I`, etc.) to share with friends.
* **🌗 Day / Night Modes** — Mode selection in the main menu chooses between two level layouts (`level_2` for Day, `level_1` for Night).
* **📱 Mobile-First UI** — Built for 360×640 portrait viewports with virtual on-screen controls (`scenes/mobile_controls.tscn`) and dynamic scaling via the `ResponsiveUI` autoload.
* **🧮 Client-Side Interpolation** — Remote players are smoothly lerped toward authoritative server positions; the local player runs physics locally and ticks updates to the server at 15 Hz.
* **🏗️ Tile-Based Levels** — Levels are built from a 2D int grid using a small terrain palette (Grass, Dirt, Stone, Rock, Bedrock, Fungus, Glow). Kill zones reset players to spawn.
* **⚙️ Jolt Physics** — Configured to use the Jolt physics engine for stable character movement.

## 🛠️ Getting Started

### 1. Start the multiplayer server

```bash
cd colyseus_server
npm install
npm start
```

The server listens on `ws://localhost:2567` by default. Override with the `PORT` environment variable.

### 2. Open the Godot project

1. Open the project in **Godot 4.6+**.
2. If you're running the server on a different host/port, edit `_server_url` in `scripts/multiplayer_manager.gd`.
3. Run the project (`F5`). The main menu (`scenes/main_menu.tscn`) launches first.

### 3. Play

1. On the main menu, pick **Day** or **Night** to choose a level layout.
2. **Host** a room — a 4-character room code is displayed in the top-left of the level.
3. On another device or client, choose the same mode, tap **Join**, enter the 4-char code, and you're in.

## 📂 Project Structure

```
project-werewolf/
├── scenes/
│   ├── main_menu.tscn       # Mode select + host/join UI
│   ├── level_1.tscn         # Night-mode level
│   ├── level_2.tscn         # Day-mode level
│   ├── player.tscn          # Player character
│   ├── mobile_controls.tscn # On-screen virtual controls
│   ├── main.tscn
│   └── interactables/       # (planned) traps, enemies, goal objects
├── scripts/
│   ├── multiplayer_manager.gd  # WebSocket client + room/session signals (autoload)
│   ├── responsive_ui.gd        # Scale-factor autoload for mobile-first layout
│   ├── main_menu.gd
│   ├── level_1.gd / level_2.gd # Tile rendering, spawn points, kill zones, player spawn/despawn
│   ├── player.gd               # Local physics + remote lerp; sends `move` at 15 Hz
│   ├── mobile_controls.gd
│   ├── collectible.gd          # Stub Area2D pickup
│   └── interactables/          # (planned) imposter traps, enemy AI scripts
├── colyseus_server/
│   ├── index.js             # Node.js WebSocket room server (built on `ws`)
│   └── package.json
├── asset/                   # Terrain textures, characters, SunnyLandForest pack
├── addons/godot_mcp/        # Godot MCP plugin (editor tooling)
└── project.godot
```

> Note: the `colyseus_server/` folder name is historical — the current server is a plain Node.js WebSocket relay using the `ws` library, not the Colyseus framework.

## 🌐 Networking Model

The networking is intentionally simple and authoritative-relay style:

| Client → Server | Server → Clients |
| --- | --- |
| `host` — create a room, receive `roomCode` + `sessionId` | `hosted` / `joined` — confirms entry |
| `join` — join a room by code | `player_joined` / `player_left` — peer membership changes |
| `move` — `{x, y, vx, vy, tick}` at 15 Hz | `player_moved` — relayed peer state |

* Each player runs their own physics locally; the server **does not** simulate or correct movement.
* Remote players are interpolated client-side toward the latest `player_moved` snapshot.
* Rooms are destroyed automatically when the last player disconnects.

This model is well-suited to extending with **imposter actions** (trap-trigger RPCs) and **enemy state** (server-owned AI broadcasts) — both planned next.

## 🗺️ Roadmap

The platforming and networking foundation is in place. Upcoming work, in rough order:

1. **Role assignment** — One random player per round is secretly the Imposter; the server tells each client only its own role.
2. **Traps** — Server-validated trap objects (spikes, falling platforms, doors) that the Imposter can trigger covertly. Visual cues and cooldowns prevent obvious tells.
3. **Enemies** — Server-authoritative AI that patrols and attacks any player, with attack/damage RPCs.
4. **Health & elimination** — Damage, downed/eliminated states, and a respawn or spectator flow.
5. **Round flow** — Goal object, win/lose conditions, end-of-round reveal of the Imposter, lobby reset.
6. **Voice / text comms or quick-chat** — Social deduction needs a way to accuse and defend.

## 📋 Development Notes

* **Autoloads** — `MultiplayerManager` (networking) and `ResponsiveUI` (scaling) are registered in `project.godot`.
* **Tick rate** — Movement is sent every `1/15 s` (`SEND_INTERVAL` in `player.gd`). Adjust there if you change server cadence.
* **Spawn points** — Hardcoded per-level in `level_1.gd` / `level_2.gd` and cycled per join order.
* **Mobile build** — APKs are produced via Godot's Android export; recent builds are checked into the repo root (`0.5.apk` … `0.14.apk`) for quick testing.

## 🤝 Contributing

Contributions welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for workflow and coding standards.

## 📄 License

Licensed under the terms in [LICENSE.md](./LICENSE.md).

---
*Built with Godot 4.6 + WebSocket.*
