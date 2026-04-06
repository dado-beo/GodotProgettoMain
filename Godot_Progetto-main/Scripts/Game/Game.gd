extends Node2D

const GAME_DURATION := 90 # Cambiato da 180 a 90 (1 min e 30 sec)
# Dizionario: Al secondo X dai Y monete
const REWARD_TIMINGS := {
	30: 5,   # Prima stella (Facile)
	60: 15,  # Seconda stella (Medio)
	90: 30   # Terza stella (Difficile)
}

var current_time := 0
var rewarded_minutes := []

# --- Tempi in cui spawna l'Ancora Gravitazionale ---
var grav_well_spawn_times = [60] 
var grav_well_scene = preload("res://scenes/Spaceships/Enemies/Ancora_Gravitazionale.tscn") 

@onready var game_timer: Timer = $GameTimer
@onready var time_label: Label = $GameTimer/TimeLabel
@onready var monete_label: Label = $MoneteLabel
@onready var spawner: Node = $EnemySpawner 
@onready var musica: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	if musica:
		musica.play()
	
	_update_monete_ui(GameData.monete_stella)
	GameData.monete_aggiornate.connect(_update_monete_ui)

	if time_label:
		time_label.text = "Tempo: 00:00"

	if game_timer.is_stopped():
		game_timer.timeout.connect(_on_timer_tick)

	if spawner:
		spawner.set_process(false)

	_spawn_selected_player()

	game_timer.start()
	if spawner:
		spawner.set_process(true)

func _update_monete_ui(valore: int):
	if monete_label:
		monete_label.text = ": %d" % valore

func _spawn_selected_player():
	var player_scene = GameData.selected_ship_scene
	
	if not player_scene:
		push_error("GameData.selected_ship_scene è null! Controllo se è stato caricato.")
		return

	var player = player_scene.instantiate()
	player.position = get_viewport_rect().size / 2
	add_child(player)
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)

func _on_timer_tick():
	current_time += 1
	_update_timer_label()

	if spawner and spawner.has_method("update_spawn_speed"):
		spawner.update_spawn_speed(current_time)

	# Assegnazione Ricompense
	if current_time in REWARD_TIMINGS and current_time not in rewarded_minutes:
		var reward = REWARD_TIMINGS[current_time]
		GameData.add_monete(reward)
		print("Hai ricevuto %d monete!" % reward)
		rewarded_minutes.append(current_time)
		
	# --- NUOVO: Controllo Spawn Ancora Gravitazionale ---
	if current_time in grav_well_spawn_times:
		_spawn_grav_well()

	if current_time >= GAME_DURATION:
		game_timer.stop()
		if spawner: spawner.set_process(false)
		_game_over()

func _update_timer_label():
	var minutes = current_time / 60
	var seconds = current_time % 60
	if time_label:
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

func _spawn_grav_well():
	if not grav_well_scene:
		push_error("Scena Ancora Gravitazionale non trovata!")
		return
		
	var viewport_size = get_viewport_rect().size
	var margin = 80 
	
	# Sceglie a caso l'asse da cui arrivano: 0 = Verticale (Su/Giù), 1 = Orizzontale (Sinistra/Destra)
	var asse_spawn = randi() % 2 
	
	for i in range(2):
		var grav_well = grav_well_scene.instantiate()
		var spawn_pos = Vector2.ZERO
		var first_target = Vector2.ZERO
		
		if asse_spawn == 0: # Asse Verticale
			if i == 0: # La prima arriva dall'ALTO
				spawn_pos = Vector2(randf_range(margin, viewport_size.x - margin), -150)
				first_target = Vector2(spawn_pos.x, margin)
			else: # La seconda arriva dal BASSO
				spawn_pos = Vector2(randf_range(margin, viewport_size.x - margin), viewport_size.y + 150)
				first_target = Vector2(spawn_pos.x, viewport_size.y - margin)
				
		else: # Asse Orizzontale
			if i == 0: # La prima arriva da SINISTRA
				spawn_pos = Vector2(-150, randf_range(margin, viewport_size.y - margin))
				first_target = Vector2(margin, spawn_pos.y)
			else: # La seconda arriva da DESTRA
				spawn_pos = Vector2(viewport_size.x + 150, randf_range(margin, viewport_size.y - margin))
				first_target = Vector2(viewport_size.x - margin, spawn_pos.y)
		
		grav_well.global_position = spawn_pos
		grav_well.target_position = first_target
		add_child(grav_well)
		
	print("ATTENZIONE: 2 Ancore Gravitazionali in arrivo da lati opposti!")

func _on_player_died():
	game_timer.stop()
	if musica: musica.pitch_scale = 0.4
	Engine.time_scale = 0.1
	await get_tree().create_timer(3 * Engine.time_scale).timeout
	Engine.time_scale = 1
	if spawner: spawner.set_process(false)
	_game_over()

func _game_over():
	print("Gioco terminato! Monete totali: %d" % GameData.monete_stella)
	GameData.check_and_save_record("mode_1", current_time)

	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
