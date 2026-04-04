extends Node2D

const ENEMY_SCENE = preload("res://scenes/Spaceships/Enemies/Turtle.tscn")
const SCREEN_WIDTH = 1152
const SCREEN_HEIGHT = 648
const SPAWN_INTERVAL = 5.0 # ogni 5 secondi

func _ready():
	randomize()
	$Timer.wait_time = SPAWN_INTERVAL
	$Timer.autostart = true
	$Timer.one_shot = false
	$Timer.start()

func _on_timer_timeout():
	var enemy = ENEMY_SCENE.instantiate()
	enemy.global_position = spawn_outside_screen()
	add_child(enemy)
	print("Spawnato TurtleEnemy") # debug

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
