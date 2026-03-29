extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 0.0
var damage: int = 0
var target: Node2D = null
var is_homing_active: bool = false 
var turn_speed: float = 7.5
var is_it_player: bool = false 

# Precarichiamo l'effetto esplosione
var explosion_scene = preload("res://scenes/AnimationAddOn/Explosion.tscn")

func _ready() -> void:
	var bullet_name = scene_file_path.get_file().get_basename()
	
	# Impostazioni in base al nome del file
	if bullet_name == "Ninja":
		set_parameters(550, 1)
		is_it_player = false
		
	elif bullet_name == "Bullet_Purple_Devil":
		set_parameters(800, 3)
		is_it_player = false
		
	elif bullet_name == "Bullet_Yellow_Ufo":
		set_parameters(700, 2)
		is_it_player = false
		
	elif bullet_name == "Bullet_Yellow_Turtle":
		set_parameters(450, 4)
		is_it_player = false
		
	elif bullet_name == "Bullet_Green_Flesh": # <-- Questo è quello del Flash
		set_parameters(700, 2) 
		is_it_player = true
		
	elif bullet_name == "Bullet_Yellow_StarChaser":
		set_parameters(900, 3)
		is_it_player = true
		
	elif bullet_name == "Bullet_Yellow_Aqua":
		set_parameters(900, 3)
		is_it_player = true
	
	# Orienta graficamente il proiettile alla partenza
	rotation = direction.angle()

func set_parameters(spd: int, dmg: int):
	speed = spd
	damage = dmg

# --- NUOVA FUNZIONE PER IL COLPO CARICATO (Chiamata dal Playwer) ---
func setup_charged_shot():
	scale = Vector2(3.0, 3.0)
	damage = 6
	is_homing_active = true
	turn_speed = 5.0 
	speed = 700.0 
	modulate = Color(2, 2, 2) 
	is_it_player = true

func _physics_process(delta: float) -> void:
	if is_homing_active:
		# Se non ha target o il target è morto, ne cerca uno nuovo
		if target == null or not is_instance_valid(target):
			target = find_nearest_enemy()
			
		# Se ha un target valido, sterza verso di lui
		if target != null and is_instance_valid(target):
			var desired = (target.global_position - global_position).normalized()
			direction = direction.lerp(desired, turn_speed * delta).normalized()
	
	# Applica rotazione grafica
	rotation = direction.angle()
	# Applica movimento fisico
	global_position += direction * speed * delta

# Cerca il nemico più vicino
func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
		
	var closest = null
	var min_dist = INF
	
	for enemy in enemies:
		# Verifica extra: ignora nemici già morti o non validi
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	return closest

# --- Collisioni e Uscita Schermo ---

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# 1. Protezione Fuoco Amico:
	# Se il proiettile è del player E colpisce il player -> Ignora
	if is_it_player and body.is_in_group("player"):
		return 
	
	# Se il proiettile è nemico E colpisce un nemico -> Ignora (opzionale)
	if not is_it_player and body.is_in_group("enemies"):
		return

	# 2. Gestione Danno
	if is_it_player:
		# Proiettile Player colpisce Nemico
		if body.is_in_group("enemies"):
			apply_damage_and_destroy(body)
	else:
		# Proiettile Nemico colpisce Player
		if body.is_in_group("player"):
			apply_damage_and_destroy(body)

func apply_damage_and_destroy(hit_target):
	if hit_target.has_method("take_damage"):
		hit_target.take_damage(damage)
	
	create_explosion()
	call_deferred("queue_free")

func create_explosion():
	if get_tree() == null: return

	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.lifetime = randf_range(0.3, 0.7)
	
	# Aumenta la dimensione dell'esplosione se il proiettile è gigante
	if scale.x > 1.0:
		explosion.scale = scale
	
	if get_tree().current_scene:
		get_tree().current_scene.call_deferred("add_child", explosion)
