extends ColorRect

# Metti qui il percorso della tua scena del Menu Principale!
@export var next_scene_path: String = "res://scenes/MainMenu.tscn" 

@onready var label_studio = $VBoxContainer/LabelStudio
@onready var label_gioco = $VBoxContainer/LabelGioco
# Percorso aggiornato in base alla tua immagine (è fuori dal VBoxContainer)
@onready var label_versione = $Versione 

func _ready():
	# Partiamo col buio totale per tutte e tre le scritte
	label_studio.modulate.a = 0.0
	label_gioco.modulate.a = 0.0
	label_versione.modulate.a = 0.0
	
	_play_splash_sequence()

func _play_splash_sequence():
	var tween = create_tween()
	
	# PAUSA INIZIALE: Buio totale per 0.5 secondi
	tween.tween_interval(0.5)
	
	# FADE IN 1: Appare "by MEMBERSONLY" in 1.5 secondi
	tween.tween_property(label_studio, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# PAUSA CORTA: (0.3 secondi) prima del titolo
	tween.tween_interval(0.3)
	
	# FADE IN 2: Appare "tempera biscotti" in 1.5 secondi
	tween.tween_property(label_gioco, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# PAUSA CORTA 2: suspense prima della versione (0.3 secondi)
	tween.tween_interval(0.3)
	
	# FADE IN 3: Appare la "Versione" un po' più velocemente (1.0 secondi)
	tween.tween_property(label_versione, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	
	# HOLD: Lasciamo tutto a schermo per 2.5 secondi
	tween.tween_interval(2.5)
	
	# FADE OUT: Svaniscono tutte e tre contemporaneamente!
	tween.tween_property(label_studio, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label_gioco, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(label_versione, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
	
	# PAUSA FINALE: Piccolo momento di buio prima di lanciare il gioco
	tween.tween_interval(0.5)
	
	# AZIONE FINALE: Andiamo al menu principale
	tween.tween_callback(_go_to_main_menu)

func _go_to_main_menu():
	get_tree().change_scene_to_file(next_scene_path)
