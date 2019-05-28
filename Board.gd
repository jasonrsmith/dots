extends Position2D

"""
TODO:
	fix bug: player movement inhibits rune drop
	setup gameover signal
"""
class_name Board

onready var cursor: Cursor = $Cursor.initialize(self)
onready var debug_area: Node2D = $DebugArea
onready var dot_area: Position2D = $Dots
onready var rune_trickle_timer: Timer = $RuneTrickleTimer
onready var success_sound: AudioStreamPlayer2D = $SuccessSound
onready var active_rune: ActiveRune = $ActiveRune

signal active_rune_cleared (count)
signal match_removed (count, rune_type, is_combo)
signal board_full

export (PackedScene) var Rune

export (int) var board_size_x
export (int) var board_size_y
export (int) var board_init_size_y
export (int) var rune_size
export (bool) var is_player_controlled

# TODO: refactor me to Grid?
enum Orientation {TOP, BOTTOM}

var _cursor_pos := 0 setget _set_cursor_pos
var _reposition_count := 0
var _is_action_made_since_last_score := true
var _grid: Grid

func _ready() -> void:
	_set_cursor_pos(_cursor_pos)
	rune_trickle_timer.connect('timeout', self, '_on_Rune_trickle_timer_timeout')
	rune_trickle_timer.start()
	active_rune.connect('active_rune_cleared', self, '_on_active_rune_cleared')
	
	_grid = _init_and_connect_grid()
	_debug_draw_grid()


func _process(delta: float) -> void:
	_debug_draw_grid()


func _unhandled_input(event: InputEvent) -> void:
	if !is_player_controlled:
		return
	if Input.is_action_just_pressed("ui_up"):
		_on_input_up()
		_is_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_down"):
		_on_input_down()
		_is_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_left"):
		_on_input_left()
		_is_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_right"):
		_on_input_right()
		_is_action_made_since_last_score = true
	var has_cursor_moved = cursor.check_for_input()
	_is_action_made_since_last_score = has_cursor_moved || _is_action_made_since_last_score


func request_move_cursor(input_direction) -> Vector2:
	if input_direction == Vector2(-1, 0):
		if _cursor_pos == 0:
			return Vector2(0, 0)
		_cursor_pos -= 1
	if input_direction == Vector2(1, 0):
		if _cursor_pos == board_size_x - 1:
			return Vector2(0, 0)
		_cursor_pos += 1
	return Vector2(_cursor_pos, board_size_y / 2) * rune_size


func _create_rune() -> Rune:
	var rune = Rune.instance()
	dot_area.add_child(rune)
	rune.connect("reposition_start", self, "_on_Rune_position_start")
	rune.connect("reposition_end", self, "_on_Rune_position_end")
	return rune


func _set_cursor_pos(new_cursor_pos: int) -> void:
	cursor.position = Vector2(new_cursor_pos, board_size_y / 2) * rune_size
	_cursor_pos = new_cursor_pos


func _score_and_remove_matches(matches: Array) -> void:
	success_sound.play()
	var rune_type = _grid.get_center_row()[matches[0]].colorType
	_grid.remove_from_center(matches)
	emit_signal('match_removed', matches.size(), rune_type, !_is_action_made_since_last_score)
	_is_action_made_since_last_score = false


func _drop_rune_in_column(column: int, direction = Orientation.TOP) -> void:
	var rune = _create_rune()
	if direction == Orientation.TOP:
		var slot = _grid.put_next_available_slot_from_top(column, rune)
		rune.position = Vector2(column, 0) * rune_size
		rune.shift(Vector2(column, slot) * rune_size)
		return
	var slot = _grid.put_next_available_slot_from_bottom(column, rune)
	rune.position = Vector2(column, _grid.get_size_y() - 1) * rune_size
	rune.shift(Vector2(column, _grid.get_size_y() - 1 - slot) * rune_size)


func _drop_runes_in_available_slots(count: int) -> void:
	for i in range(count):
		var available_slot = _grid.find_available_column()
		if !available_slot:
			emit_signal('board_full')
			return
		_drop_rune_in_column(available_slot.column, available_slot.direction)


func _materialize_rune_in_column(column, direction = Orientation.TOP):
	var rune = _create_rune()
	if direction == Orientation.TOP:
		var slot = _grid.put_next_available_slot_from_top(column, rune)
		rune.position = Vector2(column, slot) * rune_size
		return
	var slot = _grid.put_next_available_slot_from_bottom(column, rune)
	rune.position = Vector2(column, _grid.get_size_y() - 1 - slot) * rune_size


func _materialize_runes_in_available_slots(count: int) -> void:
	for i in range(count):
		var available_column = _grid.find_available_column()
		if !available_column:
			emit_signal('board_full')
			return
		_materialize_rune_in_column(available_column.column, available_column.direction)


func _debug_draw_grid() -> void:
	if debug_area.visible != true:
		return
	for child in debug_area.get_children():
		child.queue_free()
	for x in range(board_size_x):
		for y in range(board_size_y):
			var rune = _grid.get_element_at(Vector2(x, y))
			var label = Label.new()
			label.text = str(x) + "," + str(y)
			label.text += "\n"
			label.text += \
				str(rune.colorType) if rune \
				else "null"
			label.margin_top = y * rune_size
			label.margin_left = x * rune_size
			debug_area.add_child(label)


func _on_active_rune_cleared(count) -> void:
	pass


func _on_input_up() -> void:
	_grid.shift_column_up(_cursor_pos)


func _on_input_down() -> void:
	_grid.shift_column_down(_cursor_pos)


func _on_input_left() -> void:
	_grid.shift_middle_row_left()


func _on_input_right() -> void:
	_grid.shift_middle_row_right()


func _on_input_select() -> void:
	if rune_trickle_timer.is_stopped():
		rune_trickle_timer.start()
	else:
		rune_trickle_timer.stop()


var rune_drop_queue := []
func add_to_rune_drop_queue(count: int) -> void:
	rune_drop_queue.push_back(count)


func _init_and_connect_grid() -> Grid:
	var rune_matcher = RuneMatcher.new()
	var grid = Grid.new(board_size_x, board_size_y, board_init_size_y, Rune, rune_matcher)
	grid.connect('element_instanced', self, '_on_Grid_element_instanced')
	grid.connect('element_repositioned', self, '_on_Grid_element_repositioned')
	grid.connect('match_detected', self, '_on_Grid_match_detected')
	grid.setup_starting_placement()
	return grid


func _on_Rune_trickle_timer_timeout() -> void:
	if _reposition_count != 0:
		return
	_materialize_runes_in_available_slots(2)
	var number_of_runes_to_drop = rune_drop_queue.pop_front()
	number_of_runes_to_drop = 1
	if number_of_runes_to_drop:
		_drop_runes_in_available_slots(number_of_runes_to_drop)


func _on_Rune_position_start() -> void:
	_reposition_count += 1


func _on_Rune_position_end() -> void:
	_reposition_count -= 1
	if _reposition_count != 0:
		return
	_grid.check_for_match()
	_grid.settle()


func _on_Grid_element_instanced(rune, pos) -> void:
	rune.position = (pos * rune_size)
	dot_area.add_child(rune)
	rune.connect("reposition_start", self, "_on_Rune_position_start")
	rune.connect("reposition_end", self, "_on_Rune_position_end")


func _on_Grid_element_repositioned(rune, prev_pos, new_pos) -> void:
	rune.shift(new_pos * rune_size)


func _on_Grid_match_detected(matches) -> void:
	_score_and_remove_matches(matches)

