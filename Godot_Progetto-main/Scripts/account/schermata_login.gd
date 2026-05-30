extends Control

# Colleghiamo i nodi della scena usando i loro nomi esatti
@onready var username_input: LineEdit = $Panel/UsernameInput
@onready var email_input: LineEdit = $Panel/EmailInput
@onready var password_input: LineEdit = $Panel/PasswordInput
@onready var tasto_accedi: Button = $Panel/TastoAccedi
@onready var tasto_registrati: Button = $Panel/TastoRegistrati
@onready var tasto_recupera: Button = $Panel/TastoRecupera # NUOVO NODO
@onready var testo_avvisi: Label = $Panel/TestoAvvisi
@onready var tasto_chiudi: Button = $Panel/TastoChiudi

var database_reference: FirestoreCollection

# Colori per i feedback visivi
const COLOR_ERROR = Color(1.0, 0.3, 0.3)   # Rosso
const COLOR_SUCCESS = Color(0.3, 1.0, 0.3) # Verde
const COLOR_INFO = Color(1.0, 0.8, 0.2)    # Giallo/Arancio
const COLOR_NORMAL = Color(1.0, 1.0, 1.0)  # Bianco

func _ready() -> void:
	_mostra_messaggio("", COLOR_NORMAL)
	
	# Assicuriamoci che all'avvio sia in modalità Login
	_imposta_modalita_UI(false)
	
	self.visibility_changed.connect(_on_visibility_changed)
	
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
	tasto_recupera.pressed.connect(_on_tasto_recupera_pressed)
	tasto_chiudi.pressed.connect(_on_tasto_chiudi_pressed)
	
	database_reference = Firebase.Firestore.collection("giocatori")
	
	# Aspettiamo un frame per far caricare i file a Godot
	await get_tree().process_frame
	
	# ACCESSO AUTOMATICO SE GIÀ LOGGATO IN PRECEDENZA
	if Firebase.Auth.check_auth_file():
		_blocca_interfaccia(true)
		_mostra_messaggio("Bentornato! Controllo credenziali in corso...", COLOR_INFO)

# --- FUNZIONI DI SUPPORTO (UI E SICUREZZA) ---

func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$")
	return regex.search(email) != null

func _mostra_messaggio(testo: String, colore: Color) -> void:
	testo_avvisi.text = testo
	testo_avvisi.modulate = colore

func _blocca_interfaccia(bloccato: bool) -> void:
	# Previene lo spam di click disabilitando bottoni e input
	tasto_accedi.disabled = bloccato
	tasto_registrati.disabled = bloccato
	tasto_recupera.disabled = bloccato
	username_input.editable = !bloccato
	email_input.editable = !bloccato
	password_input.editable = !bloccato

func _imposta_modalita_UI(is_registrazione: bool) -> void:
	# Gestisce in modo pulito il passaggio tra Login e Registrazione
	username_input.visible = is_registrazione
	tasto_recupera.visible = not is_registrazione 
	password_input.text = "" # Svuota la password per sicurezza quando si cambia modalità
	
	if is_registrazione:
		tasto_registrati.text = "Conferma Registrazione"
		tasto_accedi.text = "Torna al Login"
		_mostra_messaggio("Scegli un nome giocatore per registrarti!", COLOR_INFO)
	else:
		tasto_registrati.text = "Crea Account"
		tasto_accedi.text = "Accedi"
		_mostra_messaggio("", COLOR_NORMAL)

# --- GESTIONE PULSANTI ---

func _on_tasto_accedi_pressed() -> void:
	# Se eravamo in modalità registrazione, torniamo al login
	if username_input.visible:
		_imposta_modalita_UI(false)
		return
	
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if email == "" or password == "":
		_mostra_messaggio("⚠️ Inserisci email e password!", COLOR_ERROR)
		return
	if not is_valid_email(email):
		_mostra_messaggio("⚠️ Formato email non valido!", COLOR_ERROR)
		return
		
	_blocca_interfaccia(true)
	_mostra_messaggio("Accesso in corso...", COLOR_INFO)
	Firebase.Auth.login_with_email_and_password(email, password)

func _on_tasto_registrati_pressed() -> void:
	# Se eravamo in modalità login, passiamo alla registrazione
	if not username_input.visible:
		_imposta_modalita_UI(true)
		return

	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username == "":
		_mostra_messaggio("⚠️ Inserisci un nome giocatore!", COLOR_ERROR)
		return
	if not is_valid_email(email):
		_mostra_messaggio("⚠️ Inserisci un'email valida!", COLOR_ERROR)
		return
	if password.length() < 6:
		_mostra_messaggio("⚠️ La password deve avere almeno 6 caratteri!", COLOR_ERROR)
		return
		
	_blocca_interfaccia(true)
	_mostra_messaggio("Creazione account in corso...", COLOR_INFO)
	Firebase.Auth.signup_with_email_and_password(email, password)

