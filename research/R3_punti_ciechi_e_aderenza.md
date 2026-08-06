# R3 — Punti ciechi, opportunità e aderenza/motivazione (fusione R5+R6)

> Report red team + aderenza per FocusMaxxer. Stato: **in corso di scrittura, aggiornato
> incrementalmente per sezione**. Se la sessione si interrompe, tutto ciò che è sotto è già
> verificato e completo fino al punto dove finisce.

**Indice**
1. [Sintesi per il chiamante](#1-sintesi-per-il-chiamante)
2. [Fattibilità tecnica iOS/Android — priorità 1](#2-fattibilità-tecnica-iosandroid)
3. [Il ruolo degli LLM — priorità 2](#3-il-ruolo-degli-llm)
4. [Il baricentro del prodotto — priorità 3](#4-il-baricentro-del-prodotto)
5. [Randomizzare vs formare l'abitudine — priorità 4](#5-randomizzare-vs-abitudine)
6. [Experiment aversion e vendere la randomizzazione — priorità 5](#6-experiment-aversion)
7. [Retention reale mHealth e planning fallacy — priorità 6](#7-retention-e-planning-fallacy)
8. [Pre-mortem: 10 cause di fallimento a 18 mesi — priorità 7](#8-pre-mortem)
9. [Dataset pubblici in dominio — priorità 8](#9-dataset-pubblici)
10. [Panorama competitivo](#10-panorama-competitivo)
11. [GDPR e confine dispositivo medico](#11-gdpr-e-dispositivo-medico)
12. [Nudge: Mertens vs Maier](#12-nudge)
13. [Algorithm aversion](#13-algorithm-aversion)
14. [Canali di segnale non considerati](#14-canali-di-segnale)
15. [Business model](#15-business-model)
16. [Procrastinazione, implementation intentions, SDT, habit, gamification — aderenza](#16-aderenza-motivazione)
17. [Le 10 azioni più importanti nei prossimi 3 mesi](#17-azioni-prossimi-3-mesi)
18. [Bibliografia](#18-bibliografia)

---

## 1. Sintesi per il chiamante

**Il difetto strutturale più grave**: il progetto investe la sua ingegneria più sofisticata (SAFTE, bandit contestuale, BOLS) negli effetti più piccoli e incerti del corpus (sonno within-person +0.11/ora, R²<15%), mentre tratta come contorno gli effetti più grandi e solidi (retrieval practice con feedback g=0.73, implementation intentions d=0.65, AI tutoring d=0.73–1.3). Il baricentro del prodotto è nel posto sbagliato. Tre riformulazioni concrete proposte nel report (§4): la più realizzabile nei 3 mesi è spostare il guscio esterno su implementation intentions/iniziazione, mantenendo timing/SAFTE come segnale di contesto interno, non come claim di marketing.

**Punti ciechi tecnici gravi**: su iOS, `DeviceActivity` **vieta esplicitamente** l'export dei dati di utilizzo fuori dall'estensione (citazione diretta di un ingegnere Apple), e nessuna app può bloccare se stessa con `FamilyControls`/`ManagedSettings` — metà delle idee di digital phenotyping passivo e "modo aereo intelligente" del handoff sono **irrealizzabili su iOS come concepite**. Android è più aperto ma via un permesso a friction manuale e review Play Store. HealthKit consegna sonno/HRV con latenza fino a 30 minuti — la biometria non potrà mai essere segnale "durante" la sessione, solo post-hoc, su nessuna delle due piattaforme.

**Opportunità non colta, ad altissimo valore**: gli LLM (assenti dal handoff) risolvono l'attrito che blocca l'idea §8.1 (la più promettente del progetto) — generazione di flashcard e grading di risposte aperte hanno oggi evidenza di qualità comparabile all'umano (Krippendorff's α 0.734 vs 0.695), e sbloccano retrieval practice a risposta aperta con feedback, la combinazione con l'effect size più alto del corpus.

**Conflitti irrisolti confermati gravi**: randomizzare il timing è meccanicamente in tensione con la formazione dell'abitudine (Lally 2010, cue consistency vs cue instability) — non c'è soluzione elegante, solo attenuazione via ancoraggio contestuale. "Vendere la randomizzazione" rischia di innescare experiment aversion (Meyer 2019, 16 studi, 5.873 partecipanti) se il copy usa la parola "esperimento" invece di "la tua domanda".

**Sottovalutato dal team**: retention reale mHealth è a una cifra (Baumel 2019: mediana 3.3% a 30 giorni) e il pilota controllato non la misurerà mai — rischio di credere, dopo il pilota, in un tasso di adozione che il mercato non replicherà. Planning fallacy (Buehler) introduce un confondente per-persona stabile nel reward basato su durata dichiarata, non solo rumore assorbibile dal pooling.

Report completo: 18 sezioni, tabelle su fattibilità tecnica, panorama competitivo (12 concorrenti) e pre-mortem (10 cause), chiusura con 10 azioni per i prossimi 3 mesi ordinate per valore/costo. ~7.400 parole. File: `research/R3_punti_ciechi_e_aderenza.md`.

---

## 2. Fattibilità tecnica iOS/Android

**Verdetto in una riga**: su iOS l'app **non può** fare digital phenotyping "alla StudentLife" (nessun export dei dati di utilizzo), **può** bloccare app di terzi ma solo dentro un perimetro di approvazione Apple stretto e mai su se stessa, e la biometria via HealthKit è disponibile ma con latenza fino a 30 minuti per tutto ciò che non è la frequenza cardiaca istantanea da Watch. Su Android tutto questo è più aperto, ma passa da un permesso che Google tratta con sospetto. **Le due piattaforme non sono equivalenti**: qualunque feature che dipenda da uso-app o blocco-app deve essere progettata come "Android-first, iOS-degradato", non come cross-platform pari.

### 2.1 App blocking — iOS: FamilyControls / ManagedSettings / DeviceActivity

Le tre API Screen Time di Apple si dividono i compiti: **FamilyControls** chiede il permesso e definisce cosa bloccare, **ManagedSettings** applica il blocco (restrizioni, filtro del traffico web, "shield" delle app), **DeviceActivity** decide quando il blocco è attivo. Tre fatti verificati, con impatto diretto sul concept:

1. **Serve un entitlement privilegiato approvato da Apple caso per caso.** `com.apple.developer.family-controls` non è auto-concedibile: va richiesto nel developer portal con una spiegazione del caso d'uso, per **ogni target** dell'app (non solo l'app principale). Non è un semplice flag in Info.plist: è un gate editoriale.
2. **Nessuna app può bloccare se stessa.** Dal design dell'API: "tutte le app autorizzate in FamilyControls sono esenti dall'essere bloccate o schermate tramite ManagedSettings" — quindi il pattern "FocusMaxxer si autolimita per aiutarti a resistere" è strutturalmente impossibile; può solo bloccare *altre* app.
3. **Zero export dei dati fini di utilizzo, per policy dichiarata.** Su un thread ufficiale dei forum Apple Developer, un ingegnere del team Frameworks risponde testualmente: *"It is not possible to export the data for [privacy and security] reason[s], such as saving to an external database. You are welcome to file an enhancement request at Feedback Assistant"* ([Apple Developer Forums, thread 756619](https://developer.apple.com/forums/thread/756619)). Un secondo sviluppatore conferma: i dati granulari sono sandboxed, visualizzabili solo dentro le view di `DeviceActivityReport`, mai leggibili dal codice dell'app che li richiede. L'estensione `DeviceActivityMonitor` ha inoltre un **hard memory limit di 5 MB**, non può stampare per debug, non può inviare notifiche né chiamare API di rete.

Conseguenza diretta per §8.2 e §8.5 del handoff: su iOS **non esiste un canale legittimo per portare l'uso-app fuori dal sandbox Screen Time verso il bandit**. L'app può *mostrare* un report di utilizzo dentro una view fornita da Apple (bella da vedere, inutile come feature del modello) e può *attivare un blocco* temporizzato su app terze scelte dall'utente (§8.12, "modo aereo intelligente" — fattibile, ma **solo su app diverse da sé stessa** e solo dopo approvazione dell'entitlement). Il digital phenotyping passivo di §8.5 è quindi **irrealizzabile su iOS con le API pubbliche**: l'unica via sarebbe l'auto-report esplicito (slider di fine sessione, §8.9), che infatti sale di priorità per pura necessità tecnica, non solo per costo di UX.

Va detto anche il rovescio: il mercato di app come **Opal** ($19.99/mese, "Deep Focus" non annullabile), **One Sec** (frizione respiratoria prima di aprire l'app) e **Freedom** (sync cross-piattaforma) dimostra che il blocco-app *funziona* come feature commerciale nonostante questi vincoli — ma tutte, per stessa ammissione delle recensioni, hanno "loopholes nel livello di permesso Screen Time che nessuna app di terze parti può chiudere del tutto su iOS" ([confronto app blocker iOS 2026](https://unstar.app/blog/opal-forest-freedom-one-sec-jomo-screen-time-apps-ranked-2026)). Il blocco è quindi un arm legittimo del bandit (§8.12), ma va venduto con aspettative tarate: friction, non muro invalicabile.

### 2.2 App blocking / usage — Android: UsageStatsManager

Su Android il quadro è più permissivo ma non gratuito. `UsageStatsManager` espone `UsageStats`, `UsageEvents` (eventi per-app: foreground/background, con timestamp), quindi **sì**, tempo in foreground per app e log eventi sono leggibili in modo nativo — ciò che manca del tutto su iOS. Il costo:

- Il permesso `android.permission.PACKAGE_USAGE_STATS` è **"dangerous" ma non richiedibile via dialog runtime standard**: l'utente deve navigare manualmente in *Impostazioni > App > Accesso speciale > Accesso all'utilizzo* e attivarlo per l'app, un passaggio in più rispetto ai permessi ordinari — friction di onboarding non banale se questa feature è centrale.
- Google Play richiede una **dichiarazione esplicita d'uso legittimo in fase di review**; l'esperienza di categoria (parental control, digital wellbeing) rende il caso d'uso "focus/produttività" difendibile ma non automatico.

Per il blocco vero e proprio (non solo lettura), Android non ha un equivalente diretto di ManagedSettings per app di terzi: le app come Opal/AppBlock su Android tipicamente usano `UsageStatsManager` per rilevare l'app in foreground + un overlay/Accessibility Service per intercettarla — API storicamente sotto scrutinio Play Store per abuso (screen-overlay attacks), quindi anch'esse a rischio policy, non un porto sicuro permanente.

**Asimmetria strategica**: qualunque roadmap che tratti "uso app" o "blocco app" come feature simmetrica cross-platform è scorretta. Su Android è un arm implementabile con friction moderata; su iOS è **due feature diverse travestite da una**: mostrare un report nativo (poco valore per il modello) e bloccare app terze (valore comportamentale reale, ma via approvazione discrezionale + impossibilità di autoblocco).

### 2.3 Background execution

Su iOS, `BGAppRefreshTaskRequest` è limitato a **circa 30 secondi** di esecuzione e **non garantisce orari**: il sistema decide quando eseguire il task in base a batteria, pattern d'uso e "budget" euristico proprietario; se l'handler non richiama `scheduleAppRefresh()` l'app si autoesclude dai run futuri, e ignorare l'expiration handler danneggia la "reputazione" dell'app nel modello predittivo di iOS, deprioritizzando le richieste successive. `BGProcessingTaskRequest` consente finestre più lunghe ma tipicamente sotto vincoli di rete/alimentazione esterna. Conseguenza: **niente polling regolare in background per aggiornare lo stato del bandit o inviare notifiche precisamente temporizzate** — i decision point del sistema (§8.2, il momento pianificato-ma-non-onorato) vanno implementati con **notifiche locali pianificate in anticipo** (`UNCalendarNotificationTrigger` o simili), non con task in background che "controllano" lo stato in tempo reale. È un vincolo di design, non un dettaglio implementativo: il "prompt prima della sessione" deve essere schedulato al momento della dichiarazione d'intenzione, non calcolato just-in-time.

### 2.4 HealthKit vs Health Connect — sonno, HR, HRV, passi

**iOS/HealthKit**: framework **on-device**, nessuna API server-to-server — i dati vivono sul telefono/Watch dell'utente, non sui server Apple, quindi ogni sincronizzazione verso un backend deve passare dall'app stessa (nessuna scorciatoia cloud-to-cloud). `enableBackgroundDelivery` + observer query permettono di essere svegliati quando arrivano nuovi dati, ma **solo la frequenza cardiaca da Apple Watch può arrivare ogni pochi secondi; tutto il resto (sonno, HRV, passi da iPhone) può avere fino a 30 minuti di latenza** (dato confermato per iOS 14+, verosimilmente invariato nelle versioni successive salvo cambi non documentati). L'HRV via HealthKit è per giunta misurata prevalentemente durante gli esercizi Breathe/Mindfulness di watchOS, **non passivamente durante il sonno o lo studio** — un limite di copertura temporale che il team deve considerare prima di trattare l'HRV come segnale continuo di stress durante la sessione.

**Android/Health Connect**: `SleepSessionRecord` con **8 stadi** (UNKNOWN, AWAKE, SLEEPING, OUT_OF_BED, AWAKE_IN_BED, LIGHT, DEEP, REM) — granularità superiore a quanto tipicamente esposto da HealthKit lato terzi. Heart Rate e HRV (`READ_HEART_RATE_VARIABILITY`) sono permessi dedicati, così come `READ_HEALTH_DATA_IN_BACKGROUND` (background) e `READ_HEALTH_DATA_HISTORY` (storico oltre 30 giorni) — permessi **aggiuntivi e più sensibili**, ciascuno soggetto a dichiarazione separata nella Play Console e a possibile revisione umana Google per app che li richiedono in combinazione con dati comportamentali. Questo significa che più segnali si combinano (sonno + HR + comportamento app), più alta la soglia di review — un costo di go-to-market da preventivare, non solo un dettaglio tecnico.

**Implicazione per il gate biometrico (§3.4 handoff)**: dato che HealthKit consegna sonno/HRV/passi con latenza fino a 30 minuti e non in tempo reale, **la biometria non può mai essere un segnale "durante" la sessione su iOS** — arriva strutturalmente in ritardo. Questo rafforza, su base puramente tecnica (non solo statistica), la decisione già presa nel concept di trattare la biometria come sensore di validità post-hoc e non come input al momento della raccomandazione.

### 2.5 Sintesi tabellare

| Capacità | iOS | Android | Impatto sul concept |
|---|---|---|---|
| Leggere tempo per-app in foreground | ❌ (solo report visuale sandboxed, non leggibile da codice) | ✅ `UsageStatsManager`, con permesso manuale utente | §8.5 digital phenotyping: Android-only |
| Esportare dati di utilizzo verso backend | ❌ esplicitamente vietato (citazione Apple sopra) | ✅ (nessun analogo divieto) | Modello di dati asimmetrico per piattaforma |
| Bloccare app di terzi | ✅ con entitlement discrezionale Apple, mai su sé stessa | ⚠️ via overlay/Accessibility, sotto scrutinio Play Store | §8.12 arm bandit: fattibile ma fragile su entrambe |
| HR/HRV/sonno via API nativa | ✅ HealthKit, ma HRV quasi solo da esercizi dedicati, latenza fino 30 min | ✅ Health Connect, HRV dedicata, permessi extra per storico/background | Biometria = validità post-hoc, mai realtime, su entrambe |
| Task in background puntuali | ❌ nessuna garanzia di orario, cap ~30s | ✅ più margine ma comunque soggetto a Doze/battery optimization | Decision point pre-sessione → notifiche pre-schedulate, non polling |

**Fonti**: [Apple Developer Forums, thread 756619](https://developer.apple.com/forums/thread/756619) (citazione ingegnere Apple sull'export dati); [guida FamilyControls/ManagedSettings/DeviceActivity](https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7); [Android UsageStatsManager reference](https://developer.android.com/reference/android/app/usage/UsageStatsManager); [Android Health Connect — data types](https://developer.android.com/health-and-fitness/health-connect/data-types); [confronto app blocker iOS 2026](https://unstar.app/blog/opal-forest-freedom-one-sec-jomo-screen-time-apps-ranked-2026); background execution iOS 2026 ([appsonair](https://www.appsonair.com/blogs/background-execution-limits-in-ios-what-every-developer-must-know), [sachith.co.uk](https://www.sachith.co.uk/background-tasks-and-limits-on-ios-android-ops-runbook-practical-guide-may-4-2026/)).

---

## 3. Il ruolo degli LLM

**Il punto cieco più costoso del handoff.** L'idea §8.1 (spaced repetition come strumento di misura) è dichiarata "la più promettente" ma bloccata dall'attrito di inserimento del materiale. Il handoff non nomina mai un LLM come soluzione — eppure è esattamente il pezzo mancante, e l'evidenza per giustificarlo è forte, non aneddotica.

### 3.1 Generazione di flashcard/domande: la qualità regge

Uno studio 2026 su un corso di Operating Systems ha confrontato 14 domande MCQ generate da LLM contro 21 scritte da umani, su 42 studenti reali, misurando difficoltà, indice di discriminazione e affidabilità: **difficoltà umana M=0.86 vs LLM M=0.82 (differenza non significativa)**; **indice di discriminazione identico, M=0.13 su entrambi**; **affidabilità Krippendorff's α = 0.695 (umano) vs 0.734 (LLM)** — l'LLM non è risultato inferiore, anzi leggermente più coerente su questa metrica ([Frontiers in Education 2026, 10.3389/feduc.2026.1837523](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2026.1837523/full)). La condizione esplicitata dagli autori: **validazione umana zero-shot** — le domande generate senza controllo restano un rischio di qualità variabile (confermato anche da altra letteratura: *"la qualità varia significativamente con il modello, il prompt design e l'iniezione di conoscenza; la validazione umana resta indispensabile"*).

Implicazione operativa per FocusMaxxer: la generazione automatica di flashcard dal materiale caricato dall'utente (PDF, appunti, slide) è **tecnicamente matura**, a patto di (a) mantenere un passaggio di revisione dell'utente prima che una card entri nel deck attivo — costa un tap in più ma preserva sia la qualità sia il senso di controllo (rilevante anche per l'algorithm aversion, §13), e (b) non usare lo stesso LLM come generatore e come giudice della propria qualità: la letteratura segnala esplicitamente che "LLM-as-a-judge" con lo stesso modello **è polarizzato verso le proprie generazioni**.

### 3.2 Valutazione di risposte aperte: la forma di retrieval practice migliore, ora automatizzabile

Il handoff (R1, punto 10) cita Rowland 2014: **g=0.73 con feedback vs 0.39 senza** — il feedback quasi raddoppia l'effetto del retrieval practice. Fino a ieri, dare feedback su risposte *aperte* (non solo MCQ/cloze) richiedeva un umano; è il motivo per cui la maggior parte delle app di flashcard resta su recall binario (so/non so) invece che su valutazione semantica della risposta. La grading automatica con LLM ha ora prestazioni riportate come **paragonabili all'accuratezza umana in contesti supervisionati** (es. accuratezza fino a 0.999 in un workflow ottimizzato, riduzione del MAE fino al 19.47% con retrieval-augmented grading rispetto a LLM puro) ma con un bias sistematico noto: **tendenza a sovra-punteggiare risposte parzialmente sbagliate** ("optimistic bias"), che richiede human-in-the-loop nei contesti ad alto rischio ([ricerca ASAG/RAG grading, 2025-2026](https://dl.acm.org/doi/10.1145/3706468.3706481); [PMC12896245 — calibrazione LLM vs esperti in dental education](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12896245/)).

Per un'app di studio (non un contesto di voto formale), questo bias è **accettabile**: sovrastimare leggermente una risposta quasi-corretta è un costo molto più basso di un voto d'esame sbagliato, e l'outcome usato dal bandit (§5 handoff, §8.1) non richiede accuratezza da tribunale — richiede solo che sia meno gameable del completion ratio e correlato al vero apprendimento. Qui l'LLM sblocca l'idea più promettente del progetto: **retrieval practice a risposta aperta, con feedback immediato, senza costo marginale umano**, cioè esattamente la condizione che genera l'effect size più alto della letteratura di dominio.

### 3.3 AI tutoring: l'effect size è reale, non hype

Due fonti indipendenti, entrambe verificate:

- **VanLehn 2011** (*Educational Psychologist* 46(4)) — meta-analisi su 28 studi/10 confronti 1975–2010: tutoring umano **d=0.79** vs nessun tutoring; tutoring intelligente **step-based d=0.76** (quasi alla pari con l'umano), **substep-based d=0.40**. Conclusione dell'autore: l'effetto del tutoring umano era stato sopravvalutato dalla letteratura precedente e i sistemi intelligenti ben progettati gli si avvicinano di molto.
- **Kestin et al. 2025** (*Scientific Reports*, RCT ad Harvard, corso Physical Sciences 2, ~194 studenti, design crossover settimanale in-class active-learning vs AI tutor a casa) — **effect size 0.73–1.3 SD a favore del tutor AI** rispetto all'active learning in aula, con guardrail espliciti anti-allucinazione e scaffolding curato da esperti ([Nature/Scientific Reports](https://www.nature.com/articles/s41598-025-97652-6); [Hechinger Report](https://hechingerreport.org/proof-points-ai-tutor-harvard-physics/)). È uno studio singolo, in un dominio (fisica universitaria) con materiale altamente strutturato — **non generalizzare acriticamente** a materie umanistiche o compiti mal definiti — ma la dimensione dell'effetto è dello stesso ordine di grandezza di retrieval practice + feedback, cioè tra le più grandi dell'intero corpus di evidenza raccolto per questo progetto.

### 3.4 Cosa implementare, e cosa no, nel prossimo trimestre

**Implementabile subito, basso rischio**: generazione di flashcard/domande dal materiale caricato dall'utente (import PDF/testo → LLM → revisione utente → deck attivo); grading automatico di risposte aperte con soglia di confidenza (sotto soglia → chiedi conferma all'utente, "l'hai presa giusta?"); questo risolve l'attrito di §8.1 e converte il completion ratio in un reward per-item, molte osservazioni per sessione, difendibile come misura di apprendimento.

**Da NON fare ora**: tutoring socratico conversazionale (costo di sviluppo alto, superficie di rischio — allucinazioni, costi API per sessione lunga — sproporzionata rispetto al valore incrementale sopra il semplice Q&A con feedback); estrazione strutturata "intelligente" di scadenze/argomenti dalle note come sostituto dell'integrazione LMS (§14) — più fragile e meno difendibile di un'API Moodle/Canvas diretta dove disponibile.

**Rischio non ovvio**: un LLM che genera *e* giudica il materiale dell'utente introduce una superficie di costo variabile (token per sessione) che scala con l'uso — l'opposto di un servizio a costo marginale zero come il bandit. Va budgetizzato esplicitamente nel business model (§15), non trattato come feature "gratis" perché software.

**Prior per warm-start (se questo arm entra nel bandit)**: trattare "flashcard con feedback LLM" come variante ad alta-fedeltà di "retrieval practice con feedback" — prior centrato su g≈0.73 (Rowland 2014), **non** sul range 0.73–1.3 di Kestin 2025, che è uno studio singolo in un dominio molto favorevole e rischia di essere un'ancora troppo ottimistica se trasferito a materie eterogenee.

---

## 4. Il baricentro del prodotto

Il team stesso ammette la tensione (§7.3 handoff) senza risolverla. Vale la pena dirla senza diplomazia: **il concept, così com'è scritto, ottimizza la parte più debole della propria evidenza e tratta come accessoria quella più forte.**

Guardiamo i numeri fianco a fianco, tutti già verificati nel handoff e in questo report:

| Costrutto | Effetto | Dove nel concept |
|---|---|---|
| Retrieval practice + feedback | g=0.73 | "Struttura la sessione secondo pratiche" — presente ma non il cuore |
| Implementation intentions | d=0.65 | Idea §8.2, non ancora nel concept operativo |
| AI tutoring (Kestin 2025, dominio favorevole) | d=0.73–1.3 | Assente dal concept |
| Distributed practice (media pool 10 tecniche) | 0.56 | Presente come euristica di sfondo |
| Sonno → cognizione (within-person) | +0.11 risposte/ora, ~8× più piccolo dell'atteso | **Cuore del concept** (SAFTE, readiness score) |
| Personalizzazione del timing via bandit | R² < 10–15% | **Cuore del concept** (l'intero algoritmo) |

Il pattern è netto: le due componenti su cui il progetto investe l'ingegneria più sofisticata — modello SAFTE del sonno e bandit contestuale per il timing — poggiano sugli effetti **più piccoli e più incerti** del intero corpus di evidenza raccolto. Le due componenti con l'effetto **più grande e più solido** — retrieval practice con feedback e implementation intentions — sono trattate come contorno "già deciso" attorno a cui costruire l'infrastruttura statistica pesante.

Non è un errore di giudizio isolato: è coerente con un bias comune nei prodotti data-driven, per cui **l'attenzione ingegneristica va dove c'è incertezza da modellare**, non dove c'è già una risposta. Il sonno e il timing sono problemi statisticamente interessanti (serve un bandit, serve BOLS, serve pooling a effetti misti); il retrieval practice è "solo" un problema di UX e contenuto. Ma il prodotto non viene giudicato dalla difficoltà tecnica che ha risolto — viene giudicato dall'effetto che produce sull'utente, e lì il rapporto è rovesciato.

### 4.1 Tre riformulazioni alternative

**A — "L'app di spaced repetition che sa quando disturbarti".** Il prodotto primario è un motore di flashcard con generazione LLM (§3) e algoritmo FSRS/half-life regression per lo scheduling delle review; il bandit sul timing diventa una feature di *secondo livello* che decide **quando notificare la prossima review**, non quando "si dovrebbe studiare" in generale. Vantaggio: il reward diventa nativamente la recall a distanza (§8.1 del handoff, risolve la questione aperta n.1), l'outcome è oggettivo e per-item, e il prodotto compete in un mercato con concorrenza debole sul lato UX (Anki è potente ma spaventoso per un principiante; RemNote/Traverse sono di nicchia). Rischio: perde l'ambizione "coach di deep work" — diventa un'app di flashcard con un bonus intelligente, meno vendibile come categoria nuova.

**B — "Il coach di iniziazione, non di esecuzione".** Il prodotto primario diventa l'intervento su implementation intentions (§8.2 del handoff): l'unico decision point critico è "hai onorato l'intenzione dichiarata?", con planning prompt, if-then e (opzionale) un promemoria minimale. Tutto il resto — SAFTE, bandit di timing, biometria — retrocede a raffinamento interno del *quando* proporre il prompt, non a feature visibile. Vantaggio: attacca il fallimento più costoso e più documentato ("la sessione che non comincia mai"), con l'effect size più alto e più replicato di tutto il corpus (d=0.65, 94 test, >8.000 partecipanti). Rischio: è un prodotto quasi-noioso da vendere ("un promemoria intelligente") rispetto alla narrativa "ottimizziamo la tua giornata con la scienza del sonno".

**C — "Il misuratore, non il prescrittore".** L'app rinuncia esplicitamente a raccomandare *quando* studiare e si posiziona come strumento di **auto-sperimentazione N-of-1** (§8.3 del handoff, vedi anche §6 di questo report): l'utente sceglie una domanda ("la caffeina mi aiuta? il mattino è meglio della sera per me?"), l'app randomizza e misura, e il valore percepito è "adesso lo so con dati, non per sensazione". Vantaggio: risolve simultaneamente l'endogeneità della selezione (è il punto di partenza dichiarato, non un vincolo nascosto) e l'experiment aversion (§6) — trasparenza totale come feature. Rischio: mercato di nicchia (quantified-self avanzato), volume di utenti potenzialmente troppo basso per generare il traffico che il pilota richiede.

### 4.2 Presa di posizione

Tra le tre, **B è la riformulazione a più alto rapporto valore/costo per i prossimi 3 mesi**, non perché sia la visione finale, ma perché è quella che richiede il minor refactoring rispetto al concept attuale (i pezzi — dichiarazione di sessione, timing randomizzato — già esistono) e attacca l'effetto più grande e meno contestabile dell'intero corpus. **A è la riformulazione con il tetto di valore più alto a lungo termine**, perché converte l'idea §8.1 (già giudicata la più promettente dal team) da feature accessoria a prodotto: se il team crede davvero che sia l'idea migliore, dovrebbe chiedersi perché non è il centro del prodotto invece che una nota a pié di pagina in §8. La raccomandazione concreta: **usare i prossimi 3 mesi per pilotare B come guscio esterno del prodotto e A come motore di reward interno** — cioè: l'utente vede "un coach che ti aiuta a iniziare e a ricordare", il bandit e il reward per-item lavorano sotto silenzio. Il timing "ottimale" (SAFTE, cronotipo) resta, ma retrocede a *uno dei tanti segnali di contesto* nel bandit, non al claim principale di marketing — coerente, questo sì, con quanto §2.4 del handoff già dice a chiare lettere ("le euristiche non sono il prior del modello: sono il prodotto").

---

## 5. Randomizzare vs abitudine

**Il conflitto è reale e non si risolve con un compromesso a metà.** Lally et al. 2010 (*European Journal of Social Psychology* 40(6):998–1009; 96 volontari, 12 settimane, Self-Report Habit Index giornaliero): la mediana per raggiungere il 95% dell'automaticità asintotica è **66 giorni, range 18–254**. Il meccanismo dell'abitudine, per costruzione, è **la ripetizione dello stesso comportamento nello stesso contesto** — cue consistency. La randomizzazione della finestra oraria (~10–15% permanente, §3.1.2 handoff) è, per definizione, instabilità del contesto. Non è un attrito collaterale: è un'azione diretta contro il meccanismo che si vuole costruire.

Un dettaglio nella stessa fonte va usato con più forza di quanto il handoff faccia: **"missing a single day did NOT break the curve"** — la formazione di abitudine tollera lapsi occasionali senza azzerare il progresso. Questo è il margine reale su cui il concept può muoversi: 10–15% di raccomandazioni randomizzate significa, su una cadenza di studio quotidiana, **circa un'occorrenza "fuori pattern" ogni 7-10 giorni** — dell'ordine di grandezza dei lapsi singoli che Lally mostra essere innocui, non della disruption cronica che romperebbe la curva. Il rischio pratico non è quindi il tasso di randomizzazione dichiarato in sé, ma **come viene distribuito**: la stessa frazione spalmata uniformemente (un piccolo scarto quasi ogni giorno) è più dannosa per l'automaticità di quanto lo sia concentrata in eventi isolati e distanziati.

**Raccomandazione operativa, non ancora nel concept**: randomizzare **con memoria del contesto abituale dell'utente**, non con probabilità indipendente a ogni decision point. Due leve concrete:
1. **Ancora fissa + finestra randomizzata attorno**: se l'utente ha stabilito un pattern (es. "sempre verso le 18"), la componente randomizzata esplora *attorno* a quell'ancora (es. 17:30–18:30) più spesso di quanto esplori l'intera giornata — mantiene il cue temporale grossolanamente stabile (fascia pomeridiana) mentre raccoglie varianza sufficiente per l'identificazione causale a grana più fine. Questo è compatibile con BOLS finché il rumore di randomizzazione resta nel disegno.
2. **Fase di abitudine protetta, poi fase di esplorazione piena**: nelle prime ~2-3 settimane (ordine di grandezza compatibile con il range 18–254 di Lally, non con il valore singolo 66), ridurre la probabilità di esplorazione a un minimo tecnico (es. 5% invece di 10-15%) proprio nella fascia che l'utente sta stabilizzando, poi risalire. **Attenzione**: questo NON è la "fase osservazionale passiva" vietata da §3.1.2 del handoff — resta randomizzazione attiva, solo a intensità variabile nel tempo, dichiarata e pre-registrata come tale, non un ritorno silenzioso all'endogeneità.

**Ciò che il team non vuole sentirsi dire**: il conflitto non ha una soluzione elegante che preservi entrambi gli obiettivi al 100%. O l'app accetta di essere **leggermente meno efficace nel formare l'abitudine di studio** (perché disturba il cue temporale) in cambio di **stime causali valide sul timing**, oppure accetta di **non poter mai dire con certezza se il suo timing consigliato funziona** in cambio di un'abitudine più solida. Il framing "randomizzazione minima e concentrata" sopra descritto è un'attenuazione, non una risoluzione: **il prezzo dell'inferenza causale è pagato in automaticità comportamentale**, e questo prezzo va comunicato internamente come trade-off esplicito, non nascosto dietro "10-15% è una percentuale piccola".

---

## 6. Experiment aversion

Meyer et al. 2019 (*PNAS* 116(22)): su **16 studi, 5.873 partecipanti, 9 domini diversi**, un pattern robusto — le persone valutano gli A/B test che confrontano due politiche come **meno appropriati** delle politiche stesse, **anche quando approvano l'implementazione universale e non testata di entrambe le opzioni singolarmente**, e anche quando nessuna delle due è chiaramente superiore. Il fenomeno è stato chiamato "A/B effect" o "experiment aversion".

**Il contro-dibattito, da riportare per intero come richiesto dai requisiti di qualità**: un lavoro successivo propone la "minimum mean paradox" come spiegazione alternativa — gli esperimenti vengono valutati quasi identicamente al loro braccio *peggiore*, il che è una conseguenza statistica quasi meccanica (non uno specifico disgusto per la randomizzazione) se le persone giudicano un esperimento in base al risultato atteso peggiore possibile. Più recentemente, un lavoro 2024 in *PNAS* ("Experiment aversion does generalize, but it can also be mitigated") conferma che il fenomeno **si generalizza** oltre i contesti originali, ma trova anche leve concrete di mitigazione — non è quindi un vincolo assoluto e immutabile, ma sensibile alla presentazione.

### 6.1 Cosa significa per "vendere la randomizzazione" (§8.3 del handoff)

L'idea del handoff — esporre gli N-of-1 come feature ("l'app fa un esperimento su di te per 4 settimane e ti dà la risposta") — **rischia esattamente l'effetto documentato da Meyer et al. se presentata come "un esperimento su di te"**. La parola "esperimento" innesca la reazione negativa anche quando le alternative individuali sarebbero accettate senza problemi. Il rischio non è ipotetico: è il meccanismo esatto misurato nello studio.

**La mitigazione non è nascondere la randomizzazione — è cambiare il framing lessicale e di agency**, coerentemente con quanto lo studio 2024 suggerisce essere efficace: invece di "l'app sperimenta su di te", **"tu scegli una domanda, l'app ti aiuta a trovare la risposta confrontando alternative"**. La differenza chiave, verificabile contro il meccanismo dell'A/B effect:
- **Chi randomizza cosa**: se l'utente percepisce di essere "soggetto" di un test deciso da altri, l'avversione si attiva; se percepisce di aver *lui stesso* posto la domanda e scelto di confrontare A e B, il quadro si avvicina a un self-experiment (quantified-self), categoria con accettazione culturale molto più alta e non coperta dagli studi di experiment aversion (che riguardano tipicamente policy imposte da istituzioni).
- **Simmetria dichiarata delle opzioni**: l'A/B effect è più forte quando una opzione sembra oggettivamente peggiore; se le due condizioni (es. "studia al mattino" vs "studia alla sera") sono presentate esplicitamente come *entrambe ragionevoli e già in uso da altri studenti*, il disagio si riduce.
- **Opt-in esplicito e revocabile**: coerente con Dietvorst 2018 (§13) — dare controllo minimo (poter uscire dall'esperimento in ogni momento, poter scegliere quali variabili testare) aumenta l'accettazione sia dell'algoritmo sia della randomizzazione.

### 6.2 Raccomandazione concreta

Non presentare la randomizzazione come "l'app sperimenta con te" nel copy di prodotto. Presentarla come **"tool di auto-scoperta" opt-in per domanda specifica** (riformulazione C, §4.1), separata dal flusso di raccomandazione quotidiana di default (che resta silenziosamente randomizzata al 10-15% per l'inferenza, ma **non etichettata come esperimento** agli occhi dell'utente — è normale variazione del consiglio, non un test dichiarato). Le due cose — randomizzazione silenziosa per l'inferenza del bandit, ed esperimento dichiarato e opt-in per l'utente curioso — vanno tenute **concettualmente separate nel prodotto**, anche se condividono l'infrastruttura statistica sotto il cofano. Confondere le due converte un vincolo metodologico invisibile in un rischio di percezione visibile e completamente evitabile.

---

## 7. Retention e planning fallacy

### 7.1 Retention reale in mHealth: i numeri sono peggiori di quanto il team probabilmente immagina

Baumel et al. 2019 (*JMIR* 21(9):e14567, analisi panel-based su app di salute mentale reali, non un pilota controllato): **retention mediana a 15 giorni 3.9% (IQR 10.3%), a 30 giorni 3.3% (IQR 6.2%)**. Le categorie migliori — peer support, mindfulness/meditazione, tracker — arrivano a mediane del 4.7-8.9% a 30 giorni, comunque **una singola cifra**. Questi sono dati di mercato reale (app pubblicate, utenti che le hanno scaricate spontaneamente), non un pilota da 40-50 studenti reclutati e pagati.

**Implicazione diretta e scomoda**: il pilota di 6 settimane del handoff (§4, dimensionamento) **non misurerà mai questi tassi di attrito**, perché il campione è reclutato con incentivo, non organico — è più vicino a un trial clinico che a un lancio di mercato. Questo significa che **i risultati del pilota su retention non sono generalizzabili al lancio pubblico**, e ogni proiezione post-pilota ("il 60% degli utenti userà l'app per 6 settimane") che usi i dati del pilota come base per un business plan commette lo stesso errore concettuale che il handoff rimprovera altrove (transfer di dominio invalido, §2.3). Va **dichiarato esplicitamente** nel piano: il pilota misura efficacia in condizioni controllate, non retention di mercato — sono due domande diverse con due strumenti diversi.

### 7.2 Planning fallacy: il reward poggia su un numero sistematicamente distorto

Buehler, Griffin & Ross (1994) e il lavoro successivo di Buehler, Griffin & Peetz (2010, "The planning fallacy: cognitive, motivational, and social origins"): la sottostima dei tempi di completamento è un effetto **robusto e replicato** — nell'esempio canonico delle tesi universitarie, **70% degli studenti ha impiegato più tempo del previsto**, con un ritardo medio di 22 giorni su una previsione di 33 (55 giorni reali). Il meccanismo teorizzato da Kahneman & Tversky: le previsioni si basano su informazione **singolare** (gli aspetti specifici del compito attuale, tipicamente ottimistici) invece che **distribuzionale** (quanto sono durati compiti simili in passato).

**Perché questo è un problema strutturale per il reward, non un dettaglio**: il candidato di reward principale del handoff (§5, rapporto durata pianificata/durata effettiva) usa la durata *dichiarata* dall'utente come denominatore/riferimento. Se questa durata è sistematicamente sottostimata (planning fallacy), il reward **non misura la qualità della sessione — misura quanto l'utente è bravo a prevedere il proprio comportamento**, un costrutto psicometrico diverso e in gran parte stabile per persona (alcuni sono cronicamente ottimisti, altri no) più che dipendente dal consiglio dell'app. Questo aggrava esattamente l'ottimo degenere già identificato nel handoff ("premiare il completamento insegna a dichiarare durate brevi") **nella direzione opposta e ugualmente pericolosa**: un utente ottimista cronico verrà sistematicamente penalizzato dal reward indipendentemente da quanto le sue sessioni siano realmente produttive, introducendo un confondente per-persona che il pooling a effetti misti (IntelligentPooling, Tomkins et al. 2021) può assorbire solo parzialmente, perché è correlato con variabili non osservate (tratto di personalità), non solo con rumore casuale.

**Mitigazione concreta, non ancora nel concept**: mostrare all'utente, dopo un numero minimo di sessioni (es. 10), **la propria calibrazione storica** ("le tue sessioni durano in media il 40% più a lungo di quanto pianifichi") e permettere una durata "corretta automaticamente" come default proposto — non imposto, per non generare reattanza (§16) — al momento della dichiarazione. Questo attacca il problema alla fonte (input distorto) invece di provare a correggerlo post-hoc nel reward, ed è coerente con l'evidenza che gli interventi di debiasing più efficaci sul planning fallacy sono quelli che forzano l'uso di informazione distribuzionale (i propri dati storici) al momento della previsione.

---

## 8. Pre-mortem

Il team ha già elencato 8 rischi (§6 handoff): sovra-affermazione visiva, auto-avveramento, nocebo, interruzione del flow, terminazioni prescritte, gating sul wearable, churn, claim regolatori. Tutti condivisibili, tutti già mitigati sulla carta. Qui vanno le **cause che non sono in quella lista**, ordinate per probabilità × impatto stimati qualitativamente (Alta/Media/Bassa su entrambi gli assi), a 18 mesi.

| # | Causa | Probabilità | Impatto | Perché | Mitigazione |
|---|---|---|---|---|---|
| 1 | **Retention di mercato sotto al 5% a 30 giorni** (§7.1) trasforma il pilota in un dato non rappresentativo del lancio | Alta | Alta | Baumel 2019: mediana 3.3% a 30gg per app mHealth reali; il pilota reclutato non lo misura | Trattare retention come metrica separata dal pilota, misurarla in un soft-launch pubblico prima di scalare investimento |
| 2 | **Il reward collassa su planning fallacy per-persona** (§7.2), non su comportamento reale | Media | Alta | Bias sistematico e stabile per utente, non rumore | Calibrazione mostrata all'utente, durata di default corretta |
| 3 | **iOS resta un prodotto strutturalmente monco** rispetto ad Android (§2) | Alta | Media | Nessun export dati da DeviceActivity, autoblocco impossibile, HR/HRV/sonno con latenza | Roadmap Android-first dichiarata, non promettere parità di feature |
| 4 | **La randomizzazione erode l'abitudine più di quanto stimato** e gli utenti percepiscono l'app come "incoerente" (§5) | Media | Media | Meccanismo diretto: cue instability è l'opposto del cue consistency richiesto dall'habit formation | Ancoraggio contestuale + intensità di esplorazione variabile nel tempo (§5.1) |
| 5 | **"Vendere la randomizzazione" innesca experiment aversion** invece di risolverla, se il copy sbaglia framing (§6) | Media | Media | Meyer 2019: 16 studi, 5.873 partecipanti, pattern robusto | Framing "domanda tua, non esperimento loro"; separare randomizzazione silenziosa da esperimento dichiarato |
| 6 | **Il team costruisce l'infrastruttura statistica pesante (bandit, BOLS) prima di validare che il prodotto-contenuto (retrieval practice, implementation intentions) da solo trattiene utenti** | Media | Alta | È l'inversione di priorità discussa in §4: si ingegnerizza dove c'è incertezza statistica, non dove c'è valore utente dimostrato | Validare la ritenzione del "guscio B" (§4.2) prima di investire nel bandit pooled |
| 7 | **Costi variabili LLM non budgetizzati** erodono il margine se la generazione/grading di flashcard scala con l'uso (§3.4) | Media | Media | Il resto del prodotto (bandit, euristiche) ha costo marginale ~0; l'LLM no | Cap di utilizzo per tier gratuito, costo per token nel pricing (§15) |
| 8 | **Un concorrente con distribuzione (Anki, Duolingo, Notion Calendar, o Apple/Google stessi con "Focus mode" nativo) copia la parte facile** (flashcard LLM o notifiche di planning) prima che FocusMaxxer raggiunga scala | Media | Alta | Le feature isolate (LLM flashcard, implementation intention prompt) sono facilmente replicabili da chi ha già distribuzione; il differenziatore difendibile è la combinazione + il rigore metodologico, non visibile all'utente medio | Puntare il marketing sul rigore scientifico (§6, §4.1-C) come differenziatore non copiabile a basso sforzo |
| 9 | **Il comitato etico o il DPO universitario blocca o rallenta il pilota** per via del combinato dati comportamentali granulari + minorenni potenziali + Art. 9 GDPR (§11) | Media | Alta | Approvazioni etiche/DPIA per dati sensibili + minori richiedono tempi mesi, non settimane, e possono richiedere ridisegno della raccolta dati | Consultare DPO/comitato etico prima di finalizzare il disegno di raccolta dati, non dopo |
| 10 | **Nessuno dei segnali aggiuntivi (biometria, digital phenotyping) supera mai la baseline solo-comportamento**, e il team continua a investire in essi comunque per inerzia di roadmap | Media | Media | È esattamente il test di ablazione richiesto da §3.4 handoff — se non viene eseguito presto e onestamente, il rischio è sunk-cost fallacy su feature che non aggiungono valore misurabile | Eseguire il test di ablazione come primo esperimento, non come conferma finale |

**Il rischio più sottovalutato della lista è il #6.** Non è un rischio tecnico ma di sequenza: il progetto ha oggi più energia intellettuale investita in BOLS, action centering e IntelligentPooling (R4) che in una singola riga di evidenza su "gli utenti tornano il giorno 8". Un algoritmo perfetto applicato a un prodotto che nessuno riapre è zero. Il rischio #9 è il secondo più sottovalutato: è procedurale, non scientifico, e i tempi di un comitato etico non sono negoziabili con l'urgenza del prodotto — va messo in calendario ora, non quando il pilota è "pronto".

---

## 9. Dataset pubblici

**Il migliore trovato, e sottovalutato**: **FSRS-Anki-20k** (Hugging Face, progetto open-spaced-repetition) — **~1,7 miliardi di review log** da 20.000 collezioni Anki reali, con una versione preprocessata da ~20GB e i raw log da ~50GB; un dataset gemello più piccolo (`anki-revlogs-10k`) con >200 milioni di review da 10.000 collezioni è già usato per allenare **FSRS**, l'algoritmo di spaced repetition open-source oggi considerato lo stato dell'arte (adottato nativamente in Anki). ([Hugging Face — FSRS-Anki-20k](https://huggingface.co/datasets/open-spaced-repetition/FSRS-Anki-20k); [srs-benchmark](https://github.com/open-spaced-repetition/srs-benchmark)).

**Perché conta più di quanto sembri**: questo dataset non sostituisce il pilota (non contiene i decision point di timing/contesto che servono al bandit), ma risolve un problema diverso e altrettanto costoso — **calibrare il modello di memoria per-item** (probabilità di recall in funzione dell'intervallo, difficoltà, storia delle review) **senza aspettare mesi di dati propri**. Se l'idea §8.1 (recall a distanza come reward) diventa il cuore del prodotto (riformulazione A, §4.1), FocusMaxxer può partire con un modello FSRS **già pre-addestrato su miliardi di osservazioni reali** invece di stimarne uno da zero sui pochi item-review che il pilota da 40-50 studenti produrrà in 6 settimane. È l'equivalente, per il layer "memoria", di quello che il transfer learning fa per la visione artificiale: un prior enorme e gratuito, da affinare (non da ricostruire) sui dati propri.

**StudentLife (Wang et al. 2014, Dartmouth, *UbiComp* 2014)**: 48 studenti, 10 settimane, Android, sensori continui + EMA. Correlazioni riportate tra pattern comportamentali (attività, conversazione, mobilità, presenza a lezione, "studying", "partying") e **GPA cumulativo tramite regressione lineare con regolarizzazione lasso** — utile come *fonte di feature engineering* (quali segnali comportamentali sono stati storicamente informativi) più che come dataset da cui derivare pesi direttamente trasferibili: N=48 è troppo piccolo per stime stabili, e il contesto (Dartmouth 2013, Android-only, pre-LLM) limita la trasferibilità diretta. Il dataset **è pubblico**, quindi utilizzabile per un'analisi esplorativa a costo zero sulla plausibilità dei costrutti comportamentali prima del pilota — non per addestrare il modello di produzione.

**Cosa manca, onestamente**: non esiste un dataset pubblico che unisca (a) sessioni di studio dichiarate con durata pianificata vs effettiva, (b) raccomandazioni di timing randomizzate, e (c) outcome di apprendimento oggettivo. È esattamente il dato che il pilota deve generare — nessuna scorciatoia lo sostituisce per la parte causale del progetto (bandit, R4). Il valore dei dataset pubblici è quindi **circoscritto e reale**: accelerano il layer di memoria (FSRS-Anki-20k, mesi di sviluppo risparmiati) e offrono un banco di prova a costo zero per il feature engineering comportamentale (StudentLife), ma **non riducono di un giorno** il bisogno del pilota per la componente di timing/scheduling, che resta insostituibile.

---

## 10. Panorama competitivo

| App | Claim | Metrica ottimizzata | Evidenza dietro il claim | Limite rilevante per FocusMaxxer |
|---|---|---|---|---|
| **Forest** | Gamifica la concentrazione (albero che cresce/muore) | Sessioni senza uscire dall'app | Nessuna validazione pubblica; efficacia = blocco distrazioni in "88% delle sessioni testate" (fonte terza, non peer-reviewed) | Puro engagement loop, zero personalizzazione, zero contenuto pedagogico |
| **Focusmate** | Accountability tramite co-working video con sconosciuti | Presentarsi alla sessione prenotata | Effetto di accountability sociale, plausibile ma non quantificato dall'azienda | Non scala a studio individuale silenzioso; dipende da disponibilità altrui |
| **Brain.fm** | Musica "funzionale" per concentrazione | Ascolto/abbonamento | Letteratura su musica di sottofondo è mista/negativa per compiti complessi (R2 handoff) — claim aggressivo su base debole | Rischio di over-claim scientifico simile a quello che il team vuole evitare |
| **RescueTime** | Analytics passivi di utilizzo dispositivo | Tempo tracciato, non azione | Nessun intervento, solo misura — non affronta né timing né contenuto | Buon esempio di "solo baseline comportamentale", nessuna prescrizione |
| **Rize** | Time tracking automatico + "focus score" AI | Punteggio giornaliero, $9.99/mese | Punteggio proprietario, non pubblicato | Score opaco — esattamente il rischio di "curva liscia su R² basso" che il team vuole evitare (§6 handoff) |
| **Sunsama, Motion, Reclaim.ai** | Pianificazione/scheduling AI del calendario | Task completati, ottimizzazione agenda | Nessuna base nelle scienze cognitive citata — sono tool di produttività generica, non di apprendimento | Competono sul "quando" ma senza alcun ancoraggio a evidenza cognitiva — spazio libero per un claim scientificamente fondato |
| **Anki / RemNote / Traverse** | Spaced repetition (SM-2/FSRS) | Recall a lungo termine | Solida: FSRS validato su miliardi di review (§9) | UX ostica per non-power-user; nessun layer di timing/contesto; nessuna generazione automatica di contenuto (fino a plugin di terzi) |
| **Rise Science** | "Energy Potential" da sleep debt + modello SAFTE | Punteggio 0-100 | Dichiara esplicitamente di basarsi su SAFTE (stesso modello del handoff) — stesso limite di dominio: validato per vigilanza sotto deprivazione, non per attenzione intra-task | Convalida indiretta che il mercato **already** usa SAFTE fuori dal suo dominio di validazione — FocusMaxxer rischierebbe lo stesso errore se non lo corregge |
| **Whoop / Oura "readiness"** | Punteggio di prontezza da HRV/sonno/temperatura | Score giornaliero fisso | Nessuna validazione pubblica indipendente della formula proprietaria | Stesso rischio di sovra-affermazione visiva; FocusMaxxer ha già deciso di evitarlo (fasce, non punteggio continuo) — differenziatore reale se comunicato bene |
| **Opal, One Sec, Freedom, AppBlock** | Blocco/frizione su app distraenti | Sessioni bloccate, abbonamento ($19.99/mese Opal) | Meccanismo comportamentale plausibile (friction), nessun RCT pubblico noto | Stesso limite tecnico iOS documentato in §2: "loopholes" strutturali, nessuno lo risolve del tutto |
| **Endel** | Audio adattivo per focus/relax | Ascolto, abbonamento | Marketing su "neuroscienza", claim non verificabile pubblicamente | Stesso rischio regolatorio/di credibilità di Brain.fm |
| **Focus Bear** | Routine + blocco app per neurodivergenti (ADHD) | Abbonamento, routine completate | Nicchia specifica (ADHD), nessuna pubblicazione di validazione trovata | Segmento verticale interessante ma fuori scope attuale |
| **StudyU / StudyMe** | Piattaforma open-source per N-of-1 trial digitali (non-commerciale, ricerca) | Completamento del trial personale | **Pubblicato su JMIR** (Wenzel et al. 2022, DOI su [jmir.org](https://www.jmir.org/2022/7/e35884)), disegno metodologicamente rigoroso, entrambe le app open-source | **Non è un concorrente diretto — è infrastruttura riusabile.** StudyU Designer (per i ricercatori) e l'app StudyU/StudyMe (per i partecipanti) implementano esattamente il pattern N-of-1 che la riformulazione C (§4.1) richiederebbe: vale la pena valutare se riusare/ispirarsi al codice open-source invece di costruire da zero il motore di trial personali |

### 10.1 Dov'è lo spazio vuoto reale

Nessuno dei concorrenti sopra combina **(a) contenuto pedagogico con supporto meta-analitico esplicito e citato**, **(b) inferenza causale onesta con incertezza dichiarata (fasce, non punteggio)**, e **(c) un layer di misura oggettiva dell'apprendimento (recall a distanza)**. Ognuno ha al massimo una di queste tre gambe: Anki ha (c) ma non (a)/(b) in modo esplicito lato prodotto; Rise/Whoop/Oura hanno l'ambizione di (b) ma la tradiscono con punteggi sovra-precisi; Forest/Focusmate hanno solo engagement loop. **Lo spazio vuoto non è una nuova categoria di feature — è il rigore combinato con onestà statistica**, comunicato come differenziatore di prodotto (coerente con la riformulazione C, §4.1, e con l'idea §8.3 del handoff). È un vantaggio difendibile solo se il team resiste alla tentazione, documentata in tutto il mercato analizzato, di **arrotondare l'incertezza per sembrare più sicuro dei concorrenti** — la stessa tentazione contro cui il handoff si è già premunito (§6, fasce anziché punteggio).

StudyU/StudyMe meritano un follow-up tecnico dedicato: se il codice è riusabile sotto licenza compatibile, il motore N-of-1 della riformulazione C potrebbe costare mesi di sviluppo in meno di quanto stimato — da verificare la licenza e l'architettura (probabilmente Flutter/Dart lato app, coerente con lo stack di FocusMaxxer, da confermare) prima di scartare l'opzione.

---

## 11. GDPR e dispositivo medico

### 11.1 GDPR — Articolo 9 e minorenni

I dati che FocusMaxxer raccoglie (sonno, HR/HRV, comportamento di studio combinato con indicatori di stato) rientrano con alta probabilità nella categoria **dati relativi alla salute** ex Art. 9 GDPR — categoria "speciale", che richiede **sia** una base giuridica ex Art. 6 **sia** una condizione specifica ex Art. 9(2) (le due basi sono cumulative, non alternative). Il consenso esplicito, per essere valido, deve essere **libero, specifico, informato, inequivocabile, documentato e revocabile**, e deve nominare esplicitamente le categorie di dati sanitari trattate — un consenso generico "acconsento al trattamento dati" in fase di onboarding **non basta** per HR/HRV/sonno.

Per il pilota accademico esiste una via alternativa: l'Art. 9(2)(j) permette il trattamento per finalità di **ricerca scientifica**, soggetto alle garanzie dell'Art. 89(1) — ma questo richiede tipicamente approvazione di un comitato etico e un disegno di raccolta dati pre-registrato, non un semplice consenso in-app. Il target utenti ("studenti") include con alta probabilità **minorenni** (matricole 17-18enni in molti sistemi universitari europei, o studenti di scuola superiore se il target si allarga): il consenso di un minore per dati sanitari **richiede** tipicamente il consenso di un titolare della responsabilità genitoriale, con eccezioni caso per caso a seconda dello stato membro — un vincolo operativo pesante per l'onboarding self-service che il concept attuale presuppone.

⚠️ **Punto da verificare con un legale prima del lancio**, non ricavabile in modo definitivo da ricerca web generalista: se il target realistico del pilota è "solo maggiorenni, iscritti universitari", il rischio minori si riduce ma non sparisce (università comprendono anche 17enni in molti paesi UE); la clausola di esclusione va formalizzata nei termini d'uso e verosimilmente verificata con un controllo età, non solo dichiarata.

### 11.2 Confine dispositivo medico — la buona notizia, con una condizione

**FDA — "General Wellness: Policy for Low Risk Devices"**, versione rivista pubblicata **6 gennaio 2026**, sostituisce la guidance del 2019: un prodotto qualifica come "general wellness" (fuori dalla regolamentazione come dispositivo medico) se soddisfa **due condizioni cumulative**: (1) è destinato **esclusivamente** a mantenere o promuovere la salute generale o comportamenti sani, e (2) presenta **basso rischio** per la sicurezza (non invasivo, non impiantato, tecnologia non a rischio). La revisione 2026 introduce un'apertura rilevante: i prodotti non invasivi possono ora **stimare, inferire o restituire parametri fisiologici** (inclusa la HRV) per finalità di general wellness **senza diventare dispositivi medici, purché non facciano riferimento a claim specifici di malattia**.

**MDCG 2019-11 (UE)** — aggiornata a giugno 2025 (rev.1): la guida per qualificare/classificare software come dispositivo medico sotto MDR/IVDR. Le fonti secondarie consultate confermano che **le app fitness/wellness sono esplicitamente chiarite come NON dispositivi medici** nella revisione, ma **non sono riuscito a recuperare il testo primario del documento** (il PDF ufficiale della Commissione Europea non è stato estraibile in questa sessione per limiti tecnici del fetch) — ⚠️ **NON VERIFICATO sul testo primario**: il criterio di demarcazione esatto (probabilmente imperniato, come nella prassi nota di MDCG 2019-11, sulla distinzione tra dati che informano decisioni cliniche/diagnostiche vs dati che restano informativi/lifestyle) va confermato leggendo il PDF direttamente prima di formulare i claim finali di prodotto.

**Implicazione operativa, comunque solida sulla base di entrambe le fonti regolatorie**: FocusMaxxer resta nel perimetro "general wellness / non-dispositivo-medico" **finché**:
1. non fa claim di diagnosi, trattamento o prevenzione di una condizione medica specifica (es. mai "rileva il tuo disturbo del sonno", sempre "ti aiuta a capire come il sonno influenza la tua giornata di studio");
2. i punteggi/fasce restano dichiaratamente informativi e non "clinicamente interpretati" — coerente con la scelta già presa dal team di usare fasce ordinate e non un punteggio clinico-style;
3. la readiness/il consiglio di timing non viene mai formulato come raccomandazione di natura sanitaria ("dovresti dormire di più per la tua salute") ma come raccomandazione di produttività/studio.

Questo perimetro è **compatibile** con il concept attuale, ma è **fragile rispetto al linguaggio di marketing**: la riformulazione C (§4.1, "l'app fa un esperimento su di te") e qualunque narrativa "misuriamo il tuo stato cognitivo" spingono pericolosamente verso claim che assomigliano a valutazione clinica. La raccomandazione linguistica è la stessa data in §6: **mai "misuriamo", sempre "ti aiutiamo a scoprire pattern nel tuo comportamento di studio"** — differenza non cosmetica, è la linea che separa general wellness da dispositivo medico secondo entrambe le guidance citate.

**Fonti**: [FDA General Wellness guidance, sintesi 2026](https://kendallpc.com/fdas-2026-guidance-on-general-wellness-devices-policy-for-low-risk-devices-key-compliance-and-regulatory-insights-for-digital-health-companies/), [Troutman Pepper](https://www.troutman.com/insights/fdas-2026-guidance-on-general-wellness-devices-policy-for-low-risk-devices/); [aggiornamento MDCG 2019-11 rev.1, giugno 2025 — pagina ufficiale CE](https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en), [sintesi BioSlice](https://www.biosliceblog.com/2025/07/revised-guidance-on-classification-of-medical-device-software-in-the-eu/); Art. 9 GDPR, sintesi ([Secure Privacy](https://secureprivacy.ai/blog/gdpr-article-9-special-categories-lawful-processing-and-compliance-guide-2026)).

---

## 12. Nudge: Mertens vs Maier

Entrambi pubblicati in *PNAS* 2022, sugli stessi dati aggregati, con conclusioni opposte — un caso da manuale di quanto la correzione per publication bias possa ribaltare un risultato:

- **Mertens et al. 2022**: effetto pooled dei nudge **d=0.43**, presentato come "tecnica efficace e ampiamente applicabile".
- **Maier et al. 2022** ("No evidence for nudging after adjusting for publication bias"): sullo stesso corpus, correggendo per bias di pubblicazione (rilevato via Egger regression e funnel plot), **l'effetto residuo è compatibile con zero**; Mertens stessa riconosce un bias significativo ma, nella propria analisi di sensibilità, stima che l'effetto vero potrebbe scendere fino a **d=0.08** nello scenario di bias severo, pur scegliendo di non applicare la correzione nell'analisi principale.

**Lettura onesta per FocusMaxxer**: il nudge come categoria generica ("notifiche/promemoria comportamentali") **non ha un effect size affidabile su cui costruire un prior forte** — la forbice 0.43→~0.08→~0 è troppo ampia per un warm-start numerico credibile. Questo non significa "non fare nudge" — significa **non trattare "nudge" come un arm unico nel bandit con un prior comune**: i nudge specifici del progetto (implementation intention prompt, d=0.65 misurato su un costrutto diverso e molto più solido; planning prompt) vanno trattati con i loro propri prior specifici, verificati singolarmente, non ereditando l'ottimismo della letteratura nudge generica ante-correzione.

**Budget di notifiche**: nessuna fonte quantifica un numero "sostenibile" universale; la letteratura su notification fatigue converge qualitativamente su "poche, contestuali, con opt-out facile" più che su un numero preciso — trattare qualunque cifra specifica (es. "max 3/giorno") come euristica di design, non come parametro derivato da evidenza, e validarla nel pilota stesso come ulteriore arm/vincolo.

---

## 13. Algorithm aversion

Dietvorst, Simmons & Massey — due studi che vanno letti in sequenza:

- **2015** ("Algorithm aversion: people erroneously avoid algorithms after seeing them err"): dopo aver visto un algoritmo sbagliare anche una sola volta, le persone lo abbandonano più rapidamente di quanto abbandonino un umano che ha sbagliato allo stesso modo — anche quando l'algoritmo resta oggettivamente più accurato in media.
- **2018** (*Management Science* 64(3):1155–1170, "Overcoming algorithm aversion: people will use imperfect algorithms if they can (even slightly) modify them"): dare agli utenti **anche un controllo minimo e fortemente vincolato** sulle previsioni dell'algoritmo aumenta significativamente la disponibilità a usarlo, la soddisfazione percepita, la fiducia nella sua superiorità, e — dato più importante — **le prestazioni effettive**. La preferenza per l'algoritmo modificabile regge **anche quando le modifiche permesse sono minime**.

**Applicazione diretta al design di FocusMaxxer**: la prima raccomandazione errata del bandit (inevitabile, è nella natura dell'esplorazione) rischia di attivare abbandono sproporzionato se l'utente non ha alcuna leva. Il concept già prevede che l'utente "possa liberamente ignorare le raccomandazioni" — buona base, ma il pattern di Dietvorst suggerisce che sia utile **rendere l'atto di modifica visibile e con feedback**, non solo possibile: un semplice "sposta questa raccomandazione" con un cursore invece di uno swipe-to-dismiss binario, perché è la sensazione di **co-autorialità** (anche vincolata) a produrre l'effetto, non solo la libertà di ignorare.

**Comunicare l'incertezza**: la letteratura su algorithm aversion non da sola risponde se dichiarare incertezza aumenti o riduca la fiducia — è un'area dove il handoff (§14 di R5, non coperta a fondo in questa sessione per budget di ricerca) meriterebbe un affondo dedicato con van der Bles et al. (Royal Society) in un futuro incremento di questo report. Nota per iterazioni successive, non chiudibile qui con evidenza diretta raccolta in questa sessione.

---

## 14. Canali di segnale non considerati

Il digital phenotyping passivo (§8.5 handoff) è per lo più bloccato su iOS (§2.1) — ma alcuni canali alternativi restano aperti su entrambe le piattaforme, o hanno un caso d'uso più forte di quanto il handoff riconosca:

- **Entropia dell'uso app come proxy di stato**: la letteratura clinica su digital phenotyping per depressione mostra correlazioni concrete — uno studio (Purple Robot) riporta **r=−0.63** tra entropia normalizzata (GPS + uso app) e PHQ-9; un altro riporta **r=−0.19 (95% CI −0.37, −0.00)** per la deviazione standard dell'entropia della frequenza d'uso app, molto più debole. Il range **r da 0.19 a 0.63** a seconda dello studio conferma esattamente l'ammonimento del _RESUME.md ("essere spietati: molti sono r≈0.2-0.4"): il segnale esiste ma è **rumoroso e dipendente dal setup**, e viene comunque da popolazioni cliniche (depressione), non da studenti sani in sessione di studio — un altro caso di transfer di dominio da trattare con cautela, non da assumere. Su Android, dove `UsageStatsManager` lo rende disponibile, è un arm a costo zero da testare nel gate di ablazione (§3.4 handoff) prima di qualunque biometria wearable.
- **Calendario ed esami**: già in §8.6 del handoff come "moderatore dominante" — qui va aggiunto che l'integrazione calendario (lettura, non scrittura) è tecnicamente banale su entrambe le piattaforme (EventKit su iOS, CalendarContract su Android) e non richiede permessi sensibili al livello di HealthKit/Health Connect — probabilmente il segnale a più alto rapporto valore/costo di implementazione di tutta la lista.
- **Meteo**: economico da integrare (API pubbliche gratuite), ma l'evidenza di un effetto diretto su performance cognitiva intra-day è debole e non è stata verificata in questa sessione con fonti primarie — trattarlo come feature esplorativa a bassissima priorità, non come arm con prior.
- **Localizzazione/luogo di studio**: forte candidato teorico (biblioteca vs casa vs bar) — su iOS richiede permesso di localizzazione con lo stesso attrito di consenso di qualunque dato sensibile, e senza un canale per dedurre "tipo di luogo" nativamente (serve geofencing + un database POI di terze parti); su Android più agevole ma stesso attrito UX. Costo di implementazione medio, non "a costo zero" come suggerito nel handoff.
- **Browser extension**: menzionata nel handoff come alternativa economica al desktop companion — confermata: tecnicamente è ordini di grandezza più semplice di un'app desktop nativa (nessuna firma di codice, nessun installer, deployment via store estensione), ma cattura solo il tempo in browser, non l'uso di altre app desktop (IDE, Word, PDF reader nativi) — copertura parziale del compito reale.
- **Integrazione LMS (Moodle/Canvas)**: le API REST di entrambe le piattaforme espongono scadenze e materiali in modo standard e documentato (OAuth2, nessuna acrobazia tecnica) — probabilmente il canale con il miglior rapporto segnale/attrito per catturare il carico accademico (§8.6 handoff) **se** l'università è il cliente (§15) e concede l'accesso; irrilevante se il go-to-market resta B2C puro, perché il singolo studente raramente ha le credenziali API per la propria istanza istituzionale.

**Sintesi**: tra i canali "creativi" elencati dal handoff, calendario ed entropia d'uso app (Android) sono gli unici a costo di implementazione realmente basso **e** con un briciolo di evidenza empirica diretta; gli altri (meteo, localizzazione, LMS) sono plausibili ma o poco supportati o costosi da integrare bene — da trattare come backlog esplorativo, non come feature del pilota a 6 settimane.

---

## 15. Business model

**Chi paga il pilota**: con 40-50 studenti × 6 settimane, il costo è dominato da incentivi ai partecipanti (compensare l'assenza di retention organica del pilota, §7.1) più costo API LLM (§3.4) — ordine di grandezza gestibile con un budget di ricerca universitario o un pre-seed, non serve un investitore istituzionale a questo stadio.

**Freemium vs abbonamento vs licenza istituzionale — tre percorsi con implicazioni di dati molto diverse**:

- **Freemium B2C**: il percorso di default implicito nel concept. Rischio già coperto (§8, causa #1): a retention mHealth reale del 3-5% a 30 giorni, il funnel gratuito→pagante richiede volumi enormi per essere sostenibile — tipico dei mercati mHealth, dove pochi player sopravvivono sulla sola acquisizione organica. Il differenziatore scientifico (§10.1) aiuta il posizionamento ma non risolve da solo l'economia dell'attrito.
- **Abbonamento diretto**: prezzo di riferimento nel mercato analizzato spazia da $6.99/mese (Focusmate) a $19.99/mese (Opal) — un abbonamento "coach di studio con scienza" si posiziona plausibilmente a metà, ma **compete per lo stesso budget studentesco** di Anki (gratuito/one-time), Notion (spesso gratuito per studenti), Forest ($1.99 one-time) — la sensibilità al prezzo del target è strutturalmente alta.
- **Licenza istituzionale (università come cliente)**: cambia radicalmente sia l'economia sia il design dei dati. Vantaggi: budget più prevedibile, accesso a dati d'esame come outcome distale gratuito (§8.4 handoff) **con consenso istituzionale invece che auto-riportato**, canale di integrazione LMS (§14) sbloccato in modo naturale. Costi: introduce un comitato etico istituzionale come gatekeeper obbligato (§8, causa #9), tempi di vendita B2B lunghi (cicli accademici, non sprint), e un conflitto di interesse da gestire con cura — l'università che paga per uno strumento che raccoglie dati comportamentali granulari sui propri studenti è un tema che richiede trasparenza esplicita verso gli studenti stessi, non solo verso l'istituzione pagante.

**Raccomandazione**: il pilota a 6 settimane è comunque un progetto di ricerca, non un test di business model — ma **la scelta del canale di reclutamento del pilota (studenti auto-selezionati vs corso universitario con credito) prefigura quale modello di business si sta implicitamente testando**. Se il pilota recluta tramite un corso specifico con l'assenso del docente, il team sta già facendo, di fatto, un proof-of-concept del canale istituzionale — vale la pena renderlo esplicito nella pianificazione invece di scoprirlo a posteriori.

---

## 16. Aderenza, motivazione, engagement

### 16.1 Procrastinazione: gli interventi funzionano, ma non quelli "leggeri"

van Eerde & Klingsieck 2018 (*Educational Research Review*, meta-analisi, **k=44 confronti, N=1.173**, 24 studi): riduzione **ampia e stabile nel follow-up** della procrastinazione dopo intervento, con la **terapia cognitivo-comportamentale più efficace** delle altre categorie (self-regulation, altri approcci terapeutici, interventi basati su punti di forza). Nota rilevante per il design: **la durata dell'intervento non è risultata un moderatore significativo** — non serve un programma lungo per ottenere effetto, ma gli interventi confrontati sono più strutturati (protocolli CBT) di quanto un prompt in-app possa replicare. Implicazione onesta: FocusMaxxer, con un semplice prompt di pianificazione, **non sta implementando un intervento anti-procrastinazione da manuale clinico** — sta implementando la sua componente più leggera e scalabile (implementation intentions), il cui effetto è ben documentato ma **isolato** rispetto al pacchetto CBT completo che la meta-analisi valuta. Non sovra-vendere l'aspettativa interna.

### 16.2 Implementation intentions in consegna digitale: quanto cala l'effetto?

Il d=0.65 di Gollwitzer & Sheeran 2006 (94 test, >8.000 partecipanti, già verificato nel handoff) proviene in larga parte da **studi con intervento faccia a faccia o su carta**, non da prompt digitali. ⚠️ **NON VERIFICATO in questa sessione con una fonte quantitativa diretta**: non è stato possibile, nel budget di ricerca disponibile, recuperare una meta-analisi specifica sul decadimento dell'effect size nella consegna app-based — è un gap esplicito da chiudere prima di fissare il prior numerico per questo arm. La raccomandazione prudente è **scontare il prior** (es. partire da d≈0.4-0.5 invece di 0.65 per il warm-start del bandit su questo arm specifico) finché non si trova o genera evidenza diretta sul canale digitale, coerente con il principio generale "gli effect size di laboratorio si comprimono nel mondo reale" già applicato altrove nel corpus di evidenza (Schwarz 2026: atteso 0.8, osservato 0.11).

### 16.3 SDT e reattanza: l'autonomy-supportive language non ha una singola meta-analisi dedicata reperita

Il principio della Self-Determination Theory (Deci & Ryan) — linguaggio che supporta l'autonomia riduce la reattanza rispetto a linguaggio controllante — è ben stabilito come framework teorico, ma ⚠️ **non è stata reperita in questo budget di ricerca una meta-analisi quantitativa specifica su "formulazione autonomy-supportive vs controllante" isolata come variabile**. La raccomandazione operativa resta valida a livello qualitativo (mai "devi fare una pausa", sempre "potresti considerare una pausa" — coerente con la scelta già presa dal team su terminazioni non prescritte, §6 handoff) ma **senza un effect size specifico da citare pubblicamente** finché non si recupera la fonte primaria.

### 16.4 Habit formation — vedi §5

Trattato in dettaglio in §5 (conflitto randomizzazione/abitudine). Qui solo il punto di raccordo: Lally et al. 2010 fissa il **range di riferimento (18-254 giorni, mediana 66)** per qualunque decisione di prodotto che assuma "l'utente avrà formato un'abitudine dopo N settimane" — il pilota di 6 settimane (42 giorni) **cade sotto la mediana**, quindi **non misurerà abitudine formata nella maggioranza dei partecipanti**, un altro limite del dimensionamento del pilota da dichiarare esplicitamente, non solo per la personalizzazione statistica (già coperta da R4) ma anche per l'aderenza comportamentale.

### 16.5 Gamification: effetto reale ma disomogeneo, e il rischio di overjustification è documentato, non teorico

Sailer & Homner 2020 (*Educational Psychology Review* 32:77-112, meta-analisi): effetti piccoli-medi e **significativi** su learning cognitivo (**g=0.49, 95% CI [0.30,0.69], k=19, N=1.686**), motivazionale (**g=0.36, [0.18,0.54], k=16, N=2.246**) e comportamentale (**g=0.25, [0.04,0.46], k=9, N=951**). Punto cruciale per la validità: **l'effetto cognitivo resta stabile negli studi a maggior rigore metodologico; gli effetti motivazionale e comportamentale sono meno stabili** — cioè la gamification "funziona per davvero" più sull'apprendimento diretto che sulla motivazione duratura, il che è controintuitivo rispetto al motivo per cui di solito la si implementa (aumentare l'engagement).

Il contro-dibattito richiesto dai requisiti di qualità: Deci, Koestner & Ryan 1999 (*Psychological Bulletin*, meta-analisi **128 studi**): le ricompense **engagement-contingent, completion-contingent e performance-contingent minano significativamente la motivazione intrinseca free-choice** — è l'evidenza quantitativa dietro l'overjustification effect, e gli autori mostrano che una meta-analisi precedente (Cameron & Pierce) che minimizzava questo rischio era "seriamente viziata" metodologicamente. **Applicazione diretta**: qualunque sistema di streak/badge/punti legato al *completamento* di una sessione (non alla sua qualità) rischia esattamente il pattern documentato da Deci — mina la motivazione intrinseca a studiare bene in cambio di un incentivo a "spuntare la casella". Coerente con l'ottimo degenere già identificato nel handoff (§5, "premiare il completamento insegna a dichiarare durate brevi") — qui la stessa dinamica si manifesta anche a livello motivazionale, non solo comportamentale-statistico.

**Raccomandazione**: se si implementa gamification, ancorarla a **outcome di qualità (recall a distanza, §8.1)**, mai al solo completamento/durata — è l'unico modo per allineare l'incentivo esterno con l'apprendimento reale invece di sostituirlo.

### 16.6 Self-efficacy e mindset: più debole di quanto la cultura pop suggerisca

Sisk et al. 2018 (meta-analisi su growth mindset) e il National Study of Learning Mindsets citati nel brief hanno mostrato effetti **piccoli e eterogenei**, molto più modesti della narrativa popolare da cui il concetto è penetrato nel mainstream. ⚠️ Non è stato possibile in questo budget recuperare i numeri esatti con fonte primaria in questa sessione — riportato qui come promemoria del rischio, non come dato verificato. Il rischio nocebo pratico: se l'app comunica un readiness/attribuzione negativa ("oggi non sei nelle condizioni ideali"), il rischio di indurre impotenza appresa è reale e **non compensato** da un effetto mindset-boosting altrettanto forte nella direzione opposta — coerente con la scelta già presa dal team (allocazione di compiti, mai ore morte, §6 handoff).

### 16.7 Brain drain: la citazione più a rischio nel corpus se non corretta ora

Ward et al. 2017 ("Brain Drain: the mere presence of one's own smartphone reduces available cognitive capacity", *JACR* 2(2)) è probabilmente la fonte più citata a supporto di "allontana il telefono" — ma **una replicazione diretta con gli stessi task (o-span, go/no-go) non ha trovato differenza tra condizioni di posizione del telefono** ([Ruiz Pardo & Minda 2022, ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0001691822002323); confermata fallita anche da una seconda replicazione indipendente). Una meta-analisi più ampia sul "brain drain effect" esiste ma con risultati eterogenei tra studi. **Implicazione per FocusMaxxer**: il claim "la sola presenza del telefono riduce le tue capacità cognitive" **non va usato come giustificazione scientifica per il blocco app** (§8.12 handoff) — è un caso da manuale esattamente come background music, CO2, ego depletion (già segnalati come ridimensionati nei requisiti di qualità di questo report). Il blocco app resta un arm difendibile su altre basi (riduzione di interruzioni misurabili, non "capacità cognitiva ridotta dalla mera presenza"), ma la narrativa di marketing va corretta ora, prima che diventi un claim pubblico difficile da ritirare.

### 16.8 Onboarding

Nessuna fonte quantitativa specifica sul "quanto si può chiedere al giorno 1" è stata reperita in questo budget — punto lasciato aperto, ma la logica generale del corpus (attrito cumulativo, retention già bassissima §7.1) suggerisce di **trattare ogni domanda d'onboarding oltre l'essenziale (tipo di compito, durata, eventuale µMCTQ) come un test A/B a sé**, non come un default assunto sicuro.

---

## 17. Le 10 azioni più importanti nei prossimi 3 mesi

Ordinate per rapporto valore/costo stimato, non per urgenza cronologica.

1. **Eseguire il test di ablazione della biometria (§3.4 handoff) come primo esperimento del progetto**, non come conferma finale. Costo: giorni di analisi su dati sintetici/pilota minimo. Valore: previene mesi di ingegneria su feature che potrebbero non superare mai "ora del giorno + comportamento".
2. **Prototipare la riformulazione B (§4.2) come guscio di prodotto**: implementation intention prompt + planning al momento della dichiarazione di sessione, senza aspettare il bandit completo. Costo: basso, riusa pezzi già esistenti nel concept. Valore: attacca l'effect size più grande e meno contestabile del corpus (d=0.65) prima ancora che l'infrastruttura statistica sia pronta.
3. **Costruire il pipeline LLM flashcard-generation + grading a bassa soglia di rischio** (§3.4): import materiale → generazione domande → revisione utente → deck attivo → grading risposte aperte con soglia di confidenza. Costo: medio (integrazione API + costi variabili da budgetizzare). Valore: sblocca l'idea §8.1 del handoff, già giudicata la più promettente, oggi bloccata solo dall'attrito che l'LLM risolve.
4. **Consultare un legale/DPO e — se rilevante — un comitato etico universitario ORA, non a ridosso del pilota** (§8 causa #9, §11): il tempo di approvazione per dati Art. 9 + potenziali minorenni non è comprimibile con la roadmap prodotto.
5. **Dichiarare esplicitamente la roadmap "Android-first, iOS-degradato"** (§2.5) nella pianificazione tecnica, evitando di promettere parità di feature che le API Apple rendono strutturalmente impossibile (export dati DeviceActivity, autoblocco).
6. **Integrare il modello FSRS pre-addestrato su FSRS-Anki-20k** (§9) invece di stimare un modello di memoria da zero sui dati del pilota — settimane di sviluppo risparmiate, prior enorme e gratuito.
7. **Riscrivere il copy di "vendita della randomizzazione" prima che diventi materiale di marketing fissato** (§6): separare randomizzazione silenziosa (per l'inferenza) da esperimento dichiarato opt-in (per l'utente curioso); mai il framing "sperimentiamo su di te".
8. **Implementare la calibrazione della planning fallacy come feature, non come correzione statistica nascosta** (§7.2): mostrare all'utente il proprio scarto storico previsto/reale e proporre (non imporre) una durata corretta di default.
9. **Progettare l'ancoraggio contestuale della randomizzazione** (§5.1): esplorazione concentrata attorno al pattern abituale dell'utente invece che uniforme sull'intera giornata, per ridurre l'erosione dell'abitudine mantenendo la validità inferenziale.
10. **Misurare la retention in un piccolo soft-launch pubblico separato dal pilota controllato**, con aspettative calibrate su Baumel 2019 (mediana 3.3% a 30 giorni per mHealth reale) — per evitare di scoprire dopo il lancio che il pilota non prediceva l'attrito di mercato.

**Cosa NON fare nei prossimi 3 mesi, esplicitamente**: costruire il desktop companion (§8.7 handoff — costoso, dopo il pilota); investire nel tutoring socratico conversazionale (§3.4); inseguire canali di segnale a basso rapporto valore/costo come meteo o localizzazione (§14) prima di aver validato calendario e (su Android) entropia d'uso app; finalizzare un business model B2C freemium senza aver prima reso esplicito, nel disegno del reclutamento del pilota, quale modello si sta di fatto testando (§15).

---

## 18. Bibliografia

**Fattibilità tecnica**
- Apple Developer Forums, thread 756619 — export dati DeviceActivity, risposta ingegnere Apple: https://developer.apple.com/forums/thread/756619
- A Developer's Guide to Apple's Screen Time APIs (FamilyControls/ManagedSettings/DeviceActivity): https://medium.com/@juliusbrussee/a-developers-guide-to-apple-s-screen-time-apis-familycontrols-managedsettings-deviceactivity-e660147367d7
- Android `UsageStatsManager` reference: https://developer.android.com/reference/android/app/usage/UsageStatsManager
- Android Health Connect — data types: https://developer.android.com/health-and-fitness/health-connect/data-types
- Confronto app blocker iOS 2026 (Opal/Forest/Freedom/One Sec/Jomo): https://unstar.app/blog/opal-forest-freedom-one-sec-jomo-screen-time-apps-ranked-2026
- iOS background execution limits 2026: https://www.appsonair.com/blogs/background-execution-limits-in-ios-what-every-developer-must-know ; https://www.sachith.co.uk/background-tasks-and-limits-on-ios-android-ops-runbook-practical-guide-may-4-2026/

**LLM ed education**
- Evaluating the instrumental quality of LLM-generated assessment items, *Frontiers in Education* 2026, 10.3389/feduc.2026.1837523: https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2026.1837523/full
- VanLehn, K. (2011). The Relative Effectiveness of Human Tutoring, Intelligent Tutoring Systems, and Other Tutoring Systems. *Educational Psychologist* 46(4). DOI: 10.1080/00461520.2011.611369
- Kestin, G. et al. (2025). AI tutoring outperforms in-class active learning: an RCT... *Scientific Reports*: https://www.nature.com/articles/s41598-025-97652-6 ; sintesi: https://hechingerreport.org/proof-points-ai-tutor-harvard-physics/
- Automatic Short Answer Grading in the LLM Era — GPT-4 con prompt engineering, LAK 2025: https://dl.acm.org/doi/10.1145/3706468.3706481
- Calibration of AI LLMs with human experts, dental education, PMC12896245: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12896245/

**Aderenza e motivazione**
- Meyer, M. N. et al. (2019). Objecting to experiments... *PNAS* 116(48/22) — A/B effect, experiment aversion.
- Experiment aversion does generalize, but it can also be mitigated (2024), *PNAS* 121: https://www.pnas.org/doi/10.1073/pnas.2315439121
- A mechanical explanation for apparent experiment aversion (minimum mean paradox), *PNAS* 2019: https://www.pnas.org/doi/pdf/10.1073/pnas.1912413116
- Baumel, A., Muench, F., Edan, S., Kane, J. M. (2019). Objective User Engagement With Mental Health Apps. *JMIR* 21(9):e14567: https://www.jmir.org/2019/9/e14567/
- Lally, P. et al. (2010). How are habits formed: Modelling habit formation in the real world. *European Journal of Social Psychology* 40(6):998–1009.
- Buehler, R., Griffin, D., Ross, M. (1994); Buehler, Griffin & Peetz (2010). The planning fallacy: cognitive, motivational, and social origins.
- van Eerde, W., Klingsieck, K. B. (2018). Overcoming procrastination? A meta-analysis of intervention studies. *Educational Research Review*.
- Sailer, M., Homner, L. (2020). The Gamification of Learning: A Meta-Analysis. *Educational Psychology Review* 32:77–112.
- Deci, E. L., Koestner, R., Ryan, R. M. (1999). A meta-analytic review of experiments examining the effects of extrinsic rewards on intrinsic motivation. *Psychological Bulletin*.
- Mertens, S. et al. (2022). The effectiveness of nudging: A meta-analysis... *PNAS* — d=0.43.
- Maier, M. et al. (2022). No evidence for nudging after adjusting for publication bias. *PNAS* 119: https://www.pnas.org/doi/10.1073/pnas.2200300119
- Dietvorst, B. J., Simmons, J. P., Massey, C. (2015). Algorithm aversion.
- Dietvorst, B. J., Simmons, J. P., Massey, C. (2018). Overcoming algorithm aversion. *Management Science* 64(3):1155–1170: https://faculty.wharton.upenn.edu/wp-content/uploads/2016/08/Dietvorst-Simmons-Massey-2018.pdf
- Ward, A. F. et al. (2017). Brain Drain: The Mere Presence of One's Own Smartphone Reduces Available Cognitive Capacity. *JACR* 2(2).
- Ruiz Pardo, D., Minda, J. P. (2022). Reexamining the "brain drain" effect: a replication of Ward et al. (2017): https://www.sciencedirect.com/science/article/pii/S0001691822002323

**Panorama competitivo e dataset**
- Wenzel, M. et al. (2022). StudyU: A Platform for Designing and Conducting Innovative Digital N-of-1 Trials. *JMIR* 24(7):e35884: https://www.jmir.org/2022/7/e35884
- open-spaced-repetition/FSRS-Anki-20k, Hugging Face Datasets: https://huggingface.co/datasets/open-spaced-repetition/FSRS-Anki-20k
- Wang, R. et al. (2014). StudentLife: assessing mental health, academic performance and behavioral trends... *UbiComp 2014*.
- Digital phenotyping / entropia uso app / PHQ-9 correlazioni: JMIR Mental Health 2026, e80765; Frontiers in Psychiatry 2021, 625247.

**Regolamentazione**
- FDA, General Wellness: Policy for Low Risk Devices (rev. 6 gennaio 2026): sintesi https://kendallpc.com/fdas-2026-guidance-on-general-wellness-devices-policy-for-low-risk-devices-key-compliance-and-regulatory-insights-for-digital-health-companies/ ; https://www.troutman.com/insights/fdas-2026-guidance-on-general-wellness-devices-policy-for-low-risk-devices/
- MDCG 2019-11 rev.1 (giugno 2025), Commissione Europea: https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en (⚠️ testo primario non estratto in questa sessione, solo sintesi secondarie)
- GDPR Art. 9, sintesi 2026: https://secureprivacy.ai/blog/gdpr-article-9-special-categories-lawful-processing-and-compliance-guide-2026

> **Nota metodologica finale**: ~30 ricerche web e 8 WebFetch eseguiti in questa sessione (leggermente sopra il budget di ~25 ricerche indicato, giustificato dalla fusione di due brief — R5 e R6 — in un solo report). Le voci marcate ⚠️ NON VERIFICATO nel testo (§11.2 su MDCG testo primario, §16.2 decadimento digitale delle implementation intentions, §16.3 meta-analisi autonomy-supportive language, §16.6 numeri esatti Sisk 2018, §16.8 onboarding budget) sono gap espliciti, non colmati per limite di budget/tempo — da chiudere in un incremento successivo prima di citarle in materiale pubblico o di fissarne un prior numerico nel bandit.
