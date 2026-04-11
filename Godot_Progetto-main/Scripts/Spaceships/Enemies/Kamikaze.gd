extends CharacterBody2D
signal kamikazeDeath

var explosion_radius : float = 50.0 # Raggio dell'esplosione 
@export var explosion_damage: int = 3       # Danno causato dall'esplosione

@onready var healthbar = $HealtBar
var player: Node2D = null

var health: int = 6
var is_exploding: bool = false 
var random_offset: float = 0.0 # Rende ogni kamikaze unico

# --- VARIABILI MOVIMENTO ---
@export var speed: float = 400        # Velocità di base (iniziale)
@export var max_speed: float = 600.0  # NUOVO: Velocità massima 
@export var acceleration: float = 10.0 # NUOVO: Di quanto aumenta la velocità ogni secondo
@export var turn_speed: float = 4.0     # Quanto velocemente riescono a curvare
@export var wobble_speed: float = 8.0   # La velocità con cui serpeggiano
@export var wobble_amplitude: float = 0.5 # L'ampiezza delle curve a zig-zag

func _ready():
	add_to_group("enemies")
	healthbar.init_healt(health)
	
	# Diamo un offset casuale a ogni nemico così non si muovono tutti in perfetta sincronia
	random_offset = randf() * 100.0

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if player == null or is_exploding:
		return
		
	# Calcoliamo subito la distanza dal giocatore
	var distance_to_player = global_position.distance_to(player.global_position)
		
	# 1. Calcola l'angolo diretto verso il giocatore
	var direction_to_player = global_position.direction_to(player.global_position)
	var target_angle = direction_to_player.angle()
	
	# 2. Aggiunge il wobble SOLO se è abbastanza lontano dal giocatore
	if distance_to_player > 150.0:
		var time = Time.get_ticks_msec() / 1000.0
		var wobble = sin(time * wobble_speed + random_offset) * wobble_amplitude
		target_angle += wobble 
	
	# 3. Gira il nemico. Se è vicino, aumenta molto la velocità di virata per non "orbitare"
	var current_turn_speed = turn_speed
	if distance_to_player < 150.0:
		current_turn_speed = turn_speed * 4.0 # Gira 4 volte più velocemente da vicino!
		
	rotation = lerp_angle(rotation, target_angle, current_turn_speed * delta)
	
	# 4. Aumenta la velocità progressivamente
	if speed < max_speed:
		speed += acceleration * delta
	
	# 5. Muoviti in avanti rispetto a dove sta guardando ora
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	move_and_slide()
	
	# --- NUOVO: 6. INNESCO DI PROSSIMITÀ ---
	# Se è vicinissimo al player, esplode a prescindere dalla collisione fisica
	if distance_to_player < 40.0:
		trigger_explosion()
		return
	
	# Controllo collisioni classico
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("player"):
			trigger_explosion()
			break

# Funzione per gestire il danno
func take_damage(amount: int) -> void:
	if is_exploding: 
		return # Evita di prendere danni se sta già esplodendo
		
	health -= amount
	healthbar.health = health
	if health <= 0:
		kamikazeDeath.emit()
		GameData.aggiungi_kill("kamikaze") # Aggiunge la kill se lo uccidiamo con i proiettili
		trigger_explosion()

# Gestisce la visuale dell'esplosione e i danni ad area
func trigger_explosion() -> void: 	
	if is_exploding:
		return
	is_exploding = true
	
	# Fermiamo e nascondiamo il Kamikaze
	set_physics_process(false) 
	$AnimatedSprite2D.visible = false 
	$CollisionShape2D.set_deferred("disabled", true) 
	healthbar.visible = false 
	
	# 1. Istanzia le particelle dell'esplosione
	var explosion = preload("res://scenes/AnimationAddOn/Explosion.tscn").instantiate() 	
	get_parent().add_child(explosion) 	
	explosion.global_position = global_position 	 	
	
	# -- SOLUZIONE PER CPUParticles2D --
	if explosion is CPUParticles2D:
		explosion.emitting = true
	elif explosion.has_node("CPUParticles2D"):
		explosion.get_node("CPUParticles2D").emitting = true
	
	# 2. Infliggi danno ad area al GIOCATORE
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.global_position.distance_to(global_position) <= explosion_radius:
			if p.has_method("take_damage"):
				p.take_damage(explosion_damage)
				
	# 3. Infliggi danno ad area agli ALTRI NEMICI (Reazione a catena!)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and enemy.global_position.distance_to(global_position) <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(explosion_damage)
	
	# Aspettiamo 1 secondo per sicurezza prima di rimuovere il Kamikaze nascosto
	await get_tree().create_timer(1.0).timeout
	queue_free()
