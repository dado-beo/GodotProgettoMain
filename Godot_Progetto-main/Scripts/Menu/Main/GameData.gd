extends Node

signal monete_aggiornate(nuovo_valore)
signal profile_icon_changed
signal achievement_sbloccato(nome_achievement)

const SAVE_PATH = "user://game_data.save"

var ship_scenes: Array[PackedScene] = [
	preload("res://scenes/Spaceships/Players/StarChaser_Player.tscn"), # Index 0
	preload("res://scenes/Spaceships/Players/Flash_Player.tscn"),      # Index 1
	preload("res://scenes/Spaceships/Players/Aqua.tscn")               # Index 2
]

var selected_ship_scene: PackedScene = ship_scenes[0]
var selected_ship_index: int = 0

# --- GESTIONE SKIN E NAVI ---
var current_icon_index: int = 0
# FIX: Portato a 4 elementi invece di 5
var unlocked_icons: Array = [true, false, false, false] 

var unlocked_ships: Array = [true, false, false] 

# --- DATI DI GIOCO ---
var monete_stella: int = 0
var stelle_totali_ottenute: int = 0 # Serve per l'achievement delle 1000 stelle
var records = { "mode_1": 0, "mode_2": 0, "mode_3": 0.0 }

# --- SISTEMA UPGRADES ---
var upgrades = {
	"triple_shot": {"purchased": false, "enabled": false},
	"speed_boost": {"purchased": false, "enabled": false},
	"homing":      {"purchased": false, "enabled": false},
	"big_bullet":  {"purchased": false, "enabled": false},
	"shield":      {"purchased": false, "enabled": false},
	"super_shield":{"purchased": false, "enabled": false}
}

# ACHIEVEMENTS E STATISTICHE (Contatori Kill separati per nemico)
var kill_kamikaze: int = 0
var kill_ufo: int = 0
var kill_tartarughe: int = 0
var kill_purpleDevil: int = 0

var achievements = {
	"primo_sparo": false,
	"killer_kamikaze": false, 
	"killer_ufo": false, 
	"killer_tartarughe": false, 
	"killer_purpleDevil": false,  
	"secondaMod_MaiColpito": false, 
	"stella_diamante": false,  
	"primoAcquisto": false,
	"tutteLeNavicelle": false, 
	"tutteLeIcone": false 
}

func _ready():
	load_data()

# --- SALVATAGGIO ---
func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"monete_stella": monete_stella,
			"stelle_totali_ottenute": stelle_totali_ottenute,
			"records": records,
			"current_icon_index": current_icon_index,
			"unlocked_icons": unlocked_icons,
			"selected_ship_index": selected_ship_index,
			"unlocked_ships": unlocked_ships,
			"upgrades": upgrades,
			
			# Salvataggio Statistiche Kill
			"kill_kamikaze": kill_kamikaze,
			"kill_ufo": kill_ufo,
			"kill_tartarughe": kill_tartarughe,
			"kill_purpleDevil": kill_purpleDevil,
			
			"achievements": achievements
		}
		file.store_string(JSON.stringify(data))
		file.close()

