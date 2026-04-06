extends Node2D

@onready var turtle_spawner = $TurtleSpawner
@onready var invasion_label = $InvasionLabel 

var time_survived: float = 0.0
var is_game_active: bool = true

# Variabile per tenere traccia dei minuti trascorsi (sia per cure che per monete)
var last_minute_passed: int = 0

# --- VARIABILI INVASIONE ---
var next_invasion_time: float = 150.0 # 150 secondi = 2 minuti e 30
var invasion_cooldown_min: float = 40.0 # Tempo minimo tra un'invasione e l'altra
var invasion_cooldown_max: float = 60.0 # Tempo massimo

# Carichiamo in memoria i nemici "intrusi"
var ufo_scene = preload("res://scenes/Spaceships/Enemies/Ufo.tscn")
var ufo_divino_scene = preload("res://scenes/Spaceships/Enemies/Ufo_Divino.tscn") 
var kamikaze_scene = preload("res://scenes/Spaceships/Enemies/Kamikaze.tscn")
# --- IL CACCIATORE ---
var hunter_scene = preload("res://scenes/Spaceships/Enemies/Hunter.tscn") 

func _ready() -> void:
	randomize()
	if invasion_label:
		invasion_label.hide() # Ci assicuriamo che sia nascosta all'avvio
	_spawn_player()

func _process(delta: float) -> void:
	if is_game_active:
		time_survived += delta
		
		# --- LOGICA EVENTI ALLO SCADERE DEL MINUTO ---
		# Calcoliamo il minuto corrente (es: 65 secondi / 60 = minuto 1)
		var current_minute = int(time_survived / 60)
		
		# Se è scattato un nuovo minuto (e non è il minuto 0 dell'inizio)
		if current_minute > last_minute_passed:
			last_minute_passed = current_minute
			
			# 1. Applica la cura
			_apply_minute_heal(3)
			
			# 2. Calcola e assegna le monete
			_reward_coins_for_survival(current_minute)
			
		# --- LOGICA TRIGGER INVASIONE ---
		# Controlliamo se il tempo di sopravvivenza ha superato il tempo previsto per l'invasione
		if time_survived >= next_invasion_time:
			trigger_invasion()
			# Calcola un nuovo tempo casuale per la PROSSIMA invasione aggiungendolo al tempo attuale
			var cooldown = randf_range(invasion_cooldown_min, invasion_cooldown_max)
			next_invasion_time = time_survived + cooldown

# --- SISTEMA RICOMPENSE MONETE ---
func _reward_coins_for_survival(minute: int) -> void:
	var reward = 0
	
	if minute == 1:
		reward = 5
	elif minute == 2:
		reward = 10
	elif minute >= 3:
		# Dal minuto 3 in poi: base 15 + 5 extra per ogni minuto oltre il terzo
		reward = 15 + ((minute - 3) * 5)
		
	if reward > 0:
		GameData.add_monete(reward)
		print("Sopravvissuto ", minute, " minuti! Ricevute: ", reward, " monete.")

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
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Scegliamo a caso il tipo di invasione (0 = Ufo, 1 = Kamikaze, 2 = Hunter)
	var event_type = randi() % 3 
	
	if event_type == 2:
		# ==========================================
		# INVASIONE SPECIALE: 2 CACCIATORI
		# ==========================================
		print("Invasione Endless: I Cacciatori sono arrivati!")
		var left_hunter = hunter_scene.instantiate()
		var right_hunter = hunter_scene.instantiate()
		
		var mid_y = viewport_size.y / 2.0
		left_hunter.position = Vector2(-200, mid_y)
		right_hunter.position = Vector2(viewport_size.x + 200, mid_y)
		
		add_child(left_hunter)
		add_child(right_hunter)
		
		left_hunter.add_to_group("enemies")
		right_hunter.add_to_group("enemies")
		
		var left_target = Vector2(200, mid_y)
		var right_target = Vector2(viewport_size.x - 200, mid_y)
		
		# Animazione di entrata stile boss, sfasata di mezzo secondo
		left_hunter.start_intro(left_target, 0.0)
		right_hunter.start_intro(right_target, 0.5)
		
	elif event_type == 0:
		# ==========================================
		# INVASIONE UFO: Standard o Divino (50/50)
		# ==========================================
		if randf() <= 0.5:
			# 50% di probabilità: Spawn di un singolo UFO Divino
			print("Invasione Endless: È arrivato l'UFO DIVINO!")
			var divine_ufo = ufo_divino_scene.instantiate()
			
			var spawn_x = -100 if randf() > 0.5 else viewport_size.x + 100
			var spawn_y = randf_range(50, viewport_size.y - 50)
			
			divine_ufo.position = Vector2(spawn_x, spawn_y)
			add_child(divine_ufo)
			divine_ufo.add_to_group("enemies")
		else:
			# 50% di probabilità: Spawn da 1 a 3 UFO normali
			var num_enemies = randi() % 3 + 1 
			print("Invasione Endless: ", num_enemies, " UFO standard.")
			
			for i in range(num_enemies):
				var enemy = ufo_scene.instantiate()
				var spawn_x = -100 if randf() > 0.5 else viewport_size.x + 100
				var spawn_y = randf_range(50, viewport_size.y - 50)
				
				enemy.position = Vector2(spawn_x, spawn_y)
				add_child(enemy)
				enemy.add_to_group("enemies")

	elif event_type == 1:
		# ==========================================
		# INVASIONE KAMIKAZE: Da 1 a 3 navicelle
		# ==========================================
		var num_enemies = randi() % 3 + 1 
		print("Invasione Endless: ", num_enemies, " Kamikaze.")
		
		for i in range(num_enemies):
			var enemy = kamikaze_scene.instantiate()
			var spawn_x = -100 if randf() > 0.5 else viewport_size.x + 100
			var spawn_y = randf_range(50, viewport_size.y - 50)
			
			enemy.position = Vector2(spawn_x, spawn_y)
			add_child(enemy)
			enemy.add_to_group("enemies")

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
