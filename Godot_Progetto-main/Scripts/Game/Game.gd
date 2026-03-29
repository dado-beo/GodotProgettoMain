extends Node2D

const GAME_DURATION := 180
# Dizionario: Al secondo X dai Y monete
const REWARD_TIMINGS := {
	60: 5,
	120: 15,
	180: 30
}

var current_time := 0
var rewarded_minutes := []

@onready var game_timer: Timer = $GameTimer
@onready var time_label: Label = $GameTimer/TimeLabel
@onready var monete_label: Label = $MoneteLabel
@onready var spawner: Node = $EnemySpawner # Assicurati che il nome nodo sia corretto
@onready var musica: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	if musica:
		musica.play()
	
	# 1. Aggiorna label monete iniziale
	_update_monete_ui(GameData.monete_stella)
	
	# 2. Collega il segnale: se le monete cambiano (es. ricompensa), aggiorna la label
	GameData.monete_aggiornate.connect(_update_monete_ui)

	if time_label:
		time_label.text = "Tempo: 00:00"

	# Collega il timeout del timer
	if game_timer.is_stopped():
		game_timer.timeout.connect(_on_timer_tick)

	# Ferma lo spawner inizialmente
	if spawner:
		spawner.set_process(false)

	# Spawna la navicella selezionata
	# await get_tree().process_frame # Opzionale, spesso non serve se lo script è ben ordinato
	_spawn_selected_player()

	# Avvia gioco
	game_timer.start()
	if spawner:
		spawner.set_process(true)

# Funzione per aggiornare la UI delle monete
func _update_monete_ui(valore: int):
	if monete_label:
		monete_label.text = ": %d" % valore

func _spawn_selected_player():
	# DIPENDENZA CORRETTA: Usa GameData
	var player_scene = GameData.selected_ship_scene
	
	if not player_scene:
		push_error("GameData.selected_ship_scene è null! Controllo se è stato caricato.")
		return

	var player = player_scene.instantiate()
	
	# Posiziona il player al centro dello schermo
	player.position = get_viewport_rect().size / 2
	add_child(player)
	
	# Opzionale: collega il segnale di morte del player se esiste
	if player.has_signal("died"):
		player.died.connect(_on_player_died)

func _on_timer_tick():
	current_time += 1
	_update_timer_label()

	# Velocità spawn progressiva (se lo spawner ha questo metodo)
	if spawner and spawner.has_method("update_spawn_speed"):
		spawner.update_spawn_speed(current_time)

	# Ricompense a tempo
	if current_time in REWARD_TIMINGS and current_time not in rewarded_minutes:
		var reward = REWARD_TIMINGS[current_time]
		
		# DIPENDENZA CORRETTA: Usa GameData per aggiungere soldi
		GameData.add_monete(reward)
		
		print("Hai ricevuto %d monete!" % reward)
		rewarded_minutes.append(current_time)

	if current_time >= GAME_DURATION:
		game_timer.stop()
		if spawner: spawner.set_process(false)
		_game_over()

func _update_timer_label():
	var minutes = current_time / 60
	var seconds = current_time % 60
	if time_label:
		time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

# Funzione per gestire la morte del player
func _on_player_died():
	game_timer.stop()
	$AudioStreamPlayer.pitch_scale=0.4
	Engine.time_scale=0.1
	await get_tree().create_timer(3*Engine.time_scale).timeout
	Engine.time_scale=1
	if spawner: spawner.set_process(false)
	_game_over()

func _game_over():
	print("Gioco terminato! Monete totali: %d" % GameData.monete_stella)
	
	# DIPENDENZA CORRETTA: Salva il record su GameData
	GameData.check_and_save_record("mode_1", current_time)
	# --------------------------

	# Gestione transizione scena
	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		# Se hai il singleton FadeTransition attivato
		FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
