# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name PokerClient

signal over_capacity
signal connected
signal disconnected
signal pong
signal server_info(server_info: TPacket.TServerInfo)
signal login_res(login_res: TPacket.TLoginRes)
signal signup_res(signup_res: TPacket.TSignupRes)
signal account(account: TPacket.TAccount)
signal enter_res(enter_res: TPacket.TEnterRes)
signal leave_res(leave_res: TPacket.TLeaveRes)
signal join_res(join_res: TPacket.TJoinRes)
signal unjoin_res(unjoin_res: TPacket.TUnjoinRes)
signal poker_info(poker_info: TPacket.TPokerInfo)
signal poker_state(poker_state: TPacket.TPokerState)
signal poker_action_reflection(poker_action_reflection: TPacket.TPokerActionReflection)
signal poker_end(poker_end: TPacket.TPokerEnd)
signal poker_restarted(poker_restarted: TPacket.TPokerRestarted)
signal unjoined(unjoined: TPacket.TUnjoined)
signal tables(tables: TPacket.TTables)
signal sessions(sessions: TPacket.TSessions)
signal update_account_res(update_account_res: TPacket.TUpdateAccountRes)

@onready var nConnecting = %Connecting
@onready var nOverCapacity = %OverCapacity

var socket: StreamPeerTCP = null
var tls: StreamPeerTLS = null
var cert: X509Certificate = null
var ws: SynchronousWebSocketStream = null

@onready var listen_thread := Thread.new()
@onready var mutex := Mutex.new()

var tcp_status: StreamPeerTCP.Status = StreamPeerTCP.STATUS_NONE
var tls_status: StreamPeerTLS.Status = StreamPeerTLS.STATUS_DISCONNECTED

@export var poll_delay: int = Config.WS_POLL_DELAY
@export var try_delay = 500
@export var reconnection_interval = 3
@export var ws_fragmentation_size = 10000

var is_tcp_connected := false
var is_tls_handshaked := false
var is_connected_to_server := false

var reconnect_timer: Timer

var host: String
var port: int
var is_websocket := false
var is_expect_connection := false

var stream:
	get:
		if is_websocket:
			return ws
		else:
			return tls

func _ready() -> void:
	is_websocket = Platform.is_web()
	
	nConnecting.show()
	nOverCapacity.hide()
	
	cert = X509Certificate.new()
	cert.load("res://ssl/test.crt")
	
	reconnect_timer = Timer.new()
	reconnect_timer.one_shot = true
	add_child(reconnect_timer)
	reconnect_timer.wait_time = reconnection_interval
	reconnect_timer.timeout.connect(_reconnect)
 
func _listen_thread_f__ws() -> void:
	var poll_time = 0
	
	while true:
		if (Time.get_ticks_msec() - poll_time) < poll_delay:
			continue
		
		mutex.lock()
		
		ws.poll()
		
		if (ws.socket.get_ready_state() == WebSocketPeer.STATE_CLOSED) || (is_connected_to_server && !ws.is_connected_to_server):
			is_connected_to_server = false
			call_deferred("_on_disconnected")
			mutex.unlock()
			break
		
		if !is_connected_to_server && ws.is_connected_to_server:
			is_connected_to_server = true
			call_deferred("_on_connected")
			mutex.unlock()
			poll_time = Time.get_ticks_msec()
			continue
		
		if is_connected_to_server && !ws.is_connected_to_server:
			is_connected_to_server = false
			call_deferred("_on_disconnected")
			mutex.unlock()
			break
		
		if !is_connected_to_server:
			mutex.unlock()
			poll_time = Time.get_ticks_msec()
			continue
		
		print("Receive loop: WS: status: ", ws.socket.get_ready_state())
		
		var opcode = ws.get_u32()
		var length = ws.get_u32()

		print("HEADER receivedddddd")
		print("TPacket.OPCODE: " + str(opcode))

		_handle_opcode(opcode)
		
		mutex.unlock()
		
		poll_time = Time.get_ticks_msec()

