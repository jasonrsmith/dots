extends Node
class_name Grid

signal element_instanced (el, pos)
signal element_repositioned (el, prev_pos, new_pos)
signal match_detected (matches)

var _grid: = []
var _size_x: int = 0
var _size_y: int = 0
var _init_fill_y: int = 0
var _instantiator: PackedScene

func _init(x: int, y: int, init_fill_y: int, instantiator: PackedScene) -> void:
	_size_x = x
	_size_y = y
	_init_fill_y = init_fill_y
	_instantiator = instantiator
	
	connect('element_repositioned', self, '_on_element_repositioned')

	
	# TODO: refactor to fill_null
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
	var tmp: Rune = _grid[y][0]
	for x in range(_size_x-1):
		_grid[y][x] = _grid[y][x + 1]
		if _grid[y][x]:
			emit_signal('element_repositioned', _grid[y][x], Vector2(x + 1, y), Vector2(x, y))
	_grid[y][_size_x-1] = tmp
	if _grid[y][_size_x-1]:
		emit_signal('element_repositioned', _grid[y][_size_x - 1], Vector2(0, y), Vector2(_size_x - 1, y))


func shift_middle_row_right() -> void:
	var y: int = _size_y / 2
	var tmp: Rune = _grid[y][_size_x - 1]
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
			if !_grid[y][i] || !_grid[y][j] || _grid[y][i].colorType != _grid[y][j].colorType:
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


func _on_element_repositioned(el, prev_pos, new_pos):
	pass