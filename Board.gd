extends Position2D
class_name Board

onready var cursor: Cursor = $Cursor.initialize(self)
onready var debug_area: Node2D = $DebugArea
onready var dot_area: Position2D = $Dots
onready var rune_trickle_timer: Timer = $RuneTrickleTimer
onready var success_sound: AudioStreamPlayer2D = $SuccessSound
onready var active_rune: ActiveRune = $ActiveRune
onready var grid: Grid = $Grid

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
	rune_trickle_timer.connect('timeout', self, '_on_rune_trickle_timer_timeout')
	rune_trickle_timer.start()
	active_rune.connect('active_rune_cleared', self, '_on_active_rune_cleared')
	_grid = Grid.new(board_size_x, board_size_y, board_init_size_y, Rune)
	print("grid1:")
	print(_grid)
	var res = _grid.connect('element_instanced', self, '_on_Grid_element_instanced')
	_grid.setup_starting_placement()
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
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
	return rune


func _set_cursor_pos(new_cursor_pos: int) -> void:
	cursor.position = Vector2(new_cursor_pos, board_size_y / 2) * rune_size
	_cursor_pos = new_cursor_pos


func _shift_column_up(cursor_pos: int) -> void:
	if _grid.get_grid_array()[0][cursor_pos] != null:
		return
	if _grid.get_grid_array()[(board_size_y / 2) + 1][cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		_grid.get_grid_array()[y][cursor_pos] = _grid.get_grid_array()[y+1][cursor_pos]
		if _grid.get_grid_array()[y][cursor_pos] != null:
			_grid.get_grid_array()[y][cursor_pos].shift(Vector2(cursor_pos, y) * rune_size)
	_grid.get_grid_array()[board_size_y - 1][cursor_pos] = null


func _shift_column_down(cursor_pos: int) -> void:
	if _grid.get_grid_array()[board_size_y - 1][cursor_pos] != null:
		return
	if _grid.get_grid_array()[(board_size_y / 2) - 1][cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		y = board_size_y - y - 1
		_grid.get_grid_array()[y][cursor_pos] = _grid.get_grid_array()[y - 1][cursor_pos]
		if _grid.get_grid_array()[y][cursor_pos] != null:
			_grid.get_grid_array()[y][cursor_pos].shift(Vector2(cursor_pos, y) * rune_size)
	_grid.get_grid_array()[0][cursor_pos] = null


func _shift_middle_row_left() -> void:
	var y: int = board_size_y / 2
	var tmp: Rune = _grid.get_grid_array()[y][0]
	for x in range(board_size_x-1):
		_grid.get_grid_array()[y][x] = _grid.get_grid_array()[y][x + 1]
		if _grid.get_grid_array()[y][x]:
			_grid.get_grid_array()[y][x].shift(Vector2(x, y) * rune_size)
	_grid.get_grid_array()[y][board_size_x-1] = tmp
	if _grid.get_grid_array()[y][board_size_x-1]:
		_grid.get_grid_array()[y][board_size_x-1].shift(Vector2(board_size_x-1, y) * rune_size)


func _shift_middle_row_right() -> void:
	var y: int = board_size_y / 2
	var tmp: Rune = _grid.get_grid_array()[y][board_size_x - 1]
	for x in range(board_size_x - 1):
		x = board_size_x - x - 1
		_grid.get_grid_array()[y][x] = _grid.get_grid_array()[y][x - 1]
		if _grid.get_grid_array()[y][x]:
			_grid.get_grid_array()[y][x].shift(Vector2(x, y) * rune_size)
	_grid.get_grid_array()[y][0] = tmp
	if _grid.get_grid_array()[y][0]:
		_grid.get_grid_array()[y][0].shift(Vector2(0, y) * rune_size)


func _check_for_match() -> void:
	var y = board_size_y / 2
	for i in range(board_size_x):
		var matches = [i]
		for j in range(i + 1, board_size_x):
			if !_grid.get_grid_array()[y][i] || !_grid.get_grid_array()[y][j] || _grid.get_grid_array()[y][i].colorType != _grid.get_grid_array()[y][j].colorType:
				break
			matches.append(j)
		if matches.size() >= 3:
			_score_and_remove_matches(matches)
			_is_action_made_since_last_score = false
			return


func _score_and_remove_matches(matches: Array) -> void:
	success_sound.play()
	var rune_type = _grid.get_grid_array()[board_size_y / 2][matches[0]].colorType
	for i in matches:
		_grid.get_grid_array()[board_size_y / 2][i].remove()
		_grid.get_grid_array()[board_size_y / 2][i] = null
	emit_signal("match_removed", matches.size(), rune_type, !_is_action_made_since_last_score)


func _settle_board() -> void:
	var y = board_size_y / 2
	for x in range(board_size_x):
		if !_grid.get_grid_array()[y][x]:
			if _grid.get_grid_array()[y-1][x]:
				var i=1
				while  y >= i && _grid.get_grid_array()[y-i][x]:
					_grid.get_grid_array()[y-i+1][x] = _grid.get_grid_array()[y-i][x]
					_grid.get_grid_array()[y-i+1][x].shift(Vector2(x, y-i+1) * rune_size)
					i += 1
				_grid.get_grid_array()[y-i+1][x] = null
			elif _grid.get_grid_array()[y+1][x]:
				var i=0
				while  y+i+1 < board_size_y && _grid.get_grid_array()[y+i+1][x]:
					_grid.get_grid_array()[y+i][x] = _grid.get_grid_array()[y+i+1][x]
					_grid.get_grid_array()[y+i][x].shift(Vector2(x, y+i) * rune_size)
					i += 1
				_grid.get_grid_array()[y+i][x] = null

"""
func _find_available_slot_in_column(column, direction = Orientation.TOP) -> int:
	if direction == Orientation.TOP:
		rune.position = Vector2(column, 0) * rune_size
		var y = 0
		while _grid.get_grid_array()[y][column] == null && y < (board_size_y / 2 + 2):
			y += 1
		y -= 1
		_grid.get_grid_array()[y][column] = rune
		rune.shift(Vector2(column, y) * rune_size)
		return y
	rune.position = Vector2(column, board_size_y - 1) * rune_size
	var i = 0
	while _grid.get_grid_array()[board_size_y - 1 - i][column] == null && i < board_size_y / 2:
		i += 1
	i -= 1
	_grid.get_grid_array()[board_size_y - 1 - i][column] = rune
	return 1
"""

func _drop_rune_in_column(column: int, direction = Orientation.TOP) -> void:
	var rune = _create_rune()
	if direction == Orientation.TOP:
		rune.position = Vector2(column, 0) * rune_size
		var i = 0
		while _grid.get_grid_array()[i][column] == null && i < (board_size_y / 2 + 2):
			i += 1
		i -= 1
		_grid.get_grid_array()[i][column] = rune
		rune.shift(Vector2(column, i) * rune_size)
		return
	rune.position = Vector2(column, board_size_y - 1) * rune_size
	var i = 0
	while _grid.get_grid_array()[board_size_y - 1 - i][column] == null && i < board_size_y / 2:
		i += 1
	i -= 1
	_grid.get_grid_array()[board_size_y - 1 - i][column] = rune
	rune.shift(Vector2(column, board_size_y - 1 - i) * rune_size)
	return


func _drop_runes_in_available_slots(count: int) -> void:
	for i in range(count):
		var available_slot = _get_available_slot()
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
		var available_slot = _get_available_slot()
		if available_slot:
			_materialize_rune_in_column(available_slot.column, available_slot.direction)


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


func _get_available_slot() -> Dictionary:
	if _check_for_loss():
		return {}
		
	var test_slots = range(board_size_x * 2)
	test_slots = _shuffle_list(test_slots)
	var i = 0
	var direction
	var column
	while i < board_size_x * Orientation.size():
		direction = test_slots[i] % Orientation.size()
		column = test_slots[i] % board_size_x
		if direction == Orientation.TOP && !_grid.get_grid_array()[0][column] || direction == Orientation.BOTTOM && !_grid.get_grid_array()[board_size_y-1][column]:
			break
		i += 1
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
	_shift_column_up(_cursor_pos)


func _on_input_down() -> void:
	_shift_column_down(_cursor_pos)


func _on_input_left() -> void:
	_shift_middle_row_left()


func _on_input_right() -> void:
	_shift_middle_row_right()


func _on_input_select() -> void:
	if rune_trickle_timer.is_stopped():
		rune_trickle_timer.start()
	else:
		rune_trickle_timer.stop()


var rune_drop_queue := []
func add_to_rune_drop_queue(count: int) -> void:
	rune_drop_queue.push_back(count)


func _on_rune_trickle_timer_timeout() -> void:
	if _reposition_count != 0:
		return
	_materialize_runes_in_available_slots(2)
	var number_of_runes_to_drop = rune_drop_queue.pop_front()
	if number_of_runes_to_drop:
		_drop_runes_in_available_slots(number_of_runes_to_drop)


func _on_rune_position_start() -> void:
	_reposition_count += 1


func _on_rune_position_end() -> void:
	_reposition_count -= 1
	if _reposition_count != 0:
		return
	_check_for_match()
	_settle_board()


func _on_Grid_element_instanced(rune, pos) -> void:
	print(pos)
	rune.position = (pos * rune_size)
	dot_area.add_child(rune)
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
