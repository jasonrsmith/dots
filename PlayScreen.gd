extends Node2D

onready var leave_game_dialog: Popup = $LeaveGameDialog
onready var lose_game_dialog: Popup = $LoseGameDialog
onready var player_board: Board = $PlayerBoard
onready var opponent_board: Board = $opponentBoard

signal leave_screen

func _ready():
	leave_game_dialog.connect("confirmed", self, "leave_screen")
	player_board.connect('board_full', self, '_on_PlayerBoard_board_full')


func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel") && leave_game_dialog.visible == false:
		leave_game_dialog.popup_centered()
		get_tree().set_input_as_handled()


func leave_screen() -> void:
	emit_signal("leave_screen")


func _on_PlayerBoard_board_full() -> void:
	lose_game_dialog.popup_centered()