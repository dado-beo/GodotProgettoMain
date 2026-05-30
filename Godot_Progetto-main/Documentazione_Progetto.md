# Documentazione Tecnica e di Game Design - Progetto Godot

## Introduzione e Panoramica del Progetto
Il presente documento ha lo scopo di fornire un'analisi dettagliata ed estensiva dell'architettura e del game design del progetto videoludico sviluppato tramite il motore grafico Godot Engine. La documentazione illustra le componenti principali del gioco, suddivise per interfacce utente e modalità di gioco, ed è redatta come relazione finale per l'esame di maturità.

Il gioco è uno sparatutto / survival spaziale 2D, in cui l'obiettivo principale del giocatore è sopravvivere a ondate crescenti di nemici, raccogliendo nel contempo una valuta in-game ("biscotti"). Questa valuta permette al giocatore di sbloccare nuovi contenuti, acquistare potenziamenti e personalizzare l'esperienza di gioco. È presente inoltre una robusta integrazione di salvataggio su Cloud (Firebase) per mantenere i progressi, gli achievement e la posizione in classifica dell'utente.

---

## 1. Menu Principale (Main Menu)
Il **Menu Principale** (`Main_Menu.gd`) funge da snodo centrale per l'intera esperienza di gioco. La schermata è progettata per essere intuitiva ed elegante, mostrando immediatamente i progressi dell'utente.

### Funzionalità Centrali
- **Hub di Navigazione:** Dal menu principale è possibile accedere alla schermata di selezione delle modalità di gioco ("Gioca"), all'Armadietto per le personalizzazioni, alle Opzioni, e alla sezione Leaderboard/Account.
- **Interfaccia Utente (UI) e Dati Giocatore:** In alto nella schermata sono costantemente visibili:
  - L'icona del profilo del giocatore.
  - Il nome utente corrente (estrapolato tramite il database).
  - Il contatore dei "biscotti" posseduti, che si aggiorna in tempo reale anche tramite l'ascolto di segnali globali (come `dati_aggiornati` e `biscotti_aggiornati`).
- **Autenticazione:** Il pulsante relativo al profilo utente controlla dinamicamente lo stato di login. Se l'utente non è autenticato (`Firebase.Auth.auth.is_empty()`), viene reindirizzato alla schermata di Login. In caso contrario, accede alle Classifiche (Leaderboard) e agli Obiettivi.
- **Transizioni Fluide:** I passaggi tra le scene del gioco non sono istantanei, ma gestiti dal nodo `FadeTransition`, che garantisce una dissolvenza pulita. Contestualmente, il volume della colonna sonora sfuma in modo elegante.

---

## 2. Menu Armadietto (Locket Menu)
L'**Armadietto** (`armadietto.gd`) è l'hub gestionale in cui il giocatore può spendere la valuta ottenuta e prepararsi per le prossime partite. Il menu è diviso in tre sezioni principali:

### 2.1 Costumi / Navicelle Giocabili (Skin)
Questa sezione (`skin.gd`) permette al giocatore di visualizzare e selezionare la navicella spaziale da utilizzare in partita.
- Le diverse navicelle spaziali hanno estetiche uniche e, potenzialmente, statistiche o tipologie di sparo differenti. 
- Il giocatore può scorrere tra le skin sbloccate, equipaggiandone una come predefinita (`GameData.selected_ship_scene`).

### 2.2 Miglioramenti (Upgrades)
La sezione **Miglioramenti** (`miglioramenti.gd`) rappresenta il nucleo dell'evoluzione del giocatore (meta-progressione).
- Utilizzando i "biscotti", l'utente può acquistare potenziamenti permanenti per la propria navicella (ad esempio, aumento della salute massima, maggiore frequenza di sparo o danni incrementati).
- Il pannello aggiorna visivamente i costi e il livello attuale di ogni miglioramento (`update_ui_elements()`). Questo garantisce un costante senso di progressione al giocatore, che è spronato a giocare più partite per sbloccare i gradi successivi di potenza.

