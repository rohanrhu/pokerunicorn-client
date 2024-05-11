extends Control
class_name UserBox

@onready var nBox = %Box
@onready var nButton: Button = %Button
@onready var nAvatarTextureRect = $NotOpened/AvatarTextureRect
@onready var nOpenedBgLayer = %OpenedBgLayer
@onready var nNotOpened = %NotOpened
@onready var nOpened = %Opened
@onready var nOpenedAvatar = %OpenedAvatar
@onready var nBackground = %Background
@onready var nOpenedSized = %OpenedSized
@onready var nSaveButton = %SaveButton
@onready var nFreeform = %Freeform
@onready var nChangeAvatarButton = %ChangeAvatarButton
@onready var nNameInput = %NameInput
@onready var nDepositAddressInput = %DepositAddressInput
@onready var nNameLabel = %NameLabel
@onready var nAvatarFileDialog = %AvatarFileDialog
@onready var nBoxAvatarTextureRect = %BoxAvatarTextureRect

var account: TPacket.TAccount = null: set = set_account

var box_original_position := Vector2.ZERO
var box_original_size := Vector2.ZERO
var box_original_z_index := 0
var box_clip_contents := false

var box_opened_anchor_left: float
var box_opened_anchor_top: float
var box_opened_anchor_right: float
var box_opened_anchor_bottom: float
var box_opened_offset_left: float
var box_opened_offset_top: float
var box_opened_offset_right: float
var box_opened_offset_bottom: float

var avatar_original_offset_top: int
var avatar_original_offset_bottom: int
var avatar_original_offset_left: int
var avatar_original_offset_right: int

var is_opened := false
var is_opening := false
var is_closing := false
var is_updating := false

var avatar_data: PackedByteArray = []
var current_avatar_texture = null

var _js_interop_on_avatar_selected = JavaScriptBridge.create_callback(_js_on_avatar_selected)

func _ready() -> void:
	APokerClient.update_account_res.connect(_on_update_account_res)
	
	nButton.show()
	nNotOpened.show()
	nOpened.hide()
	nBox.hide()
	nFreeform.hide()
	
	box_opened_anchor_left = nOpenedSized.anchor_left
	box_opened_anchor_top = nOpenedSized.anchor_top
	box_opened_anchor_right = nOpenedSized.anchor_right
	box_opened_anchor_bottom = nOpenedSized.anchor_bottom
	box_opened_offset_left = nOpenedSized.offset_left
	box_opened_offset_top = nOpenedSized.offset_top
	box_opened_offset_right = nOpenedSized.offset_right
	box_opened_offset_bottom = nOpenedSized.offset_bottom
	
	avatar_original_offset_top = nOpenedAvatar.offset_top
	avatar_original_offset_bottom = nOpenedAvatar.offset_bottom
	avatar_original_offset_left = nOpenedAvatar.offset_left
	avatar_original_offset_right = nOpenedAvatar.offset_right

func _process(delta: float) -> void:
	pivot_offset.x = size.x / 2
	pivot_offset.y = size.y / 2

func set_account(p_account: TPacket.TAccount) -> void:
	account = p_account
	
	if account:
		%NameLabel.text = account.name
		%BalanceLabel.text = Monero.pico2label(account.balance)
	else:
		%NameLabel.text = "Not logged in"
		%BalanceLabel.text = "Login or register to play"
	
	if account.avatar:
		print("Loading image " + str(account.avatar.data.size()) + " bytes...")
		
		var file := FileAccess.open("user://avatar." + account.avatar.mime.extension, FileAccess.WRITE)
		file.store_buffer(account.avatar.data)
		file.close()
		
		var image := Image.load_from_file("user://avatar." + account.avatar.mime.extension)
		nAvatarTextureRect.texture = ImageTexture.create_from_image(image)
		if not nAvatarFileDialog.current_file:
			nBoxAvatarTextureRect.texture = ImageTexture.create_from_image(image)
		
		DirAccess.remove_absolute("user://avatar." + account.avatar.mime.extension)
	else:
		nAvatarTextureRect.texture = load("res://Assets/Sprites/no-avatar.png")
		nBoxAvatarTextureRect.texture = load("res://Assets/Sprites/no-avatar.png")

