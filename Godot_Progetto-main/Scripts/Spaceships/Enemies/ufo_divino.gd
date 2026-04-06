extends CharacterBody2D

signal died

# Componenti
@onready var healthbar = $HealtBar
var player: Node2D = null

# Parametri Base
const SPEED = 350
const SHOOT_INTERVAL = 0.6
var health: int = 18

# --- NUOVO: Stati di Movimento ---
enum State { WAVY, CIRCLING }
var current_state = State.WAVY

# Variabili per Onda (Wavy)
var time_passed: float = 0.0
const WAVE_FREQ: float = 5.0 # Velocità dell'oscillazione dell'onda
const WAVE_AMP: float = 140.0 # Ampiezza dell'onda (quanto va a destra/sinistra)

# Variabili per Cerchio (Circling)
var circle_timer: float = 0.0
const CIRCLE_SPEED: float = 200.0
const CIRCLE_ROT_SPEED: float = 5.0 # Radianti al sec (velocità del giro della morte)

var velocity_dir: Vector2 = Vector2.ZERO
var change_dir_timer: Timer
var shoot_timer: Timer

# Proiettili e FX
var BulletScene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Ufo.tscn")
var ExplosionScene = preload("res://scenes/AnimationAddOn/Explosion.tscn")

func _ready():
	add_to_group("enemies")
	healthbar.init_healt(health)

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	change_dir_timer = Timer.new()
	change_dir_timer.one_shot = true
	add_child(change_dir_timer)
	change_dir_timer.timeout.connect(_on_change_dir_timeout)
	_start_new_change_timer()

	shoot_timer = Timer.new()
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timeout)

	_set_random_direction()

func _physics_process(delta: float) -> void:
	time_passed += delta

	if current_state == State.WAVY:
		# 1. MOVIMENTO ONDULATORIO (Sinusoide morbida)
		# Calcoliamo una direzione perpendicolare a dove sta andando
		var perpendicular_dir = Vector2(-velocity_dir.y, velocity_dir.x)
		
		# Creiamo l'onda moltiplicando per il seno del tempo
		var wave_offset = perpendicular_dir * sin(time_passed * WAVE_FREQ) * WAVE_AMP
		
		# Sommiamo la direzione frontale con lo scostamento laterale
		velocity = (velocity_dir * SPEED) + wave_offset
		look_at(global_position + velocity_dir) # Continua a guardare in avanti

	elif current_state == State.CIRCLING:
		# 2. MOVIMENTO CIRCOLARE (Giro della morte)
		rotation += CIRCLE_ROT_SPEED * delta
		velocity = Vector2.RIGHT.rotated(rotation) * CIRCLE_SPEED
		
		circle_timer -= delta
		if circle_timer <= 0:
			# Finito il giro, torna a fare l'onda uscendo nella direzione verso cui punta ora
			current_state = State.WAVY
			velocity_dir = Vector2.RIGHT.rotated(rotation)
			_start_new_change_timer()

	move_and_slide()
	
	# 3. RIMBALZO SUI MURI
	_handle_wall_bounce()

func _handle_wall_bounce():
	# Controlla se move_and_slide ha sbattuto contro i nodi "Walls"
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var normal = collision.get_normal()
		
		# Rimbalzo base (effetto flipper)
		velocity_dir = velocity_dir.bounce(normal)
		
		# Aggiunge un angolo di deviazione randomico tra -45° e +45° per essere imprevedibile
		var random_angle = randf_range(-PI/4, PI/4)
		velocity_dir = velocity_dir.rotated(random_angle).normalized()
		
		# Se sbatte mentre fa il cerchio, lo stoppiamo e lo facciamo fuggire
		if current_state == State.CIRCLING:
			current_state = State.WAVY
			_start_new_change_timer()
			
		look_at(global_position + velocity_dir)

func _on_change_dir_timeout():
	# Il 30% delle volte decide di fare un cerchio sul posto
	if randf() <= 0.30:
		current_state = State.CIRCLING
		circle_timer = randf_range(1.0, 2.0) # Gira su se stesso tra 1 e 2 secondi
	else:
		# Il 70% delle volte ricalcola semplicemente una direzione verso il player (o a caso)
		current_state = State.WAVY
		_set_random_direction()
		_start_new_change_timer()

func _start_new_change_timer():
	change_dir_timer.wait_time = randf_range(2.0, 4.0)
	change_dir_timer.start()

func _set_random_direction():
	if player != null:
		var dir_to_player = (player.global_position - global_position).normalized()
		var angle_offset = randf_range(-PI/4, PI/4)
		velocity_dir = dir_to_player.rotated(angle_offset)
	else:
		var angle = randf() * TAU
		velocity_dir = Vector2(cos(angle), sin(angle))

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
	GameData.aggiungi_kill("ufo")
	queue_free()
