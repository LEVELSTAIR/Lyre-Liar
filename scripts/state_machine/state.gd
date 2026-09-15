class_name State
extends Node

## Base class for node-based state machine states. The StateMachine calls
## these hooks on the active state only. `update`, `physics_update`, and
## `handle_input` return the name of the next state, or an empty StringName
## to stay in the current one.

var state_machine: StateMachine


func enter(_previous_state: StringName) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> StringName:
	return &""


func physics_update(_delta: float) -> StringName:
	return &""


func handle_input(_event: InputEvent) -> StringName:
	return &""
