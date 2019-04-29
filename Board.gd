extends Node2D

export (PackedScene) var Rune
export (PackedScene) var DebugText

export (int) var boardSizeX
export (int) var boardSizeY
export (int) var boardInitSizeY
export (int) var runeSize

var cursorPos = 0
var grid = []
var repositionCount = 0

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
	add_child(rune)
	rune.connect("reposition_start", self, "_on_rune_position_start")
	rune.connect("reposition_end", self, "_on_rune_position_end")
	return rune

func updateCursor(cursorPos):
	$Cursor.position = Vector2(cursorPos, boardSizeY / 2) * runeSize
	
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
		grid[y][x].shift(Vector2(x, y) * runeSize)
	grid[y][boardSizeX-1] = tmp
	grid[y][boardSizeX-1].shift(Vector2(boardSizeX-1, y) * runeSize)

func shiftMiddleRowRight():
	var y = boardSizeY / 2
	var tmp = grid[y][boardSizeX - 1]
	for x in range(boardSizeX - 1):
		x = boardSizeX - x - 1
		grid[y][x] = grid[y][x - 1]
		grid[y][x].shift(Vector2(x, y) * runeSize)
	grid[y][0] = tmp
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
			print("matches")
			print(matches)
			scoreAndRemoveMatches(matches)
			return

func scoreAndRemoveMatches(matches):
	$SuccessSound.play()
	for i in matches:
		grid[boardSizeY / 2][i].remove()
		grid[boardSizeY / 2][i] = null

func settleBoard():
	print("settling")
	var y = boardSizeY / 2
	for x in range(boardSizeX):
		print(grid[y][x])
		if !grid[y][x]:
			if grid[y-1][x]:
				var i=1
				while grid[y-i][x]:
					grid[y-i+1][x] = grid[y-i][x]
					grid[y-i+1][x].shift(Vector2(x, y-i+1) * runeSize)
					i += 1
				grid[y-i+1][x] = null
			elif grid[y+1][x]:
				var i=0
				while grid[y+i+1][x]:
					grid[y+i][x] = grid[y+i+1][x]
					grid[y+i][x].shift(Vector2(x, y+i) * runeSize)
					i += 1
				grid[y+i][x] = null

func debugDrawGrid():
	for child in $DebugArea.get_children():
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
			$DebugArea.add_child(label)

func _ready():
	initGrid(Vector2(boardSizeX, boardInitSizeY))
	debugDrawGrid()
	updateCursor(cursorPos)

func _process(delta):
	if repositionCount != 0:
		return
	if Input.is_action_just_pressed("ui_up"):
		shiftColumnUp(cursorPos)
	if Input.is_action_just_pressed("ui_down"):
		shiftColumnDown(cursorPos)
	if Input.is_action_just_pressed("ui_left"):
		shiftMiddleRowLeft()
	if Input.is_action_just_pressed("ui_right"):
		shiftMiddleRowRight()
	debugDrawGrid()

func _on_rune_position_start():
	repositionCount += 1

func _on_rune_position_end():
	repositionCount -= 1
	if repositionCount == 0:
		checkForMatch()
		settleBoard()
