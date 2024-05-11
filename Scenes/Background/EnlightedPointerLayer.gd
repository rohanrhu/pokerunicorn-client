# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Panel

func _process(delta):
	var x = get_viewport().get_mouse_position().x / get_viewport_rect().size.x
	var y = get_viewport().get_mouse_position().y / get_viewport_rect().size.y
	var pos = Vector2(x, y)
	
	material.set_shader_parameter("lighting_point", pos)