func _listen_thread_f() -> void:
	var poll_time = 0
	
	while true:
		mutex.lock()
		
		if !socket or !tls:
			mutex.unlock()
			continue
		
		if socket.get_status() == StreamPeerTCP.STATUS_CONNECTING:
			socket.poll()
			mutex.unlock()
			continue
		elif is_connected_to_server and (Time.get_ticks_msec() - poll_time) > poll_delay:
			socket.poll()
			tls.poll()
			poll_time = Time.get_ticks_msec()
		
		if  (
				is_tcp_connected and
				(socket.get_status() in [StreamPeerTCP.STATUS_ERROR, StreamPeerTCP.STATUS_NONE])
			) or \
			stream.get_status() > StreamPeerTLS.STATUS_CONNECTED \
		:
			is_tcp_connected = false
			is_tls_handshaked = false
			is_connected_to_server = false
			
			call_deferred("_on_disconnected")
			
			mutex.unlock()
			
			break
		elif !is_tcp_connected and socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			is_tcp_connected = true
			
			var err := tls.connect_to_stream(socket, "", TLSOptions.client_unsafe())
			if err != OK:
				print("SSL handshake failed: ", err)
				
				is_tcp_connected = false
				is_connected_to_server = false
				
				tls.disconnect_from_stream()
				socket.disconnect_from_host()
				
				call_deferred("_on_disconnected")
				
				mutex.unlock()
				
				break
			
			mutex.unlock()
			
			continue
		elif !is_tls_handshaked and stream.get_status() == StreamPeerTLS.STATUS_CONNECTED:
			is_tls_handshaked = true
			is_connected_to_server = true
			
			call_deferred("_on_connected")
		elif stream.get_status() == StreamPeerTLS.STATUS_HANDSHAKING:
			tls.poll()
			mutex.unlock()
			
			continue
		
		var opcode = stream.get_u32()
		var length = stream.get_u32()

		print("Receive loop: TCP: ", socket.get_status(), " - SSL: ", stream.get_status())
		print("HEADER receivedddddd")
		print("TPacket.OPCODE: " + str(opcode))
		
		_handle_opcode(opcode)
		
		mutex.unlock()

func _handle_opcode(opcode: int) -> void:
	match opcode:
		TPacket.OPCODE.PONG:
			_receive_pong()
		TPacket.OPCODE.SERVER_INFO:
			_receive_server_info()
		TPacket.OPCODE.LOGIN_RES:
			_receive_login_res()
		TPacket.OPCODE.SIGNUP_RES:
			_receive_signup_res()
		TPacket.OPCODE.ACCOUNT:
			_receive_account()
		TPacket.OPCODE.ENTER_RES:
			_receive_enter_res()
		TPacket.OPCODE.LEAVE_RES:
			_receive_leave_res()
		TPacket.OPCODE.JOIN_RES:
			_receive_join_res()
		TPacket.OPCODE.UNJOIN_RES:
			_receive_unjoin_res()
		TPacket.OPCODE.POKER_INFO:
			_receive_poker_info()
		TPacket.OPCODE.POKER_STATE:
			_receive_poker_state()
		TPacket.OPCODE.POKER_ACTION_REFLECTION:
			_receive_poker_action_reflection()
		TPacket.OPCODE.POKER_END:
			_receive_poker_end()
		TPacket.OPCODE.POKER_RESTARTED:
			_receive_poker_restarted()
		TPacket.OPCODE.UNJOINED:
			_receive_poker_unjoined()
		TPacket.OPCODE.TABLES:
			_receive_tables()
		TPacket.OPCODE.SESSIONS:
			_receive_sessions()
		TPacket.OPCODE.UPDATE_ACCOUNT_RES:
			_receive_update_account_res()
		TPacket.OPCODE.OVER_CAPACITY:
			_receive_over_capacity()

func connect_to_server(p_host: String, p_port: int) -> bool:
	host = p_host
	port = p_port
	
	nConnecting.show()
	nOverCapacity.hide()
	
	var err: Error
	
	if !is_websocket:
		socket = StreamPeerTCP.new()
		
		err = socket.connect_to_host(host, port)
		if err != OK:
			print("Connection failed: ", err)
			return false
		
		tls = StreamPeerTLS.new()
	else:
		if ws:
			ws.free()
		ws = SynchronousWebSocketStream.new()
		err = ws.connect_to_url("wss://" + p_host + ":5560")
		if err != OK:
			print("Connection failed: ", err)
			return false
	
	is_expect_connection = true
	
	if !listen_thread.is_alive():
		if listen_thread.is_started():
			listen_thread.wait_to_finish()
		
		if is_websocket:
			err = listen_thread.start(_listen_thread_f__ws, Thread.PRIORITY_NORMAL)
		else:
			err = listen_thread.start(_listen_thread_f, Thread.PRIORITY_NORMAL)
		if err != OK:
			print("Failed to create listen thread!")
	
	return true

