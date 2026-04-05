extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var options: Panel = $Options
# Aggiungiamo il riferimento al bottone (basato sulla tua immagine)
@onready var fullscreen_btn: CheckButton = $Options/FullscreenControl

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # continua a ricevere input anche se il gioco è in pausa
	main_buttons.visible = true
	options.visible = false
	visible = false  # menu nascosto all'avvio

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):  # tasto Esc (mappato in InputMap)
		if visible:
			close()
		else:
			open()

func open() -> void:
	visible = true
	get_tree().paused = true
	
	# --- FIX FULLSCREEN ---
	# Controlliamo se il gioco è effettivamente in fullscreen e aggiorniamo il bottone
	var current_mode = DisplayServer.window_get_mode()
	var is_fullscreen = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	if fullscreen_btn:
		fullscreen_btn.set_pressed_no_signal(is_fullscreen)

func close() -> void:
	visible = false
	get_tree().paused = false

# --- Bottoni ---
func _on_resume_btn_pressed() -> void:
	close()

func _on_quit_btn_pressed() -> void:
	close()
	FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")

func _on_back_pressed() -> void:
	main_buttons.visible = true
	options.visible = false

func _on_settings_btn_pressed() -> void:
	main_buttons.visible = false
	options.visible = true
