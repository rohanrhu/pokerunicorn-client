# PokerUnicorn Game Client
# Copyright (C) 2023, Oğuzhan Eroğlu <meowingcate@gmail.com> (https://meowingcat.io)
# https://rohanrhu.github.io/pokerunicorn-website/

extends Control
class_name TableList

signal refreshing

@onready var cTableListItem = load("res://Scenes/TableList/TableListItem.tscn")

@export var style_odd: StyleBox
@export var style_even: StyleBox
@export var style_hover: StyleBox = null

@onready var nItems: VBoxContainer = %Items
@onready var nLengthOptionButton: OptionButton = %LengthOptionButton

@onready var nList = %List
@onready var nPleaseLogin = %PleaseLogin

var items = {}

var appear_duration = 1

func _ready():
	pass

func _process(delta):
	if ALoginDialog.account:
		nPleaseLogin.hide()
		nList.show()

func _update_style() -> void:
	for i in nItems.get_child_count():
		var nItem: TableListItem = nItems.get_child(i)
		if i % 2 == 0:
			nItem.add_theme_stylebox_override("panel", style_odd)
		else:
			nItem.add_theme_stylebox_override("panel", style_even)

func get_item(p_index: int) -> TableListItem:
	return nItems.get_child(p_index)

func load_tables(tables: TPacket.TTables) -> void:
	var i = 0
	
	for nItem in nItems.get_children():
		if !nItem.is_entered:
			nItem.disappear(i, nItems.get_child_count())
			i += 1
	
	if i > 0:
		await get_tree().create_timer(appear_duration).timeout
	
	for id in items.keys():
		var incoming: TPacket.TTable = tables.get_by_id(id)
		if !incoming:
			var existing: TableListItem = items[id]["nItem"]
			if !existing.is_entered:
				existing.queue_free()
				items.erase(id)

	i = 0
	
	for _table in tables.tables:
		var table: TPacket.TTable = _table

		var nItem: TableListItem

		var item
		if items.has(table.id):
			item = items[table.id]
			nItem = item["nItem"]
			nItems.move_child(nItem, i)
		else:
			nItem = cTableListItem.instantiate()
			nItem.appear_duration = appear_duration
			if style_hover:
				nItem.style_hover = style_hover
			nItems.add_child(nItem)
			item = {}
			items[table.id] = item
			item["nItem"] = nItem

		item["table"] = table
		nItem.table = table
		
		if !nItem.is_entered:
			nItem.appear(i, tables.length)
		
		i += 1
	
	_update_style()

func refresh() -> void:
	var offset = 0
	var length = int(nLengthOptionButton.get_item_text(nLengthOptionButton.selected))
	
	emit_signal("refreshing", offset, length)

func _on_RefreshButton_pressed() -> void:
	var offset = 0
	var length = int(nLengthOptionButton.get_item_text(nLengthOptionButton.selected))
	
	emit_signal("refreshing", offset, length)

func _on_LoginBtn_pressed() -> void:
	ADialogs.open_single(ALoginDialog)
