extends Node
class_name Grid

signal element_instanced (el, pos)

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
	
	for y in range (_size_y):
		_grid.append([])
		for x in range (_size_x):
			_grid[y].append(null)


func setup_starting_placement():
	var start_cell_y: int = (_size_y / 2) - (_init_fill_y / 2)
	print("start_cell_y:" + str(start_cell_y))
	for y in range (_init_fill_y):
		var pos = Vector2(0, y + start_cell_y)
		for x in range (_size_x):
			pos.x = x
			var el = _instantiator.instance()
			_grid[y + start_cell_y][x] = el
			emit_signal('element_instanced', el, pos)


func get_size_x() -> int:
	return _size_x


func get_size_y() -> int:
	return _size_y


func get_grid_array() -> Array:
	return _grid

