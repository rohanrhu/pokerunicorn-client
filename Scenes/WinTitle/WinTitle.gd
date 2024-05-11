extends PanelContainer
class_name WinTitle

signal quitting

@onready var nCloseButton = %CloseButton

var is_moving := false
var move_start_position := Vector2.ZERO

var title := "": set = set_title

func _ready() -> void:
	%VersionLabel.text = AppInfo.VERSION_STR
	
	if "--pretend-web" in OS.get_cmdline_args():
		%PretendingWebLabel.show()
	else:
		%PretendingWebLabel.hide()

func _process(delta: float) -> void:
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_moving = false

func move_window_to(pos) -> void:
	if OS.get_name() == "Web":
		get_window().position = Vector2i(pos)
	else:
		DisplayServer.window_set_position(
			pos,
			get_window().get_window_id()
		)

func set_title(p_title: String) -> void:
	title = p_title
	%TitleLabel.text = title

func set_left_info(p_text: String) -> void:
	%LeftInfoLabel.text = p_text
	
func set_right_info(p_text: String) -> void:
	%RightInfoLabel.text = p_text

func _on_Button_button_down() -> void:
	is_moving = true
	move_start_position = get_window().get_mouse_position()

func _on_Button_button_up() -> void:
	is_moving = false

func _on_PanelContainer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			is_moving = false
	
	if (event is InputEventMouseMotion) and is_moving:
		move_window_to(DisplayServer.mouse_get_position() - Vector2i(move_start_position))

func _on_CloseButton_pressed() -> void:
	emit_signal("quitting")

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			is_moving = false
