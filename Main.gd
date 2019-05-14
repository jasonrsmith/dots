extends Node2D

export (PackedScene) var play_screen

var play_screen_instance

func leaveCurrentGame():
	remove_child(play_screen_instance)
	find_node("MainMenu").visible = true

func startNewGame():
	find_node("MainMenu").visible = false
	play_screen_instance = play_screen.instance()
	add_child(play_screen_instance)
	play_screen_instance.connect("leave_screen", self, "leaveCurrentGame")

func _input(ev):
	if Input.is_action_just_pressed("ui_toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

func _on_menu_item_selected(menuItem):
	match menuItem:
		"MenuItemStart":
			startNewGame()
		"MenuItemQuit":
			get_tree().quit()

func _ready():
	$MainMenu.connect('menu_item_selected', self, '_on_menu_item_selected')
