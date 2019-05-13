extends Node2D

export (PackedScene) var player_board

var player_board_instance

func startNewGame():
	find_node("MainMenu").visible = false
	player_board_instance = player_board.instance()
	add_child(player_board_instance)

func _input(ev):
	if Input.is_action_just_pressed("ui_toggle_fullscreen"):
		print("fullscreen")
		OS.window_fullscreen = !OS.window_fullscreen

func _on_menu_item_selected(menuItem):
	match menuItem:
		"MenuItemStart":
			startNewGame()
		"MenuItemQuit":
			get_tree().quit()

func _ready():
	$MainMenu.connect('menu_item_selected', self, '_on_menu_item_selected')
	$LeaveGameDialog.popup()