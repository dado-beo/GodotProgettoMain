extends Node

signal biscotti_aggiornati(nuovo_valore)
signal profile_icon_changed
signal achievement_sbloccato(nome_achievement)
signal dati_aggiornati

const SAVE_PATH = "user://game_data.save"

var volume_music: float = 1.0
var volume_sfx: float = 1.0

# --- DATI ACCOUNT ---
var current_user_id: String = ""
var current_username: String = ""

func format_time(seconds) -> String:
	var m = int(seconds) / 60
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]

var ship_scenes: Array[PackedScene] = [
	preload("res://scenes/Spaceships/Players/StarChaser_Player.tscn"),
	preload("res://scenes/Spaceships/Players/Flash_Player.tscn"),
	preload("res://scenes/Spaceships/Players/Aqua.tscn")
]

var selected_ship_scene: PackedScene = ship_scenes[0]
var selected_ship_index: int = 0
var tab_negozio_da_aprire: String = ""

# --- GESTIONE SKIN E NAVI ---
var current_icon_index: int = 0
var unlocked_icons = [true, false, false, false, false]
var unlocked_ships: Array = [true, false, false] 

# --- DATI DI GIOCO (Biscotti Edition 🍪) ---
var biscotti: int = 0
var biscotti_totali_ottenuti: int = 0
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

# STATISTICHE KILL
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
	"biscotto_diamante": false,
	"primoAcquisto": false,
	"tutteLeNavicelle": false, 
	"tutteLeIcone": false  
}

func _ready():
	load_data()

func test_account_sync():
	# Diamo le monete di prova
	biscotti += 1000
	biscotti_totali_ottenuti += 1000
	
	# Salviamo e carichiamo su Firebase
	# Usiamo 'true' perché nel tuo script save_data(true) attiva l'upload
	save_data(true)
	
	print("TEST: 1000 monete aggiunte e inviate al Cloud!")

# --- SALVATAGGIO LOCALE + OPZIONE CLOUD ---
func save_data(sync_cloud: bool = false):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"biscotti": biscotti, 
			"biscotti_totali_ottenuti": biscotti_totali_ottenuti,
			"records": records,
			"current_icon_index": current_icon_index,
			"unlocked_icons": unlocked_icons,
			"selected_ship_index": selected_ship_index,
			"unlocked_ships": unlocked_ships,
			"upgrades": upgrades,
			"kill_kamikaze": kill_kamikaze,
			"kill_ufo": kill_ufo,
			"kill_tartarughe": kill_tartarughe,
			"kill_purpleDevil": kill_purpleDevil,
			"achievements": achievements,
			"volume_music": volume_music,
			"volume_sfx": volume_sfx,
			# Dati Account
			"current_user_id": current_user_id,
			"current_username": current_username
		}
		file.store_string(JSON.stringify(data))
		file.close()
	
	# Se richiesto, ed esiste un account valido connesso, lancia lo specchio sul Cloud
	if sync_cloud and current_user_id != "":
		sync_to_cloud()
	dati_aggiornati.emit()

# --- FUNZIONE DI SINCRONIZZAZIONE GENERALE ---
func sync_to_cloud():
	if current_user_id == "": return
	
	var dati_cloud = {
		"nome_utente": current_username,
		"biscotti": biscotti,
		"biscotti_totali_ottenuti": biscotti_totali_ottenuti,
		"records": records,
		"current_icon_index": current_icon_index,
		"unlocked_icons": unlocked_icons,
		"selected_ship_index": selected_ship_index,
		"unlocked_ships": unlocked_ships,
		"upgrades": upgrades,
		"kill_kamikaze": kill_kamikaze,
		"kill_ufo": kill_ufo,
		"kill_tartarughe": kill_tartarughe,
		"kill_purpleDevil": kill_purpleDevil,
		"achievements": achievements
	}
	
	var database_reference = Firebase.Firestore.collection("giocatori")
	var documento = FirestoreDocument.new()
	documento.doc_name = current_user_id
	documento.doc_fields = dati_cloud
	database_reference.update(documento)
	print("🔄 Sincronizzazione cloud completata per l'utente: ", current_username)

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
			
			biscotti = data.get("biscotti", data.get("monete_stella", 5))
			biscotti_totali_ottenuti = data.get("biscotti_totali_ottenuti", biscotti)
			current_icon_index = data.get("current_icon_index", 0)
			unlocked_icons = data.get("unlocked_icons", [true, false, false, false, false])
			selected_ship_index = data.get("selected_ship_index", 0)
			
			if selected_ship_index < ship_scenes.size():
				selected_ship_scene = ship_scenes[selected_ship_index]
			
			unlocked_ships = data.get("unlocked_ships", [true, false, false])
			
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
						
			kill_kamikaze = data.get("kill_kamikaze", 0)
			kill_ufo = data.get("kill_ufo", 0)
			kill_tartarughe = data.get("kill_tartarughe", 0)
			kill_purpleDevil = data.get("kill_purpleDevil", 0)
			
			if data.has("achievements"):
				var loaded_achievements = data["achievements"]
				for key in achievements.keys():
					if loaded_achievements.has(key): 
						achievements[key] = loaded_achievements[key]
			
			volume_music = data.get("volume_music", 1.0)
			volume_sfx = data.get("volume_sfx", 1.0)
			
			var music_idx = AudioServer.get_bus_index("Music")
			var sfx_idx = AudioServer.get_bus_index("SFX")
			if music_idx != -1: AudioServer.set_bus_volume_db(music_idx, linear_to_db(volume_music))
			if sfx_idx != -1: AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(volume_sfx))
			
			# Caricamento Account
			current_user_id = data.get("current_user_id", "")
			current_username = data.get("current_username", "")
				
		file.close()

