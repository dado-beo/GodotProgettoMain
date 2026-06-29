extends Control
# 'extends Control' indica che questo script è collegato a un Nodo di tipo interfaccia utente (UI).
# I nodi Control sono la base in Godot per creare menu, pulsanti e finestre.

# ==========================================
# 1. DICHIARAZIONE DELLE VARIABILI E DEI NODI
# ==========================================

# @onready dice a Godot: "Aspetta che la scena sia completamente caricata prima di cercare questi nodi".
# Se non usassimo @onready, lo script cercherebbe i nodi prima che esistano, causando un crash.
# Usiamo il simbolo '$' per navigare nell'albero della scena e prendere i riferimenti esatti ai nodi visivi.
@onready var username_input: LineEdit = $Panel/UsernameInput # Campo di testo dove l'utente digita il nome
@onready var email_input: LineEdit = $Panel/EmailInput       # Campo di testo per l'email
@onready var password_input: LineEdit = $Panel/PasswordInput # Campo di testo per la password (con i caratteri nascosti)
@onready var tasto_accedi: Button = $Panel/TastoAccedi
@onready var tasto_registrati: Button = $Panel/TastoRegistrati
@onready var tasto_recupera: Button = $Panel/TastoRecupera 
@onready var testo_avvisi: Label = $Panel/TestoAvvisi        # Etichetta di testo usata per mostrare errori o successi
@onready var tasto_chiudi: Button = $Panel/TastoChiudi

# Variabile che conterrà il riferimento alla "collezione" del nostro database su Firebase Firestore.
# In un database NoSQL come Firestore, i dati sono salvati in Documenti, raggruppati in Collezioni.
var database_reference: FirestoreCollection

# Definiamo delle costanti per i colori in formato RGB (rosso, verde, blu, alfa).
# Servono per cambiare dinamicamente il colore dei messaggi di feedback all'utente.
const COLOR_ERROR = Color(1.0, 0.3, 0.3)   # Rosso per gli errori
const COLOR_SUCCESS = Color(0.3, 1.0, 0.3) # Verde per le operazioni andate a buon fine
const COLOR_INFO = Color(1.0, 0.8, 0.2)    # Giallo per i caricamenti
const COLOR_NORMAL = Color(1.0, 1.0, 1.0)  # Bianco di default


# ==========================================
# 2. FUNZIONE DI INIZIALIZZAZIONE (_ready)
# ==========================================
# _ready() viene chiamata in automatico da Godot nel momento in cui il nodo entra in scena.
# È il posto perfetto per impostare i setup iniziali.
func _ready() -> void:
	_mostra_messaggio("", COLOR_NORMAL) # Pulisce eventuali testi di test lasciati nell'editor
	
	# Richiama una funzione personalizzata per impostare la grafica in modalità "Login" (nascondendo il campo username)
	_imposta_modalita_UI(false)
	
	# 'connect' è la base della programmazione a eventi di Godot (i Segnali).
	# Quando la visibilità di questo pannello cambia, Godot fa scattare la funzione '_on_visibility_changed'.
	self.visibility_changed.connect(_on_visibility_changed)
	
	# --- COLLEGAMENTO SEGNALI FIREBASE AUTH ---
	# Firebase non risponde istantaneamente (dipende da internet). Per evitare che il gioco si blocchi (freeze),
	# usiamo i segnali. Diciamo allo script: "Quando Firebase ha finito e invia questo segnale, avvia questa funzione".
	Firebase.Auth.signup_succeeded.connect(_on_registrazione_ok)
	Firebase.Auth.signup_failed.connect(_on_registrazione_fallita)
	Firebase.Auth.login_succeeded.connect(_on_login_ok)
	Firebase.Auth.login_failed.connect(_on_login_fallito)
	
	# Segnale specifico che scatta quando Firebase scarica i dati sensibili del profilo (come lo stato di verifica email)
	Firebase.Auth.userdata_received.connect(_on_userdata_ricevuti)
	
	# --- COLLEGAMENTO SEGNALI PULSANTI (UI) ---
	# Colleghiamo il click fisico del mouse sui pulsanti alle rispettive funzioni logiche
	tasto_accedi.pressed.connect(_on_tasto_accedi_pressed)
	tasto_registrati.pressed.connect(_on_tasto_registrati_pressed)
	tasto_recupera.pressed.connect(_on_tasto_recupera_pressed)
	tasto_chiudi.pressed.connect(_on_tasto_chiudi_pressed)
	
	# Puntiamo la variabile alla collezione "giocatori" creata nel Cloud Firestore di Google.
	database_reference = Firebase.Firestore.collection("giocatori")
	
	# await get_tree().process_frame: Ferma temporaneamente questo script per un singolo frame visivo.
	# Serve per dare il tempo a Godot e al plugin di Firebase di caricare completamente i loro nodi interni in background.
	await get_tree().process_frame
	
	# --- AUTO-LOGIN ---
	# Controlla se sul PC esiste già un "token" di accesso salvato dalla partita precedente.
	# Se esiste, evita di far reinserire email e password ed esegue un login silenzioso.
	if Firebase.Auth.check_auth_file():
		_blocca_interfaccia(true)
		_mostra_messaggio("Bentornato! Controllo credenziali in corso...", COLOR_INFO)


