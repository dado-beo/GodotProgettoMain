extends Panel

@onready var nodo_padre = get_parent()

# Gestiamo i nodi in un dizionario per evitare ripetizioni e chiudere correttamente le parentesi
@onready var icon_slots = {
	1: {"btn": $HBoxContainer/Btn1, "lock": $Sprite2D2, "price": $MoneteLabel3, "cost": 5},
	2: {"btn": $HBoxContainer/Btn2, "lock": $Sprite2D3, "price": $MoneteLabel, "cost": 20},
	3: {"btn": $HBoxContainer/Btn3, "lock": $Sprite2D4, "price": $MoneteLabel2, "cost": 100},
	4: {"btn": $HBoxContainer/Btn4, "lock": $Sprite2D5, "price": $MoneteLabel4, "cost": 35}
}

func _ready():
	update_ui_state()

func update_ui_state():
	# Usiamo un ciclo per aggiornare tutto senza errori di indice
	for id in icon_slots.keys():
		var slot = icon_slots[id]
		# Verifica che l'indice esista in GameData prima di accedere
		var is_unlocked = GameData.unlocked_icons[id]
		
		if is_unlocked:
			slot.lock.visible = false
			slot.price.visible = false
			slot.btn.disabled = false
		else:
			slot.lock.visible = true
			slot.price.visible = true
			# Abilita il tasto solo se hai abbastanza monete
			slot.btn.disabled = (GameData.monete_stella < slot.cost)

func _on_btn_pressed(id: int) -> void:
	if GameData.unlocked_icons[id]:
		_equip_icon(id)
	else:
		var costo = icon_slots[id].cost
		if GameData.spend_monete(costo):
			GameData.unlocked_icons[id] = true
			GameData.save_data()
			update_ui_state()
			_equip_icon(id)
			
			# --- NUOVO: CONTROLLO ACHIEVEMENT ICONE ---
			var tutte_sbloccate = true
			for sbloccata in GameData.unlocked_icons:
				if sbloccata == false:
					tutte_sbloccate = false
					break # Trovata una bloccata, smette di cercare
					
			if tutte_sbloccate:
				GameData.sblocca_achievement("tutteLeIcone")

func _equip_icon(id: int):
	GameData.current_icon_index = id
	GameData.save_data()
	# Emette il segnale per aggiornare il Main_Menu
	GameData.profile_icon_changed.emit()
	print("Icona ", id, " equipaggiata!")

func _on_back_pressed() -> void:
	if nodo_padre.has_method("turn_on"):
		nodo_padre.turn_on(self)
	else:
		self.visible = false
