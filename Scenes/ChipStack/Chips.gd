# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name Chips

@onready var nStacks: Control = %Stacks
@onready var nChipStackProto: ChipsStack = %ChipStackProto

@export var duration_factor := 0.2

var chip_values: Array = [
	int(5.0 * 100),
	int(2.0 * 100),
	int(1.0 * 100),
	int(0.5 * 100),
	int(0.25 * 100),
	int(0.1 * 100),
	int(0.025 * 100),
	int(0.01 * 100),
];

var value: int = 0
var min_optimal_pieces: int = 3

var stacks := []

func _ready() -> void:
	nChipStackProto.visible = false

func _process(delta: float) -> void:
	pass

func set_value(p_value: float):
	value = int(p_value * 100)

func update():
	var pieces := resolve_pieces()

	clear();

	for i in range(pieces.size()):
		var piece = pieces[i];
		
		var nStack: ChipsStack = nChipStackProto.duplicate()
		nStack.position = Vector2(nStack.position.x + (i * 40), nStack.position.y)
		nStack.name = "Stack"
		nStack.visible = true
		nStacks.add_child(nStack)
		stacks.append(nStack)

		nStack.set_chip_values(chip_values)
		nStack.set_number(piece[0])
		nStack.set_value(piece[1])
		nStack.update()

func resolve_pieces() -> Array:
	var pieces = []
	
	var current: int = value
	var division: int
	var modulo: int

	for i in range(chip_values.size()):
		division = int(current / chip_values[i])
		modulo = current % chip_values[i]

		if division > 0:
			pieces.append([division, chip_values[i]])

		if modulo == 0:
			break

		current = modulo
	
	return pieces

func clear():
	for i in range(stacks.size()):
		stacks[i].queue_free()
	
	stacks.clear()

func move_to(to_position: Vector2):
	var tween := get_tree().create_tween()
	
	var _stacks = [];

	for i in range(stacks.size()):
		var nStack: ChipsStack = stacks[i]
		if nStack.is_queued_for_deletion() or not (nStack.is_node_ready() && nStack.is_inside_tree()):
			breakpoint
		nStack.cancel_free()
		for _node in nStack.get_children():
			_node.cancel_free()
		var nStackToAnim: ChipsStack = nStack.duplicate(DUPLICATE_SCRIPTS)
		_stacks.append(nStackToAnim)
		add_child(nStackToAnim)
		nStackToAnim.global_position = nStack.global_position

		var duration = duration_factor * i

		tween.parallel().tween_property(nStackToAnim, "global_position", to_position, duration).set_ease(Tween.EASE_OUT)

	await tween.finished

	for i in range(_stacks.size()):
		if _stacks[i] != null:
			_stacks[i].queue_free()
