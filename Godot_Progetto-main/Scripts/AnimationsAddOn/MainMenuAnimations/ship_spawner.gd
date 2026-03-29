extends Node2D

# --- CONFIGURAZIONE RISORSE ---
# Array costante che contiene tutte le scene delle navi possibili.
# Usiamo 'preload' per caricare i file in memoria all'avvio del gioco.
const SHIP_SCENES = [
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/StarChaser_DecorativeShip.tscn"),
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/Flash_DecorativeShip.tscn"),
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/Turtle_DecorativeShip.tscn"),
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/PurpleDevil_DecorativeShip.tscn"),
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/Ninja_DecorativeShip.tscn"),
	preload("res://scenes/AnimationAddOn/MainMenuAnimations/Aqua_DecorativeShip.tscn")
]

func _ready() -> void:
	# Inizializza il generatore di numeri casuali. 
	# Senza questo, la sequenza di navi sarebbe identica a ogni avvio.
	randomize()
	
	# --- TIMER SETUP ---
	# Colleghiamo via codice il segnale 'timeout' del nodo Timer alla nostra funzione.
	# Quando il timer arriva a zero, esegue '_on_timer_timeout'.
	$Timer.timeout.connect(_on_timer_timeout)
	
	# Avvia il timer.
	$Timer.start()

func _on_timer_timeout():
	# 1. SELEZIONE
	# Sceglie un indice casuale tra 0 e l'ultimo elemento dell'array.
	var random_index = randi() % SHIP_SCENES.size()
	var chosen_scene = SHIP_SCENES[random_index]
	
	# 2. ISTANZIAZIONE
	# Crea una copia concreta della nave in memoria.
	var ship = chosen_scene.instantiate()
	
	# 3. POSIZIONAMENTO
	# Chiama la funzione helper per decidere dove far apparire la nave.
	ship.global_position = spawn_outside_screen()
	
	# 4. INSERIMENTO
	# Aggiunge la nave alla scena corrente.
	add_child(ship)

# Funzione Helper per calcolare una posizione valida fuori dallo schermo.
# Restituisce un Vector2 (coordinate X, Y).
func spawn_outside_screen() -> Vector2:
	# --- LOGICA DINAMICA (Responsive) ---
	# get_viewport_rect().size restituisce un Vector2 con la risoluzione attuale.
	# Esempio: (1152, 648) oppure (1920, 1080).
	var screen_size = get_viewport_rect().size
	
	var pos = Vector2()
	
	# Scegliamo casualmente uno dei 4 lati (0=Sx, 1=Dx, 2=Su, 3=Giù)
	var side = randi() % 4
	
	# Distanza di sicurezza dal bordo per non far apparire la nave "a metà".
	var offset = 50 

	match side:
		0: # LATO SINISTRO
			# Posizioniamo la X a sinistra dello schermo (negativa)
			pos.x = -offset
			# La Y può essere un punto qualsiasi dell'altezza schermo
			pos.y = randf() * screen_size.y
			
		1: # LATO DESTRO
			# Posizioniamo la X oltre il bordo destro
			pos.x = screen_size.x + offset
			# La Y è casuale
			pos.y = randf() * screen_size.y
			
		2: # LATO SUPERIORE
			# La X è casuale lungo la larghezza
			pos.x = randf() * screen_size.x
			# Posizioniamo la Y sopra lo schermo (negativa)
			pos.y = -offset
			
		3: # LATO INFERIORE
			# La X è casuale
			pos.x = randf() * screen_size.x
			# Posizioniamo la Y sotto il bordo inferiore
			pos.y = screen_size.y + offset

	return pos
