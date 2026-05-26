extends Control

@onready var label_tempo: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode1
@onready var label_ondate: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode2
@onready var label_record: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode3
@onready var scroll_container = $ScrollContainer
@onready var icona_moneta: Sprite2D = $"../Sprite2D"
@onready var testo_moneta: Label = $"../BiscottiLabel"

@onready var tasto_logout: Button = $Logout

@onready var contenitore_achievements: VBoxContainer = $ScrollContainer/ContenitoreScorrevole/ListaObiettivi
const SCENA_ENTRY = preload("res://scenes/Menu/EntryAchievement.tscn")

var testi_achievements = {
	"primo_sparo": {"titolo": "Pew Pew!", "desc": "Hai sparato il tuo primo proiettile!","icona": preload("res://Sprites/Achivments/primo_di_molti.png"), "target": 1},
	"killer_kamikaze": {"titolo": "Esplosivo", "desc": "Hai eliminato 10 Kamikaze!","icona": preload("res://Sprites/Achivments/esplosivo.png"), "target": 10},
	"killer_ufo": {"titolo": "Area 51", "desc": "Hai distrutto 10 UFO!","icona": preload("res://Sprites/Achivments/area51.png"), "target": 10},
	"killer_tartarughe": {"titolo": "Donatello", "desc": "Hai eliminato 10 Tartarughe spaziali!","icona": preload("res://Sprites/Achivments/donatello.png"), "target": 10},
	"killer_purpleDevil": {"titolo": "Esorcista Spaziale", "desc": "Hai rimandato a casa 10 Purple Devil!","icona": preload("res://Sprites/Achivments/esorcista.png"), "target": 10},
	"secondaMod_MaiColpito": {"titolo": "Intoccabile", "desc": "Hai completato le Ondate senza subire danni!","icona": preload("res://Sprites/Achivments/intoccabile.png"), "target": 1},
	"biscotto_diamante": {"titolo": "Zio Paperone", "desc": "Hai raccolto 1000 Biscotti totali!","icona": preload("res://Sprites/Achivments/astrofilo.png"), "target": 1000},
	"primoAcquisto": {"titolo": "Dollaroni", "desc": "Hai fatto il tuo primo acquisto nel negozio!","icona": preload("res://Sprites/Achivments/spendaccione.png"), "target": 1},
	"tutteLeNavicelle": {"titolo": "Concessionario Stellare", "desc": "Hai sbloccato tutte le navicelle!","icona": preload("res://Sprites/Achivments/collezionista_di_lusso.png"), "target": 3},
	"tutteLeIcone": {"titolo": "Profilato", "desc": "Hai sbloccato tutte le icone profilo!","icona": preload("res://Sprites/Achivments/galleria_d_arte.png"), "target": 4}
}

func _ready():
	# Nasconde la barra predefinita brutta, ma mantiene attivo lo scorrimento
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	update_scores()
	visibility_changed.connect(_on_visibility_changed)
	
	await get_tree().process_frame
	
	if tasto_logout and not tasto_logout.pressed.is_connected(_on_logout_pressed):
		tasto_logout.pressed.connect(_on_logout_pressed)
	
	if not Firebase.Auth.logged_out.is_connected(_on_logout_confirm):
		Firebase.Auth.logged_out.connect(_on_logout_confirm)

func _on_visibility_changed():
	if visible:
		update_scores()
		
		if Firebase.Auth.auth.is_empty():
			tasto_logout.visible = false
		else:
			tasto_logout.visible = true
			
		if icona_moneta and testo_moneta:
			icona_moneta.visible = false
			testo_moneta.visible = false
			
		await get_tree().process_frame
	else:
		if icona_moneta and testo_moneta:
			icona_moneta.visible = true
			testo_moneta.visible = true

func update_scores():
	label_tempo.text = "Tempo Sopravvissuto: " + GameData.format_time(GameData.records["mode_1"])
	label_ondate.text = "Ondate Completate: " + str(GameData.records["mode_2"])
	label_record.text = "Record Infinito: " + GameData.format_time(GameData.records["mode_3"])

	for entry in contenitore_achievements.get_children():
		entry.queue_free()
		
	for id_achievement in testi_achievements.keys():
		var dati = testi_achievements[id_achievement]
		var is_sbloccato = GameData.achievements.get(id_achievement, false)
		
		var nuova_entry = SCENA_ENTRY.instantiate()
		nuova_entry.get_node("Testi/Titolo").text = dati["titolo"]
		nuova_entry.get_node("Icona").texture = dati["icona"]
		
		if is_sbloccato:
			nuova_entry.get_node("Testi/Descrizione").text = dati["desc"]
			nuova_entry.modulate = Color(1, 1, 1)
		else:
			nuova_entry.get_node("Testi/Titolo").text += " (Bloccato)"
			nuova_entry.modulate = Color(0.4, 0.4, 0.4)
			
			var target = dati.get("target", 1)
			
			if target > 1:
				var progresso_attuale = 0
				match id_achievement:
					"killer_kamikaze": progresso_attuale = GameData.kill_kamikaze
					"killer_ufo": progresso_attuale = GameData.kill_ufo
					"killer_tartarughe": progresso_attuale = GameData.kill_tartarughe
					"killer_purpleDevil": progresso_attuale = GameData.kill_purpleDevil
					"biscotto_diamante": progresso_attuale = GameData.biscotti_totali_ottenuti
					"tutteLeNavicelle":
						progresso_attuale = 0
						for n in GameData.unlocked_ships:
							if n: progresso_attuale += 1
					"tutteLeIcone":
						progresso_attuale = 0
						for i in GameData.unlocked_icons:
							if i: progresso_attuale += 1
				
				progresso_attuale = min(progresso_attuale, target)
				nuova_entry.get_node("Testi/Descrizione").text = dati["desc"] + " [" + str(progresso_attuale) + "/" + str(target) + "]"
			else:
				nuova_entry.get_node("Testi/Descrizione").text = dati["desc"]
			
		contenitore_achievements.add_child(nuova_entry)

func _on_back_pressed() -> void:
	get_parent().switch_view("main")

# --- GESTIONE LOGOUT ---
func _on_logout_pressed() -> void:
	tasto_logout.disabled = true 
	print("Richiesta di logout in corso...")
	if GameData.has_method("esegui_logout"):
		GameData.esegui_logout()
	else:
		Firebase.Auth.logout()

func _on_logout_confirm() -> void:
	print("Logout confermato!")
	tasto_logout.disabled = false 
	
	if get_parent().has_method("switch_view"):
		get_parent().switch_view("main")
