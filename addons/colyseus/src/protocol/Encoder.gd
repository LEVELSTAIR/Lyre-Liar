class_name Encoder
extends RefCounted

var _buffer = PackedByteArray()
var _stream := StreamPeerBuffer.new()

func _init():
	_stream.big_endian = false  # Colyseus uses little-endian

# --- Raw typed encoders (no type tag prefix) ---
# These match @colyseus/schema's encoder: just the raw value bytes.

func encode_boolean(value: bool) -> void:
	_stream.put_u8(1 if value else 0)

func encode_int8(value: int) -> void:
	_stream.put_8(value)

func encode_uint8(value: int) -> void:
	_stream.put_u8(value)

func encode_int16(value: int) -> void:
	_stream.put_16(value)

func encode_uint16(value: int) -> void:
	_stream.put_u16(value)

func encode_int32(value: int) -> void:
	_stream.put_32(value)

func encode_uint32(value: int) -> void:
	_stream.put_u32(value)

func encode_float32(value: float) -> void:
	_stream.put_float(value)

func encode_float64(value: float) -> void:
	_stream.put_double(value)

# --- Msgpack string encoding ---
# fixstr (len < 32):   0xA0 | len, then UTF-8 bytes
# str8 (len < 256):    0xD9, uint8 len, then UTF-8 bytes
# str16 (len < 65536): 0xDA, uint16 LE len, then UTF-8 bytes
# str32:               0xDB, uint32 LE len, then UTF-8 bytes

func encode_string(value: String) -> void:
	var bytes = value.to_utf8_buffer()
	var length = bytes.size()
	if length < 32:
		_stream.put_u8(0xA0 | length)
	elif length < 256:
		_stream.put_u8(0xD9)
		_stream.put_u8(length)
	elif length < 65536:
		_stream.put_u8(0xDA)
		_stream.put_u16(length)
	else:
		_stream.put_u8(0xDB)
		_stream.put_u32(length)
	if length > 0:
		_stream.put_data(bytes)

# --- Msgpack number encoding ---
# positive fixint (0-127):    value as single byte
# uint8 (128-255):            0xCC + 1 byte
# uint16 (256-65535):         0xCD + 2 bytes LE
# uint32 (65536-2^32-1):      0xCE + 4 bytes LE
# negative fixint (-32 to -1): 0xE0 | (value + 0x20)
# int8 (-128 to -33):         0xD0 + 1 byte
# int16 (-32768 to -129):     0xD1 + 2 bytes LE
# int32:                      0xD2 + 4 bytes LE
# float64:                    0xCB + 8 bytes LE

func encode_number(value) -> void:
	if value is float and value != int(value):
		_stream.put_u8(0xCB)
		_stream.put_double(value)
	elif value >= 0:
		if value < 128:
			_stream.put_u8(value)
		elif value < 256:
			_stream.put_u8(0xCC)
			_stream.put_u8(value)
		elif value < 65536:
			_stream.put_u8(0xCD)
			_stream.put_u16(value)
		elif value < 4294967296:
			_stream.put_u8(0xCE)
			_stream.put_u32(value)
		else:
			_stream.put_u8(0xCF)
			_stream.put_u64(value)
	else:
		if value >= -32:
			_stream.put_u8(0xE0 | (value + 0x20))
		elif value >= -128:
			_stream.put_u8(0xD0)
			_stream.put_8(value)
		elif value >= -32768:
			_stream.put_u8(0xD1)
			_stream.put_16(value)
		elif value >= -2147483648:
			_stream.put_u8(0xD2)
			_stream.put_32(value)
		else:
			_stream.put_u8(0xD3)
			_stream.put_64(value)

# --- Legacy/utility ---

func encode_varint(value: int) -> void:
	while true:
		var byte = value & 0x7F
		value >>= 7
		if value != 0:
			byte |= 0x80
		_stream.put_u8(byte)
		if value == 0:
			break

func get_data() -> PackedByteArray:
	_stream.seek(0)
	var size = _stream.get_available_bytes()
	return _stream.get_data(size)[1]

# --- Msgpack value encoding (standard big-endian, for ROOM_DATA payloads) ---
# These encode arbitrary Variant values using standard msgpack format (big-endian
# multi-byte values), matching msgpackr used by real Colyseus servers.

static func encode_value(value) -> PackedByteArray:
	var buf := PackedByteArray()
	_encode_value_into(buf, value)
	return buf

