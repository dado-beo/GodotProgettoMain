extends CharacterBody2D

# ==========================================
# VARIABILI
# ==========================================
var speed: float = 40.0 
var slow_power: float = 0.4

# Variabili per il movimento casuale
var target_position: Vector2
var screen_rect: Rect2
var is_inside_arena: bool = false

@onready var gravity_aura: Area2D = $GravityAura

func _ready() -> void:
	add_to_group("enemies")
	screen_rect = get_viewport_rect()
	
	# Disabilitiamo la collisione con i Muri (Layer 2) appena nasce per farla entrare
	set_collision_mask_value(2, false)

func _physics_process(delta: float) -> void:
	# 1. Controllo se è entrata nell'arena per la prima volta
	if not is_inside_arena and screen_rect.has_point(global_position):
		is_inside_arena = true
		# È dentro! Riattiviamo i muri (Layer 2)
		set_collision_mask_value(2, true)
	
	# 2. Si muove verso il bersaglio attuale
	var direction = global_position.direction_to(target_position)
	velocity = direction * speed
	
	# Ruota dolcemente 
	rotation = lerp_angle(rotation, direction.angle(), 0.05)
	move_and_slide()

	# 3. Se ha raggiunto il punto sceglie una nuova rotta
	if global_position.distance_to(target_position) < 10.0:
		pick_new_random_target()

func pick_new_random_target() -> void:
	var margin = 60 
	var rand_x = randf_range(margin, screen_rect.size.x - margin)
	var rand_y = randf_range(margin, screen_rect.size.y - margin)
	target_position = Vector2(rand_x, rand_y)

# ==========================================
# GESTIONE AURA GRAVITAZIONALE
# ==========================================
func _on_gravity_aura_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_slow"):
		body.apply_slow(slow_power)

func _on_gravity_aura_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("remove_slow"):
		body.remove_slow()

# ==========================================
# GESTIONE DANNI (IMMORTALE)
# ==========================================
func take_damage(amount: int) -> bool:
	# Assorbe il colpo: fa un piccolo flash visivo per feedback
	modulate = Color(2, 2, 2) 
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
	
	# Restituisce SEMPRE false, segnalando al player/dash che non l'ha uccisa
	return false
