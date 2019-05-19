extends Position2D
class_name Board

onready var cursor: Node2D = $Cursor
onready var debug_area: Node2D = $DebugArea
onready var dots: Position2D = $Dots
onready var rune_trickle_timer: Timer = $RuneTrickleTimer
onready var success_sound: AudioStreamPlayer2D = $SuccessSound

signal active_rune_cleared (count)
signal match_removed (count, rune_type, is_combo)

export (PackedScene) var Rune

export (int) var board_size_x
export (int) var board_size_y
export (int) var board_init_size_y
export (int) var rune_size
export (bool) var player_controlled

enum Orientation {TOP, BOTTOM}

var _cursor_pos = 0
var grid = []
var reposition_count = 0
var is_board_action_made_since_last_score = false

func initGrid(size):
	var startCellY = (board_size_y / 2) - (board_init_size_y / 2)
	
	for y in range (board_size_y):
		grid.append([])
		for x in range (board_size_x):
			grid[y].append(null)
	
	for y in range (size.y):
		var newPos = Vector2(0, y + startCellY)
		for x in range (size.x):
			newPos.x = x
			var rune = createRune()
			rune.position = (newPos * rune_size)
			grid[y + startCellY][x] = rune

func createRune():
	var rune = Rune.instance()
	dots.add_child(rune)
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
	return rune

func updateCursor(_cursor_pos):
	cursor.position = Vector2(_cursor_pos, board_size_y / 2) * rune_size
	
