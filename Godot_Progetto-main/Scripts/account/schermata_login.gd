extends Control

# Colleghiamo i nodi della scena usando i loro nomi esatti
@onready var username_input: LineEdit = $Panel/UsernameInput
@onready var email_input: LineEdit = $Panel/EmailInput
@onready var password_input: LineEdit = $Panel/PasswordInput
@onready var tasto_accedi: Button = $Panel/TastoAccedi
@onready var tasto_registrati: Button = $Panel/TastoRegistrati
@onready var testo_avvisi: Label = $Panel/TestoAvvisi
@onready var tasto_chiudi: Button = $Panel/TastoChiudi

var database_reference: FirestoreCollection

func _ready() -> void:
	testo_avvisi.text = ""
	
	# Collegamento segnali Firebase Auth
	Firebase.Auth.signup_succeeded.connect(_on_registrazione_ok)
	Firebase.Auth.signup_failed.connect(_on_registrazione_fallita)
	Firebase.Auth.login_succeeded.connect(_on_login_ok)
	Firebase.Auth.login_failed.connect(_on_login_fallito)
	
	# Segnale per ricevere i dati profilo aggiornati
	Firebase.Auth.userdata_received.connect(_on_userdata_ricevuti)
	
	# Collegamento pulsanti
	tasto_accedi.pressed.connect(_on_tasto_accedi_pressed)
	tasto_registrati.pressed.connect(_on_tasto_registrati_pressed)
	tasto_chiudi.pressed.connect(_on_tasto_chiudi_pressed)
	
	database_reference = Firebase.Firestore.collection("giocatori")
	
	# Aspettiamo un frame per far caricare i file a Godot
	await get_tree().process_frame
	
	# ACCESSO AUTOMATICO SE GIÀ LOGGATO IN PRECEDENZA
	# Nota: check_auth_file() lancerà automaticamente _on_login_ok se ha successo!
	if Firebase.Auth.check_auth_file():
		testo_avvisi.text = "Bentornato! Controllo credenziali in corso..."

# --- LIVELLO DI SICUREZZA 1: REGEX ---
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$")
	return regex.search(email) != null

# --- GESTIONE PULSANTI ---

func _on_tasto_accedi_pressed() -> void:
	username_input.visible = false
	tasto_registrati.text = "Registrati"
	
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		testo_avvisi.text = "⚠️ Inserisci email e password!"
		return
	if not is_valid_email(email):
		testo_avvisi.text = "⚠️ Formato email non valido!"
		return
		
	testo_avvisi.text = "Accesso in corso..."
	Firebase.Auth.login_with_email_and_password(email, password)

func _on_tasto_registrati_pressed() -> void:
	if not username_input.visible:
		username_input.visible = true
		testo_avvisi.text = "Scegli un nome giocatore per registrarti!"
		tasto_registrati.text = "Conferma Registrazione"
		return

	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username == "":
		testo_avvisi.text = "⚠️ Inserisci un nome giocatore!"
		return
	if not is_valid_email(email):
		testo_avvisi.text = "⚠️ Inserisci un'email valida!"
		return
	if password.length() < 6:
		testo_avvisi.text = "⚠️ La password deve avere almeno 6 caratteri!"
		return
		
	testo_avvisi.text = "Creazione account in corso..."
	Firebase.Auth.signup_with_email_and_password(email, password)

func _on_tasto_chiudi_pressed() -> void:
	if get_parent().has_method("switch_view"):
		get_parent().switch_view("main")
	else:
		self.visible = false

# --- REGISTRAZIONE ---

func _on_registrazione_ok(auth_info: Dictionary) -> void:
	var user_id = auth_info.localid
	var username = username_input.text.strip_edges()
	
	# Salviamo i dati correnti (ex-Ospite) nel nuovo account
	GameData.current_user_id = user_id
	GameData.current_username = username
	GameData.save_data(true) # Forza caricamento immediato su Cloud
	
	testo_avvisi.text = "🎉 Account creato! Controlla l'email per verificare l'account."
	Firebase.Auth.send_account_verification_email()