func begin_put() -> void:
	if is_websocket:
		ws.begin_put()

func end_put() -> void:
	if is_websocket:
		ws.end_put()

func send_header(opcode: TPacket.OPCODE, length: int = 0) -> void:
	print("Sending header... OPCODE: ", opcode)
	
	stream.put_u32(opcode)
	stream.put_u32(length)

func send_meow() -> void:
	print("Sending MEOW....")
	
	begin_put()
	send_header(TPacket.OPCODE.MEOW)
	end_put()

func send_ping() -> void:
	print("Sending PING....")
	
	begin_put()
	send_header(TPacket.OPCODE.PING)
	end_put()

func send_login(id_token: String, password: String) -> void:
	print("Sending LOGIN....")

	var id_token_bytes := id_token.to_ascii_buffer()
	var password_bytes := password.to_ascii_buffer()
	
	begin_put()

	send_header(TPacket.OPCODE.LOGIN)

	stream.put_u16(id_token_bytes.size())
	stream.put_u16(password_bytes.size())

	stream.put_data(id_token_bytes)
	stream.put_data(password_bytes)
	
	end_put()

func send_signup(id_token: String, password: String, name: String, avatar: PackedByteArray = []) -> void:
	print("Sending SIGNUP....")

	var id_token_bytes := id_token.to_ascii_buffer()
	var password_bytes := password.to_ascii_buffer()
	var name_bytes := name.to_ascii_buffer()
	
	var avatar_bytes = avatar
	var avatar_size = avatar_bytes.size()
	
	begin_put()

	send_header(TPacket.OPCODE.SIGNUP)

	stream.put_u16(id_token_bytes.size())
	stream.put_u16(password_bytes.size())
	stream.put_u16(name_bytes.size())
	stream.put_u32(avatar_size)

	stream.put_data(id_token_bytes)
	stream.put_data(password_bytes)
	stream.put_data(name_bytes)
	
	if avatar_size > 0:
		stream.put_data(avatar_bytes)
	
	end_put()

func send_get_account() -> void:
	print("Sending GET_ACCOUNT....")

	begin_put()
	
	send_header(TPacket.OPCODE.GET_ACCOUNT)
	
	end_put()

func send_enter(table_id: int) -> void:
	print("Sending ENTER....")

	begin_put()
	
	send_header(TPacket.OPCODE.ENTER)

	stream.put_u64(table_id)
	
	end_put()

func send_leave(table_id: int) -> void:
	print("Sending LEAVE....")

	begin_put()
	
	send_header(TPacket.OPCODE.LEAVE)

	stream.put_u64(table_id)
	
	end_put()

func send_join(p_table_id: int, p_enterance_amount: int, p_position: int) -> void:
	print("Sending JOIN....")

	begin_put()
	
	send_header(TPacket.OPCODE.JOIN)
	
	stream.put_u64(p_table_id)
	stream.put_u8(p_position)
	stream.put_u64(p_enterance_amount)
	
	end_put()

func send_unjoin(table_id: int) -> void:
	print("Sending UNJOIN....")

	begin_put()
	
	send_header(TPacket.OPCODE.UNJOIN)

	stream.put_u64(table_id)
	
	end_put()

func send_action(p_table_id: int, p_kind: TPoker.ACTION_KIND, p_amount: int = 0) -> void:
	print("Sending ACTION....")

	begin_put()
	
	send_header(TPacket.OPCODE.POKER_ACTION)

	stream.put_u64(p_table_id)
	stream.put_u16(p_kind)
	stream.put_u64(p_amount)
	
	end_put()

func send_get_tables(offset: int = 0, length: int = 10) -> void:
	print("Sending GET_TABLES....")
	
	begin_put()
	
	send_header(TPacket.OPCODE.GET_TABLES)

	stream.put_u16(offset)
	stream.put_u16(length)
	
	end_put()

func send_get_sessions(offset: int = 0, length: int = 10) -> void:
	print("Sending GET_SESSIONS....")
	
	begin_put()
	
	send_header(TPacket.OPCODE.GET_SESSIONS)

	stream.put_u16(offset)
	stream.put_u16(length)
	
	end_put()

