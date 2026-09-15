class_name PhysicsLayers
extends RefCounted

## Bit values for the 2D physics layers named in project.godot
## (layer_names/2d_physics). Use these instead of magic numbers.

const WORLD := 1 << 0
const PLAYER := 1 << 1
const ENEMIES := 1 << 2
const HAZARDS := 1 << 3
const PICKUPS := 1 << 4
const TRIGGERS := 1 << 5
