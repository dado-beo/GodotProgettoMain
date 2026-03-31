extends Control


@onready var label_tempo: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode1
@onready var label_ondate: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode2
@onready var label_record: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode3

# Il contenitore vuoto dove inseriremo la lista
@onready var contenitore_achievements: VBoxContainer = $ScrollContainer/ContenitoreScorrevole/ListaObiettivi

# Carichiamo la scena del mattoncino che abbiamo creato (ATTENZIONE: controlla che il percorso sia giusto!)
const SCENA_ENTRY = preload("res://scenes/Menu/EntryAchievement.tscn")

# Dizionario dei testi
var testi_achievements = {
	"primo_sparo": {"titolo": "Pew Pew!", "desc": "Hai sparato il tuo primo proiettile!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"killer_kamikaze": {"titolo": "Esplosivo", "desc": "Hai eliminato 10 Kamikaze!","icona": preload("res://Sprites/Buttons/#TEMP4.png")},
	"killer_ufo": {"titolo": "Area 51", "desc": "Hai distrutto 10 UFO!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"killer_tartarughe": {"titolo": "Donatello", "desc": "Hai eliminato 10 Tartarughe spaziali!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"killer_purpleDevil": {"titolo": "Esorcista Spaziale", "desc": "Hai rimandato a casa 10 Purple Devil!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"secondaMod_MaiColpito": {"titolo": "Intoccabile", "desc": "Hai completato le Ondate senza subire danni!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"stella_diamante": {"titolo": "Zio Paperone", "desc": "Hai raccolto 1000 Stelle totali!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"primoAcquisto": {"titolo": "Dollaroni", "desc": "Hai fatto il tuo primo acquisto nel negozio!","icona": preload("res://Sprites/Buttons/spendaccione.png")},
	"tutteLeNavicelle": {"titolo": "Concessionario Stellare", "desc": "Hai sbloccato tutte le navicelle!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"tutteLeIcone": {"titolo": "Profilato", "desc": "Hai sbloccato tutte le icone profilo!","icona": preload("res://Sprites/Buttons/galleria_d_arte.png")}
}

func _ready():
	update_scores()
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		update_scores()

func update_scores():
	# --- 1. AGGIORNA I RECORD ---
	label_tempo.text = "Tempo Sopravvissuto: " + GameData.format_time(GameData.records["mode_1"])
	label_ondate.text = "Ondate Completate: " + str(GameData.records["mode_2"])
	label_record.text = "Record Infinito: " + GameData.format_time(GameData.records["mode_3"])

	# --- 2. AGGIORNA GLI ACHIEVEMENTS ---
	
	# Pulisce la lista prima di rigenerarla
	for entry in contenitore_achievements.get_children():
		entry.queue_free()
		
	# Cicla attraverso il dizionario
	for id_achievement in testi_achievements.keys():
		var dati = testi_achievements[id_achievement]
		var is_sbloccato = GameData.achievements.get(id_achievement, false)
		
		# Crea una copia della scena EntryAchievement
		var nuova_entry = SCENA_ENTRY.instantiate()
		
		# IMPOSTA I TESTI E L'IMMAGINE
		nuova_entry.get_node("Testi/Titolo").text = dati["titolo"]
		
		# INSERISCI QUI IL PERCORSO DI UN'IMMAGINE PROVVISORIA (es. il tuo asteroide)
		# Assicurati che il percorso tra le virgolette sia corretto e punti a un'immagine che esiste!
		var immagine_default = load("res://Sprites/Asteroids/AsteroidBase.png")
		nuova_entry.get_node("Icona").texture = immagine_default
		
		# Se sbloccato mostra la descrizione vera
		if is_sbloccato:
			nuova_entry.get_node("Testi/Descrizione").text = dati["desc"]
			nuova_entry.modulate = Color(1, 1, 1) # Colore normale
		else:
			nuova_entry.get_node("Testi/Titolo").text += " (Bloccato)"
			nuova_entry.get_node("Testi/Descrizione").text = "Continua a giocare per sbloccare!"
			nuova_entry.modulate = Color(0.4, 0.4, 0.4) # Grigio scuro per i bloccati
			
		# Aggiunge la voce alla lista visibile
		contenitore_achievements.add_child(nuova_entry)

# --- TASTO INDIETRO ---
func _on_back_pressed() -> void:
	# Chiama la funzione switch_view del tuo Main_Menu.gd per tornare alla Home!
	get_parent().switch_view("main")
