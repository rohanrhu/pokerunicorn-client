extends Control
class_name LoginDialog

signal account_updated

@onready var nAnimationPlayer = $AnimationPlayer
@onready var nLayer = $CanvasLayer/Layer
@onready var nBox = %Box
@onready var nWarningLabel = %WarningLabel
@onready var nIdTokenInput: LineEdit = %IdTokenInput
@onready var nPasswordInput: LineEdit = %PasswordInput
@onready var nSubViewportContainer = %SubViewportContainer

var is_opened: bool = false
var account: TPacket.TAccount: set = set_account

var is_registering = false

func set_account(p_account: TPacket.TAccount):
	account = p_account
	emit_signal("account_updated")

func _ready():
	nLayer.visible = false
	
	APokerClient.login_res.connect(_on_login_res)
	
	ARegisterDialog.opened.connect(_on_ARegisterDialog_opened)
	ARegisterDialog.closed.connect(_on_ARegisterDialog_closed)
	
	if (APokerClient.host == "127.0.0.1") or (APokerClient.host == "localhost"):
		nPasswordInput.text = "123456"
	
	nWarningLabel.hide()

func _process(delta):
	nBox.pivot_offset.x = nBox.size.x / 2
	nBox.pivot_offset.y = nBox.size.y / 2
	
	nSubViewportContainer.pivot_offset.x = nSubViewportContainer.size.x / 2
	nSubViewportContainer.pivot_offset.y = nSubViewportContainer.size.y / 2

func warn_error(message: String):
	ASounds.play_wrong()
	nWarningLabel.text = message
	nWarningLabel.show()
	
	var tween := get_tree().create_tween()
	tween.tween_property(nSubViewportContainer, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(nSubViewportContainer, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(nSubViewportContainer, "scale", Vector2(1, 1), 0.1)

func open() -> void:
	is_opened = true
	nAnimationPlayer.play("Open")
	ASounds.play_pop(0.25)
	nIdTokenInput.grab_focus()

func close() -> void:
	is_opened = false
	nAnimationPlayer.play("Close")
	ASounds.play_bop()

func submit() -> bool:
	var id_token = nIdTokenInput.text
	var password = nPasswordInput.text
	
	if (APokerClient.host != "127.0.0.1") and (APokerClient.host != "localhost") and id_token.length() < 42:
		warn_error("Please provide a valid ID token")
		nIdTokenInput.grab_focus()
		return false
	if password.length() < 6:
		warn_error("Please provide a password at least 6 chars")
		nPasswordInput.grab_focus()
		return false
	
	APokerClient.send_login(id_token, password)
	
	return true

func _on_RegisterBtn_pressed():
	is_registering = true
	ASounds.play_bop()
	ARegisterDialog.open()
	nAnimationPlayer.play("StageDown")

func _on_CloseBtn_pressed() -> void:
	close()

func _on_LoginBtn_pressed() -> void:
	submit()

func _on_login_res(login_res: TPacket.TLoginRes):
	if !login_res.is_ok:
		warn_error("Something went wrong :(")
		return
	if !login_res.is_logined:
		warn_error("Your credentials were wrong :(")
		return
	
	account = login_res.account
	close()

func _on_CloseButton_pressed() -> void:
	close()

func _on_ARegisterDialog_opened() -> void:
	pass

func _on_ARegisterDialog_closed() -> void:
	if is_registering:
		$AnimationPlayer.play("StageUp")
		await $AnimationPlayer.animation_finished
		
		is_registering = false
		
		if ARegisterDialog.account:
			account = ARegisterDialog.account
			close()
			return
		
		nIdTokenInput.grab_focus()

func _input(event: InputEvent) -> void:
	if !is_instance_of(event, InputEventKey):
		return
	
	if !is_opened:
		return
	if is_registering:
		return
	if !event.is_pressed():
		return
	if event.echo:
		return
	
	if event.keycode == KEY_ENTER:
		submit()
	elif event.keycode == KEY_ESCAPE:
		if !is_registering:
			close()
