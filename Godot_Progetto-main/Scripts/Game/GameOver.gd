extends CanvasLayer 

# --- REFERENZE ---
@onready var label_titolo: Label = $Panel/VBoxContainer/TitoloLabel
@onready var label_frase: Label = $Panel/VBoxContainer/FraseLabel
@onready var label_tempo: Label = $Panel/VBoxContainer/TempoLabel
@onready var label_uccisioni: Label = $Panel/VBoxContainer/UccisioniLabel
@onready var label_biscotti: Label = $Panel/VBoxContainer/BiscottiLabel # <-- MODIFICATO

# --- NODI DEL TEASER (Lista Verticale) ---
@onready var teaser_container = $Panel/VBoxContainer/TeaserContainer
@onready var teaser_frase = $Panel/VBoxContainer/TeaserContainer/TeaserFrase

# Nodi Costume
@onready var box_costume = $Panel/VBoxContainer/TeaserContainer/BoxCostume
@onready var btn_costume = box_costume.get_node("BtnCostume")
@onready var testo_costume = box_costume.get_node("TestoCostume")

# Nodi Upgrade
@onready var box_upgrade = $Panel/VBoxContainer/TeaserContainer/BoxUpgrade
@onready var btn_upgrade = box_upgrade.get_node("BtnUpgrade")
@onready var testo_upgrade = box_upgrade.get_node("TestoUpgrade")

# Nodi Icona
@onready var box_icona = $Panel/VBoxContainer/TeaserContainer/BoxIcona
@onready var btn_icona = box_icona.get_node("BtnIcona")
@onready var testo_icona = box_icona.get_node("TestoIcona")

@onready var replay: Button = $Panel/Replay
@onready var menu: Button = $Panel/Menu

var frasi_sconfitta = [
	"Non sbriciolarti ora!", 
	"La frolla cosmica si e' spezzata!", 
	"Troppo inzuppo gravitazionale!",
	"Il tuo biscotto\ne' andato in frantumi!",
	"Un pasticciere spaziale non\nsi arrende mai!"
]
var frasi_vittoria = [
	"Biscotto temperato \nalla perfezione!", "Hai salvato la frolla cosmica!"
]

func _ready() -> void:
	if label_titolo:
		var blink_tween = create_tween().set_loops()
		blink_tween.tween_property(label_titolo, "modulate:a", 0.0, 0.8)
		blink_tween.tween_property(label_titolo, "modulate:a", 1.0, 0.8)

func setup_game_over(biscotti: int, uccisioni: int, tempo_testo: String, survived: bool) -> void: # <-- MODIFICATO
	label_tempo.text = tempo_testo
	label_uccisioni.text = "Nemici Distrutti: " + str(uccisioni)
	label_biscotti.text = "Biscotti Ottenuti: " + str(biscotti) # <-- MODIFICATO
	
	if survived:
		label_titolo.text = "VITTORIA!"
		label_frase.text = frasi_vittoria.pick_random()
		label_frase.modulate = Color(1, 0.8, 0)
	else:
		label_titolo.text = "GAME OVER" # <-- NUOVO: Mantiene Game Over in caso di sconfitta
		label_frase.text = frasi_sconfitta.pick_random()
		label_frase.modulate = Color(1, 0.3, 0.3) 
		
		if label_frase:
			var blink_tween_frase = create_tween().set_loops()
			blink_tween_frase.tween_property(label_frase, "modulate:a", 0.0, 0.8)
			blink_tween_frase.tween_property(label_frase, "modulate:a", 1.0, 0.8)
			
	_genera_teaser_negozio(biscotti) 
		
