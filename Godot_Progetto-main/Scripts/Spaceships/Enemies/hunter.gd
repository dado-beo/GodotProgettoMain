extends Area2D

signal died

@export var hp: int = 20
@export var bullet_scene: PackedScene # Assegna la scena del proiettile nemico da ispettore!

var is_active: bool = false
var target_player: Node2D = null
var is_dashing: bool = false
var is_aiming_dash: bool = false # Nuova variabile per il mirino laser

func _ready():
	# Cerca subito il giocatore
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		
	# --- SETUP HEALTBAR ---
	if has_node("HealtBar"):
		$HealtBar.max_value = hp
		$HealtBar.value = hp
		$HealtBar.visible = false # La nascondiamo finché non entra in scena

func _process(delta: float) -> void:
	# Finché è vivo, c'è un bersaglio e NON sta scattando, lo fissa col muso
	if is_active and target_player and is_instance_valid(target_player) and not is_dashing:
		look_at(target_player.global_position)
		
		# --- GESTIONE MIRINO LASER (Line2D) ---
		if has_node("Line2D"):
			if is_aiming_dash: 
				$Line2D.visible = true
				$Line2D.clear_points()
				
				# Punto A: Canna del fucile
				var start_point = Vector2.ZERO
				if has_node("Hunter_ShootyPart"):
					start_point = $Hunter_ShootyPart.position
					
				$Line2D.add_point(start_point)
				# Punto B: Il giocatore (convertito in coordinate locali)
				$Line2D.add_point(to_local(target_player.global_position))
			else:
				$Line2D.visible = false
	else:
		# Spegni tutto se è in dash o inattivo
		if has_node("Line2D"):
			$Line2D.visible = false

# Chiamata dallo spawner per farli "entrare in scena"
func start_intro(target_pos: Vector2, delay: float):
	visible = false
	await get_tree().create_timer(delay).timeout
	visible = true
	
	if has_node("HealtBar"):
		$HealtBar.visible = true
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	is_active = true
	_behavior_loop()

func _behavior_loop():
	while is_active and is_inside_tree() and hp > 0:
		
		# ==========================================
		# 1. FASE DI MOVIMENTO E SPARO
		# ==========================================
		is_dashing = false
		if target_player and is_instance_valid(target_player):
			var random_offset = Vector2(randf_range(-250, 250), randf_range(-250, 250))
			var wander_target = target_player.global_position + random_offset
			
			var screen_size = get_viewport_rect().size
			wander_target.x = clamp(wander_target.x, 50, screen_size.x - 50)
			wander_target.y = clamp(wander_target.y, 50, screen_size.y - 50)
			
			var move_tween = create_tween()
			move_tween.tween_property(self, "position", wander_target, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			for i in range(3):
				if not is_inside_tree() or hp <= 0: break
				_shoot()
				await get_tree().create_timer(0.6).timeout 
				
			if move_tween.is_running():
				await move_tween.finished

		if not is_inside_tree() or hp <= 0: break
		
		# ==========================================
		# 2. PREPARAZIONE E MIRINO (Telegraphing)
		# ==========================================
		is_aiming_dash = true 
		modulate = Color(1.0, 0.2, 0.2) 
		await get_tree().create_timer(0.6).timeout # Leggermente più veloce a caricare
		modulate = Color(1.0, 1.0, 1.0)
		is_aiming_dash = false 
		
		if not is_inside_tree() or hp <= 0: break
		
		# ==========================================
		# 3. DASH (Scatto fulmineo per trapassarti)
		# ==========================================
		is_dashing = true 
		if target_player and is_instance_valid(target_player):
			var direction = (target_player.global_position - global_position).normalized()
			
			# OVERSHOOT ENORME: Punta ad andare tra 800 e 1200 pixel OLTRE di te
			var dist_to_player = global_position.distance_to(target_player.global_position)
			var total_dash_dist = dist_to_player + randf_range(800.0, 1200.0) 
			
			var dash_target = global_position + (direction * total_dash_dist)
			var will_bounce = false
			var bounce_direction = Vector2.ZERO
			
			# --- GESTIONE MURI ---
			if has_node("DashCast"):
				var cast = $DashCast
				cast.target_position = to_local(dash_target)
				
				# CRUCIALE: Diciamo al raggio di ignorare fisicamente il giocatore, 
				# così non si ferma addosso a te!
				cast.add_exception(target_player)
				
				cast.force_shapecast_update() 
				
				if cast.is_colliding():
					dash_target = cast.get_collision_point(0)
					will_bounce = true
					bounce_direction = cast.get_collision_normal(0)
					
				# Rimuoviamo l'eccezione per pulizia
				cast.clear_exceptions()
			
			if has_node("DashParticles"):
				$DashParticles.emitting = true
			
			var dash_tween = create_tween()
			# TEMPO DIMEZZATO: Ora ci mette solo 0.25 secondi, è velocissimo!
			dash_tween.tween_property(self, "position", dash_target, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await dash_tween.finished
			
			if has_node("DashParticles"):
				$DashParticles.emitting = false
				
			# --- ANIMAZIONE RIMBALZO ---
			if will_bounce:
				var bounce_tween = create_tween()
				var bounce_target = global_position + (bounce_direction * 40.0)
				bounce_tween.tween_property(self, "position", bounce_target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				await bounce_tween.finished
				
		if not is_inside_tree() or hp <= 0: break
		
		# Cooldown
		await get_tree().create_timer(0.3).timeout

func _shoot():
	if not bullet_scene or not is_instance_valid(target_player): 
		return
	
	var bullet = bullet_scene.instantiate()
	
	if has_node("Hunter_ShootyPart"):
		bullet.global_position = $Hunter_ShootyPart.global_position
	else:
		bullet.global_position = global_position
		
	var spawn_pos = bullet.global_position
	var dir = (target_player.global_position - spawn_pos).normalized()
	
	bullet.direction = dir
	
	get_parent().add_child(bullet)

func take_damage(amount: int):
	hp -= amount
	
	if has_node("HealtBar"):
		$HealtBar.value = hp
		
	if hp <= 0:
		if get_tree().get_nodes_in_group("enemies").size() == 1:
			Engine.time_scale = 0.3
			await get_tree().create_timer(0.3).timeout
			Engine.time_scale = 1.0
			
		died.emit()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullets"):
		var damage_amount = 1
		if "damage" in area:
			damage_amount = area.damage
			
		take_damage(damage_amount)
		area.queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
