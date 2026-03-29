extends Node

@onready var bottoni = $"../../MainButtons"
@onready var this=$".."
@onready var musica=$"../../AudioStreamPlayer2D"

func _on_back_pressed() -> void:
	this.visible=false
	bottoni.visible=true


func _on_mod_1_pressed() -> void:
	musica.stop()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
