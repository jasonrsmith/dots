extends Node2D

export (int) var size

const RUNE_TYPES = [
  preload("res://marbles/marble-blue.png"),
  preload("res://marbles/marble-brown.png"),
  preload("res://marbles/marble-purple.png"),
  preload("res://marbles/marble-red.png"),
  preload("res://marbles/marble-teal.png"),
]

export (int, "BLUE", "BROWN", "PURPLE", "RED", "TEAL") var colorType setget setColorType

func setColorType(newColorType):
	if newColorType != null:
		colorType = newColorType
		$Sprite.texture = RUNE_TYPES[colorType]

func initType():
	var pick = randi() % RUNE_TYPES.size()
	setColorType(pick)

func _ready():
	initType()
