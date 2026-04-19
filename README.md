# Project Werewolf — 2D Multiplayer Platformer

[![Godot Engine](https://img.shields.io/badge/Godot-4.6-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Networking](https://img.shields.io/badge/Network-WebRTC-green)](https://webrtc.org)
[![Physics](https://img.shields.io/badge/Physics-Jolt-orange)](https://github.com/godot-jolt/godot-jolt)

An advanced 2D multiplayer platformer built with **Godot 4.6**, focusing on high-performance synchronization, mobile-first responsive design, and peer-to-peer networking via WebRTC.

This is the official repository for **Project Werewolf**, originally maintained by [LEVELSTAIR](https://github.com/LEVELSTAIR/project-werewolf).

## 🚀 Key Features

*   **⚡ WebRTC Multiplayer**: Robust peer-to-peer networking using a custom WebSocket signaling server for room creation and peer discovery.
*   **🛠️ Authority-Based Sync**: Advanced physics synchronization with client-side prediction, authority reporting, and server-side state correction to ensure smooth gameplay.
*   **📱 Mobile-First UI**: Fully responsive UI designed for mobile viewports (360×640) with dedicated virtual controls and dynamic scaling.
*   **🏗️ Dynamic World Generation**: Tile-based level construction system with support for custom terrain types (Grass, Dirt, Stone, Fungus, etc.) and kill-zone mechanics.
*   **⚙️ Jolt Physics Integration**: Leverages the high-performance Jolt Physics engine for accurate and efficient 2D character movement.

## 🛠️ Getting Started

### 1. Signaling Server Setup
The game requires a signaling server to coordinate WebRTC connections.

```bash
cd signaling_server
npm install
npm start
```
*The server defaults to `ws://localhost:9080`.*

### 2. Godot Project Configuration
1.  Open the project in **Godot 4.6+**.
2.  In `scripts/multiplayer_manager.gd`, ensure the `signaling_server_url` matches your local or deployed server.
3.  Run the project (`F5`).

### 3. Playing
*   **Host**: Select "Host" from the main menu to generate a 4-character Room Code.
*   **Join**: Enter the Room Code on another client to connect via WebRTC.

## 📂 Project Structure

*   `scenes/` — Game scenes (Main Menu, Levels, Player, Mobile Controls).
*   `scripts/` — Core logic including `MultiplayerManager.gd` and `ResponsiveUI.gd`.
*   `signaling_server/` — Node.js WebSocket server for WebRTC signaling.
*   `addons/webrtc/` — Godot WebRTC extension.
*   `asset/` — Terrain textures, icons, and player sprites.

## 📋 Development Notes

*   **Responsive UI**: The `ResponsiveUI` autoload handles dynamic scaling for different screen aspects.
*   **Multiplayer**: Game logic is split between local authority and server verification. See `player.gd` for RPC implementation details (`_sync_position`, `_force_correction`).
*   **Physics**: Configured to use Jolt Physics for better stability in multiplayer environments.

## 🤝 Contributing

We welcome contributions! Please refer to [CONTRIBUTING.md](./CONTRIBUTING.md) for our workflow and coding standards.

## 📄 License

This project is licensed under the terms found in [LICENSE.md](./LICENSE.md).

---
*Built with ❤️ using Godot and WebRTC.*