extends Control

@onready var musica = $AudioStreamPlayer2D
@onready var biscotti_label = $BiscottiLabel
@onready var user := $PlayerInfo
@export var profile_textures: Array[Texture2D]

@onready var fullscreen_btn: CheckButton = $Options/VBoxContainer/FullscreenControl

@onready var views = {
	"main": $MainButtons,
	"options": $Options,
	"armadietto": $Armadietto,
	"selection": $Gioca,
	"leaderboard": $LeaderboardAndAchievementsMenu,
	"login": $SchermataLogin
}

@onready var background_elements = {
	"title": $Title,
	"profile_info": $PlayerInfo,
	"coins": $BiscottiLabel
}

func _ready() -> void:
	switch_view("main")
	musica.volume_db = 0 
	musica.play()
	
	# Aggiornamenti singoli (per quando compri roba nel negozio o prendi biscotti in game)
	_update_biscotti_label()
	if GameData.has_signal("biscotti_aggiornati"):
		GameData.biscotti_aggiornati.connect(_on_biscotti_aggiornate_signal)

	if GameData.has_signal("profile_icon_changed"):
		GameData.profile_icon_changed.connect(_update_player_icon)
	_update_player_icon() 
	
	# AGGIUNTA FONDAMENTALE: Ascoltiamo il nuovo segnale Cloud!
	if GameData.has_signal("dati_aggiornati"):
		GameData.dati_aggiornati.connect(_aggiorna_interfaccia_completa)
		
	# Inizializziamo subito anche il nome utente
	_update_player_name()
	
	var current_mode = DisplayServer.window_get_mode()
	var is_fullscreen = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if fullscreen_btn:
		fullscreen_btn.set_pressed_no_signal(is_fullscreen)

# --- FUNZIONI DI AGGIORNAMENTO INTERFACCIA ---

func _aggiorna_interfaccia_completa():
	_update_biscotti_label()
	_update_player_icon()
	_update_player_name()
	print("Menu Principale: Interfaccia sincronizzata istantaneamente coi dati del Cloud!")

func _update_player_name():
	if user:
		user.text = GameData.current_username

func _update_biscotti_label():
	biscotti_label.text = ": %d" % GameData.biscotti

func _on_biscotti_aggiornate_signal(_nuovo_valore):
	_update_biscotti_label()

func _update_player_icon():
	if GameData.current_icon_index < profile_textures.size():
		user.icon = profile_textures[GameData.current_icon_index]

# --- NAVIGAZIONE MENU ---

func switch_view(view_name: String) -> void:
	for key in views:
		views[key].visible = (key == view_name)
		
	$Options/VBoxContainer/Back.visible = (view_name != "main")
	$Title.visible = (view_name != "main")
	
	var is_on_leaderboard = (view_name == "leaderboard")
	for key in background_elements:
		if background_elements[key]:
			background_elements[key].visible = !is_on_leaderboard

func _on_player_info_pressed():
	if Firebase.Auth.auth.is_empty():
		switch_view("login")
	else:
		switch_view("leaderboard")

# ... Pulsanti navigazione ...
func _on_start_pressed(): switch_view("selection")
func _on_settings1_pressed(): switch_view("options")
func _on_settings2_pressed(): switch_view("armadietto")
func _on_back_pressed(): switch_view("main")
func _on_button_4_pressed(): get_tree().quit()
	
func _on_mod_pressed(mod: String) -> void:
	var tween = create_tween()
	tween.tween_property(musica, "volume_db", -80.0, 0.5)
	tween.tween_callback(FadeTransition.change_scene.bind("res://scenes/Game/Game"+mod+".tscn"))
