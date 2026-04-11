extends CharacterBody2D
signal preso_danno
signal died

# ==========================================
# COSTANTI E PARAMETRI
# ==========================================
const SPEED = 500
const CHARGE_DELAY: float = 0.00  # Tempo per distinguere "click" da "tieni premuto"
const SHIELD_DURATION: float = 8.0 # Quanto dura lo scudo acceso
const SHIELD_COOLDOWN: float = 8.0 # Tempo di ricarica dello scudo
const MAX_HEALTH: int = 24 # Vita massima per non curarsi all'infinito

# ==========================================
# VARIABILI DI STATO
# ==========================================
var health: int = MAX_HEALTH
var is_preparing_charge: bool = false
var is_charging: bool = false
var charge_timer: float = 0.0
var is_shield_active: bool = false

# Contatore per la prima abilità (Cura)
var hit_counter: int = 0

var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")

const FIRE_RATE: float = 0.3
var time_since_last_shot: float = 0.3

# ==========================================
# NODI (Onready)
# ==========================================
@onready var Shooty_part = $ShootyPart
@onready var collisione_scudo = $Area2D/CollisionShape2D 
@onready var healthbar = $HealtBar

# Nodi visivi dello scudo
@onready var anim_start = $AnimatedSprite2D2
@onready var sprite_scudo = $Sprite2D
@onready var anim_end = $AnimatedSprite2D3

# Nodi Timer e UI
@onready var cooldown_timer: Timer = $Timer
@onready var shield_ui: TextureProgressBar = $ShieldCooldownUI

# ==========================================
# FUNZIONI DI SISTEMA GODOT
# ==========================================
func _ready():
	add_to_group("player")
	
	# Assicuriamoci che lo scudo sia spento all'avvio
	collisione_scudo.set_deferred("disabled", true)
	anim_start.visible = false
	sprite_scudo.visible = false
	anim_end.visible = false
	
	healthbar.init_healt(health)
	
	# Impostiamo il timer per non essere ciclico (One Shot)
	cooldown_timer.one_shot = true

func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())

	var input_vector = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()

	velocity = lerp(get_real_velocity(), input_vector * SPEED, 0.1)
	move_and_slide()

func _process(delta: float) -> void:
	var can_shield = GameData.upgrades["super_shield"]["enabled"]
	
	if shield_ui:
		shield_ui.visible = can_shield
	
	# ==========================================
	# FUOCO AUTOMATICO (Tasto Sinistro)
	# ==========================================
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= FIRE_RATE:
		fire()
		time_since_last_shot = 0.0

	# ==========================================
	# LOGICA ATTIVAZIONE SCUDO (Tasto Destro)
	# ==========================================
	if can_shield:
		# 1. APPENA PREMUTO IL TASTO DESTRO
		if Input.is_action_just_pressed("ability"):
			if cooldown_timer.is_stopped() and not is_shield_active:
				is_preparing_charge = true
				charge_timer = 0.0

		# 2. MENTRE SI TIENE PREMUTO IL TASTO DESTRO
		if Input.is_action_pressed("ability") and is_preparing_charge:
			charge_timer += delta
			if charge_timer >= CHARGE_DELAY and not is_charging:
				start_charging()

		# 3. RILASCIO DEL TASTO DESTRO
		if Input.is_action_just_released("ability"):
			if is_charging:
				activate_shield()
			
			is_preparing_charge = false
			is_charging = false
			charge_timer = 0.0
			
		# 4. AGGIORNAMENTO UI
		if shield_ui:
			if is_shield_active:
				shield_ui.value = 0
				shield_ui.tint_progress = Color(0.8, 0.2, 0.2, 1.0) 
			elif not cooldown_timer.is_stopped():
				shield_ui.max_value = cooldown_timer.wait_time
				shield_ui.value = cooldown_timer.wait_time - cooldown_timer.time_left
				shield_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
			else:
				shield_ui.max_value = 1.0
				shield_ui.value = 1.0 
				shield_ui.tint_progress = Color(0.2, 0.8, 1.0, 1.0)
	else:
		is_preparing_charge = false
		is_charging = false


# ==========================================
# SISTEMA ARMI E SCUDO
# ==========================================
func fire() -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = Shooty_part.global_position
	bullet.direction = transform.x.normalized()
	get_tree().get_current_scene().add_child(bullet)

func start_charging() -> void:
	is_charging = true
	modulate = Color(2, 2, 2) 
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.1)

func activate_shield() -> void:
	is_shield_active = true
	
	anim_start.visible = true
	anim_start.frame = 0
	anim_start.play("default")
	await anim_start.animation_finished
	
	if not is_instance_valid(self): return
	anim_start.visible = false
	sprite_scudo.visible = true
	collisione_scudo.set_deferred("disabled", false)
	
	await get_tree().create_timer(SHIELD_DURATION).timeout
	if not is_instance_valid(self): return
	
	sprite_scudo.visible = false
	collisione_scudo.set_deferred("disabled", true)
	
	anim_end.visible = true
	anim_end.frame = 0
	anim_end.play("default")
	await get_tree().create_timer(0.5).timeout
	
	if not is_instance_valid(self): return
	anim_end.visible = false
	is_shield_active = false
	
	cooldown_timer.start(SHIELD_COOLDOWN)


# ==========================================
# SCUDO RIFLETTENTE (Logica Collisione)
# ==========================================
func _on_area_2d_area_entered(area):
	if area.is_in_group("enemy_bullets"):
		
		# Ora lo scudo si attiva SOLO se hai la SECONDA mod ("super_shield"),
		# quindi se siamo qui, l'effetto riflettente parte in automatico!
		var reflected_bullet = bullet_scene.instantiate()
		reflected_bullet.global_position = area.global_position
		
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
		
		area.queue_free()

func _spawna_proiettile(proiettile):
	get_tree().get_current_scene().add_child(proiettile)

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
# SISTEMA CURA (PRIMA ABILITÀ) E DANNI
# ==========================================
func register_enemy_hit() -> void:
	if GameData.upgrades["shield"]["enabled"]:
		hit_counter += 1
		if hit_counter >= 6:
			hit_counter = 0
			heal(1)

func heal(amount: int) -> void:
	health += amount
	if health > MAX_HEALTH:
		health = MAX_HEALTH
		
	if healthbar:
		healthbar.health = health
		
	# --- EFFETTO VISIVO CURA ---
	# Crea un lampo verde per far capire al giocatore che si è curato
	var flash = create_tween()
	flash.tween_property(self, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	flash.tween_property(self, "modulate", Color(1, 1, 1), 0.2)

func take_damage(amount: int) -> void:
	# --- FIX CRUCIALE: INVULNERABILITÀ ---
	# Se lo scudo è attivo, qualsiasi danno viene annullato sul nascere!
	if is_shield_active:
		return 
	# -------------------------------------
	
	preso_danno.emit() # Avvisa il gioco che sei stato colpito!
	
	health -= amount
	if healthbar:
		healthbar.health = health 
	if health <= 0:
		died.emit()
		die()

func die() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
