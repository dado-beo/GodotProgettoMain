extends Node

func _ready() -> void:
	# Colleghiamo i segnali
	Firebase.Auth.signup_succeeded.connect(_on_registrazione_ok)
	Firebase.Auth.signup_failed.connect(_on_registrazione_fallita)
	
	print("Provando a registrare l'utente tramite .env...")
	Firebase.Auth.signup_with_email_and_password("biscottotest@gmail.com", "PasswordSicura123!")

func _on_registrazione_ok(auth_info: Dictionary) -> void:
	print("🎉 BINGO! L'utente è stato creato su Firebase!")

func _on_registrazione_fallita(error_code: int, message: String) -> void:
	print("❌ ERRORE: ", message)
