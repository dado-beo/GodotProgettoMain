extends CharacterBody2D

const BASE_SPEED = 200  # Ho aumentato leggermente la base, 100 è molto lento
const EXTRA_SPEED = 100
const FIRE_RATE = 0.3 # secondi
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")

@onready var shooty_part = $ShootyPart
@onready var shooty_part2 = $ShootyPart2
@onready var shooty_part3 = $ShootyPart3
@onready var healthbar = $HealtBar

var time_since_last_shot := 0.0
var health: int = 12

func _ready():
	# Inizializza la barra vita
	healthbar.init_healt(health)
	add_to_group("player")
	
func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())

	# In Godot 4 è meglio usare get_vector per gestire le diagonali correttamente
	var input_vector = Input.get_vector("left", "right", "up", "down")

	var speed = BASE_SPEED
	
	# --- CORREZIONE DIPENDENZA ---
	# Usiamo GameData invece di Global
	if GameData.upgrades.speed_boost.enabled:
		speed += EXTRA_SPEED

	# Movimento fluido
	velocity = velocity.lerp(input_vector * speed, 0.1)

	# Gestione sparo
	time_since_last_shot += delta

	# Nota: Usa 'is_action_pressed' se vuoi sparare tenendo premuto,
	# 'is_action_just_pressed' se vuoi cliccare ogni volta.
	if Input.is_action_pressed("shoot") and time_since_last_shot >= FIRE_RATE:
		fire()
		time_since_last_shot = 0.0
		GameData.sblocca_achievement("primo_sparo")

	move_and_slide()

func fire():
	# Spara sempre dal centrale
	spawn_bullet(shooty_part)

	# --- CORREZIONE DIPENDENZA ---
	# Usiamo GameData invece di Global
	if GameData.upgrades.triple_shot.enabled:
		spawn_bullet(shooty_part2)
		spawn_bullet(shooty_part3)

func spawn_bullet(part: Node2D):
	if part == null: return # Sicurezza nel caso mancasse il nodo
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = part.global_position
	# Usa la rotazione del player per la direzione del proiettile
	bullet.rotation = rotation 
	# Assumendo che il proiettile abbia una proprietà 'direction' o si muova in avanti
	if "direction" in bullet:
		bullet.direction = Vector2.RIGHT.rotated(rotation)
		
	get_tree().get_current_scene().add_child(bullet)

# Funzione per gestire il danno
func take_damage(amount: int) -> void:
	health -= amount
	healthbar.health = health
	if health <= 0:
		die()

# Quando la vita finisce
func die() -> void:
	# Salva eventuali progressi o statistiche prima di morire se necessario
	# GameData.save_data() 
	
	# Cambio scena differito per evitare crash fisici
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Menu/Main_Menu.tscn")
