extends HSlider

@export var audio_bus_name: String

var audio_bus_id: int

func _ready():
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	# Leggiamo il valore iniziale direttamente da GameData
	if audio_bus_name == "Music":
		self.value = GameData.volume_music
	elif audio_bus_name == "SFX":
		self.value = GameData.volume_sfx

func _on_value_changed(slider_value: float) -> void:
	# 1. Modifica l'audio in tempo reale nel gioco
	var db = linear_to_db(slider_value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	
	# 2. Aggiorna la variabile globale dentro GameData
	if audio_bus_name == "Music":
		GameData.volume_music = slider_value
	elif audio_bus_name == "SFX":
		GameData.volume_sfx = slider_value
		
	# 3. Scrivi i dati su file (se la tua funzione di salvataggio in GameData si chiama ad esempio save_data())
	if GameData.has_method("save_data"):
		GameData.save_data()
