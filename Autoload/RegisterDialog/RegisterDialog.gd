extends Control
class_name RegisterDialog

signal opened
signal closed

@onready var nAnimationPlayer = $AnimationPlayer
@onready var nConfirmAnimationPlayer = $ConfirmAnimationPlayer
@onready var nLayer = $CanvasLayer/Layer
@onready var nBox = %Box
@onready var nWarningLabel = %WarningLabel

@onready var nIdTokenInput: LineEdit = %IdTokenInput
@onready var nNameInput: LineEdit = %NameInput
@onready var nPasswordInput: LineEdit = %PasswordInput
@onready var nPasswordAgainInput: LineEdit = %PasswordAgainInput
@onready var nIdTokenConfirmInput: LineEdit = %IdTokenConfirmInput
@onready var nSubmitBtn: Button = %SubmitBtn
@onready var nConfirmBtn: Button = %ConfirmBtn

@onready var nWaitingLayer: Control = %WaitingLayer

@onready var poker_client: PokerClient = APokerClient

var is_opened: bool = false
var is_confirmation_opened: bool = false
var id_token: String = ""
var account: TPacket.TAccount = null

func _ready():
	nLayer.visible = false
	nWarningLabel.hide()
	nWaitingLayer.hide()
	
	APokerClient.signup_res.connect(_on_signup_res)

func _process(delta):
	nBox.pivot_offset.x = nBox.size.x / 2
	nBox.pivot_offset.y = nBox.size.y / 2

func open() -> void:
	var id = BigCat.BigNumber.from_random(256)
	id_token = id.to_hex()
	
	nIdTokenInput.text = id_token
	
	is_opened = true
	ASounds.play_pop(0.25)
	nAnimationPlayer.play("Open")
	opened.emit()
	
	await nAnimationPlayer.animation_finished
	
	nIdTokenInput.grab_focus()
	
	nIdTokenConfirmInput.text = ""
	nConfirmBtn.disabled = true

func close() -> void:
	await close_confirmation()
	
	is_opened = false
	ASounds.play_bop()
	nAnimationPlayer.play("Close")
	await nAnimationPlayer.animation_finished
	closed.emit()

func open_confirmation() -> void:
	if is_confirmation_opened:
		return
	
	is_confirmation_opened = true
	ASounds.play_bop()
	nConfirmAnimationPlayer.play("Open")
	await nConfirmAnimationPlayer.animation_finished
	nIdTokenConfirmInput.grab_focus()

func close_confirmation() -> void:
	if !is_confirmation_opened:
		return
	
	is_confirmation_opened = false
	ASounds.play_bop()
	nConfirmAnimationPlayer.play("Close")
	await nConfirmAnimationPlayer.animation_finished

func clear_warning():
	nWarningLabel.hide()

func warn_invalid(message: String):
	ASounds.play_wrong()
	nWarningLabel.text = message
	nWarningLabel.show()
	
	var tween := get_tree().create_tween()
	tween.tween_property(%Box, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(%Box, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(%Box, "scale", Vector2(1, 1), 0.1)

func warn_error(message: String):
	ASounds.play_wrong()
	nWarningLabel.text = message
	nWarningLabel.show()
	
	var tween := get_tree().create_tween()
	tween.tween_property(%Box, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(%Box, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(%Box, "scale", Vector2(1, 1), 0.1)

func validate() -> bool:
	clear_warning()
	
	var name = nNameInput.text
	var password = nPasswordInput.text
	var password_again = nPasswordAgainInput.text
	
	if (id_token.length() < 42) or (id_token.substr(0, 2) != "0x"):
		warn_invalid("Please provide a valid ID token")
		nIdTokenInput.grab_focus()
		return false
	if name.length() < 5:
		warn_invalid("Please provide a nickname at least 5 chars")
		nNameInput.grab_focus()
		return false
	if password.length() < 6:
		warn_invalid("Please provide a password at least 6 chars")
		nPasswordInput.grab_focus()
		return false
	if password != password_again:
		warn_invalid("Passwords are not same")
		nPasswordAgainInput.grab_focus()
		return false
	
	return true

func submit():
	var name = nNameInput.text
	var password = nPasswordInput.text
	var password_again = nPasswordAgainInput.text
	
	nIdTokenConfirmInput.text = ""
	nConfirmBtn.disabled = true
	
	nWaitingLayer.show()
	
	poker_client.send_signup(id_token, password, name)

func _on_signup_res(signup_res: TPacket.TSignupRes) -> void:
	nWaitingLayer.hide()
	
	if signup_res.status == TPacket.TSignupRes.STATUS.ALREADY_EXISTS:
		warn_error("This ID token is already in use :)")
		return
	
	if !signup_res.is_ok:
		warn_error("Something went wrong :(")
		return
	
	account = signup_res.account
	ALoginDialog.account = account
	
	if signup_res.is_logined:
		close()
	else:
		close()

func _on_SubmitBtn_pressed() -> void:
	var is_valid = validate()
	if is_valid:
		open_confirmation()

func _on_CloseButton_pressed() -> void:
	close()

func _on_LoginBtn_pressed() -> void:
	close()

func _input(event: InputEvent) -> void:
	if !is_instance_of(event, InputEventKey):
		return
	
	if !is_opened:
		return
	if !event.is_pressed():
		return
	if event.echo:
		return
	
	if is_confirmation_opened:
		if event.keycode == KEY_ENTER:
			var is_valid = validate()
			if is_valid:
				submit()
			else:
				close_confirmation()
		elif event.keycode == KEY_ESCAPE:
			close_confirmation()
	else:
		if event.keycode == KEY_ENTER:
			var is_valid = validate()
			if is_valid:
				open_confirmation()
		elif event.keycode == KEY_ESCAPE:
			close()

func _on_IdTokenConfirmInput_text_changed(new_text):
	if new_text.strip_edges() == id_token:
		nConfirmBtn.disabled = false
	else:
		nConfirmBtn.disabled = true

func _on_ConfirmBtn_pressed():
	var is_valid = validate()
	
	if is_valid:
		submit()

func _on_ConfirmPopupBgCloserBtn_pressed():
	close_confirmation()