func send_update_account(name: String, avatar: PackedByteArray = []) -> void:
	print("Sending UPDATE_ACCOUNT....")

	var name_bytes := name.to_ascii_buffer()
	
	var avatar_bytes = avatar
	
	begin_put()

	send_header(TPacket.OPCODE.UPDATE_ACCOUNT)

	stream.put_u16(name_bytes.size())
	stream.put_u32(avatar_bytes.size())

	if name_bytes.size() > 0:
		stream.put_data(name_bytes)
	
	if avatar_bytes.size() > 0:
		stream.put_data(avatar_bytes)
	
	end_put()

func send_json(json: String) -> void:
	print("Sending JSON....")

	begin_put()
	
	send_header(TPacket.OPCODE.JSON_PACKET, json.length())
	
	stream.put_data(json.to_ascii_buffer())
	
	end_put()

func _receive_over_capacity() -> void:
	print("OVER_CAPACITY receivedddddddddd")
	call_deferred("_over_capacity")

func _over_capacity():
	nConnecting.hide()
	nOverCapacity.show()
	over_capacity.emit()

func _receive_pong() -> void:
	print("PONG receivedddddddddd")
	call_deferred("emit_signal", "pong")

func _receive_server_info() -> void:
	print("SERVER_INFO receivedddddddddd")
	
	var build_number = stream.get_u64()
	var version_length = stream.get_u16()
	var revision_length = stream.get_u16()
	var compiler_length = stream.get_u16()
	
	var _server_info = TPacket.TServerInfo.new()
	_server_info.build_number = build_number
	_server_info.version = PackedByteArray(stream.get_data(version_length)[1]).get_string_from_ascii()
	_server_info.revision = PackedByteArray(stream.get_data(revision_length)[1]).get_string_from_ascii()
	_server_info.compiler = PackedByteArray(stream.get_data(compiler_length)[1]).get_string_from_ascii()
	
	call_deferred("emit_signal", "server_info", _server_info)

func _receive_login_res() -> void:
	print("Receiving LOGIN_RES....")
		
	var _login_res = TPacket.TLoginRes.new()
	_login_res.is_ok = bool(stream.get_u8())
	_login_res.is_logined = bool(stream.get_u8())
	
	if _login_res.is_ok && _login_res.is_logined:
		var xmr_deposit_address_length = stream.get_u16()
		var id_token_length = stream.get_u16()
		var name_length = stream.get_u16()
		var avatar_length = stream.get_u32()
		
		_login_res.account = TPacket.TAccount.new()
		_login_res.account.id = stream.get_u64()
		_login_res.account.balance = stream.get_u64()
		_login_res.account.xmr_deposit_address = PackedByteArray(stream.get_data(xmr_deposit_address_length)[1]).get_string_from_ascii()
		_login_res.account.id_token = PackedByteArray(stream.get_data(id_token_length)[1]).get_string_from_ascii()
		_login_res.account.name = PackedByteArray(stream.get_data(name_length)[1]).get_string_from_ascii()
		if avatar_length > 0:
			_login_res.account.avatar = TPacket.TAvatar.new()
			var avatar_result = stream.get_data(avatar_length)
			var avatar_data: PackedByteArray = avatar_result[1]
			_login_res.account.avatar.mime = TPacket.TMime.from_type(avatar_data.decode_u8(0))
			_login_res.account.avatar.data = PackedByteArray(avatar_data.slice(1))
		else:
			_login_res.account.avatar = null
		
		print("_login_res.account.id: ", _login_res.account.id)
		print("_login_res.account.balance: ", _login_res.account.balance)
		print("_login_res.account.id_token: ", _login_res.account.id_token)
		print("_login_res.account.name: ", _login_res.account.name)
		if _login_res.account.avatar:
			print("_login_res.account.avatar: ", _login_res.account.avatar.data.size())
	
	call_deferred("emit_signal", "login_res", _login_res)

