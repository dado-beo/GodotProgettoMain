extends CharacterBody2D

@onready var healthbar = $HealtBar
var player: Node2D = null

const SPEED = 400
var health: int = 6

func _ready():
	add_to_group("enemies")
	# Inizializza la barra vita
	healthbar.init_healt(health)

	# Trova il player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(_delta: float) -> void:
	if player == null:
		return
	velocity = (player.global_position - global_position).normalized() * SPEED
	look_at(player.global_position)
	move_and_slide()

# Funzione per gestire il danno
func take_damage(amount: int) -> void:
	health -= amount
	healthbar.health = health
	if health <= 0:
		die()

# Quando la vita finisce
func die() -> void: 	
	# istanzia particelle esplosione 	
	var explosion = preload("res://scenes/AnimationAddOn/Explosion.tscn").instantiate() 	
	get_parent().add_child(explosion) 	
	explosion.global_position = global_position 	 	
	GameData.aggiungi_kill("kamikaze") # Aggiunge
	queue_free()
