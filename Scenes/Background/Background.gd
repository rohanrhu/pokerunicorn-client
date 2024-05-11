# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Panel

@export var is_web_styled: bool = false
@export var stylebox__web: StyleBox = null

func _ready() -> void:
	if (OS.get_name() == "Web") && is_web_styled && (stylebox__web != null):
		add_theme_stylebox_override("panel", get_theme_stylebox("panel").duplicate())
		get_theme_stylebox("panel").set_corner_radius_all(0)
		$Panel.add_theme_stylebox_override("panel", stylebox__web)

func _process(delta: float) -> void:
	pass