func _receive_signup_res() -> void:
	print("Receiving SIGNUP_RES....")
	
	var _signup_res = TPacket.TSignupRes.new()
	_signup_res.is_ok = bool(stream.get_u8())
	_signup_res.is_logined = bool(stream.get_u8())
	_signup_res.status = stream.get_u16()
	
	_signup_res.account = null

	if _signup_res.is_ok && _signup_res.is_logined:
		var id_token_length = stream.get_u16()
		var name_length = stream.get_u16()
		var avatar_length = stream.get_u32()
		var xmr_deposit_address_length = stream.get_u16()
		
		_signup_res.account = TPacket.TAccount.new()
		_signup_res.account.id = stream.get_u64()
		_signup_res.account.balance = stream.get_u64()
		_signup_res.account.id_token = PackedByteArray(stream.get_data(id_token_length)[1]).get_string_from_ascii()
		_signup_res.account.name = PackedByteArray(stream.get_data(name_length)[1]).get_string_from_ascii()
		if avatar_length > 0:
			_signup_res.account.avatar = TPacket.TAvatar.new()
			var avatar_result = stream.get_data(avatar_length)
			var avatar_data: PackedByteArray = avatar_result[1]
			_signup_res.account.avatar.mime = TPacket.TMime.from_type(avatar_data.decode_u8(0))
			_signup_res.account.avatar.data = PackedByteArray(avatar_data.slice(1))
		_signup_res.account.xmr_deposit_address = PackedByteArray(stream.get_data(xmr_deposit_address_length)[1]).get_string_from_ascii()
		
		print("_signup_res.account.id: ", _signup_res.account.id)
		print("_signup_res.account.balance: ", _signup_res.account.balance)
		print("_signup_res.account.id_token: ", _signup_res.account.id_token)
		print("_signup_res.account.name: ", _signup_res.account.name)
		print("_signup_res.account.avatar: ", _signup_res.account.avatar)
	
	call_deferred("emit_signal", "signup_res", _signup_res)

func _receive_account() -> void:
	print("Receiving ACCOUNT....")
	
	var xmr_deposit_address_length = stream.get_u16()
	var id_token_length = stream.get_u16()
	var name_length = stream.get_u16()
	var avatar_length = stream.get_u32()
	
	var _account = TPacket.TAccount.new()
	_account.id = stream.get_u64()
	_account.balance = stream.get_u64()
	if xmr_deposit_address_length > 0:
		_account.xmr_deposit_address = PackedByteArray(stream.get_data(xmr_deposit_address_length)[1]).get_string_from_ascii()
	_account.id_token = PackedByteArray(stream.get_data(id_token_length)[1]).get_string_from_ascii()
	_account.name = PackedByteArray(stream.get_data(name_length)[1]).get_string_from_ascii()
	if avatar_length > 0:
		_account.avatar = TPacket.TAvatar.new()
		var avatar_result = stream.get_data(avatar_length)
		var avatar_data: PackedByteArray = avatar_result[1]
		_account.avatar.mime = TPacket.TMime.from_type(avatar_data.decode_u8(0))
		_account.avatar.data = PackedByteArray(avatar_data.slice(1))
	
	call_deferred("emit_signal", "account", _account)

func _receive_enter_res() -> void:
	print("Receiving ENTER_RES....")
	
	var _enter_res := TPacket.TEnterRes.new()
	_enter_res.table_id = stream.get_u64()
	_enter_res.is_ok = bool(stream.get_u8())
	
	print("\tenter_res.table_id: ", _enter_res.table_id)
	print("\tenter_res.is_ok: ", _enter_res.is_ok)
	
	call_deferred("emit_signal", "enter_res", _enter_res)

func _receive_leave_res() -> void:
	print("Receiving LEAVE_RES....")
	
	var _leave_res := TPacket.TLeaveRes.new()
	_leave_res.table_id = stream.get_u64()
	_leave_res.is_ok = bool(stream.get_u8())
	
	call_deferred("emit_signal", "leave_res", _leave_res)

func _receive_join_res() -> void:
	print("Receiving JOIN_RES....")
	
	var _join_res := TPacket.TJoinRes.new()
	_join_res.table_id = stream.get_u64()
	_join_res.is_ok = bool(stream.get_u8())
	
	call_deferred("emit_signal", "join_res", _join_res)

func _receive_unjoin_res() -> void:
	print("Receiving UNJOIN_RES....")
	
	var _unjoin_res := TPacket.TUnjoinRes.new()
	_unjoin_res.table_id = stream.get_u64()
	_unjoin_res.is_ok = bool(stream.get_u8())
	
	call_deferred("emit_signal", "unjoin_res", _unjoin_res)

