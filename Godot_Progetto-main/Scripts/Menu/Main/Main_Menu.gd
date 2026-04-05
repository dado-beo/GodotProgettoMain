extends Control
@onready var musica = $AudioStreamPlayer2D
@onready var monete_label := $MoneteLabel
@onready var user := $PlayerInfo
@export var profile_textures: Array[Texture2D]

# Aggiungiamo il riferimento al bottone (basato sulla tua immagine)
@onready var fullscreen_btn: CheckButton = $Options/VBoxContainer/FullscreenControl

@onready var views = {
	"main": $MainButtons,
	"options": $Options,
	"armadietto": $Armadietto,
	"selection": $Gioca,
	"leaderboard": $LeaderboardAndAchievementsMenu
}

func _ready() -> void:
	switch_view("main")
	musica.volume_db = 0 
	musica.play()
	# Aggiornamento Monete
	_update_monete_label()
	GameData.monete_aggiornate.connect(_on_monete_aggiornate_signal)

	# Aggiornamento Icona Profilo
	GameData.profile_icon_changed.connect(_update_player_icon)
	_update_player_icon() # Imposta subito l'icona salvata
	
	# --- FIX FULLSCREEN ---
	# Sincronizza il bottone con lo stato reale all'avvio del menù
	var current_mode = DisplayServer.window_get_mode()
	var is_fullscreen = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	if fullscreen_btn:
		fullscreen_btn.set_pressed_no_signal(is_fullscreen)
	
func _update_monete_label():
	monete_label.text = ": %d" % GameData.monete_stella

func _on_monete_aggiornate_signal(_nuovo_valore):
	_update_monete_label()

func _update_player_icon():
	if GameData.current_icon_index < profile_textures.size():
		user.icon = profile_textures[GameData.current_icon_index]
	else:
		print("Errore: Indice icona non trovato nell'array!")

# ... existing Main_Menu.gd code ...

# Dictionary of background elements to hide selectively
# ATTENZIONE: Assicurati che questi percorsi coincidano esattamente con i nomi dei nodi nel tuo albero del menu principale!
@onready var background_elements = {
	"title": $Title,          # "Tempera Biscotti"
	"profile_info": $PlayerInfo,   # icona profilo
	"coins": $MoneteLabel      # monete
	# ... aggiungi altri nodi del background se necessario ...
}

func switch_view(view_name: String) -> void:
	for key in views:
		views[key].visible = (key == view_name)
		
	# Gestione speciale per il tasto "Back" (se la sua posizione è ok, lascialo così)
	$Options/VBoxContainer/Back.visible = (view_name != "main")

	# --- NASCONDERE SELETTIVAMENTE GLI ELEMENTI DEL BACKGROUND ---
	# Nascondi gli elementi se siamo nella schermata leaderboard, mostrali altrimenti
	var is_on_leaderboard = (view_name == "leaderboard")
	for key in background_elements:
		# Se l'elemento esiste, lo nascondiamo o lo mostriamo
		if background_elements[key]:
			background_elements[key].visible = !is_on_leaderboard

	# --- Opzione per nascondere anche MainButtons se preferisci ---
	# $MainButtons.visible = !is_on_leaderboard

# ... the rest of the Main_Menu.gd code ...
func fade_out_music(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(musica, "volume_db", -80.0, duration)
	tween.tween_callback(musica.stop)

func _on_start_pressed(): switch_view("selection")
func _on_settings1_pressed(): switch_view("options")
func _on_settings2_pressed(): switch_view("armadietto")
func _on_back_pressed():	switch_view("main")
func _on_player_info_pressed(): switch_view("leaderboard")
func _on_mod_pressed(mod: String) -> void:
	fade_out_music(0.5) 
	FadeTransition.change_scene("res://scenes/Game/Game"+mod+".tscn")
