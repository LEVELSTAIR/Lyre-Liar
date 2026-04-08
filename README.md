# Werewolf (Mafia) — Godot social deduction game

An open-source Godot implementation of the classic social deduction party game Werewolf (also called Mafia). Players are secretly assigned roles and must use discussion, bluffing, and voting to survive.

## Overview

Werewolf is a turn-based social game of deception and deduction. Each round alternates between Night (hidden actions) and Day (public discussion and voting). The core tension comes from secret roles, social bluffing, and trying to read other players.

## Core rules (short)

- Night: Players with hidden roles (e.g., werewolves) perform secret actions. Most players sleep and do nothing.
- Day: All players discuss, accuse, defend, and then vote to eliminate one player.
- Goal: Villagers win by eliminating all werewolves. Werewolves win by reducing villagers to parity.

Common roles (configurable): Villager, Werewolf, Seer, Doctor, Moderator.

## Features (planned)

- Local and online play (Godot multiplayer integration)
- Configurable roles and round settings
- Spectator mode and replays
- Simple UI and keyboard/controller support

## Getting started

Requirements

- Godot 4.x (recommended). Use the official Godot editor to open the project.

Quick start

1. Clone the repo:

   git clone <repo-url>

2. Open the project folder in Godot (open `project.godot`).

3. Run the main scene from the Godot editor.

Development notes

- Keep game logic decoupled from networking to allow offline play and easier testing.
- Use scenes and signals for clear flow between UI and game state.

## Contributing

We welcome contributions. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for code style, branch workflow, and PR guidelines.

Guidelines

- Keep PRs focused (one feature/fix per PR).
- Add tests where practical and keep changes small and well-documented.

## Project structure (high level)

- `project.godot` — Godot project file
- `scenes/` — Godot scenes (UI, game, roles)
- `scripts/` — GDScript or C# game logic
- `assets/` — art, icons, audio
- `CONTRIBUTING.md` — contribution rules
- `LICENSE.md` — project license

Adjust the structure as needed; keep code modular and documented.

## License

This project uses the license in `LICENSE.md`.

## Want to help?

Open issues, suggest roles or balance changes, and submit small PRs to get started. If you'd like, mention what you'd like to work on and we can point you at a good first issue.

---

Thanks for helping build a friendly, open-source Werewolf implementation!