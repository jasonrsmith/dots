extends Node
class_name Grid

var _grid := []
var _size_x: int = 0
var _size_y: int = 0

func _init(x: int, y: int) -> void:
	_size_x = x
	_size_y = y
	var start_cell_y: int = (board_size_y / 2) - (board_init_size_y / 2)
	
	for y in range (_size_y):
		_grid.append([])
		for x in range (_size_x):
			_grid[y].append(null)
	
	for y in range (size.y):
		var new_pos = Vector2(0, y + start_cell_y)
		for x in range (size.x):
			new_pos.x = x
			var rune = _create_rune()
			rune.position = (new_pos * rune_size)
			_grid[y + start_cell_y][x] = rune


func get_size_x() -> int:
	return _size_x


func get_size_y() -> int:
	return _size_y