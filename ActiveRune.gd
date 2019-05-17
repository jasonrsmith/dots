extends Position2D

export (PackedScene) var Rune

var current_active_rune
var board
var active_count

func update_active_rune_count(count):
	active_count = count
	find_node("ActiveRuneCountLabel").text = str(active_count)

func _on_match_removed(count, rune_type, is_combo):
	if count == 5:
		current_active_rune.setColorType(rune_type)
		update_active_rune_count(1)
		return
	if current_active_rune.colorType != rune_type:
		return
	var inc_count = count - 2
	update_active_rune_count(active_count + inc_count)

func _ready():
	current_active_rune = find_node("Rune")
	get_parent().connect("match_removed", self, "_on_match_removed")
	active_count = 1