extends CharacterBody2D

signal died

# Componenti
@onready var healthbar = $HealtBar

@onready var Shooty_part = $ShootyPart
@onready var Shooty_part2 = $ShootyPart2
@onready var Shooty_part3 = $ShootyPart3
var player: Node2D = null

# Parametri UFO
const SPEED = 300.0 # Velocità di inseguimento dell'orbita
const SHOOT_INTERVAL = 2.0
var health: int = 10

# Parametri Movimento Circolare
var orbit_radius: float = 350.0  # Raggio medio (distanza dal player)
var rotation_speed: float = 1.0  # Velocità di rotazione in radianti al secondo
var current_angle: float = 0.0

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
		# Calcola l'angolo iniziale basato sulla posizione di spawn
		# così non "scatta" a zero quando appare
		current_angle = (global_position - player.global_position).angle()

	# Timer sparo
	shoot_timer = Timer.new()
	shoot_timer.wait_time = SHOOT_INTERVAL
	shoot_timer.one_shot = false
	shoot_timer.autostart = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timeout)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# 1. Aggiorna l'angolo di rotazione
	current_angle += rotation_speed * delta
	
	# 2. Calcola la posizione target sul cerchio attorno al player
	# Formula: Centro + Vettore(cos, sin) * Raggio
	var offset = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	var target_position = player.global_position + offset
	
	# 3. Muovi il nemico verso quella posizione target
	# Usiamo velocity per mantenere la fisica corretta (collisioni etc.)
	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)
	
	# Se siamo lontani dal punto dell'orbita, andiamo veloci, se siamo vicini rallentiamo (effetto fluido)
	if distance > 10.0:
		velocity = direction * SPEED
	else:
		velocity = direction * distance # Rallenta quando arriva in posizione perfetta
	
	move_and_slide()
	
	# 4. Guarda sempre verso il player (per sparare giusto)
	look_at(player.global_position)

func _on_shoot_timeout():
	if player == null:
		return
	spawn_bullet(Shooty_part)
	spawn_bullet(Shooty_part2)
	spawn_bullet(Shooty_part3)

func spawn_bullet(part: Node2D):
	var bullet = BulletScene.instantiate()
	bullet.global_position = part.global_position
	# Usa transform.x perché il nemico sta già guardando il player grazie a look_at() nel process
	bullet.direction = transform.x.normalized() 
	
	# bullet.shooter = self 
	
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
	
	GameData.aggiungi_kill("purple_devil") # Aggiunto
	
	queue_free()
