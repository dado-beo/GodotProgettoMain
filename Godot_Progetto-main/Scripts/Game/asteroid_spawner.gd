extends Node2D

@onready var timer = $EventAsteroidTimer 

# Carica la scena dell'asteroide
var asteroid_scene = preload("res://scenes/Game/asteroid.tscn")

func _ready() -> void:
	randomize()
	
	if not timer.timeout.is_connected(_on_event_asteroid_timer_timeout):
		timer.timeout.connect(_on_event_asteroid_timer_timeout)
	
	# Assicuriamoci che il timer parta
	if timer.is_stopped():
		timer.start()

func _on_event_asteroid_timer_timeout() -> void:
	# 75% di possibilità
	if randf() > 0.75:
		print("Evento Asteroide: Saltato (Sfortuna!)")
		return
	
	print("Evento Asteroide: ATTIVATO!")
	_spawn_wave()

func _spawn_wave():
	# Sceglie un numero casuale di asteroidi per questa ondata (da 1 a 6).
	var num_asteroids = randi_range(5, 10)
	
	for i in range(num_asteroids):
		_spawn_single_asteroid()
		
		# Aggiunge una pausa casuale (tra 0.3 e 1.2 secondi) prima di spawnare il prossimo asteroide.
		# In questo modo non compaiono tutti nello stesso esatto momento!
		var spawn_delay = randf_range(0.3, 1.2)
		await get_tree().create_timer(spawn_delay).timeout

func _spawn_single_asteroid():
	var asteroid = asteroid_scene.instantiate()
	
	# Aggiungiamo l'asteroide alla scena principale (il padre di questo nodo)
	add_child(asteroid)
	
	# Calcoliamo i dati di spawn
	var spawn_data = _get_random_spawn_trajectory()
	
	# Impostiamo l'asteroide
	asteroid.global_position = spawn_data.start 
	asteroid.setup(spawn_data.start, spawn_data.end)

func _get_random_spawn_trajectory() -> Dictionary:
	# Otteniamo le dimensioni dello schermo dinamicamente
	var viewport_rect = get_viewport_rect().size
	var screen_width = viewport_rect.x
	var screen_height = viewport_rect.y
	
	var side = randi() % 4
	var start_pos = Vector2()
	var end_pos = Vector2()
	var offset = 60 # Un po' di margine fuori schermo
	
	match side:
		0: # Sinistra -> Va verso Destra
			start_pos = Vector2(-offset, randf() * screen_height)
			end_pos = Vector2(screen_width + offset, randf() * screen_height)
		1: # Destra -> Va verso Sinistra
			start_pos = Vector2(screen_width + offset, randf() * screen_height)
			end_pos = Vector2(-offset, randf() * screen_height)
		2: # Sopra -> Va verso Sotto
			start_pos = Vector2(randf() * screen_width, -offset)
			end_pos = Vector2(randf() * screen_width, screen_height + offset)
		3: # Sotto -> Va verso Sopra
			start_pos = Vector2(randf() * screen_width, screen_height + offset)
			end_pos = Vector2(randf() * screen_width, -offset)
			
	return {"start": start_pos, "end": end_pos}
