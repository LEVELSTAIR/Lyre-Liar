class_name Decoder
extends RefCounted

var _data: PackedByteArray
var _offset: int = 0
var _stream := StreamPeerBuffer.new()

func _init(data: PackedByteArray):
	_data = data
	_stream.big_endian = false  # Colyseus uses little-endian
	_stream.put_data(_data)
	_stream.seek(0)

# --- Raw typed decoders ---

func decode_boolean() -> bool:
	return _stream.get_u8() > 0

func decode_int8() -> int:
	return _stream.get_8()

func decode_uint8() -> int:
	return _stream.get_u8()

func decode_u8() -> int:
	return _stream.get_u8()

func decode_int16() -> int:
	return _stream.get_16()

func decode_uint16() -> int:
	return _stream.get_u16()

func decode_int32() -> int:
	return _stream.get_32()

func decode_uint32() -> int:
	return _stream.get_u32()

func decode_float32() -> float:
	return _stream.get_float()

func decode_float64() -> float:
	return _stream.get_double()

# --- Msgpack string decoding ---

func decode_string() -> String:
	var prefix = _stream.get_u8()
	var length: int = 0
	if prefix >= 0xA0 and prefix < 0xC0:
		length = prefix & 0x1F  # fixstr
	elif prefix == 0xD9:
		length = _stream.get_u8()  # str8
	elif prefix == 0xDA:
		length = _stream.get_u16()  # str16 LE
	elif prefix == 0xDB:
		length = _stream.get_u32()  # str32 LE
	else:
		return ""
	if length == 0:
		return ""
	var result = _stream.get_data(length)
	var bytes: PackedByteArray = result[1] if result is Array and result.size() > 1 else PackedByteArray()
	return bytes.get_string_from_utf8()

# --- Msgpack number decoding ---

func decode_number():
	var prefix = _stream.get_u8()
	if prefix < 0x80:
		return prefix  # positive fixint
	elif prefix == 0xCC:
		return _stream.get_u8()  # uint8
	elif prefix == 0xCD:
		return _stream.get_u16()  # uint16 LE
	elif prefix == 0xCE:
		return _stream.get_u32()  # uint32 LE
	elif prefix == 0xCF:
		return _stream.get_u64()  # uint64 LE
	elif prefix == 0xD0:
		return _stream.get_8()  # int8
	elif prefix == 0xD1:
		return _stream.get_16()  # int16 LE
	elif prefix == 0xD2:
		return _stream.get_32()  # int32 LE
	elif prefix == 0xD3:
		return _stream.get_64()  # int64 LE
	elif prefix == 0xCA:
		return _stream.get_float()  # float32 LE
	elif prefix == 0xCB:
		return _stream.get_double()  # float64 LE
	elif prefix >= 0xE0:
		return prefix - 256  # negative fixint
	return 0

# --- Position accessor ---

func get_position() -> int:
	return _stream.get_position()

# --- Legacy/utility ---

func decode_varint() -> int:
	var result := 0
	var shift := 0
	while true:
		var byte := _stream.get_u8()
		_offset += 1
		result |= (byte & 0x7F) << shift
		if (byte & 0x80) == 0:
			break
		shift += 7
	return result

# --- Msgpack string check (matches @colyseus/schema stringCheck) ---

static func string_check(data: PackedByteArray, offset: int) -> bool:
	var prefix := data[offset]
	return (prefix < 0xC0 and prefix > 0xA0) or prefix == 0xD9 or prefix == 0xDA or prefix == 0xDB

# --- Msgpack value decoding (standard big-endian, for ROOM_DATA payloads) ---
# Decodes arbitrary msgpack values matching msgpackr format (big-endian).
# Returns [value, new_offset].

