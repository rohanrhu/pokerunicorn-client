extends Control
class_name TakeSeatButton

signal enter(nTakeSeatButton: TakeSeatButton, enterance_amount: int)

@export var position_index: int = 0

@onready var nBox = %Box
@onready var nButton = %Button
@onready var nOpenedBgLayer = %OpenedBgLayer
@onready var nContent = %Content
@onready var nNotOpened = %NotOpened
@onready var nOpened = %Opened
@onready var nOpenedSized = %OpenedSized
@onready var nEnteranceAmountSlider: HSlider = %EnteranceAmountSlider
@onready var nEnteranceAmountLabel: Label = %EnteranceAmountLabel

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

var is_opened := false
var is_opening := false
var is_closing := false

var enterance_amount: int

func _ready() -> void:
	nContent.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	nButton.show()
	nNotOpened.show()
	nOpened.hide()
	
	box_opened_anchor_left = nOpenedSized.anchor_left
	box_opened_anchor_top = nOpenedSized.anchor_top
	box_opened_anchor_right = nOpenedSized.anchor_right
	box_opened_anchor_bottom = nOpenedSized.anchor_bottom
	box_opened_offset_left = nOpenedSized.offset_left
	box_opened_offset_top = nOpenedSized.offset_top
	box_opened_offset_right = nOpenedSized.offset_right
	box_opened_offset_bottom = nOpenedSized.offset_bottom

func _process(delta: float) -> void:
	pivot_offset.x = size.x / 2
	pivot_offset.y = size.y / 2

func open() -> void:
	if is_opened || is_opening || is_closing:
		return
	
	ASounds.play_pop(0.1)
	
	var nPoker: Poker = find_parent("Poker")

	var emin = nPoker.poker_info.enterance_min
	var emax = nPoker.poker_info.enterance_max
	var emin_xmr = Monero.pico2xmr(emin) * 100
	var emax_xmr = Monero.pico2xmr(emax) * 100

	nEnteranceAmountSlider.min_value = emin_xmr
	nEnteranceAmountSlider.max_value = emax_xmr
	
	is_opened = true
	is_opening = true
	
	nButton.hide()
	
	box_original_position = nBox.global_position
	box_original_size = nBox.size
	box_original_z_index = nBox.z_index
	box_clip_contents = nBox.clip_contents
	nBox.top_level = true
	nBox.global_position = box_original_position
	nBox.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	nBox.clip_contents = true
	
	nOpenedBgLayer.show()
	nOpenedBgLayer.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
	nOpenedBgLayer.top_level = true
	nOpenedBgLayer.set_anchors_preset(PRESET_FULL_RECT)
	nOpenedBgLayer.set_offsets_preset(PRESET_FULL_RECT)
	
	nNotOpened.hide()
	nOpened.show()
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(nOpened, "modulate:a", 1, 0.15)
	tween.parallel().tween_property(nNotOpened, "modulate:a", 0, 0.15)
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
	
	await tween.finished
	
	is_opening = false

func close() -> void:
	if !is_opened || is_opening || is_closing:
		return
	
	ASounds.play_bop(0.1)
	
	is_closing = true
	
	var tween = get_tree().create_tween()
	tween.parallel().tween_property(nOpened, "modulate:a", 0, 0.15)
	tween.parallel().tween_property(nNotOpened, "modulate:a", 1, 0.175)
	tween.parallel().tween_property(nBox, "anchor_left", box_opened_anchor_left - 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_top", box_opened_anchor_top - 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_right", box_opened_anchor_right + 0.05, 0.175)
	tween.parallel().tween_property(nBox, "anchor_bottom", box_opened_anchor_bottom + 0.05, 0.175)
	tween.tween_interval(0.1)
	tween.parallel().tween_property(nBox, "global_position", box_original_position, 0.25)
	tween.parallel().tween_property(nBox, "size", box_original_size, 0.25)
	
	await tween.finished
	
	nBox.top_level = false
	nBox.global_position = box_original_position
	box_original_position = Vector2.ZERO
	nBox.set_anchors_preset(PRESET_TOP_LEFT)
	nBox.z_index = box_original_z_index
	
	nButton.show()
	nOpenedBgLayer.hide()
	nOpenedBgLayer.top_level = false
	
	await get_tree().create_timer(0.1).timeout
	
	nNotOpened.show()
	nOpened.hide()
	
	nBox.size = box_original_size
	nBox.clip_contents = box_clip_contents
	
	is_opened = false
	is_closing = false

func _on_Button_pressed() -> void:
	open()

func _on_Button_mouse_entered() -> void:
	if is_opened || is_opening || is_closing:
		return
	
	ASounds.play_bop()

	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_interval(0.05)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)

func _on_Button_mouse_exited() -> void:
	if is_opened || is_opening || is_closing:
		return
	
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
		pass
	elif event.keycode == KEY_ESCAPE:
		close()

func _on_OpenedBgLayer_Button_pressed() -> void:
	close()

func _on_EnteranceAmountSlider_value_changed(value: int) -> void:
	var nPoker: Poker = find_parent("Poker")
	enterance_amount = value * 10000000000
	nEnteranceAmountLabel.text = Monero.pico2label(enterance_amount)

func _on_CloseButton_pressed() -> void:
	close()

func _on_EnterButton_pressed() -> void:
	close()
	enter.emit(self, enterance_amount)
