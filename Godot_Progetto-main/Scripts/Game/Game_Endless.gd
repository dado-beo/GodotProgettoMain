extends Node2D

# --- REFERENZE AI NODI DELLA SCENA ---
@onready var invasion_label = $InvasionLabel 
@onready var game_over_screen = $GameOver
@onready var musica: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer") # <-- AGGIUNTO

# Riferimenti Animazione UI
@onready var contenitore_ui = get_node_or_null("UI/Contenitore UI") 
@onready var biscotti_label = get_node_or_null("UI/Contenitore UI/BiscottiLabel")

# Spawners
@onready var ninja_spawner = $NinjaSpawner
@onready var turtle_spawner = $TurtleSpawner
@onready var asteroid_spawner = $AsteroidSpawner
@onready var purple_devil_spawner = $PurpleDevilSpawner

# --- VARIABILI DI GIOCO ---
var time_survived: float = 0.0
var is_game_active: bool = true

# Statistiche della partita attuale
var last_minute_passed: int = 0
var enemies_killed: int = 0
var biscotti_ottenuti_partita: int = 0 

# Variabile per l'animazione visiva
var visual_biscotti: int = 0

# --- VARIABILI INVASIONE ---
var next_invasion_time: float = 150.0 
var invasion_cooldown_min: float = 40.0 
var invasion_cooldown_max: float = 60.0 

# Carichiamo in memoria i nemici "intrusi"
var ufo_scene = preload("res://scenes/Spaceships/Enemies/Ufo.tscn")
var ufo_divino_scene = preload("res://scenes/Spaceships/Enemies/Ufo_Divino.tscn") 
var kamikaze_scene = preload("res://scenes/Spaceships/Enemies/Kamikaze.tscn")
var hunter1_scene = preload("res://scenes/Spaceships/Enemies/Hunter1.tscn") # Modificato
var hunter2_scene = preload("res://scenes/Spaceships/Enemies/Hunter2.tscn") # Modificato

func _ready() -> void:
	randomize()
	
	add_to_group("endless_mode")
	
	if musica:
		musica.play()
		
	if invasion_label:
		invasion_label.hide() 
		
	# --- SETUP ANIMAZIONE BISCOTTI ---
	visual_biscotti = GameData.biscotti
	if contenitore_ui:
		contenitore_ui.modulate.a = 0.0 # Nascondiamo all'inizio
		if biscotti_label:
			biscotti_label.text = ": %d" % visual_biscotti
			
	GameData.biscotti_aggiornati.connect(_update_biscotti_ui) 
	
	_spawn_player()

func _process(delta: float) -> void:
	if is_game_active:
		time_survived += delta
		
		var current_minute = int(time_survived / 60)
		
		if current_minute > last_minute_passed:
			last_minute_passed = current_minute
			
			# 1. Applica la cura
			_apply_minute_heal(3)
			
			# 2. Calcola e assegna i biscotti (attiverà in automatico l'animazione)
			_reward_biscotti_for_survival(current_minute)
			
		if time_survived >= next_invasion_time:
			trigger_invasion()
			var cooldown = randf_range(invasion_cooldown_min, invasion_cooldown_max)
			next_invasion_time = time_survived + cooldown

# --- LOGICA ANIMAZIONE BISCOTTI ---

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

