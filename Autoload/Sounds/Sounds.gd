extends Control

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func play_pop(start_delay: float = 0) -> void:
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	%PopPlayer.play()

func play_bop(start_delay: float = 0) -> void:
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	%BopPlayer.play()

func play_fail(start_delay: float = 0) -> void:
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	%FailPlayer.play()

func play_wrong(start_delay: float = 0) -> void:
	if start_delay > 0:
		await get_tree().create_timer(start_delay).timeout
	%WrongPlayer.play()
