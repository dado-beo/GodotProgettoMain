extends CharacterBody2D
signal preso_danno
signal died

const SPEED = 550
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Green_Flesh.tscn")

@onready var Shooty_part = $ShootyPart
@onready var healthbar = $HealtBar
@onready var cooldown_ui = $ChargedShotCooldown 

var counter = 0
var health: int = 22

# --- VARIABILI STATO GRAVITÀ ---
var speed_multiplier: float = 1.0 # 1.0 normale, 0.4 rallentato

const FIRE_RATE: float = 0.2 
var time_since_last_shot: float = 0.2

# --- VARIABILI ABILITÀ E COOLDOWN ---
const CHARGE_DURATION: float = 0.0
const COOLDOWN_DURATION: float = 4.0 
var charge_time: float = 0.0
var is_charged_ready: bool = false
var current_cooldown: float = 0.0 

func _ready():
	add_to_group("player")
	healthbar.init_healt(health)
	
	if cooldown_ui:
		cooldown_ui.max_value = COOLDOWN_DURATION
		cooldown_ui.value = COOLDOWN_DURATION

func _physics_process(delta: float) -> void: 
	look_at(get_global_mouse_position())

	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	# APPLICAZIONE RALLENTAMENTO: Moltiplichiamo la SPEED per lo speed_multiplier
	velocity = lerp(get_real_velocity(), input_vector * (SPEED * speed_multiplier), 0.1)
	move_and_slide()
	
	# ==========================================
	# GESTIONE COOLDOWN E UI
	# ==========================================
	# Controllo se il potenziamento è attivo per mostrare/nascondere l'UI
	var can_use_charged = GameData.upgrades["big_bullet"]["enabled"]
	
	if cooldown_ui:
		cooldown_ui.visible = can_use_charged

	if current_cooldown > 0:
		current_cooldown -= delta
		if cooldown_ui:
			cooldown_ui.value = COOLDOWN_DURATION - current_cooldown
			cooldown_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0) 
	else:
		if cooldown_ui:
			cooldown_ui.value = COOLDOWN_DURATION
			cooldown_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0) 
	
	# ==========================================
	# FUOCO AUTOMATICO (Tasto Sinistro)
	# ==========================================
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= FIRE_RATE:
		shoot()
		time_since_last_shot = 0.0

	# ==========================================
	# LOGICA CARICAMENTO COLPO (Tasto Destro)
	# ==========================================
	if can_use_charged and current_cooldown <= 0.0:
		if Input.is_action_just_pressed("ability"):
			charge_time = 0.0
			is_charged_ready = false

		if Input.is_action_pressed("ability"):
			charge_time += delta
			
			if charge_time >= CHARGE_DURATION and not is_charged_ready:
				is_charged_ready = true
				modulate = Color(10, 10, 10) 

		if Input.is_action_just_released("ability"):
			if is_charged_ready:
				fire_charged_shot()
				current_cooldown = COOLDOWN_DURATION 
			
			charge_time = 0.0
			is_charged_ready = false
			_reset_color()
			
	else:
		if Input.is_action_just_released("ability"):
			charge_time = 0.0
			is_charged_ready = false
			_reset_color()

# Funzione di supporto per gestire i colori senza sovrascriverli
func _reset_color():
	if speed_multiplier == 1.0:
		modulate = Color(1, 1, 1)
	else:
		modulate = Color(0.7, 0.5, 1.0) # Viola rallentamento

func shoot():
	$AudioStreamPlayer2D.set_pitch_scale(1)
	var bullet = bullet_scene.instantiate()
	bullet.global_position = Shooty_part.global_position
	bullet.direction = transform.x.normalized()
	$AudioStreamPlayer2D.play()
	
	# Controllo per l'abilità Homing (Colpo a ricerca)
	var has_homing = GameData.upgrades["homing"]["enabled"]
	
	counter += 1
	
	if has_homing and counter >= 5:
		bullet.is_homing_active = true
		bullet.turn_speed = 10.0
		bullet.speed = 400
		counter = 0 
	else:
		bullet.is_homing_active = false
		bullet.speed = 600
		if counter > 5:
			counter = 0
	
	get_tree().get_current_scene().add_child(bullet)

func fire_charged_shot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = Shooty_part.global_position
	bullet.direction = transform.x.normalized()
	$AudioStreamPlayer2D.set_pitch_scale(0.4)
	$AudioStreamPlayer2D.play()
	get_tree().get_current_scene().add_child(bullet)
	
	if bullet.has_method("setup_charged_shot"):
		bullet.setup_charged_shot()

func heal(amount: int) -> void:
	var max_health = 25 
	health = clamp(health + amount, 0, max_health)
	
	if healthbar:
		healthbar.health = health
	
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	# Ritorna al colore corretto in base allo stato dello slow
	var final_color = Color(1, 1, 1) if speed_multiplier == 1.0 else Color(0.7, 0.5, 1.0)
	flash.tween_property(self, "modulate", final_color, 0.2)

func take_damage(amount: int) -> void:
	if health <= 0:
		return 
		
	preso_danno.emit()
	health -= amount
	
	if is_instance_valid(healthbar):
		healthbar.health = health 
		
	if health <= 0:
		set_collision_layer_value(1, false)
		set_collision_mask_value(2, false)
		visible = false 
		set_physics_process(false) 
		set_process(false) 
		died.emit()
		
func die() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu/Main_Menu.tscn")

# ==========================================
# EFFETTI DI STATO ESTERNI (Ancora Gravitazionale)
# ==========================================
func apply_slow(amount: float) -> void:
	speed_multiplier = amount
	modulate = Color(0.7, 0.5, 1.0) # Colore Viola/Aura

func remove_slow() -> void:
	speed_multiplier = 1.0
	modulate = Color(1, 1, 1) # Torna normale
