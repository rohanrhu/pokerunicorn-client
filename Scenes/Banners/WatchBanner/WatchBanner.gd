extends PanelContainer

func _ready() -> void:
	$AnimationPlayer.play("Idle")

func _process(delta: float) -> void:
	%CardsIcon.pivot_offset = %CardsIcon.size * 0.5
