extends CharacterBody2D

const SPEED = 500
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Green_Flesh.tscn")
@onready var Shooty_part = $ShootyPart
@onready var healthbar = $HealtBar

var counter = 0
var charge_time: float = 0.0
const CHARGE_DURATION: float = 1
var is_charged_ready: bool = false # Per sapere se il colpo è pronto
var health: int = 22

const FIRE_RATE: float = 0.2 
var time_since_last_shot: float = 0.2

func _ready():
	add_to_group("player")
	healthbar.init_healt(health)

func _physics_process(delta: float) -> void: 
	# --- MOVIMENTO E ROTAZIONE ---
	look_at(get_global_mouse_position())

	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = lerp(get_real_velocity(), input_vector * SPEED, 0.1)
	move_and_slide()
	
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
	
	# 1. APPENA PREMO DESTRO
	if Input.is_action_just_pressed("ability"):
		charge_time = 0.0
		is_charged_ready = false

	# 2. MENTRE TENGO PREMUTO DESTRO
	if Input.is_action_pressed("ability"):
		charge_time += delta
		
		if charge_time >= CHARGE_DURATION and not is_charged_ready:
			is_charged_ready = true
			modulate = Color(10, 10, 10) # Diventa luminosissimo

	# 3. RILASCIO DEL TASTO DESTRO
	if Input.is_action_just_released("ability"):
		if is_charged_ready:
			fire_charged_shot()
		
		# RESET TOTALE 
		charge_time = 0.0
		is_charged_ready = false
		modulate = Color(1, 1, 1)

# --- FUNZIONE SPARO NORMALE (con logica 1 su 5) ---
func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = Shooty_part.global_position
	bullet.direction = transform.x.normalized()
	
	counter += 1
	
	if counter >= 5:
		# Colpo Homing (5°)
		bullet.is_homing_active = true
		bullet.turn_speed = 10.0
		bullet.speed = 400
		counter = 0 # Reset contatore
	else:
		# Colpo Normale (1-4)
		bullet.is_homing_active = false
		bullet.speed = 600
	
	get_tree().get_current_scene().add_child(bullet)

# --- FUNZIONE SPARO CARICATO (Speciale) ---
func fire_charged_shot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = Shooty_part.global_position
	bullet.direction = transform.x.normalized()
	
	get_tree().get_current_scene().add_child(bullet)
	
	# Trasformazione in colpo gigante
	if bullet.has_method("setup_charged_shot"):
		bullet.setup_charged_shot()

# --- SISTEMA DI CURA ---
func heal(amount: int) -> void:
	var max_health = 25 # Assicurati che corrisponda alla vita iniziale
	health += amount
	
	# Impediamo che la vita superi il massimo
	health = clamp(health, 0, max_health)
	
	# Aggiorniamo la barra della vita nella UI
	if healthbar:
		healthbar.health = health
	
	# Effetto visivo: un lampo verde per far capire che si è curato
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func take_damage(amount: int) -> void:
	health -= amount
	healthbar.health = health 
	if health <= 0:
		die()
		
func die() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu/Main_Menu.tscn")
