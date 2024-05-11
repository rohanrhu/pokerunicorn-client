# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends PanelContainer
class_name WatchBox

@onready var nNoSession = %NoSession
@onready var nSession = %Session
@onready var nNameLabel = %NameLabel
@onready var nPlayerNames = %PlayerNames
@onready var nPlayerNames_Items = nPlayerNames.get_node("Items")
@onready var nJoinButton = %JoinButton
@onready var nFullLabel = %FullLabel
@onready var nEmptyBackground = %EmptyBackground
@onready var nPlayingBackground = %PlayingBackground

var session: TPacket.TPokerInfo: set = set_session

func _ready() -> void:
	nPlayingBackground.hide()
	nEmptyBackground.show()
	nSession.hide()
	nNoSession.show()
	
	ASessions.entered_session.connect(_on_entered_session)
	ASessions.left_session.connect(_on_left_session)

func _process(delta: float) -> void:
	pass

func set_session(p_session: TPacket.TPokerInfo) -> void:
	session = p_session
	
	if !session || !session.players.size():
		nNoSession.show()
		nSession.hide()
		
		nEmptyBackground.show()
		nPlayingBackground.hide()
		
		return
	
	nNoSession.hide()
	nSession.show()
	
	nEmptyBackground.hide()
	nPlayingBackground.show()
	
	for node in nPlayerNames_Items.get_children():
		nPlayerNames_Items.remove_child(node)
	
	for player in session.players:
		var nLabel = Label.new()
		nLabel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		nLabel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nPlayerNames_Items.add_child(nLabel)
		
		nLabel.text = player.name
	
	nNameLabel.text = session.name
	
	if session.players.size() == session.max_players:
		nJoinButton.hide()
		nFullLabel.show()
	else:
		nJoinButton.show()
		nFullLabel.hide()
	
	if ASessions.get_session(session.table_id):
		nJoinButton.hide()

func _on_entered_session(table_id: int) -> void:
	if !session:
		return
	
	if session.table_id == table_id:
		nJoinButton.hide()

func _on_left_session(table_id: int) -> void:
	if !session:
		return
	
	if session.table_id == table_id:
		nJoinButton.show()

func _on_JoinButton_pressed() -> void:
	if !session:
		return
	
	if not  ALoginDialog.account:
		return
	
	ASessions.enter_session(session.table_id)
