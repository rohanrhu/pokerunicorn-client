extends Control
class_name Dialogs

var DIALOGS = [
	ALoginDialog,
	ARegisterDialog
]

func _ready():
	pass

func _process(delta):
	pass

func open_single(dialog) -> void:
	for other in DIALOGS:
		if (other != dialog) && other.is_opened:
			other.close()
	
	dialog.open()
