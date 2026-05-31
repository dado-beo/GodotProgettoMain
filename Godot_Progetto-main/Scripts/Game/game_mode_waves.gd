extends Node2D

# --- RIFERIMENTI NODI
@onready var wave_label: Label = get_node_or_null("CanvasLayer/WaveLabel")
@onready var contenitore_ui = get_node_or_null("UI/Contenitore UI") 
@onready var biscotti_label = get_node_or_null("UI/Contenitore UI/BiscottiLabel")
@onready var game_over_screen = get_node_or_null("GameOver")
@onready var musica: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer") # <-- AGGIUNTO: Riferimento alla musica

# --- COSTANTI E SCENE ---
const SPAWN_WIDTH := 1152
const SPAWN_HEIGHT := 648
const ENEMY_SCENE := preload("res://scenes/Spaceships/Enemies/Ufo.tscn")
const HUNTER1_SCENE := preload("res://scenes/Spaceships/Enemies/hunter1.tscn") 
const HUNTER2_SCENE := preload("res://scenes/Spaceships/Enemies/hunter2.tscn") 
const DIVINE_UFO_SCENE := preload("res://scenes/Spaceships/Enemies/Ufo_Divino.tscn")

# --- VARIABILI ANIMAZIONE ---
var visual_biscotti: int = 0

# --- LOGICA DI GIOCO ---
var boss_phase_triggered: bool = false
var mai_colpito: bool = true 
var is_game_active: bool = true 

var current_wave: int = 0
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var is_spawning: bool = false
var rewarded_waves: Array = []
var max_waves: int = 3

var enemies_killed: int = 0 
var biscotti_ottenuti_partita: int = 0 

var waves_data = [
	{"enemies": 3, "spawn_interval": 2.0},
	{"enemies": 6, "spawn_interval": 1.6},
	{"enemies": 12, "spawn_interval": 2.0},
]

func _ready() -> void:
	randomize()
	
	if musica:
		musica.play()
	
	# Setup UI Animata
	visual_biscotti = GameData.biscotti
	if contenitore_ui:
		contenitore_ui.modulate.a = 0.0 # Nascondiamo all'inizio
		if biscotti_label:
			biscotti_label.text = ": %d" % visual_biscotti
	
	GameData.biscotti_aggiornati.connect(_update_biscotti_ui) 
	
	_spawn_player()
	await start_next_wave()

# --- ANIMAZIONE BISCOTTI ---

func _update_biscotti_ui(nuovo_valore: int):
	if nuovo_valore > visual_biscotti:
		var guadagno = nuovo_valore - visual_biscotti
		_esegui_animazione_biscotti(guadagno, nuovo_valore)
	else:
		visual_biscotti = nuovo_valore
		if biscotti_label:
			biscotti_label.text = ": %d" % visual_biscotti

