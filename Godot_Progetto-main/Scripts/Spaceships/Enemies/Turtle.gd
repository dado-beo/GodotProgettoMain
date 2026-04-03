extends CharacterBody2D

# --------------------
# Health bar
@onready var healthbar = $HealthBar
var health: int = 12

# --------------------
# Movimento e sparo
var player: Node2D = null
const SPEED = 75
const FIRE_RATE = 1.5
var time_since_last_shot := 0.0

# Proiettile
var bullet_scene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Turtle.tscn")

# --------------------
func _ready():
	# Aggiungi al gruppo "enemies" per il proiettile
	if not is_in_group("enemies"):
		add_to_group("enemies")

	# Trova il giocatore
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# Inizializza health bar
	if healthbar != null:
		healthbar.init_healt(health)
	else:
		push_error("HealthBar non trovata!")

# --------------------
func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Movimento verso il giocatore
	velocity = (player.global_position - global_position).normalized() * SPEED
	look_at(player.global_position)
	move_and_slide()

	# Sparo automatico
	time_since_last_shot += delta
	if time_since_last_shot >= FIRE_RATE:
		fire()
		time_since_last_shot = 0.0

# --------------------
func fire():
	if player == null:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	get_tree().get_current_scene().add_child(bullet)

# --------------------
func take_damage(amount: int) -> void:
	print("TurtleEnemy prende danno:", amount)
	health -= amount
	if healthbar != null:
		healthbar.health = health
	if health <= 0:
		die()

# --------------------
func die() -> void:
	# Istanzia esplosione
	var explosion = preload("res://scenes/AnimationAddOn/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.emitting = true
	get_parent().add_child(explosion)

	GameData.aggiungi_kill("tartaruga") # Aggiunto

	queue_free()
