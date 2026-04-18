extends CharacterBody2D
signal preso_danno
signal died

# ==========================================
# COSTANTI E MODIFICATORI DI VELOCITÀ
# ==========================================
const BASE_SPEED: float = 500.0
const EXTRA_SPEED: float = 100.0
const FIRE_RATE: float = 0.5    
const CHARGE_DELAY: float = 0.0 
var speed_multiplier: float = 1.0 # 1.0 = velocità normale, 0.5 = rallentato della metà

# ==========================================
# VARIABILI ESPORTATE
# ==========================================
@export_group("Dash Settings")
@export var max_dash_distance: float = 600.0
@export var max_cooldown: float = 5.0
@export var dash_damage: int = 6
@export var cooldown_reduction_per_kill: float = 1.0 

@export_group("Juice Settings")
@export var ghost_count: int = 5            
@export var ghost_fade_time: float = 0.3    

# ==========================================
# VARIABILI DI STATO
# ==========================================
var health: int = 25
var time_since_last_shot: float = 0.0
var is_charging: bool = false
var dash_vector: Vector2 = Vector2.ZERO
var time_tween: Tween
var charge_timer: float = 0.0
var is_preparing_charge: bool = false
var primo_colpo_effettuato: bool = false

var bullet_scene: PackedScene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")

# Array per ricordare chi abbiamo già affettato con il dash corrente
var nemici_colpiti_nel_dash: Array = []

# ==========================================
# NODI
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

func _ready() -> void:
	add_to_group("player")
	process_mode = Node.PROCESS_MODE_ALWAYS
	trajectory_line.visible = false
	healthbar.init_healt(health)
	dash_particles.emitting = false

func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())

	var input_vector = Input.get_vector("left", "right", "up", "down")
	var speed = BASE_SPEED
	
	if GameData.upgrades["speed_boost"]["enabled"]:
		speed += EXTRA_SPEED

	# Applichiamo il moltiplicatore di velocità dell'Ancora Gravitazionale
	velocity = velocity.lerp(input_vector * (speed * speed_multiplier), 0.1)
	move_and_slide()

func _process(delta: float) -> void:
	var can_dash = GameData.upgrades["speed_boost"]["enabled"]
	dash_ui.visible = can_dash

	# FUOCO AUTOMATICO
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= FIRE_RATE:
		fire() 
		time_since_last_shot = 0.0

	# LOGICA DASH
	if can_dash:
		if Input.is_action_just_pressed("ability"):
			if cooldown_timer.is_stopped():
				is_preparing_charge = true
				charge_timer = 0.0

		if Input.is_action_pressed("ability") and is_preparing_charge:
			charge_timer += delta
			if charge_timer >= CHARGE_DELAY and not is_charging:
				start_charging()

		if is_charging:
			update_charging()
			
		if Input.is_action_just_released("ability"):
			if is_charging:
				execute_dash()
			
			is_preparing_charge = false
			is_charging = false
			charge_timer = 0.0
			
		if not cooldown_timer.is_stopped():
			dash_ui.max_value = cooldown_timer.wait_time
			dash_ui.value = cooldown_timer.wait_time - cooldown_timer.time_left
			dash_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
		else:
			dash_ui.max_value = 1.0
			dash_ui.value = 1.0 
			dash_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
	else:
		is_preparing_charge = false
		is_charging = false

func fire() -> void:
	if not primo_colpo_effettuato:
		primo_colpo_effettuato = true
		if GameData.has_method("sblocca_achievement"):
			GameData.sblocca_achievement("primo_sparo")

	$AudioStreamPlayer2D.play()
	spawn_bullet(shooty_part)
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
	$AudioStreamPlayer2D2.play()
	is_charging = false
	trajectory_line.visible = false
	start_iframes()
	if time_tween:
		time_tween.kill()
	Engine.time_scale = 1.0
	
	dash_particles.emitting = true
	spawn_ghost_trail()
	
	# ==========================================
	# FIX DEFINITIVO: Il Dash Trapano!
	# ==========================================
	dash_cast.target_position = to_local(global_position + dash_vector)
	
	# 1. Resettiamo la memoria del raggio ad ogni scatto
	dash_cast.clear_exceptions()
	dash_cast.force_shapecast_update()

	var enemies_killed: int = 0

	# 2. Ciclo while: "Finché c'è qualcosa da colpire..."
	while dash_cast.is_colliding():
		for i in range(dash_cast.get_collision_count()):
			var collider = dash_cast.get_collider(i)
			
			if is_instance_valid(collider):
				if collider.has_method("take_damage"):
					if collider.take_damage(dash_damage):
						enemies_killed += 1
				
				# 3. IL SEGRETO: Diciamo al cast di diventare "fantasma" 
				# per questo nemico specifico, così lo trapassa!
				dash_cast.add_exception(collider)
		
		# 4. Aggiorniamo di nuovo il cast. Avendo ignorato i nemici
		# di prima, ora rileverà quelli che stavano dietro!
		dash_cast.force_shapecast_update()
	# ==========================================
				
	var distance_ratio = dash_vector.length() / max_dash_distance
	var base_cooldown = max(0.5, max_cooldown * distance_ratio)
	var final_cooldown = max(0.1, base_cooldown - (enemies_killed * cooldown_reduction_per_kill))
	cooldown_timer.start(final_cooldown)

	var move_tween = create_tween()
	move_tween.tween_property(self, "global_position", global_position + dash_vector, 0.05)
	move_tween.tween_callback(func(): dash_particles.emitting = false)

# ==========================================
# FIX: Sistema Iframes senza async/await
# ==========================================
func start_iframes() -> void:
	set_collision_layer_value(1, false) 
	set_collision_mask_value(2, false) 

	var blink_tween = create_tween().set_loops(3)
	blink_tween.tween_property(self, "modulate:a", 0.2, 0.05)
	blink_tween.tween_property(self, "modulate:a", 1.0, 0.05)

	get_tree().create_timer(0.4).timeout.connect(_end_iframes)

func _end_iframes() -> void:
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	if speed_multiplier == 1.0:
		modulate = Color(1, 1, 1, 1)
	else:
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
	# 1. Se siamo già morti, ignoriamo ulteriori danni
	if health <= 0:
		return 
		
	preso_danno.emit()
	health -= amount
	
	# 2. Sicurezza: Controlliamo che la healthbar esista ancora
	if is_instance_valid(healthbar):
		healthbar.health = health 
		
	if health <= 0:
		# 3. Disattiviamo le collisioni così i nemici non ci sbattono più contro
		set_collision_layer_value(1, false)
		set_collision_mask_value(2, false)
		
		visible = false # Nasconde lo sprite
		set_physics_process(false) # Gli impedisce di muoversi ancora
		
		died.emit()
		
func heal(amount: int) -> void:
	var max_health = 25 
	health += amount
	health = clamp(health, 0, max_health)
	
	if healthbar:
		healthbar.health = health
	
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	var final_color = Color(1, 1, 1) if speed_multiplier == 1.0 else Color(0.7, 0.5, 1.0)
	flash.tween_property(self, "modulate", final_color, 0.2)

func die() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu/Main_Menu.tscn")

# ==========================================
# EFFETTI DI STATO ESTERNI (Ancora Gravitazionale)
# ==========================================
func apply_slow(amount: float) -> void:
	speed_multiplier = amount
	modulate = Color(0.7, 0.5, 1.0) 

func remove_slow() -> void:
	speed_multiplier = 1.0
	modulate = Color(1, 1, 1)
