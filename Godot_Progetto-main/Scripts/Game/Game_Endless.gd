extends Node2D

@onready var turtle_spawner = $TurtleSpawner
@onready var invasion_label = $InvasionLabel # Assicurati che il percorso sia corretto in base a dove l'hai messa!

var time_survived: float = 0.0
var is_game_active: bool = true
var last_minute_healed: int = 0

# --- VARIABILI INVASIONE ---
# --- VARIABILI INVASIONE ---
var next_invasion_time: float = 150.0 # 150 secondi = 2 minuti e 30 (Modificato!)
var invasion_cooldown_min: float = 40.0 # Tempo minimo tra un'invasione e l'altra
var invasion_cooldown_max: float = 60.0 # Tempo massimo

# Carichiamo in memoria i nemici "intrusi"
var ufo_scene = preload("res://scenes/Spaceships/Enemies/Ufo.tscn")
var kamikaze_scene = preload("res://scenes/Spaceships/Enemies/Kamikaze.tscn")

func _ready() -> void:
	randomize()
	if invasion_label:
		invasion_label.hide() # Ci assicuriamo che sia nascosta all'avvio
	_spawn_player()

func _process(delta: float) -> void:
	if is_game_active:
		time_survived += delta
		
		# --- LOGICA CURA OGNI MINUTO ---
		# Calcoliamo il minuto corrente (es: 65 secondi / 60 = minuto 1)
		var current_minute = int(time_survived / 60)
		
		# Se è scattato un nuovo minuto (e non è il minuto 0 dell'inizio)
		if current_minute > last_minute_healed:
			last_minute_healed = current_minute
			_apply_minute_heal(3)
			
		# --- LOGICA TRIGGER INVASIONE ---
		# Controlliamo se il tempo di sopravvivenza ha superato il tempo previsto per l'invasione
		if time_survived >= next_invasion_time:
			trigger_invasion()
			# Calcola un nuovo tempo casuale per la PROSSIMA invasione aggiungendolo al tempo attuale
			var cooldown = randf_range(invasion_cooldown_min, invasion_cooldown_max)
			next_invasion_time = time_survived + cooldown


func _apply_minute_heal(amount: int) -> void:
	# Cerchiamo il player nel gruppo
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
	player.add_to_group("player")
	
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	else:
		player.tree_exited.connect(_on_player_died)

# --- SISTEMA INVASIONE ---
func trigger_invasion():
	show_invasion_warning()
	
	# Aspettiamo 2.5 secondi (mentre la scritta lampeggia) prima di far spawnare i nemici
	await get_tree().create_timer(2.5).timeout
	
	# Se il giocatore è morto nel frattempo, interrompiamo tutto
	if not is_game_active: 
		return
	
	# 1. Scegliamo a caso tra Ufo e Kamikaze (50% di probabilità)
	var enemy_to_spawn = ufo_scene if randf() > 0.5 else kamikaze_scene
	
	# 2. Scegliamo quanti nemici far spawnare (da 1 a 3)
	var num_enemies = randi() % 3 + 1 
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	for i in range(num_enemies):
		var enemy = enemy_to_spawn.instantiate()
		
		# Facciamo spawnare i nemici leggermente fuori dallo schermo a sinistra o destra
		# così arrivano verso il centro invece di comparire in faccia al giocatore
		var spawn_x = -100 if randf() > 0.5 else viewport_size.x + 100
		var spawn_y = randf_range(50, viewport_size.y - 50)
		
		enemy.position = Vector2(spawn_x, spawn_y)
		add_child(enemy)

func show_invasion_warning():
	if not invasion_label:
		push_error("InvasionLabel non trovata! Controlla il nome del nodo.")
		return
		
	invasion_label.show()
	invasion_label.modulate.a = 1.0 # Assicuriamoci che l'opacità sia al massimo
	
	# Usiamo un Tween per far lampeggiare la scritta (Animazione via codice)
	var tween = create_tween().set_loops(4) # Ripete l'animazione 4 volte
	tween.tween_property(invasion_label, "modulate:a", 0.0, 0.3) # Svanisce in 0.3 sec
	tween.tween_property(invasion_label, "modulate:a", 1.0, 0.3) # Riappare in 0.3 sec
	
	# Quando ha finito di lampeggiare, nascondiamo la label
	tween.finished.connect(func(): invasion_label.hide())
# ------------------------

func _on_player_died():
	is_game_active = false
	_game_over()

func _game_over():
	print("Gioco terminato! Monete totali: %d" % GameData.monete_stella)
	GameData.check_and_save_record("mode_3", time_survived)

	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