static func _encode_value_into(buf: PackedByteArray, value) -> void:
	if value == null:
		buf.append(0xC0)
	elif value is bool:
		buf.append(0xC3 if value else 0xC2)
	elif value is int:
		_encode_int_be(buf, value)
	elif value is float:
		_encode_float64_be(buf, value)
	elif value is String:
		_encode_string_be(buf, value)
	elif value is Dictionary:
		_encode_map_be(buf, value)
	elif value is Array:
		_encode_array_be(buf, value)
	else:
		buf.append(0xC0)  # unknown → null

static func _encode_int_be(buf: PackedByteArray, value: int) -> void:
	if value >= 0:
		if value < 128:
			buf.append(value)
		elif value < 256:
			buf.append(0xCC)
			buf.append(value)
		elif value < 65536:
			buf.append(0xCD)
			buf.append((value >> 8) & 0xFF)
			buf.append(value & 0xFF)
		elif value < 4294967296:
			buf.append(0xCE)
			buf.append((value >> 24) & 0xFF)
			buf.append((value >> 16) & 0xFF)
			buf.append((value >> 8) & 0xFF)
			buf.append(value & 0xFF)
		else:
			buf.append(0xCF)
			for i in range(7, -1, -1):
				buf.append((value >> (i * 8)) & 0xFF)
	else:
		if value >= -32:
			buf.append(0xE0 | (value + 0x20))
		elif value >= -128:
			buf.append(0xD0)
			buf.append(value & 0xFF)
		elif value >= -32768:
			buf.append(0xD1)
			buf.append((value >> 8) & 0xFF)
			buf.append(value & 0xFF)
		elif value >= -2147483648:
			buf.append(0xD2)
			buf.append((value >> 24) & 0xFF)
			buf.append((value >> 16) & 0xFF)
			buf.append((value >> 8) & 0xFF)
			buf.append(value & 0xFF)
		else:
			buf.append(0xD3)
			for i in range(7, -1, -1):
				buf.append((value >> (i * 8)) & 0xFF)

static func _encode_float64_be(buf: PackedByteArray, value: float) -> void:
	buf.append(0xCB)
	# Encode float64 via StreamPeerBuffer (little-endian), then reverse to big-endian
	var s := StreamPeerBuffer.new()
	s.big_endian = false
	s.put_double(value)
	s.seek(0)
	var bytes: PackedByteArray = s.get_data(8)[1]
	for i in range(7, -1, -1):
		buf.append(bytes[i])

static func _encode_string_be(buf: PackedByteArray, value: String) -> void:
	var utf8 := value.to_utf8_buffer()
	var length := utf8.size()
	if length < 32:
		buf.append(0xA0 | length)
	elif length < 256:
		buf.append(0xD9)
		buf.append(length)
	elif length < 65536:
		buf.append(0xDA)
		buf.append((length >> 8) & 0xFF)
		buf.append(length & 0xFF)
	else:
		buf.append(0xDB)
		buf.append((length >> 24) & 0xFF)
		buf.append((length >> 16) & 0xFF)
		buf.append((length >> 8) & 0xFF)
		buf.append(length & 0xFF)
	buf.append_array(utf8)

static func _encode_map_be(buf: PackedByteArray, dict: Dictionary) -> void:
	var count := dict.size()
	if count < 16:
		buf.append(0x80 | count)
	elif count < 65536:
		buf.append(0xDE)
		buf.append((count >> 8) & 0xFF)
		buf.append(count & 0xFF)
	else:
		buf.append(0xDF)
		buf.append((count >> 24) & 0xFF)
		buf.append((count >> 16) & 0xFF)
		buf.append((count >> 8) & 0xFF)
		buf.append(count & 0xFF)
	for key in dict:
		_encode_value_into(buf, key)
		_encode_value_into(buf, dict[key])

static func _encode_array_be(buf: PackedByteArray, arr: Array) -> void:
	var count := arr.size()
	if count < 16:
		buf.append(0x90 | count)
	elif count < 65536:
		buf.append(0xDC)
		buf.append((count >> 8) & 0xFF)
		buf.append(count & 0xFF)
	else:
		buf.append(0xDD)
		buf.append((count >> 24) & 0xFF)
		buf.append((count >> 16) & 0xFF)
		buf.append((count >> 8) & 0xFF)
		buf.append(count & 0xFF)
	for item in arr:
		_encode_value_into(buf, item)
