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
func _set_health(new_health):
	var prev_health = health
	
	health = min(max_value, new_health)
	value = health
	
	if health <= 0:
		queue_free()
		
	# --- LOGICA DELL'EFFETTO SCIA E FLASH ---
	if health < prev_health:
		# CASO: Abbiamo preso DANNO.
		timer.start()
		
		# EFFETTO BRILLANTE
		# Spariamo la luminosità della barra al massimo (effetto flash bianco/luminoso)
		modulate = Color(2.5, 2.5, 2.5) 
		
		# E la facciamo tornare normale in 0.2 secondi
		var flash_tween = create_tween()
		flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.2)
		
	else:
		# CASO: Ci siamo CURATI.
		damage_bar.value = health

# Chiamata quando il Timer finisce (dopo aver preso danno).
func _on_timer_timeout() -> void:
	# Invece di farla saltare di scatto, creiamo un Tween
	# che fa scorrere la barra del danno fluidamente in 0.2 secondi!
	var tween = create_tween()
	tween.tween_property(damage_bar, "value", health, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
