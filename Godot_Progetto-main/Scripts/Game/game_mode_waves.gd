extends Node2D

@onready var wave_label: Label = get_node_or_null("CanvasLayer/WaveLabel")
@onready var monete_label: Label = get_node_or_null("MoneteLabel")

const SPAWN_WIDTH := 1152
const SPAWN_HEIGHT := 648
const ENEMY_SCENE := preload("res://scenes/Spaceships/Enemies/Ufo.tscn")

var current_wave: int = 0
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var is_spawning: bool = false
var rewarded_waves: Array = []
var max_waves: int = 3

var waves_data = [
	{"enemies": 3, "spawn_interval": 2.0},
	{"enemies": 6, "spawn_interval": 1.8},
	{"enemies": 10, "spawn_interval": 1.0},
]

var DEBUG := true

func _ready() -> void:
	randomize()
	_update_monete_ui(GameData.monete_stella)
	GameData.monete_aggiornate.connect(_update_monete_ui)
	
	_spawn_player()
	
	# Avvia il loop
	await start_next_wave()

func _spawn_player() -> void:
	var player_scene = GameData.selected_ship_scene
	if not player_scene:
		push_error("Nessuna nave selezionata in GameData!")
		return
		
	var player = player_scene.instantiate()
	player.position = get_viewport().get_visible_rect().size / 2
	add_child(player)
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	else:
		player.tree_exited.connect(_on_player_died)

func start_next_wave():
	# --- FIX: Se siamo usciti dalla scena, fermati subito ---
	if not is_inside_tree(): return

	if current_wave >= max_waves:
		if wave_label:
			wave_label.text = "Tutte le ondate completate!"
			wave_label.visible = true
			
		GameData.check_and_save_record("mode_2", current_wave)
		
		# --- FIX: Controllo Timer ---
		if is_inside_tree():
			await get_tree().create_timer(3.0).timeout
			if is_inside_tree(): # Controllo dopo il timeout
				get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
		return

	current_wave += 1
	var wave_data = waves_data[current_wave - 1]
	enemies_to_spawn = wave_data["enemies"]
	var spawn_interval = wave_data["spawn_interval"]

	if wave_label:
		wave_label.text = "Ondata %d" % current_wave
		wave_label.visible = true
	
	# --- FIX: Controllo Timer ---
	if is_inside_tree():
		await get_tree().create_timer(2.0).timeout
	else:
		return # Se siamo usciti durante il timer, fermati
	
	if wave_label:
		wave_label.visible = false

	if DEBUG:
		print("--- START ONDATA %d ---" % current_wave)

	# Avvia lo spawn (nota: spawn_wave ora gestisce i suoi controlli)
	spawn_wave(enemies_to_spawn, spawn_interval)

	# Loop di attesa
	while is_spawning or get_tree().get_nodes_in_group("enemies").size() > 0:
		# --- FIX CRUCIALE: Se usciamo durante il loop, rompi il ciclo ---
		if not is_inside_tree(): 
			return
		
		if DEBUG and Engine.get_process_frames() % 60 == 0:
			print("Wave in corso... Nemici: %d" % get_tree().get_nodes_in_group("enemies").size())
		
		await get_tree().process_frame

	# --- FIX: Controllo Timer finale ---
	if is_inside_tree():
		await get_tree().create_timer(0.5).timeout
		_on_wave_finished()

func spawn_wave(count: int, interval: float):
	is_spawning = true
	for i in range(count):
		# --- FIX: Se cambiamo scena durante lo spawn, interrompi ---
		if not is_inside_tree(): 
			is_spawning = false
			return
			
		spawn_enemy()
		enemies_to_spawn = max(0, enemies_to_spawn - 1)
		
		# Timer tra un nemico e l'altro
		await get_tree().create_timer(interval).timeout
		
	is_spawning = false

func spawn_enemy() -> void:
	# Un ultimo controllo di sicurezza
	if not is_inside_tree(): return

	var enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2(randi() % SPAWN_WIDTH, randi() % SPAWN_HEIGHT)
	add_child(enemy)

	if not enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")

	enemies_alive += 1

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive = max(0, enemies_alive - 1)

func _on_wave_finished() -> void:
	# Sicurezza
	if not is_inside_tree(): return

	if DEBUG: print(">>> ONDATA %d FINITA <<<" % current_wave)

	_give_wave_reward(current_wave)
	GameData.check_and_save_record("mode_2", current_wave)

	if wave_label:
		wave_label.text = "Ondata %d completata!" % current_wave
		wave_label.visible = true
		
	# --- FIX: Controllo Timer ---
	if is_inside_tree():
		await get_tree().create_timer(2.0).timeout
	else:
		return
	
	if wave_label:
		wave_label.visible = false
	
	# Controlliamo ancora prima di chiamare la prossima ondata
	if is_inside_tree():
		start_next_wave()

func _on_player_died():
	print("Player morto all'ondata: ", current_wave)
	
	GameData.check_and_save_record("mode_2", current_wave)
	
	# --- FIX: Controllo Timer ---
	# Se il player esce subito dopo la morte ma prima dei 2 secondi, questo crasherà senza il controllo
	if is_inside_tree():
		await get_tree().create_timer(2.0).timeout
		
		# Controllo finale prima di cambiare scena
		if is_inside_tree():
			get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")

func _give_wave_reward(wave: int) -> void:
	if wave in rewarded_waves:
		return
		
	var reward = 0
	match wave:
		1: reward = 5
		2: reward = 10
		3: reward = 15
	
	if reward > 0:
		GameData.add_monete(reward)
		print("Ricompensa ondata %d: %d monete" % [wave, reward])
		
	rewarded_waves.append(wave)

func _update_monete_ui(valore: int) -> void:
	if monete_label:
		monete_label.text = ": %d" % valore