# --- EFFETTUA LOGOUT ED AZZERA I DATI LOCALI PER IL NUOVO OSPITE ---
func esegui_logout() -> void:
	current_user_id = ""
	current_username = ""
	
	# Reset totale di gioco ai valori iniziali di un Ospite pulito
	biscotti = 0
	biscotti_totali_ottenuti = 0
	current_icon_index = 0
	unlocked_icons = [true, false, false, false, false]
	selected_ship_index = 0
	selected_ship_scene = ship_scenes[0]
	unlocked_ships = [true, false, false]
	records = { "mode_1": 0, "mode_2": 0, "mode_3": 0.0 }
	kill_kamikaze = 0
	kill_ufo = 0
	kill_tartarughe = 0
	kill_purpleDevil = 0
	
	for key in upgrades.keys():
		upgrades[key]["purchased"] = false
		upgrades[key]["enabled"] = false
	for key in achievements.keys():
		achievements[key] = false
		
	save_data() # Salva il file locale vuoto
	Firebase.Auth.logout() # Scollega le credenziali nel dispositivo
	emit_signal("biscotti_aggiornati", biscotti)
	print("🚫 Logout eseguito. Il file locale è stato resettato per un nuovo Ospite.")

func sblocca_achievement(id_achievement: String):
	if achievements.has(id_achievement) and achievements[id_achievement] == false:
		achievements[id_achievement] = true
		save_data(true) # Sincronizza l'achievement sbloccato nel Cloud
		emit_signal("achievement_sbloccato", id_achievement)

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
	save_data() # Salvataggio standard locale delle statistiche

func add_biscotti(amount: int) -> void:
	biscotti += amount
	biscotti_totali_ottenuti += amount
	if biscotti_totali_ottenuti >= 1000: sblocca_achievement("biscotto_diamante")
	save_data() # Nota: per i biscotti singoli salviamo solo in locale per non sovraccaricare Firebase. 
	emit_signal("biscotti_aggiornati", biscotti)

func spend_biscotti(amount: int) -> bool:
	if biscotti >= amount:
		biscotti -= amount
		sblocca_achievement("primoAcquisto")
		save_data(true) # Importante: Sincronizziamo l'acquisto (es: nel Negozio) subito sul Cloud!
		emit_signal("biscotti_aggiornati", biscotti)
		return true
	return false

# --- GESTIONE STATO UPGRADE ---
func imposta_stato_upgrade(id_upgrade: String, abilitato: bool) -> void:
	if upgrades.has(id_upgrade):
		# Controlliamo che il giocatore lo abbia effettivamente comprato prima di poterlo attivare
		if abilitato and not upgrades[id_upgrade]["purchased"]:
			print("Errore: Impossibile attivare un upgrade non acquistato.")
			return
			
		upgrades[id_upgrade]["enabled"] = abilitato
		
		# IL SEGRETO: Salviamo e inviamo immediatamente il nuovo stato al Cloud!
		save_data(true) 
		print("Upgrade '", id_upgrade, "' impostato su: ", abilitato)
	else:
		push_error("L'upgrade '" + id_upgrade + "' non esiste nel database!")

func check_and_save_record(mode: String, value):
	if value > records.get(mode, 0):
		records[mode] = value
		save_data(true) # Sincronizziamo il nuovo Record sul Cloud!

func get_selected_player_scene() -> PackedScene:
	return selected_ship_scene

func set_player_ship(index: int):
	if index < ship_scenes.size():
		selected_ship_index = index
		selected_ship_scene = ship_scenes[index]
		save_data(true) # Sincronizziamo il cambio navicella sul Cloud!

func reset_to_guest() -> void:
	current_user_id = ""
	current_username = "Ospite"
	
	biscotti = 0
	biscotti_totali_ottenuti = 0
	current_icon_index = 0
	selected_ship_index = 0
	
	unlocked_icons = [true, false, false, false, false] 
	unlocked_ships = [true, false, false]
	
	# Struttura fissa per i record
	records = {
		"mode_1": 0.0,
		"mode_2": 0,
		"mode_3": 0.0
	}
	
	achievements = {}
	
	upgrades = {
		"triple_shot": {"purchased": false, "enabled": false},
		"speed_boost": {"purchased": false, "enabled": false},
		"homing": {"purchased": false, "enabled": false},
		"big_bullet": {"purchased": false, "enabled": false},
		"shield": {"purchased": false, "enabled": false},
		"super_shield": {"purchased": false, "enabled": false}
	}
	
	if ship_scenes.size() > 0:
		selected_ship_scene = ship_scenes[0]
	
	save_data(false) 
	print("Dati resettati.")
