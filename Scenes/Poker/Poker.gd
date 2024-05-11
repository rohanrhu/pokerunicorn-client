# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name Poker

signal enter_failed(table_id: int)
signal join_failed(table_id: int)
signal entered(table_id: int)
signal left(table_id: int)

@onready var nDevTools: Control = %DevTools
@onready var nDevTools_AnimationPlayer: AnimationPlayer = %DevTools/AnimationPlayer
@onready var nDevTools_AddressInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Address/AddressInput
@onready var nDevTools_PortInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Address/PortInput
@onready var nDevTools_TableIdInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Join/TableIdInput
@onready var nDevTools_EnteranceAmountInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Join/EnteranceAmountInput
@onready var nDevTools_IdTokenInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Login/IdTokenInput
@onready var nDevTools_PasswordInput: TextEdit = %DevTools/PanelContainer/VBoxContainer/Login/PasswordInput
@onready var nWinTitle: WinTitle = %WinTitle
@onready var nPlayersCircle: PlayersCircle = %PlayersCircle
@onready var nRaiseBtn: Button = %RaiseBtn
@onready var nAllInBtn: Button = %AllInBtn
@onready var nRaiseSlider: HSlider = %RaiseSlider
@onready var nRaiseToLabel: Label = %RaiseToLabel
@onready var nPositionLabel: Label = %PositionLabel
@onready var nPlayingPositionLabel: Label = %PlayingPositionLabel
@onready var nPotAmountLabel: Label = %PotAmountLabel
@onready var nPot: Control = %Pot
@onready var nPotLabel: Label = %PotLabel
@onready var nPotChips: Chips = %PotChips
@onready var nBoard = %Board
@onready var nStarting: Control = %Starting
@onready var nStarting_AnimationPlayer: AnimationPlayer = %Starting/AnimationPlayer
@onready var nYouWon: Control = %YouWon
@onready var nYouWon_AnimationPlayer: AnimationPlayer = %YouWon/AnimationPlayer
@onready var nAction = %Action
@onready var nGameLogsLabel = %GameLogsLabel

@onready var nAudioPlayerFlop = %AudioPlayerFlop
@onready var nAudioPlayerHand = %AudioPlayerHand
@onready var nAudioPlayerDeal = %AudioPlayerDeal
@onready var nAudioPlayerRaise = %AudioPlayerRaise
@onready var nAudioPlayerCheck = %AudioPlayerCheck
@onready var nAudioPlayerCall = %AudioPlayerCall
@onready var nAudioPlayerWinner = %AudioPlayerWinner

var account: TPacket.TAccount = null

@export var table_id: int = 0
@export var is_devtools_opened := true

var poker_info: TPacket.TPokerInfo = null
var poker_state: TPacket.TPokerState = null

var is_entered := false
var is_joined := false

var players: Array[PlayersCircle.PlayersCirclePlayer] = []

func _ready() -> void:
	connect_event_handlers()
	
	randomize()
	
	nYouWon.hide()
	nAction.hide()
	nStarting.hide()
	
	nGameLogsLabel.text = ""

func _process(delta: float) -> void:
	pass

func connect_event_handlers() -> void:
	APokerClient.pong.connect(_on_pong)
	APokerClient.login_res.connect(_on_login_res)
	APokerClient.enter_res.connect(_on_enter_res)
	APokerClient.join_res.connect(_on_join_res)
	APokerClient.poker_info.connect(_on_poker_info)
	APokerClient.poker_state.connect(_on_poker_state)
	APokerClient.poker_action_reflection.connect(_on_poker_action_reflection)
	APokerClient.poker_end.connect(_on_poker_end)
	APokerClient.poker_restarted.connect(_on_poker_restarted)
	APokerClient.unjoined.connect(_on_unjoined)
	APokerClient.leave_res.connect(_on_leave_res)

func disconnect_event_handlers() -> void:
	APokerClient.pong.disconnect(_on_pong)
	APokerClient.login_res.disconnect(_on_login_res)
	APokerClient.enter_res.disconnect(_on_enter_res)
	APokerClient.join_res.disconnect(_on_join_res)
	APokerClient.poker_info.disconnect(_on_poker_info)
	APokerClient.poker_state.disconnect(_on_poker_state)
	APokerClient.poker_action_reflection.disconnect(_on_poker_action_reflection)
	APokerClient.poker_end.disconnect(_on_poker_end)
	APokerClient.poker_restarted.disconnect(_on_poker_restarted)
	APokerClient.unjoined.disconnect(_on_unjoined)
	APokerClient.leave_res.disconnect(_on_leave_res)

