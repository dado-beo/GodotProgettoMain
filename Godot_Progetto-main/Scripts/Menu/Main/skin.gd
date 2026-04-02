extends Panel

@onready var nodo = get_parent()

# Struttura dati per gestire le navi in modo ciclico
@onready var ship_slots = [
	{"btn": $HBoxContainer/Seleziona, "lock": null, "price_label": null, "cost": 0},
	{"btn": $HBoxContainer/Seleziona2, "lock": $Sprite2D3, "price_label": $MoneteLabel, "cost": 80},
	{"btn": $HBoxContainer/Seleziona3, "lock": $Sprite2D4, "price_label": $MoneteLabel2, "cost": 140}
]

func _ready():
	update_ui_state()

func update_ui_state():
	for i in range(ship_slots.size()):
		var slot = ship_slots[i]
		var is_unlocked = GameData.unlocked_ships[i]
		
		if is_unlocked:
			# Se è sbloccata, nascondi lucchetto e prezzo (SE esistono)
			if slot.lock: slot.lock.visible = false
			if slot.price_label: slot.price_label.visible = false
			slot.btn.disabled = false
		else:
			# Se è bloccata, mostra lucchetto e prezzo (SE esistono)
			if slot.lock: slot.lock.visible = true
			if slot.price_label: slot.price_label.visible = true
			
			# Disabilita se non hai abbastanza monete
			slot.btn.disabled = (GameData.monete_stella < slot.cost)

# Unica funzione per tutti i tasti (passa l'indice dall'Editor)
func _on_seleziona_generic(index: int) -> void:
	var slot = ship_slots[index]
	
	if GameData.unlocked_ships[index]:
		GameData.set_player_ship(index)
	else:
		if GameData.spend_monete(slot.cost):
			GameData.unlocked_ships[index] = true
			update_ui_state()
			GameData.set_player_ship(index)
			
			# AGGIUNTA: Chiamata alla funzione universale che controlla sia le navi che le icone!
			GameData.check_completamento_acquisti()

func _on_back_pressed() -> void:
	# Chiama la funzione del genitore per chiudere il pannello
	if nodo.has_method("turn_on"):
		nodo.turn_on(self)
	else:
		self.visible = false # Fallback se il metodo non esiste
