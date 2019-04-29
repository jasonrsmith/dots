extends Node2D

export (int) var size

signal reposition_start
signal reposition_end

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
		$Pivot/Sprite.texture = RUNE_TYPES[colorType]


func initType():
	randomize()
	var pick = randi() % RUNE_TYPES.size()
	setColorType(pick)

func shift(targetPosition):
	set_process(false)
	emit_signal("reposition_start")
	$ClickSound.play(0.1)
	$AnimationPlayer.play("move")
	$Tween.interpolate_property(self, "position", position, targetPosition, $AnimationPlayer.current_animation_length, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($AnimationPlayer, "animation_finished")
	set_process(true)
	emit_signal("reposition_end")

func remove():
	$AnimationPlayer.play("explode");

func _ready():
	initType()
	

