extends Node
class_name Grid

signal element_instanced (el, pos)
signal element_repositioned (el, prev_pos, new_pos)
signal match_detected (matches)

enum Orientation {TOP, BOTTOM}

var _grid: = []
var _size_x: int = 0
var _size_y: int = 0
var _init_fill_y: int = 0
var _instantiator: PackedScene
var _matcher: Object

func _init(x: int, y: int, init_fill_y: int, instantiator: PackedScene, matcher: Object) -> void:
	_size_x = x
	_size_y = y
	_init_fill_y = init_fill_y
	_instantiator = instantiator
	_matcher = matcher
	
	connect('element_repositioned', self, '_on_element_repositioned')
	fill_null()


func fill_null():
	for y in range (_size_y):
		_grid.append([])
		for x in range (_size_x):
			_grid[y].append(null)


func setup_starting_placement():
	var start_cell_y: int = (_size_y / 2) - (_init_fill_y / 2)
	for y in range (_init_fill_y):
		var pos = Vector2(0, y + start_cell_y)
		for x in range (_size_x):
			pos.x = x
			var el = _instantiator.instance()
			_grid[y + start_cell_y][x] = el
			emit_signal('element_instanced', el, pos)


func shift_column_up(col: int) -> void:
	if _grid[0][col] != null:
		return
	if _grid[(_size_y / 2) + 1][col] == null:
		return
	for y in range (_size_y - 1):
		_grid[y][col] = _grid[y+1][col]
		if _grid[y][col] != null:
			emit_signal('element_repositioned', _grid[y][col], Vector2(col, y+1), Vector2(col, y))
	_grid[_size_y - 1][col] = null


func shift_column_down(col: int) -> void:
	if _grid[_size_y - 1][col] != null:
		return
	if _grid[(_size_y / 2) - 1][col] == null:
		return
	for y in range (_size_y - 1):
		y = _size_y - y - 1
		_grid[y][col] = _grid[y - 1][col]
		if _grid[y][col] != null:
			emit_signal('element_repositioned', _grid[y][col], Vector2(col, y-1), Vector2(col, y))
	_grid[0][col] = null


func shift_middle_row_left() -> void:
	var y: int = _size_y / 2
	var tmp = _grid[y][0]
	for x in range(_size_x-1):
		_grid[y][x] = _grid[y][x + 1]
		if _grid[y][x]:
			emit_signal('element_repositioned', _grid[y][x], Vector2(x + 1, y), Vector2(x, y))
	_grid[y][_size_x-1] = tmp
	if _grid[y][_size_x-1]:
		emit_signal('element_repositioned', _grid[y][_size_x - 1], Vector2(0, y), Vector2(_size_x - 1, y))


func shift_middle_row_right() -> void:
	var y: int = _size_y / 2
	var tmp = _grid[y][_size_x - 1]
	for x in range(_size_x - 1):
		x = _size_x - x - 1
		_grid[y][x] = _grid[y][x - 1]
		if _grid[y][x]:
			emit_signal('element_repositioned', _grid[y][x], Vector2(x - 1, y), Vector2(x, y))
	_grid[y][0] = tmp
	if _grid[y][0]:
		emit_signal('element_repositioned', _grid[y][0], Vector2(_size_x - 1, y), Vector2(0, y))


func get_size_x() -> int:
	return _size_x


func get_size_y() -> int:
	return _size_y


func get_grid_array() -> Array:
	return _grid


func check_for_match() -> void:
	var y = _size_y / 2
	for i in range(_size_x):
		var matches = [i]
		for j in range(i + 1, _size_x):
			# TODO: extract match algorithm?
			#if !_grid[y][i] || !_grid[y][j] || _grid[y][i].colorType != _grid[y][j].colorType:
			if !_grid[y][i] || !_grid[y][j] || !_matcher.is_equal(_grid[y][i], _grid[y][j]):
				break
			matches.append(j)
		if matches.size() >= 3:
			emit_signal('match_detected', matches)
			return


func remove_from_center(indices_to_remove: Array) -> void:
	for i in indices_to_remove:
		get_center_row()[i].remove()
		get_center_row()[i] = null


func get_center_row():
	return _grid[_size_y / 2]


func settle() -> void:
	var y = _size_y / 2
	for x in range(_size_x):
		if !_grid[y][x]:
			if _grid[y-1][x]:
				var i=1
				while y >= i && _grid[y-i][x]:
					_grid[y-i+1][x] = _grid[y-i][x]
					emit_signal('element_repositioned', _grid[y - i + 1][x], Vector2(x, y - i), Vector2(x, y - i + 1))
					i += 1
				_grid[y-i+1][x] = null
			elif _grid[y+1][x]:
				var i=0
				while  y+i+1 < _size_y && _grid[y+i+1][x]:
					_grid[y+i][x] = _grid[y+i+1][x]
					emit_signal('element_repositioned', _grid[y + i + 1][x], Vector2(x, y + i + 1), Vector2(x, y + i))
					i += 1
				_grid[y+i][x] = null


func put_next_available_slot_from_top(column, item) -> int:
	var i = 0
	while _grid[i][column] == null && i < (_size_y / 2 + 2):
		i += 1
	i -= 1
	_grid[i][column] = item
	return i


func put_next_available_slot_from_bottom(column, item) -> int:
	var i = 0
	while _grid[_size_y - 1 - i][column] == null && i < _size_y / 2:
		i += 1
	i -= 1
	_grid[_size_y - 1 - i][column] = item
	return i


func find_available_column() -> Dictionary:
	var test_slots = range(_size_x * 2)
	test_slots = _shuffle_list(test_slots)
	var row = 0
	var direction
	var column
	while row < _size_x * Orientation.size():
		direction = test_slots[row] % Orientation.size()
		column = test_slots[row] % _size_x
		if direction == Orientation.TOP && !_grid[0][column] || direction == Orientation.BOTTOM && !_grid[_size_y-1][column]:
			break
		row += 1
	if row == _size_x * Orientation.size():
		return {}
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


func _on_element_repositioned(el, prev_pos, new_pos):
	pass