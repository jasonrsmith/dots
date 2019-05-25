extends "res://addons/gut/test.gd"

func test_ittests():
	assert_eq(true, true, "this is a test of the testing system")
	

func test_creates_grid() -> void:
	var x = 10
	var y = 15
	var grid = Grid.new(x, y)
	assert_eq(grid.get_size_x(), x, "initializes x")
	assert_eq(grid.get_size_y(), y, "initializes y")