func _on_tasto_recupera_pressed() -> void:
	var email = email_input.text.strip_edges()
	
	if email == "":
		_mostra_messaggio("⚠️ Inserisci la tua email nel campo per recuperare la password!", COLOR_ERROR)
		return
		
	if not is_valid_email(email):
		_mostra_messaggio("⚠️ Formato email non valido!", COLOR_ERROR)
		return
		
	_blocca_interfaccia(true)
	_mostra_messaggio("📧 Invio email di recupero...", COLOR_INFO)
	Firebase.Auth.send_password_reset_email(email)
	
	# Riabilitiamo subito dopo l'invio perché Firebase non ha un segnale specifico per il reset completato
	await get_tree().create_timer(1.5).timeout
	_mostra_messaggio("📧 Se l'account esiste, riceverai un'email per il reset a breve.", COLOR_SUCCESS)
	_blocca_interfaccia(false)

func _on_tasto_chiudi_pressed() -> void:
	if get_parent().has_method("switch_view"):
		get_parent().switch_view("main")
	else:
		self.visible = false

# --- REGISTRAZIONE ---

func _on_registrazione_ok(auth_info: Dictionary) -> void:
	var user_id = auth_info.localid
	var username = username_input.text.strip_edges()
	
	GameData.current_user_id = user_id
	GameData.current_username = username
	GameData.save_data(true)
	
	_mostra_messaggio("🎉 Account creato! Controlla l'email per verificarlo.", COLOR_SUCCESS)
	Firebase.Auth.send_account_verification_email()
	_blocca_interfaccia(false)
	_imposta_modalita_UI(false) # Riporta alla schermata di login per l'accesso futuro

func _on_registrazione_fallita(_error_code: int, message: String) -> void:
	_blocca_interfaccia(false)
	if "EMAIL_EXISTS" in message:
		_mostra_messaggio("❌ Questa email è già registrata!", COLOR_ERROR)
	elif "INVALID_EMAIL" in message:
		_mostra_messaggio("❌ L'email non è valida!", COLOR_ERROR)
	elif "WEAK_PASSWORD" in message:
		_mostra_messaggio("❌ La password è troppo debole!", COLOR_ERROR)
	else:
		_mostra_messaggio("❌ Errore registrazione: " + message, COLOR_ERROR)

# --- LOGIN E VERIFICA EMAIL ---

func _on_login_ok(auth_info: Dictionary) -> void:
	_mostra_messaggio("Verifico lo stato dell'account...", COLOR_INFO)
	Firebase.Auth.save_auth(auth_info)
	
	await get_tree().create_timer(0.5).timeout
	Firebase.Auth.get_user_data()

func _on_userdata_ricevuti(userdata) -> void:
	if not userdata.email_verified:
		_mostra_messaggio("⚠️ Devi prima confermare la tua email! Controlla la posta.", COLOR_ERROR)
		Firebase.Auth.logout()
		_blocca_interfaccia(false)
		return
	
	_mostra_messaggio("Email verificata! Recupero i tuoi dati...", COLOR_INFO)
	_avvia_recupero_dati()

func _on_login_fallito(_error_code: int, _message: String) -> void:
	_blocca_interfaccia(false)
	_mostra_messaggio("❌ Email o password errate!", COLOR_ERROR)

# --- RECUPERO DATI CLOUD ---

func _avvia_recupero_dati() -> void:
	var user_id = Firebase.Auth.auth.localid
	var documento = await database_reference.get_doc(user_id)
	_on_dati_scaricati(documento)

# --- RECUPERO DATI CLOUD ---

func _on_dati_scaricati(documento: FirestoreDocument) -> void:
	if documento and documento.doc_fields != null:
		var dati = documento.doc_fields
		
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
			
		GameData.save_data(false) 
		GameData.dati_aggiornati.emit()
		
		_mostra_messaggio("Bentornato, " + GameData.current_username + "!", COLOR_SUCCESS)
		await get_tree().create_timer(1.5).timeout
		_blocca_interfaccia(false)
		
		# FIX: Torna al main menu SOLO se il pannello di login è visibile!
		if self.visible:
			_on_tasto_chiudi_pressed()
	else:
		GameData.current_user_id = Firebase.Auth.auth.localid
		GameData.current_username = "Giocatore"
		GameData.save_data(true)
		_blocca_interfaccia(false)
		
		# FIX ANCHE QUI: Torna al main menu SOLO se il pannello è visibile!
		if self.visible:
			_on_tasto_chiudi_pressed()

func _on_visibility_changed() -> void:
	# Eseguiamo il reset SOLO quando la schermata diventa visibile
	if self.visible:
		_imposta_modalita_UI(false)           # Torna alla modalità Login standard
		_mostra_messaggio("", COLOR_NORMAL)   # Pulisce i messaggi di avviso
		
		# Opzionale ma super consigliato: Svuota anche i campi di testo!
		email_input.text = ""
		password_input.text = ""
		username_input.text = ""
