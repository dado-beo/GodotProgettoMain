extends Panel

@onready var upgrade1 = $Upgrade1
@onready var upgrade2 = $Upgrade2
@onready var nodo = get_parent()

# Dizionario unico: contiene Nomi, Costi, Chiavi Salvataggio e Icone
var ship_data = {
	0: {
		"u1": {"nome": "Triple Shot", "costo": 500, "key": "triple_shot", "icon": preload("res://Sprites/Buttons/triple_shoot_off.png")},
		"u2": {"nome": "Speed Boost", "costo": 750, "key": "speed_boost", "icon": preload("res://Sprites/Buttons/speed_boost_off.png")}
	},
	1: {
		"u1": {"nome": "Homing", "costo": 500, "key": "homing", "icon": preload("res://Sprites/Buttons/homing_target_off.png")},
		"u2": {"nome": "Big Bullet", "costo": 750, "key": "big_bullet", "icon": preload("res://Sprites/Buttons/charged_shot_off.png")}
	},
	2: {
		"u1": {"nome": "Shield", "costo": 500, "key": "shield", "icon": preload("res://Sprites/Buttons/shield_off.png")},
		"u2": {"nome": "Super Shield", "costo": 750, "key": "super_shield", "icon": preload("res://Sprites/Buttons/bouncing_shield_off.png")}
	}
}

func _ready():
	update_ui_elements()

func update_ui_elements():
	var ship_idx = GameData.selected_ship_index
	var data = ship_data[ship_idx]
	
	# Applichiamo icone e stati usando un piccolo ciclo o riferimenti diretti
	_setup_button(upgrade1, data["u1"])
	_setup_button(upgrade2, data["u2"])
	$Upgrade1/Price1.text=str(data["u1"]["costo"])
	$Upgrade2/Price2.text=str(data["u2"]["costo"])

func _on_button_pressed() -> void:
	_process_purchase("u1")

func _on_button_2_pressed() -> void:
	_process_purchase("u2")

# Quando configuri i bottoni a schermo:
func _setup_button(btn, info: Dictionary):
	btn.icon = info["icon"]
	btn.expand_icon = true
	var key = info["key"] # es: "triple_shot"
	btn.button_pressed = GameData.upgrades[key]["enabled"]
	btn.disabled = not GameData.upgrades[key]["purchased"]

# Quando compri l'upgrade:
func _process_purchase(upgrade_id: String):
	var data = ship_data[GameData.selected_ship_index][upgrade_id]
	var key = data["key"]
	
	if GameData.spend_monete(data["costo"]):
		GameData.upgrades[key]["purchased"] = true
		GameData.upgrades[key]["enabled"] = true
		GameData.save_data()
		update_ui_elements()
	else:
		print("Monete insufficienti per: ", data["nome"])

# Quando clicchi la spunta per attivare/disattivare:
func _on_upgrade_1_toggled(toggled_on: bool) -> void:
	var key = ship_data[GameData.selected_ship_index]["u1"]["key"]
	GameData.upgrades[key]["enabled"] = toggled_on
	GameData.save_data()

func _on_upgrade_2_toggled(toggled_on: bool) -> void:
	var key = ship_data[GameData.selected_ship_index]["u2"]["key"]
	GameData.set(key + "_enabled", toggled_on)
	GameData.save_data()

func _on_ritorno_pressed() -> void:
	if nodo.has_method("turn_on"):
		nodo.turn_on(self)
	else:
		self.visible = false # Fallback se il metodo non esiste