### 2.3 Icone (Icons)
L'ultima sottosezione (`icons.gd`) è puramente estetica e dedicata all'account del giocatore.
- È possibile sbloccare o selezionare icone del profilo personalizzate. Quando un'icona viene scelta, viene inviato un segnale al `GameData` (`profile_icon_changed`) che aggiorna l'immagine in tempo reale in tutto il gioco, inclusa la schermata principale e le classifiche globali.

---

## 3. Menu Opzioni (Options Menu)
Il **Menu Opzioni** garantisce l'adattabilità dell'esperienza di gioco alle esigenze dell'utente. Il sistema è accessibile sia dal Main Menu, sia durante la partita in corso tramite il Menu di Pausa.

### Menu di Pausa (`paused_menu.gd`)
- Durante il gameplay, premendo il tasto "Esc" (mappato sull'azione `pause`), il tempo di gioco viene fermato (`get_tree().paused = true`) e l'interfaccia di pausa diventa visibile. Il nodo del menu di pausa opera in `PROCESS_MODE_ALWAYS` per permettere la ricezione degli input anche a tempo fermo.
- Da qui il giocatore può:
  - **Riprendere** la partita.
  - **Aprire le impostazioni.**
  - **Abbandonare** la partita. In quest'ultimo caso, i dati vengono forzatamente salvati sul Cloud (`GameData.save_data(true)`) per evitare la perdita dei progressi o della valuta ottenuta fino a quel momento.

### Regolazioni Tecniche
- **Gestione Schermo:** È presente un controllo (`FullscreenControl`) che permette di passare dinamicamente dalla modalità a finestra al Fullscreen (`DisplayServer.WINDOW_MODE_FULLSCREEN`). Lo stato viene letto e aggiornato non appena si apre il menu, per evitare discrepanze visive.
- **Audio Control:** Gestione centralizzata dei canali audio (Musica, Effetti Sonori) collegata ai bus audio di Godot.

---

## 4. Prima Modalità di Gioco (Time Survival)
La **Prima Modalità** (`Game.gd`) è una sfida di sopravvivenza basata su un timer rigoroso. È l'ideale per i principianti o per sessioni veloci.

### Regole e Obiettivi
- **Durata:** Il giocatore deve sopravvivere esattamente per 90 secondi (1 minuto e 30 secondi).
- **Vittoria:** Se il timer (`current_time`) raggiunge la costante `GAME_DURATION`, il giocatore vince la partita. In tal caso si innesca la logica di fine gioco con parametro `survived: true`.

### Difficoltà Dinamica
La frequenza di generazione (spawn rate) degli ostacoli e dei nemici non è fissa, ma peggiora gradualmente nel tempo tramite la funzione `update_spawn_speed(c_time)`:
- **0-30 secondi:** Fase facile. Il tempo di attesa tra un nemico e l'altro scende morbidamente da 2.5 a 1.5 secondi.
- **30-60 secondi:** Fase media. L'intervallo si riduce ulteriormente da 1.5 a 0.8 secondi.
- **60-90 secondi:** Sopravvivenza finale. Il gioco diventa frenetico, raggiungendo il picco di 0.35 secondi tra uno spawn e l'altro.

### Eventi Speciali e Ricompense
- Al raggiungimento di step prefissati (30s, 60s, 90s), il giocatore viene ricompensato rispettivamente con 5, 15 e 30 biscotti. Una sofisticata animazione UI (`_esegui_animazione_biscotti`) evidenzia l'incremento di valuta in tempo reale.
- **L'Ancora Gravitazionale:** Al 60° secondo, la partita genera un pericolo maggiore: due istanze di "Ancore Gravitazionali" invadono la mappa provenendo da lati opposti (su/giù o destra/sinistra), restringendo ulteriormente lo spazio di manovra del giocatore.

---

## 5. Seconda Modalità di Gioco (Wave Survival)
La **Seconda Modalità** (`game_mode_waves.gd`) passa da un focus temporale a uno incentrato sul combattimento strutturato. Il giocatore deve affrontare specifiche "Ondate" (Waves) di nemici.

### Struttura delle Ondate
Il gameplay è scandito da un array di dizionari che definisce le regole di ogni fase (`waves_data`). Sono previste 3 ondate totali:
1. **Ondata 1:** 3 nemici (Ufo), spawn lento (2.0s).
2. **Ondata 2:** 6 nemici, spawn accelerato (1.6s).
3. **Ondata 3:** 12 nemici, ritorno al ritmo 2.0s ma con mole numerica raddoppiata.

C'è una probabilità fissa del 10% che l'algoritmo sostituisca un nemico comune con un temibile "Ufo Divino" (`DIVINE_UFO_SCENE`).

### Fase Boss Finale (I Cacciatori)
Al termine della terza ondata, il gioco non finisce immediatamente. Lo schermo visualizza un segnale di allarme lampeggiante ("CACCIATORI IN ARRIVO!") e genera il boss dell'evento: due navicelle "Hunter" (Cacciatori).
- Questi nemici entrano in scena da fuori schermo, eseguendo una sequenza introduttiva cinematica (`start_intro`) posizionandosi simmetricamente sul lato sinistro e destro dell'arena.
- Solo dopo aver sconfitto questi ultimi due avversari, la partita decreterà la Vittoria.

### Achievement e Ricompense
- Oltre alle ricompense fornite per ogni ondata completata (5, 10, 15 biscotti), questa modalità include una variabile di tracking dei danni (`mai_colpito`). Se il giocatore completa l'intera modalità senza ricevere alcun danno, sblocca un traguardo speciale sul cloud ("secondaMod_MaiColpito").

---

## 6. Terza Modalità di Gioco (Endless Survival)
L'**Endless Mode** (`Game_Endless.gd`) è la sfida definitiva, pensata per i giocatori hardcore. Non vi è una condizione di vittoria: l'obiettivo è resistere il più a lungo possibile prima dell'inevitabile distruzione.

### Progressione e Sopravvivenza
- Il ciclo vitale premia attivamente i giocatori coriacei: allo scoccare di ogni minuto intero, il giocatore viene ricompensato con valuta (10 biscotti al min. 1, 15 al min. 2, e 20+ per i successivi) e riceve una Cura (Heal) di 3 punti vita.

### Spawner Multipli
A differenza delle altre modalità, qui i nemici sono gestiti da molteplici sistemi indipendenti che creano un ecosistema caotico:
- `NinjaSpawner`
- `TurtleSpawner`
- `AsteroidSpawner`
- `PurpleDevilSpawner`

### Il Sistema di "Invasione"
Il vero pericolo della modalità Infinita è rappresentato dalle **Invasioni**, eventi dinamici che costringono il giocatore a improvvisare.
- Una volta superati i primi 150 secondi di gioco, il sistema entra in stato di allerta.
- Ogni 40-60 secondi scatta un'Invasione. A schermo compare un avviso testuale rosso lampeggiante (`show_invasion_warning`), seguito dallo spawn di una delle seguenti calamità:
  1. **Invasione Ufo:** Spawn massiccio di Ufo normali e Divini dai bordi dello schermo.
  2. **Invasione Kamikaze:** Inserimento nella mappa di nemici rapidi pronti a schiantarsi contro il giocatore.
  3. **Invasione di Cacciatori:** Appaiono due Hunters ai lati dello schermo (esattamente come il boss della Seconda Modalità).

### Gestione del Game Over
Quando la salute del giocatore arriva a zero:
- Tutti i timer degli Spawner vengono brutalmente interrotti.
- Si attiva un drammatico effetto "Slow Motion" che rallenta il motore di gioco al 10% della velocità normale (`Engine.time_scale = 0.1`).
- Tutti i nemici, asteroidi e proiettili a schermo vengono distrutti.
- Dopo un secondo reale, il tempo torna normale, viene invocata la schermata di Game Over e viene forzato il salvataggio dei record e della valuta sul Cloud di Firebase.

---
## Conclusione
Il progetto dimostra una forte consapevolezza nelle logiche di Game Design, una solida organizzazione a stati dell'Interfaccia Utente e un'eccellente capacità di implementare cicli di gameplay modulari. L'utilizzo di Segnali (Signals), Tween per le animazioni e l'integrazione di servizi backend (Firebase) rendono l'applicativo un prodotto maturo ed esportabile.
