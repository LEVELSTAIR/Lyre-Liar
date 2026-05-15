class_name Schema
extends RefCounted

# Operations
const OP_ADD := 128
const OP_REPLACE := 0
const OP_DELETE := 64
const OP_DELETE_AND_ADD := 192
const OP_CLEAR := 10
const SWITCH_TO_STRUCTURE := 255
const TYPE_ID := 213

# Field definition: index -> {name, type}
var _fields_by_index := {}
var _fields_by_name := {}

# Ref tracking for nested structures
var _refs := {}  # refId -> ref object

# Schema type factories for nested schemas
var _schema_types := {}  # schema_name -> Callable factory
var _schema_type_ids := {}  # type_id (int) -> schema_name

func _init():
	pass

func is_collection() -> bool:
	return false

func is_map_collection() -> bool:
	return false

func get_child_type() -> String:
	return ""

# Default values for reset on DELETE
var _defaults := {}

# Property-level callbacks: field_name -> Array[Callable]
var _prop_callbacks: Dictionary = {}

# Schema-level change callbacks: fire when any property changes (no args)
var _change_callbacks: Array = []

func on_change(callback: Callable) -> Callable:
	_change_callbacks.append(callback)
	return func(): _change_callbacks.erase(callback)

func listen(prop: String, callback: Callable, immediate: bool = true) -> Callable:
	if prop not in _prop_callbacks:
		_prop_callbacks[prop] = []
	_prop_callbacks[prop].append(callback)
	if immediate and prop in _fields_by_name and get(prop) != null:
		callback.call(get(prop), null)
	return func(): _prop_callbacks[prop].erase(callback)

func register_schema_type(schema_name: String, factory: Callable, type_id: int = -1) -> void:
	_schema_types[schema_name] = factory
	if type_id >= 0:
		_schema_type_ids[type_id] = schema_name

func _define_field(index: int, name: String, type: String) -> void:
	_fields_by_index[index] = {"name": name, "type": type}
	_fields_by_name[name] = {"index": index, "type": type}
	_defaults[name] = get(name)

# --- Binary decode ---
# Decodes @colyseus/schema binary format.
#
# Two encoding modes:
#   Schema fields: byte = operation | field_index (compressed single byte)
#   Collection items: operation = full byte, field_index = msgpack number
#
# SWITCH_TO_STRUCTURE (255) switches decode context to a nested ref.

func decode(bytes: PackedByteArray, it: Dictionary = {"offset": 0}) -> Array:
	var changes := []
	var total_bytes := bytes.size()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_data(bytes)
	stream.seek(it.offset)

	# Root schema is always refId=0
	_refs[0] = self
	var ref: RefCounted = self

	while stream.get_position() < total_bytes:
		var byte := stream.get_u8()

		# SWITCH_TO_STRUCTURE: change decode context
		if byte == SWITCH_TO_STRUCTURE:
			var ref_id = _decode_msgpack_number(stream)
			ref = _refs.get(ref_id)
			if ref == null:
				push_error("Schema: refId %d not found" % ref_id)
				break
			continue

		var is_schema: bool = not ref.is_collection()

		if is_schema:
			_decode_schema_field(stream, ref, byte, changes)
		else:
			_decode_collection_item(stream, ref, byte, changes)

	it.offset = stream.get_position()
	return changes

# --- Schema field decode (compressed byte) ---

