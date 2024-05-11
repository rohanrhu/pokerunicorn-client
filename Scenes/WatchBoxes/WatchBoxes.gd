# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends PanelContainer
class_name WatchBoxes

@onready var nItems = %Items

@onready var items_length = nItems.get_child_count()

var sessions: TPacket.TSessions: set = set_sessions
var items: Dictionary = {}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func set_item_session(index: int, session: TPacket.TPokerInfo) -> void:
	var nItem: WatchBox = nItems.get_child(index)
	
	if !session:
		nItem.session = null
		return
	
	var item
	
	if items.has(session.table_id):
		item = items[session.table_id]
		item["nItem"] = nItem
	else:
		item = {
			nItem = nItem,
			session = session
		}
		
		items[session.table_id] = item
	
	nItem.session = session

func set_sessions(p_sessions: TPacket.TSessions) -> void:
	sessions = p_sessions
	
	for i in range(sessions.length):
		var session = sessions.sessions[i]
		set_item_session(i, session)
	
	var diff = items_length - sessions.length
	
	for i in range(sessions.length, sessions.length + diff):
		set_item_session(i, null)
