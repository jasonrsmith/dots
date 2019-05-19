extends Position2D
class_name Board

onready var cursor: Node2D = $Cursor
onready var debug_area: Node2D = $DebugArea
onready var dots: Position2D = $Dots
onready var rune_trickle_timer: Timer = $RuneTrickleTimer
onready var success_sound: AudioStreamPlayer2D = $SuccessSound

signal active_rune_cleared (count)
signal match_removed (count, rune_type, is_combo)

export (PackedScene) var DebugText
export (PackedScene) var Rune

export (int) var boardSizeX
export (int) var boardSizeY
export (int) var boardInitSizeY
export (int) var runeSize
export (bool) var player_controlled

enum Orientation {TOP, BOTTOM}

var cursorPos = 0
var grid = []
var repositionCount = 0
var is_board_action_made_since_last_score = false

func initGrid(size):
	var startCellY = (boardSizeY / 2) - (boardInitSizeY / 2)
	
	for y in range (boardSizeY):
		grid.append([])
		for x in range (boardSizeX):
			grid[y].append(null)
	
	for y in range (size.y):
		var newPos = Vector2(0, y + startCellY)
		for x in range (size.x):
			newPos.x = x
			var rune = createRune()
			rune.position = (newPos * runeSize)
			grid[y + startCellY][x] = rune

func createRune():
	var rune = Rune.instance()
	dots.add_child(rune)
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
	return rune

func updateCursor(cursorPos):
	cursor.position = Vector2(cursorPos, boardSizeY / 2) * runeSize
	
func shiftColumnUp(cursorPos):
	if grid[0][cursorPos] != null:
		return
	if grid[(boardSizeY / 2) + 1][cursorPos] == null:
		return
	for y in range (boardSizeY - 1):
		grid[y][cursorPos] = grid[y+1][cursorPos]
		if grid[y][cursorPos] != null:
			grid[y][cursorPos].shift(Vector2(cursorPos, y) * runeSize)
	grid[boardSizeY - 1][cursorPos] = null

func shiftColumnDown(cursorPos):
	if grid[boardSizeY - 1][cursorPos] != null:
		return
	if grid[(boardSizeY / 2) - 1][cursorPos] == null:
		return
	for y in range (boardSizeY - 1):
		y = boardSizeY - y - 1
		grid[y][cursorPos] = grid[y - 1][cursorPos]
		if grid[y][cursorPos] != null:
			grid[y][cursorPos].shift(Vector2(cursorPos, y) * runeSize)
	grid[0][cursorPos] = null

func shiftMiddleRowLeft():
	var y = boardSizeY / 2
	var tmp = grid[y][0]
	for x in range(boardSizeX-1):
		grid[y][x] = grid[y][x + 1]
		if grid[y][x]:
			grid[y][x].shift(Vector2(x, y) * runeSize)
	grid[y][boardSizeX-1] = tmp
	if grid[y][boardSizeX-1]:
		grid[y][boardSizeX-1].shift(Vector2(boardSizeX-1, y) * runeSize)

func shiftMiddleRowRight():
	var y = boardSizeY / 2
	var tmp = grid[y][boardSizeX - 1]
	for x in range(boardSizeX - 1):
		x = boardSizeX - x - 1
		grid[y][x] = grid[y][x - 1]
		if grid[y][x]:
			grid[y][x].shift(Vector2(x, y) * runeSize)
	grid[y][0] = tmp
	if grid[y][0]:
		grid[y][0].shift(Vector2(0, y) * runeSize)

func requestMoveCursor(inputDirection):
	if inputDirection == Vector2(-1, 0):
		if cursorPos == 0:
			return
		cursorPos -= 1
	if inputDirection == Vector2(1, 0):
		if cursorPos == boardSizeX - 1:
			return
		cursorPos += 1
	return Vector2(cursorPos, boardSizeY / 2) * runeSize

func checkForMatch():
	var y = boardSizeY / 2
	for i in range(boardSizeX):
		var matches = [i]
		for j in range(i + 1, boardSizeX):
			if !grid[y][i] || !grid[y][j] || grid[y][i].colorType != grid[y][j].colorType:
				break
			matches.append(j)
		if matches.size() >= 3:
			scoreAndRemoveMatches(matches)
			is_board_action_made_since_last_score = false
			return

