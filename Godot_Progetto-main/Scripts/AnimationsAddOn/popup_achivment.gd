extends CanvasLayer

@onready var contenitore = $Contenitore
@onready var lbl_titolo = $Contenitore/HBoxContainer/VBoxContainer/Titolo
@onready var lbl_descrizione = $Contenitore/HBoxContainer/VBoxContainer/Descrizione
@onready var icona_achievement = $Contenitore/HBoxContainer/TextureRect

# dizionario
var testi_achievements = {

"primo_sparo": {"titolo": "Pew Pew!", "desc": "Hai sparato il tuo primo proiettile!", "icona": null},

"killer_kamikaze": {"titolo": "Esplosivo", "desc": "Hai eliminato 10 Kamikaze!", "icona": preload("res://Sprites/Buttons/#TEMP2.png")},

"killer_ufo": {"titolo": "Area 51", "desc": "Hai distrutto 10 UFO!", "icona": null},

"killer_tartarughe": {"titolo": "Donatello", "desc": "Hai eliminato 10 Tartarughe spaziali!", "icona": null},

"killer_purpleDevil": {"titolo": "Esorcista Spaziale", "desc": "Hai rimandato a casa 10 Purple Devil!", "icona": null},

"secondaMod_MaiColpito": {"titolo": "Intoccabile", "desc": "Hai completato le Ondate senza subire danni!", "icona": null},

"stella_diamante": {"titolo": "Zio Paperone", "desc": "Hai raccolto 1000 Stelle totali!", "icona": null},

"primoAcquisto": {"titolo": "Dollaroni", "desc": "Hai fatto il tuo primo acquisto nel negozio!", "icona": null},

"tutteLeNavicelle": {"titolo": "Concessionario Stellare", "desc": "Hai sbloccato tutte le navicelle!", "icona": null},

"tutteLeIcone": {"titolo": "Profilato", "desc": "Hai sbloccato tutte le icone profilo!", "icona": null}

}

func _ready():
	contenitore.modulate.a = 0
	contenitore.visible = false
	GameData.achievement_sbloccato.connect(mostra_popup)

func mostra_popup(id_achievement: String):
	# Prepariamo testi e immagine
	if testi_achievements.has(id_achievement):
		lbl_titolo.text = "🏆 " + testi_achievements[id_achievement]["titolo"]
		lbl_descrizione.text = testi_achievements[id_achievement]["desc"]
		# Cambiamo l'immagine assegnando quella del dizionario:
		icona_achievement.texture = testi_achievements[id_achievement]["icona"]
	else:
		lbl_titolo.text = "🏆 Sbloccato!"
		lbl_descrizione.text = id_achievement
		# Un'immagine di default nel caso ci scordassimo di metterla nel dizionario
		icona_achievement.texture = null 
		
	# ... (il resto del codice con l'animazione tween rimane UGUALE a prima)
	contenitore.visible = true
	var tween = create_tween()
	tween.tween_property(contenitore, "modulate:a", 1.0, 0.5)
	tween.tween_interval(5.0)
	tween.tween_property(contenitore, "modulate:a", 0.0, 0.5)
	tween.tween_callback(nascondi_contenitore)

func nascondi_contenitore():
	contenitore.visible = false