func _decode_schema_field(stream: StreamPeerBuffer, ref: RefCounted, byte: int, changes: Array) -> void:
	var operation := (byte >> 6) << 6
	var field_index: int
	if operation == OP_REPLACE:
		field_index = byte % 255
	else:
		field_index = byte % operation

	var field_def = ref._fields_by_index.get(field_index)
	if field_def == null:
		return

	var field_name: String = field_def.name
	var field_type: String = field_def.type

	# DELETE (pure)
	if operation == OP_DELETE:
		var previous = ref.get(field_name)
		ref.set(field_name, ref._defaults.get(field_name))
		changes.append({"op": "delete", "field": field_name, "previous": previous, "ref": ref})
		return

	# DELETE_AND_ADD: reset then fall through
	if operation == OP_DELETE_AND_ADD:
		ref.set(field_name, ref._defaults.get(field_name))

	# Check for direct ref field (nested child schema)
	if field_type.begins_with("ref:"):
		var schema_name := field_type.substr(4)

		# Check for TYPE_ID (polymorphic type marker)
		var peek_pos := stream.get_position()
		var peek_byte := stream.get_u8()
		if peek_byte == TYPE_ID:
			var tid = _decode_msgpack_number(stream)
			var resolved_name = _schema_type_ids.get(tid, schema_name)
			schema_name = resolved_name
		else:
			stream.seek(peek_pos)

		var ref_id = _decode_msgpack_number(stream)
		var child_schema = null

		if (operation & OP_ADD) == OP_ADD:
			var factory = _schema_types.get(schema_name)
			if factory:
				child_schema = factory.call()
				_refs[ref_id] = child_schema
			else:
				push_error("Schema: no factory registered for '%s'" % schema_name)
		else:
			child_schema = _refs.get(ref_id, ref.get(field_name))
			if child_schema:
				_refs[ref_id] = child_schema

		ref.set(field_name, child_schema)
		var op_name := "add" if (operation & OP_ADD) == OP_ADD else "replace"
		changes.append({"op": op_name, "field": field_name, "value": child_schema, "ref": ref})
		return

	# Check for collection types
	var is_collection_type := (
		field_type.begins_with("array:")
		or field_type.begins_with("map:")
		or field_type.begins_with("set:")
		or field_type.begins_with("collection:")
	)
	if is_collection_type:
		var ref_id = _decode_msgpack_number(stream)
		var child_type := field_type.substr(field_type.find(":") + 1)
		var collection: RefCounted

		if (operation & OP_ADD) == OP_ADD:
			if field_type.begins_with("array:"):
				collection = ArraySchema.new(child_type)
			elif field_type.begins_with("map:"):
				collection = MapSchema.new(child_type)
			elif field_type.begins_with("set:"):
				collection = SetSchema.new(child_type)
			else:
				collection = CollectionSchema.new(child_type)
			_refs[ref_id] = collection
		else:
			collection = _refs.get(ref_id, ref.get(field_name))
			if collection:
				_refs[ref_id] = collection

		ref.set(field_name, collection)
		var op_name := "add" if (operation & OP_ADD) == OP_ADD else "replace"
		changes.append({"op": op_name, "field": field_name, "value": collection, "ref": ref})
		return

	# Primitive value
	var value = _decode_value(stream, field_type)
	var previous = ref.get(field_name)
	ref.set(field_name, value)
	var op_name := "add" if (operation & OP_ADD) == OP_ADD else "replace"
	changes.append({"op": op_name, "field": field_name, "value": value, "previous": previous, "ref": ref})

# --- Collection item decode (full byte operation) ---

