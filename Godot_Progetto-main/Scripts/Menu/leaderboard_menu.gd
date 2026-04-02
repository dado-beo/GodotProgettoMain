extends Control

@onready var label_tempo: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode1
@onready var label_ondate: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode2
@onready var label_record: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode3
@onready var scroll_container = $ScrollContainer
@onready var v_slider = $VSlider 
@onready var scroll_bar = scroll_container.get_v_scroll_bar()
@onready var icona_moneta: Sprite2D = $"../Sprite2D"
@onready var testo_moneta: Label = $"../MoneteLabel"

# Il contenitore vuoto dove inseriremo la lista
@onready var contenitore_achievements: VBoxContainer = $ScrollContainer/ContenitoreScorrevole/ListaObiettivi

# Carichiamo la scena del mattoncino che abbiamo creato
const SCENA_ENTRY = preload("res://scenes/Menu/EntryAchievement.tscn")

# Dizionario dei testi
var testi_achievements = {
	"primo_sparo": {"titolo": "Pew Pew!", "desc": "Hai sparato il tuo primo proiettile!","icona": preload("res://Sprites/Achivments/primo_di_molti.png")},
	"killer_kamikaze": {"titolo": "Esplosivo", "desc": "Hai eliminato 10 Kamikaze!","icona": preload("res://Sprites/Buttons/#TEMP4.png")},
	"killer_ufo": {"titolo": "Area 51", "desc": "Hai distrutto 10 UFO!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"killer_tartarughe": {"titolo": "Donatello", "desc": "Hai eliminato 10 Tartarughe spaziali!","icona": preload("res://Sprites/Buttons/pptout.png")},
	"killer_purpleDevil": {"titolo": "Esorcista Spaziale", "desc": "Hai rimandato a casa 10 Purple Devil!","icona": preload("res://Sprites/Achivments/esorcista.png")},
	"secondaMod_MaiColpito": {"titolo": "Intoccabile", "desc": "Hai completato le Ondate senza subire danni!","icona": preload("res://Sprites/Achivments/intoccabile.png")},
	"stella_diamante": {"titolo": "Zio Paperone", "desc": "Hai raccolto 1000 Stelle totali!","icona": preload("res://Sprites/Achivments/astrofilo.png")},
	"primoAcquisto": {"titolo": "Dollaroni", "desc": "Hai fatto il tuo primo acquisto nel negozio!","icona": preload("res://Sprites/Achivments/spendaccione.png")},
	"tutteLeNavicelle": {"titolo": "Concessionario Stellare", "desc": "Hai sbloccato tutte le navicelle!","icona": preload("res://Sprites/Buttons/pptout.png")}, 
	"tutteLeIcone": {"titolo": "Profilato", "desc": "Hai sbloccato tutte le icone profilo!","icona": preload("res://Sprites/Achivments/galleria_d_arte.png")}
}

func _ready():
	# Nasconde visivamente la barra predefinita, lasciando attiva la funzionalità
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	update_scores()
	visibility_changed.connect(_on_visibility_changed)
	
	# Attende il calcolo delle dimensioni della lista
	await get_tree().process_frame
	_aggiorna_limiti_slider()
	
	if scroll_bar:
		# Quando si usa la rotellina, aggiorna lo slider
		scroll_bar.value_changed.connect(_on_scroll_container_scrolled)
		# Se la lista cambia dimensione, ricalcola i limiti
		scroll_bar.changed.connect(_aggiorna_limiti_slider)
		
	if v_slider:
		# Quando si trascina lo slider, aggiorna la lista
		v_slider.value_changed.connect(_on_vslider_dragged)

func _on_visibility_changed():
	if visible:
		update_scores()
		
		# --- NASCONDE LE MONETE QUANDO ENTRI ---
		if icona_moneta and testo_moneta:
			icona_moneta.visible = false
			testo_moneta.visible = false
			
		# Ricalcola in caso di nuovi sblocchi
		await get_tree().process_frame
		_aggiorna_limiti_slider()
	else:
		# --- MOSTRA LE MONETE QUANDO ESCI ---
		if icona_moneta and testo_moneta:
			icona_moneta.visible = true
			testo_moneta.visible = true

func update_scores():
	# --- 1. AGGIORNA I RECORD ---
	label_tempo.text = "Tempo Sopravvissuto: " + GameData.format_time(GameData.records["mode_1"])
	label_ondate.text = "Ondate Completate: " + str(GameData.records["mode_2"])
	label_record.text = "Record Infinito: " + GameData.format_time(GameData.records["mode_3"])

	# --- 2. AGGIORNA GLI ACHIEVEMENTS ---
	for entry in contenitore_achievements.get_children():
		entry.queue_free()
		
	for id_achievement in testi_achievements.keys():
		var dati = testi_achievements[id_achievement]
		var is_sbloccato = GameData.achievements.get(id_achievement, false)
		
		var nuova_entry = SCENA_ENTRY.instantiate()
		nuova_entry.get_node("Testi/Titolo").text = dati["titolo"]
		
		# --- MODIFICA APPLICATA: Assegniamo l'icona dal dizionario! ---
		nuova_entry.get_node("Icona").texture = dati["icona"]
		
		if is_sbloccato:
			nuova_entry.get_node("Testi/Descrizione").text = dati["desc"]
			nuova_entry.modulate = Color(1, 1, 1)
		else:
			nuova_entry.get_node("Testi/Titolo").text += " (Bloccato)"
			nuova_entry.get_node("Testi/Descrizione").text = "Continua a giocare per sbloccare!"
			nuova_entry.modulate = Color(0.4, 0.4, 0.4)
			
		contenitore_achievements.add_child(nuova_entry)

# --- FUNZIONI DI SINCRONIZZAZIONE SCROLLCONTAINER <-> VSLIDER ---

func _aggiorna_limiti_slider():
	if not scroll_bar or not v_slider:
		return
		
	var max_scroll = scroll_bar.max_value - scroll_bar.page
	
	if max_scroll <= 0:
		v_slider.hide()
	else:
		v_slider.show()
		v_slider.max_value = max_scroll
		v_slider.page = scroll_bar.page

func _on_scroll_container_scrolled(value: float):
	if v_slider:
		# Evita che l'impostazione generi un segnale di ritorno (loop)
		v_slider.set_value_no_signal(value)

func _on_vslider_dragged(value: float):
	if scroll_container:
		scroll_container.scroll_vertical = int(value)

# --- TASTO INDIETRO ---
func _on_back_pressed() -> void:
	get_parent().switch_view("main")
