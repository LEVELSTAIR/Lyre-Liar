# Contributing to Project Werewolf

First off, thank you for considering contributing to Project Werewolf! It is community contributions that help us build a better 2D multiplayer platformer.

To ensure high-quality and maintainable code, we follow **professional game studio practices**. By following these guidelines, you help us review and merge your work faster.

---

## 🚀 How to Get Started

### 1. Find an Issue
Every contribution must start with an **Issue**. Check our [Issue Tracker](https://github.com/LEVELSTAIR/project-werewolf/issues) to find something to work on. If you have a new idea, open an issue first to discuss it with the maintainers.

### 2. Fork the Repository
Standard contributions happen via **Forks**.
1.  **Fork** this repository to your own GitHub account.
2.  **Clone** your fork locally and set up the Godot 4.6 development environment.
3.  Add the upstream repository as a remote:
    ```bash
    git remote add upstream https://github.com/LEVELSTAIR/project-werewolf.git
    ```

### 3. Create a Feature Branch
Always branch off from the latest `dev` branch:
```bash
git fetch upstream
git checkout -b feature/your-feature-name upstream/dev
```

### 4. Implement & Test
*   Follow existing code patterns in the project.
*   Test your changes in the Godot Editor (ensure both Host and Join flows work if changing networking).
*   Verify that your changes don't break the build or the signaling server.

### 5. Submit a Pull Request
Once ready, push your branch to your fork and open a PR against our `dev` branch. Link the PR to the relevant issue.

## 1. Branching model (no exceptions)

We use a **simple, strict model**.

### Branches

* `main` → always playable, stable
* `dev` → active integration branch
* `feature/*` → all work happens here

You **never** commit directly to `main` or `dev`.

Example:

```
feature/physics-jolt-integration
feature/ui-room-matchmaking
feature/player-movement-sync
```

---

## 2. Issue-first development (mandatory)

**Every PR must be linked to an Issue.**

No issue = no PR.

Why:

* Prevents random drive-by changes
* Keeps scope controlled
* Makes reviews objective

### Workflow

1. Open or claim an Issue
2. Discuss approach if unclear
3. Create feature branch from `dev`
4. Implement **only what the issue describes**
5. Open PR

If you discover extra work:

* Open a **new issue**
* Do **not** sneak it into the same PR

---

## 3. Commit discipline (this matters)

### When to commit

Commit when:

* One logical change is complete
* Code compiles
* Tests or play mode still run

Do **not** commit:

* Half-working systems
* “WIP” junk
* Debug spam

You are not saving checkpoints. You are writing history.

---

## 4. Commit message format (enforced)

We follow a **Conventional Commits–inspired** format.

### Structure

```
<type>(scope): short description
```

### Types

* `feat` – new feature
* `fix` – bug fix
* `refactor` – internal change, no behavior change
* `docs` – documentation only
* `chore` – tooling, config, cleanup

### Examples

```
feat(player): add dash movement mechanic
fix(network): resolve WebRTC ice candidate timeout
refactor(ui): split room list view into separate components
docs: update README with network setup steps
```

Rules:

* Present tense
* No emojis
* No “stuff”, “things”, “changes”
* One idea per commit

Bad commits will be requested to be squashed or rewritten.

---

## 5. Rebase, don’t merge (important)

We use **Rebase and Merge**.

Why:

* Linear history
* Clean blame
* No “merge branch dev into feature” garbage

### Before opening a PR

```
git fetch origin
git rebase origin/dev
```

Fix conflicts locally.
If you don’t know how to rebase, learn it before contributing.

---

## 6. Pull Request rules (read carefully)

### A PR must:

* Address **one issue**
* Touch **one system** (UI, Core, Network, Physics, etc.)
* Build without network dependency (use local mock if possible)
* Respect authority boundaries (Authority vs Client vs Server)

### A PR must NOT:

* Mix refactors + features
* Introduce new packages (addons) without approval
* Break offline/local development mode
* “Improve architecture” without discussion

---

## 7. How to write a good PR

### PR title

Same format as commit messages:

```
feat(network): add WebRTC room signaling
```

### PR description template

Use this structure:

**What does this PR do?**
Clear, short explanation.

**Which issue does it close?**
`Closes #42`

**How was this tested?**

* Editor play mode
* Cross-client sync tested (Host + 2 Clients)
* Local vs Deployed signaling server checked

**Anything reviewers should know?**
Edge cases, follow-ups, limitations.

If your PR description is vague, reviewers will push back.

---

## 8. Review process (who to tag)

### Required reviewers

Tag **at least one** maintainer based on the system:

* Core / Gameplay → Core Maintainers
* UI / Layout → UI Maintainers
* Networking / WebRTC → Networking Maintainers
* Physics / Jolt → Physics Maintainers

If you tag nobody, your PR will sit untouched.

Reviews are **not personal**.
If a reviewer asks for changes, it’s not an insult — it’s how teams work.

---

## 9. Scope control (this saves the project)

Project Werewolf survives only if scope is controlled.

That means:

* Small PRs
* Clear intent
* No ego-driven rewrites

If a PR grows too big, you will be asked to split it.
If you refuse, it will be closed.

This is not punishment. It’s maintenance.

---

## 10. Code quality expectations

* Follow existing patterns
* No magic numbers without explanation
* No WebRTC calls outside `MultiplayerManager`
* No Jolt-specific physics hacks in `player.gd`
* No UI logic in gameplay systems
* No gameplay logic in UI

If you’re unsure, ask **before coding**.

---

## 11. Final note (read once)

Open source does not mean lawless.
Professional projects survive because they are boringly disciplined.

If you follow this guide:

* Your PRs will be reviewed faster
* Your work will actually ship
* You’ll learn how real studios operate

If you ignore it:

* Your PRs will stall or close
* Nobody will argue with you
* The repo stays healthy

That’s the deal.
