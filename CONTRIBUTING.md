# Contributing to Project Werewolf

Project Werewolf is an open-source project, but it follows **professional game studio practices**.
If you want chaos, experiment in your own fork.
If you want your work merged, follow this document.

---

## 1. Branching model (no exceptions)

We use a **simple, strict model**.

### Branches

* `main` → always playable, stable
* `dev` → active integration branch
* `feature/*` → all work happens here

You **never** commit directly to `main` or `dev`.

Example:

```
feature/plant-growth-stage-logic
feature/ui-eden-browser
feature/night-ai-spawner
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
feat(plant): add growth stage progression logic
fix(night): prevent enemy spawn during day phase
refactor(ui): split eden screen controller
docs: update README with multiplayer rules
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
* Touch **one system** (UI, Core, Network, Steam, etc.)
* Build without Steam running
* Respect assembly boundaries

### A PR must NOT:

* Mix refactors + features
* Introduce new packages without approval
* Break offline mode
* “Improve architecture” without discussion

---

## 7. How to write a good PR

### PR title

Same format as commit messages:

```
feat(eden): add basic plant placement
```

### PR description template

Use this structure:

**What does this PR do?**
Clear, short explanation.

**Which issue does it close?**
`Closes #42`

**How was this tested?**

* Editor play mode
* Scene tested
* Steam disabled / enabled (if relevant)

**Anything reviewers should know?**
Edge cases, follow-ups, limitations.

If your PR description is vague, reviewers will push back.

---

## 8. Review process (who to tag)

### Required reviewers

Tag **at least one** maintainer based on the system:

* Core / Gameplay → Core Maintainers
* UI Toolkit → UI Maintainers
* Networking / EDEN → Networking Maintainers
* Steam integration → Steam Maintainers

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
* No hard Steam calls outside `Leaf.Steam`
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
