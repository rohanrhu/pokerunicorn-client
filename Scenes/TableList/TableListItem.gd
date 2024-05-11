# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends PanelContainer
class_name TableListItem

@export var table_id: int

@export var style_default: StyleBox
@export var style_entered: StyleBox
@export var style_hover: StyleBox

@onready var cPoker: PackedScene = load("res://Scenes/Poker/Poker.tscn")

@onready var nNameLabel: Label = %NameLabel
@onready var nSmallBlindLabel: Label = %SmallBlindLabel
@onready var nBigBlindLabel: Label = %BigBlindLabel
@onready var nPlayersCountLabel: Label = %PlayersCountLabel
@onready var nEnterBtn: Button = %EnterBtn

var is_entered := false : set = set_is_entered
var nTableList: TableList = null
var table: TPacket.TTable: set = set_table
var nPoker: Poker = null
var appear_duration = 1.5

func _ready():
	style_default = get_theme_stylebox("panel")
	modulate.a = 0
	
	ASessions.entered_session.connect(_on_entered_session)
	ASessions.left_session.connect(_on_left_session)

func _process(delta):
	nEnterBtn.pivot_offset.x = nEnterBtn.size.x / 2
	nEnterBtn.pivot_offset.y = nEnterBtn.size.y / 2

func set_table(p_table: TPacket.TTable) -> void:
	table = p_table
	table_id = table.id
	
	nNameLabel.text = table.name
	nSmallBlindLabel.text = Monero.pico2label(table.small_blind)
	nBigBlindLabel.text = Monero.pico2label(table.big_blind)
	nPlayersCountLabel.text = str(table.players_count)

func set_is_entered(p_is_entered: bool) -> void:
	is_entered = p_is_entered
	
	nEnterBtn.disabled = is_entered
	
	if is_entered && style_entered:
		add_theme_stylebox_override("panel", style_entered)

func appear(idx: int, total: int) -> void:
	var tween = get_tree().create_tween()
	
	var duration = (float(idx) / total) * appear_duration
	tween.tween_property(self, "modulate:a", 1, duration)

func disappear(idx: int, total: int) -> void:
	var tween = get_tree().create_tween()
	
	var duration = (float(idx) / total) * appear_duration
	tween.tween_property(self, "modulate:a", 0, duration)

func _on_entered_session(p_table_id: int) -> void:
	if p_table_id != table_id:
		return
	
	set_is_entered(true)

func _on_left_session(p_table_id: int) -> void:
	if p_table_id != table_id:
		return
	
	set_is_entered(false)

func _on_EnterBtn_pressed() -> void:
	ASounds.play_bop()
	ALoading.open()
	ASessions.enter_session(table_id)
	ALoading.close()

func _on_mouse_entered() -> void:
	add_theme_stylebox_override("panel", style_hover)

func _on_mouse_exited() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func _on_EnterBtn_mouse_entered() -> void:
	if is_entered:
		return
	
	ASounds.play_bop()
	
	var tween = get_tree().create_tween()
	tween.tween_property(nEnterBtn, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(nEnterBtn, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(nEnterBtn, "scale", Vector2(1, 1), 0.05)


func _on_EnterBtn_mouse_exited() -> void:
	if is_entered:
		return
	
	ASounds.play_bop()
	
	var tween = get_tree().create_tween()
	tween.tween_property(nEnterBtn, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(nEnterBtn, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(nEnterBtn, "scale", Vector2(1, 1), 0.05)
