extends CharacterBody2D

# 🔹 Configurazione sparo
const FIRE_RATE = 0.8 # secondi
var bullet_scene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Ufo.tscn")

# 🔹 4 punti di sparo
@onready var Shooty_part1 = $Ninja_ShootyPart1
@onready var Shooty_part2 = $Ninja_ShootyPart2
@onready var Shooty_part3 = $Ninja_ShootyPart3
@onready var Shooty_part4 = $Ninja_ShootyPart4

# 🔹 Movimento
var target_position: Vector2
const MOVE_SPEED = 150

# 🔹 Timer sparo
var time_since_last_shot := 0.0

func _ready():
	add_to_group("enemies") # per identificare i nemici

func _physics_process(delta: float) -> void:
	# Movimento verso target
	if target_position:
		var dir = (target_position - global_position).normalized()
		velocity = dir * MOVE_SPEED
		move_and_slide()

	# Sparo automatico
	time_since_last_shot += delta
	if time_since_last_shot >= FIRE_RATE:
		fire()
		time_since_last_shot = 0.0

func fire():
	# Sparo dai 4 punti con direzioni fisse
	spawn_bullet(Shooty_part1, Vector2.RIGHT)   # Destra
	spawn_bullet(Shooty_part2, Vector2.DOWN)    # Giù
	spawn_bullet(Shooty_part3, Vector2.UP)      # Su
	spawn_bullet(Shooty_part4, Vector2.LEFT)    # Sinistra

func spawn_bullet(part: Node2D, direction: Vector2):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = part.global_position
	bullet.direction = direction.normalized()
	get_tree().get_current_scene().add_child(bullet)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free() # distrugge il nemico
