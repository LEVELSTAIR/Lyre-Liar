class_name StateMachine
extends Node

## Delegates process, physics, and input callbacks to the active child State
## and performs transitions by state node name.

signal state_changed(previous_state: StringName, new_state: StringName)

@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.state_machine = self
	if initial_state == null:
		push_error("StateMachine '%s' has no initial_state" % get_path())
		return
	# Wait for the owner to finish _ready so states can use its @onready nodes.
	if owner != null and not owner.is_node_ready():
		await owner.ready
	current_state = initial_state
	current_state.enter(&"")


func _process(delta: float) -> void:
	if current_state:
		_try_transition(current_state.update(delta))


func _physics_process(delta: float) -> void:
	if current_state:
		_try_transition(current_state.physics_update(delta))


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		_try_transition(current_state.handle_input(event))


func transition_to(state_name: StringName) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: unknown state '%s'" % state_name)
		return
	var previous_name: StringName = current_state.name if current_state else &""
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter(previous_name)
	state_changed.emit(previous_name, state_name)


func is_in(state_name: StringName) -> bool:
	return current_state != null and current_state.name == state_name


func _try_transition(next_state: StringName) -> void:
	if next_state != &"" and (current_state == null or next_state != current_state.name):
		transition_to(next_state)