# --- FORMATTAZIONE TEMPO INTERNA ---
func _format_time(time_in_seconds: float) -> String:
	var minutes = int(time_in_seconds) / 60
	var seconds = int(time_in_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

# --- SISTEMA RICOMPENSE BISCOTTI ---
func _reward_biscotti_for_survival(minute: int) -> void:
	var reward = 0
	
	if minute == 1:
		reward = 10
	elif minute == 2:
		reward = 15
	elif minute >= 3:
		reward = 20 + ((minute - 3) * 10)
		
	if reward > 0:
		GameData.add_biscotti(reward)
		biscotti_ottenuti_partita += reward 
		print("Sopravvissuto ", minute, " minuti! Ricevuti: ", reward, " biscotti.")

func _apply_minute_heal(amount: int) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("heal"):
			player.heal(amount)
			print("Cura minuto effettuata: +", amount)

func _spawn_player() -> void:
	var player_scene = GameData.selected_ship_scene
	if not player_scene: 
		push_error("Nessuna scena player selezionata in GameData")
		return

	var player = player_scene.instantiate()
	player.position = get_viewport().get_visible_rect().size / 2
	add_child(player)
	player.add_to_group("player") # Già corretto! Perfetto per la pulizia finale
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	else:
		player.tree_exited.connect(_on_player_died)

# --- SISTEMA INVASIONE ---
func trigger_invasion():
	show_invasion_warning()
	await get_tree().create_timer(2.5).timeout
	
	if not is_game_active: 
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var event_type = randi() % 3 
	
	if event_type == 2:
		# INVASIONE SPECIALE: 2 CACCIATORI
		var left_hunter = hunter1_scene.instantiate()
		var right_hunter = hunter2_scene.instantiate()
		var mid_y = viewport_size.y / 2.0
		left_hunter.position = Vector2(-200, mid_y)
		right_hunter.position = Vector2(viewport_size.x + 200, mid_y)
		
		add_child(left_hunter)
		add_child(right_hunter)
		left_hunter.add_to_group("enemies")
		right_hunter.add_to_group("enemies")
		
		left_hunter.start_intro(Vector2(200, mid_y), 0.0)
		right_hunter.start_intro(Vector2(viewport_size.x - 200, mid_y), 0.5)
		
	elif event_type == 0:
		# INVASIONE UFO
		_spawn_random_enemies(ufo_scene if randf() > 0.2 else ufo_divino_scene, viewport_size)

	elif event_type == 1:
		# INVASIONE KAMIKAZE
		_spawn_random_enemies(kamikaze_scene, viewport_size)

func _spawn_random_enemies(scene: PackedScene, viewport_size: Vector2):
	var num = randi() % 3 + 1
	for i in range(num):
		var e = scene.instantiate()
		var spawn_x = -100 if randf() > 0.5 else viewport_size.x + 100
		e.position = Vector2(spawn_x, randf_range(50, viewport_size.y - 50))
		add_child(e)
		e.add_to_group("enemies")

func registra_kill() -> void:
	if is_game_active:
		enemies_killed += 1

func show_invasion_warning():
	if not invasion_label: return
	invasion_label.show()
	invasion_label.modulate.a = 1.0 
	var tween = create_tween().set_loops(4)
	tween.tween_property(invasion_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(invasion_label, "modulate:a", 1.0, 0.3)
	tween.finished.connect(func(): invasion_label.hide())


# --- SEQUENZA FINE PARTITA UNIFICATA ---

func _on_player_died():
	_avvia_sequenza_fine_gioco(false)

func _avvia_sequenza_fine_gioco(survived: bool):
	if not is_game_active: return
	is_game_active = false
	
	# 1. FERMIAMO TUTTI GLI SPAWNER IN SCENA
	if ninja_spawner and ninja_spawner.has_node("Timer"):
		ninja_spawner.get_node("Timer").stop()
	if turtle_spawner and turtle_spawner.has_node("Timer"):
		turtle_spawner.get_node("Timer").stop()
	if asteroid_spawner and asteroid_spawner.has_node("EventAsteroidTimer"):
		asteroid_spawner.get_node("EventAsteroidTimer").stop()
	if purple_devil_spawner and purple_devil_spawner.has_node("EventPurpleDevil"):
		purple_devil_spawner.get_node("EventPurpleDevil").stop()
		
	# 2. GESTIONE MUSICA
	if musica:
		if survived:
			musica.pitch_scale = 1.3
		else:
			musica.pitch_scale = 0.4
			
	# 3. EFFETTO SLOW MOTION
	Engine.time_scale = 0.1
	
	# 4. PAUSA CINEMATOGRAFICA
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# 5. PASSA AL GAME OVER
	_mostra_game_over(survived)

func _mostra_game_over(survived: bool):
	# 1. RIPRISTINO TEMPO E PULIZIA
	Engine.time_scale = 1.0
	var gruppi_da_pulire = ["enemies", "player", "projectiles", "asteroids", "grav_well"]
	for gruppo in gruppi_da_pulire:
		get_tree().call_group(gruppo, "queue_free")
		
	print("Endless terminata! Record salvato.")
	
	# 2. SALVATAGGIO DATI E SINCRONIZZAZIONE
	GameData.check_and_save_record("mode_3", time_survived)
	GameData.save_data(true)
	
	var tempo_formattato = _format_time(time_survived)
	
	# 3. MOSTRA SCHERMATA UI
	if game_over_screen and game_over_screen.has_method("setup_game_over"):
		game_over_screen.visible = true
		game_over_screen.setup_game_over(biscotti_ottenuti_partita, enemies_killed, "Tempo: " + tempo_formattato, survived)
	else:
		push_error("Nodo GameOver non trovato nella scena Endless!")