static func decode_value(data: PackedByteArray, offset: int) -> Array:
	if offset >= data.size():
		return [null, offset]

	var prefix := data[offset]
	offset += 1

	# nil
	if prefix == 0xC0:
		return [null, offset]
	# false
	if prefix == 0xC2:
		return [false, offset]
	# true
	if prefix == 0xC3:
		return [true, offset]

	# positive fixint (0x00 - 0x7F)
	if prefix < 0x80:
		return [prefix, offset]

	# fixmap (0x80 - 0x8F)
	if prefix >= 0x80 and prefix < 0x90:
		return _decode_map_be(data, offset, prefix & 0x0F)

	# fixarray (0x90 - 0x9F)
	if prefix >= 0x90 and prefix < 0xA0:
		return _decode_array_be(data, offset, prefix & 0x0F)

	# fixstr (0xA0 - 0xBF)
	if prefix >= 0xA0 and prefix < 0xC0:
		var length := prefix & 0x1F
		var str_val := data.slice(offset, offset + length).get_string_from_utf8()
		return [str_val, offset + length]

	# uint8
	if prefix == 0xCC:
		return [data[offset], offset + 1]
	# uint16 BE
	if prefix == 0xCD:
		var val := (data[offset] << 8) | data[offset + 1]
		return [val, offset + 2]
	# uint32 BE
	if prefix == 0xCE:
		var val := (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
		return [val, offset + 4]
	# uint64 BE
	if prefix == 0xCF:
		var val := 0
		for i in 8:
			val = (val << 8) | data[offset + i]
		return [val, offset + 8]

	# float32 BE
	if prefix == 0xCA:
		var bytes_le := PackedByteArray([data[offset + 3], data[offset + 2], data[offset + 1], data[offset]])
		var s := StreamPeerBuffer.new()
		s.big_endian = false
		s.put_data(bytes_le)
		s.seek(0)
		return [s.get_float(), offset + 4]
	# float64 BE
	if prefix == 0xCB:
		var bytes_le := PackedByteArray([data[offset + 7], data[offset + 6], data[offset + 5], data[offset + 4],
			data[offset + 3], data[offset + 2], data[offset + 1], data[offset]])
		var s := StreamPeerBuffer.new()
		s.big_endian = false
		s.put_data(bytes_le)
		s.seek(0)
		return [s.get_double(), offset + 8]

	# int8
	if prefix == 0xD0:
		var val := data[offset]
		if val >= 128:
			val -= 256
		return [val, offset + 1]
	# int16 BE
	if prefix == 0xD1:
		var val := (data[offset] << 8) | data[offset + 1]
		if val >= 32768:
			val -= 65536
		return [val, offset + 2]
	# int32 BE
	if prefix == 0xD2:
		var val := (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
		return [val, offset + 4]
	# int64 BE
	if prefix == 0xD3:
		var val := 0
		for i in 8:
			val = (val << 8) | data[offset + i]
		# Sign extend
		if val >= (1 << 63):
			val -= (1 << 64)
		return [val, offset + 8]

	# str8
	if prefix == 0xD9:
		var length := data[offset]
		offset += 1
		var str_val := data.slice(offset, offset + length).get_string_from_utf8()
		return [str_val, offset + length]
	# str16 BE
	if prefix == 0xDA:
		var length := (data[offset] << 8) | data[offset + 1]
		offset += 2
		var str_val := data.slice(offset, offset + length).get_string_from_utf8()
		return [str_val, offset + length]
	# str32 BE
	if prefix == 0xDB:
		var length := (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
		offset += 4
		var str_val := data.slice(offset, offset + length).get_string_from_utf8()
		return [str_val, offset + length]

	# array16 BE
	if prefix == 0xDC:
		var count := (data[offset] << 8) | data[offset + 1]
		return _decode_array_be(data, offset + 2, count)
	# array32 BE
	if prefix == 0xDD:
		var count := (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
		return _decode_array_be(data, offset + 4, count)

	# map16 BE
	if prefix == 0xDE:
		var count := (data[offset] << 8) | data[offset + 1]
		return _decode_map_be(data, offset + 2, count)
	# map32 BE
	if prefix == 0xDF:
		var count := (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3]
		return _decode_map_be(data, offset + 4, count)

	# negative fixint (0xE0 - 0xFF)
	if prefix >= 0xE0:
		return [prefix - 256, offset]

	# Unknown prefix — skip
	return [null, offset]

static func _decode_map_be(data: PackedByteArray, offset: int, count: int) -> Array:
	var dict := {}
	for i in count:
		var key_result := decode_value(data, offset)
		offset = key_result[1]
		var val_result := decode_value(data, offset)
		offset = val_result[1]
		dict[key_result[0]] = val_result[0]
	return [dict, offset]

static func _decode_array_be(data: PackedByteArray, offset: int, count: int) -> Array:
	var arr := []
	for i in count:
		var result := decode_value(data, offset)
		offset = result[1]
		arr.append(result[0])
	return [arr, offset]