func _decode_collection_item(stream: StreamPeerBuffer, ref: RefCounted, operation: int, changes: Array) -> void:
	# CLEAR
	if operation == OP_CLEAR:
		ref.clear_items()
		changes.append({"op": "clear", "ref": ref})
		return

	# Field index is a separate msgpack number
	var field_index = _decode_msgpack_number(stream)

	var is_map: bool = ref.is_map_collection()

	# ADD: for maps, read key string
	if (operation & OP_ADD) == OP_ADD:
		if is_map:
			var key := _decode_msgpack_string(stream)
			ref.set_index(field_index, key)

	# DELETE
	if (operation & OP_DELETE) == OP_DELETE:
		if operation != OP_DELETE_AND_ADD:
			var previous = null
			var key = null
			if is_map:
				key = ref.get_index(field_index)
				previous = ref.get_item(key) if key != "" else null
				ref.delete_by_index(field_index)
			else:
				previous = ref.get_item(field_index)
				ref.delete_at(field_index)
			var change := {"op": "delete", "field_index": field_index, "ref": ref, "previous": previous}
			if key != null:
				change["key"] = key
			changes.append(change)
			return
		if operation == OP_DELETE:
			return

	# Decode value using collection's child type
	var child_type: String = ref.get_child_type()
	var value

	if child_type.begins_with("ref:"):
		# Schema ref: check for TYPE_ID (polymorphic type marker)
		var schema_name := child_type.substr(4)
		var peek_pos := stream.get_position()
		var peek_byte := stream.get_u8()
		if peek_byte == TYPE_ID:
			# Polymorphic: read type_id and resolve schema name
			var tid = _decode_msgpack_number(stream)
			var resolved_name = _schema_type_ids.get(tid, schema_name)
			schema_name = resolved_name
		else:
			# Not TYPE_ID — rewind, it's the refId
			stream.seek(peek_pos)

		var child_ref_id = _decode_msgpack_number(stream)
		if (operation & OP_ADD) == OP_ADD:
			var factory = _schema_types.get(schema_name)
			if factory:
				value = factory.call()
				_refs[child_ref_id] = value
			else:
				push_error("Schema: no factory registered for '%s'" % schema_name)
		else:
			value = _refs.get(child_ref_id)
	else:
		value = _decode_value(stream, child_type)

	if is_map:
		ref.set_by_index(field_index, value)
	else:
		ref.set_at(field_index, value)

	var op_name := "add" if (operation & OP_ADD) == OP_ADD else "replace"
	var change := {"op": op_name, "field_index": field_index, "value": value, "ref": ref}
	if is_map:
		change["key"] = ref.get_index(field_index)
	changes.append(change)

# --- Value decoders ---

func _decode_value(stream: StreamPeerBuffer, type: String):
	match type:
		"uint8":
			return stream.get_u8()
		"int8":
			return stream.get_8()
		"uint16":
			return stream.get_u16()
		"int16":
			return stream.get_16()
		"uint32":
			return stream.get_u32()
		"int32":
			return stream.get_32()
		"float32":
			return stream.get_float()
		"float64":
			return stream.get_double()
		"boolean":
			return stream.get_u8() > 0
		"string":
			return _decode_msgpack_string(stream)
		"number":
			return _decode_msgpack_number(stream)
		_:
			push_error("Schema: unknown field type '%s'" % type)
			return null

func _decode_msgpack_string(stream: StreamPeerBuffer) -> String:
	var prefix := stream.get_u8()
	var length: int = 0
	if prefix >= 0xA0 and prefix < 0xC0:
		length = prefix & 0x1F
	elif prefix == 0xD9:
		length = stream.get_u8()
	elif prefix == 0xDA:
		length = stream.get_u16()
	elif prefix == 0xDB:
		length = stream.get_u32()
	else:
		return ""
	if length == 0:
		return ""
	var result = stream.get_data(length)
	var bytes: PackedByteArray = result[1] if result is Array and result.size() > 1 else PackedByteArray()
	return bytes.get_string_from_utf8()

func _decode_msgpack_number(stream: StreamPeerBuffer):
	var prefix := stream.get_u8()
	if prefix < 0x80:
		return prefix
	elif prefix == 0xCC:
		return stream.get_u8()
	elif prefix == 0xCD:
		return stream.get_u16()
	elif prefix == 0xCE:
		return stream.get_u32()
	elif prefix == 0xCF:
		return stream.get_u64()
	elif prefix == 0xD0:
		return stream.get_8()
	elif prefix == 0xD1:
		return stream.get_16()
	elif prefix == 0xD2:
		return stream.get_32()
	elif prefix == 0xD3:
		return stream.get_64()
	elif prefix == 0xCA:
		return stream.get_float()
	elif prefix == 0xCB:
		return stream.get_double()
	elif prefix >= 0xE0:
		return prefix - 256
	return 0
