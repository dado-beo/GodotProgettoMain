extends Node2D

const WIDTH = 1152
const HEIGHT = 648
const SPAWNING_ENEMY = preload("res://scenes/Game/spawning_enemy.tscn")

var spawnArea = Rect2()
var delta := 2.0
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

# Aggiorna velocità di spawn in base al tempo di gioco
func update_spawn_speed(current_time: int) -> void:
	# Da 0 a 60 secondi: scende gradualmente da 2.0 a 1.5
	if current_time < 60:
		var progress: float = current_time / 60.0
		delta = lerp(2.5, 2.0, progress)
		
	# Da 60 a 90 secondi: scende gradualmente da 1.5 a 1.0
	elif current_time < 90:
		var progress: float = (current_time - 60) / 30.0
		delta = lerp(2.0, 1.5, progress)
		
	# Da 90 a 120 secondi: scende gradualmente da 1.0 a 0.75
	elif current_time < 120:
		var progress: float = (current_time - 90) / 30.0
		delta = lerp(1.5, 1.0, progress)
		
	# Da 120 a 150 secondi: scende gradualmente da 0.75 a 0.5
	elif current_time < 150:
		var progress: float = (current_time - 120) / 30.0
		delta = lerp(1.0, 0.75, progress)
		
	# Dopo 150 secondi (2.5 minuti) la velocità si ferma a 0.5
	else:
		delta = 0.5
