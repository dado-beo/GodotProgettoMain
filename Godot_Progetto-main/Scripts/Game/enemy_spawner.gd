extends Node2D

const WIDTH = 1152
const HEIGHT = 648
const SPAWNING_ENEMY = preload("res://scenes/Game/spawning_enemy.tscn")

var spawnArea = Rect2()
var delta := 2.5 # Partiamo da 2.5 per una partenza tranquilla
var offset := 0.5
var current_game_time := 0

func _ready():
	randomize()
	spawnArea = Rect2(0, 0, WIDTH, HEIGHT)
	set_next_spawn()

func spawn_enemy():
	var spawn_pos = Vector2(randi() % WIDTH, randi() % HEIGHT)
	var spawn_anim = SPAWNING_ENEMY.instantiate()
	spawn_anim.position = spawn_pos
	get_parent().add_child(spawn_anim)

func set_next_spawn():
	var nextTime = delta + (randf() - 0.5) * 2 * offset
	nextTime = clamp(nextTime, 0.1, 5.0)  # per sicurezza
	$Timer.wait_time = nextTime
	$Timer.start()
	
func _on_timer_timeout():
	spawn_enemy()
	set_next_spawn()

# Aggiorna velocità di spawn in base al tempo di gioco (Totale 90 sec)
func update_spawn_speed(current_time: int) -> void:
	
	# Da 0 a 30 secondi (Fase Facile / Principianti)
	if current_time <= 30:
		var progress: float = current_time / 30.0
		# Scende dolcemente da 2.5 a 1.5 secondi tra uno spawn e l'altro
		delta = lerp(2.5, 1.5, progress)
		
	# Da 30 a 60 secondi (Fase Media)
	elif current_time <= 60:
		var progress: float = (current_time - 30) / 30.0
		# Scende da 1.5 a 0.8 secondi (inizia a farsi affollato)
		delta = lerp(1.5, 0.8, progress)
		
	# Da 60 a 90 secondi (Fase Difficile / Sopravvivenza finale)
	elif current_time <= 90:
		var progress: float = (current_time - 60) / 30.0
		# Scende da 0.8 a 0.35 secondi
		delta = lerp(0.8, 0.35, progress)
		
	# Oltre i 90 secondi
	else:
		delta = 0.35