func _esegui_animazione_biscotti(quantita: int, totale_finale: int):
	if not contenitore_ui or not biscotti_label: return

	var popup = Label.new()
	popup.text = "+%d" % quantita
	if biscotti_label.label_settings:
		popup.label_settings = biscotti_label.label_settings
	
	popup.modulate = Color(1.0, 0.8, 0.0) 
	contenitore_ui.add_child(popup)
	popup.position = biscotti_label.position + Vector2(80, -20)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(contenitore_ui, "modulate:a", 1.0, 0.3)
	tween.tween_property(popup, "position:y", popup.position.y - 60, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(popup, "modulate:a", 0.0, 0.4).set_delay(0.8)
	
	var count_tween = create_tween()
	count_tween.tween_method(func(v): biscotti_label.text = ": %d" % v, visual_biscotti, totale_finale, 1.0).set_delay(0.2)
	
	visual_biscotti = totale_finale
	await count_tween.finished
	await get_tree().create_timer(1.5).timeout
	
	if visual_biscotti == GameData.biscotti:
		create_tween().tween_property(contenitore_ui, "modulate:a", 0.0, 0.5)
	popup.queue_free()

# --- GESTIONE ONDATE ---

func _spawn_player() -> void:
	var player_scene = GameData.selected_ship_scene
	if not player_scene: return
		
	var player = player_scene.instantiate()
	player.position = get_viewport().get_visible_rect().size / 2
	add_child(player)
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	else:
		player.tree_exited.connect(_on_player_died)
		
	if player.has_signal("preso_danno"):
		player.preso_danno.connect(func(): mai_colpito = false)

func start_next_wave():
	if not is_inside_tree() or not is_game_active: return

	if current_wave >= max_waves:
		if wave_label:
			wave_label.text = ""
			wave_label.visible = true
		GameData.check_and_save_record("mode_2", current_wave)
		if mai_colpito: GameData.sblocca_achievement("secondaMod_MaiColpito")
		
		# Abbiamo rimosso il timer manuale qui per affidare tutto al nuovo regista della fine partita
		if is_game_active: _vittoria_boss_finale()
		return

	current_wave += 1
	var wave_data = waves_data[current_wave - 1]
	enemies_to_spawn = wave_data["enemies"]
	var spawn_interval = wave_data["spawn_interval"]

	if wave_label:
		wave_label.text = "Ondata %d" % current_wave
		wave_label.visible = true
	
	await get_tree().create_timer(2.0).timeout
	if wave_label: wave_label.visible = false
	if not is_game_active: return
	
	spawn_wave(enemies_to_spawn, spawn_interval)

	while (is_spawning or get_tree().get_nodes_in_group("enemies").size() > 0) and is_game_active:
		await get_tree().process_frame

	if not is_game_active: return

	if current_wave == max_waves and not boss_phase_triggered:
		boss_phase_triggered = true
		if wave_label:
			wave_label.text = "CACCIATORI IN ARRIVO!"
			wave_label.visible = true
			var t = create_tween().set_loops(4)
			t.tween_property(wave_label, "modulate:a", 0.0, 0.3)
			t.tween_property(wave_label, "modulate:a", 1.0, 0.3)
			await t.finished 
			wave_label.visible = false
		
		if is_game_active: _spawn_final_hunters()
		
		while get_tree().get_nodes_in_group("enemies").size() > 0 and is_game_active:
			await get_tree().process_frame

	if is_game_active:
		await get_tree().create_timer(0.5).timeout
		_on_wave_finished()

func spawn_wave(count: int, interval: float):
	is_spawning = true
	var divin_ufo_spawned = false 
	for i in range(count):
		if not is_game_active: break
		
		# --- FIX PAUSA: Blocca il ciclo finché il gioco è in pausa ---
		while get_tree().paused:
			await get_tree().process_frame
			
		var spawn_divine = false
		if not divin_ufo_spawned and randf() <= 0.1:
			spawn_divine = true
			divin_ufo_spawned = true
			
		spawn_enemy(spawn_divine)
		enemies_to_spawn = max(0, enemies_to_spawn - 1)
		
		# I parametri 'false, false' forzano il timer a fermarsi durante la pausa
		await get_tree().create_timer(interval, false, false).timeout
		
	is_spawning = false

func spawn_enemy(is_divine: bool = false) -> void:
	if not is_game_active: return
	var enemy = DIVINE_UFO_SCENE.instantiate() if is_divine else ENEMY_SCENE.instantiate()
	enemy.position = Vector2(randi() % SPAWN_WIDTH, randi() % SPAWN_HEIGHT)
	add_child(enemy)
	enemy.add_to_group("enemies")
	enemies_alive += 1
	enemy.tree_exited.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	if is_game_active:
		enemies_alive = max(0, enemies_alive - 1)
		enemies_killed += 1

func _on_wave_finished() -> void:
	if not is_game_active: return
	_give_wave_reward(current_wave)
	GameData.check_and_save_record("mode_2", current_wave)

	if wave_label:
		wave_label.text = "Ondata %d completata!" % current_wave
		wave_label.visible = true
	
	await get_tree().create_timer(2.0).timeout
	if wave_label: wave_label.visible = false
	if is_game_active: start_next_wave()

func _spawn_final_hunters():
	var mid_y = SPAWN_HEIGHT / 2.0
	
	var left_hunter = HUNTER1_SCENE.instantiate()
	var right_hunter = HUNTER2_SCENE.instantiate()
	
	left_hunter.position = Vector2(-200, mid_y)
	right_hunter.position = Vector2(SPAWN_WIDTH + 200, mid_y)
	
	add_child(left_hunter)
	add_child(right_hunter)
	
	left_hunter.add_to_group("enemies")
	right_hunter.add_to_group("enemies")
	left_hunter.tree_exited.connect(_on_enemy_died)
	right_hunter.tree_exited.connect(_on_enemy_died)
	enemies_alive += 2
	
	left_hunter.start_intro(Vector2(200, mid_y), 0.0)
	right_hunter.start_intro(Vector2(SPAWN_WIDTH - 200, mid_y), 0.5)

func _give_wave_reward(wave: int) -> void:
	if wave in rewarded_waves: return
	var reward = 0
	match wave:
		1: reward = 5
		2: reward = 10
		3: reward = 15
	
	if reward > 0:
		GameData.add_biscotti(reward)
		biscotti_ottenuti_partita += reward
	rewarded_waves.append(wave)

# --- SEQUENZA FINE PARTITA UNIFICATA ---

func _on_player_died():
	_avvia_sequenza_fine_gioco(false)

func _vittoria_boss_finale():
	_avvia_sequenza_fine_gioco(true)

func _avvia_sequenza_fine_gioco(survived: bool):
	if not is_game_active: return
	is_game_active = false
	is_spawning = false
	
	# 1. GESTIONE MUSICA
	if musica:
		if survived:
			musica.pitch_scale = 1.3
		else:
			musica.pitch_scale = 0.4
			
	# 2. EFFETTO SLOW MOTION
	Engine.time_scale = 0.1
	
	# 3. PAUSA CINEMATOGRAFICA
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# 4. PASSA AL GAME OVER
	_mostra_game_over(survived)

func _mostra_game_over(survived: bool):
	# RIPRISTINO TEMPO E PULIZIA
	Engine.time_scale = 1.0
	var gruppi_da_pulire = ["enemies", "player", "projectiles", "asteroids", "grav_well"]
	for gruppo in gruppi_da_pulire:
		get_tree().call_group(gruppo, "queue_free")
		
	GameData.save_data(true) 
	
	if game_over_screen:
		game_over_screen.visible = true
		var testo = "Ondata: " + str(current_wave) if not survived else "VITTORIA!"
		game_over_screen.setup_game_over(biscotti_ottenuti_partita, enemies_killed, testo, survived)
