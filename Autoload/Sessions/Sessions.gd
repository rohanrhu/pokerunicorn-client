# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control

signal entered_session(table_id: int)
signal left_session(table_id: int)

@onready var cPoker: PackedScene = load("res://Scenes/Poker/Poker.tscn")

@onready var nGameWindowProto = %GameWindowProto
@onready var nGameWindows = %GameWindows

var sessions = {}

func _ready() -> void:
	APokerClient.enter_res.connect(_on_enter_res)
	APokerClient.poker_info.connect(_on_poker_info)

func _process(delta: float) -> void:
	pass

func enter_session(table_id: int) -> void:
	var nGameWindow = nGameWindowProto.duplicate()
	nGameWindow.name = str(table_id)
	nGameWindows.add_child(nGameWindow)
	
	var session = {
		poker_info = null,
		nGameWindow = nGameWindow,
		is_entered = false
	}
	sessions[table_id] = session
	
	var nPoker: Poker = cPoker.instantiate()
	nPoker.name = "Poker"
	nPoker.enter_failed.connect(_on_Poker_enter_failed)
	nPoker.entered.connect(_on_Poker_entered)
	nPoker.left.connect(_on_Poker_left)
	nGameWindow.add_child(nPoker)
	
	nPoker.set_account(ALoginDialog.account)
	nPoker.enter_table(table_id)
	
	entered_session.emit(table_id)

func leave_session(table_id: int) -> void:
	if not sessions.has(table_id):
		return
	
	var session: Dictionary = sessions[table_id]
	var nGameWindow: Window = session["nGameWindow"]
	
	var nPoker = nGameWindow.get_node_or_null("Poker")

	if nPoker && is_instance_valid(nPoker):
		nPoker.disconnect_event_handlers()
		nPoker.hide()
		nGameWindow.remove_child(nPoker)
		nPoker.queue_free()
	
	nGameWindow.hide()
	nGameWindow.queue_free()
	sessions.erase(table_id)
	
	left_session.emit(table_id)

func get_session(table_id: int) -> TPacket.TPokerInfo:
	if !sessions.has(table_id):
		return null
	
	return sessions[table_id]["poker_info"]

func _on_enter_res(enter_res: TPacket.TEnterRes) -> void:
	if !enter_res.is_ok:
		return
	
	sessions[enter_res.table_id]["is_entered"] = true

func _on_poker_info(poker_info: TPacket.TPokerInfo) -> void:
	sessions[poker_info.table_id]["poker_info"] = poker_info

func _on_Poker_enter_failed(table_id: int) -> void:
	leave_session(table_id)
	
func _on_Poker_entered(table_id: int) -> void:
	var session: Dictionary = sessions[table_id]
	var nGameWindow: Window = session["nGameWindow"]
	
	nGameWindow.call_deferred("show")

func _on_Poker_left(table_id: int) -> void:
	leave_session(table_id)
