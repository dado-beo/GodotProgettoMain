extends CharacterBody2D

var explosion_radius : float = 65.0 # Raggio dell'esplosione 
@export var explosion_damage: int = 3       # Danno causato dall'esplosione

@onready var healthbar = $HealtBar
var player: Node2D = null

var health: int = 6
var is_exploding: bool = false 
var random_offset: float = 0.0 # Rende ogni kamikaze unico

# --- VARIABILI MOVIMENTO ---
@export var speed: float = 350.0        # Velocità di base
@export var turn_speed: float = 4.0     # Quanto velocemente riescono a curvare (più è basso, più "giri" fanno)
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
		
	# 1. Calcola l'angolo diretto verso il giocatore
	var direction_to_player = global_position.direction_to(player.global_position)
	var target_angle = direction_to_player.angle()
	
	# 2. Aggiunge una curva a zig-zag basata sul tempo per renderli imprevedibili
	var time = Time.get_ticks_msec() / 1000.0
	var wobble = sin(time * wobble_speed + random_offset) * wobble_amplitude
	target_angle += wobble 
	
	# 3. Gira il nemico in modo fluido verso il bersaglio (invece di "scattare" all'istante)
	rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
	
	# 4. Muoviti in avanti rispetto a dove sta guardando ora
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	move_and_slide()
	
	# Controllo collisioni (uguale a prima)
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
		# Se il nodo radice della scena è direttamente il CPUParticles2D
		explosion.emitting = true
	elif explosion.has_node("CPUParticles2D"):
		# Se il CPUParticles2D è un nodo figlio all'interno della scena
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
