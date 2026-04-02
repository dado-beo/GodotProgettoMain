extends CharacterBody2D

# ==========================================
# COSTANTI
# ==========================================
const BASE_SPEED: float = 420.0  # Base aumentata per maggiore fluidità
const EXTRA_SPEED: float = 100.0
const FIRE_RATE: float = 0.3     # Tempo tra uno sparo e l'altro in secondi
const CHARGE_DELAY: float = 0.30 # Tempo per distinguere un "click" da un "tieni premuto"

# ==========================================
# VARIABILI ESPORTATE (Modificabili dall'Inspector)
# ==========================================
@export_group("Dash Settings")
@export var max_dash_distance: float = 600.0
@export var max_cooldown: float = 5.0
@export var dash_damage: int = 6
@export var cooldown_reduction_per_kill: float = 1.0 

@export_group("Juice Settings")
@export var ghost_count: int = 5            # Quanti "fantasmi" lasciare
@export var ghost_fade_time: float = 0.3    # Quanto tempo impiegano a sparire

# ==========================================
# VARIABILI DI STATO
# ==========================================
var health: int = 12
var time_since_last_shot: float = 0.0
var is_charging: bool = false
var dash_vector: Vector2 = Vector2.ZERO
var time_tween: Tween
var charge_timer: float = 0.0
var is_preparing_charge: bool = false

# Variabile per l'achievement
var primo_colpo_effettuato: bool = false

# Caricamento della scena del proiettile
var bullet_scene: PackedScene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")

# ==========================================
# NODI (Onready)
# ==========================================
@onready var healthbar = $HealtBar
@onready var trajectory_line: Line2D = $Line2D
@onready var cooldown_timer: Timer = $Timer
@onready var dash_cast: ShapeCast2D = $DashCast
@onready var shooty_part: Node2D = $ShootyPart
@onready var shooty_part2: Node2D = $ShootyPart2
@onready var shooty_part3: Node2D = $ShootyPart3
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var dash_ui: TextureProgressBar = $DashCooldownUI

# ==========================================
# FUNZIONI DI SISTEMA GODOT
# ==========================================
func _ready() -> void:
	add_to_group("player")
	process_mode = Node.PROCESS_MODE_ALWAYS
	trajectory_line.visible = false
	healthbar.init_healt(health)
	dash_particles.emitting = false

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())

	var input_vector = Input.get_vector("left", "right", "up", "down")
	var speed = BASE_SPEED
	
	# OTTIMIZZAZIONE: Accesso sicuro al dizionario GameData
	if GameData.upgrades["speed_boost"]["enabled"]:
		speed += EXTRA_SPEED

	velocity = velocity.lerp(input_vector * speed, 0.1)
	move_and_slide()

func _process(delta: float) -> void:
	# Verifichiamo una volta sola se l'upgrade è attivo (più leggero per la CPU)
	var can_dash = GameData.upgrades["speed_boost"]["enabled"]
	
	# Gestione visibilità UI in base all'upgrade
	dash_ui.visible = can_dash

	# 1. INPUT APPENA PREMUTO (Sparo Istantaneo Sempre Attivo)
	if Input.is_action_just_pressed("shoot"):
		fire() 
		
		# Inizia la fase di preparazione al Dash SOLO se l'upgrade è abilitato e il timer è pronto
		if can_dash and cooldown_timer.is_stopped():
			is_preparing_charge = true
			charge_timer = 0.0

	# ==========================================
	# LOGICA DASH (Protetta dall'Upgrade)
	# ==========================================
	if can_dash:
		# 2. GESTIONE DEL "TENERE PREMUTO"
		if Input.is_action_pressed("shoot") and is_preparing_charge:
			charge_timer += delta
			
			if charge_timer >= CHARGE_DELAY and not is_charging:
				start_charging()

		# 3. AGGIORNAMENTO TRAIETTORIA
		if is_charging:
			update_charging()
			
		# 4. RILASCIO DEL TASTO (Esecuzione)
		if Input.is_action_just_released("shoot"):
			if is_charging:
				execute_dash()
			
			is_preparing_charge = false
			is_charging = false
			charge_timer = 0.0
			
		# 5. AGGIORNAMENTO UI COOLDOWN
		if not cooldown_timer.is_stopped():
			# In Ricarica
			dash_ui.max_value = cooldown_timer.wait_time
			dash_ui.value = cooldown_timer.wait_time - cooldown_timer.time_left
			# BUG FIX: Colore grigio scuro durante la ricarica
			dash_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
		else:
			# Pronto all'uso
			dash_ui.max_value = 1.0
			dash_ui.value = 1.0 
			# BUG FIX: Colore azzurro brillante quando è pronto
			dash_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
			
	else:
		# Reset di sicurezza se l'upgrade viene disattivato
		is_preparing_charge = false
		is_charging = false

# ==========================================
# SISTEMA DI ARMI
# ==========================================
func fire() -> void:
	# --- ACHIEVEMENT PRIMO COLPO ---
	if not primo_colpo_effettuato:
		primo_colpo_effettuato = true
		if GameData.has_method("sblocca_obiettivo"):
			# NOTA: Cambia "primo_sparo" con l'ID esatto del tuo obiettivo se è diverso!
			GameData.sblocca_obiettivo("primo_sparo")
	# -------------------------------

	spawn_bullet(shooty_part)

	# OTTIMIZZAZIONE: Accesso sicuro al dizionario GameData
	if GameData.upgrades["triple_shot"]["enabled"]:
		spawn_bullet(shooty_part2)
		spawn_bullet(shooty_part3)

