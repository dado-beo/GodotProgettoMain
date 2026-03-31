extends CharacterBody2D

const SPEED = 450
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")
var health: int = 12

@onready var Shooty_part = $ShootyPart
@onready var collisione_scudo = $Area2D/CollisionShape2D 
@onready var healthbar = $HealtBar

# Variabile per controllare se l'upgrade è attivo
var upgrade_scudo_riflettente_sbloccato = true 

func _ready():
	call_deferred("_gestisci_ciclo_animazione")
	add_to_group("player")

func _gestisci_ciclo_animazione():
	await get_tree().create_timer(0.1).timeout
	
	# Scudo fisico disattivato all'inizio
	collisione_scudo.set_deferred("disabled", true)
	
	while true:
		$AnimatedSprite2D2.visible = false
		$Sprite2D.visible = false
		
		await get_tree().create_timer(15.0).timeout 
		
		$AnimatedSprite2D2.visible = true
		$AnimatedSprite2D2.frame = 0
		$AnimatedSprite2D2.play("default")
		
		await $AnimatedSprite2D2.animation_finished
		
		$AnimatedSprite2D2.visible = false
		$Sprite2D.visible = true
		
		# ATTIVA LO SCUDO FISICO
		collisione_scudo.set_deferred("disabled", false)
		
		await get_tree().create_timer(4.0).timeout
		
		$Sprite2D.visible = false
		
		# DISATTIVA LO SCUDO FISICO
		collisione_scudo.set_deferred("disabled", true)
		
		$AnimatedSprite2D3.visible = true
		$AnimatedSprite2D3.frame = 0
		$AnimatedSprite2D3.play("default")
		
		await get_tree().create_timer(0.5).timeout


func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())

	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = lerp(get_real_velocity(), input_vector * SPEED, 0.1)
	
	if Input.is_action_just_pressed("shoot"):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = Shooty_part.global_position
		bullet.direction = transform.x.normalized()
		get_tree().get_current_scene().add_child(bullet)

	move_and_slide()


# SCUDO RIFLETTENTE
func _on_area_2d_area_entered(area):
	# Se quello che ci ha colpito è un proiettile nemico
	if area.is_in_group("enemy_bullets"):
		if upgrade_scudo_riflettente_sbloccato:
			var reflected_bullet = bullet_scene.instantiate()
			reflected_bullet.global_position = area.global_position
			
			# Accendiamo l'inseguimento SOLO per questo colpo riflesso
			reflected_bullet.is_homing_active = true
			reflected_bullet.turn_speed = 10.0
			
			var bersaglio = _trova_nemico_piu_vicino()
			
			if bersaglio != null:
				var direzione_verso_nemico = (bersaglio.global_position - reflected_bullet.global_position).normalized()
				reflected_bullet.direction = direzione_verso_nemico
				reflected_bullet.rotation = direzione_verso_nemico.angle()
			else:
				reflected_bullet.direction = Vector2.UP 
			
			call_deferred("_spawna_proiettile", reflected_bullet)
		
		# Il proiettile nemico viene distrutto (assorbito dallo scudo)
		area.queue_free()

func _spawna_proiettile(proiettile):
	get_parent().add_child(proiettile)

func _trova_nemico_piu_vicino() -> Node2D:
	var nemici = get_tree().get_nodes_in_group("enemies")
	var nemico_piu_vicino = null
	var distanza_minima = INF
	
	for nemico in nemici:
		if is_instance_valid(nemico) and not nemico.is_queued_for_deletion():
			var distanza = global_position.distance_to(nemico.global_position)
			if distanza < distanza_minima:
				distanza_minima = distanza
				nemico_piu_vicino = nemico
				
	return nemico_piu_vicino

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
