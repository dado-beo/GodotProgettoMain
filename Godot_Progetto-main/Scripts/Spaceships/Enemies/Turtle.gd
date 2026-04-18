extends CharacterBody2D

# Health bar
@onready var healthbar = $HealthBar
var health: int = 18

# Movimento e sparo
var player: Node2D = null
const SPEED = 75
const FIRE_RATE = 2.0 
var time_since_last_shot := 0.0

var is_shooting := false # Questa variabile gestisce lo stato "Carro armato fermo"

var bullet_scene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Turtle.tscn")

func _ready():
	if not is_in_group("enemies"):
		add_to_group("enemies")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	if healthbar != null:
		healthbar.init_healt(health)
	else:
		push_error("HealthBar non trovata!")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# --- FIX bug SGUARDO ---
	# La tartaruga deve guardare il giocatore SEMPRE, sia quando si muove che quando spara
	look_at(player.global_position)

	# Se sta sparando, frena e si ferma
	if is_shooting:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	else:
		# Se non sta sparando, avanza verso il giocatore
		velocity = (player.global_position - global_position).normalized() * SPEED
		
	move_and_slide()

	# Gestione timer sparo
	time_since_last_shot += delta
	if time_since_last_shot >= FIRE_RATE and not is_shooting:
		start_firing_sequence()
		time_since_last_shot = 0.0


# Gestisce la sequenza di carica e sparo
func start_firing_sequence():
	is_shooting = true
	
	# 1. CARICA IL COLPO: Aspetta mezzo secondo per caricare il colpo pesante
	await get_tree().create_timer(0.5).timeout
	
	# Controllo di sicurezza nel caso la tartaruga muoia mentre caricava il colpo
	if player == null or not is_instance_valid(self): return 
	
	fire_spread() # 2. SPARA a ventaglio
	
	# 3. RINCULO/RICARICA: Pausa dopo lo sparo prima di ricominciare a muoversi
	await get_tree().create_timer(0.5).timeout
	
	is_shooting = false

# --------------------
func fire_spread():
	if player == null:
		return
	$AudioStreamPlayer2D.play()
	var base_direction = (player.global_position - global_position).normalized()
	
	# Angoli per i 3 proiettili (circa -15°, 0°, +15° espressi in radianti)
	var spread_angles = [-0.25, 0.0, 0.25] 
	
	for angle in spread_angles:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		# Ruota la direzione di base per creare l'effetto a ventaglio
		bullet.direction = base_direction.rotated(angle)
		get_tree().get_current_scene().add_child(bullet)

# --------------------
func take_damage(amount: int) -> void:
	health -= amount
	if healthbar != null:
		healthbar.health = health
	if health <= 0:
		die()

# --------------------
func die() -> void:
	var explosion = preload("res://scenes/AnimationAddOn/Explosion.tscn").instantiate()
	explosion.global_position = global_position
	
	if explosion is CPUParticles2D:
		explosion.emitting = true
	elif explosion.has_node("CPUParticles2D"):
		explosion.get_node("CPUParticles2D").emitting = true
		
	get_parent().add_child(explosion)

	GameData.aggiungi_kill("tartaruga")

	queue_free()
