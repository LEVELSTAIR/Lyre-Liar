@tool
extends EditorPlugin

## Godot MCP Plugin - Provides Model Context Protocol integration for Claude Code
## Enables AI assistance by exposing project resources through MCP

var mcp_server: MCPServer
var resources_cache: Dictionary = {}

func _enter_tree() -> void:
	print("[Godot MCP] Plugin loaded")
	mcp_server = MCPServer.new()
	mcp_server.plugin = self
	add_autoload_singleton("GodotMCP", mcp_server)
	_scan_project_resources()

func _exit_tree() -> void:
	print("[Godot MCP] Plugin unloaded")
	if mcp_server:
		mcp_server.queue_free()
	remove_autoload_singleton("GodotMCP")

func _scan_project_resources() -> void:
	"""Scan project for GDScript files, scenes, and resources"""
	resources_cache.clear()
	_scan_directory("res://")

func _scan_directory(path: String) -> void:
	"""Recursively scan directory for project files"""
	var dir = DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path = path + file_name

		if dir.current_is_dir():
			_scan_directory(full_path + "/")
		else:
			# Index GDScript, scene, and resource files
			if file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
				resources_cache[full_path] = {
					"name": file_name,
					"type": "file",
					"path": full_path
				}

		file_name = dir.get_next()

func get_project_resources() -> Dictionary:
	"""Return cached project resources"""
	return resources_cache

func read_resource(path: String) -> String:
	"""Read file content by path"""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

class MCPServer:
	extends Node

	var plugin: EditorPlugin

	func _ready() -> void:
		print("[Godot MCP] Server initialized")

	func list_resources() -> Array:
		"""List all project resources for MCP"""
		var resources = []
		for path in plugin.get_project_resources():
			var resource = plugin.resources_cache[path]
			resources.append({
				"uri": "godot://" + path,
				"name": resource.name,
				"type": resource.type
			})
		return resources

	func read_resource(uri: String) -> String:
		"""Read resource content by URI"""
		var path = uri.trim_prefix("godot://")
		return plugin.read_resource(path)