func shiftColumnUp(_cursor_pos):
	if grid[0][_cursor_pos] != null:
		return
	if grid[(board_size_y / 2) + 1][_cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		grid[y][_cursor_pos] = grid[y+1][_cursor_pos]
		if grid[y][_cursor_pos] != null:
			grid[y][_cursor_pos].shift(Vector2(_cursor_pos, y) * rune_size)
	grid[board_size_y - 1][_cursor_pos] = null

func shiftColumnDown(_cursor_pos):
	if grid[board_size_y - 1][_cursor_pos] != null:
		return
	if grid[(board_size_y / 2) - 1][_cursor_pos] == null:
		return
	for y in range (board_size_y - 1):
		y = board_size_y - y - 1
		grid[y][_cursor_pos] = grid[y - 1][_cursor_pos]
		if grid[y][_cursor_pos] != null:
			grid[y][_cursor_pos].shift(Vector2(_cursor_pos, y) * rune_size)
	grid[0][_cursor_pos] = null

func shiftMiddleRowLeft():
	var y = board_size_y / 2
	var tmp = grid[y][0]
	for x in range(board_size_x-1):
		grid[y][x] = grid[y][x + 1]
		if grid[y][x]:
			grid[y][x].shift(Vector2(x, y) * rune_size)
	grid[y][board_size_x-1] = tmp
	if grid[y][board_size_x-1]:
		grid[y][board_size_x-1].shift(Vector2(board_size_x-1, y) * rune_size)

func shiftMiddleRowRight():
	var y = board_size_y / 2
	var tmp = grid[y][board_size_x - 1]
	for x in range(board_size_x - 1):
		x = board_size_x - x - 1
		grid[y][x] = grid[y][x - 1]
		if grid[y][x]:
			grid[y][x].shift(Vector2(x, y) * rune_size)
	grid[y][0] = tmp
	if grid[y][0]:
		grid[y][0].shift(Vector2(0, y) * rune_size)

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
			if !grid[y][i] || !grid[y][j] || grid[y][i].colorType != grid[y][j].colorType:
				break
			matches.append(j)
		if matches.size() >= 3:
			scoreAndRemoveMatches(matches)
			is_board_action_made_since_last_score = false
			return

func scoreAndRemoveMatches(matches):
	success_sound.play()
	var rune_type = grid[board_size_y / 2][matches[0]].colorType
	for i in matches:
		grid[board_size_y / 2][i].remove()
		grid[board_size_y / 2][i] = null
	emit_signal("match_removed", matches.size(), rune_type, !is_board_action_made_since_last_score)

func settleBoard():
	var y = board_size_y / 2
	for x in range(board_size_x):
		if !grid[y][x]:
			if grid[y-1][x]:
				var i=1
				while  y >= i && grid[y-i][x]:
					grid[y-i+1][x] = grid[y-i][x]
					grid[y-i+1][x].shift(Vector2(x, y-i+1) * rune_size)
					i += 1
				grid[y-i+1][x] = null
			elif grid[y+1][x]:
				var i=0
				while  y+i+1 < board_size_y && grid[y+i+1][x]:
					grid[y+i][x] = grid[y+i+1][x]
					grid[y+i][x].shift(Vector2(x, y+i) * rune_size)
					i += 1
				grid[y+i][x] = null

func addRune(column, direction = Orientation.TOP):
	var rune = createRune()
	if direction == Orientation.TOP:
		rune.position = Vector2(column, 0) * rune_size
		var i = 0
		while grid[i][column] == null && i < (board_size_y / 2 + 2):
			i += 1
		i -= 1
		grid[i][column] = rune
		rune.shift(Vector2(column, i) * rune_size)
		return
	rune.position = Vector2(column, board_size_y - 1) * rune_size
	var i = 0
	while grid[board_size_y - 1 - i][column] == null && i < board_size_y / 2:
		i += 1
	i -= 1
	grid[board_size_y - 1 - i][column] = rune
	rune.shift(Vector2(column, board_size_y - 1 - i) * rune_size)
	return

func checkForLoss():
	var hits = 0
	for x in range(board_size_x):
		if grid[0][x] != null:
			hits += 1
		if grid[board_size_y - 1][x] != null:
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
		if direction == Orientation.TOP && !grid[0][column] || direction == Orientation.BOTTOM && !grid[board_size_y-1][column]:
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

func debugDrawGrid():
	for child in debug_area.get_children():
		child.queue_free()
	for x in range(board_size_x):
		for y in range(board_size_y):
			var label = Label.new()
			label.text = str(x) + "," + str(y)
			label.text += "\n"
			label.text += \
				str(grid[y][x].colorType) if grid[y][x] \
				else "null"
			label.margin_top = y * rune_size
			label.margin_left = x * rune_size
			debug_area.add_child(label)

func _ready():
	initGrid(Vector2(board_size_x, board_init_size_y))
	debugDrawGrid()
	updateCursor(_cursor_pos)
	rune_trickle_timer.connect('timeout', self, '_on_rune_trickle_timer_timeout')
	rune_trickle_timer.start()
	$ActiveRune.connect('active_rune_cleared', self, 'on_active_rune_cleared')

func on_active_rune_cleared(count):
	pass

func onInputUp():
	shiftColumnUp(_cursor_pos)

func onInputDown():
	shiftColumnDown(_cursor_pos)

func onInputLeft():
	shiftMiddleRowLeft()

func onInputRight():
	shiftMiddleRowRight()

func onInputSelect():
	if rune_trickle_timer.is_stopped():
		rune_trickle_timer.start()
	else:
		rune_trickle_timer.stop()

func _process(delta):
	debugDrawGrid()

func _unhandled_input(event):
	if !player_controlled:
		return
	if Input.is_action_just_pressed("ui_up"):
		onInputUp()
		is_board_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_down"):
		onInputDown()
		is_board_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_left"):
		onInputLeft()
		is_board_action_made_since_last_score = true
	if Input.is_action_just_pressed("ui_right"):
		onInputRight()
		is_board_action_made_since_last_score = true
	var has_cursor_moved = cursor.checkForInput()
	is_board_action_made_since_last_score = has_cursor_moved || is_board_action_made_since_last_score

func _on_rune_position_start():
	reposition_count += 1

func _on_rune_position_end():
	reposition_count -= 1
	if reposition_count != 0:
		return
	checkForMatch()
	settleBoard()

var rune_drop_queue = []
func add_to_rune_drop_queue(count):
	rune_drop_queue.push_back(count)

func _on_rune_trickle_timer_timeout():
	if reposition_count != 0 || rune_drop_queue.size() == 0:
		return
	drop_runes(rune_drop_queue.pop_front())

func drop_runes(count):
	for i in range(count):
		var availableSlot = getAvailableSlot()
		if availableSlot:
			addRune(availableSlot.column, availableSlot.direction)
