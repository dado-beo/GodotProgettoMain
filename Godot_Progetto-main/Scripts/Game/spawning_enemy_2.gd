extends Node2D

const ENEMY = preload("res://scenes/Spaceships/Enemies/Ufo.tscn")

@onready var anim = $AnimationPlayer

signal enemy_spawned(enemy)   # Segnale per notificare GameModeWave

func _ready():
	anim.play("spawn")
	anim.animation_finished.connect(_on_spawn_finished)

func _on_spawn_finished(anim_name: String):
	if anim_name != "spawn":
		return
	
	# Crea il nemico reale
	var enemy = ENEMY.instantiate()
	enemy.position = global_position
	
	# Trova il player nella scena
	var player_node = get_tree().get_current_scene().get_node_or_null("Player")
	if player_node:
		enemy.player = player_node
	
	# Aggiungi il nemico al nodo padre
	get_parent().add_child(enemy)
	
	# Notifica GameModeWave
	emit_signal("enemy_spawned", enemy)
	
	# Rimuovi il wrapper
	queue_free()
