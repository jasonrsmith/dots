extends Position2D
class_name Board

onready var cursor: Cursor = $Cursor
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

var _cursor_pos := 0
var _grid := []
var _reposition_count := 0
var _is_action_made_since_last_score := false

func _ready() -> void:
	_init_grid(Vector2(board_size_x, board_init_size_y))
	_debug_draw_grid()
	_update_cursor(_cursor_pos)
	rune_trickle_timer.connect('timeout', self, '_on_rune_trickle_timer_timeout')
	rune_trickle_timer.start()
	active_rune.connect('active_rune_cleared', self, '_on_active_rune_cleared')


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


func _init_grid(size: Vector2) -> void:
	var start_cell_y: int = (board_size_y / 2) - (board_init_size_y / 2)
	
	for y in range (board_size_y):
		_grid.append([])
		for x in range (board_size_x):
			_grid[y].append(null)
	
	for y in range (size.y):
		var new_pos = Vector2(0, y + start_cell_y)
		for x in range (size.x):
			new_pos.x = x
			var rune = _create_rune()
			rune.position = (new_pos * rune_size)
			_grid[y + start_cell_y][x] = rune


func _create_rune() -> Rune:
	var rune = Rune.instance()
	dot_area.add_child(rune)
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
	return rune


func _update_cursor(_cursor_pos):
	cursor.position = Vector2(_cursor_pos, board_size_y / 2) * rune_size