func open() -> void:
	if is_opened || is_opening || is_closing:
		return
	
	nNameInput.text = account.name
	nDepositAddressInput.text = account.xmr_deposit_address
	
	ASounds.play_pop(0.1)
	
	var nPoker: Poker = find_parent("Poker")
	
	is_opened = true
	is_opening = true
	
	nButton.hide()
	
	box_original_position = global_position
	box_original_size = size
	box_original_z_index = nBox.z_index
	box_clip_contents = nBox.clip_contents
	nBox.top_level = true
	nBox.global_position = box_original_position
	nBox.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	
	nFreeform.show()
	nOpenedBgLayer.show()
	nOpenedBgLayer.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
	nOpenedBgLayer.top_level = true
	nOpenedBgLayer.set_anchors_preset(PRESET_FULL_RECT)
	nOpenedBgLayer.set_offsets_preset(PRESET_FULL_RECT)
	
	nOpened.show()
	nBox.show()
	
	nBox.modulate.a = 1
	
	nOpenedAvatar.offset_top = avatar_original_offset_top - 50
	nOpenedAvatar.offset_bottom = avatar_original_offset_bottom - 50
	nOpenedAvatar.offset_left = avatar_original_offset_left + 50
	nOpenedAvatar.offset_right = avatar_original_offset_right - 50
	nOpenedAvatar.modulate.a = 0
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(nOpened, "modulate:a", 1, 0.09)
	tween.parallel().tween_property(nBox, "modulate:a", 1, 0.1)
	tween.parallel().tween_property(nBox, "anchor_left", box_opened_anchor_left - 0.05, 0.15)
	tween.parallel().tween_property(nBox, "anchor_top", box_opened_anchor_top - 0.05, 0.15)
	tween.parallel().tween_property(nBox, "anchor_right", box_opened_anchor_right + 0.05, 0.15)
	tween.parallel().tween_property(nBox, "anchor_bottom", box_opened_anchor_bottom + 0.05, 0.15)
	tween.parallel().tween_property(nBox, "offset_left", box_opened_offset_left, 0.15)
	tween.parallel().tween_property(nBox, "offset_top", box_opened_offset_top, 0.15)
	tween.parallel().tween_property(nBox, "offset_right", box_opened_offset_right, 0.15)
	tween.parallel().tween_property(nBox, "offset_bottom", box_opened_offset_bottom, 0.15)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nBox, "anchor_left", box_opened_anchor_left, 0.1)
	tween.parallel().tween_property(nBox, "anchor_top", box_opened_anchor_top, 0.1)
	tween.parallel().tween_property(nBox, "anchor_right", box_opened_anchor_right, 0.1)
	tween.parallel().tween_property(nBox, "anchor_bottom", box_opened_anchor_bottom, 0.1)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nOpenedAvatar, "modulate:a", 1, 0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_top", avatar_original_offset_top - 20, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_bottom", avatar_original_offset_bottom + 20, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_left", avatar_original_offset_left + 20, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_right", avatar_original_offset_right - 20, 0.15)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_top", avatar_original_offset_top, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_bottom", avatar_original_offset_bottom, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_left", avatar_original_offset_left, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_right", avatar_original_offset_right, 0.15)
	
	await tween.finished
	
	is_opening = false

