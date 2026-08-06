# R2 — Algoritmo e Reward Design: come deve imparare FocusMaxxer

> Report unificato R3 (metrica di outcome e reward design) + R4 (algoritmo: bandit contestuale, MRT,
> inferenza su dati adattivi). Risponde alla domanda: **come deve funzionare l'algoritmo, come impara
> dai dati, qual è il target da ottimizzare.**
>
> Stato: **COMPLETATO** (prima stesura). Budget di ricerca: 28 ricerche web, 6 WebFetch (2 falliti per
> parsing PDF, contenuto recuperato via ricerca testuale). Sezioni marcate ⚠️ NON VERIFICATO dove il
> dato numerico preciso non è stato recuperabile entro il budget.

**Indice**
1. [Il problema in una frase](#1-il-problema-in-una-frase)
2. [Il candidato attuale e i suoi limiti](#2-il-candidato-attuale-e-i-suoi-limiti)
3. [Ottimi degeneri e reward hacking](#3-ottimi-degeneri-e-reward-hacking)
4. [Candidati di reward alternativi](#4-candidati-di-reward-alternativi)
5. [Proxy, ancore e validità dei segnali disponibili](#5-proxy-ancore-e-validità-dei-segnali-disponibili)
6. [Il paradosso di misura e i dati mancanti](#6-il-paradosso-di-misura-e-i-dati-mancanti)
7. [MRT, JITAI e i casi reali in mHealth](#7-mrt-jitai-e-i-casi-reali-in-mhealth)
8. [Algoritmo: Thompson sampling, action centering, pooling](#8-algoritmo-thompson-sampling-action-centering-pooling)
9. [Inferenza valida su dati adattivi](#9-inferenza-valida-su-dati-adattivi)
10. [Non-stazionarietà, availability, non-aderenza](#10-non-stazionarietà-availability-non-aderenza)
11. [Warm start, safety, comunicazione dell'incertezza](#11-warm-start-safety-comunicazione-dellincertezza)
12. [**Reward function raccomandata**](#12-reward-function-raccomandata)
13. [**Architettura raccomandata**](#13-architettura-raccomandata)
14. [Roadmap a fasi](#14-roadmap-a-fasi)
15. [Bibliografia](#15-bibliografia)

---

## 1. Il problema in una frase

FocusMaxxer non può osservare la concentrazione: può osservare solo comportamento auto-dichiarato e
proxy rumorosi, non può randomizzare quando l'utente studia (solo cosa gli viene raccomandato), e
qualunque scalare che scelga di massimizzare verrà, prima o poi, gamed — dall'utente, dal sistema, o
da entrambi insieme. Il compito di questo report è scegliere una funzione di reward che (a) sia
calcolabile dal solo telefono, (b) resista ai quattro ottimi degeneri già identificati dal team, (c)
sia coerente con un algoritmo che deve imparare da ~75 decision point per utente, non da migliaia, e
(d) produca stime che restano statisticamente valide nonostante i dati siano raccolti da un sistema
che sta already agendo su quelle stesse stime (il problema dell'inferenza su dati adattivi, §9).

La tesi di questo report: **nessuna reward comportamentale pura risolve il problema**; la reward
comportamentale (rapporto durata pianificata/effettiva) va mantenuta come componente a bassa varianza
e zero-attrito, ma la componente decisiva — quella che rompe il ciclo "il bandit impara a predire
invece che a cambiare" — è il **recall a distanza per-item da spaced repetition** (§8.1 del handoff).
È l'unica candidata tra quelle esaminate che è insieme non manipolabile, ripetuta (molte osservazioni
per sessione anziché una), e ancorata a un costrutto — l'apprendimento — che l'app ha già deciso di
insegnare comunque (retrieval practice, evidenza più forte nel dominio: g=0.50, Rowland 2014). Le
sezioni §12–§13 formalizzano questa scelta in equazioni e pseudocodice.

---

## 2. Il candidato attuale e i suoi limiti

Il candidato di partenza è
R_comportamentale = durata_effettiva / durata_pianificata (troncato a [0,1] o a [0, cap] se si vuole
premiare un piccolo overrun). I suoi pregi restano validi dopo la ricerca:

- **Auto-normalizzato per sessione**: non richiede una nozione assoluta di "buona sessione" comune a
  tutti gli utenti/compiti, quindi è comparabile tra un ripasso di 20 minuti e un nuovo materiale da
  90.
- **Randomizzabile in modo pulito**: si randomizza la *durata suggerita* (il denominatore), che è
  esattamente ciò che l'algoritmo controlla — è la struttura di un'azione in un MRT, non un artefatto.
- **Zero attrito**: non richiede che l'utente inserisca nulla oltre a ciò che già dichiara a inizio
  sessione (tipo di compito, durata prevista) e alla chiusura (fine dichiarata/rilevata).

Ma è, per costruzione, un proxy comportamentale del tipo discusso da Nahum-Shani et al. (framework
JITAI: outcome prossimale vs distale) — misura **aderenza al piano**, non **qualità dell'apprendimento
avvenuto durante il piano**. La sezione §3 mostra perché questa distanza tra proxy e target reale è
esattamente il tipo di gap che produce reward hacking (Goodhart, Manheim & Garrabrant 2018): più lo
scalare viene ottimizzato, più diverge dall'obiettivo che doveva rappresentare. Il completion ratio
resta nella reward finale raccomandata (§12), ma come **componente**, mai come **unico termine**.

---

## 3. Ottimi degeneri e reward hacking

### 3.1 La tassonomia di Manheim & Garrabrant (2018)

Manheim & Garrabrant, *Categorizing Variants of Goodhart's Law* (2018, disponibile su arXiv e
ResearchGate, 79+ citazioni) formalizzano (almeno) quattro meccanismi distinti con cui una metrica
proxy M smette di tracciare l'obiettivo vero V quando viene ottimizzata:

1. **Regressional Goodhart**: M e V sono correlati ma non identici; selezionare per M estremo seleziona
   anche per la componente di M che *non* è V (rumore), quindi il valore atteso di V condizionato su M
   alto è più basso di quanto M alto suggerisca. Applicato a FocusMaxxer: sessioni con completion ratio
   molto alto non sono sistematicamente le sessioni con più apprendimento — sono anche, in parte, le
   sessioni con durata dichiarata artificialmente bassa.
2. **Extremal Goodhart**: la relazione M↔V, valida nel regime osservato storicamente, si rompe nella
   coda dove l'ottimizzatore spinge il sistema — un regime mai osservato prima. Il bandit che spinge
   verso durate sempre più brevi (perché il completion ratio sale) esce dal regime in cui "sessione
   più breve → più aderenza → più apprendimento" è mai stato vero.
3. **Causal Goodhart**: si interviene su M invece che sulla causa comune a monte. Se M = aderenza e la
   vera causa dell'apprendimento è "l'utente aveva già le condizioni giuste" (§3.1 handoff,
   endogeneità della selezione), ottimizzare M non cambia nulla della causa reale — il bandit impara a
   **predire** momenti favorevoli, non a **crearli**. Questo è il degenere "più insidioso" già
   identificato dal team, ed è precisamente un caso di Causal Goodhart.
4. **Adversarial Goodhart**: un agente (qui: l'utente, consapevolmente o no) ha un incentivo a
   manipolare M per ragioni proprie (percepire l'app come "generosa", ridurre l'attrito, chiudere la
   sessione prima). È il meccanismo dietro "premiare il completamento → dichiarare durate brevi".

### 3.2 I quattro degeneri noti, riletti con la tassonomia

| Degenere | Meccanismo Goodhart | Perché accade | Segnale osservabile che sta accadendo |
|---|---|---|---|
| Il bandit impara a *predire* il comportamento invece di *cambiarlo* | Causal | La reward comportamentale è a valle della stessa endogeneità di selezione che rende osservazionali le stime "ore migliori" invalide (§3.1 handoff) | Il coefficiente stimato per un'azione converge a un valore alto **anche condizionando solo sul braccio randomizzato**, cioè l'effetto causale (WCLS, §8) è ~0 mentre l'effetto osservazionale naive è grande |
| Minuti assoluti → sessioni lunghe e improduttive | Regressional / Extremal | Ottimizzare la quantità assoluta non normalizza per compito né penalizza il tempo-su-compito oltre il punto di vigilance decrement | Durata media suggerita cresce monotonicamente nel tempo senza che il proxy di qualità (recall, §4) cresca in proporzione |
| Premiare il completamento → l'utente dichiara durate brevi | Adversarial | Il completion ratio è manipolabile lato utente al momento della dichiarazione, prima che l'azione dell'algoritmo abbia effetto | Durata pianificata dichiarata scende nel tempo, specialmente negli utenti con completion ratio storicamente basso |
| Premiare il numero di sessioni → frammentazione | Regressional | Sessioni più frequenti e più corte massimizzano il conteggio senza che ciascuna sia di qualità | Durata media per sessione scende, frequenza sale, ma il tempo totale settimanale di studio (metrica non ottimizzata direttamente) resta piatto o scende |

### 3.3 Degeneri aggiuntivi non nella lista originale del team

- **Gaming della disponibilità (ρ_t)**: se l'algoritmo osserva "utente non disponibile" come dato
  mancante neutro invece che come possibile esito del trattamento passato, un utente può imparare che
  ignorare le notifiche per un periodo cambia la distribuzione delle raccomandazioni future (§10.3).
- **Reward hacking sulla dichiarazione del tipo di compito**: se "memorizzazione" riceve raccomandazioni
  sistematicamente più generose (finestre migliori, durate più permissive), l'utente è incentivato a
  dichiarare sempre "memorizzazione" indipendentemente dal compito reale — corrompendo il contesto S_t,
  non solo la reward.
- **Peak-end e self-report come reward**: se in futuro si aggiungesse un termine di reward basato sullo
  slider retrospettivo di fine sessione (§8.9 handoff), si eredita il bias peak-end documentato nella
  letteratura sul recall affettivo (Kahneman) — l'ultimo minuto di sessione domina la valutazione
  dell'intera sessione, indipendentemente dalla qualità media. Motivo per cui lo slider resta un'**ancora
  sparsa di validazione**, mai una componente di reward diretta (v. §5).
- **Reward non stazionaria per habituation**: se la reward include un termine di engagement (es. aprire
  l'app), il novelty effect documentato in mHealth (v. §6.10 sotto) fa sì che il valore atteso della
  stessa azione scenda nel tempo per ragioni non legate alla sua efficacia — un bandit non accorto la
  scambia per un peggioramento dell'azione, non del contesto temporale.

**Conseguenza per il design**: ogni componente ammessa nella reward deve superare un test esplicito —
*"un utente razionale che vuole solo un punteggio alto, senza voler davvero studiare meglio, può
alzarlo con un'azione a costo quasi zero?"* Il completion ratio fallisce parzialmente questo test
(può abbassare la durata dichiarata); il recall a distanza per-item (§4.1) lo supera per costruzione,
perché il costo per "gamarlo" è studiare davvero abbastanza bene da ricordare — che è l'obiettivo
stesso.

---

## 4. Candidati di reward alternativi

### 4.1 Recall a distanza da spaced repetition (§8.1 handoff) — il candidato principale

Se l'app gestisce flashcard/domande di richiamo (comunque necessario per implementare retrieval
practice, l'euristica di contenuto con supporto più forte: g=0.50, Rowland 2014), ogni card studiata
genera una traiettoria di richiami futuri. I modelli di memoria dello stato dell'arte forniscono un
target per-item, oggettivo e ripetuto:

- **Half-Life Regression** (Settles & Meeder 2016, ACL — il modello di Duolingo): definisce la
  probabilità di richiamo come p = 2^(−Δ/h), dove Δ è il tempo trascorso dall'ultima esposizione e h è
  l'emivita di memoria della card, stimata come funzione log-lineare di feature di storia e lessicali.
  In produzione a Duolingo ha ridotto l'errore di predizione del **45%** rispetto al baseline e
  aumentato l'engagement giornaliero del **12%** — numeri riportati dagli stessi autori, quindi da
  trattare come upper bound ottimistico (non indipendentemente replicati).
- **FSRS** (Free Spaced Repetition Scheduler, comunità open-spaced-repetition): evoluzione più recente
  basata su un modello DSR (Difficulty-Stability-Retrievability) a tre parametri per card, con
  ottimizzazione per-utente dei pesi via gradient descent su log dei propri richiami storici; oggi lo
  standard di riferimento tra gli scheduler open-source (Anki lo ha adottato come default), con
  benchmark pubblici (`open-spaced-repetition/srs-benchmark`) che lo confrontano contro SM-2 e HLR.

**Perché questo è il candidato che risolve §5 del handoff meglio di ogni alternativa comportamentale:**

1. **Non manipolabile dall'utente in modo economico.** A differenza del completion ratio, non esiste
   un modo a basso sforzo per alzare la probabilità di richiamo di domani senza aver effettivamente
   consolidato l'informazione oggi. L'unica "scorciatoia" — dichiarare di aver rivisto una card senza
   averla guardata — è rilevabile (tempo di risposta anomalo, pattern di risposta random) ed è comunque
   auto-punitiva: abbassa la propria stessa performance futura, non quella del sistema.
2. **Osservazioni per-item, non per-sessione.** Una sessione con 20 card genera 20 osservazioni di
   qualità dell'encoding, non 1. Questo è decisivo per il vincolo di potenza (§7.3): con ~75 decision
   point per utente nel pilota, disporre di un moltiplicatore ×10–×20 sul numero di osservazioni per lo
   stesso costo di raccolta è l'unica leva realistica per compensare N piccolo.
3. **Difendibile.** "Misuriamo se hai imparato, non se hai obbedito" è un claim che resiste a un audit
   esterno — importante data la sensibilità regolatoria già segnalata nel handoff (confine
   general-wellness).
4. **Compatibile col reframe centrale** (§4 handoff): il recall a distanza *è* l'outcome comportamentale
   che il bandit deve massimizzare via scheduling — non richiede di predire uno stato cognitivo latente,
   solo di osservare se l'informazione è rimasta.

**Costo, onestamente pesato**: richiede che l'utente inserisca materiale nell'app (flashcard). È
attrito reale — la stessa ragione per cui il team lo aveva lasciato come idea "da valutare" e non come
decisione presa. Tre mitigazioni, in ordine di maturità tecnica (cfr. R6 per l'approfondimento
sull'LLM-generation):
- Import da Anki/altri deck esistenti (basso costo ingegneristico, copre solo utenti già praticanti).
- Generazione automatica di domande dal materiale caricato (foto/PDF) via LLM — qualità delle domande
  generate è un'area di ricerca attiva, non ⚠️ verificata in questa sessione con benchmark specifici;
  va trattata come feature di fase 2, non di lancio.
- Riduzione del minimo utile: anche **poche card per sessione** (es. 3–5, non un mazzo completo) bastano
  a generare segnale se il modello di memoria è ragionevolmente calibrato — non serve digitalizzare
  l'intero corso.

**Rumore per-item e stabilità della stima.** Un singolo richiamo è un evento binario ad alta varianza
(p ∈ {0,1}); serve aggregazione. Con modelli DASH/FSRS-like, lo stimatore naturale non è il singolo
esito ma la **log-likelihood del modello di memoria sotto la sequenza osservata**, oppure la media della
probabilità di richiamo prevista per le card riviste in una finestra successiva alla sessione (es. 24h,
72h, 7gg — orizzonti multipli, non uno solo, per non premiare solo la memoria a brevissimo termine).
Con ~10–20 item per sessione la deviazione standard della proporzione di richiami corretti scende
abbastanza da rendere il segnale utilizzabile a livello di sessione già nel pilota.

### 4.2 Mind-wandering detection — scartata per il pilota, non per il futuro

Ricerca reale sul rilevamento del mind-wandering da segnali digitali, con thought probe come ground
truth: **EEG raggiunge 80–83% di accuratezza** in setting realistici tipo lezione dal vivo (classificazione
binaria within-subject); classificatori basati su **eye-gaze arrivano ad AUROC ≥0.80** in-domain ma
**crollano a 0.56–0.68 cross-domain**; modelli fisiologici/gaze validati su nuovi studenti (cross-subject)
raggiungono solo **18–23 punti percentuali sopra il caso** — un margine modesto. Fonti: studi EEG su
apprendimento video-based (*Frontiers in Human Neuroscience* 2023, PMC10267732); rilevamento gaze-based
durante lettura e visione panoramica guidata (*Scientific Reports* 2024/2025, PMC11564806); rilevamento
multimodale aware/unaware mind-wandering durante lezioni (ACM 2024).

**Verdetto**: nessuno di questi canali (EEG, eye-tracking dedicato) è disponibile su smartphone comune.
Le uniche proxy realisticamente accessibili — pattern di interazione con lo schermo, velocità di
risposta a probe testuali sporadici — non hanno letteratura di validazione diretta reperita in questa
sessione (⚠️ NON VERIFICATO per un'implementazione mobile-only). **Fuori scope per il pilota.** Un
thought-probe sporadico (1–2 al giorno, "stavi pensando al compito? sì/no/non ricordo") resta
un'opzione di *validazione*, non di reward — v. §5.

### 4.3 Digital phenotyping — proxy comportamentale, non reward diretta

**StudentLife** (Wang et al. 2014, ACM UbiComp; Dartmouth, 48 studenti, 10 settimane) resta il
riferimento del dominio: sensing continuo (conversazione, attività, mobilità, sonno, uso dello
smartphone) correlato con well-being mentale e performance accademica. Findings chiave: correlazioni
significative tra conversazione/attività/mobilità/sonno automaticamente sensati e outcome di benessere
mentale; un modello lasso-regularized su feature comportamentali predice il **GPA cumulativo**; è
documentato un "term lifecycle" — affetto positivo e attività alte a inizio semestre, stress crescente
e sonno/attività in calo verso la fine. Il successore **SmartGPA** (stesso gruppo Dartmouth) estende
l'analisi predittiva del GPA da comportamento sensato.

**Lettura spietata richiesta dal mandato**: gli R² riportati in questa famiglia di studi sono
tipicamente modesti e su campioni piccoli (N≈48–83, una singola istituzione/coorte, nessuna cross-validation
temporale esterna riportata nei risultati recuperati in questa sessione — ⚠️ i valori numerici di R² per
la predizione di GPA non sono stati recuperati con precisione in questa sessione, solo la direzione
qualitativa dei risultati). Il digital phenotyping passivo è quindi trattato qui come **feature del
contesto S_t** (baseline comportamentale, in linea con §3.4/§4 handoff — "ora del giorno + comportamento"),
**mai come reward**: non esiste, nella letteratura recuperata, un modello che lo tratti come outcome
per-decisione a granularità fine (i decision point di uno scheduling bandit sono ore, non settimane).

---

## 5. Proxy, ancore e validità dei segnali disponibili

### 5.1 Proxy comportamentali di sessione (screen-off, app-switching, dwell time)

Segnali come durata di schermo spento, numero di cambi app, tempo di permanenza sull'app di studio sono
economici da raccogliere ma — nella ricerca svolta in questa sessione — **non risultano ancorati a
ground truth di apprendimento in studi in-dominio**: la letteratura reperita li tratta o come feature
predittive di GPA/benessere a grana settimanale (StudentLife, §4.3), o come misure di engagement
nell'ambito mHealth generico (§6), non come validatori diretti della qualità della singola sessione di
studio. Vanno quindi trattati come **contesto S_t** (in linea con §3.4/§4 handoff: baseline
comportamentale prima ancora della biometria), non come reward: userli come target diretto
reintrodurrebbe un proxy manipolabile quanto il completion ratio, senza nemmeno il vantaggio della sua
semplicità interpretativa.

### 5.2 Self-report a fine sessione: cosa vale e cosa no

Uno slider retrospettivo di qualità percepita/difficoltà/distraibilità (§8.9 handoff) è un'**ancora
sparsa** nel senso del reframe (§4 handoff, punto sul self-supervised + ancore validate): non è
reward, ma dato di validazione contro cui testare se la reward comportamentale/di recall si comporta in
modo sensato. Due limiti documentati vanno rispettati nel design:

- **Decoupling self-report/arousal fisiologico**: la letteratura su misure soggettive di
  flow/concentrazione (Flow Short Scale, protocolli ESM) è nota per la debole correlazione con
  correlati fisiologici oggettivi — motivo per cui la biometria, quando ammessa, non va validata contro
  il self-report ma contro outcome comportamentali/di apprendimento indipendenti.
- **Bias peak-end**: la valutazione retrospettiva di un'esperienza è dominata dal picco e dalla fine,
  non dalla media (letteratura Kahneman su valutazione retrospettiva). Uno slider di fine sessione
  misura "come mi sono sentito negli ultimi minuti", non "quanto ho imparato in media" — coerente col
  motivo per cui §3.3 esclude esplicitamente il self-report dalla reward diretta.

### 5.3 Ruolo nel disegno complessivo

Proxy comportamentali e self-report entrano nella **funzione di validazione del sistema** (v. §12.4,
test di plausibilità/recovery test), non nella funzione obiettivo. Questo separa nettamente due domande
che il team tende a confondere: *"cosa ottimizza il bandit"* (§12) vs *"come verifichiamo che
l'ottimizzazione non sia degenerata"* (§12.4 + §3). Le ancore sparse servono solo alla seconda.

---

## 6. Il paradosso di misura e i dati mancanti

### 6.1 Missing-not-at-random nel mobile sensing: cosa dice la letteratura mHealth

Una rassegna dedicata — *Data Missing Not at Random in Mobile Health Research: Assessment of the
Problem and a Case for Sensitivity Analyses* (JMIR 2021, PMC8277392) — documenta che (a) c'è stata
**poca indagine sistematica** su come la mancanza di dati viene trattata negli RCT mHealth, (b) i
metodi standard per MAR (imputazione multipla, massima verosimiglianza) **non correggono il bias
quando i dati sono MNAR**, e (c) l'attrito differenziale tra braccio attivo e controllo è esso stesso
un segnale di MNAR probabile — es. partecipanti che beneficiano meno dell'intervento abbandonano più
spesso, distorcendo sistematicamente le stime residue verso l'alto.

Applicato a FocusMaxxer: il paradosso di misura (§3.2 handoff — l'assenza del telefono, segnale più
forte di deep work, è indistinguibile dall'abbandono dell'app) è un caso limite di MNAR — la mancanza
del dato è **causata dal successo dell'intervento stesso**. Non esiste, nella letteratura recuperata,
uno strumento che "risolva" questo (nessuna imputazione può distinguere ex-post i due casi da dati
comportamentali soli); esistono solo mitigazioni:

1. **Dichiarazione esplicita di inizio/fine sessione** (già nel concept): converte l'assenza di segnale
   in un evento positivo esplicito invece che in un buco nei dati. È la mitigazione col miglior
   rapporto costo/efficacia già identificata dal team.
2. **Trattare la disponibilità ρ_t come variabile modellata, non come missing neutro** (§10.3): se
   l'indisponibilità stessa è endogena al trattamento passato, va inclusa esplicitamente nel modello di
   selezione, non semplicemente scartata riga per riga.
3. **Sensitivity analysis stile Rosenbaum bounds**: quantifica quanto un confondente non osservato
   dovrebbe essere forte per invalidare la conclusione, invece di assumere MAR per comodità
   computazionale. Nel dominio mHealth generico esiste un precedente diretto per outcome continui:
   lo **stimatore delle medie troncate ("trimmed means")** per la sensibilità a dropout MNAR in trial
   clinici (PMC9303448) — imposta i valori mancanti al valore più estremo e poi "rifila" una frazione
   uguale da entrambi i gruppi prima di stimare l'effetto, dando un bound conservativo invece di una
   stima puntuale falsamente precisa. Applicabile come analisi di sensibilità secondaria sul reward
   comportamentale (dove il missing è plausibile), non necessario sul reward di recall (dove il dato
   manca solo se la card non viene mai ripresentata, un evento controllato dallo scheduler, non
   dall'utente).

### 6.2 Perché il recall a distanza soffre meno del paradosso di misura

Il reward di recall (§4.1) è meno esposto a questo problema per costruzione: la sua osservazione
dipende dallo **scheduler** (quando ripresenta la card), non dal comportamento spontaneo dell'utente
durante la sessione. Il momento della misura è scelto dal sistema, non subito passivamente — a patto
che l'utente riapra l'app abbastanza spesso da essere ri-testato, il che è comunque un prerequisito
minimo di qualunque intervento mHealth (v. attrition, §6.3 sotto e R5). Resta un caso di missingness
legato al **churn dell'app** (non-uso totale), ma non al successo della singola sessione — rompendo
proprio l'accoppiamento perverso che affligge la reward comportamentale pura.

### 6.3 Habituation e novelty effect come ulteriore fonte di non-stazionarietà del reward

Letteratura mHealth generale documenta un pattern robusto: utilizzo massimo all'adozione, calo
progressivo; **più di due terzi degli utenti** che scaricano un'app di salute mobile la usano una sola
volta e smettono (rassegna cross-sectional, *Healthcare* 2022, PMC8872344). Le notifiche mostrano
habituation misurabile (in un MRT su notifiche time-varying, *JMIR mHealth uHealth* 2023 e
PMC6293241, l'aver ricevuto una notifica il giorno prima è un predittore della risposta a quella
odierna). Implicazione diretta per §10.2 (non-stazionarietà): la reward attesa della stessa azione
**non è stazionaria nemmeno a comportamento dell'utente costante**, perché la sua efficacia decade con
l'esposizione — un fenomeno distinto dal drift stagionale (carico accademico, esami) e che va gestito
con gli stessi strumenti (discounting, sliding window) ma trattato come ipotesi di lavoro fin dal
disegno del pilota, non come sorpresa da scoprire dopo.

---

## 7. MRT, JITAI e i casi reali in mHealth

### 7.1 Il framework JITAI (Nahum-Shani et al.)

Un JITAI si specifica lungo sei elementi: **distal outcome** (obiettivo clinico/comportamentale a
lungo termine), **proximal outcome** (obiettivo a breve termine, valutato subito dopo il trattamento,
usato per verificarne l'efficacia immediata), **tailoring variables** (cosa personalizza la decisione),
**decision points**, **decision rules**, **intervention options**. Il proximal outcome esiste per
targettare meccanismi malleabili che *mediano* il distal outcome — non è un sostituto arbitrario, è
scelto per teoria. Per FocusMaxxer: il distal outcome plausibile è il rendimento accademico (§8.4
handoff, esami come outcome gratuito ma raro/rumoroso); il proximal outcome deve essere qualcosa che la
teoria dell'apprendimento collega causalmente a quel distal outcome — il che è un argomento a favore
del recall a distanza (§4.1) rispetto al completion ratio: il primo ha una teoria di mediazione diretta
(retrieval practice → consolidamento → performance d'esame), il secondo no.

### 7.2 Casi reali: algoritmo, reward, N, risultati

| Trial | Dominio | Algoritmo | Reward/outcome ottimizzato | N / durata | Risultato | Lezione operativa |
|---|---|---|---|---|---|---|
| **HeartSteps I** | Attività fisica, ipertensione stadio I | Contextual bandit, variante Thompson Sampling | log(0.5+step count) nei 30 min dopo la decisione | 44 adulti, 6 settimane, 5 decision point/giorno | Suggerimento vs nessun suggerimento: **+14% step nei 30 min (+35 step), p=.06** — effetto positivo ma al margine della significatività convenzionale | Anche un trial "di successo" nella narrativa pubblica atterra su un effetto piccolo e borderline: calibrare le aspettative sull'effect size prossimale |
| **HeartSteps II / "Personalized HeartSteps"** | Stesso dominio, algoritmo RL online personalizzante | RL con personalizzazione online (Liao et al., ACM IMWUT 2020) | Stesso reward log-step | Coorte successiva, 5 decision point/giorno | Il paper di follow-up **"Did we personalize?"** (Springer *Machine Learning* 2024, arXiv:2304.05365) costruisce un metodo di resampling *appositamente perché rilevare se la personalizzazione ha avuto luogo non è banale* | Il fatto stesso che serva un metodo statistico dedicato per verificare "abbiamo personalizzato?" è la lezione: la personalizzazione in mHealth con N piccoli **non si vede a occhio nudo nei dati aggregati**, va testata esplicitamente — motiva il recovery test in §12.4 |
| **DIAMANTE** | Attività fisica, diabete + depressione | Contextual multi-armed bandit su categoria messaggio + timing (4 fasce, 8–20) | Step count giornaliero | 3 bracci (RL-adattivo / messaggi random / controllo), popolazione multilingue, cliniche safety-net SF, durante COVID-19 (JMIR 2024, PMC11496924) | ⚠️ NON VERIFICATO in questa sessione: non è stato recuperato il confronto numerico esatto braccio-adattivo vs braccio-random (il fetch full-text non è riuscito); dalla struttura a 3 bracci — inclusione deliberata di un braccio "random messaging" come comparatore — si inferisce che gli autori stessi non davano per scontato che l'adattività battesse la randomizzazione pura | Il solo fatto che un trial di questa scala includa un braccio "messaggi casuali" come confronto pari-livello all'algoritmo adattivo conferma che nel campo si considera la randomizzazione permanente un comparatore serio, non uno strawman — coerente con l'approccio di FocusMaxxer (§3.1.2 handoff) |
| **Sense2Stop** | Cessazione fumo, gestione stress | MRT, classificatore cStress in tempo reale su sensori (Autosense) per rilevare "minuto probabilmente stressato" | Prompt di stress-management vs nessun prompt, micro-randomizzato su minuti stressati/non stressati | 75 fumatori adulti, sensori a torace/polso, 4gg pre-quit + 10gg post-quit | Obiettivo dichiarato: prompt riduce probabilità di stress e di fumare nelle 2h successive; lo stress corrente come moderatore dell'effetto (risultati numerici specifici non recuperati in questa sessione — ⚠️ NON VERIFICATO) | Esempio diretto di sensore biometrico usato come **variabile di contesto/moderatore** (S_t), non come reward — esattamente il ruolo assegnato alla biometria in FocusMaxxer (§3.4/§4 handoff) |
| **Oralytics** | Igiene orale (spazzolamento) | Online RL / contextual bandit, aggiornamento ogni 7gg | R = Q − C, dove Q = brushing quality, C = costo di invio messaggio (v. §7.4 sotto) | Fase pilota primavera 2023, 35 giorni, spazzolino Bluetooth | Risultati di efficacia non quantificati nei materiali recuperati in questa sessione (⚠️ NON VERIFICATO); il contributo rilevante qui è metodologico (reward design, v. §7.4) | Prima evidenza reale di un reward **composito con termine di costo esplicito** per proteggere da over-messaging — precedente diretto per il vincolo di §12.3 |
| **MyBehavior** | Attività fisica + dieta | Multi-armed bandit su suggerimenti "continua/evita/modifica" da log automatico+manuale | Comportamento seguito vs ignorato | Pilota 17 partecipanti (9 vs 8), 3 settimane | **Camminata significativamente maggiore nel gruppo MyBehavior vs controllo non-personalizzato (p=.05)**; differenza su scelte alimentari **non significativa (p=.15)** | Anche in un trial minuscolo la personalizzazione batte le raccomandazioni generiche per un outcome (attività), non per l'altro (dieta) — la personalizzazione non è un moltiplicatore uniforme, dipende dal costrutto |
| **StayWell** | ⚠️ NON VERIFICATO | — | — | — | Nessun dato affidabile recuperato in questa sessione di ricerca | Da verificare in una sessione dedicata prima di citarlo pubblicamente |

### 7.3 Calcolo di potenza esplicito: bastano 3.000 decision point?

La metodologia di riferimento è quella di **Liao et al. (2016)**, *Sample size calculations for
micro-randomized trials in mHealth* (implementata nei tool `MRTSampleSize`/`MRTSampleSizeBinary` su
CRAN e nel calcolatore Shiny "MRT-SS Calculator", arXiv:1609.00695), che risolve per la numerosità dato
un test dell'ipotesi nulla di **effetto prossimale marginale nullo** (o funzione del tempo), con i
seguenti input strutturali:

- **n**: numero di partecipanti
- **T**: numero di decision point totali per partecipante nello studio
- **p**: probabilità di randomizzazione al trattamento (spesso costante, es. 0.3–0.5 nei trial citati;
  può essere time-varying)
- **σ²**: varianza residua del proximal outcome
- **η (effect size standardizzato)**: la quantità che si vuole rilevare, tipicamente espressa come
  differenza standardizzata dell'effetto marginale del trattamento

La forma funzionale esatta della potenza dipende dalla struttura di correlazione within-subject
assunta (spesso una working independence o AR(1) sul residuo); i pacchetti citati la implementano
numericamente. Non essendo stato recuperato in questa sessione l'algebra chiusa completa (⚠️ va
riprodotta con il pacchetto R prima dell'uso operativo), il punto qualitativo cruciale — e sufficiente
per rispondere alla domanda "bastano 3.000 decision point?" — è il seguente:

**La potenza di un MRT scala con `n·T`, non con `n` o `T` isolatamente, ma il termine dominante per
rilevare *moderazione* (interazione trattamento×contesto, cioè personalizzazione) è più vicino a
`n·T` diviso per il numero di livelli del moderatore, non a `n·T` intero.** Con **40–50 utenti × 6
settimane × 3 decision point/giorno × ~60% availability ≈ 3.000 decision point** (~75/utente):

- Per l'**effetto prossimale medio marginale** (un solo coefficiente, il caso più favorevole): 3.000
  decision point con effect size atteso piccolo-medio (coerente con l'ordine di grandezza osservato in
  HeartSteps I, +14%, p=.06 su appena 44×6settimane×5/die ≈ 9.240 decision point lordi, meno
  disponibilità) sono **plausibilmente sufficienti per un segnale marginale**, ma HeartSteps I stesso —
  con un N di decision point lordi superiore — atterra su p=.06, cioè *non* raggiunge la significatività
  convenzionale al 5%. Questo è un dato diretto, non un'estrapolazione: **se un trial con più decision
  point disponibili di quelli pianificati per FocusMaxxer produce un effetto marginale al limite,
  3.000 decision point vanno considerati adeguati solo per un effetto di dimensione simile o
  maggiore, non per rilevare effetti più piccoli con confidenza.**
- Per i **moderatori principali** (es. l'effetto varia per ora del giorno, sì/no): dividendo
  effettivamente il campione in bracci di contesto, la potenza per singolo moderatore scende
  proporzionalmente al numero di livelli — con 3–4 fasce orarie e ~75 decision point/utente, restano
  ~19–25 decision point per utente per fascia, insufficiente per stime individuali stabili ma
  **adeguato per un effetto di moderazione a livello di popolazione con pooling** (da cui la necessità
  strutturale di IntelligentPooling, §8.3, non di bandit persona-per-persona).
- Per la **personalizzazione piena per-utente** (coefficiente stimato individualmente, senza pooling):
  ~75 osservazioni per persona sono **insufficienti** in modo netto — è esattamente la conclusione già
  scritta nel handoff (§4), qui confermata dal confronto con la letteratura di potenza reale: nessuno
  dei trial in tabella con N di decision point comparabile o superiore (HeartSteps 44×~150,
  Sense2Stop 75×~14gg) riporta stime individuali stabili senza un qualche meccanismo di pooling o
  effetti misti.

**Conclusione operativa**: i 3.000 decision point bastano per l'effetto medio della randomizzazione
(se di dimensione ≥ quella osservata in HeartSteps I) e per moderatori a pochi livelli con pooling
gerarchico. **Non bastano** per personalizzazione individuale piena, né — punto aggiuntivo non nel
handoff originale — per rilevare con confidenza un effetto **più piccolo** di quello di HeartSteps I,
che è già borderline. Questo rafforza l'argomento per moltiplicare le osservazioni via reward per-item
(§4.1, §9.4): a parità di decision point "comportamentali", il recall a distanza fornisce ~10–20×
osservazioni per la stima dell'effetto sul proximal outcome di apprendimento.

### 7.4 Reward design in Oralytics: il precedente più vicino al problema di FocusMaxxer

Il caso più direttamente trasferibile trovato in letteratura è la formalizzazione **esplicita** del
reward in Oralytics (*Reward Design For An Online Reinforcement Learning Algorithm Supporting Oral
Self-Care*, AAAI 2023 / arXiv:2208.07406):

```
Q_{i,t} = min(B_{i,t} − P_{i,t}, 180)          # brushing quality, in secondi
R_{i,t} = Q_{i,t} − C_{i,t}                     # reward finale = qualità − costo
```

dove B è la durata di spazzolamento, P la durata con pressione eccessiva, e la **troncatura a 180**
esiste esplicitamente per non premiare l'over-brushing (un secondo obiettivo raggiunto solo perché
qualcuno gaming il sistema spazzolando più a lungo del necessario). Il termine di costo C è pensato
per l'effetto del messaggio corrente sulla **responsività futura** — cioè un costo di habituation
esplicito nel reward stesso, non solo un vincolo esterno. È il precedente pubblicato più vicino alla
struttura raccomandata in §12: **reward primaria (qualità) meno un termine di costo/vincolo
(habituation, notification budget)**, non uno scalare unidimensionale ingenuo.

---

## 8. Algoritmo: Thompson sampling, action centering, pooling

### 8.1 Thompson sampling contestuale: garanzie e fragilità

Per bandit lineari contestuali, Thompson Sampling con prior e verosimiglianza gaussiane ottiene regret
Õ(d√T), vicino al lower bound teorico Ω(√dT) (Agrawal & Goyal 2013). Due limiti pratici documentati,
rilevanti per FocusMaxxer:

1. **Sensibilità alla misspecificazione del prior**: se il prior assegna probabilità troppo bassa
   all'azione ottimale vera, l'algoritmo tende a sotto-esplorarla sistematicamente — un rischio
   concreto se il warm-start (§11) da letteratura è mal calibrato in scala/unità.
2. **I bound di regret standard assumono prior diffusi/non informativi**: proprio l'opposto di quanto
   FocusMaxxer vuole fare (prior informativo da meta-analisi). Questo non invalida l'approccio, ma
   implica che i bound teorici pubblicati non si applicano direttamente al regime "prior fortemente
   informativo + N piccolo" in cui opera il pilota — un gap esplicito tra teoria e uso, da colmare con
   simulazione (recovery test, §12.4) piuttosto che con garanzie chiuse.

### 8.2 Action centering (Boruvka et al. 2018, JASA 113(523):1112–1121)

Il problema che risolve: in un MRT le azioni sono assegnate con probabilità di randomizzazione nota
π_t (spesso diversa da 0.5, e potenzialmente funzione del contesto), e i moderatori S_t possono essere
essi stessi influenzati da azioni passate. Un confronto ingenuo tra Y quando A=1 e Y quando A=0
confonde l'**effetto causale** con la **selezione indotta dalla storia**. Boruvka et al. definiscono
l'**effetto di escursione causale**:

```
ξ(t) = E[Y(t+1) | A(t)=1, H(t)] − E[Y(t+1) | A(t)=0, H(t)]
```

e lo stimano con **Weighted Centered Least Squares (WCLS)**:

```
Y(t+1) = β₀ + β₁·[A(t) − π(t)] + β₂ᵀS(t) + β₃ᵀ[A(t) − π(t)]·S(t) + ε(t)
w(t) = 1 / [π(t)·(1 − π(t))]
```

Il termine **[A(t) − π(t)]**, l'"azione centrata", è il cuore del metodo: sottraendo la probabilità di
randomizzazione nota, l'azione osservata viene ortogonalizzata rispetto alla storia che ha determinato
quella probabilità, rimuovendo la fonte di confondimento senza richiedere di modellare esplicitamente
il processo di selezione. Il peso w(t) = 1/[π(t)(1−π(t))] è l'analogo di un inverse-probability weight
che stabilizza la varianza della stima quando π(t) si allontana da 0.5. Le assunzioni necessarie:
disponibilità osservata correttamente (l'azione è offerta solo a decision point eleggibili),
assenza di confondenti non misurati nell'insieme dei moderatori S(t), consistenza (l'esito osservato
sotto A(t) coincide col potenziale outcome), e π(t) nota e registrata dal sistema — condizione che
FocusMaxxer soddisfa per costruzione, essendo l'algoritmo stesso a fissare π(t).

**Perché serve qui, non solo nei trial clinici**: senza centrare sull'azione, il bandit che apprende
online rischia di confondere "questo momento ha ricevuto raccomandazione A perché il contesto storico
lo suggeriva" con "raccomandazione A causa un esito migliore" — la stessa endogeneità di selezione di
§3.1 handoff, mascherata dentro l'algoritmo di apprendimento invece che nell'analisi post-hoc. Action
centering è quindi non un dettaglio statistico ma **l'implementazione algoritmica del vincolo
metodologico dominante del progetto**.

### 8.3 IntelligentPooling (Tomkins, Liao, Klasnja & Murphy 2021, *Machine Learning* 110(9):2685–2727)

Risolve il problema opposto e complementare: con N piccolo per utente, stimare un modello
completamente individuale è ad alta varianza (troppo lento a convergere), stimare un solo modello di
popolazione è distorto per utenti eterogenei (bias). IntelligentPooling usa una struttura **mista** con
pooling adattivo:

```
R_{i,k} = φ(S_{i,k}, A_{i,k})ᵀ w_i + ε_{i,k},      w_i = w_pop + u_i,   ε_{i,k} ~ N(0, σ_ε²)
```

dove w_pop sono i pesi di popolazione condivisi e u_i è la deviazione random-effect per l'utente i. La
distribuzione a posteriori dei pesi individuali si ottiene da un processo gaussiano equivalente:

```
ŵ_i = μ_w + M_iᵀ (K + σ_ε² I)^{-1} R̃_n
Σ_i = Σ_w + Σ_u − M_iᵀ (K + σ_ε² I)^{-1} M_i
```

con R̃_n il vettore di reward centrate sul prior e M_i la matrice di feature delle osservazioni
dell'utente i. Il punto operativo chiave: **la forza del pooling (Σ_u, varianza random-effect) non è
fissata a mano ma stimata online per massima verosimiglianza marginale**:

```
λ̂ = argmax_λ  −½ [ R̃_nᵀ (K(λ)+σ_ε²I)^{-1} R̃_n + log det(K(λ)+σ_ε²I) + n log(2π) ]
```

Quando la stima di Σ_u risulta piccola (utenti omogenei), il sistema pooled fortemente (comportamento
vicino a un modello di popolazione unico); quando Σ_u è grande (utenti eterogenei), il sistema
personalizza di più — **il grado di personalizzazione emerge dai dati, non è una scelta di design a
priori**. Il campionamento Thompson per la decisione al tempo k usa il posterior corrente:

```
π_{i,k} = Pr{ φ(s,1)ᵀ w̃_{i,k} > φ(s,0)ᵀ w̃_{i,k} },   w̃_{i,k} ~ N(ŵ_i, Σ_i)
```

**Risultato riportato**: −26% di regret medio rispetto allo stato dell'arte comparabile ("Gang of
Bandits"), con vantaggio dimostrato sia su popolazioni omogenee, sia bimodali, sia a variazione liscia
— cioè robusto a diverse ipotesi sulla vera eterogeneità tra utenti, che per FocusMaxxer è sconosciuta
a priori. Note implementative per un pilota a 40–50 utenti: aggiornamento degli iperparametri di
pooling su base periodica (nello studio di fattibilità citato, ogni 7 giorni, non ad ogni decisione:
un compromesso costo computazionale/adattività ragionevole anche qui), clipping della probabilità di
randomizzazione in un intervallo prefissato (nello studio citato [0.1, 0.8]) per garanzie di
inferenza successiva (§9), costo computazionale dominato dall'inversione del kernel O(n²) sul totale
delle osservazioni — trattabile con ~3.000 decision point totali, da rivalutare se il prodotto
scalasse a decine di migliaia di utenti.

### 8.4 RoME: un'alternativa più recente, non ancora il default raccomandato

**RoME** (Huch, Golbus, Shi, Moreno, Dempsey et al., NeurIPS 2024, arXiv:2312.06403) generalizza
l'idea di effetti misti aggiungendo (1) effetti random utente- e tempo-specifici sul reward
differenziale, (2) penalità di *network cohesion* tra utenti simili, (3) stima flessibile del reward
di baseline via debiased machine learning, ottenendo un regret bound che dipende solo dalla
dimensione del modello di reward differenziale (non dalla complessità del baseline, potenzialmente
non lineare). È più recente e più potente di IntelligentPooling su carta, ma non ha ancora lo stesso
corpo di validazione in deployment reale (validato in questa sessione solo su simulazione + due studi
di off-policy evaluation, non su un trial prospettico pubblicato). **Raccomandazione**: candidato di
seconda fase (dopo che IntelligentPooling ha stabilito una baseline in produzione), non per il lancio.

---

## 9. Inferenza valida su dati adattivi

### 9.1 Perché l'OLS ordinario fallisce (Zhang, Janson & Murphy 2020, NeurIPS 33:9818–9829)

Risultato centrale: l'OLS, asintoticamente normale su dati campionati indipendentemente, **non è
asintoticamente normale su dati raccolti da un bandit** (multi-braccio o contestuale) quando non
esiste un unico braccio ottimale — cioè esattamente sotto l'ipotesi nulla che interessa testare
("questa raccomandazione ha effetto zero"). La causa è che le azioni successive del bandit sono
correlate con le reward passate (per costruzione — è quello che rende il bandit efficiente), quindi il
regressore A_t non è indipendente dagli errori passati nel modo richiesto dai teoremi CLT standard.
Conseguenza pratica: **inflazione dell'errore di tipo I e intervalli di confidenza con copertura sotto
il livello nominale** — esattamente il contrario di quanto serve per testare se una raccomandazione
funziona davvero prima di darle credito nella policy.

### 9.2 Lo stimatore BOLS

Gli autori introducono il **Batched OLS (BOLS)**: si applica l'OLS non ai dati sequenziali continui,
ma dopo aver diviso la raccolta in **batch** — blocchi di osservazioni raccolti sotto una politica di
assegnazione fissata all'interno del batch, con la politica che può cambiare solo tra un batch e il
successivo. BOLS è dimostrato (1) asintoticamente normale sia per bandit multi-braccio sia contestuali,
e (2) **robusto alla non-stazionarietà della reward di base** — proprietà rilevante data l'habituation
documentata in §6.3 e il drift stagionale atteso (§10.2).

### 9.3 Implicazioni di design — non rimandabili all'analisi

Il vincolo del handoff (§3.3) è confermato e va precisato: **la raccolta deve essere batched by
design fin dall'inizio**, non solo l'analisi finale. In pratica:

- **Aggiornare i parametri del bandit (compresi i pesi di pooling, §8.3) solo a intervalli fissi**
  (es. ogni 7 giorni, coerente con la cadenza usata in IntelligentPooling), non ad ogni singola
  osservazione. All'interno di un batch, π(t) resta costante per una data combinazione di contesto/arm.
- **Probability clipping**: vincolare π(t) ∈ [π_min, π_max] (es. [0.1, 0.8], coerente col precedente
  IntelligentPooling) per evitare che il peso 1/[π(1−π)] (§8.2) esploda quando il bandit diventa
  troppo confidente — un requisito che serve sia alla stabilità della stima WCLS sia alla validità
  della normalità asintotica BOLS.
- **Split subject-wise e forward-chaining temporale, mai k-fold casuale**: per qualunque validazione
  del modello (recovery test incluso, §12.4), i fold devono rispettare l'ordine temporale e
  l'indipendenza tra soggetti — un fold che mescola osservazioni future e passate dello stesso
  bandit re-introduce esattamente la correlazione azione-storia che BOLS è costruito per neutralizzare
  solo se il disegno di raccolta è rispettato.
- **Pre-registrazione delle ipotesi primarie**: l'effetto prossimale medio (§7.3) e i moderatori
  principali vanno dichiarati prima della raccolta, non scelti ex-post sui dati del pilota — coerente
  con la pratica MRT standard (Boruvka et al. 2018; NIH d3c.isr.umich.edu).

### 9.4 Batch e potere statistico: interazione con §7.3

La scelta della dimensione del batch è essa stessa un trade-off di potenza: batch più piccoli
permettono all'algoritmo di adattarsi più in fretta (miglior regret operativo) ma riducono il numero
di "punti di aggiornamento indipendenti" disponibili per l'analisi BOLS, che tratta ogni batch come
un'unità quasi-indipendente ai fini della normalità asintotica. Con ~3.000 decision point totali e un
aggiornamento settimanale su un pilota di 6 settimane, si hanno **solo 6 batch** — un numero piccolo
per l'asintotica di BOLS, che tecnicamente richiede il numero di batch (non il numero di osservazioni
totali) a crescere. Questo è un limite reale del pilota, non risolvibile aumentando N di poco: va
gestito dichiarando esplicitamente il pilota come **fase di stima, non di conferma inferenziale
definitiva** (v. roadmap, §14) — le stime del pilota alimentano il prior della fase successiva, non
producono di per sé un claim causale definitivo con copertura nominale garantita.

---

## 10. Non-stazionarietà, availability, non-aderenza

### 10.1 Non-stazionarietà: strumenti disponibili

Due famiglie di metodi per bandit non-stazionari, entrambe consolidate: **metodi passivi di
dimenticanza** (sliding window UCB/TS, Discounted-TS/UCB — scartano o svalutano gradualmente
l'informazione vecchia) e **metodi attivi di rilevamento del cambiamento** (CUSUM-UCB, GLR-klUCB,
BR-MAB — decidono *quando* scartare in base a un test statistico di cambiamento). Varianti recenti
combinano le due (es. f-dsw TS, discount + sliding window insieme) per contesti con drift sia
graduale sia a regime (tipico di un anno accademico: drift gentile nella settimana normale, salto
discreto in settimana d'esami). Per FocusMaxxer la fonte di non-stazionarietà più rilevante — e più
prevedibile — resta quella già indicata dal team (§8.6 handoff: carico accademico come moderatore
dominante), affrontabile in parte come **feature del contesto S_t** (calendario esami dichiarato)
piuttosto che come drift da rilevare post-hoc: se il moderatore è osservato, non serve un
change-point detector per scoprirlo, serve solo includerlo nel modello (v. §12.2).

BOLS (§9.2) è dichiarato robusto alla non-stazionarietà della reward di **baseline** (l'intercetta),
non necessariamente a un drift dell'**effetto del trattamento stesso** nel tempo — distinzione che non
va confusa: se l'efficacia relativa di una finestra oraria cambia da settimana normale a settimana
d'esame (non solo il livello medio di reward), serve comunque un modello che permetta a β₁,β₃ (§8.2)
di variare, non solo β₀.

### 10.2 Availability ρ_t: modellazione e trappole

L'availability (l'utente è raggiungibile/interrompibile in quel decision point) va trattata come
processo esso stesso soggetto a possibile influenza del trattamento passato — non come missingness
neutra. Se una raccomandazione ignorata sistematicamente riduce la probabilità che l'utente sia
"disponibile" (nel senso operativo di aprire l'app) ai decision point successivi, allora condizionare
l'analisi solo sui decision point disponibili introduce un bias di selezione post-trattamento — lo
stesso principio dell'analisi ITT (§3.1.3 handoff): l'unità di analisi resta la raccomandazione
*emessa*, e ρ_t va modellato esplicitamente (es. come outcome secondario, o incluso nei pesi WCLS)
piuttosto che filtrato via.

### 10.3 Non-aderenza e la raccomandazione randomizzata come strumento IV

L'analisi ITT (raccomandazione emessa) stima l'**effetto dell'offerta**, non l'effetto del
comportamento effettivamente seguito. Per stimare quest'ultimo — "quanto aiuta *davvero* seguire il
consiglio, per chi lo segue" — la letteratura su encouragement design offre lo strumento naturale:
la randomizzazione della raccomandazione stessa è un'**instrumental variable (IV)** valida per
l'esposizione al comportamento, sotto due assunzioni:

1. **Exclusion restriction**: la raccomandazione influenza l'outcome (recall/completion) *solo*
   attraverso il canale del comportamento indotto, non con un effetto diretto indipendente. Assunzione
   discutibile qui: una notifica che suggerisce "studia ora" potrebbe avere un effetto placebo/motivante
   di per sé, indipendente dal fatto che l'utente segua l'orario suggerito — un rischio di violazione
   da testare (es. confrontando raccomandazioni "silenti" via dashboard vs notifiche push a parità di
   contenuto).
2. **Monotonicity**: nessun "defier" — nessun utente che fa esattamente il contrario di quanto
   raccomandato *a causa* della raccomandazione. Plausibile in questo dominio (reattanza esiste, ma
   tipicamente si manifesta come non-seguire, non come fare l'opposto attivo), ma non garantita: va
   dichiarata come assunzione, non dimostrata.

Sotto queste assunzioni, lo stimatore **CACE/LATE** (Complier Average Causal Effect / Local Average
Treatment Effect) identifica l'effetto del comportamento **per i complier** — gli utenti che seguono
la raccomandazione se e solo se ricevuta — non per la popolazione intera. È un uso legittimo e
"gratuito" (la randomizzazione esiste già per altri motivi metodologici, §3.1.2 handoff): non
richiede raccolta dati aggiuntiva, solo un'analisi supplementare che scompone l'effetto ITT in
effetto-sui-complier × tasso di compliance. Un precedente diretto in letteratura adiacente:
*Bounding the local average treatment effect in an instrumental variable analysis of engagement with
a mobile intervention* (arXiv:2008.06473) applica esattamente questo schema di bounding IV
all'engagement con un intervento mobile — conferma che l'approccio è transitato dalla teoria a
applicazioni mHealth reali, anche se con **bound** (intervalli, non punti) piuttosto che stime puntuali,
proprio perché le due assunzioni sopra restano difendibili solo entro un margine.

**Raccomandazione operativa**: riportare sia l'ITT (la stima primaria, pre-registrata, valida sotto
le assunzioni più deboli) sia il CACE/IV come analisi secondaria esplorativa — mai il contrario, e mai
usare il CACE per guidare la policy del bandit (che deve restare basata sull'effetto della
raccomandazione emessa, l'unica leva causale che il sistema controlla davvero, §3.1.1 handoff).

---

## 11. Warm start, safety, comunicazione dell'incertezza

### 11.1 Da effect size meta-analitico a prior bayesiano: il meccanismo

I **meta-analytic-predictive (MAP) prior** (letteratura clinica, es. Neuenschwander et al. e
successori; overview in PharmaLex/Emergent Mind) offrono il meccanismo diretto: sintetizzano dati
storici/esterni (qui: gli effect size meta-analitici di R1/R2) in una distribuzione predittiva
informativa sul parametro del nuovo studio, con **shrinkage automatico verso il pooled estimate**
proporzionale all'eterogeneità tra le fonti storiche (misurata da un prior sul parametro di
eterogeneità τ, tipicamente half-normal o half-Cauchy). Il vantaggio documentato in ambito clinico:
riduzione della dimensione campionaria necessaria e aumento della potenza a parità di N — esattamente
la leva che serve con un pilota da ~3.000 decision point (§7.3).

**Traduzione pratica per un coefficiente del bandit** (β nel modello WCLS, §8.2):

1. **Standardizzare l'unità**: l'effect size di letteratura (es. d di Cohen, g di Hedges) è quasi
   sempre riferito a un outcome diverso da quello di FocusMaxxer (voti/punteggi di test in laboratorio,
   non recall a distanza o completion ratio in-app). La conversione richiede un passaggio esplicito e
   dichiarato: o si riscala l'effect size sulla deviazione standard *attesa* del proximal outcome scelto
   (stimata da dati pilota preliminari o da studi affini, es. varianza del recall in FSRS/HLR), oppure
   si tratta l'effect size di letteratura solo come **direzione e ordine di grandezza relativo tra
   arms**, non come valore assoluto — la scelta più difendibile dato il gap di dominio.
2. **Centrare il prior su una versione attenuata dell'effetto di laboratorio**: la letteratura RCT di
   laboratorio sovrastima sistematicamente l'effetto atteso in un contesto applicato a bassa aderenza
   (coerente col divario osservato altrove nel progetto, es. Schwarz et al. 2026: atteso 8× più grande
   dell'osservato). Prior pratica: centrare su una frazione (es. 25–50%, arbitrario ma dichiarato) del
   d/g di letteratura, non sul valore pieno.
3. **Shrinkage esplicito via τ**: se più fonti riportano stime eterogenee (es. Donoghue & Hattie 2021
   riporta un pool 0.56 su 10 tecniche eterogenee), il prior deve riflettere quella eterogeneità con
   una varianza propria (non un punto), altrimenti il warm-start è overconfident fin dal giorno 1 — un
   rischio diretto per Thompson Sampling (§8.1, sensibilità a prior mal calibrati).
4. **Prior predictive check prima del deploy**: simulare dati dal prior scelto e verificare che le
   traiettorie generate (es. distribuzione dei completion ratio simulati) siano plausibili — se il
   prior implica reward attese fuori dal range fisicamente possibile, va ricalibrato prima, non dopo.

### 11.2 Safety / policy floor

Il principio "se il sistema appreso fa peggio delle euristiche, torna alle euristiche" (§4 handoff) ha
un corrispettivo formale nella letteratura di **conservative bandits**: ad ogni round, l'azione
suggerita dall'algoritmo (qui: TS pooled) viene eseguita solo se soddisfa un vincolo di performance
minima rispetto a una baseline nota (le euristiche validate come policy di riferimento); altrimenti si
esegue l'azione della baseline. Formalizzazioni più generali (framework **Seldonian**, algoritmi
SPIBB — Safe Policy Improvement with Baseline Bootstrapping, incl. varianti multi-obiettivo) offrono
garanzie ad alta probabilità che la nuova policy non peggiori la baseline lungo ciascun obiettivo
dichiarato — rilevante se si adotta un reward vincolato multi-obiettivo (§12.3). Per FocusMaxxer, il
meccanismo minimo implementabile senza machinery pesante: **vincolo stage-wise** — l'azione scelta dal
bandit è eseguita solo se il suo valore atteso posteriore supera quello della baseline euristica per
una soglia di confidenza dichiarata; altrimenti si esegue la baseline. Più semplice dei framework SPIBB
completi, sufficiente per un pilota, upgradabile in seguito.

### 11.3 Comunicazione dell'incertezza

Il team vuole fasce ordinate, non punteggi continui (coerente con §6 handoff, rischio di
sovra-affermazione visiva su R²<15%). Questo è coerente con l'output naturale di Thompson Sampling:
la probabilità posteriore che un'azione sia la migliore, discretizzata in bande (es. "raccomandato con
alta confidenza / moderata / esplorativo") invece di esporre il valore atteso continuo — evita di
comunicare falsa precisione su un modello con potere esplicativo realisticamente basso, e rende
visibile all'utente quando una raccomandazione è nella frazione esplorativa permanente (§3.1.2
handoff) piuttosto che nella frazione "il sistema ha imparato qualcosa" — trasparenza che, per la
letteratura su algorithm aversion/appreciation trattata in R5, è probabile che aumenti l'adesione più
di quanto la comunicazione di falsa certezza la aumenterebbe.

---

## 12. Reward function raccomandata

### 12.1 Tre alternative candidate, valutate

**Alternativa A — Completion ratio puro (baseline attuale).**
```
R_A(t) = clip(durata_effettiva(t) / durata_pianificata(t), 0, 1)
```
*Pro*: zero attrito, disponibile dal giorno 1, comparabile tra compiti. *Contro*: vulnerabile a tutti
e quattro i degeneri di §3 (in particolare Causal Goodhart — impara a predire, non a cambiare —
e Adversarial Goodhart — durate dichiarate artificialmente brevi). Nessuna difesa evidenziale contro
l'obiezione "misurate obbedienza, non apprendimento". **Scartata come reward unica**, mantenuta come
componente (§12.2).

**Alternativa B — Reward composita comportamento + engagement (proxy multipli pesati).**
```
R_B(t) = w1·completion_ratio(t) + w2·session_count_norm(t) + w3·self_report(t)
```
*Pro*: usa più segnali disponibili subito, nessun attrito aggiuntivo. *Contro*: ogni termine aggiunto
introduce un proprio canale di gaming (§3.3: frammentazione da session_count, bias peak-end da
self_report) e i pesi w_i sono arbitrari — un problema di scalarizzazione documentato in letteratura
sui bandit multi-obiettivo (la scalarizzazione nasconde i trade-off invece di renderli espliciti,
Constrained Contextual Bandits literature, §10 sopra). **Scartata**: aggiunge complessità senza
risolvere il problema strutturale di §3 (proxy comportamentali, non outcome di apprendimento).

**Alternativa C — Recall a distanza per-item, vincolato su aderenza minima e budget di notifiche
(raccomandata).**
```
Reward primaria:   R_C(t) = media_i∈items(t) [ p̂_recall(item_i, orizzonte=24h/72h/7gg) ]
Vincoli:           completion_ratio(t) ≥ soglia_floor   (altrimenti: fallback a policy euristica)
                   notifiche_settimana(utente) ≤ budget  (hard constraint, mai violabile)
```
*Pro*: non manipolabile a basso sforzo (§4.1, punto 1), osservazioni per-item quindi molte per sessione
(§4.1, punto 2 — critico dato il vincolo di potenza di §7.3), difendibile ("misuriamo apprendimento"),
coerente col reframe (fisiologia/comportamento come contesto S_t, apprendimento come target, §4
handoff). *Contro*: richiede inserimento di materiale (attrito reale, §4.1), non disponibile per
utenti che non usano le flashcard, richiede il modello di memoria (HLR/FSRS-like) come componente
tecnica aggiuntiva. **Scelta motivata**: è l'unica delle tre che rompe strutturalmente il Causal
Goodhart della reward comportamentale — non perché "misura meglio la concentrazione" (nessuna reward
comportamentale può, dato il tetto R²<10–15% del progetto), ma perché il suo bersaglio (probabilità di
richiamo futura) è **causalmente a valle** della qualità della sessione in un modo che il completion
ratio non è: si può dichiarare una durata breve senza cambiare nulla, ma non si può "dichiarare" di
ricordare domani una card non consolidata oggi.

### 12.2 Reward finale raccomandata: formalizzazione completa

Combina il termine primario (C) con il termine comportamentale (A) come **componente secondaria a
bassa varianza, sempre disponibile**, per gli utenti/sessioni senza flashcard, e come termine di
regolarizzazione anche quando (C) è disponibile — evita che il sistema ignori completamente
l'aderenza in favore di ottimizzare solo il recall su un piccolo sottoinsieme di card facili:

```
                 ⎧ α·R_C(t) + (1−α)·R_A(t)        se items(t) ≠ ∅   (sessione con flashcard)
R(t) =           ⎨
                 ⎩ R_A(t)                          altrimenti        (fallback comportamentale puro)

con:
  R_C(t) = (1/|items(t)|) Σ_i  p̂(recall | item_i, Δ=24h)     ∈ [0,1]
  R_A(t) = clip(durata_effettiva(t) / durata_pianificata(t), 0, cap=1.2)   # piccolo margine per overrun
  α ∈ [0.5, 0.8]   (peso del termine di apprendimento; iniziare conservativo, es. 0.5, e
                     spostare verso 0.7-0.8 dopo il recovery test di §12.4)
```

**Vincoli espliciti (reward vincolato, non scalarizzazione nascosta — §8.13 handoff):**

```
Vincolo 1 (safety/policy floor, §11.2):
   Esegui l'azione del bandit SOLO SE  E[R(t) | azione_bandit] ≥ E[R(t) | azione_euristica] − ε
   ALTRIMENTI esegui l'azione euristica.   (ε = margine di tolleranza statistica, non zero secco,
   per non bloccare l'esplorazione su rumore campionario)

Vincolo 2 (budget di notifiche/interruzioni, hard):
   notifiche_inviate(utente, settimana) ≤ N_max     (violazione: mai permessa, non negoziabile
   nell'ottimizzazione — implementato come maschera sulle azioni disponibili, non come termine
   di penalità nel reward)

Vincolo 3 (anti-frammentazione):
   sessioni_giorno(utente) non entra nella reward, ma è monitorato come metrica di sanità
   (§12.4) — se sale mentre R(t) sale, è un segnale di gaming da investigare, non da correggere
   automaticamente via reward (rischio di introdurre un nuovo canale di gaming, §3.3)
```

**Perché vincolato e non scalarizzato**: uno scalare unico che sommasse anche il budget di notifiche
o l'anti-frammentazione nasconderebbe il trade-off (quanti punti di apprendimento "valgono" una
notifica in più?) dietro un peso arbitrario — esattamente il problema già scartato in Alternativa B.
Trattare i vincoli come vincoli hard (azioni mascherate) o come gate stage-wise (§11.2) invece che come
termini pesati preserva l'interpretabilità e non introduce nuovi gradi di libertà da calibrare a mano.

### 12.3 Test anti-degenerazione (piano di validazione)

Prima del deploy e periodicamente durante il pilota:

1. **Simulazione avversariale**: simulare un utente "razionale gaming" che minimizza sforzo massimizzando
   R(t) secondo ciascuna definizione (A, B, C, finale) e verificare quale strategia emerge come
   ottimale. Per (C) finale, la strategia ottimale del simulatore deve rimanere "studiare abbastanza da
   ricordare" — se emerge una scorciatoia più economica (es. inserire card banalmente facili), va
   corretta prima del deploy (es. normalizzando per la difficoltà storica della card, già una feature
   nativa dei modelli DSR/FSRS).
2. **Monitoraggio delle metriche non ottimizzate** (§3.2, "segnale osservabile che sta accadendo"):
   durata media dichiarata, frequenza sessioni, tempo totale settimanale, difficoltà media delle card
   inserite — se una di queste si muove in modo correlato con R(t) al rialzo ma le altre (specialmente
   il recall a orizzonti lunghi, 7gg, più difficile da gamificare di quello a 24h) restano piatte o
   peggiorano, è un allarme di Goodhart in corso.
3. **Confronto ITT vs braccio randomizzato puro** (§3.1.2/§10.3): se l'effetto marginale del braccio
   "raccomandazione seguita" non supera significativamente quello del braccio "raccomandazione
   randomizzata pura" sulla reward finale, il sistema non sta ancora producendo valore di
   personalizzazione reale — condizione esplicita di **non-avanzamento** nella roadmap (§14).

### 12.4 Recovery test e test di plausibilità (dettaglio)

Prima di fidarsi delle stime del bandit su dati reali, verificare su dati **simulati con verità nota**:

- **Recovery test**: generare dati sintetici da un modello dove gli effetti noti da letteratura sono
  iniettati per costruzione (es. "il retrieval-practice-arm ha effetto vero +0.5σ sul recall, lo
  spacing-arm +0.3σ, l'ora del giorno non ha effetto vero"). Far girare la pipeline completa (WCLS +
  IntelligentPooling + BOLS, §8–9) su questi dati e verificare che gli stimatori ricostruiscano gli
  effetti iniettati entro l'incertezza attesa. Se il sistema non recupera effetti noti su dati puliti,
  non c'è motivo di fidarsi delle sue stime su dati reali rumorosi.
- **Test di plausibilità dei coefficienti**: i segni e gli ordini di grandezza dei coefficienti stimati
  devono essere compatibili con la letteratura di R1/R2 (es. il coefficiente per retrieval-practice non
  dovrebbe mai stimarsi negativo con alta confidenza — se accade, è più probabile un bug o una
  violazione delle assunzioni di WCLS che una vera scoperta contro-intuitiva, e va trattato come tale
  prima di essere esposto in UI).
- **Policy floor come test continuo**, non solo come vincolo di esecuzione (§11.2/§12.2 Vincolo 1): il
  confronto E[R|bandit] vs E[R|euristica] va tracciato come metrica di monitoraggio dashboard, non solo
  come gate one-off.

---

## 13. Architettura raccomandata

### 13.1 Specifica del sistema

**Decision points**: fino a ~3/giorno per utente — (a) prima dell'inizio sessione (finestra e modalità
suggerite, il decision point più prezioso secondo §8.2 handoff, fuori scope stretto di questo report
ma condiviso strutturalmente con R5), (b) a inizio sessione dichiarata (durata suggerita, tipo di
compito confermato), (c) opzionale a fine sessione (se generare o meno un prompt di richiamo
immediato).

**Availability ρ_t**: 1 se l'utente ha aperto l'app/è in una finestra interagibile, 0 altrimenti.
Modellata esplicitamente (§10.2), non scartata.

**Context S_t** (feature del modello, tutte low-cost, coerenti col gate biometrico §3.4 handoff):
ora del giorno (encoding circolare: sin/cos), giorno settimana, tipo di compito dichiarato, minuti dal
risveglio stimato (da cronotipo MCTQ/µMCTQ, cold start §6 handoff), completion ratio storico
dell'utente (rolling window), difficoltà/stabilità media delle card in coda (se disponibili), flag
periodo esami (dichiarato, §8.6 handoff), biometria *solo se* ha superato il gate di ablazione (§3.4
handoff) — trattata come feature aggiuntiva in S_t, mai come target.

**Actions A_t**: le euristiche validate come arms (retrieval practice on/off, spacing suggerito
on/off, durata suggerita ∈ {breve, media, lunga}, finestra oraria suggerita ∈ {fasce pre-definite}) —
ciascuna randomizzata con probabilità π(t) ∈ [π_min, π_max] = [0.10, 0.85] (floor di esplorazione
permanente ~10-15% come da §3.1.2 handoff, cap per evitare pesi WCLS degeneri, §9.3).

**Reward**: R(t) come definito in §12.2.

### 13.2 Pipeline end-to-end (pseudocodice)

```
# ---- FASE ONLINE: assegnazione dell'azione (gira ad ogni decision point) ----
function ASSEGNA_AZIONE(user_i, S_t):
    # 1. Policy floor / safety gate (§11.2, §12.2 Vincolo 1)
    valore_atteso_euristica = VALUTA_EURISTICA(S_t)          # policy fissa da letteratura (R1/R2)

    # 2. Campionamento Thompson dal posterior mixed-effects corrente (§8.3)
    w_tilde_i ~ N(w_hat_i, Sigma_i)                            # posterior utente i, aggiornato a batch
    valori_attesi = { a: phi(S_t, a)^T · w_tilde_i  for a in Actions }
    azione_candidata = argmax_a valori_attesi[a]

    # 3. Confronto col floor (§12.2 Vincolo 1)
    if valori_attesi[azione_candidata] < valore_atteso_euristica - epsilon:
        azione_scelta = VALUTA_EURISTICA(S_t).azione            # fallback esplicito

    # 4. Randomizzazione permanente sovrapposta (§3.1.2 handoff)
    pi_t = clip(PROBABILITA_SOFTMAX(valori_attesi), pi_min=0.10, pi_max=0.85)
    azione_scelta = SAMPLE(Bernoulli(pi_t) su azione_candidata vs baseline)

    # 5. Vincolo hard sul budget notifiche (§12.2 Vincolo 2) — maschera le azioni, non pesa il reward
    azione_scelta = APPLICA_MASCHERA_BUDGET(azione_scelta, notifiche_settimana(user_i))

    LOG(user_i, t, S_t, azione_scelta, pi_t)                    # pi_t noto e registrato: prerequisito WCLS
    return azione_scelta


# ---- FASE DI OSSERVAZIONE: calcolo della reward (asincrono, dopo l'orizzonte di osservazione) ----
function CALCOLA_REWARD(user_i, t):
    if items(t) non vuoto:
        R_C = mean( p_hat_recall(item, horizon=24h) for item in items(t) )   # da modello FSRS/HLR
        R = alpha * R_C + (1 - alpha) * R_A(t)
    else:
        R = R_A(t)                                               # completion ratio, §12.2
    LOG_REWARD(user_i, t, R)
    return R


# ---- FASE BATCH: aggiornamento del modello (gira ogni 7 giorni, MAI ad ogni osservazione — §9.3) ----
function AGGIORNA_MODELLO_BATCH(batch_dati):
    # 1. Stima WCLS action-centered per l'effetto causale marginale/moderato (§8.2)
    for ogni azione a in Actions:
        fit_WCLS( Y ~ beta0 + beta1*(A - pi) + beta2*S + beta3*(A-pi)*S,
                   weights = 1/(pi*(1-pi)),
                   data = batch_dati[batch_dati.azione == a] )

    # 2. Aggiornamento mixed-effects posterior (IntelligentPooling, §8.3)
    lambda_hat = argmax_lambda LogLikelihoodMarginale(batch_dati, lambda)   # Sigma_u, sigma_eps^2
    for ogni utente i:
        (w_hat_i, Sigma_i) = POSTERIOR_UPDATE(batch_dati[i], lambda_hat, prior=MAP_prior)

    # 3. Inferenza valida (§9.2): applicare BOLS sui batch accumulati per i test di ipotesi
    #    primari pre-registrati (effetto prossimale medio, moderatori principali)
    BOLS_estimate = fit_BOLS(tutti_i_batch_fin_qui)

    # 4. Test di sanità prima di promuovere il modello aggiornato in produzione (§12.4)
    if not RECOVERY_TEST_PASS(lambda_hat, w_hat) or not PLAUSIBILITY_CHECK(w_hat):
        ROLLBACK a versione precedente del modello; ALERT team
    else:
        DEPLOY(w_hat, lambda_hat)
```

### 13.3 Perché questa combinazione e non altre

- **TS invece di UCB puro**: più naturale per l'esposizione dell'incertezza come probabilità/fasce
  (§11.3), e l'infrastruttura di posterior gaussiano è condivisa con IntelligentPooling (stesso
  linguaggio matematico, non due sistemi separati da far convivere).
- **Action centering non opzionale**: senza di esso, ogni stima di effetto — anche quella usata solo
  per il ranking interno delle azioni — eredita l'endogeneità di selezione che l'intero progetto è
  costruito per evitare (§8.2). Va implementato dal primo giorno, non aggiunto dopo.
- **IntelligentPooling invece di modelli persona-per-persona o un solo modello di popolazione**: è
  l'unico dei tre regimi coerente col vincolo di potenza (§7.3 — 75 osservazioni/utente insufficienti
  per personalizzazione piena, ma il pooling permette comunque un guadagno misurabile, −26% regret
  riportato).
- **RoME non nel percorso critico di lancio** (§8.4): più potente ma meno validato in deployment reale;
  riconsiderare dopo che IntelligentPooling ha stabilito una baseline in produzione (fase 3 della
  roadmap, §14).
- **BOLS come livello di inferenza separato dalla policy operativa**: il bandit (TS+pooling) decide le
  azioni in tempo quasi-reale; BOLS gira sui batch accumulati per produrre le stime *con garanzie
  statistiche* che alimentano i report, le decisioni di go/no-go della roadmap e gli aggiornamenti del
  prior — due sistemi con scopi diversi (decisione operativa vs inferenza valida) che condividono i
  dati ma non la stessa procedura di stima.

---

## 14. Roadmap a fasi

| Fase | Cosa gira | Reward attiva | Criterio di ingresso | Campione richiesto | Criterio di passaggio alla fase successiva |
|---|---|---|---|---|---|
| **0 — Strumentazione** | Nessun algoritmo: solo raccolta con randomizzazione uniforme delle azioni (MRT puro, tutte le π_t fisse e note, es. 0.5 dove possibile) | R_A soltanto (completion ratio) — R_C non ancora disponibile finché le flashcard non sono in produzione | — | Prime 1-2 settimane del pilota | Pipeline di logging (S_t, A_t, π_t, R(t)) validata end-to-end; nessun dato perso; π_t effettivamente registrata per ogni decisione |
| **1 — MRT puro con reward composita** | Randomizzazione fissa (non ancora bandit adattivo), ma R(t) completa (R_C + R_A, §12.2) attiva non appena il modulo flashcard è live | R(t) completo | Modulo flashcard/domande di richiamo in produzione; modello FSRS/HLR calibrato su dati minimi (anche da letteratura come cold-start) | Tutto il pilota, ~3.000 decision point | Stima WCLS dell'effetto prossimale medio con BOLS (§9.2) su ≥4-6 batch; recovery test (§12.4) passato su dati simulati; nessuna violazione dei vincoli hard (§12.2) osservata |
| **2 — Bandit pooled (IntelligentPooling)** | TS + action centering + pooling misto, come da pseudocodice §13.2, MA con floor euristico dominante (ε piccolo, quindi il bandit devia poco dalla baseline) | R(t) completo | Fase 1 completata con criteri soddisfatti; prior MAP calibrato (§11.1) e superato il prior predictive check | Continuazione del pilota o estensione a coorte 2 (obiettivo: accumulare batch sufficienti per l'asintotica BOLS, §9.4 — idealmente ≥10-15 batch, quindi estensione oltre le 6 settimane iniziali) | Confronto ITT vs braccio randomizzato puro (§12.3, punto 3) mostra effetto di personalizzazione misurabile e positivo; nessun segnale di Goodhart nei monitoraggi (§12.3, punto 2); policy floor mai violato in modo sistematico |
| **3 — Personalizzazione a effetti misti matura + valutazione RoME/CACE** | Pooling con più fiducia nel componente random-effect (α di pooling verso personalizzazione più alta, emerge dai dati, §8.3); analisi CACE/IV come stima secondaria (§10.3); valutazione di RoME come possibile upgrade (§8.4) | R(t) completo, eventualmente con α (§12.2) alzato verso 0.7-0.8 se il recovery test lo giustifica | Fase 2 completata; N utenti/decision point sufficiente per stime individuali non totalmente dominate dal prior di popolazione | Scala di prodotto (oltre il pilota) | Criterio di business/prodotto, non solo statistico — fuori scope di questo report (v. R6 per considerazioni di scala) |

**Nota sul non-avanzamento**: ogni fase ha un criterio di **non passaggio esplicito** (§12.3, punto 3):
se l'ITT non supera il braccio puramente randomizzato, il sistema resta in Fase 1/2 più a lungo
piuttosto che avanzare su una base statistica debole — coerente con l'intero impianto metodologico del
progetto, che tratta l'assenza di personalizzazione dimostrata come esito di default, non come
fallimento da nascondere.

---

## 15. Bibliografia

### Reward design, Goodhart, JITAI

- Manheim, D., & Garrabrant, S. (2018). *Categorizing Variants of Goodhart's Law*. arXiv:1803.04585. —
  [arXiv](https://arxiv.org/abs/1803.04585) · [ResearchGate](https://www.researchgate.net/publication/323747167_Categorizing_Variants_of_Goodhart's_Law)
- Nahum-Shani, I., Smith, S. N., Spring, B. J., Collins, L. M., Witkiewitz, K., Tewari, A., & Murphy,
  S. A. (2018). *Just-in-Time Adaptive Interventions (JITAIs) in Mobile Health: Key Components and
  Design Principles for Ongoing Health Behavior Support*. **Annals of Behavioral Medicine** 52(6),
  446–462. — [Oxford Academic](https://academic.oup.com/abm/article/52/6/446/4733473)
- Settles, B., & Meeder, B. (2016). *A Trainable Spaced Repetition Model for Language Learning*.
  **ACL 2016**. — modello half-life regression, deployment Duolingo (−45% errore predizione, +12%
  engagement giornaliero)
- FSRS / DSR model — [open-spaced-repetition/free-spaced-repetition-scheduler](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler),
  benchmark: [open-spaced-repetition/srs-benchmark](https://github.com/open-spaced-repetition/srs-benchmark)

### mHealth: casi reali, bandit e reward

- Klasnja, P., et al. — HeartSteps micro-randomized trial; reward log(0.5+step count), +14%
  (+35 step), p=.06 su 44 adulti/6 settimane. — [Efficacy of Contextually Tailored Suggestions,
  ResearchGate](https://www.researchgate.net/publication/327451781)
- Liao, P., et al. (2020). *Personalized HeartSteps: A Reinforcement Learning Algorithm for Optimizing
  Physical Activity*. **ACM IMWUT** 4(1). — [ACM](https://dl.acm.org/doi/10.1145/3381007) · [arXiv:1909.03539](https://arxiv.org/abs/1909.03539)
- *Did we personalize? Assessing personalization by an online reinforcement learning algorithm using
  resampling* (2024). **Machine Learning** — [Springer](https://link.springer.com/article/10.1007/s10994-024-06526-x) · [arXiv:2304.05365](https://arxiv.org/pdf/2304.05365)
- DIAMANTE trial. *Effectiveness of a Digital Health Intervention Leveraging Reinforcement Learning*
  (2024). **JMIR** 2024;26:e60834. — [JMIR](https://www.jmir.org/2024/1/e60834) · [PMC11496924](https://pmc.ncbi.nlm.nih.gov/articles/PMC11496924/)
  ⚠️ risultati numerici del confronto braccio-adattivo vs braccio-random non recuperati in questa
  sessione.
- *Sense2Stop: A micro-randomized trial using wearable sensors to optimize a just-in-time-adaptive
  stress management intervention for smoking relapse prevention*. — [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1551714421002706) · [PubMed](https://pubmed.ncbi.nlm.nih.gov/34375749/)
- Oralytics. *Reward Design For An Online Reinforcement Learning Algorithm Supporting Oral Self-Care*
  (2023). **AAAI**. arXiv:2208.07406. — [arXiv](https://arxiv.org/abs/2208.07406) · formula reward
  Q=min(B−P,180), R=Q−C
- Oralytics deployment. *A Deployed Online Reinforcement Learning Algorithm In An Oral Health Clinical
  Trial*. arXiv:2409.02069.
- Rabbi, M., et al. *MyBehavior: Automated Personalized Feedback for Physical Activity and Dietary
  Behavior Change With Mobile Phones*. **JMIR mHealth uHealth** 2015;3(2):e42. — [JMIR](https://mhealth.jmir.org/2015/2/e42/) · [PMC4812832](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4812832/)

### Algoritmo: Thompson sampling, action centering, pooling, robustezza

- Agrawal, S., & Goyal, N. (2013). *Thompson Sampling for Contextual Bandits with Linear Payoffs*.
  **PMLR** 28. — [PMLR](https://proceedings.mlr.press/v28/agrawal13.html)
- Boruvka, A., Almirall, D., Witkiewitz, K., & Murphy, S. A. (2018). *Assessing Time-Varying Causal
  Effect Moderation in Mobile Health*. **JASA** 113(523), 1112–1121. — [PDF](https://archive.md2k.org/images/papers/jitai/boruvka033117.pdf)
  · formalizzazione dell'effetto di escursione causale e dello stimatore WCLS (action centering)
- Tomkins, S., Liao, P., Klasnja, P., & Murphy, S. A. (2021). *IntelligentPooling: practical Thompson
  sampling for mHealth*. **Machine Learning** 110(9), 2685–2727. — [Springer](https://link.springer.com/article/10.1007/s10994-021-05995-8) · [arXiv:2008.01571](https://arxiv.org/abs/2008.01571) · [PMC8494236](https://pmc.ncbi.nlm.nih.gov/articles/PMC8494236/)
  · −26% regret medio vs stato dell'arte
- Huch, E., Golbus, J. R., Shi, et al. (2024). *RoME: A Robust Mixed-Effects Bandit Algorithm for
  Optimizing Mobile Health Interventions*. **NeurIPS 2024**. arXiv:2312.06403. — [arXiv](https://arxiv.org/abs/2312.06403) · [PMC12395203](https://pmc.ncbi.nlm.nih.gov/articles/PMC12395203/)

### Inferenza su dati adattivi

- Zhang, K. W., Janson, L., & Murphy, S. A. (2020). *Inference for Batched Bandits*. **NeurIPS** 33,
  9818–9829. — [arXiv:2002.03217](https://arxiv.org/abs/2002.03217) · [PMC8734616](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8734616/)
  · dimostra non-normalità asintotica di OLS su dati da bandit, introduce BOLS
- Liao, P., Klasnja, P., Tewari, A., & Murphy, S. A. (2016). *Sample size calculations for
  micro-randomized trials in mHealth*. **Statistics in Medicine**. — package `MRTSampleSize`/
  `MRTSampleSizeBinary` (CRAN); calcolatore Shiny arXiv:1609.00695
- *The Micro-randomized Trial for Developing Digital Interventions: Experimental Design and Data
  Analysis Considerations*. arXiv:2107.03544.

### Instrumental variables / encouragement design

- *Bounding the local average treatment effect in an instrumental variable analysis of engagement
  with a mobile intervention*. arXiv:2008.06473.

### Prior bayesiani / warm start

- Meta-analytic-predictive (MAP) prior — overview clinico: [PharmaLex](https://www.pharmalex.com/thought-leadership/blogs/the-use-of-meta-analytic-predictive-priors-in-clinical-trial-design/)

### Missing data, non-stazionarietà, engagement decay

- *Data Missing Not at Random in Mobile Health Research: Assessment of the Problem and a Case for
  Sensitivity Analyses*. **JMIR** 2021;23(6):e26749. — [PMC8277392](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8277392/)
- *Sensitivity to missing not at random dropout in clinical trials: Use and interpretation of the
  trimmed means estimator*. — [PMC9303448](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9303448/)
- *User Engagement and Abandonment of mHealth: A Cross-Sectional Survey*. **Healthcare** 2022;10(2):221. — [PMC8872344](https://pmc.ncbi.nlm.nih.gov/articles/PMC8872344/)
- *To Prompt or Not to Prompt? A Microrandomized Trial of Time-Varying Push Notifications to Increase
  Proximal Engagement With a Mobile Health App*. — [PMC6293241](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6293241/)

### Mind-wandering, digital phenotyping

- *Mind wandering state detection during video-based learning via EEG*. **Frontiers in Human
  Neuroscience** 2023. — [PMC10267732](https://pmc.ncbi.nlm.nih.gov/articles/PMC10267732/) (80–83%
  accuratezza within-subject)
- *Gaze-based detection of mind wandering during audio-guided panorama viewing*. **Scientific
  Reports**. — [PMC11564806](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11564806/) (AUROC ≥0.80
  in-domain, 0.56–0.68 cross-domain)
- Wang, R., et al. (2014). *StudentLife: Assessing Mental Health, Academic Performance and Behavioral
  Trends of College Students Using Smartphones*. **ACM UbiComp 2014**. — [ACM](https://dl.acm.org/doi/10.1145/2632048.2632054)
- SmartGPA — [Dartmouth](https://www.cs.dartmouth.edu/~campbell/smartGPA.pdf)

### Surrogate endpoint

- Prentice, R. L. (1989). *Surrogate endpoints in clinical trials: definition and operational
  criteria*. **Statistics in Medicine**. — criteri di validazione statistica di un surrogate endpoint,
  applicati criticamente in §7.1 al confronto proximal/distal outcome

> Le fonti marcate ⚠️ NON VERIFICATO nel corpo del testo indicano dati che questa sessione di ricerca
> non è riuscita a recuperare con precisione numerica (fetch full-text falliti o non tentati per
> vincolo di budget) — da verificare prima di citarli in materiale pubblico o in decisioni di design
> ad alto impatto.
