extends ConfirmationDialog

func _unhandled_input(event):
	if visible and popup_exclusive:
		if Input.is_action_just_pressed("ui_cancel"):
			visible = false
		get_tree().set_input_as_handled()