func _on_registrazione_fallita(_error_code: int, message: String) -> void:
	if "EMAIL_EXISTS" in message:
		testo_avvisi.text = "❌ Questa email è già registrata!"
	elif "INVALID_EMAIL" in message:
		testo_avvisi.text = "❌ L'email non è valida!"
	elif "WEAK_PASSWORD" in message:
		testo_avvisi.text = "❌ La password è troppo debole!"
	else:
		testo_avvisi.text = "❌ Errore registrazione: " + message

# --- LOGIN E VERIFICA EMAIL ---
func _on_login_ok(auth_info: Dictionary) -> void:
	testo_avvisi.text = "Verifico lo stato dell'account..."
	
	# Salviamo la sessione sul disco locale
	Firebase.Auth.save_auth(auth_info)
	
	# Diamo mezzo secondo a Firebase per "digerire" il token prima di usarlo
	await get_tree().create_timer(0.5).timeout
	
	# Chiediamo al server i dati freschi (ora in sicurezza, senza Errore 44)
	Firebase.Auth.get_user_data()

func _on_userdata_ricevuti(userdata) -> void:
	# Il controllo ora avviene sui dati appena scaricati
	if not userdata.email_verified:
		testo_avvisi.text = "⚠️ Devi prima confermare la tua email! Controlla la posta."
		Firebase.Auth.logout()
		return
	
	testo_avvisi.text = "Email verificata! Recupero i tuoi biscotti..."
	_avvia_recupero_dati()

func _on_login_fallito(_error_code: int, _message: String) -> void:
	testo_avvisi.text = "❌ Email o password errate!"

# --- RECUPERO DATI CLOUD ---

func _avvia_recupero_dati() -> void:
	var user_id = Firebase.Auth.auth.localid
	var documento = await database_reference.get_doc(user_id)
	_on_dati_scaricati(documento)

func _on_dati_scaricati(documento: FirestoreDocument) -> void:
	if documento and documento.doc_fields != null:
		var dati = documento.doc_fields
		
		# Aggiorniamo GameData con i dati del Cloud
		GameData.current_username = dati.get("nome_utente", "Giocatore")
		GameData.current_user_id = Firebase.Auth.auth.localid
		GameData.biscotti = int(dati.get("biscotti", 0))
		GameData.biscotti_totali_ottenuti = int(dati.get("biscotti_totali_ottenuti", 0))
		GameData.current_icon_index = int(dati.get("current_icon_index", 0))
		GameData.selected_ship_index = int(dati.get("selected_ship_index", 0))
		
		if dati.has("unlocked_icons"): GameData.unlocked_icons = dati["unlocked_icons"]
		if dati.has("unlocked_ships"): GameData.unlocked_ships = dati["unlocked_ships"]
		if dati.has("records"): GameData.records = dati["records"]
		if dati.has("upgrades"): GameData.upgrades = dati["upgrades"]
		if dati.has("achievements"): GameData.achievements = dati["achievements"]
		
		if GameData.selected_ship_index < GameData.ship_scenes.size():
			GameData.selected_ship_scene = GameData.ship_scenes[GameData.selected_ship_index]
			
		GameData.save_data(false) # Salva localmente la copia specchio
		
		# Emette il segnale per aggiornare Main Menu e Negozi (Lucchetti e Monete)
		GameData.dati_aggiornati.emit()
		
		testo_avvisi.text = "Bentornato, " + GameData.current_username + "!"
		await get_tree().create_timer(1.5).timeout
		_on_tasto_chiudi_pressed()
	else:
		# Se l'account non ha dati sul cloud, usiamo quelli correnti e li carichiamo
		GameData.current_user_id = Firebase.Auth.auth.localid
		GameData.current_username = "Giocatore"
		GameData.save_data(true)
		_on_tasto_chiudi_pressed()
