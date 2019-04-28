extends Sprite

var throb_dir = -1.0

func _ready():
	pass # Replace with function body.

func _process(delta):
	modulate.a += throb_dir * delta
	if modulate.a < 0.6 || modulate.a > 1.0:
		throb_dir *= -1