extends Node

# Definiamo un segnale per avvisare le scene quando i soldi cambiano
signal monete_aggiornate(nuovo_valore)
var monete_stella: int = 0

func _ready():
	GameData.load_data() # Se hai una funzione di caricamento

func add_monete(amount: int):
	monete_stella += amount
	GameData.save_data()
	monete_aggiornate.emit(monete_stella)
