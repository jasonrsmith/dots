extends Node2D

export (PackedScene) var player_board

func _input(ev):
	if Input.is_action_just_pressed("ui_up"):
		$PlayerBoard.onInputUp()
	if Input.is_action_just_pressed("ui_down"):
		$PlayerBoard.onInputDown()
	if Input.is_action_just_pressed("ui_left"):
		$PlayerBoard.onInputLeft()
	if Input.is_action_just_pressed("ui_right"):
		$PlayerBoard.onInputRight()

	if Input.is_action_just_pressed("ui_toggle_fullscreen"):
		print("fullscreen")
		OS.window_fullscreen = !OS.window_fullscreen

func _ready():
	pass