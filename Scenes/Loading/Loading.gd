# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name Loading

func _ready() -> void:
	%Layer.hide()

func open() -> void:
	%Layer.show()

func close() -> void:
	%Layer.hide()

func _process(delta: float) -> void:
	pass

func _on_AnimateTimer_timeout() -> void:
	%AnimationPlayer.play("Bounce")
