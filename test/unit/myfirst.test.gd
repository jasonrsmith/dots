extends "res://addons/gut/test.gd"

func test_ittests():
	assert_eq(true, true)

func test_itfails():
	assert_eq(true, false)