func spawn_bullet(part: Node2D) -> void:
	if part == null: 
		return
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = part.global_position
	bullet.rotation = rotation
	
	if "direction" in bullet:
		bullet.direction = Vector2.RIGHT.rotated(rotation)
		
	get_tree().current_scene.add_child(bullet)

# ==========================================
# SISTEMA DASH (Scatto e Bullet Time)
# ==========================================
func start_charging() -> void:
	is_charging = true
	trajectory_line.visible = true
	
	modulate = Color(2, 2, 2) 
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	
	if time_tween:
		time_tween.kill()
		
	time_tween = create_tween()
	time_tween.tween_property(Engine, "time_scale", 0.05, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func update_charging() -> void:
	var desired_vector = get_global_mouse_position() - global_position
	dash_vector = desired_vector.limit_length(max_dash_distance)
	
	trajectory_line.clear_points()
	trajectory_line.add_point(Vector2.ZERO)
	trajectory_line.add_point(to_local(global_position + dash_vector))

func execute_dash() -> void:
	is_charging = false
	trajectory_line.visible = false
	start_iframes()
	if time_tween:
		time_tween.kill()
	Engine.time_scale = 1.0
	
	# ... (codice precedente di execute_dash) ...
	dash_particles.emitting = true
	spawn_ghost_trail()
	
	# ==========================================
	# FIX: RILEVAMENTO MULTIPLO (Raggio Perforante)
	# ==========================================
	dash_cast.target_position = to_local(global_position + dash_vector)
	dash_cast.clear_exceptions() # Svuota la memoria dei nemici ignorati dal dash precedente
	dash_cast.force_shapecast_update()

	var enemies_killed: int = 0
	var fail_safe: int = 0 # Previene cicli infiniti se qualcosa va storto

	# Finché il raggio sbatte contro qualcosa (e non superiamo i 50 cicli di sicurezza)
	while dash_cast.is_colliding() and fail_safe < 50:
		fail_safe += 1
		
		# Controlliamo cosa ha colpito in questo punto
		for i in range(dash_cast.get_collision_count()):
			var collider = dash_cast.get_collider(i)
			
			if collider.has_method("take_damage"):
				if collider.take_damage(dash_damage):
					enemies_killed += 1
					
			# LA MAGIA: Diciamo al radar di "diventare fantasma" per questo specifico oggetto
			dash_cast.add_exception(collider)
			
		# Aggiorniamo il radar: ora trapasserà i nemici che abbiamo appena inserito nelle eccezioni
		dash_cast.force_shapecast_update()
	# ==========================================
				
	# Gestione Cooldown
	var distance_ratio = dash_vector.length() / max_dash_distance
	# ... (il resto del codice rimane identico) ...
	var base_cooldown = max(0.5, max_cooldown * distance_ratio)
	var final_cooldown = max(0.1, base_cooldown - (enemies_killed * cooldown_reduction_per_kill))
	cooldown_timer.start(final_cooldown)

	# Spostamento navicella
	var move_tween = create_tween()
	move_tween.tween_property(self, "global_position", global_position + dash_vector, 0.05)
	move_tween.tween_callback(func(): dash_particles.emitting = false)

# ==========================================
# FUNZIONI JUICE SPECIFICHE
# ==========================================
func start_iframes() -> void:
	# 1. DISATTIVA IL LAYER (Bit 1: "Io sono il Player")
	# In questo modo i nemici non sanno più che esisti
	set_collision_layer_value(1, false) 
	
	# 2. DISATTIVA LA MASK (Bit 2: "Vedo i nemici")
	# In questo modo non calcoli collisioni fisiche con loro
	set_collision_mask_value(2, false) 

	# Juice: Lampeggio
	var blink_tween = create_tween().set_loops(3)
	blink_tween.tween_property(self, "modulate:a", 0.2, 0.05)
	blink_tween.tween_property(self, "modulate:a", 1.0, 0.05)

	# Durata dell'invulnerabilità (leggermente più lunga del dash)
	await get_tree().create_timer(0.4).timeout

	if blink_tween.is_valid():
		blink_tween.kill() 
		
	# 3. RIPRISTINA TUTTO
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	modulate.a = 1.0

func spawn_ghost_trail() -> void:
	for i in range(ghost_count):
		var percent = float(i + 1) / float(ghost_count + 1)
		var ghost_pos = global_position + (dash_vector * percent)

		var ghost = Sprite2D.new()
		var current_anim = animated_sprite.animation
		var current_frame = animated_sprite.frame
		
		ghost.texture = animated_sprite.sprite_frames.get_frame_texture(current_anim, current_frame)
		ghost.global_position = ghost_pos
		ghost.rotation = rotation               
		ghost.scale = animated_sprite.scale     
		ghost.modulate = Color(0.5, 0.8, 1, 0.6) 

		get_tree().current_scene.add_child(ghost)

		var ghost_tween = create_tween()
		ghost_tween.tween_property(ghost, "modulate:a", 0.0, ghost_fade_time).set_trans(Tween.TRANS_SINE)
		ghost_tween.tween_callback(ghost.queue_free)

# ==========================================
# SISTEMA VITA E DANNI
# ==========================================
func take_damage(amount: int) -> void:
	health -= amount
	healthbar.health = health 
	if health <= 0:
		die()

func die() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu/Main_Menu.tscn")
