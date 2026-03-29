extends Area2D

@export var min_speed: float = 200.0
@export var max_speed: float = 600.0

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
	
	# Connetti i segnali se non lo fai dall'editor
	body_entered.connect(_on_body_entered)
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

func _on_body_entered(body):
	# Se colpisce il giocatore e non è già esploso
	if body.is_in_group("player") and !is_exploded:
		call_deferred("explode")
		# Qui potresti chiamare una funzione di danno sul giocatore, es:
		# if body.has_method("take_damage"):
		# 	body.take_damage()

func explode():
	is_exploded = true
	velocity = Vector2.ZERO # Ferma il movimento
	collision_shape.set_deferred("disabled", true) # Disabilita collisioni
	
	base_sprite.visible = false
	explosion_anim.visible = true
	
	if explosion_anim is AnimatedSprite2D:
		explosion_anim.play("default") # Assicurati di avere un'animazione "default"
		await explosion_anim.animation_finished
	else:
		# Se è un'immagine statica, aspettiamo un po'
		await get_tree().create_timer(0.5).timeout
		
	queue_free()
