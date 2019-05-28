extends Position2D
class_name Board

onready var cursor: Cursor = $Cursor.initialize(self)
onready var debug_area: Node2D = $DebugArea
onready var dot_area: Position2D = $Dots
onready var rune_trickle_timer: Timer = $RuneTrickleTimer
onready var success_sound: AudioStreamPlayer2D = $SuccessSound
onready var active_rune: ActiveRune = $ActiveRune

signal active_rune_cleared (count)
signal match_removed (count, rune_type, is_combo)

export (PackedScene) var Rune

export (int) var board_size_x
export (int) var board_size_y
export (int) var board_init_size_y
export (int) var rune_size
export (bool) var is_player_controlled

enum Orientation {TOP, BOTTOM}

var _cursor_pos := 0 setget _set_cursor_pos
var _reposition_count := 0
var _is_action_made_since_last_score := false
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
		var available_slot = _find_available_column()
		if available_slot:
			_drop_rune_in_column(available_slot.column, available_slot.direction)


# TODO: refactor out finding final rune position for this and drop method
func _materialize_rune_in_column(column, direction = Orientation.TOP):
	var rune = _create_rune()
	if direction == Orientation.TOP:
		var i = 0
		while _grid.get_grid_array()[i][column] == null && i < (board_size_y / 2 + 2):
			i += 1
		i -= 1
		_grid.get_grid_array()[i][column] = rune
		rune.position = Vector2(column, i) * rune_size
		return
	var i = 0
	while _grid.get_grid_array()[board_size_y - 1 - i][column] == null && i < board_size_y / 2:
		i += 1
	i -= 1
	_grid.get_grid_array()[board_size_y - 1 - i][column] = rune
	rune.position = Vector2(column, board_size_y - 1 - i) * rune_size
	return


func _materialize_runes_in_available_slots(count: int) -> void:
	for i in range(count):
		var available_column = _find_available_column()
		if available_column:
			_materialize_rune_in_column(available_column.column, available_column.direction)


func _check_for_loss():
	var hits = 0
	for x in range(board_size_x):
		if _grid.get_grid_array()[0][x] != null:
			hits += 1
		if _grid.get_grid_array()[board_size_y - 1][x] != null:
			hits += 1
	if (hits == board_size_x * 2):
		print("game over")
		return true
	return false


func _find_available_column() -> Dictionary:
	if _check_for_loss():
		return {}
		
	var test_slots = range(board_size_x * 2)
	test_slots = _shuffle_list(test_slots)
	var row = 0
	var direction
	var column
	while row < board_size_x * Orientation.size():
		direction = test_slots[row] % Orientation.size()
		column = test_slots[row] % board_size_x
		if direction == Orientation.TOP && !_grid.get_grid_array()[0][column] || direction == Orientation.BOTTOM && !_grid.get_grid_array()[board_size_y-1][column]:
			break
		row += 1
	return {
		direction = direction,
		column = column
	}


func _shuffle_list(list: Array) -> Array:
    var shuffledList = [] 
    var indexList = range(list.size())
    for i in range(list.size()):
        var x: int = randi() % indexList.size()
        shuffledList.append(list[indexList[x]])
        indexList.remove(x)
    return shuffledList


func _debug_draw_grid() -> void:
	if debug_area.visible != true:
		return
	for child in debug_area.get_children():
		child.queue_free()
	for x in range(board_size_x):
		for y in range(board_size_y):
			var label = Label.new()
			label.text = str(x) + "," + str(y)
			label.text += "\n"
			label.text += \
				str(_grid.get_grid_array()[y][x].colorType) if _grid.get_grid_array()[y][x] \
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