func _read_poker_info() -> TPacket.TPokerInfo:
	var name_length = stream.get_u16()
	var players_length = stream.get_u16()
	
	var _poker_info = TPacket.TPokerInfo.new()
	_poker_info.table_id = stream.get_u64()
	_poker_info.max_players = stream.get_u16()
	_poker_info.action_timeout = stream.get_u16()
	_poker_info.small_blind = stream.get_u64()
	_poker_info.big_blind = stream.get_u64()
	_poker_info.enterance_min = stream.get_u64()
	_poker_info.enterance_max = stream.get_u64()
	
	_poker_info.name = PackedByteArray(stream.get_data(name_length)[1]).get_string_from_ascii()
	
	for i in range(players_length):
		var player_name_length = stream.get_u16()
		var player_avatar_length = stream.get_u32()

		var player = TPacket.TStatePlayer.new()
		player.parent = _poker_info
		_poker_info.players.append(player)
		player.id = stream.get_u64()

		player.position = stream.get_u8()
		player.is_playing = stream.get_u8()
		player.is_dealt = stream.get_u8()
		player.is_allin = stream.get_u8()
		player.is_folded = stream.get_u8()
		player.is_left = stream.get_u8()
		
		player.balance = stream.get_u64()
		
		var vec
		if player_name_length > 0:
			vec = stream.get_data(player_name_length)
			player.name = PackedByteArray(vec[1]).get_string_from_ascii()
		if player_avatar_length > 0:
			player.avatar = TPacket.TAvatar.new()
			var avatar_result = stream.get_data(player_avatar_length)
			var avatar_data: PackedByteArray = avatar_result[1]
			player.avatar.mime = TPacket.TMime.from_type(avatar_data.decode_u8(0))
			player.avatar.data = PackedByteArray(avatar_data.slice(1))
		else:
			player.avatar = null
	
	return _poker_info

func _receive_poker_info() -> void:
	print("Receiving POKER_INFO....")
	
	var _poker_info = _read_poker_info()
	
	call_deferred("emit_signal", "poker_info", _poker_info)

func _receive_poker_state() -> void:
	print("Receiving POKER_STATE....")
	
	var players_length = stream.get_u16()
	
	var _poker_state = TPacket.TPokerState.new()
	_poker_state.table_id = stream.get_u64()
	_poker_state.state = TPoker.STATE.values()[stream.get_u16()]
	_poker_state.is_playing = bool(stream.get_u8())

	for i in range(5):
		var encoded = stream.get_u8()

		var card := TPoker.TCard.new()
		card.index = (encoded & 240) >> 4
		if encoded & 15 < TPoker.CARD_KIND.values().size():
			card.kind = TPoker.CARD_KIND.values()[encoded & 15]

		_poker_state.cards.append(card)

	_poker_state.position = stream.get_u8()
	_poker_state.playing_position = stream.get_u8()
	_poker_state.is_dealt = bool(stream.get_u8())

	var hand_card_0 = stream.get_u8()
	var hand_card_1 = stream.get_u8()

	if _poker_state.is_dealt:
		_poker_state.hand_cards.append(TPoker.TCard.new())
		_poker_state.hand_cards[0].index = (hand_card_0 & 240) >> 4
		_poker_state.hand_cards[0].kind = TPoker.CARD_KIND.values()[hand_card_0 & 15]
		print("Card 1 -> Index: ", _poker_state.hand_cards[0].index, " --- Kind: ", hand_card_0 & 15)
		_poker_state.hand_cards.append(TPoker.TCard.new())
		_poker_state.hand_cards[1].index = (hand_card_1 & 240) >> 4
		_poker_state.hand_cards[1].kind = TPoker.CARD_KIND.values()[hand_card_1 & 15]
		print("Card 2 -> Index: ", _poker_state.hand_cards[1].index, " --- Kind: ", hand_card_1 & 15)
	
	_poker_state.balance = stream.get_u64()
	_poker_state.bet = stream.get_u64()
	_poker_state.current_raise = stream.get_u64()
	_poker_state.current_bet = stream.get_u64()
	_poker_state.pot_amount = stream.get_u64()
	_poker_state.starting_time = stream.get_u64()
	
	for i in range(players_length):
		var player_name_length = stream.get_u16()

		var player := TPacket.TStatePlayer.new()
		player.parent = _poker_state
		_poker_state.players.append(player)
		player.id = stream.get_u64()

		player.position = stream.get_u8()
		player.is_playing = stream.get_u8()
		player.is_dealt = stream.get_u8()
		player.is_allin = stream.get_u8()
		player.is_folded = stream.get_u8()
		player.is_left = stream.get_u8()
		
		player.balance = stream.get_u64()

		var vec
		
		if player_name_length > 0:
			vec = stream.get_data(player_name_length)
			player.name = PackedByteArray(vec[1]).get_string_from_ascii()
	
	call_deferred("emit_signal", "poker_state", _poker_state)