# ==========================================
# 3. FUNZIONI DI SUPPORTO (UI E SICUREZZA)
# ==========================================

# Utilizza le Espressioni Regolari (RegEx) per la sicurezza preventiva.
# Evita che l'utente scriva "ciao" nel campo email. Il pattern controlla che ci sia una stringa, una '@', e un dominio (es. '.com').
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$")
	return regex.search(email) != null

# Funzione di utilità per cambiare testo e colore (modulate) della Label di feedback con una sola riga di codice
func _mostra_messaggio(testo: String, colore: Color) -> void:
	testo_avvisi.text = testo
	testo_avvisi.modulate = colore # 'modulate' moltiplica il colore originale del nodo per il colore fornito

# Funzione Anti-Spam: quando fa chiamate a Firebase, si disabilitano i pulsanti.
# Questo impedisce all'utente di cliccare 100 volte su "Accedi", inviando 100 richieste ai server Google rischiando il ban.
func _blocca_interfaccia(bloccato: bool) -> void:
	tasto_accedi.disabled = bloccato
	tasto_registrati.disabled = bloccato
	tasto_recupera.disabled = bloccato
	username_input.editable = !bloccato # Usa '!' (NOT) perché editable funziona all'incontrario rispetto a disabled
	email_input.editable = !bloccato
	password_input.editable = !bloccato

# Ottimizzazione UI: Invece di avere due scene separate per Login e Registrazione, usiamo la stessa.
# Questa funzione accende o spegne i nodi visivi in base a quello che serve in quel momento.
func _imposta_modalita_UI(is_registrazione: bool) -> void:
	username_input.visible = is_registrazione
	tasto_recupera.visible = not is_registrazione 
	password_input.text = "" # Misura di sicurezza: svuotiamo la password ogni volta che si cambia schermata
	
	if is_registrazione:
		tasto_registrati.text = "Conferma Registrazione"
		tasto_accedi.text = "Torna al Login"
		_mostra_messaggio("Scegli un nome giocatore per registrarti!", COLOR_INFO)
	else:
		tasto_registrati.text = "Crea Account"
		tasto_accedi.text = "Accedi"
		_mostra_messaggio("", COLOR_NORMAL)


# ==========================================
# 4. GESTIONE DEI PULSANTI (INPUT UTENTE)
# ==========================================

# LOGICA TASTO ACCEDI
func _on_tasto_accedi_pressed() -> void:
	# Se l'utente era nella schermata di registrazione, questo tasto serve solo per tornare indietro visivamente
	if username_input.visible:
		_imposta_modalita_UI(false)
		return
	
	# 'strip_edges()' è fondamentale: rimuove eventuali spazi vuoti messi per sbaglio all'inizio o alla fine del testo
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	# Controlli di sicurezza lato Client prima di contattare il Server
	if email == "" or password == "":
		_mostra_messaggio("⚠️ Inserisci email e password!", COLOR_ERROR)
		return
	if not is_valid_email(email):
		_mostra_messaggio("⚠️ Formato email non valido!", COLOR_ERROR)
		return
		
	# Blocca la UI e invia i dati a Firebase Authentication
	_blocca_interfaccia(true)
	_mostra_messaggio("Accesso in corso...", COLOR_INFO)
	Firebase.Auth.login_with_email_and_password(email, password)

