extends CharacterBody2D

@export var max_health: int = 4
var current_health: int

func _ready() -> void:
	current_health = max_health

# ==========================================
# LA FUNZIONE CHE IL PLAYER CERCA
# ==========================================
# Questa funzione riceve il danno (amount) e restituisce un booleano (true/false)
func take_damage(amount: int) -> bool:
	print("Preso")
	current_health -= amount
	
	# JUICE: Piccolo feedback visivo quando viene colpito (lampeggia di rosso)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Controllo della morte
	if current_health <= 0:
		die()
		# Restituisce 'true' al player: "Sì, mi hai ucciso! Sconta il tuo cooldown!"
		return true 
		
	# Restituisce 'false' al player: "Ahi, ma sono ancora vivo."
	return false

func die() -> void:
	# Qui in futuro potrai aggiungere particelle di esplosione, suoni o drop
	queue_free() # Elimina il manichino dalla scena
