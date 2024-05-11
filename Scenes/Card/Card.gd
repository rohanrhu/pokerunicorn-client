# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name Card

@onready var nKindImage1: TextureRect = %KindImage1;
@onready var nKindImage2: TextureRect = %KindImage2;

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func set_kind(kind: TPoker.CARD_KIND):
	if kind == TPoker.CARD_KIND.CLUB:
		nKindImage1.texture = load("res://Assets/Sprites/Kinds/club.png")
		nKindImage2.texture = load("res://Assets/Sprites/Kinds/club.png")
	elif kind == TPoker.CARD_KIND.DIAMOND:
		nKindImage1.texture = load("res://Assets/Sprites/Kinds/diamond.png")
		nKindImage2.texture = load("res://Assets/Sprites/Kinds/diamond.png")
	elif kind == TPoker.CARD_KIND.HEART:
		nKindImage1.texture = load("res://Assets/Sprites/Kinds/heart.png")
		nKindImage2.texture = load("res://Assets/Sprites/Kinds/heart.png")
	elif kind == TPoker.CARD_KIND.SPADE:
		nKindImage1.texture = load("res://Assets/Sprites/Kinds/spade.png")
		nKindImage2.texture = load("res://Assets/Sprites/Kinds/spade.png")

func set_value(value: int):
	if value >= TPoker.CARD_SYMBOLS.size():
		print_debug("value >= TPoker.CARD_SYMBOLS.size() is true")
		return

	var label: String = TPoker.CARD_SYMBOLS[value]

	get_node("%ValueLabel1").text = label
	get_node("%ValueLabel2").text = label