# --- CARICAMENTO ---
func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return 
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		
		if parse_result == OK:
			var data = json.get_data()
			
			monete_stella = data.get("monete_stella", 5)
			stelle_totali_ottenute = data.get("stelle_totali_ottenute", monete_stella)
			
			current_icon_index = data.get("current_icon_index", 0)
			var loaded_icons = data.get("unlocked_icons", [])
			if loaded_icons.size() > 0: unlocked_icons = loaded_icons
			
			selected_ship_index = data.get("selected_ship_index", 0)
			if selected_ship_index < ship_scenes.size():
				selected_ship_scene = ship_scenes[selected_ship_index]
			
			var loaded_ships = data.get("unlocked_ships", [])
			if loaded_ships.size() > 0: unlocked_ships = loaded_ships
			
			if data.has("records"):
				var loaded_records = data["records"]
				for key in records.keys():
					if loaded_records.has(key): records[key] = loaded_records[key]
			
			if data.has("upgrades"):
				var loaded_upgrades = data["upgrades"]
				for key in upgrades.keys():
					if loaded_upgrades.has(key):
						upgrades[key]["purchased"] = loaded_upgrades[key].get("purchased", false)
						upgrades[key]["enabled"] = loaded_upgrades[key].get("enabled", false)
						
			# Caricamento Statistiche Kill
			kill_kamikaze = data.get("kill_kamikaze", 0)
			kill_ufo = data.get("kill_ufo", 0)
			kill_tartarughe = data.get("kill_tartarughe", 0)
			kill_purpleDevil = data.get("kill_purpleDevil", 0)
			
			if data.has("achievements"):
				var loaded_achievements = data["achievements"]
				for key in achievements.keys():
					if loaded_achievements.has(key): 
						achievements[key] = loaded_achievements[key]
				
		file.close()

# --- ACHIEVEMENTS ---
func sblocca_achievement(id_achievement: String):
	if achievements.has(id_achievement) and achievements[id_achievement] == false:
		achievements[id_achievement] = true
		save_data() 
		emit_signal("achievement_sbloccato", id_achievement)
		print("🏆 ACHIEVEMENT SBLOCCATO: ", id_achievement, "!")

# NUOVA FUNZIONE: Controlla se hai tutte le icone o le navicelle
func check_completamento_acquisti():
	# 1. Controlla le Icone (Devono essere 4 in totale)
	var icone_sbloccate = 0
	for icona in unlocked_icons:
		if icona == true:
			icone_sbloccate += 1
			
	if icone_sbloccate >= 4:
		sblocca_achievement("tutteLeIcone")

	# 2. Controlla le Navicelle (Devono essere 3 in totale)
	var navi_sbloccate = 0
	for nave in unlocked_ships:
		if nave == true:
			navi_sbloccate += 1
			
	if navi_sbloccate >= 3:
		sblocca_achievement("tutteLeNavicelle")

# Funzione Universale per le Kill
func aggiungi_kill(tipo_nemico: String):
	if tipo_nemico == "kamikaze":
		kill_kamikaze += 1
		if kill_kamikaze >= 10: sblocca_achievement("killer_kamikaze")
	elif tipo_nemico == "ufo":
		kill_ufo += 1
		if kill_ufo >= 10: sblocca_achievement("killer_ufo")
	elif tipo_nemico == "tartaruga":
		kill_tartarughe += 1
		if kill_tartarughe >= 10: sblocca_achievement("killer_tartarughe")
	elif tipo_nemico == "purple_devil":
		kill_purpleDevil += 1
		if kill_purpleDevil >= 10: sblocca_achievement("killer_purpleDevil")
		
	save_data()

# --- MONETE ---
func add_monete(amount: int) -> void:
	monete_stella += amount
	stelle_totali_ottenute += amount # Aggiorna il record totale
	
	if stelle_totali_ottenute >= 1000:
		sblocca_achievement("stella_diamante")
		
	save_data()
	emit_signal("monete_aggiornate", monete_stella)

func spend_monete(amount: int) -> bool:
	if monete_stella >= amount:
		monete_stella -= amount
		sblocca_achievement("primoAcquisto") # Sblocca achievement spesa
		save_data()
		emit_signal("monete_aggiornate", monete_stella)
		return true
	else:
		print("Non hai abbastanza monete!")
		return false

# --- RECORDS ---
func check_and_save_record(mode: String, value):
	if value > records.get(mode, 0):
		records[mode] = value
		save_data()

func format_time(seconds) -> String:
	var m = int(seconds) / 60
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]

# --- PLAYER ---
func get_selected_player_scene() -> PackedScene:
	return selected_ship_scene

func set_player_ship(index: int):
	if index < ship_scenes.size():
		selected_ship_index = index
		selected_ship_scene = ship_scenes[index]
		save_data()
