extends CharacterBody2D

const SPEED = 300
var bullet_scene = preload("res://scenes/Bullets/Player/Bullet_Yellow_StarChaser.tscn")

@onready var Shooty_part = $ShootyPart

func _ready():
	# È meglio usare call_deferred per avviare cicli infiniti in _ready
	# per assicurarsi che la scena sia caricata completamente.
	call_deferred("_gestisci_ciclo_animazione")
	add_to_group("player")

func _gestisci_ciclo_animazione():
	# Aspettiamo un attimo prima di iniziare il ciclo per sicurezza
	await get_tree().create_timer(0.1).timeout
	
	while true:
		print("Inizio ciclo: attesa 15 secondi")
		
		# 1. Reset visibilità
		$AnimatedSprite2D2.visible = false
		$Sprite2D.visible = false
		
		# 2. Attesa 15 secondi (IMPORTANTE: await è obbligatorio qui)
		# Per testare metti 1.0, poi rimetti 15.0
		await get_tree().create_timer(15.0).timeout 
		
		# 3. Mostra e avvia animazione
		print("Attivo animazione")
		$AnimatedSprite2D2.visible = true
		$AnimatedSprite2D2.frame = 0 # Resetta l'animazione al primo frame
		$AnimatedSprite2D2.play("default")
		
		# 4. Aspetta ESATTAMENTE la fine dell'animazione
		await $AnimatedSprite2D2.animation_finished
		
		# 5. Mostra l'immagine statica
		print("Animazione finita, mostro immagine")
		$AnimatedSprite2D2.visible = false
		$Sprite2D.visible = true
		
		# 6. Attesa 4 secondi (IMPORTANTE: await è obbligatorio qui)
		await get_tree().create_timer(4.0).timeout
		
		print("Disattivo animazione")
		$Sprite2D.visible = false
		$AnimatedSprite2D3.visible = true
		$AnimatedSprite2D3.frame = 0 # Resetta l'animazione al primo frame
		$AnimatedSprite2D3.play("default")
		
		await get_tree().create_timer(0.5).timeout
		# Il ciclo ricomincia
	
	
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
