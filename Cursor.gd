extends Node2D

onready var Board = get_parent()

var throb_dir = -1.0

func bump(inputDirection):
	print("bump")

func getInputDirection():
	if Input.is_action_just_pressed("ui_cursor_left"):
		return Vector2(-1, 0)
	if Input.is_action_just_pressed("ui_cursor_right"):
		return Vector2(1, 0)

func updateThrob(delta):
	modulate.a += throb_dir * delta / 2
	if modulate.a < 0.75 || modulate.a > 1.25:
		throb_dir *= -1

func moveTo(targetPosition):
	$Tween.interpolate_property(self, "position", position, targetPosition, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()

func _unhandled_input(event):
	var inputDirection = getInputDirection()
	if !inputDirection:
		return

	var targetPosition = Board.requestMoveCursor(inputDirection)
	if targetPosition:
		moveTo(targetPosition)
	else:
		bump(inputDirection)

func _process(delta):
	updateThrob(delta)
