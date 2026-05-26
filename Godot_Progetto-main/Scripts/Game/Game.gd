extends Node2D

const GAME_DURATION := 90 # Cambiato da 180 a 90 (1 min e 30 sec)
# Dizionario: Al secondo X dai Y biscotti
const REWARD_TIMINGS := {
	30: 5,   # Prima stella (Facile)
	60: 15,  # Seconda stella (Medio)
	90: 30   # Terza stella (Difficile)
}

const WIDTH = 1152
const HEIGHT = 648
const enemy_scene = preload("res://scenes/Game/spawning_enemy.tscn")
const grav_well_scene = preload("res://scenes/Spaceships/Enemies/Ancora_Gravitazionale.tscn") 

var spawnArea = Rect2()
var delta := 2.5 # Partiamo da 2.5 per una partenza tranquilla
var offset := 0.5
var current_time := 0
var rewarded_minutes := []
var enemies_killed := 0
var biscotti_ottenuti_partita := 0 # Modificato da monete a biscotti

# --- Tempi in cui spawna l'Ancora Gravitazionale ---
var grav_well_spawn_times = [60] 

# --- VARIABILI PER L'ANIMAZIONE UI ---
var visual_biscotti: int = 0

# --- REFERENZE AI NODI ---
@onready var game_timer: Timer = $GameTimer
@onready var time_label: Label = $GameTimer/TimeLabel 
@onready var contenitore_ui = $"UI/Contenitore UI" # Riferimento aggiornato per l'animazione
@onready var biscotti_label = $"UI/Contenitore UI/BiscottiLabel" # Riferimento aggiornato
@onready var musica: AudioStreamPlayer = $AudioStreamPlayer
@onready var spawn_timer: Timer = $Timer 
@onready var game_over_screen = $GameOver

