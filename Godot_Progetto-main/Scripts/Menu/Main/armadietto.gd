extends Panel

# Mappiamo i nomi dei nodi (Bottoni) alle chiavi dei pannelli
@onready var panels = {
	"Costumi": $Skin,      # Assicurati che il nome del bottone sia esattamente 'Costumi'
	"Upgrades": $Miglioramenti,
	"Icone": $Icons
}

@onready var ui_elements = {
	"buttons": $VBoxContainer,
	"back": $VBoxContainer/Back,
	"title": $Label
}

func _ready() -> void:
	# Nascondi i pannelli all'avvio
	for key in panels:
		panels[key].visible = false
	_toggle_main_ui(true)
	
	# Collega automaticamente tutti i bottoni dentro il VBoxContainer
	for button in $VBoxContainer.get_children():
		if button is Button:
			# Passiamo il bottone stesso come argomento al segnale 
			button.pressed.connect(_on_menu_button_pressed.bind(button))

# Funzione universale per aprire i sottomenu
func _on_menu_button_pressed(btn: Button) -> void:
	var button_name = btn.name
	if panels.has(button_name):
		panels[button_name].visible = true
		
		# AGGIORNAMENTO: Richiamiamo la nuova funzione che abbiamo creato nel pannello Upgrades
		if button_name == "Upgrades":
			if panels[button_name].has_method("update_ui_elements"):
				panels[button_name].update_ui_elements()
				
		_toggle_main_ui(false)

# Gestione delle Scene (Modalità di gioco)
func _on_mod_pressed(scene_path: String) -> void:
	# Usa il FadeTransition se presente nel tuo Main_Menu
	FadeTransition.change_scene(scene_path)

func _toggle_main_ui(is_visible: bool) -> void:
	for element in ui_elements.values():
		element.visible = is_visible

func turn_on(closed_panel) -> void:
	closed_panel.visible = false
	_toggle_main_ui(true)