func shiftColumnUp(_cursor_pos):
	if _grid[0][_cursor_pos] != null:
		return
	if _grid[(board_size_y / 2) + 1][_cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		_grid[y][_cursor_pos] = _grid[y+1][_cursor_pos]
		if _grid[y][_cursor_pos] != null:
			_grid[y][_cursor_pos].shift(Vector2(_cursor_pos, y) * rune_size)
	_grid[board_size_y - 1][_cursor_pos] = null


func shiftColumnDown(_cursor_pos):
	if _grid[board_size_y - 1][_cursor_pos] != null:
		return
	if _grid[(board_size_y / 2) - 1][_cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		y = board_size_y - y - 1
		_grid[y][_cursor_pos] = _grid[y - 1][_cursor_pos]
		if _grid[y][_cursor_pos] != null:
			_grid[y][_cursor_pos].shift(Vector2(_cursor_pos, y) * rune_size)
	_grid[0][_cursor_pos] = null


func shiftMiddleRowLeft():
	var y: int = board_size_y / 2
	var tmp: Rune = _grid[y][0]
	for x in range(board_size_x-1):
		_grid[y][x] = _grid[y][x + 1]
		if _grid[y][x]:
			_grid[y][x].shift(Vector2(x, y) * rune_size)
	_grid[y][board_size_x-1] = tmp
	if _grid[y][board_size_x-1]:
		_grid[y][board_size_x-1].shift(Vector2(board_size_x-1, y) * rune_size)


func _shift_middle_row_right() -> void:
	var y: int = board_size_y / 2
	var tmp: Rune = _grid[y][board_size_x - 1]
	for x in range(board_size_x - 1):
		x = board_size_x - x - 1
		_grid[y][x] = _grid[y][x - 1]
		if _grid[y][x]:
			_grid[y][x].shift(Vector2(x, y) * rune_size)
	_grid[y][0] = tmp
	if _grid[y][0]:
		_grid[y][0].shift(Vector2(0, y) * rune_size)


func requestMoveCursor(inputDirection):
	if inputDirection == Vector2(-1, 0):
		if _cursor_pos == 0:
			return
		_cursor_pos -= 1
	if inputDirection == Vector2(1, 0):
		if _cursor_pos == board_size_x - 1:
			return
		_cursor_pos += 1
	return Vector2(_cursor_pos, board_size_y / 2) * rune_size

func checkForMatch():
	var y = board_size_y / 2
	for i in range(board_size_x):
		var matches = [i]
		for j in range(i + 1, board_size_x):
			if !_grid[y][i] || !_grid[y][j] || _grid[y][i].colorType != _grid[y][j].colorType:
				break
			matches.append(j)
		if matches.size() >= 3:
			scoreAndRemoveMatches(matches)
			_is_action_made_since_last_score = false
			return

func scoreAndRemoveMatches(matches):
	success_sound.play()
	var rune_type = _grid[board_size_y / 2][matches[0]].colorType
	for i in matches:
		_grid[board_size_y / 2][i].remove()
		_grid[board_size_y / 2][i] = null
	emit_signal("match_removed", matches.size(), rune_type, !_is_action_made_since_last_score)

func settleBoard():
	var y = board_size_y / 2
	for x in range(board_size_x):
		if !_grid[y][x]:
			if _grid[y-1][x]:
				var i=1
				while  y >= i && _grid[y-i][x]:
					_grid[y-i+1][x] = _grid[y-i][x]
					_grid[y-i+1][x].shift(Vector2(x, y-i+1) * rune_size)
					i += 1
				_grid[y-i+1][x] = null
			elif _grid[y+1][x]:
				var i=0
				while  y+i+1 < board_size_y && _grid[y+i+1][x]:
					_grid[y+i][x] = _grid[y+i+1][x]
					_grid[y+i][x].shift(Vector2(x, y+i) * rune_size)
					i += 1
				_grid[y+i][x] = null

func addRune(column, direction = Orientation.TOP):
	var rune = _create_rune()
	if direction == Orientation.TOP:
		rune.position = Vector2(column, 0) * rune_size
		var i = 0
		while _grid[i][column] == null && i < (board_size_y / 2 + 2):
			i += 1
		i -= 1
		_grid[i][column] = rune
		rune.shift(Vector2(column, i) * rune_size)
		return
	rune.position = Vector2(column, board_size_y - 1) * rune_size
	var i = 0
	while _grid[board_size_y - 1 - i][column] == null && i < board_size_y / 2:
		i += 1
	i -= 1
	_grid[board_size_y - 1 - i][column] = rune
	rune.shift(Vector2(column, board_size_y - 1 - i) * rune_size)
	return

func checkForLoss():
	var hits = 0
	for x in range(board_size_x):
		if _grid[0][x] != null:
			hits += 1
		if _grid[board_size_y - 1][x] != null:
			hits += 1
	if (hits == board_size_x * 2):
		print("game over")
		return true
	return false

func getAvailableSlot():
	if checkForLoss():
		return
		
	var testSlots = range(board_size_x * 2)
	testSlots = shuffleList(testSlots)
	var i = 0
	var direction
	var column
	while i < board_size_x * Orientation.size():
		direction = testSlots[i] % Orientation.size()
		column = testSlots[i] % board_size_x
		if direction == Orientation.TOP && !_grid[0][column] || direction == Orientation.BOTTOM && !_grid[board_size_y-1][column]:
			break
		i += 1
	return {
		direction = direction,
		column = column
	}


func shuffleList(list):
    var shuffledList = [] 
    var indexList = range(list.size())
    for i in range(list.size()):
        var x = randi() % indexList.size()
        shuffledList.append(list[indexList[x]])
        indexList.remove(x)
    return shuffledList


func _debug_draw_grid():
	for child in debug_area.get_children():
		child.queue_free()
	for x in range(board_size_x):
		for y in range(board_size_y):
			var label = Label.new()
			label.text = str(x) + "," + str(y)
			label.text += "\n"
			label.text += \
				str(_grid[y][x].colorType) if _grid[y][x] \
				else "null"
			label.margin_top = y * rune_size
			label.margin_left = x * rune_size
			debug_area.add_child(label)


func _on_active_rune_cleared(count):
	pass


func _on_input_up():
	shiftColumnUp(_cursor_pos)


func _on_input_down():
	shiftColumnDown(_cursor_pos)


func _on_input_left():
	shiftMiddleRowLeft()


func _on_input_right():
	_shift_middle_row_right()


func onInputSelect():
	if rune_trickle_timer.is_stopped():
		rune_trickle_timer.start()
	else:
		rune_trickle_timer.stop()


var rune_drop_queue = []
func add_to_rune_drop_queue(count):
	rune_drop_queue.push_back(count)


func drop_runes(count):
	for i in range(count):
		var availableSlot = getAvailableSlot()
		if availableSlot:
			addRune(availableSlot.column, availableSlot.direction)


func _on_rune_trickle_timer_timeout():
	if _reposition_count != 0 || rune_drop_queue.size() == 0:
		return
	drop_runes(rune_drop_queue.pop_front())


func _on_rune_position_start():
	_reposition_count += 1


func _on_rune_position_end():
	_reposition_count -= 1
	if _reposition_count != 0:
		return
	checkForMatch()
	settleBoard()