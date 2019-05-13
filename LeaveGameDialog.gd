extends ConfirmationDialog

func _unhandled_input(event):
	if visible and popup_exclusive:
		get_tree().set_input_as_handled()