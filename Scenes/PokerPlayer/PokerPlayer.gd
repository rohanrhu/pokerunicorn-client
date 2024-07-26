# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

@tool

extends Control
class_name PokerPlayer

@export var current_style: StyleBox
@export var allin_style: StyleBox
@export var default_style: StyleBox

@onready var nAnimationPlayer: AnimationPlayer = $AnimationPlayer
@onready var nBox: PanelContainer = $HBoxContainer/Content/Box
@onready var nBox_AnimationPlayer: AnimationPlayer = $HBoxContainer/Content/Box/AnimationPlayer
@onready var nAvatar: PanelContainer = $HBoxContainer/Content/Box/HBoxContainer/Avatar
@onready var nAvatarTextureRect: TextureRect = $HBoxContainer/Content/Box/HBoxContainer/Avatar/AvatarTextureRect
@onready var nNameLabel: Label = $HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Name/NameLabel
@onready var nCards: Control = $HBoxContainer/Content/Cards
@onready var nCard1: Control = $HBoxContainer/Content/Cards/VBoxContainer/Card1
@onready var nCard2: Control = $HBoxContainer/Content/Cards/VBoxContainer/Card2
@onready var nBalanceLabel: Label = $HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Balance/BalanceLabel
@onready var nBet: Control = $Bet
@onready var nBetChips: Chips = $Bet/BetChips
@onready var nAllin: Control = $HBoxContainer/Content/Allin
@onready var nActionTimerBar = $HBoxContainer/Content/ActionTimerBar
@onready var nChipsPosition: Control = null

enum SIDING {
	LEFT,
	RIGHT
}

@export var siding: SIDING = SIDING.LEFT

var account_id: int = 0

var is_left := false
var is_playing := false
var is_folded := false
var is_allin := false
var is_dealt := false
var is_current := false
@onready var balance: int

var cards: Array[TPoker.TCard]

var action_timeout: int
var action_timer_start: int
var is_action_timer_running: bool = false

var avatar: TPacket.TAvatar = null

func _ready() -> void:
	nCards.visible = false
	default_style = nBox.get_theme_stylebox("panel")
	
	nChipsPosition = get_node_or_null("ChipsPosition")
	
	if nChipsPosition:
		nBet.global_position = nChipsPosition.global_position
		nBet.scale = nChipsPosition.scale
	
	if !Engine.is_editor_hint():
		balance = 0
		nBox.material = nBox.material.duplicate()

var prev_siding = siding

func _process(delta: float) -> void:
	if prev_siding != siding:
		prev_siding = siding
		if siding == SIDING.LEFT:
			nBox.get_node("HBoxContainer").move_child(nAvatar, 0)
			$HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Name/NameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			$HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Balance/BalanceLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			nBox.get_node("HBoxContainer").move_child(nAvatar, 1)
			$HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Name/NameLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			$HBoxContainer/Content/Box/HBoxContainer/VBoxContainer/Balance/BalanceLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	nChipsPosition = get_node_or_null("ChipsPosition")
	
	if nChipsPosition:
		nBet.global_position = nChipsPosition.global_position
		nBet.scale = nChipsPosition.scale * 0.5
	
	if is_action_timer_running:
		var elapsed = Time.get_ticks_msec() - action_timer_start
		var left = action_timeout - elapsed
		nActionTimerBar.value = left
		var ratio = elapsed / float(action_timeout)
		
		var style_box: StyleBoxFlat = nActionTimerBar.get_theme_stylebox("fill")
		var g = 1.0 - ratio
		var r = ratio
		var color: Color = Color(r, g, 0, 1)
		style_box.bg_color = color
		
		if elapsed >= action_timeout:
			is_action_timer_running = false

func set_is_left(p_is_left: bool):
	is_left = p_is_left

func set_is_playing(p_is_playing: bool):
	is_playing = p_is_playing

func set_is_folded(p_is_folded: bool):
	is_folded = p_is_folded

func set_is_allin(p_is_allin: bool):
	is_allin = p_is_allin

func set_is_current(p_is_current: bool):
	is_current = p_is_current
	nActionTimerBar.visible = is_current
	is_action_timer_running = is_current

func set_is_dealt(p_is_dealt: bool):
	is_dealt = p_is_dealt

func set_cards(p_cards: Array[TPoker.TCard]):
	cards = p_cards

func set_balance(p_balance: int):
	balance = p_balance
	nBalanceLabel.text = Monero.pico2label(balance)
	nBetChips.set_value(Monero.pico2xmr(balance))
	await nBetChips.update()

func move_chips_to(to_position: Vector2):
	nBetChips.move_to(to_position)

func update():
	if is_current:
		nBox_AnimationPlayer.play("Current")
	else:
		nBox_AnimationPlayer.play("NotCurrent")

	if is_playing && !is_left:
		modulate = Color(modulate.r, modulate.g, modulate.b, 1)
	else:
		modulate = Color(modulate.r, modulate.g, modulate.b, 0.5)

	if is_folded:
		nAvatarTextureRect.self_modulate.a = 0.5
	else:
		nAvatarTextureRect.self_modulate.a = 1
	
	if is_allin:
		nAllin.show()
	else:
		nAllin.hide()

	nCards.visible = is_playing && is_dealt

	if is_dealt && cards.size() == 2:
		nCard1.get_node("Back").visible = false
		nCard2.get_node("Back").visible = false
		nCard1.get_node("Card").visible = true
		nCard2.get_node("Card").visible = true

		nCard1.get_node("Card").set_kind(cards[0].kind)
		nCard1.get_node("Card").set_value(cards[0].index)
		nCard2.get_node("Card").set_kind(cards[1].kind)
		nCard2.get_node("Card").set_value(cards[1].index)
	else:
		nCard1.get_node("Back").visible = true
		nCard2.get_node("Back").visible = true
		nCard1.get_node("Card").visible = false
		nCard2.get_node("Card").visible = false

func set_player_id(p_id: int):
	account_id = p_id

func set_player_name(p_name: String):
	nNameLabel.text = p_name

func set_avatar(p_avatar: TPacket.TAvatar):
	avatar = p_avatar
	
	if avatar:
		print("Loading image " + str(avatar.data.size()) + " bytes...")
		
		var file_path = "user://avatar-" + str(account_id) + "." + avatar.mime.extension
		
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		file.store_buffer(avatar.data)
		file.close()
		
		var image := Image.load_from_file(file_path)
		nAvatarTextureRect.texture = ImageTexture.create_from_image(image)
		
		#DirAccess.remove_absolute("user://avatar." + avatar.mime.extension)
	else:
		nAvatarTextureRect.texture = load("res://Assets/Sprites/no-avatar.png")

func set_action_timeout(p_msecs: int) -> void:
	action_timeout = p_msecs
	nActionTimerBar.max_value = p_msecs

func start_action_timer() -> void:
	action_timer_start = Time.get_ticks_msec()
	is_action_timer_running = true

func reset_action_timer() -> void:
	is_action_timer_running = false
	nActionTimerBar.hide()

func _on_mouse_entered():
	nAnimationPlayer.play("Hover")

func _on_mouse_exited():
	nAnimationPlayer.play("Blur")