func _receive_poker_action_reflection() -> void:
	print("Receiving POKER_ACTION_REFLECTION....")
	
	var _poker_action_reflection := TPacket.TPokerActionReflection.new()
	_poker_action_reflection.table_id = stream.get_u64()
	_poker_action_reflection.account_id = stream.get_u64()
	_poker_action_reflection.action_kind = TPoker.ACTION_KIND.values()[stream.get_u16()]
	_poker_action_reflection.amount = stream.get_u64()
	
	call_deferred("emit_signal", "poker_action_reflection", _poker_action_reflection)

func _receive_poker_end() -> void:
	print("Receiving POKER_END....")
	
	var _poker_end := TPacket.TPokerEnd.new()
	_poker_end.table_id = stream.get_u64()
	_poker_end.winner_account_id = stream.get_u64()
	var scores_length = stream.get_u8()
	_poker_end.earned_amount = stream.get_u64()
	
	for i in range(scores_length):
		var score := TPacket.TPokerEndScore.new()
		score.account_id = stream.get_u64()
		score.bet_diff = stream.get_u64()
		_poker_end.scores.append(score)

	call_deferred("emit_signal", "poker_end", _poker_end)

func _receive_poker_restarted() -> void:
	print("Receiving POKER_RESTARTED....")
	
	var _poker_restarted := TPacket.TPokerRestarted.new()
	_poker_restarted.table_id = stream.get_u64()
	
	call_deferred("emit_signal", "poker_restarted", _poker_restarted)

func _receive_poker_unjoined() -> void:
	print("Receiving UNJOINED....")
	
	var _unjoined := TPacket.TUnjoined.new()
	_unjoined.table_id = stream.get_u64()
	_unjoined.reason = stream.get_u32()
	
	call_deferred("emit_signal", "unjoined", _unjoined)

func _receive_tables() -> void:
	print("Receiving TABLES....")
	
	var _tables := TPacket.TTables.new()
	_tables.offset = stream.get_u16()
	_tables.length = stream.get_u16()
	print("\toffset: ", _tables.offset, " - length: ", _tables.length)
	
	for i in range(_tables.length):
		var name_length = stream.get_u16()
		
		var table := TPacket.TTable.new()
		table.id = stream.get_u64()
		table.max_players = stream.get_u16()
		table.players_count = stream.get_u16()
		table.watchers_count = stream.get_u16()
		table.small_blind = stream.get_u64()
		table.big_blind = stream.get_u64()
		table.name = PackedByteArray(stream.get_data(name_length)[1]).get_string_from_ascii()
		
		_tables.tables.append(table)
	
	call_deferred("emit_signal", "tables", _tables)

func _receive_sessions() -> void:
	print("Receiving SESSIONS....")
	
	var _sessions := TPacket.TSessions.new()
	_sessions.offset = stream.get_u16()
	_sessions.length = stream.get_u16()
	print("\toffset: ", _sessions.offset, " - length: ", _sessions.length)
	
	for i in range(_sessions.length):
		var _poker_info = _read_poker_info()
		_sessions.sessions.append(_poker_info)
	
	call_deferred("emit_signal", "sessions", _sessions)

func _receive_update_account_res() -> void:
	print("Receiving UPDATE_ACCOUNT_RES....")
	
	var _update_account_res := TPacket.TUpdateAccountRes.new()
	_update_account_res.is_ok = bool(stream.get_u8())
	_update_account_res.is_avatar_too_big = bool(stream.get_u8())
	
	call_deferred("emit_signal", "update_account_res", _update_account_res)

func _on_connected() -> void:
	print("PokerClient._on_connected()")
	nConnecting.call_deferred("hide")
	
	call_deferred("emit_signal", "connected")

func _on_disconnected() -> void:
	print("PokerClient._on_disconnected()")
	
	is_expect_connection = false
	
	call_deferred("emit_signal", "disconnected")
	
	socket = null
	tls = null
	
	print("Disconnected, gonna retry in ", reconnection_interval, " seconds...")
	
	reconnect_timer.stop()
	reconnect_timer.start(reconnection_interval)
	
	ASounds.play_fail()

func _reconnect() -> void:
	print("Trying to re-connect...")
	connect_to_server(host, port)

func _on_RequestSessions_pressed() -> void:
	send_get_sessions()
