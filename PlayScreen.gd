extends Node2D

signal leave_screen

func leaveScreen():
	print("leave_screen")
	emit_signal("leave_screen")

func _ready():
	$LeaveGameDialog.connect("confirmed", self, "leaveScreen")

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel") && $LeaveGameDialog.visible == false:
		$LeaveGameDialog.popup_centered()
		get_tree().set_input_as_handled()