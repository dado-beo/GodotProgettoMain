extends CharacterBody2D

const SPEED = 500
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Green_Flesh.tscn")
@onready var Shooty_part = $ShootyPart

var counter = 0
var charge_time: float = 0.0
const CHARGE_DURATION: float = 1
var is_charged_ready: bool = false # Per sapere se il colpo è pronto

func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void: # Nota: rinominato _delta in delta perché lo usiamo
	# --- MOVIMENTO E ROTAZIONE ---
	look_at(get_global_mouse_position())

	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = lerp(get_real_velocity(), input_vector * SPEED, 0.1)
	move_and_slide()
	
	# --- LOGICA DI SPARO E CARICAMENTO ---
	
	# 1. APPENA PREMO: Spara il colpo normale (feedback istantaneo)
	if Input.is_action_just_pressed("shoot"):
		shoot()
		# Resettiamo il timer per sicurezza quando si inizia a cliccare
		charge_time = 0.0
		is_charged_ready = false

	# 2. MENTRE TENGO PREMUTO: Calcolo il tempo di carica
	if Input.is_action_pressed("shoot"):
		charge_time += delta
		
		# Se superiamo il tempo e non siamo ancora pronti
		if charge_time >= CHARGE_DURATION and not is_charged_ready:
			is_charged_ready = true
			modulate = Color(10, 10, 10) # Diventa luminosissimo

	# 3. APPENA RILASCIO: Controllo se devo sparare il colpo speciale
	if Input.is_action_just_released("shoot"):
		if is_charged_ready:
			fire_charged_shot()
		
		# RESET TOTALE (Sia che ho sparato il colpo caricato, sia che ho lasciato prima)
		charge_time = 0.0
		is_charged_ready = false
		modulate = Color(1, 1, 1) # Torna al colore normale

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
