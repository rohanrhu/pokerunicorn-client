# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name ChipsStack

var chip_values: Array
var chip_textures: Array[Texture2D]

@onready var nChipProto: TextureRect = $ChipProto
@onready var nChips: Control = $Chips

var value: int = 0
var number: int = 1

func _ready() -> void:
	for i in range(8):
		chip_textures.append(load("res://Assets/Sprites/Chips/chip-" + str(i+1) + ".png"))

func _process(delta: float) -> void:
	pass

func set_chip_values(p_chip_values: Array):
	chip_values = p_chip_values

func set_value(p_value: int):
	value = p_value

func set_number(p_number: int):
	number = p_number

func update():
	for i in range(nChips.get_child_count()):
		nChips.get_child(i).queue_free()

	for i in range(number):
		var nChip: TextureRect = nChipProto.duplicate()
		nChip.texture = chip_textures[chip_values.find(value)]
		nChip.visible = true
		nChip.set_position(Vector2(nChip.position.x, nChip.position.y - (8 * i)))
		nChips.add_child(nChip)
