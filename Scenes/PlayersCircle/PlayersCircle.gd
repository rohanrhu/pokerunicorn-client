# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name PlayersCircle

class PlayersCirclePlayer:
	var state_player: TPacket.TStatePlayer
	var nPlayer: PokerPlayer

signal take_seat(position_index: int, enterance_amount: int)

var nPlayer: PokerPlayer = null
@onready var nPositions: Control = %Positions

var max_players: int = -1

var player_position := 0

var players: Array[PlayersCirclePlayer]

var account: TPacket.TAccount
var poker_info: TPacket.TPokerInfo
var poker_state: TPacket.TPokerState

var is_entered := false
var is_joined := false
var is_playing := false

var nPositions_N: Control = null

var last_playing_pos = -1
var last_state = 0

func _ready() -> void:
	for __nPositions_N in nPositions.get_children():
		var _nPositions_N: Control = __nPositions_N
		_nPositions_N.visible = false
		
		for _nPoint in _nPositions_N.get_children():
			var nPoint: Control = _nPoint
			
			if nPoint.get_child_count() < 2:
				continue
			
			nPoint.get_child(0).visible = false
			nPoint.get_child(1).visible = true

func _process(delta: float) -> void:
	pass

func set_account(p_account: TPacket.TAccount):
	account = p_account

func set_poker_info(p_poker_info: TPacket.TPokerInfo):
	poker_info = p_poker_info

func set_poker_state(p_poker_state: TPacket.TPokerState):
	poker_state = p_poker_state

func set_player_position(p_position: int = 0):
	player_position = p_position

func set_max_players(p_max_players: int):
	max_players = p_max_players
	
	
	nPositions_N = nPositions.get_node(str(max_players))
	nPositions_N.visible = true
	
	nPlayer = nPositions_N.get_child(0).get_node("Player")
	
	for _nPoint in nPositions_N.get_children():
		var nPoint: Control = _nPoint
		
		nPoint.visible = true
		nPoint.get_child(0).visible = false
		nPoint.get_child(1).visible = true

func set_is_entered(p_is_entered: bool):
	is_entered = p_is_entered

func set_is_joined(p_is_joined: bool):
	is_joined = p_is_joined

func set_is_playing(p_is_playing: bool):
	is_playing = p_is_playing

func set_players(p_players: Array[TPacket.TStatePlayer], cards: Array[TPoker.TCard] = []):
	for _nPoint in nPositions_N.get_children():
		var nPoint: Control = _nPoint
		
		nPoint.get_child(0).visible = false
		nPoint.get_child(1).visible = true
		
		nPoint.visible = !is_joined
	
	for i in range(p_players.size()):
		var state_player: TPacket.TStatePlayer = p_players[i]
		var existing_player: PlayersCirclePlayer = null
		
		for j in range(players.size()):
			if players[j].state_player.id == state_player.id:
				existing_player = players[j]
				existing_player.state_player = state_player
				break

		var player: PlayersCirclePlayer = null
		
		if existing_player == null:
			player = PlayersCirclePlayer.new()
			players.append(player)
		else:
			player = existing_player
		
		var point_index: int
		
		if !is_joined:
			point_index = state_player.position
		else:
			if state_player.id == account.id:
				point_index = 0
			else:
				point_index = (((max_players - 1) - player_position) + state_player.position) % max_players
				point_index = (point_index + 1) % max_players
		
		var nPlayerPoint: Control = nPositions_N.get_child(point_index)
		nPlayerPoint.visible = true
		
		var nOpponent: PokerPlayer = nPlayerPoint.get_node("Player")
		var nTakeSeatButton: TakeSeatButton = nPlayerPoint.get_node("TakeSeatButton")

		player.nPlayer = nOpponent
		player.state_player = state_player
		player.nPlayer.visible = true
		
		nTakeSeatButton.visible = false

		player.nPlayer.set_player_id(state_player.id)
		player.nPlayer.set_player_name(state_player.name)
		if state_player.avatar:
			player.nPlayer.set_avatar(state_player.avatar)
		player.nPlayer.set_is_playing(state_player.is_playing)
		player.nPlayer.set_is_folded(state_player.is_folded)
		player.nPlayer.set_is_allin(state_player.is_allin)
		if poker_state:
			player.nPlayer.set_is_dealt(poker_state.is_dealt)
			player.nPlayer.set_is_current(state_player.position == poker_state.playing_position)
			player.nPlayer.set_action_timeout(poker_info.action_timeout)
			if (state_player.position == poker_state.playing_position) && (poker_state.state > TPoker.STATE.BIG_BLIND) && (poker_state.state < TPoker.STATE.DONE):
				if (last_playing_pos == -1) || (last_state != poker_state.state) || (last_playing_pos != poker_state.playing_position):
					last_state = poker_state.state
					last_playing_pos = poker_state.playing_position
					player.nPlayer.start_action_timer()
			elif last_state != poker_state.state:
				player.nPlayer.reset_action_timer()
				last_playing_pos = -1
		else:
			player.nPlayer.set_is_dealt(false)
			player.nPlayer.set_is_current(true)
		
		if (state_player.id != account.id) || !poker_state || !poker_state.is_dealt:
			player.nPlayer.set_cards([])
		else:
			player.nPlayer.set_cards(poker_state.hand_cards)
		player.nPlayer.set_balance(player.state_player.balance)
		player.nPlayer.set_is_left(player.state_player.is_left)
		player.nPlayer.update()

	var new_players: Array[PlayersCirclePlayer] = []
	
	for i in range(players.size()):
		for j in range(p_players.size()):
			if p_players[j].id == players[i].state_player.id:
				new_players.append(players[i])
				break
	
	players = new_players

func move_player_chips_to(account_id: int, to_position: Vector2):
	print("move_player_chips_to("+str(account_id)+", "+str(to_position)+")")
	
	if account.id == account_id:
		nPlayer.move_chips_to(to_position)
		return
	
	for i in range(players.size()):
		var player: PlayersCirclePlayer = players[i];

		if player.state_player.id != account_id:
			continue
		
		player.nPlayer.call_deferred("move_chips_to", to_position)

func get_player_by_account_id(account_id: int) -> PlayersCirclePlayer:
	for player in players:
		if player.state_player.id == account_id:
			return player
	
	return null

func _on_item_rect_changed():
	var rect := get_rect()

	var mx: float = rect.end.x - rect.position.x
	var my: float = rect.end.y - rect.position.y

func _on_TakeSeatButton_enter(nTakeSeatButton: TakeSeatButton, enterance_amount: int) -> void:
	print("Taking seat at: " + str(nTakeSeatButton.position_index))
	take_seat.emit(nTakeSeatButton.position_index, enterance_amount)
	ASounds.play_bop()
