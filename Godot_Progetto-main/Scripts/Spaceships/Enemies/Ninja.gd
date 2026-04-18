extends CharacterBody2D

# 🔹 Configurazione sparo e movimento
const FIRE_RATE = 0.8
var bullet_scene = preload("res://scenes/Bullets/Enemies/Bullet_Yellow_Ufo.tscn")
var target_position: Vector2
const MOVE_SPEED = 150
var time_since_last_shot := 0.0

# 🔹 Nodi per lo scudo (3 fasi come su Aqua)
@onready var scudo_start = $Scudo1
@onready var scudo_mid = $Scudo
@onready var scudo_end = $Scudo2

# 🔹 Variabili di controllo
var is_shield_active := false 
const SHIELD_DURATION := 6.0 # Durata totale dello scudo acceso

func _ready():
	add_to_group("neutral")
	# Reset iniziale: tutto spento
	if scudo_start: scudo_start.visible = false
	if scudo_mid: scudo_mid.visible = false
	if scudo_end: scudo_end.visible = false

func _physics_process(delta: float) -> void:
	if target_position:
		var dir = (target_position - global_position).normalized()
		velocity = dir * MOVE_SPEED
		move_and_slide()

	time_since_last_shot += delta
	if time_since_last_shot >= FIRE_RATE:
		fire()
		time_since_last_shot = 0.0

func fire():
	spawn_bullet($Ninja_ShootyPart1, Vector2.RIGHT)
	spawn_bullet($Ninja_ShootyPart2, Vector2.DOWN)
	spawn_bullet($Ninja_ShootyPart3, Vector2.UP)
	spawn_bullet($Ninja_ShootyPart4, Vector2.LEFT)

func spawn_bullet(part: Node2D, direction: Vector2):
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = part.global_position
	bullet.direction = direction.normalized()
	get_tree().get_current_scene().add_child(bullet)

# ==========================================
# LOGICA SCUDO TEMPORIZZATO (6 SECONDI)
# ==========================================

func _on_shield_area_area_entered(area: Area2D) -> void:
	# Verifichiamo che sia un proiettile
	if area.is_in_group("player_bullets") or area.is_in_group("enemy_bullets"):
		# 1. Distruggiamo SEMPRE il proiettile che entra
		area.queue_free() 
		
		# 2. Attiviamo l'animazione SOLO se lo scudo non è già attivo
		if not is_shield_active:
			attiva_sequenza_scudo()

func attiva_sequenza_scudo() -> void:
	is_shield_active = true
	
	# FASE 1: Animazione di Apertura (Scudo1)
	if scudo_start:
		scudo_start.visible = true
		scudo_start.frame = 0
		scudo_start.play("default")
		await scudo_start.animation_finished
		scudo_start.visible = false
	
	if not is_instance_valid(self): return
	
	# FASE 2: Mantenimento (Scudo fisso per 6 secondi)
	if scudo_mid:
		scudo_mid.visible = true
		
	# Qui il Ninja è "sotto scudo". Qualsiasi colpo arrivi ora
	# verrà distrutto da _on_shield_area_area_entered ma non ripartirà questa funzione.
	await get_tree().create_timer(SHIELD_DURATION).timeout
	
	if not is_instance_valid(self): return
	
	# FASE 3: Animazione di Chiusura (Scudo2)
	if scudo_mid: scudo_mid.visible = false
	if scudo_end:
		scudo_end.visible = true
		scudo_end.frame = 0
		scudo_end.play("default")
		await scudo_end.animation_finished
		scudo_end.visible = false
	
	# Scudo spento, ora può essere riattivato dal prossimo colpo
	is_shield_active = false

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
