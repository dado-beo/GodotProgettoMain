extends CharacterBody2D

signal died

# Componenti
@onready var healthbar = $HealtBar
var player: Node2D = null

# Parametri UFO
const SPEED = 250
const SHOOT_INTERVAL = 2.0
var health: int = 6

var velocity_dir: Vector2 = Vector2.ZERO
var change_dir_timer: Timer
var shoot_timer: Timer

# Proiettile UFO
var BulletScene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Ufo.tscn")
var ExplosionScene = preload("res://scenes/AnimationAddOn/Explosion.tscn")

func _ready():
	add_to_group("enemies")
	healthbar.init_healt(health)

	# Trova il player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Timer cambio direzione
	change_dir_timer = Timer.new()
	change_dir_timer.one_shot = true
	add_child(change_dir_timer)
	change_dir_timer.timeout.connect(_on_change_dir_timeout)
	_start_new_change_timer()

	# Timer sparo
	shoot_timer = Timer.new()
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timeout)

	# Direzione iniziale
	_set_random_direction()

func _physics_process(delta: float) -> void:
	velocity = velocity_dir * SPEED
	move_and_slide()

func _on_change_dir_timeout():
	_set_random_direction()
	_start_new_change_timer()

func _start_new_change_timer():
	change_dir_timer.wait_time = randf_range(2.0, 5.0)
	change_dir_timer.start()

func _set_random_direction():
	if player != null:
		var dir_to_player = (player.global_position - global_position).normalized()
		var angle_offset = randf_range(-PI/4, PI/4) # ±45°
		velocity_dir = dir_to_player.rotated(angle_offset)
	else:
		var angle = randf() * TAU
		velocity_dir = Vector2(cos(angle), sin(angle))

	look_at(global_position + velocity_dir)

func _on_shoot_timeout():
	if player == null:
		return
	var bullet = BulletScene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	health -= amount
	healthbar.health = health
	if health <= 0:
		die()

func die() -> void:
	var explosion = ExplosionScene.instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

	emit_signal("died")
	
	GameData.aggiungi_kill("ufo") # Aggiunge
	
	queue_free()
