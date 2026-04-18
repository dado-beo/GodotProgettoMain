extends CharacterBody2D

signal died

# Componenti
@onready var healthbar = $HealtBar
@onready var Shooty_part = $ShootyPart
@onready var Shooty_part2 = $ShootyPart2
@onready var Shooty_part3 = $ShootyPart3
var player: Node2D = null

# Parametri Devil
const SPEED = 400.0 
const SHOOT_INTERVAL = 1.0
var health: int = 16

# --- MOVIMENTO
var base_orbit_radius: float = 350.0 
var orbit_oscillation: float = 150.0 # Quanto si avvicina/allontana (Oscilla tra 200 e 500)
var oscillation_speed: float = 2.5   # Velocità di "pulsazione" verso il giocatore

var rotation_speed: float = 1.5      # Velocità base di rotazione
var current_direction: int = 1       # 1 = orario, -1 = antiorario
var current_angle: float = 0.0

var time_alive: float = 0.0          # Tiene traccia del tempo per le funzioni matematiche
var change_dir_timer: Timer          # Timer per invertire la rotta

var shoot_timer: Timer

# Proiettile UFO
var BulletScene = preload("res://scenes/Bullets/Enemies/Bullet_Purple_Devil.tscn")
var ExplosionScene = preload("res://scenes/AnimationAddOn/Explosion.tscn")

func _ready():
	add_to_group("enemies")
	healthbar.init_healt(health)

	# Trova il player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		current_angle = (global_position - player.global_position).angle()

	# Timer sparo
	shoot_timer = Timer.new()
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.autostart = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timeout)
	
	# Timer Inversione di rotta (Ogni 1.5 - 3.5 secondi cambia giro)
	change_dir_timer = Timer.new()
	change_dir_timer.autostart = true
	add_child(change_dir_timer)
	change_dir_timer.timeout.connect(_on_change_direction)
	_reset_direction_timer()

# Funzione per cambiare direzione a caso
func _on_change_direction():
	current_direction *= -1 # Inverte (se era 1 diventa -1 e viceversa)
	_reset_direction_timer()

func _reset_direction_timer():
	change_dir_timer.wait_time = randf_range(1.5, 3.5)
	change_dir_timer.start()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	time_alive += delta

	# 1. Aggiorna l'angolo (con la direzione variabile)
	current_angle += (rotation_speed * current_direction) * delta
	
	# 2. CALCOLA IL RAGGIO DINAMICO
	# Usiamo sin() per farlo avvicinare e allontanare costantemente.
	var dynamic_radius = base_orbit_radius + (sin(time_alive * oscillation_speed) * orbit_oscillation)
	
	# 3. Posizione target
	var offset = Vector2(cos(current_angle), sin(current_angle)) * dynamic_radius
	var target_position = player.global_position + offset
	
	# 4. Muovi il nemico
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	# Scatta veloce verso il punto, dando un feeling molto reattivo
	if distance > 15.0:
		velocity = velocity.lerp(direction * SPEED, 5.0 * delta)
	else:
		velocity = direction * (distance * 10.0) # Rallenta dolcemente
	
	move_and_slide()
	
	# 5. Guarda sempre verso il player
	look_at(player.global_position)

func _on_shoot_timeout():
	if player == null:
		return
	spawn_bullet(Shooty_part)
	spawn_bullet(Shooty_part2)
	spawn_bullet(Shooty_part3)

func spawn_bullet(part: Node2D):
	$AudioStreamPlayer2D.play()
	var bullet = BulletScene.instantiate()
	bullet.global_position = part.global_position
	bullet.direction = transform.x.normalized() 
	get_tree().get_current_scene().add_child(bullet)
	
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
	GameData.aggiungi_kill("purple_devil")
	queue_free()