func toggle_dev_tools():
	is_devtools_opened = !is_devtools_opened

	if is_devtools_opened:
		nDevTools_AnimationPlayer.play("Open")
	else:
		nDevTools_AnimationPlayer.play("Close")

func enter_table(p_table_id: int):
	if !APokerClient.is_connected:
		print("Not connected to serverrrrr!!!!!!!!!!!!!!!")
		return
	
	table_id = p_table_id
	
	APokerClient.send_enter(table_id)
	
	toggle_dev_tools()

func set_account(p_account: TPacket.TAccount) -> void:
	account = p_account
	nPlayersCircle.set_account(account)
	%PlayerIdLabel.text = str(account.id)

func starting() -> void:
	nStarting_AnimationPlayer.play("Appear")
	nGameLogsLabel.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	nGameLogsLabel.add_text("Hand is starting...")
	nGameLogsLabel.pop_all()

func started() -> void:
	nStarting_AnimationPlayer.play("Disappear")
	nYouWon_AnimationPlayer.play("Disappear")
	
	nGameLogsLabel.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	nGameLogsLabel.push_color(Color.GREEN)
	nGameLogsLabel.add_text("Hand started!")
	nGameLogsLabel.pop_all()

func waiting() -> void:
	nStarting_AnimationPlayer.play("Disappear")

func _on_login_res(login_res: TPacket.TLoginRes):
	print("LoginRes receivedddddd")
	print("LoginRes.IsOk: ", login_res.is_ok)
	print("LoginRes.IsLogined: ", login_res.is_logined)
	print("LoginRes.Account.Id: ", login_res.account.id)
	print("LoginRes.Account.Name: ", login_res.account.name)
	print("LoginRes.Account.Avatar: ", login_res.account.avatar)
	print("LoginRes.Account.Balance: ",login_res.account.balance)

	set_account(login_res.account)

func _on_pong():
	pass

func _on_enter_res(enter_res: TPacket.TEnterRes):
	if enter_res.table_id != table_id:
		return
	
	print("TEnterRes receivedddddd")
	print("TEnterRes.IsOk: ", enter_res.is_ok)
	
	is_entered = enter_res.is_ok
	
	if !is_entered:
		print("Entering failed")
		enter_failed.emit(table_id)
		return
	
	entered.emit(table_id)

func _on_join_res(join_res: TPacket.TJoinRes):
	if join_res.table_id != table_id:
		return
	
	print("JoinRes receivedddddd")
	print("JoinRes.IsOk: ", join_res.is_ok)
	
	is_joined = join_res.is_ok
	nPlayersCircle.set_is_joined(is_joined)
	
	if !is_joined:
		print("Joining failed")
	
func _on_poker_info(p_poker_info: TPacket.TPokerInfo):
	if p_poker_info.table_id != table_id:
		return
	
	print("PokerInfo receivedddddd")
	print("PokerInfo.TableId: ", p_poker_info.table_id)
	
	poker_info = p_poker_info
	
	nPlayersCircle.set_poker_info(poker_info)
	nPlayersCircle.set_max_players(poker_info.max_players)
	nPlayersCircle.set_players(poker_info.players, [])
	
	nAction.hide()
	
	nWinTitle.set_title(poker_info.name)
	nWinTitle.set_left_info(
		"SB: " + Monero.pico2label(poker_info.small_blind) + ", " +
		"BB: " + Monero.pico2label(poker_info.big_blind)
	)
	nWinTitle.set_right_info(
		"Buy: " +
		Monero.pico2label(poker_info.enterance_min) + " - " +
		Monero.pico2label(poker_info.enterance_max)
	)
	
	var new_players: Array[TPacket.TStatePlayer] = []
	
	for player in poker_info.players:
		var is_exists = false
		
		for existing_player in players:
			if player.id == existing_player.state_player.id:
				is_exists = true
		
		if not is_exists:
			new_players.append(player)
	
	for player in new_players:
		nGameLogsLabel.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
		nGameLogsLabel.push_color(Color.GREEN)
		nGameLogsLabel.add_text(player.name + " joined the game!")
		nGameLogsLabel.pop_all()
	
	players = nPlayersCircle.players.duplicate()
	
