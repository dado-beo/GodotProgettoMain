extends Node2D

const ENEMY_SCENE = preload("res://scenes/Spaceships/Enemies/Purple_Devil.tscn")

const SCREEN_WIDTH = 1152
const SCREEN_HEIGHT = 648
const SPAWN_INTERVAL = 17.5 # ogni 17.5 secondi

func _ready():
	randomize()

	if has_node("EventPurpleDevil"):
		$EventPurpleDevil.wait_time = SPAWN_INTERVAL
		$EventPurpleDevil.autostart = true
		$EventPurpleDevil.one_shot = false
		$EventPurpleDevil.start()

func _on_event_purple_devil_timeout() -> void:
	# Logica Probabilità:
	# randf() genera un numero tra 0.0 e 1.0
	# Se esce un numero > 0.75 (quindi tra 0.76 e 1.00 -> 25% dei casi), salta.
	# Risultato: 75% di probabilità di SPAWN.
	if randf() > 0.50:
		print("Evento Devil: Saltato (Sfortuna!)")
		return
	
	print("Evento Devil: ATTIVATO!")
	_spawn_devil()

# Questa è la funzione che mancava nel tuo codice originale
func _spawn_devil():
	var enemy = ENEMY_SCENE.instantiate()
	
	# Calcola la posizione PRIMA di aggiungere il figlio
	# Questo è fondamentale perché lo script del nemico usa la posizione nel suo _ready()
	enemy.global_position = spawn_outside_screen()
	
	add_child(enemy) 

func spawn_outside_screen() -> Vector2:
	var pos = Vector2()
	var side = randi() % 4

	match side:
		0: # Sinistra
			pos.x = -50
			pos.y = randf() * SCREEN_HEIGHT
		1: # Destra
			pos.x = SCREEN_WIDTH + 50
			pos.y = randf() * SCREEN_HEIGHT
		2: # Sopra
			pos.x = randf() * SCREEN_WIDTH
			pos.y = -50
		3: # Sotto
			pos.x = randf() * SCREEN_WIDTH
			pos.y = SCREEN_HEIGHT + 50

	return pos
