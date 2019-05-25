extends Node2D
class_name Cursor

onready var move_tween: Tween = $MoveTween

var _throb_dir: = -1.0
var _board

func initialize(board) -> Cursor:
	_board = board
	return self


func _process(delta) -> void:
	_update_throb(delta)


func check_for_input() -> bool:
	var input_direction = _get_input_direction()
	if !input_direction:
		return false

	var target_position = _board.request_move_cursor(input_direction)
	if target_position:
		_move_to(target_position)
	else:
		_bump(input_direction)
	return true


func _bump(input_direction):
	print("bump")


func _get_input_direction():
	if Input.is_action_just_pressed("ui_cursor_left"):
		return Vector2(-1, 0)
	if Input.is_action_just_pressed("ui_cursor_right"):
		return Vector2(1, 0)


func _update_throb(delta):
	modulate.a += _throb_dir * delta / 2
	if modulate.a < 0.75 || modulate.a > 1.25:
		_throb_dir *= -1


func _move_to(target_position):
	move_tween.interpolate_property(self, "position", position, target_position, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN)
	move_tween.start()

