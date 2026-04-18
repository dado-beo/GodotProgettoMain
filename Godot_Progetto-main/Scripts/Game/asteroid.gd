extends Area2D

@export var min_speed: float = 200.0
@export var max_speed: float = 600.0
@export var aoe_damage: int = 2
@export var blast_radius: float = 48.0 # Metà di 96px, ovvero il raggio dell'esplosione

@onready var base_sprite = $Sprite2D
@onready var explosion_anim = $ExplosionAnim
@onready var collision_shape = $CollisionShape2D

var velocity = Vector2.ZERO
var is_exploded = false

func _ready():
	# Assicuriamoci che l'esplosione sia nascosta all'inizio
	explosion_anim.visible = false
	if explosion_anim is AnimatedSprite2D:
		explosion_anim.stop()
	
	# Connettiamo i segnali per corpi fisici (Player/Nemici) e Aree (Proiettili)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func setup(start_pos: Vector2, target_pos: Vector2):
	position = start_pos
	look_at(target_pos)
	
	# Calcola la direzione verso il punto target
	var direction = (target_pos - start_pos).normalized()
	var speed = randf_range(min_speed, max_speed)
	velocity = direction * speed

func _process(delta):
	if !is_exploded:
		position += velocity * delta
		# Rotazione opzionale per effetto visivo
		base_sprite.rotation += 2.0 * delta

# Rileva Player e Nemici (CharacterBody2D)
func _on_body_entered(body):
	if !is_exploded and (body.is_in_group("player") or body.is_in_group("enemies")):
		call_deferred("explode")

# Rileva Proiettili (Area2D)
func _on_area_entered(area):
	# Controlla se l'area che lo ha colpito è un proiettile
	# NOTA: Assicurati che i tuoi proiettili siano nei gruppi "player_bullets" o "enemy_bullets"
	if !is_exploded and (area.is_in_group("player_bullets") or area.is_in_group("enemy_bullets") or "Bullet" in area.name):
		
		# Distrugge il proiettile che ha colpito l'asteroide
		if area.has_method("queue_free"):
			area.call_deferred("queue_free")
			
		call_deferred("explode")

func explode():
	$AudioStreamPlayer2D.play()
	if is_exploded: return # Evita esplosioni multiple simultanee
	is_exploded = true
	
	velocity = Vector2.ZERO # Ferma il movimento
	collision_shape.set_deferred("disabled", true) # Disabilita collisioni fisiche
	
	base_sprite.visible = false
	explosion_anim.visible = true
	
	# --- ESEGUE IL DANNO AD AREA ---
	_deal_area_damage()
	
	if explosion_anim is AnimatedSprite2D:
		explosion_anim.play("default") # Assicurati di avere un'animazione "default"
		await explosion_anim.animation_finished
	else:
		# Se è un'immagine statica, aspettiamo un po'
		await get_tree().create_timer(0.5).timeout
		
	queue_free()

# Permette all'asteroide di essere distrutto dal Dash della StarChaser
func take_damage(amount: int) -> bool:
	if !is_exploded:
		call_deferred("explode")
		
		# Ritorna 'true' se vuoi che distruggere un asteroide riduca il 
		# cooldown del dash (come se fosse un nemico ucciso). 
		# Altrimenti metti 'false'.
		return true 
	return false


# Funzione per calcolare chi si trova dentro l'esplosione
func _deal_area_damage():
	# Cerca tutti i nodi player e nemici nella scena
	for group in ["player", "enemies"]:
		for entity in get_tree().get_nodes_in_group(group):
			# Verifichiamo che l'entità esista e possa prendere danno
			if is_instance_valid(entity) and entity.has_method("take_damage"):
				# Se la distanza tra l'asteroide e l'entità è minore del raggio dell'esplosione
				if global_position.distance_to(entity.global_position) <= blast_radius:
					entity.take_damage(aoe_damage)