# LOGICA TASTO REGISTRATI
func _on_tasto_registrati_pressed() -> void:
	# Se l'utente è nel login, questo tasto fa apparire il campo username per avviare la registrazione
	if not username_input.visible:
		_imposta_modalita_UI(true)
		return

	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	# Controlli lato client (inclusa la sicurezza della password dettata da Firebase)
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

# LOGICA TASTO RECUPERA PASSWORD
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
	
	# 'await get_tree().create_timer(1.5).timeout' crea una pausa nel codice senza bloccare il gioco.
	# Lo usiamo per mostrare il messaggio per un po' prima di sbloccare l'interfaccia.
	await get_tree().create_timer(1.5).timeout
	_mostra_messaggio("📧 Se l'account esiste, riceverai un'email per il reset a breve.", COLOR_SUCCESS)
	_blocca_interfaccia(false)

# Tasto "X" per chiudere la schermata e tornare al main menu
func _on_tasto_chiudi_pressed() -> void:
	if get_parent().has_method("switch_view"):
		get_parent().switch_view("main")
	else:
		self.visible = false


# ==========================================
# 5. GESTIONE RISPOSTE DA FIREBASE (REGISTRAZIONE)
# ==========================================

# Funzione collegata al segnale 'signup_succeeded'. 
# Firebase restituisce un Dizionario (auth_info) contenente l'ID univoco generato dai server Google.
func _on_registrazione_ok(auth_info: Dictionary) -> void:
	var user_id = auth_info.localid # Questo ID in Firebase si chiama UID (User ID), è unico per ogni persona nel mondo.
	var username = username_input.text.strip_edges()
	
	# Salviamo temporaneamente l'ID e l'Username nel nostro Singleton globale 'GameData'
	GameData.current_user_id = user_id
	GameData.current_username = username
	GameData.save_data(true)
	
	_mostra_messaggio("🎉 Account creato! Controlla l'email per verificarlo.", COLOR_SUCCESS)
	# Inviamo subito un link di verifica alla mail dell'utente per evitare account fake (bot)
	Firebase.Auth.send_account_verification_email()
	_blocca_interfaccia(false)
	_imposta_modalita_UI(false) # Lo riportiamo alla UI del login per costringerlo ad accedere normalmente.

# Gestione degli errori restituiti dal server (es. se la mail è già presente nel database Google)
func _on_registrazione_fallita(_error_code: int, message: String) -> void:
	_blocca_interfaccia(false)
	# Traduciamo l'errore tecnico di Firebase (in inglese) in un messaggio user-friendly per il giocatore
	if "EMAIL_EXISTS" in message:
		_mostra_messaggio("❌ Questa email è già registrata!", COLOR_ERROR)
	elif "INVALID_EMAIL" in message:
		_mostra_messaggio("❌ L'email non è valida!", COLOR_ERROR)
	elif "WEAK_PASSWORD" in message:
		_mostra_messaggio("❌ La password è troppo debole!", COLOR_ERROR)
	else:
		_mostra_messaggio("❌ Errore registrazione: " + message, COLOR_ERROR)


# ==========================================
# 6. GESTIONE RISPOSTE DA FIREBASE (LOGIN E VERIFICA)
# ==========================================

# L'utente ha inserito le credenziali giuste, MA non lo facciamo giocare subito.
func _on_login_ok(auth_info: Dictionary) -> void:
	_mostra_messaggio("Verifico lo stato dell'account...", COLOR_INFO)
	# Salva il token crittografato sul PC per i login futuri
	Firebase.Auth.save_auth(auth_info)
	
	# Chiediamo al server di mandarci tutti i dati di sicurezza dell'utente
	await get_tree().create_timer(0.5).timeout
	Firebase.Auth.get_user_data()

# Firebase ci ha risposto coi dati. Ora verifichiamo la validità della mail.
func _on_userdata_ricevuti(userdata) -> void:
	# Se la variabile booleana 'email_verified' nei server di Google è false, blocchiamo l'accesso!
	if not userdata.email_verified:
		_mostra_messaggio("⚠️ Devi prima confermare la tua email! Controlla la posta.", COLOR_ERROR)
		Firebase.Auth.logout() # Lo cacciamo forzatamente dal sistema
		_blocca_interfaccia(false)
		return
	
	_mostra_messaggio("Email verificata! Recupero i tuoi dati...", COLOR_INFO)
	_avvia_recupero_dati()

# Errore classico se si sbaglia la password
func _on_login_fallito(_error_code: int, _message: String) -> void:
	_blocca_interfaccia(false)
	_mostra_messaggio("❌ Email o password errate!", COLOR_ERROR)