func _on_poker_state(p_poker_state: TPacket.TPokerState):
	if p_poker_state.table_id != table_id:
		return
	
	var prev_state = poker_state
	var is_state_changed = poker_state != p_poker_state
	poker_state = p_poker_state
	
	print("PokerState receivedddddd")
	print("PokerState.TableId: " + str(poker_state.table_id))
	
	if is_state_changed:
		if poker_state.state == TPoker.STATE.STARTING:
			starting()
		elif (!prev_state || (prev_state.state == TPoker.STATE.STARTING)) && (poker_state.state > TPoker.STATE.STARTING):
			started()
		else:
			waiting()

	nPositionLabel.text = str(poker_state.position)
	nPlayingPositionLabel.text = str(poker_state.playing_position)
	nPotAmountLabel.text = Monero.pico2label(poker_state.pot_amount)

	nPotLabel.text = "Pot: " + Monero.pico2label(poker_state.pot_amount)
	nPotChips.set_value(Monero.pico2xmr(poker_state.pot_amount))
	nPotChips.update()

	nPlayersCircle.set_player_position(poker_state.position)
	nPlayersCircle.set_poker_state(poker_state)
	nPlayersCircle.set_players(poker_state.players, poker_state.hand_cards)

	if poker_state.is_playing && (poker_state.state > TPoker.STATE.BIG_BLIND) && (poker_state.state < TPoker.STATE.DONE):
		nAction.show()
	else:
		nAction.hide()

	for i in range(poker_state.players.size()):
		var player := poker_state.players[i]
	
	if poker_state.state < TPoker.STATE.FLOP:
		pass
	elif is_state_changed:
		if poker_state.state >= TPoker.STATE.FLOP:
			nBoard.set_flop(poker_state.cards)
			if poker_state.state == TPoker.STATE.FLOP:
				nBoard.flop()
				%AudioPlayerFlop.play()
		if poker_state.state >= TPoker.STATE.TURN:
			nBoard.set_turn(poker_state.cards[3])
			if poker_state.state == TPoker.STATE.TURN:
				nBoard.turn()
		if poker_state.state == TPoker.STATE.RIVER:
			nBoard.set_river(poker_state.cards[4])
			nBoard.river()
		if poker_state.state == TPoker.STATE.DONE:
			nBoard.set_flop(poker_state.cards)
			nBoard.set_turn(poker_state.cards[3])
			nBoard.set_river(poker_state.cards[4])
			nBoard.done()
	
	if poker_state.balance >= poker_state.current_raise:
		var rmin = poker_state.current_bet + poker_state.current_raise
		var rmax = poker_state.balance + poker_state.bet
		var rmin_xmr = Monero.pico2xmr(rmin) * 100
		var rmax_xmr = Monero.pico2xmr(rmax) * 100

		nRaiseSlider.min_value = rmin_xmr
		nRaiseSlider.max_value = rmax_xmr
		
		if nRaiseSlider.min_value != nRaiseSlider.max_value:
			nRaiseSlider.show()
			nRaiseBtn.show()
			nAllInBtn.hide()
		else:
			nRaiseSlider.hide()
			nRaiseBtn.hide()
			nAllInBtn.show()
			nRaiseToLabel.text = Monero.pico2label(poker_state.balance + poker_state.bet)
	else:
		nRaiseSlider.hide()
		nRaiseBtn.hide()
		nRaiseToLabel.text = Monero.pico2label(poker_state.balance + poker_state.bet)
		if poker_state.balance > 0:
			nAllInBtn.show()
		else:
			nAllInBtn.hide()
	
	nRaiseSlider.value = nRaiseSlider.min_value
	
	if poker_state.state >= TPoker.STATE.DONE:
		nPotAmountLabel.hide()
	elif poker_state.state >= TPoker.STATE.PREFLOP:
		nPotAmountLabel.show()
	
func _on_poker_action_reflection(poker_action_reflection: TPacket.TPokerActionReflection):
	if poker_action_reflection.table_id != table_id:
		return
	
	print("PokerActionReflection receivedddddd")
	print("PokerActionReflection.TableId: ", poker_action_reflection.table_id)
	print("PokerActionReflection.AccountId: ", poker_action_reflection.account_id)

	if (poker_action_reflection.amount > 0) && (poker_action_reflection.account_id > 0):
		nPlayersCircle.call_deferred("move_player_chips_to", poker_action_reflection.account_id, nPotChips.global_position)
	
	if poker_action_reflection.action_kind <= TPoker.ACTION_KIND.BIG_BLIND:
		%AudioPlayerCheck.play()
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.CHECK:
		%AudioPlayerCheck.play()
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.RAISE:
		%AudioPlayerRaise.play()
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.FOLD:
		%AudioPlayerHand.play()
	
	var player = nPlayersCircle.get_player_by_account_id(poker_action_reflection.account_id)
	
	nGameLogsLabel.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	if poker_action_reflection.action_kind == TPoker.ACTION_KIND.SMALL_BLIND:
		nGameLogsLabel.push_color(Color.GRAY)
		nGameLogsLabel.add_text(player.state_player.name + " puts SB " + Monero.pico2label(poker_action_reflection.amount))
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.BIG_BLIND:
		nGameLogsLabel.push_color(Color.GRAY)
		nGameLogsLabel.add_text(player.state_player.name + " puts BB " + Monero.pico2label(poker_action_reflection.amount))
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.RAISE:
		nGameLogsLabel.push_color(Color.BLUE)
		nGameLogsLabel.add_text(player.state_player.name + " raised to " + Monero.pico2label(poker_action_reflection.amount))
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.CHECK:
		nGameLogsLabel.push_color(Color.GREEN)
		nGameLogsLabel.add_text(player.state_player.name + " checked")
	elif poker_action_reflection.action_kind == TPoker.ACTION_KIND.FOLD:
		nGameLogsLabel.push_color(Color.RED)
		nGameLogsLabel.add_text(player.state_player.name + " folded!")
	nGameLogsLabel.pop_all()
	
