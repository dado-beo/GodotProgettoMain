extends Panel

@onready var upgrade1 = $Upgrade1
@onready var upgrade2 = $Upgrade2
@onready var nodo = get_parent()

# Dizionario: contiene Icone OFF e ON
var ship_data = {
	0: {
		"u1": {"nome": "Triple Shot", "costo": 60, "key": "triple_shot", "icon_off": preload("res://Sprites/Buttons/triple_shoot_off.png"), "icon_on": preload("res://Sprites/Buttons/triple_shoot_on.png")},
		"u2": {"nome": "Speed Boost", "costo": 100, "key": "speed_boost", "icon_off": preload("res://Sprites/Buttons/speed_boost_off.png"), "icon_on": preload("res://Sprites/Buttons/speed_boost_on.png")}
	},
	1: {
		"u1": {"nome": "Homing", "costo": 100, "key": "homing", "icon_off": preload("res://Sprites/Buttons/homing_target_off.png"), "icon_on": preload("res://Sprites/Buttons/homing_target_on.png")},
		"u2": {"nome": "Big Bullet", "costo": 140, "key": "big_bullet", "icon_off": preload("res://Sprites/Buttons/charged_shot_off.png"), "icon_on": preload("res://Sprites/Buttons/charged_shot_on.png")}
	},
	2: {
		"u1": {"nome": "Shield", "costo": 120, "key": "shield", "icon_off": preload("res://Sprites/Buttons/vampirism_off.png"), "icon_on": preload("res://Sprites/Buttons/vampirism_on.png")},
		"u2": {"nome": "Super Shield", "costo": 160, "key": "super_shield", "icon_off": preload("res://Sprites/Buttons/bouncing_shield_off.png"), "icon_on": preload("res://Sprites/Buttons/bouncing_shield_on.png")}
	}
}

func _ready():
	update_ui_elements()

func update_ui_elements():
	var ship_idx = GameData.selected_ship_index
	var data = ship_data[ship_idx]
	
	_setup_button(upgrade1, data["u1"])
	_setup_button(upgrade2, data["u2"])
	
	# --- LOGICA PER NASCONDERE I PREZZI ---
	var key1 = data["u1"]["key"]
	var key2 = data["u2"]["key"]
	
	var is_purchased_1 = GameData.upgrades[key1]["purchased"]
	var is_purchased_2 = GameData.upgrades[key2]["purchased"]
	
	# Gestione Upgrade 1
	$Upgrade1/Price1.text = str(data["u1"]["costo"])
	$Upgrade1/Price1.visible = not is_purchased_1 # Nasconde la label se acquistato
	$Upgrade1/Sprite2D.visible = not is_purchased_1 # Nasconde la label se acquistato
	
	# Gestione Upgrade 2
	$Upgrade2/Price2.text = str(data["u2"]["costo"])
	$Upgrade2/Price2.visible = not is_purchased_2 # Nasconde la label se acquistato
	$Upgrade2/Sprite2D.visible = not is_purchased_2 # Nasconde la label se acquistato

func _setup_button(btn, info: Dictionary):
	var key = info["key"]
	var is_purchased = GameData.upgrades[key]["purchased"]
	var is_enabled = GameData.upgrades[key]["enabled"]
	
	if is_purchased and is_enabled:
		btn.icon = info["icon_on"]
	else:
		btn.icon = info["icon_off"]
		
	btn.expand_icon = true
	btn.set_pressed_no_signal(is_enabled) 
	btn.disabled = false 

func _handle_upgrade_click(u_id: String, btn: Button, toggled_on: bool):
	var ship_idx = GameData.selected_ship_index
	var data = ship_data[ship_idx][u_id]
	var key = data["key"]
	var is_purchased = GameData.upgrades[key]["purchased"]
	
	if not is_purchased:
		if toggled_on and GameData.spend_monete(data["costo"]):
			GameData.upgrades[key]["purchased"] = true
			GameData.upgrades[key]["enabled"] = true
			
			# AGGIUNTA: Controllo completamento acquisti dopo ogni acquisto andato a buon fine
			GameData.check_completamento_acquisti()
		else:
			print("Monete insufficienti per: ", data["nome"])
			btn.set_pressed_no_signal(false) 
	else:
		GameData.upgrades[key]["enabled"] = toggled_on
		
	GameData.save_data()
	update_ui_elements()

func _on_upgrade_1_toggled(toggled_on: bool) -> void:
	_handle_upgrade_click("u1", upgrade1, toggled_on)

func _on_upgrade_2_toggled(toggled_on: bool) -> void:
	_handle_upgrade_click("u2", upgrade2, toggled_on)

func _on_ritorno_pressed() -> void:
	if nodo.has_method("turn_on"):
		nodo.turn_on(self)
	else:
		self.visible = false