# ==========================================
# 7. RECUPERO DATI DAL CLOUD (FIRESTORE)
# ==========================================

# Ora che l'identità è verificata, andiamo a prendere il "Salvataggio di gioco" dal database.
func _avvia_recupero_dati() -> void:
	var user_id = Firebase.Auth.auth.localid
	# Usiamo 'await' perché scaricare dati da Firestore (il Database di Google) è un'operazione Asincrona.
	# Lo script aspetta qui finché il file non è stato scaricato dalla rete, poi passa alla funzione successiva.
	var documento = await database_reference.get_doc(user_id)
	_on_dati_scaricati(documento)

# I dati sono arrivati da Google sotto forma di 'FirestoreDocument' (strutturato in JSON/Dizionario)
func _on_dati_scaricati(documento: FirestoreDocument) -> void:
	# Controlliamo se il documento esiste (se ha campi dati)
	if documento and documento.doc_fields != null:
		var dati = documento.doc_fields
		
		# Effettuiamo il Mapping: trasferiamo i dati scaricati dal server alle variabili locali di 'GameData'
		# Utilizziamo 'get("chiave", valore_di_default)' così, se un dato manca nel cloud, non crasha ma inserisce un default.
		GameData.current_username = dati.get("nome_utente", "Giocatore")
		GameData.current_user_id = Firebase.Auth.auth.localid
		GameData.biscotti = int(dati.get("biscotti", 0))
		GameData.biscotti_totali_ottenuti = int(dati.get("biscotti_totali_ottenuti", 0))
		GameData.current_icon_index = int(dati.get("current_icon_index", 0))
		GameData.selected_ship_index = int(dati.get("selected_ship_index", 0))
		
		# Recuperiamo le collezioni (Array e Dizionari complessi)
		if dati.has("unlocked_icons"): GameData.unlocked_icons = dati["unlocked_icons"]
		if dati.has("unlocked_ships"): GameData.unlocked_ships = dati["unlocked_ships"]
		if dati.has("records"): GameData.records = dati["records"]
		if dati.has("upgrades"): GameData.upgrades = dati["upgrades"]
		if dati.has("achievements"): GameData.achievements = dati["achievements"]
		
		# Applichiamo la skin della navicella scelta
		if GameData.selected_ship_index < GameData.ship_scenes.size():
			GameData.selected_ship_scene = GameData.ship_scenes[GameData.selected_ship_index]
			
		GameData.save_data(false) 
		# EMETTIAMO IL SEGNALE: Questo urla a tutto il resto del gioco che i dati cloud sono pronti.
		# Il MainMenu lo ascolta e aggiorna la grafica (nome, biscotti, ecc.)
		GameData.dati_aggiornati.emit()
		
		_mostra_messaggio("Bentornato, " + GameData.current_username + "!", COLOR_SUCCESS)
		await get_tree().create_timer(1.5).timeout
		_blocca_interfaccia(false)
		
		# Chiudiamo la finestra di login, ma solo se l'utente non l'ha già chiusa a mano
		if self.visible:
			_on_tasto_chiudi_pressed()
	else:
		# Se il documento è vuoto, significa che è il PRIMO ACCESSO in assoluto del giocatore.
		# Creiamo un profilo pulito assegnando le variabili di base.
		GameData.current_user_id = Firebase.Auth.auth.localid
		GameData.current_username = "Giocatore"
		GameData.save_data(true)
		_blocca_interfaccia(false)
		
		if self.visible:
			_on_tasto_chiudi_pressed()


# ==========================================
# 8. RESET DELL'INTERFACCIA
# ==========================================

# Questa funzione viene chiamata in automatico grazie al segnale 'visibility_changed' impostato nella _ready.
func _on_visibility_changed() -> void:
	# Serve per evitare bug grafici (es. aprire il menu, chiuderlo e riaprirlo e trovarsi le vecchie scritte/errori)
	if self.visible:
		_imposta_modalita_UI(false)           # Torna alla modalità Login standard (nasconde la registrazione)
		_mostra_messaggio("", COLOR_NORMAL)   # Pulisce i vecchi messaggi di avviso
		
		# Svuota i campi di testo per proteggere la privacy dell'utente
		email_input.text = ""
		password_input.text = ""
		username_input.text = ""
