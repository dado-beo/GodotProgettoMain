extends CheckButton

func _ready() -> void:
	# Controlla la modalità attuale della finestra del sistema operativo
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# set_pressed_no_signal attiva o disattiva graficamente il bottone 
	# SENZA far scattare la funzione _on_toggled (evitando un loop o glitch visivi all'avvio)
	set_pressed_no_signal(is_fullscreen)

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
