extends Node2D

@onready var turtle_spawner = $TurtleSpawner

var time_survived: float = 0.0
var is_game_active: bool = true

func _ready() -> void:
	randomize()
	_spawn_player()

func _process(delta: float) -> void:
	if is_game_active:
		time_survived += delta

func _spawn_player() -> void:
	# --- DIPENDENZA CORRETTA ---
	# Recuperiamo la nave selezionata da GameData
	var player_scene = GameData.selected_ship_scene
	
	if not player_scene: 
		push_error("Nessuna scena player selezionata in GameData")
		return

	var player = player_scene.instantiate()
	player.position = get_viewport().get_visible_rect().size / 2
	add_child(player)
	player.add_to_group("player")
	
	# IMPORTANTE: Collega la morte
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	else:
		# Fallback se il player non ha un segnale custom "died"
		player.tree_exited.connect(_on_player_died)

func _on_player_died():
	#$AudioStreamPlayer.pitch_scale=0.4
	Engine.time_scale=0.1
	await $".".create_timer(3*Engine.time_scale).timeout
	Engine.time_scale=1
	_game_over()

func _game_over():
	print("Gioco terminato! Monete totali: %d" % GameData.monete_stella)
	
	# DIPENDENZA CORRETTA: Salva il record su GameData
	GameData.check_and_save_record("mode_3", time_survived)
	# --------------------------

	# Gestione transizione scena
	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		# Se hai il singleton FadeTransition attivato
		FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
