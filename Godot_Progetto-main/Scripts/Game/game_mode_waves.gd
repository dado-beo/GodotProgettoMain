extends Node2D

@onready var wave_label: Label = get_node_or_null("CanvasLayer/WaveLabel")
@onready var monete_label: Label = get_node_or_null("MoneteLabel")

const SPAWN_WIDTH := 1152
const SPAWN_HEIGHT := 648
const ENEMY_SCENE := preload("res://scenes/Spaceships/Enemies/Ufo.tscn")

const HUNTER_SCENE := preload("res://scenes/Spaceships/Enemies/Hunter.tscn") # Controlla il percorso!
var boss_phase_triggered: bool = false

var current_wave: int = 0
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var is_spawning: bool = false
var rewarded_waves: Array = []
var max_waves: int = 3

var mai_colpito: bool = true # Variabile per l'achievement

var waves_data = [
	{"enemies": 3, "spawn_interval": 2.0},
	{"enemies": 6, "spawn_interval": 1.6},
	{"enemies": 12, "spawn_interval": 2.0},
]

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
		
	# --- Rilevamento per l'Achievement Intoccabile ---
	if player.has_signal("preso_danno"):
		player.preso_danno.connect(func(): mai_colpito = false)

func start_next_wave():
	if current_wave >= max_waves:
		if wave_label:
			wave_label.text = "Tutte le ondate completate!"
			wave_label.visible = true
			
		GameData.check_and_save_record("mode_2", current_wave)
		
		# --- NUOVO: Controllo e Sblocco Achievement ---
		if mai_colpito:
			GameData.sblocca_achievement("secondaMod_MaiColpito")
		
		if is_inside_tree():
			await get_tree().create_timer(3.0).timeout
			if is_inside_tree():
				get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
		return

	current_wave += 1
	var wave_data = waves_data[current_wave - 1]
	enemies_to_spawn = wave_data["enemies"]
	var spawn_interval = wave_data["spawn_interval"]

	if wave_label:
		wave_label.text = "Ondata %d" % current_wave
		wave_label.visible = true
	
	if is_inside_tree():
		await get_tree().create_timer(2.0).timeout
	else:
		return 
	
	if wave_label:
		wave_label.visible = false

	print("--- START ONDATA %d ---" % current_wave)
	spawn_wave(enemies_to_spawn, spawn_interval)

	# --- LOOP ATTESA NEMICI NORMALI ---
	while is_spawning or get_tree().get_nodes_in_group("enemies").size() > 0:
		if not is_inside_tree(): 
			return
		await get_tree().process_frame

	# --- NUOVO: FASE BOSS EXTRA PER L'ULTIMA ONDATA ---
	if current_wave == max_waves and not boss_phase_triggered:
		boss_phase_triggered = true
		
		if wave_label:
			wave_label.text = "CACCIATORI IN ARRIVO!"
			wave_label.visible = true
			wave_label.modulate.a = 1.0 # Assicura che l'opacità sia al massimo
			
			# Usiamo lo stesso Tween dell'Endless mode per il lampeggio!
			var tween = create_tween().set_loops(4)
			tween.tween_property(wave_label, "modulate:a", 0.0, 0.3)
			tween.tween_property(wave_label, "modulate:a", 1.0, 0.3)
			
			# Invece di un timer fisso, aspettiamo che finisca l'animazione di lampeggio
			await tween.finished 
			
			if is_inside_tree() and wave_label:
				wave_label.visible = false
		else:
			# Se per caso la label non c'è, aspettiamo comunque circa 2.5 secondi
			await get_tree().create_timer(2.4).timeout
		
		# Esegui lo spawn speciale
		if is_inside_tree():
			_spawn_final_hunters()
		
		# Nuovo Loop: Aspettiamo che muoiano i Cacciatori
		while get_tree().get_nodes_in_group("enemies").size() > 0:
			if not is_inside_tree(): return
			await get_tree().process_frame

	# Se siamo arrivati qui, tutti i nemici (inclusi i boss se c'erano) sono morti
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

func _spawn_final_hunters():
	print("--- SPAWN BOSS CACCIATORI ---")
	
	var left_hunter = HUNTER_SCENE.instantiate()
	var right_hunter = HUNTER_SCENE.instantiate()
	
	# Li posizioniamo fuori dallo schermo a metà altezza
	var mid_y = SPAWN_HEIGHT / 2.0
	left_hunter.position = Vector2(-200, mid_y)
	right_hunter.position = Vector2(SPAWN_WIDTH + 200, mid_y)
	
	add_child(left_hunter)
	add_child(right_hunter)
	
	# Assicuriamoci che contino come nemici
	left_hunter.add_to_group("enemies")
	right_hunter.add_to_group("enemies")
	
	left_hunter.tree_exited.connect(_on_enemy_died)
	right_hunter.tree_exited.connect(_on_enemy_died)
	enemies_alive += 2
	
	# Punti di arrivo (un po' all'interno dello schermo)
	var left_target = Vector2(200, mid_y)
	var right_target = Vector2(SPAWN_WIDTH - 200, mid_y)
	
	# Avviamo il loro comportamento. 
	# Il secondo parametro è il delay: il destro parte 0.5 sec dopo per creare il pattern sfalsato!
	left_hunter.start_intro(left_target, 0.0)
	right_hunter.start_intro(right_target, 0.5)

func _on_player_died():
	# PRINT MANTENUTO: Morte del giocatore
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
