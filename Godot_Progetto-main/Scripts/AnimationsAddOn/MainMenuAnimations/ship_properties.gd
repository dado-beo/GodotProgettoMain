extends Node2D

# Vettore normalizzato che indica la direzione di movimento (verso il centro).
var direction: Vector2
# Velocità di movimento in pixel al secondo (assegnata dinamicamente nel _ready).
var speed: int

func _ready() -> void:
	# Legge il nome del file della scena (es. "Aqua_DecorativeShip.tscn")
	# e imposta la velocità specifica per quel tipo di nave.
	# Questo permette di usare UN SOLO script per tutte le varianti estetiche.
	# Salviamo il nome in una variabile per non ricalcolarlo più volte
	var ship_name = scene_file_path.get_file().get_basename()
	
	if ship_name == "Aqua_DecorativeShip":
		speed = 450
	elif ship_name == "Flash_DecorativeShip":
		speed = 400
	elif ship_name == "Ninja_DecorativeShip":
		speed = 600
	elif ship_name == "PurpleDevil_DecorativeShip":
		speed = 700
	elif ship_name == "StarChaser_DecorativeShip":
		speed = 300
	else:
		speed = 100
	
	# --- CALCOLO DELLA TRAIETTORIA ---
	# Definisce il punto target: il centro esatto dello schermo.
	var screen_center = get_viewport_rect().size / 2
	
	# Calcola il vettore direzione: (Destinazione - Posizione Attuale).
	# .normalized() riduce la lunghezza del vettore a 1, mantenendo solo la direzione.
	direction = (screen_center - global_position).normalized()
	
	# Ruota lo sprite fisicamente affinché guardi verso la direzione in cui sta andando.
	rotation = direction.angle()
	
# --- LOOP DI GIOCO ---
# 'delta' è il tempo trascorso dall'ultimo frame.
func _process(delta: float) -> void:
	# Formula standard del movimento lineare:
	global_position += direction * speed * delta

# Collegato al segnale 'screen_exited' del nodo VisibleOnScreenNotifier2D.
# Viene attivato quando la nave esce completamente dall'inquadratura.
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Rimuove l'oggetto dalla memoria per evitare rallentamenti (memory leaks)
	# dato che la nave non serve più una volta uscita dallo schermo.
	queue_free()