func _ready():
	if musica:
		musica.play()
	
	randomize()
	spawnArea = Rect2(0, 0, WIDTH, HEIGHT)
	
	# Inizializza UI Biscotti e la rende invisibile all'inizio
	visual_biscotti = GameData.biscotti
	if contenitore_ui:
		contenitore_ui.modulate.a = 0.0
		if biscotti_label:
			biscotti_label.text = ": %d" % visual_biscotti
	
	# Connette il segnale corretto da GameData
	GameData.biscotti_aggiornati.connect(_update_biscotti_ui)

	if time_label:
		time_label.text = "Tempo: 00:00"

	# Connettiamo i timer
	if game_timer.is_stopped():
		game_timer.timeout.connect(_on_timer_tick)
	if spawn_timer.is_stopped():
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	_spawn_selected_player()

	# Avvio i timer
	game_timer.start()
	set_next_spawn()

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
	
	popup.modulate = Color(1.0, 0.8, 0.0) # Giallo dorato
	contenitore_ui.add_child(popup)
	popup.position = biscotti_label.position + Vector2(100, -20)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(contenitore_ui, "modulate:a", 1.0, 0.3)
	tween.tween_property(popup, "position:y", popup.position.y - 60, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(popup, "modulate:a", 0.0, 0.4).set_delay(0.8)
	
	var count_tween = create_tween()
	count_tween.tween_method(
		func(v): biscotti_label.text = ": %d" % v, 
		visual_biscotti, 
		totale_finale, 
		1.0
	).set_delay(0.2)
	
	visual_biscotti = totale_finale
	
	await count_tween.finished
	await get_tree().create_timer(1.5).timeout
	
	# Nasconde di nuovo se non ci sono stati altri aggiornamenti nel frattempo
	if visual_biscotti == GameData.biscotti:
		var fade_out = create_tween()
		fade_out.tween_property(contenitore_ui, "modulate:a", 0.0, 0.5)
	
	popup.queue_free()

# --- GESTIONE SPAWN NEMICI BASE ---
func set_next_spawn():
	var nextTime = delta + (randf() - 0.5) * 2 * offset
	nextTime = clamp(nextTime, 0.1, 5.0)  # per sicurezza
	spawn_timer.wait_time = nextTime
	spawn_timer.start()
	
func _on_spawn_timer_timeout():
	spawn_enemy()
	set_next_spawn()

func spawn_enemy():
	if not is_inside_tree(): return
	
	var spawn_pos = Vector2(randi() % WIDTH, randi() % HEIGHT)
	var enemy_inst = enemy_scene.instantiate()
	enemy_inst.position = spawn_pos
	
	# Connettiamo il segnale della kill sull'istanza appena creata
	if enemy_inst.has_signal("kamikazeDeath"):
		enemy_inst.kamikazeDeath.connect(_on_enemy_died)
	else:
		enemy_inst.tree_exited.connect(_on_enemy_died)
		
	add_child(enemy_inst)

# Aggiorna velocità di spawn in base al tempo di gioco (Totale 90 sec)
func update_spawn_speed(c_time: int) -> void:
	# Da 0 a 30 secondi (Fase Facile / Principianti)
	if c_time <= 30:
		var progress: float = c_time / 30.0
		# Scende dolcemente da 2.5 a 1.5 secondi tra uno spawn e l'altro
		delta = lerp(2.5, 1.5, progress)
		
	# Da 30 a 60 secondi (Fase Media)
	elif c_time <= 60:
		var progress: float = (c_time - 30) / 30.0
		# Scende da 1.5 a 0.8 secondi (inizia a farsi affollato)
		delta = lerp(1.5, 0.8, progress)
		
	# Da 60 a 90 secondi (Fase Difficile / Sopravvivenza finale)
	elif c_time <= 90:
		var progress: float = (c_time - 60) / 30.0
		# Scende da 0.8 a 0.35 secondi
		delta = lerp(0.8, 0.35, progress)
		
	# Oltre i 90 secondi
	else:
		delta = 0.35

# --- LOGICA DI GIOCO E RICOMPENSE ---
func _on_timer_tick():
	current_time += 1
	_update_timer_label()
	
	# Aggiorna la velocità di spawn definita in questo script
	update_spawn_speed(current_time)

	# Assegnazione Ricompense
	if current_time in REWARD_TIMINGS and current_time not in rewarded_minutes:
		var reward = REWARD_TIMINGS[current_time]
		GameData.add_biscotti(reward) # Aggiornato per usare i biscotti
		biscotti_ottenuti_partita += reward
		print("Hai ricevuto %d biscotti!" % reward)
		rewarded_minutes.append(current_time)
		
	# Controllo Spawn Ancora Gravitazionale
	if current_time in grav_well_spawn_times:
		_spawn_grav_well()

	if current_time >= GAME_DURATION:
		_game_over(true) # True = ha vinto/sopravvissuto allo scadere del tempo

func _update_timer_label():
	var minutes = current_time / 60
	var seconds = current_time % 60
	if time_label:
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

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

# --- SPAWN EVENTI SPECIALI ---
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
		if "target_position" in grav_well:
			grav_well.target_position = first_target
			
		add_child(grav_well)
		
	print("ATTENZIONE: 2 Ancore Gravitazionali in arrivo da lati opposti!")

# --- EVENTI E GAME OVER ---
func _on_enemy_died() -> void:
	enemies_killed += 1

func _on_player_died():
	game_timer.stop()
	spawn_timer.stop()
	if musica: musica.pitch_scale = 0.4
	
	get_tree().call_group("enemies", "queue_free") # Questo comando dice a tutti i nodi nel gruppo "enemies" di autodistruggersi!
	
	# Rallenta il tempo al 10%
	Engine.time_scale = 0.1
	
	# Aspettiamo 1 secondo REALE (ignorando il time_scale di Engine)
	await get_tree().create_timer(1.0, true, false, true).timeout
	
	# Riportiamo il tempo normale per la UI
	Engine.time_scale = 1.0
	
	# Ora chiamiamo la funzione che fa apparire il Game Over
	_game_over(false)
	
func _game_over(survived: bool):
	print("Gioco terminato! Biscotti totali: %d" % GameData.biscotti)
	game_timer.stop()
	spawn_timer.stop()
	GameData.check_and_save_record("mode_1", current_time)
	var tempo_finale = time_label.text if time_label else "Tempo: 00:00"
		
	# Passiamo i dati alla UI di Game Over e la rendiamo visibile
	if game_over_screen and game_over_screen.has_method("setup_game_over"):
		game_over_screen.visible = true
		game_over_screen.setup_game_over(biscotti_ottenuti_partita, enemies_killed, tempo_finale, survived)
	else:
		push_error("Il nodo Game Over non è stato trovato o non ha il metodo setup_game_over")
