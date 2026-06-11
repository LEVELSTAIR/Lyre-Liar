<!--
Thanks for opening a pull request! Please fill out each section below.
The checklist isn't bureaucracy — reviewers actually use it to decide
what to spot-check before approving. See CONTRIBUTING.md for the full
workflow, branching model, and code style.
-->

## Summary
<!-- 1–3 bullets on what changed and why. The "why" matters more than the "what" — the diff already shows the what. -->
-

## Linked issue
<!-- Required per CONTRIBUTING.md. Use "Closes #N" so the issue auto-closes on merge. -->
Closes #

## Type of change
<!-- Check all that apply. -->
- [ ] Bug fix
- [ ] Feature / enhancement
- [ ] Refactor
- [ ] Docs
- [ ] Build / tooling / CI

## Testing
<!-- What did you actually run? Be specific — "tested in editor" alone isn't enough. -->
- [ ] Opened the project in Godot 4.6+ and verified the change in the editor
- [ ] If touching networking: both **Host** and **Join** flows verified end-to-end (room code shown, second client joined, players see each other move)
- [ ] If touching `colyseus_server/`: `npm start` runs cleanly and the room accepts a connection
- [ ] If touching map / level scripts: respawn (`KillZone`) still fires and the player resets to spawn
- [ ] If touching mobile controls or responsive UI: tested on at least one phone-sized viewport
- [ ] If touching exports: an Android APK build still succeeds

## Screenshots / recordings
<!-- Required for gameplay, map, or UI changes. Drag files directly into this field. A 5-second screen recording beats a paragraph of description. -->

## Checklist
- [ ] Branched off the base branch specified in `CONTRIBUTING.md`
- [ ] Follows existing code patterns and style in the project
- [ ] Doesn't break the build (Godot project loads, no parse errors in the output panel)
- [ ] No unrelated changes bundled in (binary assets, generated `.uid` files, `.DS_Store`, etc.)
- [ ] If this introduces a new autoload, scene, or input action, `project.godot` is updated accordingly
