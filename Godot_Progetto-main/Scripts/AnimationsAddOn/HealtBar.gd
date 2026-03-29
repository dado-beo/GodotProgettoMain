extends ProgressBar

# Riferimento al Timer che gestisce l'animazione del danno.
@onready var timer = $Timer

# Riferimento alla seconda barra che sta SOTTO la barra della vita.
# Questa crea l'effetto "scia" quando si viene colpiti.
@onready var damage_bar  = $DamageBar

# Variabile della salute con un SETTER personalizzato.
# La sintassi ': set = _set_health' dice a Godot:
# "Ogni volta che qualcuno scrive 'health = X', esegui la funzione '_set_health(X)'."
var health = 0 : set = _set_health

# Funzione di configurazione iniziale (chiamata quando l'unità viene creata).
# Imposta i valori massimi e attuali di entrambe le barre.
func init_healt(_health):
	health = _health
	max_value = health # Imposta il massimo della barra principale
	value = health     # Imposta il valore attuale
	
	# Sincronizza anche la barra del danno (all'inizio devono essere uguali)
	damage_bar.max_value = health
	damage_bar.value = health

# --- IL CUORE DEL SISTEMA ---
# Questa funzione viene chiamata automaticamente ogni volta che 'health' cambia.
func _set_health(new_health):
	var prev_health = health # Salviamo la vita precedente per fare un confronto
	
	# Aggiorniamo la variabile interna, assicurandoci che non superi il massimo.
	health = min(max_value, new_health)
	
	# Aggiorniamo SUBITO la barra principale (feedback istantaneo).
	value = health
	
	# Controllo Morte: Se la vita è a zero, rimuoviamo la barra.
	# (NOTA: Solitamente è l'entità a morire, non solo la barra, ma qui puliamo la UI).
	if health <= 0:
		queue_free()
		
	# --- LOGICA DELL'EFFETTO SCIA ---
	if health < prev_health:
		# CASO: Abbiamo preso DANNO.
		# La barra principale scende subito (riga 35), ma la damage_bar resta ferma.
		# Avviamo il timer: per un po' vedremo la differenza tra le due barre.
		timer.start()
	else:
		# CASO: Ci siamo CURATI.
		# In questo caso non vogliamo l'effetto ritardo.
		# Anche la damage_bar deve salire subito per coprire lo spazio vuoto.
		damage_bar.value = health

# Chiamata quando il Timer finisce (dopo aver preso danno).
func _on_timer_timeout() -> void:
	# Il tempo di "visualizzazione del danno" è finito.
	# La barra del danno si allinea alla vita attuale.
	damage_bar.value = health