func close() -> void:
	if !is_opened || is_opening || is_closing:
		return
	
	ASounds.play_bop(0.1)
	
	is_closing = true
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(nOpenedAvatar, "modulate:a", 1, 0.05)
	tween.tween_property(nOpened, "modulate:a", 0, 0.05)
	await tween.finished
	nOpened.hide()
	tween.stop()
	tween.parallel().tween_property(nOpenedAvatar, "offset_top", avatar_original_offset_top - 20, 0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_bottom", avatar_original_offset_bottom + 20, 0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_left", avatar_original_offset_left + 20, 0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_right", avatar_original_offset_right - 20, 0.1)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nOpenedAvatar, "offset_top", avatar_original_offset_top - 50, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_bottom", avatar_original_offset_bottom - 50, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_left", avatar_original_offset_left + 50, 0.15)
	tween.parallel().tween_property(nOpenedAvatar, "offset_right", avatar_original_offset_right - 50, 0.15)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nBox, "anchor_left", box_opened_anchor_left - 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_top", box_opened_anchor_top - 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_right", box_opened_anchor_right + 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_bottom", box_opened_anchor_bottom + 0.05, 0.175)
	tween.parallel().tween_property(nBox, "modulate:a", 0, 0.25)
	tween.parallel().tween_property(nOpened, "modulate:a", 0, 0.25)
	tween.parallel().tween_property(nBox, "global_position", box_original_position, 0.25)
	tween.parallel().tween_property(nBox, "size", box_original_size, 0.25)
	tween.play()
	
	await tween.finished
	
	nBox.top_level = false
	nBox.global_position = box_original_position
	box_original_position = Vector2.ZERO
	nBox.set_anchors_preset(PRESET_TOP_LEFT)
	nBox.z_index = box_original_z_index
	
	nButton.show()
	nOpenedBgLayer.hide()
	nBox.hide()
	nOpenedBgLayer.top_level = false
	
	await get_tree().create_timer(0.1).timeout
	nOpened.hide()
	nFreeform.hide()
	
	nBox.size = box_original_size
	nBox.clip_contents = box_clip_contents
	
	is_opened = false
	is_closing = false

func submit_update() -> void:
	if is_updating:
		return
	
	nNameInput.editable = false
	is_updating = true
	
	current_avatar_texture = nAvatarTextureRect.texture
	
	print("Sending avatar: ", avatar_data.size(), " bytes")
	APokerClient.send_update_account(nNameInput.text, avatar_data)
	close()

func _on_Button_pressed() -> void:
	if account:
		open()
	else:
		ADialogs.open_single(ALoginDialog)

func _on_Button_mouse_entered() -> void:
	ASounds.play_bop()

	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)

func _on_Button_mouse_exited() -> void:
	ASounds.play_bop()
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)

func _input(event: InputEvent) -> void:
	if !is_instance_of(event, InputEventKey) || !is_opened || !event.is_pressed() || event.echo:
		return
	
	if event.keycode == KEY_ENTER:
		submit_update()
	elif event.keycode == KEY_ESCAPE:
		close()

func _on_SaveButton_pressed() -> void:
	submit_update()

func _on_OpenedBgLayer_Button_pressed() -> void:
	close()

func _on_ChangeAvatarButton_pressed() -> void:
	if OS.get_name() == "Web":
		var interop := JavaScriptBridge.get_interface("GameInterop")
		interop.openAvatarDialog(_js_interop_on_avatar_selected)
	else:
		nAvatarFileDialog.popup_centered()

func _on_AvatarFileDialog_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	var file = FileAccess.open(path, FileAccess.READ)
	avatar_data = file.get_buffer(file.get_length())
	avatar_data.insert(0, TPacket.TMime.from_path(path).type)
	
	var texture = ImageTexture.create_from_image(image)
	nBoxAvatarTextureRect.texture = texture

func _on_update_account_res(update_account_res: TPacket.TUpdateAccountRes) -> void:
	if update_account_res.is_ok:
		current_avatar_texture = nBoxAvatarTextureRect.texture
		nAvatarTextureRect.texture = current_avatar_texture
		nNameLabel.text = nNameInput.text
		account.name = nNameInput.text
	else:
		nBoxAvatarTextureRect.texture = current_avatar_texture
	
	nNameInput.editable = true
	is_updating = false

func _js_on_avatar_selected(args: Array):
	print("_js_interop_on_avatar_selected(): args: ", args)
	
	var avatar_file = args[0]
	var avatar_data_buff = args[1]
	
	var mime = TPacket.TMime.from_path(avatar_file.name)
	
	avatar_data = PackedByteArray()
	
	print("Avatar file: ", avatar_file.name)
	print("Avatar length: ", avatar_data_buff.length)
	
	avatar_data.resize(avatar_data_buff.length)
	
	for i in range(avatar_data_buff.length):
		avatar_data.encode_u8(i, avatar_data_buff[i])
	
	avatar_data.insert(0, mime.type)
	
	var file := FileAccess.open("user://avatar." + mime.extension, FileAccess.WRITE)
	file.store_buffer(avatar_data)
	file.close()
	
	var image := Image.load_from_file("user://avatar." + mime.extension)
	nBoxAvatarTextureRect.texture = ImageTexture.create_from_image(image)
	
	DirAccess.remove_absolute("user://avatar." + account.avatar.mime.extension)
