extends Parallax2D

# Velocità di scorrimento in pixel al secondo.
# Modifica questo valore nell'Inspector per trovare la velocità giusta.
@export var speed: float = 50.0

# Direzione dello scorrimento (-1 verso sinistra, 1 verso destra)
@export var direction: Vector2 = Vector2(-1, 0)

func _process(delta: float) -> void:
	# Aggiorniamo lo scroll_offset basandoci su velocità e tempo trascorso (delta)
	# Questo garantisce che lo scorrimento sia fluido indipendentemente dagli FPS
	scroll_offset += direction * speed * delta
