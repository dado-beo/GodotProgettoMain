extends Control

@onready var label_tempo: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode1
@onready var label_ondate: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode2
@onready var label_record: Label = $ScrollContainer/ContenitoreScorrevole/Stats/Lbl_Mode3
@onready var scroll_container = $ScrollContainer
@onready var v_slider = $VSlider 
@onready var scroll_bar = scroll_container.get_v_scroll_bar()
@onready var icona_moneta: Sprite2D = $"../Sprite2D"
@onready var testo_moneta: Label = $"../MoneteLabel"

@onready var contenitore_achievements: VBoxContainer = $ScrollContainer/ContenitoreScorrevole/ListaObiettivi
const SCENA_ENTRY = preload("res://scenes/Menu/EntryAchievement.tscn")

var testi_achievements = {
	"primo_sparo": {"titolo": "Pew Pew!", "desc": "Hai sparato il tuo primo proiettile!","icona": preload("res://Sprites/Achivments/primo_di_molti.png"), "target": 1},
	"killer_kamikaze": {"titolo": "Esplosivo", "desc": "Hai eliminato 10 Kamikaze!","icona": preload("res://Sprites/Achivments/esplosivo.png"), "target": 10},
	"killer_ufo": {"titolo": "Area 51", "desc": "Hai distrutto 10 UFO!","icona": preload("res://Sprites/Buttons/pptout.png"), "target": 10},
	"killer_tartarughe": {"titolo": "Donatello", "desc": "Hai eliminato 10 Tartarughe spaziali!","icona": preload("res://Sprites/Achivments/donatello.png"), "target": 10},
	"killer_purpleDevil": {"titolo": "Esorcista Spaziale", "desc": "Hai rimandato a casa 10 Purple Devil!","icona": preload("res://Sprites/Achivments/esorcista.png"), "target": 10},
	"secondaMod_MaiColpito": {"titolo": "Intoccabile", "desc": "Hai completato le Ondate senza subire danni!","icona": preload("res://Sprites/Achivments/intoccabile.png"), "target": 1},
	"stella_diamante": {"titolo": "Zio Paperone", "desc": "Hai raccolto 1000 Stelle totali!","icona": preload("res://Sprites/Achivments/astrofilo.png"), "target": 1000},
	"primoAcquisto": {"titolo": "Dollaroni", "desc": "Hai fatto il tuo primo acquisto nel negozio!","icona": preload("res://Sprites/Achivments/spendaccione.png"), "target": 1},
	"tutteLeNavicelle": {"titolo": "Concessionario Stellare", "desc": "Hai sbloccato tutte le navicelle!","icona": preload("res://Sprites/Achivments/collezionista_di_lusso.png"), "target": 3},
	"tutteLeIcone": {"titolo": "Profilato", "desc": "Hai sbloccato tutte le icone profilo!","icona": preload("res://Sprites/Achivments/galleria_d_arte.png"), "target": 4}
}

func _ready():
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	update_scores()
	visibility_changed.connect(_on_visibility_changed)
	
	await get_tree().process_frame
	_aggiorna_limiti_slider()
	
	if scroll_bar:
		scroll_bar.value_changed.connect(_on_scroll_container_scrolled)
		scroll_bar.changed.connect(_aggiorna_limiti_slider)
		
	if v_slider:
		v_slider.value_changed.connect(_on_vslider_dragged)

func _on_visibility_changed():
	if visible:
		update_scores()
		if icona_moneta and testo_moneta:
			icona_moneta.visible = false
			testo_moneta.visible = false
			
		await get_tree().process_frame
		_aggiorna_limiti_slider()
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
					"stella_diamante": progresso_attuale = GameData.stelle_totali_ottenute
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
		v_slider.set_value_no_signal(value)

func _on_vslider_dragged(value: float):
	if scroll_container:
		scroll_container.scroll_vertical = int(value)

func _on_back_pressed() -> void:
	get_parent().switch_view("main")