func scoreAndRemoveMatches(matches):
	success_sound.play()
	var rune_type = grid[boardSizeY / 2][matches[0]].colorType
	for i in matches:
		grid[boardSizeY / 2][i].remove()
		grid[boardSizeY / 2][i] = null
	emit_signal("match_removed", matches.size(), rune_type, !is_board_action_made_since_last_score)

func settleBoard():
	var y = boardSizeY / 2
	for x in range(boardSizeX):
		if !grid[y][x]:
			if grid[y-1][x]:
				var i=1
				while  y >= i && grid[y-i][x]:
					grid[y-i+1][x] = grid[y-i][x]
					grid[y-i+1][x].shift(Vector2(x, y-i+1) * runeSize)
					i += 1
				grid[y-i+1][x] = null
			elif grid[y+1][x]:
				var i=0
				while  y+i+1 < boardSizeY && grid[y+i+1][x]:
					grid[y+i][x] = grid[y+i+1][x]
					grid[y+i][x].shift(Vector2(x, y+i) * runeSize)
					i += 1
				grid[y+i][x] = null

func addRune(column, direction = Orientation.TOP):
	var rune = createRune()
	if direction == Orientation.TOP:
		rune.position = Vector2(column, 0) * runeSize
		var i = 0
		while grid[i][column] == null && i < (boardSizeY / 2 + 2):
			i += 1
		i -= 1
		grid[i][column] = rune
		rune.shift(Vector2(column, i) * runeSize)
		return
	rune.position = Vector2(column, boardSizeY - 1) * runeSize
	var i = 0
	while grid[boardSizeY - 1 - i][column] == null && i < boardSizeY / 2:
		i += 1
	i -= 1
	grid[boardSizeY - 1 - i][column] = rune
	rune.shift(Vector2(column, boardSizeY - 1 - i) * runeSize)
	return

func checkForLoss():
	var hits = 0
	for x in range(boardSizeX):
		if grid[0][x] != null:
			hits += 1
		if grid[boardSizeY - 1][x] != null:
			hits += 1
	if (hits == boardSizeX * 2):
		print("game over")
		return true
	return false

func getAvailableSlot():
	if checkForLoss():
		return
		
	var testSlots = range(boardSizeX * 2)
	testSlots = shuffleList(testSlots)
	var i = 0
	var direction
	var column
	while i < boardSizeX * Orientation.size():
		direction = testSlots[i] % Orientation.size()
		column = testSlots[i] % boardSizeX
		if direction == Orientation.TOP && !grid[0][column] || direction == Orientation.BOTTOM && !grid[boardSizeY-1][column]:
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
	for x in range(boardSizeX):
		for y in range(boardSizeY):
			var label = DebugText.instance()
			label.text = str(x) + "," + str(y)
			label.text += "\n"
			label.text += \
				str(grid[y][x].colorType) if grid[y][x] \
				else "null"
			label.margin_top = y * runeSize
			label.margin_left = x * runeSize
			debug_area.add_child(label)

func _ready():
	initGrid(Vector2(boardSizeX, boardInitSizeY))
	debugDrawGrid()
	updateCursor(cursorPos)
	rune_trickle_timer.connect('timeout', self, '_on_rune_trickle_timer_timeout')
	rune_trickle_timer.start()
	$ActiveRune.connect('active_rune_cleared', self, 'on_active_rune_cleared')

func on_active_rune_cleared(count):
	pass

func onInputUp():
	shiftColumnUp(cursorPos)

func onInputDown():
	shiftColumnDown(cursorPos)

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
	repositionCount += 1

func _on_rune_position_end():
	repositionCount -= 1
	if repositionCount != 0:
		return
	checkForMatch()
	settleBoard()

var rune_drop_queue = []
func add_to_rune_drop_queue(count):
	rune_drop_queue.push_back(count)

func _on_rune_trickle_timer_timeout():
	if repositionCount != 0 || rune_drop_queue.size() == 0:
		return
	drop_runes(rune_drop_queue.pop_front())

func drop_runes(count):
	for i in range(count):
		var availableSlot = getAvailableSlot()
		if availableSlot:
			addRune(availableSlot.column, availableSlot.direction)
