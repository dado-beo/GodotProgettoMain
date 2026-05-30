extends Panel

@onready var nodo = get_parent()

# --- 1. PRELOAD DELLE TEXTURE ON/OFF ---
# Sostituisci i percorsi con la cartella reale in cui hai salvato le immagini
var tex_0_off = preload("res://Sprites/Buttons/millenium_falcon_off.png")
var tex_0_on  = preload("res://Sprites/Buttons/millenium_falcon_on.png")

var tex_1_off = preload("res://Sprites/Buttons/flash_player_off.png")
var tex_1_on  = preload("res://Sprites/Buttons/flash_player_on.png")

var tex_2_off = preload("res://Sprites/Buttons/acqua_select_off.png")
var tex_2_on  = preload("res://Sprites/Buttons/acqua_select_on.png")

# --- 2. AGGIUNTA DELLE TEXTURE AI DIZIONARI ---
@onready var ship_slots = [
	{"btn": $HBoxContainer/Seleziona, "lock": null, "price_label": null, "cost": 0, "tex_off": tex_0_off, "tex_on": tex_0_on},
	{"btn": $HBoxContainer/Seleziona2, "lock": $Sprite2D3, "price_label": $MoneteLabel, "cost": 60, "tex_off": tex_1_off, "tex_on": tex_1_on},
	{"btn": $HBoxContainer/Seleziona3, "lock": $Sprite2D4, "price_label": $MoneteLabel2, "cost": 80, "tex_off": tex_2_off, "tex_on": tex_2_on}
]

# Teniamo traccia della navicella attualmente in uso
var indice_equipaggiato: int = 0 

func _ready():
	# All'avvio recuperiamo l'indice della nave in uso da GameData
	# (Assumo che tu abbia una variabile tipo selected_ship_index, adatta il nome se necessario)
	if "selected_ship_index" in GameData:
		indice_equipaggiato = GameData.selected_ship_index
		
	update_ui_state()
	
	if GameData.has_signal("dati_aggiornati"):
		GameData.dati_aggiornati.connect(update_ui_state)

func update_ui_state():
	for i in range(ship_slots.size()):
		var slot = ship_slots[i]
		var is_unlocked = GameData.unlocked_ships[i]
		var is_equipped = (i == indice_equipaggiato)
		
		# --- GESTIONE SBLOCCO / PREZZO ---
		if is_unlocked:
			if slot.lock: slot.lock.visible = false
			if slot.price_label: slot.price_label.visible = false
			slot.btn.disabled = false
		else:
			if slot.lock: slot.lock.visible = true
			if slot.price_label: slot.price_label.visible = true
			slot.btn.disabled = (GameData.biscotti < slot.cost)
			
		# --- 3. CAMBIO GRAFICA VERDE/ROSSO ---
		# Importante: se 'Seleziona' è un bottone normale, si usa 'icon'.
		# Se hai usato il nodo 'TextureButton', cambia 'icon' in 'texture_normal'!
		if is_equipped:
			slot.btn.icon = slot.tex_on
		else:
			slot.btn.icon = slot.tex_off

func _on_seleziona_generic(index: int) -> void:
	var slot = ship_slots[index]
	
	if GameData.unlocked_ships[index]:
		# La nave è già nostra: la equipaggiamo
		GameData.set_player_ship(index)
		indice_equipaggiato = index
		update_ui_state() # <-- Questo forza tutti i bottoni a ricolorarsi
	else:
		# Tentiamo l'acquisto
		if GameData.spend_biscotti(slot.cost):
			GameData.unlocked_ships[index] = true
			GameData.set_player_ship(index)
			indice_equipaggiato = index
			update_ui_state() # <-- Aggiorna l'UI dopo l'acquisto
			
			# GameData.check_completamento_acquisti()

func _on_back_pressed() -> void:
	if nodo.has_method("turn_on"):
		nodo.turn_on(self)
	else:
		self.visible = false
