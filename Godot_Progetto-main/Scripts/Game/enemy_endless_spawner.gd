extends Node2D

const ENEMY_SCENE = preload("res://scenes/Spaceships/Enemies/Ninja.tscn")
const SCREEN_WIDTH = 1152
const SCREEN_HEIGHT = 648

func _ready() -> void:
	randomize()
	$Timer.start()

func _on_timer_timeout():
	var enemy = ENEMY_SCENE.instantiate()
	enemy.global_position = spawn_outside_screen()
	enemy.target_position = get_opposite_position(enemy.global_position)
	add_child(enemy)

func spawn_outside_screen() -> Vector2:
	var pos = Vector2()
	var side = randi() % 4

	match side:
		0:
			pos.x = -50
			pos.y = randf() * SCREEN_HEIGHT
		1:
			pos.x = SCREEN_WIDTH + 50
			pos.y = randf() * SCREEN_HEIGHT
		2:
			pos.x = randf() * SCREEN_WIDTH
			pos.y = -50
		3:
			pos.x = randf() * SCREEN_WIDTH
			pos.y = SCREEN_HEIGHT + 50

	return pos

func get_opposite_position(pos: Vector2) -> Vector2:
	var opposite = Vector2()

	if pos.x < 0:
		opposite.x = SCREEN_WIDTH + 50
		opposite.y = randf() * SCREEN_HEIGHT
	elif pos.x > SCREEN_WIDTH:
		opposite.x = -50
		opposite.y = randf() * SCREEN_HEIGHT
	elif pos.y < 0:
		opposite.x = randf() * SCREEN_WIDTH
		opposite.y = SCREEN_HEIGHT + 50
	elif pos.y > SCREEN_HEIGHT:
		opposite.x = randf() * SCREEN_WIDTH
		opposite.y = -50

	return opposite
