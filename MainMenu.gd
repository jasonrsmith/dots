extends MarginContainer

onready var cursor: Label = find_node("Cursor")
onready var menu_items: VBoxContainer = find_node("MenuItems")

var _menu_item_list
var _currently_selected_item

signal menu_item_selected

func _process(delta: float) -> void:
	self.repositionCursor()


func _ready() -> void:
	self._menu_item_list = menu_items.get_children()
	self._currently_selected_item = 0


func _unhandled_input(ev) -> void:
	if !visible:
		return
	if Input.is_action_just_pressed("ui_up"):
		self.cursorUp()
	if Input.is_action_just_pressed("ui_down"):
		self.cursorDown()
	if Input.is_action_just_pressed("ui_accept"):
		self.acceptSelection()
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func repositionCursor() -> void:
	cursor.margin_top = self._menu_item_list[_currently_selected_item].margin_top + 10


func cursorUp() -> void:
	self._currently_selected_item = self._menu_item_list.size() - 1 if self._currently_selected_item == 0 else self._currently_selected_item - 1	


func cursorDown() -> void:
	self._currently_selected_item = (self._currently_selected_item + 1) % self._menu_item_list.size()


func acceptSelection() -> void:
	self.emit_signal('menu_item_selected', _menu_item_list[_currently_selected_item].name)

