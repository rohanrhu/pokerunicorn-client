# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control

@onready var nFlopAnimationPlayer: AnimationPlayer = $FlopAnimationPlayer
@onready var nTurnAnimationPlayer: AnimationPlayer = $TurnAnimationPlayer
@onready var nRiverAnimationPlayer: AnimationPlayer = $RiverAnimationPlayer

var animation_state: TPoker.STATE = TPoker.STATE.CREATED

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func set_flop(cards: Array[TPoker.TCard]) -> void:
	for i in range(3):
		var card: TPoker.TCard = cards[i];
		var nCard: Card = get_node("%BoardCard" + str(i+1));
		
		nCard.set_kind(card.kind);
		nCard.set_value(card.index);
		nCard.visible = true;

func set_turn(card: TPoker.TCard) -> void:
	var nCard: Card = get_node("%BoardCard4")
	nCard.set_kind(card.kind)
	nCard.set_value(card.index)

func set_river(card: TPoker.TCard) -> void:
	var nCard: Card = get_node("%BoardCard5")
	nCard.set_kind(card.kind)
	nCard.set_value(card.index)

func flop() -> void:
	if animation_state >= TPoker.STATE.FLOP:
		return

	nFlopAnimationPlayer.play("Flop")

	animation_state = TPoker.STATE.FLOP

func turn() -> void:
	if animation_state >= TPoker.STATE.TURN:
		return

	nTurnAnimationPlayer.play("Turn");

	animation_state = TPoker.STATE.TURN;

func river() -> void:
	if animation_state >= TPoker.STATE.RIVER:
		return

	nRiverAnimationPlayer.play("River");

	animation_state = TPoker.STATE.RIVER

func done() -> void:
	if animation_state < TPoker.STATE.FLOP:
		nFlopAnimationPlayer.play("Flop");
		await nFlopAnimationPlayer.animation_finished
	if animation_state < TPoker.STATE.TURN:
		nTurnAnimationPlayer.play("Turn");
		await nTurnAnimationPlayer.animation_finished
	if animation_state < TPoker.STATE.RIVER:
		nRiverAnimationPlayer.play("River");
	
	animation_state = TPoker.STATE.RIVER

func reset() -> void:
	nFlopAnimationPlayer.play("RESET")
	nTurnAnimationPlayer.play("RESET")
	nRiverAnimationPlayer.play("RESET")
	
	animation_state = TPoker.STATE.CREATED
