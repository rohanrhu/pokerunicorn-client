# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Object
class_name SynchronousWebSocketStream

var socket: WebSocketPeer
var buffer: PackedByteArray = []
var is_connected_to_server := false

var put_buffer: PackedByteArray = []

var poll_delay := Config.WS_POLL_DELAY

var close_code: int
var close_reason: String

func _init():
	socket = WebSocketPeer.new()
	socket.outbound_buffer_size = 2000000
	socket.inbound_buffer_size = 2000000
	socket.max_queued_packets = 4096

func connect_to_url(p_url: String) -> Error:
	var err := socket.connect_to_url(p_url, TLSOptions.client_unsafe())
	if err != OK:
		printerr(err)
	return err

func poll() -> void:
	print("ws.poll()")
	
	socket.poll()
	
	var state := socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		is_connected_to_server = true
		
		if socket.get_available_packet_count():
			var bytes := socket.get_packet()
			buffer.append_array(bytes)
	elif state == WebSocketPeer.STATE_CLOSING:
		is_connected_to_server = false
	elif state == WebSocketPeer.STATE_CLOSED:
		is_connected_to_server = false
		close_code = socket.get_close_code()
		close_reason = socket.get_close_reason()
	
	if not is_connected_to_server:
		var error = socket.get_packet_error()
		if error != 0:
			print("WS Packet Error: ", error)

func get_bytes(size: int) -> PackedByteArray:
	var poll_time = 0
	
	while true:
		if buffer.size() >= size:
			break
		
		if (Time.get_ticks_msec() - poll_time) < poll_delay:
			continue
		
		socket.poll()
		
		if not is_connected_to_server:
			return []
		
		if socket.get_available_packet_count() > 0:
			var bytes := socket.get_packet()
			buffer.append_array(bytes)
		
		poll_time = Time.get_ticks_msec()
	
	var bytes: PackedByteArray = buffer.slice(0, size)
	buffer = buffer.slice(size)
	
	return bytes

# Receivers

func get_data(size: int) -> Array:
	var bytes = get_bytes(size)
	return [bytes.size(), bytes]

func get_u8() -> int:
	return get_bytes(1).decode_u8(0)

func get_u16() -> int:
	return get_bytes(2).decode_u16(0)

func get_u32() -> int:
	return get_bytes(4).decode_u32(0)

func get_u64() -> int:
	return get_bytes(8).decode_u64(0)

func get_8() -> int:
	return get_bytes(1).decode_s8(0)

func get_16() -> int:
	return get_bytes(2).decode_s16(0)

func get_32() -> int:
	return get_bytes(4).decode_s32(0)

func get_64() -> int:
	return get_bytes(8).decode_s64(0)

func send_bytes(bytes: PackedByteArray) -> void:
	print("send_bytes(): ", bytes.size(), " bytes")
	socket.send(bytes)

# Senders

func begin_put() -> void:
	put_buffer.clear()

func end_put() ->void:
	send_bytes(put_buffer.duplicate())

func put_data(data: PackedByteArray) -> void:
	put_buffer.append_array(data)

func put_u8(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(1)
	vector.encode_u8(0, scalar)
	print("put_u8(): ", vector)
	put_buffer.append_array(vector)

func put_u16(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(2)
	vector.encode_u16(0, scalar)
	print("put_u16(): ", vector)
	put_buffer.append_array(vector)

func put_u32(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(4)
	vector.encode_u32(0, scalar)
	print("put_u32(): ", vector)
	put_buffer.append_array(vector)

func put_u64(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(8)
	vector.encode_u64(0, scalar)
	print("put_u64(): ", vector)
	put_buffer.append_array(vector)

func put_8(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(1)
	vector.encode_s8(0, scalar)
	put_buffer.append_array(vector)

func put_16(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(2)
	vector.encode_s16(0, scalar)
	put_buffer.append_array(vector)

func put_32(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(4)
	vector.encode_s32(0, scalar)
	put_buffer.append_array(vector)

func put_64(scalar: int) -> void:
	var vector := PackedByteArray()
	vector.resize(8)
	vector.encode_s64(0, scalar)
	put_buffer.append_array(vector)
