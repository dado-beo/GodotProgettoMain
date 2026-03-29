extends CanvasLayer

# Riferimento al nodo AnimationPlayer che contiene l'animazione "dissolve".
# "dissolve" anima l'opacità (modulate.a) di un ColorRect nero da 0 a 1.
@onready var anim = $AnimationPlayer

# Funzione pubblica chiamata dagli altri script (es. dal Menu o dal Player).
# Parametro: target_scene_path = il percorso del file della scena (es. "res://Game.tscn").
func change_scene(target_scene_path: String) -> void:
	# 1. INIZIO TRANSIZIONE
	# Riproduce l'animazione che porta lo schermo a nero completo.
	anim.play("dissolve")
	
	# PAUSA SINCRONA:
	# 'await' ferma l'esecuzione DI QUESTA FUNZIONE (non di tutto il gioco)
	# finché il segnale 'animation_finished' non viene emesso.
	# Senza questo, il cambio scena avverrebbe istantaneamente senza aspettare il nero.
	await anim.animation_finished
	
	# 2. CAMBIO SCENA REALE
	# Ora che lo schermo è nero, chiediamo al motore di cambiare la scena attiva.
	get_tree().change_scene_to_file(target_scene_path)
	
	# 3. STABILIZZAZIONE (Il trucco del frame)
	# Aspettiamo esattamente un frame di elaborazione del motore.
	# PERCHÉ? Appena cambiata la scena, Godot ha bisogno di un istante per eseguire i '_ready()'
	# della nuova scena e preparare la grafica.
	# Se togliessimo questa riga, potremmo vedere un "glitch" o un frame vuoto.
	await get_tree().process_frame
	
	# 4. FINE TRANSIZIONE (Sipario su)
	# Riproduciamo l'animazione al contrario (da nero a trasparente).
	anim.play_backwards("dissolve")
