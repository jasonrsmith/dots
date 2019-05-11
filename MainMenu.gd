extends MarginContainer

var menuItems
var selectedItem

signal menu_item_selected

func repositionCursor():
	find_node("Cursor").margin_top = self.menuItems[selectedItem].margin_top + 10

func cursorUp():
	self.selectedItem = self.menuItems.size() - 1 if self.selectedItem == 0 else self.selectedItem - 1	

func cursorDown():
	self.selectedItem = (self.selectedItem + 1) % self.menuItems.size()

func acceptSelection():
	self.emit_signal('menu_item_selected', menuItems[selectedItem].name)

func _process(delta):
	self.repositionCursor()

func _ready():
	self.menuItems = find_node("Menu").get_children()
	self.selectedItem = 0

func _input(ev):
	if Input.is_action_just_pressed("ui_up"):
		self.cursorUp()
	if Input.is_action_just_pressed("ui_down"):
		self.cursorDown()
	if Input.is_action_just_pressed("ui_accept"):
		self.acceptSelection()