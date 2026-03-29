extends Node2D

const ENEMY = preload("res://scenes/Spaceships/Enemies/Kamikaze.tscn")

@onready var anim = $AnimationPlayer

func _ready():
	anim.stop()
	anim.play("spawn")
	
func spawn_enemy():
	var enemy = ENEMY.instantiate()
	enemy.global_position = global_position
	
	# Nota: Non serve assegnare 'enemy.player' qui manualmente, 
	# perché lo script del Kamikaze lo cerca da solo nel suo _ready usando i gruppi.
	
	get_parent().add_child(enemy)

func kill():
	queue_free()