func _on_poker_end(poker_end: TPacket.TPokerEnd):
	if poker_end.table_id != table_id:
		return
	
	print("PokerEnd receivedddddd")
	print("PokerEnd.TableId: ", poker_end.table_id)
	print("PokerEnd.WinnerAccountId: ", poker_end.winner_account_id)

	if account.id == poker_end.winner_account_id:
		nYouWon_AnimationPlayer.play("Appear")
		%AudioPlayerWinner.play()
	
	nGameLogsLabel.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	nGameLogsLabel.add_text("Hand finished!")
	nGameLogsLabel.pop_all()
	
func _on_poker_restarted(poker_restarted: TPacket.TPokerRestarted):
	if poker_restarted.table_id != table_id:
		return
	
	print("PokerRestarted receivedddddd")
	print("PokerRestarted.TableId: ", poker_restarted.table_id)

	nYouWon_AnimationPlayer.play("Disappear")
	ASounds.play_bop()
	
	nBoard.reset()

func _on_unjoined(unjoined: TPacket.TUnjoined):
	if unjoined.table_id != table_id:
		return

	is_joined = false
	nPlayersCircle.set_is_joined(is_joined)

func _on_DevTools_ConnectBtn_pressed():
	if APokerClient.is_connected:
		print("Already connecteddddddddddd")
		return
	
	var address = nDevTools_AddressInput.text
	var port = int(nDevTools_PortInput.text)

	APokerClient.connect_to_server(address, port)

func _on_DevTools_LoginBtn_pressed():
	if !APokerClient.is_connected:
		print("Not connected to serverrrrr!!!!!!!!!!!!!!!")
		return

	var id_token = nDevTools_IdTokenInput.text
	var password = nDevTools_PasswordInput.text

	APokerClient.send_login(id_token, password)

func _on_DevTools_EnterBtn_pressed():
	if !APokerClient.is_connected:
		print("Not connected to serverrrrr!!!!!!!!!!!!!!!")
		return

	var _table_id = int(nDevTools_TableIdInput.text)
	
	APokerClient.send_enter(_table_id)
	table_id = _table_id
	
	toggle_dev_tools()

func _on_RaiseBtn_pressed():
	if !poker_state:
		return
	
	var xmr_amount = nRaiseSlider.value
	var amount = xmr_amount * 10000000000
	
	APokerClient.send_action(table_id, TPoker.ACTION_KIND.RAISE, amount)

func _on_AllInBtn_pressed() -> void:
	if !poker_state:
		return
	
	var raise_to = poker_state.balance + poker_state.bet
	
	APokerClient.send_action(table_id, TPoker.ACTION_KIND.RAISE, raise_to)

func _on_CheckBtn_pressed():
	if !poker_state:
		return
	
	APokerClient.send_action(table_id, TPoker.ACTION_KIND.CHECK)

func _on_FoldBtn_pressed():
	if !poker_state:
		return
	
	APokerClient.send_action(table_id, TPoker.ACTION_KIND.FOLD)

func _on_PlayersCircle_take_seat(position_index: int, enterance_amount: int) -> void:
	APokerClient.send_join(table_id, enterance_amount, position_index)

func _on_RaiseSlider_value_changed(value: int) -> void:
	if !poker_state:
		return
	
	var raise_to = value * 10000000000
	nRaiseToLabel.text = Monero.pico2label(raise_to)

func _on_DevTools_ToggleButton_pressed():
	toggle_dev_tools()

func _on_WinTitle_quitting() -> void:
	if is_entered:
		APokerClient.send_leave(poker_info.table_id)

func _on_leave_res(leave_res: TPacket.TLeaveRes) -> void:
	if table_id == leave_res.table_id:
		emit_signal("left", table_id)
