extends Node2D

export (PackedScene) var Rune

export (int) var boardSizeX
export (int) var boardSizeY
export (int) var boardInitSizeY
export (int) var runeSize

var cursorPos = 0
var grid = []

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
	return rune

func updateCursor(cursorPos):
	$Cursor.position = Vector2(cursorPos, boardSizeY / 2) * runeSize
	$Cursor.z_index = 100
	
func shiftColumnUp(cursorPos):
	if grid[0][cursorPos] != null:
		return
	if grid[(boardSizeY / 2) + 1][cursorPos] == null:
		return
	for y in range (boardSizeY - 1):
		grid[y][cursorPos] = grid[y+1][cursorPos]
		if grid[y][cursorPos] != null:
			grid[y][cursorPos].position.y -= runeSize
	grid[boardSizeY - 1][cursorPos] = null

func shiftColumnDown(cursorPos):
	if grid[boardSizeY - 1][cursorPos] != null:
		return
	if grid[(boardSizeY / 2) - 1][cursorPos] == null:
		return
	for y in range (boardSizeY - 1):
		y = boardSizeY - y - 2
		grid[y+1][cursorPos] = grid[y][cursorPos]
		if grid[y][cursorPos] != null:
			grid[y][cursorPos].position.y += runeSize
	grid[0][cursorPos] = null

func shiftMiddleRowLeft():
	# TODO: get overflow working
	for x in range(boardSizeX):
		grid[boardSizeY / 2][x - 1] = grid[boardSizeY / 2][x]
		grid[boardSizeY / 2][x].position.x -= runeSize

func shiftMiddleRowRight():
	# TODO: get overflow working
	for x in range(boardSizeX):
		x = boardSizeX - x
		grid[boardSizeY / 2][x] = grid[boardSizeY / 2][x - 1]
		grid[boardSizeY / 2][x].position.x += runeSize

func _ready():
	initGrid(Vector2(boardSizeX, boardInitSizeY))
	updateCursor(cursorPos)

func _process(delta):
	if Input.is_action_just_pressed("ui_cursor_left"):
		cursorPos = boardSizeX - 1 if cursorPos == 0 else cursorPos - 1
		updateCursor(cursorPos)
	if Input.is_action_just_pressed("ui_cursor_right"):
		cursorPos = (cursorPos + 1) % boardSizeX
		updateCursor(cursorPos)
	if Input.is_action_just_pressed("ui_up"):
		shiftColumnUp(cursorPos)
	if Input.is_action_just_pressed("ui_down"):
		shiftColumnDown(cursorPos)
	if Input.is_action_just_pressed("ui_left"):
		shiftMiddleRowLeft()
	if Input.is_action_just_pressed("ui_right"):
		shiftMiddleRowRight()