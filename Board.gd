extends Node2D

export (PackedScene) var Rune

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
			if grid[y][i].colorType != grid[y][j].colorType:
				break
			matches.append(j)
		if matches.size() >= 3:
			print("matches")
			print(matches)
			scoreAndRemoveMatches(matches)
			settleBoard()

func scoreAndRemoveMatches(matches):
	$SuccessSound.play()
	for i in matches:
		grid[boardSizeY / 2][i].remove()

func settleBoard():
	pass


func _ready():
	initGrid(Vector2(boardSizeX, boardInitSizeY))
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

func _on_rune_position_start():
	repositionCount += 1

func _on_rune_position_end():
	repositionCount -= 1
	if repositionCount == 0:
		checkForMatch()
