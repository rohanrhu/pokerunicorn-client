# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Object
class_name TPacket

enum OPCODE {
	NOP = 0,
	MEOW,
	PING,
	PONG,
	LOGIN,
	LOGIN_RES,
	SIGNUP,
	SIGNUP_RES,
	GET_ACCOUNT,
	ACCOUNT,
	ENTER,
	ENTER_RES,
	LEAVE,
	LEAVE_RES,
	JOIN,
	JOIN_RES,
	UNJOIN,
	UNJOIN_RES,
	POKER_INFO,
	POKER_STATE,
	POKER_ACTION,
	POKER_ACTION_REFLECTION,
	POKER_END,
	POKER_RESTARTED,
	JSON_PACKET,
	UNJOINED,
	GET_TABLES,
	TABLES,
	GET_SESSIONS,
	SESSIONS,
	UPDATE_ACCOUNT,
	UPDATE_ACCOUNT_RES,
	SERVER_INFO,
	OVER_CAPACITY,
	END
}

class TMime:
	enum TYPE {
		UNKNOWN = 0,
		JPG,
		PNG
	}
	
	var extension: String: get = get_extension, set = set_extension
	
	var type: TYPE = TYPE.UNKNOWN
	
	static func from_path(p_path: String) -> TMime:
		var path_extension = p_path.get_extension()
		
		var mime = new()
		
		if (path_extension == "jpg") || (path_extension == "jpeg"):
			mime.type = TYPE.JPG
		elif path_extension == "png":
			mime.type = TYPE.PNG
		else:
			mime.type = TYPE.UNKNOWN
		
		return mime
	
	static func from_type(p_type: TYPE) -> TMime:
		var mime = new()
		mime.type = p_type
		return mime
	
	func get_extension() -> String:
		if type == TYPE.JPG:
			return "jpg"
		elif type == TYPE.PNG:
			return "png"
		else:
			return ""
	
	func set_extension(p_extension: String):
		if (extension == "jpg") || (extension == "jpeg"):
			type = TYPE.JPG
		elif extension == "png":
			type = TYPE.PNG
		else:
			type = TYPE.UNKNOWN

class THeader:
	var opcode: int
	var length: int

class TServerInfo:
	var build_number: int
	var version: String
	var revision: String
	var compiler: String

class TAvatar:
	var mime: TMime
	var data: PackedByteArray

class TAccount:
	var id: int
	var id_token: String
	var name: String
	var avatar: TAvatar
	var balance: int
	var xmr_deposit_address: String

class TLoginRes:
	var is_ok: bool
	var is_logined: bool
	var account: TAccount

class TSignupRes:
	enum STATUS {
		OK,
		ERROR,
		ALREADY_EXISTS
	}
	
	var is_ok: bool
	var is_logined: bool
	var status: int
	var account: TAccount

class TEnterRes:
	var table_id: int
	var is_ok: bool

class TLeaveRes:
	var table_id: int
	var is_ok: bool

class TJoinRes:
	var table_id: int
	var is_ok: bool

class TUnjoinRes:
	var table_id: int
	var is_ok: bool

class TStatePlayer:
	var parent # TPokerInfo || TPokerState
	var id: int
	var name: String
	var avatar: TAvatar
	var position: int
	var is_playing: bool
	var is_dealt: bool
	var is_allin: bool
	var is_folded: bool
	var is_left: bool
	var balance: int

class TPokerInfo:
	var table_id: int
	var small_blind: int
	var big_blind: int
	var max_players: int
	var action_timeout: int
	var name: String
	var players: Array[TStatePlayer]
	var enterance_min: int
	var enterance_max: int
	
	var me: TStatePlayer = null: get = get_me
	
	func getby_id(p_id: int) -> TStatePlayer:
		for player in players:
			if player.id == p_id:
				return player
		
		return null
	
	func get_me() -> TStatePlayer:
		if !ALoginDialog.account:
			return null
		
		for player in players:
			if player.id == ALoginDialog.account.id:
				return player
		
		return null

class TPokerState:
	var table_id: int
	var state: TPoker.STATE
	var is_playing: int
	var cards: Array[TPoker.TCard]
	var players: Array[TStatePlayer]
	var position: int
	var playing_position: int
	var is_dealt: int
	var hand_cards: Array[TPoker.TCard]
	var balance: int
	var bet: int
	var current_raise: int
	var current_bet: int
	var pot_amount: int
	var starting_time: int
	
	var me: TStatePlayer = null: get = get_me
	
	func getby_id(p_id: int) -> TStatePlayer:
		for player in players:
			if player.id == p_id:
				return player
		
		return null
	
	func get_me() -> TStatePlayer:
		if !ALoginDialog.account:
			return null
		
		for player in players:
			if player.id == ALoginDialog.account.id:
				return player
		
		return null

class TPokerActionReflection:
	var table_id: int
	var account_id: int
	var action_kind: TPoker.ACTION_KIND
	var amount: int

class TPokerEndScore:
	var account_id: int
	var bet_diff: int

class TPokerEnd:
	var table_id: int
	var winner_account_id: int
	var earned_amount: int
	var scores: Array[TPokerEndScore]

class TPokerRestarted:
	var table_id: int

class TUnjoined:
	var table_id: int
	var reason: int

class TTable:
	var id: int
	var small_blind: int
	var big_blind: int
	var max_players: int
	var players_count: int
	var watchers_count: int
	var name: String

class TTables:
	var offset: int
	var length: int
	var tables: Array[TTable]
	
	func get_by_id(p_id: int) -> TTable:
		for table in tables:
			if table.id == p_id:
				return table
		return null

class TSessions:
	var offset: int
	var length: int
	var sessions: Array[TPokerInfo]
	
	func get_by_id(p_id: int) -> TPokerInfo:
		for session in sessions:
			if session.table_id == p_id:
				return session
		return null

class TUpdateAccountRes:
	var is_ok: bool
	var is_avatar_too_big: bool