# --- SISTEMA TEASER A LISTA ---
func _genera_teaser_negozio(biscotti_partita: int): # <-- MODIFICATO
	var costumi_mancanti = []
	var upgrades_mancanti = []
	var icone_mancanti = []
	
	# 1. Trova COSTUMI mancanti
	if GameData.unlocked_ships.size() > 1 and GameData.unlocked_ships[1] == false:
		costumi_mancanti.append({"costo": 60, "img": preload("res://Sprites/Buttons/ship2_background(1).png")})
	if GameData.unlocked_ships.size() > 2 and GameData.unlocked_ships[2] == false:
		costumi_mancanti.append({"costo": 80, "img": preload("res://Sprites/Buttons/ship3_background.png")})

	# 2. Trova UPGRADES mancanti (per la nave attuale)
	var nave_attuale = GameData.selected_ship_index 
	match nave_attuale:
		0:
			if GameData.upgrades["triple_shot"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 60, "img": preload("res://Sprites/Buttons/triple_shoot_on.png")})
			if GameData.upgrades["speed_boost"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 100, "img": preload("res://Sprites/Buttons/speed_boost_on.png")})
		1:
			if GameData.upgrades["homing"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 100, "img": preload("res://Sprites/Buttons/homing_target_on.png")})
			if GameData.upgrades["big_bullet"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 140, "img": preload("res://Sprites/Buttons/charged_shot_on.png")})
		2:
			if GameData.upgrades["shield"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 120, "img": preload("res://Sprites/Buttons/vampirism_on.png")})
			if GameData.upgrades["super_shield"]["purchased"] == false:
				upgrades_mancanti.append({"costo": 160, "img": preload("res://Sprites/Buttons/bouncing_shield_on.png")})

	# 3. Trova ICONE mancanti
	if GameData.unlocked_icons.size() > 1 and GameData.unlocked_icons[1] == false:
		icone_mancanti.append({"costo": 5, "img": preload("res://Sprites/Buttons/#TEMP1.png")})
	if GameData.unlocked_icons.size() > 2 and GameData.unlocked_icons[2] == false:
		icone_mancanti.append({"costo": 20, "img": preload("res://Sprites/Buttons/#TEMP2.png")})
	if GameData.unlocked_icons.size() > 3 and GameData.unlocked_icons[3] == false:
		icone_mancanti.append({"costo": 100, "img": preload("res://Sprites/Buttons/#TEMP3.png")})
	if GameData.unlocked_icons.size() > 4 and GameData.unlocked_icons[4] == false:
		icone_mancanti.append({"costo": 35, "img": preload("res://Sprites/Buttons/#TEMP4.png")})
		
	# Estraiamo un elemento a caso per ogni categoria
	var costume_scelto = costumi_mancanti.pick_random() if costumi_mancanti.size() > 0 else null
	var upgrade_scelto = upgrades_mancanti.pick_random() if upgrades_mancanti.size() > 0 else null
	var icona_scelta = icone_mancanti.pick_random() if icone_mancanti.size() > 0 else null
	
	if costume_scelto == null and upgrade_scelto == null and icona_scelta == null:
		teaser_container.visible = false
		return
		
	# --- AGGIORNAMENTO UI E CALCOLO FRASI ---
	# Qui passiamo anche i biscotti_partita alla funzione che crea la frase
	if costume_scelto:
		box_costume.visible = true
		btn_costume.texture_normal = costume_scelto["img"]
		testo_costume.text = _get_frase_oggetto("Costumi", costume_scelto["costo"], biscotti_partita) # <-- MODIFICATO
	else:
		box_costume.visible = false 
		
	if upgrade_scelto:
		box_upgrade.visible = true
		btn_upgrade.texture_normal = upgrade_scelto["img"]
		testo_upgrade.text = _get_frase_oggetto("Upgrades", upgrade_scelto["costo"], biscotti_partita) # <-- MODIFICATO
	else:
		box_upgrade.visible = false
		
	if icona_scelta:
		box_icona.visible = true
		btn_icona.texture_normal = icona_scelta["img"]
		testo_icona.text = _get_frase_oggetto("Icone", icona_scelta["costo"], biscotti_partita) # <-- MODIFICATO
	else:
		box_icona.visible = false

	# Frase titolo generica
	teaser_frase.text = "Nuovi oggetti ti aspettano al negozio!"
	teaser_frase.modulate = Color(1, 0.9, 0)

# Funzione che calcola i biscotti mancanti e genera la frase per ogni riga
func _get_frase_oggetto(tab: String, costo: int, biscotti_partita: int) -> String: # <-- MODIFICATO
	
	# USA DIRETTAMENTE IL VALORE DI GAMEDATA (non sommare nulla!)
	var biscotti_reali = GameData.biscotti # <-- MODIFICATO
	
	var puo_comprare = (biscotti_reali >= costo)
	var biscotti_mancanti = costo - biscotti_reali # <-- MODIFICATO
	var frasi = []
	
	if puo_comprare:
		match tab:
			"Costumi": frasi = ["Hai i fondi per questa bellezza!", "È il momento di sbloccarla!"]
			"Upgrades": frasi = ["Te lo puoi permettere!", "Sblocco disponibile!"]
			"Icone": frasi = ["Biscotti sufficienti!", "Nuovo stile pronto!"] # <-- MODIFICATO
	else:
		match tab:
			"Costumi": frasi = ["Ti mancano %d biscotti!" % biscotti_mancanti, "Quasi tua, mancano %d biscotti!" % biscotti_mancanti] # <-- MODIFICATO
			"Upgrades": frasi = ["Ancora %d biscotti e sarà tuo!" % biscotti_mancanti] # <-- MODIFICATO
			"Icone": frasi = ["A %d biscotti dal nuovo stile!" % biscotti_mancanti] # <-- MODIFICATO
			
	return frasi.pick_random() + "\nPrezzo: " + str(costo)


# --- NUOVI SEGNALI DEI 3 BOTTONI ---
func _on_btn_costume_pressed() -> void:
	GameData.tab_negozio_da_aprire = "Costumi"
	_on_menu_pressed()

func _on_btn_upgrade_pressed() -> void:
	GameData.tab_negozio_da_aprire = "Upgrades"
	_on_menu_pressed()

func _on_btn_icona_pressed() -> void:
	GameData.tab_negozio_da_aprire = "Icone"
	_on_menu_pressed()

# --- GESTIONE BOTTONI NORMALI ---
func _on_replay_pressed() -> void:
	# Otteniamo il percorso della scena in cui ci troviamo attualmente (Endless, Waves, o Classica)
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		# Usiamo la tua transizione fluida passandole la scena corrente
		FadeTransition.change_scene(current_scene_path)
	else:
		# Metodo di riserva super sicuro di Godot per ricaricare la scena attuale
		get_tree().reload_current_scene()
	
func _on_menu_pressed() -> void:
	if FileAccess.file_exists("res://scenes/AnimationAddOn/fade_transition.tscn"):
		FadeTransition.change_scene("res://scenes/Menu/Main_Menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Menu/Main_Menu.tscn")
