# FocusMaxxer — Handoff di contesto

> Documento di trasferimento dalla fase di analisi strategica/scientifica alla fase implementativa.
> Sintetizza decisioni prese, evidenza raccolta, vincoli metodologici, questioni aperte e piste da esplorare.
> **Non** è un piano di implementazione: è il contesto necessario per scriverne uno.
>
> **Revisione 2 (2026-08-06)** — aggiornato con i tre report di ricerca in `research/`:
> `R1_cosa_raccomandare.md`, `R2_algoritmo_e_reward.md`, `R3_punti_ciechi_e_aderenza.md`.
> Le modifiche principali: §2.1 (spacing d=0.85), §2.5 (baricentro deciso), §3.5 (fattibilità di
> piattaforma), §5 (reward risolto), §5.4 (layer LLM, nuovo), §7 (quattro questioni chiuse).

**Indice**
1. [Il concept](#1-il-concept-versione-corrente-post-revisione)
2. [Stato dell'evidenza](#2-stato-dellevidenza-numeri-non-aggettivi)
3. [Vincoli metodologici non negoziabili](#3-vincoli-metodologici-non-negoziabili)
4. [Il reframe che scioglie il problema delle etichette](#4-il-reframe-che-scioglie-il-problema-delle-etichette)
5. [Reward design — risolto](#5-reward-design--risolto)
6. [Rischi di prodotto](#6-rischi-di-prodotto-identificati)
7. [Questioni aperte](#7-questioni-aperte)
8. [Idee da esplorare](#8-idee-da-esplorare)
9. [Anti-pattern](#9-anti-pattern-da-non-ripetere)
10. [Fonti primarie](#10-fonti-primarie)

---

## 1. Il concept (versione corrente, post-revisione)

L'utente apre l'app e **dichiara** l'inizio di una sessione di studio quando vuole, indicando in un tap il **tipo di compito** (nuovo materiale / esercizi / ripasso / memorizzazione) e la **durata prevista**.

Dal primo giorno l'app:
- struttura la sessione secondo pratiche con supporto meta-analitico solido (obiettivo if-then, retrieval practice, spacing sui materiali);
- gestisce **il materiale di richiamo dell'utente** (flashcard/domande, generate da LLM dal materiale caricato) — è insieme l'intervento più forte e la sorgente della metrica di outcome (§5);
- mostra un'**allocazione oraria** della giornata che assegna a *ogni* fascia un tipo di lavoro adatto — mai zone morte, mai divieti;
- emette raccomandazioni di finestra e modalità che sono **parzialmente randomizzate fin dall'inizio e per sempre**.

Il comportamento sul dispositivo, ancorato dalla dichiarazione esplicita di sessione e disambiguato dal wearable quando presente, fornisce l'outcome *comportamentale*; la performance di richiamo a distanza fornisce l'outcome *di apprendimento* (§5.2). Man mano che i dati si accumulano, il prior di popolazione cede il posto alle stime personali — e l'app comunica cosa ha imparato **insieme a quanto ne è sicura**.

### Differenze rispetto alla formulazione iniziale del concept

| Formulazione iniziale | Versione corrente | Perché |
|---|---|---|
| Prima impara (fase passiva), poi prescrive | Randomizzazione permanente; prescrittivo dal giorno 1 con contenuto validato | La fase osservazionale produce stime causalmente invalide (§3.1) e uccide la retention |
| Grafico zone migliori/peggiori | Allocazione tipo-di-compito per fascia | Elimina nocebo, sfrutta evidenza più forte, claim più difendibile |
| Pause e terminazioni suggerite durante la sessione | Piano concordato a inizio sessione (durata dichiarata) | Evidenza più forte, zero costo di interruzione, etichetta migliore |
| Biometria come feature primaria | Biometria opzionale, ruolo di sensore di validità sessione | Copertura di mercato + la biometria non supera la baseline comportamentale + latenza tecnica fino a 30 min (§3.5) |
| — | Tipo di compito dichiarato | Confondente probabilmente dominante sull'ora del giorno; **e** moderatore che impedisce danni (§2.1, expertise reversal) |
| Flashcard come idea opzionale (§8.1) | **Flashcard come nucleo**: intervento + strumento di misura | Risolve §5 (reward) e §7.3 (baricentro); l'attrito che lo bloccava è caduto con gli LLM (§5.4) |

---

## 2. Stato dell'evidenza (numeri, non aggettivi)

### 2.1 Cosa è forte — e riguarda il *contenuto*, non il *timing*

⚑ **Breakdown per tecnica recuperato dal full text di Donoghue & Hattie 2021** (era la questione aperta §7.7). Il `0.56` citato nella revisione precedente era la **media di tutte e dieci le tecniche**, non il valore dello spacing.

| Tecnica | Cohen's d | SEM | N casi | N partecipanti |
|---|---|---|---|---|
| **Distributed practice** | **0.85** | 0.053 | 150 | 152.952 |
| **Practice testing** | **0.74** | 0.040 | 374 | 6.033 |
| Elaborative interrogation | 0.56 | 0.048 | 254 | 2.138 |
| Imagery | 0.56 | 0.061 | 135 | 1.052 |
| Self-explanation | 0.54 | 0.092 | 93 | 804 |
| Mnemonics (keyword) | 0.50 | 0.104 | 107 | 580 |
| Re-reading | 0.47 | 0.060 | 113 | 1.529 |
| Interleaved practice | 0.47 | 0.089 | 104 | 972 |
| Underlining | 0.44 | 0.115 | 56 | 1.129 |
| Summarization | 0.44 | 0.055 | 234 | 1.990 |

*Media del pool: d = 0.56 su 1.619 effetti / 169.179 partecipanti unici (242 studi).*

Altre fonti convergenti sulle due tecniche di testa:

| Costrutto | Effetto | Fonte |
|---|---|---|
| Retrieval practice / testing effect | **g = 0.50** complessivo; **0.73** con feedback vs **0.39** senza | Rowland 2014 |
| Practice testing (replica indipendente) | **g = 0.61** overall; **classe 0.67 vs lab 0.62** — nessun crollo fuori laboratorio | Adesope et al. 2017, 253 studi |
| Implementation intentions | **d = 0.65**, 94 test indipendenti, >8.000 partecipanti | Gollwitzer & Sheeran 2006 |
| Interleaving | **g = 0.42** (95% CI [0.34, 0.50]) — solo se le categorie sono confondibili | Brunmair & Richter 2019, 59 studi |
| Feedback (come costrutto autonomo) | **d = 0.48**, ma eterogeneità altissima: non è un trattamento singolo | Wisniewski et al. 2020, 435 studi, N>61.000 |
| AI tutoring | **d = 0.73–1.3** (studio singolo, dominio favorevole); ITS step-based **d = 0.76** | Kestin et al. 2025; VanLehn 2011 |

**Moderatori del pool che cambiano il design** (Donoghue & Hattie, tutte le tecniche insieme):
- Near transfer d = 0.61 vs **far transfer d = 0.39**
- Apprendimento di superficie d = 0.60 vs **profondo d = 0.26** (la maggioranza degli studi misura superficie: l'estrapolazione a comprensione profonda è debole)
- Bassa abilità d = 0.47 vs **alta abilità d = −0.11** → per gli studenti già forti l'effetto **si inverte**. È la giustificazione forte del "tipo di compito dichiarato": non è un raffinamento, è ciò che impedisce all'app di fare danni.

**Intervallo di spacing ottimale** (Cepeda et al. 2006/2008, >1.350 soggetti): non è un intervallo fisso, è una **proporzione dell'orizzonte di ritenzione** — dal **20–40% per un ritardo di 1 settimana** al **5–10% per un ritardo di 1 anno**. Richiede di conoscere la data d'esame → il calendario esami (§8.6) è ora giustificato due volte.

### 2.2 Cosa è debole

| Area | Realtà | Fonte |
|---|---|---|
| Rilevazione stress acuto da wearable, cross-dataset | **F1 ≈ 61%** (random forest, il più stabile) su HRV cross-dataset | Sensors 2023 |
| Rilevazione ansia, cross-attività / cross-popolazione | **AUROC medio migliore 0.62**; cross-activity **0.59–0.62** | Nepal et al. 2025 |
| Sonno → cognizione giorno dopo (within-person) | **+0.11 risposte corrette per ora di sonno in più** (95% CI 0.06–0.15); gli autori: *"smaller than the 0.8 difference that we expected a priori"* → **~8× più piccolo dell'atteso** | Schwarz et al. 2026 |
| Sonno → cognizione (between-person) | **Nullo**: durata, efficienza e qualità tutte p > .05 | Schwarz et al. 2026 |
| Microbreak | Riduce fatica e aumenta vigore; effetto su **performance ≈ nullo** per compiti impegnativi | Albulescu et al. 2022 |
| Mind-wandering detection su smartphone | EEG 80–83% e gaze AUROC ≥0.80 *in-domain*, ma **crollo a 0.56–0.68 cross-domain**; nessun canale disponibile su telefono comune | R2 §4.2 |
| Digital phenotyping → outcome | Correlazioni reali ma modeste, N≈48–83, singola coorte; **utilizzabile come contesto, mai come reward** | StudentLife/SmartGPA |
| Pomodoro 25/5 | **Non superiore** a pause auto-regolate | — |
| Ritmo ultradiano 90 min | Senza supporto | — |
| Burnout da wearable | Scadente | doc. strategico originale |

### 2.3 Correzioni fattuali importanti

- **Windred et al. 2024** riguarda la **mortalità per tutte le cause**, non la cognizione del giorno dopo. Citarlo per il readiness score è transfer di dominio invalido.
- I modelli di vigilanza validati (**SAFTE-FAST**, **UMP**, **Three-Process Model**) sono validati per la vigilanza sotto privazione di sonno, **non** per l'attenzione intra-task in soggetti riposati.
- La letteratura sulla vigilanza **non** è interamente fuori dominio: *vigilance decrement*, *time-on-task* e *mind-wandering detection* sono costrutti in dominio.
- Il rapporto osservato/atteso nello studio Schwarz è **~8×** (0.11 vs 0.8).
- ⚑ **Il "brain drain" di Ward et al. 2017 NON replica** (Ruiz Pardo & Minda 2022, *Acta Psychologica*: nessuna differenza tra condizioni). Va rimosso da qualunque narrazione causale. Resta robusta solo la **correlazione** uso-rendimento: r = −0.16 (95% CI [−0.20, −0.13]), 63 studi, N = 124.166 — piccola (~2,6% di varianza), su campione enorme, ma correlazionale e con confondente plausibile (autoregolazione).
- ⚑ **La letteratura CO2/cognizione è internamente contraddittoria**: Allen 2016 (Harvard, N=24) riporta −15% a 950 ppm e −50% a 1.400 ppm; uno studio danese e uno su sottomarinisti USA non trovano alcun declino fino a **5.000–15.000 ppm**. Effect size originale implausibile. **Escludere da ogni arm e da ogni claim.**
- ⚑ **Musica di sottofondo: effetto medio nullo** (Kämpfe et al. 2011), negativo con testo durante la lettura. Nessun arm "raccomanda musica" difendibile.
- **Non esiste una soglia di durata "vera"** per il vigilance decrement: il declino è continuo e task-dipendente (meta-analisi su 68 studi, ~500.000 risposte a thought-probe). La durata va trattata come **arm randomizzabile con prior piatto**, non come output di un modello di soglia.

### 2.4 Il tetto realistico

Le fonti di evidenza sono **correlate tra loro**, non indipendenti. R² totale stimato **< 10–15%** (r ≈ 0.3). Sufficiente per nudging a costi asimmetrici, **insufficiente per prescrizione**. Ogni elemento di UI che comunica più certezza di questa è una menzogna grafica.

**Implicazione strategica centrale:** le direttive di contenuto che l'app può dare gratis al giorno 1 hanno effetti **diverse volte più grandi** di qualsiasi cosa il modello personalizzato produrrà mai. Le euristiche non sono il prior del modello: **sono il prodotto**.

### 2.5 Il baricentro — decisione presa

La revisione precedente registrava questa come tensione irrisolta (§7.3). Messi i numeri fianco a fianco, non lo è più:

| Costrutto | Effetto | Dove stava nel concept |
|---|---|---|
| AI tutoring (dominio favorevole) | d = 0.73–1.3 | **assente** |
| Distributed practice | d = 0.85 | euristica di sfondo |
| Retrieval practice + feedback | g = 0.73 | "struttura la sessione", non il cuore |
| Implementation intentions | d = 0.65 | idea §8.2, non operativa |
| Sonno → cognizione (within-person) | +0.11/ora, ~8× sotto l'atteso | **cuore del concept** (SAFTE) |
| Personalizzazione del timing | R² < 10–15% | **cuore del concept** (bandit) |

Il pattern è netto: **l'ingegneria più sofisticata è investita sugli effetti più piccoli e incerti del corpus**, mentre quelli più grandi e solidi sono trattati come contorno. È il bias classico dei prodotti data-driven — l'attenzione ingegneristica va dove c'è incertezza da modellare, non dove c'è già una risposta — ma il prodotto è giudicato dall'effetto che produce, non dalla difficoltà tecnica risolta.

**Decisione**: il guscio esterno del prodotto si sposta su **iniziazione (implementation intentions) e apprendimento (retrieval + spacing)**. SAFTE, cronotipo e timing **restano**, ma retrocedono da claim principale a *uno dei segnali di contesto* `S_t` del bandit. Questo non smonta l'architettura di §4: il bandit continua a esistere e a randomizzare, ma ottimizza prevalentemente **la struttura della sessione e il ripasso**, non l'ora del giorno.

---

## 3. Vincoli metodologici non negoziabili

### 3.1 Endogeneità della selezione — il vincolo dominante

L'utente studia quando ha *già* le condizioni giuste. Qualunque stima "quali sono le tue ore migliori" derivata da dati osservazionali misura **l'effetto delle circostanze sulla scelta dell'ora**, non l'effetto dell'ora sulla performance. Il risultato è circolare, inutile, e **convincente** — che è la parte peggiore.

Conseguenze operative:
1. **Non puoi randomizzare quando l'utente studia** (decide lui). **Puoi randomizzare la raccomandazione**. È l'unica leva causale disponibile.
2. **L'esplorazione è permanente, non una fase.** Senza una frazione permanente randomizzata (~10–15%) il sistema si fossilizza sul primo errore e lo auto-conferma.
3. **Descrittivo ≠ prescrittivo.** "Ecco quando studi di più" è un fatto. "Ecco quando dovresti studiare" è un claim causale.
4. **Analisi intention-to-treat.** L'unità di analisi è la raccomandazione *emessa*, non quella *seguita*.

### 3.2 Il paradosso di misura

Il segnale comportamentale più forte di deep work è **l'assenza del telefono**, ed è indistinguibile dall'**abbandono dell'app**. Peggio: "allontana il telefono" è una delle direttive che l'app vorrà prescrivere — **la strumentazione muore esattamente quando il consiglio funziona**.

È un caso limite di **MNAR** (missing not at random): la mancanza del dato è *causata dal successo dell'intervento*. Nessuna imputazione lo risolve (la letteratura mHealth è esplicita: i metodi standard per MAR non correggono il bias sotto MNAR). Esistono solo mitigazioni:
- **Dichiarazione esplicita di inizio/fine sessione.** Converte lo schermo spento da segnale ambiguo a segnale *positivo*. Costa un tap; è l'intervento singolo più utile su tutta la pipeline dati.
- **Wearable come sensore di validità della sessione, non di stato cognitivo.** Barra bassissima che la biometria supera comodamente.
- **Sensitivity analysis** stile Rosenbaum bounds / trimmed means: produce un bound conservativo invece di una stima puntuale falsamente precisa.
- ⚑ **Il reward di recall (§5.2) soffre molto meno di questo problema**: la sua osservazione dipende dallo *scheduler* (quando ripresenta la card), non dal comportamento spontaneo durante la sessione. Il momento della misura è scelto dal sistema. Resta esposto al churn totale dell'app, ma non all'accoppiamento perverso "il consiglio funziona → il dato sparisce".
- Desktop companion — raddoppia il costo di sviluppo, da valutare dopo il pilota.

### 3.3 Inferenza su dati raccolti adattivamente

L'OLS, asintoticamente normale su dati campionati indipendentemente, **non è asintoticamente normale** su dati raccolti da un bandit quando non esiste un braccio ottimale unico (cioè sotto ipotesi nulla di effetto del trattamento): inflazione dell'errore di tipo I, copertura degli IC sotto il nominale (Zhang, Janson & Murphy 2020).

**Serve BOLS (Batched OLS)** — asintoticamente normale su dati da bandit multi-braccio e contestuali, e robusto alla non-stazionarietà della reward *di base*. Il che impone che la raccolta sia **batched by design** fin dall'inizio.

⚑ **Precisazione aggiunta in questa revisione**: l'asintotica di BOLS richiede che cresca **il numero di batch**, non il numero di osservazioni. Con aggiornamento settimanale su 6 settimane si hanno **6 batch** — pochi. Conseguenza da accettare esplicitamente: **il pilota è una fase di stima, non di conferma inferenziale definitiva**. Le sue stime alimentano il prior della fase successiva, non producono da sole un claim causale con copertura nominale garantita.

⚑ Seconda precisazione: BOLS è robusto al drift della **baseline** (l'intercetta), non necessariamente al drift dell'**effetto del trattamento**. Se l'efficacia di una finestra oraria cambia tra settimana normale e settimana d'esame, serve un modello che lasci variare β₁ e β₃, non solo β₀.

Altri accorgimenti: probability clipping; split subject-wise e forward-chaining temporale (mai k-fold casuale); pre-registrazione delle ipotesi primarie.

### 3.4 Il gate di ammissione della biometria

Prima di ammettere qualunque feature biometrica: **test di ablazione dei confondenti**. Il rischio concreto è che il clustering non supervisionato su segnali da polso recuperi postura, movimento, fase circadiana, effetti termici, caffeina e artefatti del sensore — "un pedometro con un orologio".

Baseline da battere: **ora del giorno + comportamento + baseline personale**, solo-telefono. Se la biometria non la batte, non entra. Questo test è anche il più economico e informativo dell'intero progetto, e va eseguito **come primo esperimento**, non come conferma finale.

⚑ Il gate ha ora una seconda giustificazione, **tecnica anziché statistica**: vedi §3.5 — con latenza fino a 30 minuti, la biometria non può essere un segnale *durante* la sessione su nessuna piattaforma.

### 3.5 Fattibilità di piattaforma — vincolo aggiunto in questa revisione

Verificato sulla documentazione ufficiale. **Invalida feature intere del concept precedente.**

| Capacità | iOS | Android |
|---|---|---|
| Leggere tempo per-app in foreground | ❌ solo report visuale sandboxed, non leggibile dal codice | ✅ `UsageStatsManager` |
| Esportare dati di utilizzo verso backend | ❌ **vietato per policy dichiarata** | ✅ nessun divieto analogo |
| Bloccare app di terzi | ✅ con entitlement discrezionale Apple, **mai su sé stessa** | ⚠️ via overlay/Accessibility, sotto scrutinio Play |
| HR/HRV/sonno via API nativa | ✅ HealthKit, **latenza fino a 30 min**; HRV quasi solo da esercizi dedicati | ✅ Health Connect, HRV dedicata, permessi extra |
| Task in background puntuali | ❌ ~30s, nessuna garanzia di orario | ✅ più margine, soggetto a Doze |

Dettagli decisivi:
- Su un thread ufficiale Apple Developer, un ingegnere del team Frameworks: *"It is not possible to export the data for [privacy and security] reason[s]"*. I dati granulari di `DeviceActivity` sono visualizzabili solo dentro le view fornite da Apple, mai leggibili dal codice. L'estensione `DeviceActivityMonitor` ha un **hard limit di 5 MB**, non può fare rete né notifiche.
- `com.apple.developer.family-controls` non è auto-concedibile: gate editoriale Apple, per **ogni target** dell'app.
- Su Android `PACKAGE_USAGE_STATS` non è richiedibile via dialog runtime: l'utente deve attivarlo manualmente in Impostazioni → friction di onboarding reale.

**Tre conseguenze non negoziabili:**
1. **§8.5 (digital phenotyping) è Android-only.** Su iOS non esiste un canale legittimo verso il bandit. Lo slider di fine sessione (§8.9) sale di priorità per **necessità tecnica**, non per costo di UX.
2. **§8.12 ("modo aereo intelligente") è friction, non muro**, e mai su sé stessa. Va venduto con aspettative tarate.
3. **I decision point pre-sessione richiedono notifiche locali pre-schedulate** al momento della dichiarazione d'intenzione, non polling in background. È un vincolo di design, non di implementazione.

**Regola di pianificazione**: dichiarare esplicitamente la roadmap **"Android-first, iOS-degradato"**. Qualunque piano che tratti uso-app o blocco-app come feature simmetrica cross-platform è scorretto.

---

## 4. Il reframe che scioglie il problema delle etichette

**Non predire la concentrazione. Apprendere una policy di scheduling** via contextual bandit su reward comportamentali e di apprendimento.

La fisiologia entra come **contesto S_t**, non come target di predizione. Da cui: *non devi più difendere l'affermazione che la tua feature misura qualcosa — devi solo mostrare che migliora la decisione.*

Corollario sul "unsupervised risolve il problema delle etichette": **falso**. L'unsupervised sposta le etichette dal training alla validazione. Il regime corretto è **self-supervised / weakly-supervised + insieme sparso di ancore validate**.

### Anatomia del sistema

- **Decision points**: fino a 3/giorno — (a) *pre-sessione* sul momento pianificato ma non ancora onorato (il più prezioso, §8.2), (b) *inizio sessione* dichiarata (durata suggerita, modalità), (c) *fine sessione*, opzionale (prompt di richiamo immediato sì/no)
- **Availability ρ_t**: modellata esplicitamente, **non** trattata come missingness neutra (§4.4)
- **Context S_t**: ora del giorno in **encoding circolare** (sin/cos), giorno della settimana, tipo di compito dichiarato, minuti dal risveglio stimato (µMCTQ), completion ratio storico su finestra mobile, difficoltà/stabilità media delle card in coda, flag periodo esami, biometria *solo se* ha superato il gate §3.4
- **Actions**: le euristiche validate come *arms* — retrieval-first vs restudy-first, intervallo di spacing suggerito, durata suggerita ∈ {3–4 livelli}, finestra oraria suggerita, interleaved vs blocked (solo se la categoria è nota), worked-example-first (solo se "nuovo materiale")
- **Proximal reward**: §5

### Le euristiche validate hanno tre ruoli simultanei

1. Gli **arms** del bandit
2. I **prior di warm-start**
3. Il **sanity check / policy floor** — se il sistema appreso fa peggio delle euristiche di popolazione, si torna a quelle

### 4.1 Algoritmo di riferimento

**Thompson sampling contestuale + action centering + pooling a effetti misti**, con BOLS come livello di inferenza separato.

**Action centering** (Boruvka et al. 2018) è il pezzo non opzionale. Stima l'effetto di escursione causale
`ξ(t) = E[Y(t+1)|A(t)=1, H(t)] − E[Y(t+1)|A(t)=0, H(t)]`
via **Weighted Centered Least Squares**:

```
Y(t+1) = β₀ + β₁·[A(t) − π(t)] + β₂ᵀS(t) + β₃ᵀ[A(t) − π(t)]·S(t) + ε(t)
w(t)   = 1 / [π(t)·(1 − π(t))]
```

Il termine **[A(t) − π(t)]** è il cuore: sottraendo la probabilità di randomizzazione *nota*, l'azione osservata viene ortogonalizzata rispetto alla storia che ha determinato quella probabilità. **È l'implementazione algoritmica del vincolo §3.1** — senza, l'endogeneità di selezione rientra *dentro* l'algoritmo di apprendimento invece che nell'analisi post-hoc. Richiede che π(t) sia nota e registrata ad ogni decisione: condizione che il sistema soddisfa per costruzione, essendo lui stesso a fissarla.

**IntelligentPooling** (Tomkins et al. 2021, −26% regret medio) risolve il problema opposto: con ~75 osservazioni per utente, un modello individuale è ad alta varianza e uno di popolazione è distorto. Struttura mista `w_i = w_pop + u_i`, dove **la forza del pooling (Σ_u) non è fissata a mano ma stimata online per massima verosimiglianza marginale**: utenti omogenei → il sistema poola forte; eterogenei → personalizza. Il grado di personalizzazione *emerge dai dati*.

**Alternativa**: RoME (NeurIPS 2024) è più potente su carta ma validato solo in simulazione e off-policy, non in un trial prospettico. Candidato di seconda fase, non di lancio.

Rollout in tre fasi: **MRT puro → bandit pooled → personalizzazione a effetti misti**.

### 4.2 Dal prior meta-analitico al prior bayesiano

Domanda pratica che la revisione precedente non affrontava. Meccanismo: **MAP prior** (meta-analytic-predictive), in quattro passi.

1. **Standardizzare l'unità.** Il d di letteratura è su un outcome diverso dal nostro. O si riscala sulla deviazione standard attesa del proximal outcome, o — più difendibile dato il gap di dominio — si usa l'effect size **solo come ordine di priorità relativo tra arms**, mai come valore assoluto.
2. **Attenuare.** Centrare su una frazione dichiarata (25–50%) del valore di laboratorio. La giustificazione empirica è già nel documento: Schwarz et al. si aspettavano 0.8 e hanno osservato 0.11.
3. **Shrinkage esplicito via τ.** Il prior deve avere varianza propria che riflette l'eterogeneità delle fonti, non essere un punto. TS è **sensibile ai prior mal calibrati**: se il prior assegna probabilità troppo bassa all'azione ottimale vera, la sotto-esplora sistematicamente.
4. **Prior predictive check** prima del deploy: simulare e verificare che le traiettorie generate siano fisicamente plausibili.

⚠️ I regret bound pubblicati per TS assumono prior diffusi — l'opposto di quel che facciamo. Nel regime "prior informativo + N piccolo" **le garanzie chiuse non si applicano**: il gap si colma con simulazione (recovery test), non citando i bound.

### 4.3 Safety: il policy floor, formalizzato

Corrispettivo formale nella letteratura sui **conservative bandits** / safe policy improvement. Meccanismo minimo implementabile senza machinery pesante — **vincolo stage-wise**:

```
Esegui l'azione del bandit SOLO SE  E[R|azione_bandit] ≥ E[R|azione_euristica] − ε
ALTRIMENTI esegui l'azione euristica
```

ε è un margine di tolleranza statistica, **non zero secco**, altrimenti si blocca l'esplorazione sul rumore campionario. Il confronto va tracciato come **metrica di dashboard continua**, non solo come gate one-off.

### 4.4 Availability, non-aderenza, IV

**Availability ρ_t** va trattata come processo potenzialmente influenzato dal trattamento passato. Se una raccomandazione ignorata riduce la probabilità che l'utente sia raggiungibile dopo, condizionare l'analisi sui soli decision point disponibili introduce un bias di selezione post-trattamento.

**Non-aderenza**: l'ITT stima l'effetto *dell'offerta*. Per stimare l'effetto del *comportamento* la randomizzazione della raccomandazione è uno strumento naturale (**encouragement design**, IV/CACE) — fattibile, con precedente in letteratura. ⚠️ Ma l'**exclusion restriction è discutibile**: la notifica può avere un effetto diretto e non solo tramite il comportamento indotto. **Da riportare come analisi secondaria, mai per guidare la policy.**

### 4.5 Dimensionamento del pilota — rivisto al ribasso

40–50 studenti × 6 settimane × 3 decision point/giorno × ~60% availability ≈ **3.000 decision point** (~75/utente).

⚑ **Confronto con la letteratura reale**: **HeartSteps I** — 44 adulti, 6 settimane, 5 decision point/giorno, quindi **più decision point lordi dei nostri** — atterra su **+14% step (+35 step), p = .06**. Un trial più grande del nostro produce un effetto marginale che *non* raggiunge la significatività convenzionale.

Conclusione operativa in tre righe:
- **Effetto prossimale medio**: 3.000 decision point bastano **solo per un effetto di dimensione ≥ quella di HeartSteps I**. Non per effetti più piccoli. *(Questo è nuovo rispetto alla revisione precedente.)*
- **Moderatori a pochi livelli**: adeguato **con pooling gerarchico** (3–4 fasce orarie lasciano ~19–25 decision point per utente per fascia).
- **Personalizzazione individuale piena**: **insufficiente**, come già scritto. Nessun trial con N comparabile riporta stime individuali stabili senza pooling.

⚑ **Da qui l'importanza strutturale del reward per-item** (§5.2): una sessione con 20 card produce 20 osservazioni invece di 1. Il moltiplicatore ×10–20 è l'unica leva realistica per compensare N piccolo. **La scelta della reward e il vincolo di potenza sono lo stesso problema.**

### 4.6 Test di sanità

- **Recovery test**: generare dati sintetici con effetti noti iniettati per costruzione, far girare l'intera pipeline (WCLS + pooling + BOLS) e verificare che li ricostruisca entro l'incertezza attesa. Se il sistema non recupera effetti noti su dati puliti, non c'è motivo di fidarsi delle sue stime su dati reali.
- **Test di plausibilità dei coefficienti**: segni e ordini di grandezza compatibili con §2.1. Un coefficiente negativo ad alta confidenza per retrieval practice è più probabilmente un bug o una violazione delle assunzioni WCLS che una scoperta contro-intuitiva.
- **Policy floor come metrica continua** (§4.3).
- **Rollback automatico** in produzione se recovery test o plausibility check falliscono.

---

## 5. Reward design — RISOLTO

> Era la questione aperta n.1, bloccante per l'algoritmo. Questa sezione la chiude.

### 5.1 Perché nessuna reward comportamentale pura funziona

Il candidato precedente — `durata_effettiva / durata_pianificata` — misura **aderenza al piano**, non **qualità dell'apprendimento avvenuto durante il piano**. La tassonomia di Manheim & Garrabrant (2018) sulle varianti della legge di Goodhart spiega perché i quattro degeneri già identificati non sono difetti separati ma manifestazioni di quattro meccanismi noti:

| Degenere | Meccanismo | Segnale osservabile che sta accadendo |
|---|---|---|
| Il bandit impara a *predire* invece che a *cambiare* | **Causal Goodhart** | L'effetto causale (WCLS) è ~0 mentre quello osservazionale naive è grande |
| Minuti assoluti → sessioni lunghe e improduttive | Regressional / Extremal | La durata suggerita cresce monotonicamente senza che il recall cresca in proporzione |
| Premiare il completamento → durate dichiarate brevi | **Adversarial** | La durata pianificata scende nel tempo, specialmente negli utenti con completion ratio storicamente basso |
| Premiare il numero di sessioni → frammentazione | Regressional | Durata media giù, frequenza su, tempo totale settimanale piatto |

Degeneri aggiuntivi identificati in questa revisione:
- **Gaming del tipo di compito dichiarato**: se "memorizzazione" riceve raccomandazioni più generose, l'utente è incentivato a dichiararlo sempre — corrompendo `S_t`, non solo la reward.
- **Gaming della disponibilità ρ_t**: ignorare le notifiche cambia la distribuzione delle raccomandazioni future.
- **Peak-end sullo slider di fine sessione**: motivo per cui resta **ancora di validazione**, mai componente di reward.
- **Habituation**: la reward attesa della stessa azione decade con l'esposizione, per ragioni non legate alla sua efficacia. Da trattare come ipotesi di lavoro dal disegno, non come sorpresa post-hoc.

**Test di ammissione per ogni componente**: *"un utente razionale che vuole solo un punteggio alto, senza voler studiare meglio, può alzarlo con un'azione a costo quasi zero?"* Il completion ratio fallisce parzialmente. Il recall a distanza lo supera **per costruzione**: il costo per gamarlo è studiare davvero abbastanza bene da ricordare — che è l'obiettivo stesso.

### 5.2 La reward raccomandata

```
                 ⎧ α·R_C(t) + (1−α)·R_A(t)     se items(t) ≠ ∅   (sessione con flashcard)
R(t) =           ⎨
                 ⎩ R_A(t)                       altrimenti        (fallback comportamentale)

R_C(t) = (1/|items(t)|) · Σᵢ p̂(recall | itemᵢ, Δ = 24h / 72h / 7gg)      ∈ [0,1]
R_A(t) = clip(durata_effettiva / durata_pianificata, 0, cap = 1.2)
α      ∈ [0.5, 0.8]   — iniziare a 0.5, salire a 0.7–0.8 dopo il recovery test
```

`p̂(recall)` viene dal modello di memoria (**FSRS** o half-life regression). Gli **orizzonti multipli** non sono un dettaglio: il recall a 7 giorni è molto più difficile da gamificare di quello a 24h, e la divergenza tra i due è essa stessa un allarme di Goodhart.

**Perché il recall e non un proxy comportamentale**: non perché "misuri meglio la concentrazione" (nessuna reward può, dato il tetto R² < 15%), ma perché il suo bersaglio è **causalmente a valle** della qualità della sessione in un modo che il completion ratio non è. Si può dichiarare una durata breve senza cambiare nulla; non si può "dichiarare" di ricordare domani una card non consolidata oggi.

Tre proprietà che ne discendono: **non manipolabile a basso sforzo**, **per-item** (×10–20 osservazioni, §4.5), **difendibile** ("misuriamo apprendimento, non obbedienza" — rilevante per l'inquadramento regolatorio).

### 5.3 I vincoli — hard, non pesati

Non scalarizzati dentro la reward: uno scalare unico nasconderebbe il trade-off ("quanti punti di apprendimento valgono una notifica in più?") dietro un peso arbitrario.

```
Vincolo 1 — policy floor (§4.3): gate stage-wise, fallback all'euristica
Vincolo 2 — budget notifiche: hard, implementato come MASCHERA sulle azioni disponibili,
            mai come termine di penalità nel reward
Vincolo 3 — anti-frammentazione: NON entra nella reward; è monitorata come metrica di sanità.
            Se sale mentre R(t) sale, è un segnale di gaming da investigare — non da correggere
            automaticamente via reward (introdurrebbe un nuovo canale di gaming)
```

Precedente pubblicato più vicino: **Oralytics** (AAAI 2023) usa `R = Q − C` con `Q = min(B − P, 180)`, dove la troncatura a 180 secondi esiste esplicitamente per non premiare l'over-brushing, e `C` è un costo di habituation esplicito.

### 5.4 Il layer LLM — ciò che rende possibile tutto questo *(nuovo)*

La revisione precedente lasciava §8.1 come "idea da valutare" perché richiedeva che l'utente inserisse materiale, attrito giudicato proibitivo. **Quell'ostacolo non esiste più**, e l'handoff precedente non nominava mai un LLM — era il punto cieco più costoso del documento.

- **Generazione di domande**: studio 2026 su corso reale, 14 domande LLM vs 21 umane, 42 studenti — difficoltà 0.82 vs 0.86 (n.s.), indice di discriminazione identico (0.13), **affidabilità α = 0.734 LLM vs 0.695 umano**. L'LLM non è inferiore.
- **Grading di risposte aperte**: accuratezza vicina all'umano in workflow supervisionati. Sblocca la forma di retrieval practice con l'effect size più alto — quella *con feedback* (0.73 vs 0.39) su risposta libera, finora impossibile senza un umano. È il motivo per cui quasi tutte le app di flashcard si fermano al richiamo binario "so / non so", che è la forma debole.

**Tre guardrail non negoziabili:**
1. **Revisione utente prima che una card entri nel deck attivo.** Costa un tap; preserva qualità e senso di controllo (rilevante anche contro l'algorithm aversion).
2. **Mai lo stesso modello come generatore e come giudice** — è documentato che è polarizzato verso le proprie generazioni.
3. **Bias ottimistico noto** nel grading (sovrastima le risposte parzialmente sbagliate). Accettabile per un'app di studio, non per un voto formale.

**Prior di warm-start**: trattare "flashcard con feedback LLM" come variante ad alta fedeltà di retrieval-practice-con-feedback → centrare su **g ≈ 0.73** (Rowland), **non** sul range 0.73–1.3 di Kestin 2025, che è studio singolo in dominio molto favorevole.

**Costo**: gli LLM introducono un costo variabile per sessione che scala con l'uso — l'opposto del bandit, a costo marginale ~zero. Va budgetizzato esplicitamente nel business model, non trattato come "gratis perché software".

**Da NON fare ora**: tutoring socratico conversazionale (superficie di rischio e costo sproporzionati rispetto al valore incrementale sopra il Q&A con feedback).

### 5.5 Piano anti-degenerazione

1. **Simulazione avversariale** prima del deploy: simulare un utente che massimizza R(t) minimizzando lo sforzo. Per la reward finale la strategia ottimale deve restare "studiare abbastanza da ricordare". Se emerge una scorciatoia (es. inserire card banalmente facili), correggere prima — normalizzando per la difficoltà storica della card, già feature nativa dei modelli DSR/FSRS.
2. **Monitoraggio delle metriche non ottimizzate**: durata dichiarata, frequenza sessioni, tempo totale settimanale, difficoltà media delle card. Se una si muove al rialzo con R(t) mentre il recall a 7 giorni resta piatto → allarme Goodhart.
3. **Confronto ITT vs braccio randomizzato puro**: se l'effetto della raccomandazione seguita non supera quello della randomizzazione pura, il sistema non sta producendo valore di personalizzazione. **Condizione esplicita di non-avanzamento** nella roadmap.

---

## 6. Rischi di prodotto identificati

| Rischio | Mitigazione decisa |
|---|---|
| Sovra-affermazione visiva (curva liscia su R² < 15%) | Fasce ordinate anziché punteggio continuo; incertezza esplicita; personalizzazione sbloccata dopo N sessioni |
| Auto-avveramento del grafico | Esplorazione permanente (§3.1.2) |
| Nocebo / impotenza appresa | Allocazione di compiti: ogni fascia riceve un'assegnazione, nessuna ora morta |
| Interruzione del flow da notifica di pausa | Intervento spostato a inizio sessione; niente interruzioni mid-session |
| Terminazioni prescritte | Opt-in o riformulate come prompt riflessivo — nessuna base evidenziale |
| Gating sul wearable taglia l'80–90% del mercato | Biometria = potenziamento opzionale; nucleo solo-telefono |
| Churn prima di avere dati | Prodotto = strumento di sessione (valore immediato); analytics = bonus; dati come sottoprodotto |
| Claim di performance su capacità nominata | Inquadramento general-wellness; il framing "misuriamo apprendimento, non capacità cognitiva" (§5.2) è più difendibile |
| ⚑ **Experiment aversion** | Vedi §6.1 — riformulare il copy **prima** che diventi materiale di marketing |
| ⚑ **Randomizzazione contro abitudine** | Vedi §6.2 — trade-off reale, mitigabile ma non risolvibile |
| ⚑ **Retention reale peggiore dell'atteso** | Mediana **3,3% a 30 giorni** per app mHealth reali (Baumel 2019); >2/3 degli utenti usano un'app di salute **una volta sola**. Il pilota controllato **non misurerà mai** questo: serve un soft-launch pubblico separato |
| ⚑ **Planning fallacy sul denominatore del reward** | La durata dichiarata è sistematicamente sottostimata. Trasformarlo in **feature visibile** (mostrare lo scarto storico previsto/reale e *proporre* una correzione) invece che in correzione statistica nascosta |
| ⚑ **Asimmetria di piattaforma** | §3.5 — pianificare Android-first, non promettere parità |

**Cold start risolto**: MCTQ / µMCTQ danno una curva cronotipica personalizzata al giorno 1, dichiarata come tale, senza un singolo dato comportamentale.

### 6.1 Experiment aversion — come presentare la randomizzazione

Meyer et al. 2019 (*PNAS*, **16 studi, 5.873 partecipanti, 9 domini**): le persone giudicano un A/B test **meno appropriato di entrambe le sue braccia prese singolarmente**, anche quando approverebbero l'adozione universale e non testata di ciascuna. Un lavoro 2024 conferma che il fenomeno **generalizza**, ma è **sensibile alla presentazione**.

La §8.3 così com'era scritta — *"l'app fa un esperimento su di te"* — innesca esattamente questo meccanismo. La mitigazione non è nascondere la randomizzazione, è **separare due cose oggi confuse**:

- **Randomizzazione silenziosa** (10–15%, per l'inferenza del bandit): non etichettata come esperimento. È normale variazione del consiglio.
- **Esperimento dichiarato e opt-in** per l'utente curioso: *"tu scegli una domanda, l'app ti aiuta a trovare la risposta confrontando alternative"*. Agency all'utente, opzioni presentate come entrambe ragionevoli e già in uso, uscita sempre possibile.

Condividono l'infrastruttura statistica sotto il cofano ma vanno tenute **concettualmente separate nel prodotto**. Confonderle converte un vincolo metodologico invisibile in un rischio di percezione visibile e del tutto evitabile.

### 6.2 Randomizzare contro formare l'abitudine

Lally et al. 2010 (96 volontari, 12 settimane): mediana **66 giorni** per il 95% dell'automaticità, range **18–254**. Il meccanismo dell'abitudine è la ripetizione dello stesso comportamento **nello stesso contesto** — cue consistency. La randomizzazione della finestra oraria è, per definizione, instabilità del contesto. **Non è un attrito collaterale: è un'azione diretta contro il meccanismo che si vuole costruire.**

Il margine reale sta in un dettaglio della stessa fonte: **saltare un singolo giorno non rompe la curva**. Un 10–15% su cadenza quotidiana significa circa **un'occorrenza fuori pattern ogni 7–10 giorni** — dell'ordine dei lapsi innocui, non della disruption cronica. Il rischio non è quindi il tasso, è **come viene distribuito**: la stessa frazione spalmata uniformemente danneggia l'automaticità più di quanto faccia concentrata in eventi isolati.

Due leve operative:
1. **Ancora fissa + finestra randomizzata attorno**: se l'utente ha stabilizzato un pattern (es. le 18), esplorare *attorno* a quell'ancora (17:30–18:30) più spesso dell'intera giornata. Mantiene il cue grossolanamente stabile e raccoglie varianza per l'identificazione a grana fine.
2. **Intensità di esplorazione variabile nel tempo**: 5% nelle prime 2–3 settimane sulla fascia che l'utente sta stabilizzando, poi risalita. **Non è la fase osservazionale passiva vietata da §3.1**: resta randomizzazione attiva, solo a intensità variabile, dichiarata e pre-registrata.

**Ciò che va detto senza diplomazia**: il conflitto non ha una soluzione che preservi entrambi gli obiettivi al 100%. **Il prezzo dell'inferenza causale si paga in automaticità comportamentale.** Va comunicato internamente come trade-off esplicito, non nascosto dietro "10–15% è una percentuale piccola".

---

## 7. Questioni aperte

### Chiuse in questa revisione

1. ~~**Specifica del reward**~~ → **§5.2**. Reward composita `α·R_C + (1−α)·R_A` con tre vincoli hard.
3. ~~**Asimmetria timing/contenuto**~~ → **§2.5**. Baricentro spostato su iniziazione + apprendimento; timing retrocesso a segnale di contesto.
6. ~~**Enumerazione degli arms e dei prior**~~ → tabella completa in `research/R1_cosa_raccomandare.md` §5.
7. ~~**Breakdown Donoghue & Hattie**~~ → **§2.1**. Distributed practice d = 0.85; practice testing d = 0.74.

### Ancora aperte

2. **Schema di randomizzazione**: parzialmente specificato (π ∈ [0.10, 0.85], batch settimanali, ancoraggio contestuale §6.2), ma **la distribuzione temporale dell'esplorazione** va progettata e pre-registrata.
4. **Layer di ancoraggio in-app** (PVT-B / thought probes): da adottare o no? Il mind-wandering detection su smartphone è fuori scope (§2.2), ma un thought-probe sporadico resta un'opzione di *validazione*.
5. **Desktop companion**: dopo il pilota. Confermato come "non nei prossimi 3 mesi".
8. ⚑ **Consenso etico e GDPR**: dati Art. 9 + potenziali minorenni. Il tempo di approvazione **non è comprimibile** con la roadmap prodotto — va avviato ora, non a ridosso del pilota.
9. ⚑ **Modello di business**: chi paga il pilota. Rilevante per il design dei dati (l'università come cliente apre a dati d'esame e comitati etici). Da esplicitare **prima** del reclutamento, perché il reclutamento testa di fatto un modello.
10. ⚑ **Costo variabile LLM** per sessione: da budgetizzare (§5.4).
11. ⚑ **Lacune di letteratura non colmate nel budget di ricerca**: durata ottimale della pausa, nap, ART/natura, consolidamento sleep-dependent, wakeful rest, nutrizione, RCT su app blocker, effect size del mismatch cronotipo-orario, meta-analisi sulla calibrazione metacognitiva. Nessuna contraddizione emersa, ma nessuna verifica: vedi §7 di `R1_cosa_raccomandare.md`.

---

## 8. Idee da esplorare

> Stato aggiornato: alcune di queste non sono più "da esplorare".

### 8.1 ✅ PROMOSSA A NUCLEO — Spaced repetition come strumento di misura

**Non è più un'idea: è il perno del sistema.** Tre report indipendenti vi convergono — è l'euristica più forte (§2.1, d = 0.85), l'unica reward non manipolabile (§5.2), e l'attrito che la bloccava è caduto (§5.4). Vedi §1, §5.2, §5.4.

Nota implementativa: integrare **FSRS pre-addestrato su FSRS-Anki-20k** invece di stimare un modello di memoria da zero sui dati del pilota — settimane di sviluppo risparmiate e un prior enorme e gratuito.

### 8.2 ✅ PROMOSSA — Il decision point più prezioso è *prima* che la sessione inizi

Confermata e promossa a guscio esterno del prodotto (§2.5). Il fallimento più comune non è la sessione mediocre: è **la sessione che non comincia mai**, e lì l'implementation intention ha la sua evidenza migliore (d = 0.65 è misurato proprio sull'*iniziazione* del goal striving). Aprire un decision point sul momento pianificato ma non ancora onorato (a) attacca il problema più grande, (b) rompe la selezione di §3.1, (c) sfrutta l'evidenza più forte.

⚠️ Vincolo tecnico da §3.5: va implementato con **notifiche locali pre-schedulate al momento della dichiarazione**, non con polling in background.

### 8.3 ⚠️ RIFORMULATA — Vendere la randomizzazione

L'idea resta valida ma **il copy va riscritto prima di diventare materiale di marketing**: mai il framing "sperimentiamo su di te" (§6.1). Separare randomizzazione silenziosa ed esperimento dichiarato opt-in.

### 8.4 Gli esami come outcome distale naturale

Gli studenti hanno esiti reali, oggettivi e datati. Outcome distale **gratuito** e non auto-riportato — raro in mHealth. Utilizzabile per la validazione finale (il proximal reward predice l'esito distale?). Nel framework JITAI questo è il *distal outcome*, e il recall a distanza ha con esso una **teoria di mediazione diretta** (retrieval practice → consolidamento → performance) che il completion ratio non ha.

### 8.5 ⚠️ RIDIMENSIONATA — Digital phenotyping passivo

**Android-only** (§3.5): su iOS l'export dei dati d'uso è vietato per policy. Resta **feature del contesto S_t**, mai reward (§2.2). Conseguenza: lo slider di fine sessione (§8.9) sale di priorità per necessità tecnica.

### 8.6 ✅ RAFFORZATA — Il carico accademico come moderatore dominante

Ora giustificata due volte: come moderatore (settimana d'esame vs normale) **e** come input necessario al calcolo dell'intervallo di spacing ottimale, che dipende dall'orizzonte di ritenzione (§2.1, Cepeda). Cattura a costo bassissimo: calendario esami dichiarato una volta.

### 8.7 Telemetria del compito da desktop companion

Resta il segnale probabilmente più informativo in assoluto e il più costoso da costruire. **Esplicitamente fuori dai prossimi 3 mesi.**

### 8.8 Peer benchmark come cold start alternativo

Invariata. Nota: IntelligentPooling (§4.1) fa già una forma di questo automaticamente, stimando la forza del pooling dai dati.

### 8.9 ⬆️ PRIORITÀ ALZATA — Slider retrospettivo di fine sessione

Sale di priorità perché su iOS è **l'unica via** al segnale che il digital phenotyping non può dare (§3.5). Resta un'**ancora di validazione, mai una componente di reward** — bias peak-end documentato (§5.1).

### 8.10 Detection della fine naturale vs terminazione prescritta

Invariata. Zero claim causali, zero intrusività, migliora la qualità delle etichette.

### 8.11 Foundation model da wearable, solo in seconda battuta

Invariata. Da riconsiderare dopo il pilota, non prima.

### 8.12 ⚠️ RIDIMENSIONATA — "Modo aereo intelligente"

Resta un arm legittimo, ma: **mai su sé stessa** (impossibile per design su iOS), soggetto a entitlement discrezionale Apple, fragile su Android (overlay/Accessibility sotto scrutinio Play). Va venduto come **friction, non come muro invalicabile**. ⚑ E **non può più essere giustificato con il brain drain** (§2.3, non replica): solo con la correlazione uso-rendimento e con l'assenza-telefono come segnale di deep work.

### 8.13 ✅ ADOTTATA — Reward vincolato invece che scalare

Adottata in §5.3. I vincoli sono hard (maschera sulle azioni) o gate stage-wise, non termini pesati.

### 8.14 ⚑ NUOVA — Calibrazione metacognitiva come sottoprodotto

Se il richiamo chiede la **confidenza prima della risposta**, si ottiene la correzione dell'overconfidence senza disegnare un intervento separato. Gli studenti (specialmente i più deboli) sovrastimano sistematicamente quanto ricorderanno, e **fallire un tentativo di richiamo riduce l'overconfidence più del rileggere**. ⚠️ Nessun effect size aggregato citabile recuperato: meccanismo di supporto, non arm indipendente.

### 8.15 ⚑ NUOVA — Dataset pubblici in dominio

Un dataset di sessioni di studio reali varrebbe mesi di pilota. Da cercare seriamente prima di raccogliere dati: deck Anki pubblici, dataset MOOC/learning analytics, StudentLife.

---

## 9. Anti-pattern da non ripetere

- ❌ Dataset generici (WESAD, SMILE, TILES-2018/19, SWELL-KW) — **fuori dominio**
- ❌ Modelli fondazionali generici da wearable (LSM-2, WBM, SensorFM) — stessa obiezione (ma cfr. §8.11)
- ❌ Predittore di umore per il giorno successivo — inutile per il prodotto
- ❌ Unsupervised come soluzione al problema delle etichette (§4)
- ❌ k-fold casuale al posto di split subject-wise / forward-chaining
- ❌ Transfer di dominio da modelli di vigilanza sotto privazione di sonno
- ❌ Fase osservazionale "passiva" (§3.1)
- ❌ OLS ordinario su dati da bandit (§3.3)
- ⚑ ❌ **Citare il brain drain (Ward 2017) come base causale** — non replica (§2.3)
- ⚑ ❌ **Costruire claim su CO2, musica di sottofondo o caffeina-come-enhancer** — evidenza contraddetta o nulla (§2.3)
- ⚑ ❌ **Usare lo stesso LLM come generatore e come giudice** del materiale (§5.4)
- ⚑ ❌ **Trattare uso-app o blocco-app come feature simmetrica cross-platform** (§3.5)
- ⚑ ❌ **Presentare la randomizzazione come "un esperimento su di te"** (§6.1)
- ⚑ ❌ **Aggiornare il bandit ad ogni osservazione** invece che a batch fissi (§3.3)
- ⚑ ❌ **Usare la stima IV/CACE per guidare la policy** — analisi secondaria soltanto (§4.4)

---

## 10. Fonti primarie

### 10.1 Scienze dell'apprendimento — le euristiche come arms

- Rowland, C. A. (2014). *The effect of testing versus restudy on retention*. **Psychological Bulletin** 140(6), 1432–1463. — [PubMed](https://pubmed.ncbi.nlm.nih.gov/25150680/)
- Adesope, O. O., Trevisan, D. A., & Sundararajan, N. (2017). *Rethinking the use of tests: A meta-analysis of practice testing*. **Review of Educational Research** 87(3), 659–701. — [SAGE](https://journals.sagepub.com/doi/10.3102/0034654316689306) — *g = 0.61; classe 0.67 vs lab 0.62*
- Donoghue, G. M., & Hattie, J. A. C. (2021). *A meta-analysis of ten learning techniques*. **Frontiers in Education** 6, 581216. — [full text](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2021.581216/full) — *fonte della Tabella 1 in §2.1*
- Cepeda, N. J., et al. (2006). *Distributed practice in verbal recall tasks*. **Psychological Bulletin**. — 839 confronti / 317 esperimenti
- Cepeda, N. J., et al. (2008). *Spacing effects in learning: A temporal ridgeline of optimal retention*. **Psychological Science** 19(11), 1095–1102. — *il gap ottimale come proporzione dell'orizzonte di ritenzione*
- Gollwitzer, P. M., & Sheeran, P. (2006). *Implementation intentions and goal achievement*. **Adv Exp Soc Psychol** 38, 69–119. — [KOPS](https://kops.uni-konstanz.de/handle/123456789/10973)
- Brunmair, M., & Richter, T. (2019). *Similarity matters: A meta-analysis of interleaved learning*. — *g = 0.42, 59 studi*
- Dunlosky, J., et al. (2013). *Improving students' learning with effective learning techniques*. **PSPI** 14(1), 4–58. — *quantificato da Donoghue & Hattie 2021*
- Wisniewski, B., Zierer, K., & Hattie, J. (2020). *The Power of Feedback Revisited*. **Frontiers in Psychology** 10, 3087. — [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6987456/)
- Settles, B., & Meeder, B. (2016). *A Trainable Spaced Repetition Model for Language Learning*. **ACL**. — [GitHub](https://github.com/duolingo/halflife-regression) — *half-life regression; −45% errore, +12% engagement (numeri degli autori)*
- **FSRS** — Free Spaced Repetition Scheduler, modello DSR; benchmark pubblici `open-spaced-repetition/srs-benchmark`; modello pre-addestrato **FSRS-Anki-20k**

### 10.2 LLM per l'apprendimento *(nuova)*

- *LLM-generated vs human-written MCQ* (2026). **Frontiers in Education**, 10.3389/feduc.2026.1837523. — [full text](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2026.1837523/full) — *difficoltà 0.82 vs 0.86 n.s.; α = 0.734 vs 0.695*
- Kestin, G., et al. (2025). *AI tutoring outperforms in-class active learning*. **Scientific Reports**. — [Nature](https://www.nature.com/articles/s41598-025-97652-6) — *d = 0.73–1.3, RCT Harvard, ~194 studenti; studio singolo, dominio favorevole*
- VanLehn, K. (2011). *The relative effectiveness of human tutoring, ITS, and other tutoring systems*. **Educational Psychologist** 46(4). — *umano d = 0.79; ITS step-based d = 0.76; substep d = 0.40*

### 10.3 Pause, fatica, timing

- Albulescu, P., et al. (2022). *"Give me a break!"*. **PLOS ONE** 17(8), e0272460. — [PLOS](https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0272460)
- Wieth, M. B., & Zacks, R. T. (2011). *Time of day effects on problem solving: When the non-optimal is optimal*. **Thinking & Reasoning** 17(4). — *asynchrony effect sul problem solving creativo*
- Chang, Y. K., et al. (2012). *The effects of acute exercise on cognitive performance: A meta-analysis*. **Brain Research**. — *minimo 11 min; benefici solidi >20 min; finestra ottimale ~15 min dopo*
- Drake, C., et al. (2013). *Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed*. **JCSM**. — *−1,2h di sonno indipendentemente dal timing entro 0–6h*

### 10.4 Sonno → cognizione del giorno dopo

- Schwarz, J., et al. (2026). *Daily fluctuations in sleep duration and quality affect next-day processing speed*. **SLEEP** 49(1), zsaf321. — [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12795734/)
- Okano, K., et al. (2019). *Sleep quality, duration, and consistency are associated with better academic performance*. **npj Science of Learning** 4, 16. — [Nature](https://www.nature.com/articles/s41539-019-0055-z) — *100 studenti MIT; la **consistenza** predice più della durata*
- Windred, D. P., et al. (2024). **SLEEP** 47(1), zsad253. — ⚠️ **Riguarda la mortalità, non la cognizione.**

### 10.5 Miti smontati *(nuova)*

- Ruiz Pardo, D., & Minda, J. P. (2022). *Reexamining the "brain drain" effect: A replication of Ward et al. (2017)*. **Acta Psychologica**. — [PubMed](https://pubmed.ncbi.nlm.nih.gov/36007374/) — **la replica fallisce**
- Meta-analisi uso smartphone/rendimento (63 studi, N = 124.166): **r = −0.16** [−0.20, −0.13]
- Allen, J. G., et al. (2016) su CO2 — contraddetto da studio danese (*Building & Environment* 2016) e da studio su sottomarinisti USA (nessun declino a 2.500–15.000 ppm)
- Kämpfe, J., Sedlmeier, P., & Renkewitz, F. (2011). *The impact of background music on adult listeners*. **Psychology of Music**. — *effetto medio nullo*

### 10.6 Rilevazione di stress/ansia da wearable — limiti di generalizzazione

- *Cross Dataset Analysis for Generalizability of HRV-Based Stress Detection Models* (2023). **Sensors** 23(4), 1807. — *F1 ≈ 61%*
- *Are Anxiety Detection Models Generalizable?* (2025). arXiv:2504.03695. — *AUROC 0.59–0.62*

### 10.7 Metodologia causale e adattiva

- Zhang, K. W., Janson, L., & Murphy, S. A. (2020). *Inference for Batched Bandits*. **NeurIPS** 33, 9818–9829. — [arXiv](https://arxiv.org/abs/2002.03217) — *BOLS*
- Boruvka, A., Almirall, D., Witkiewitz, K., & Murphy, S. A. (2018). *Assessing time-varying causal effect moderation in mobile health*. **JASA** 113(523), 1112–1121. — [PDF](https://archive.md2k.org/images/papers/jitai/boruvka033117.pdf) — *action centering, WCLS*
- Tomkins, S., Liao, P., Klasnja, P., & Murphy, S. A. (2021). *IntelligentPooling*. **Machine Learning** 110(9), 2685–2727. — [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8494236/) — *−26% regret*
- Liao, P., et al. (2016). *Sample size calculations for micro-randomized trials in mHealth*. arXiv:1609.00695. — pacchetti `MRTSampleSize` / `MRTSampleSizeBinary`
- Huch, et al. (2024). *RoME: Robust Mixed-Effects bandit*. **NeurIPS**, arXiv:2312.06403. — candidato di seconda fase
- Manheim, D., & Garrabrant, S. (2018). *Categorizing Variants of Goodhart's Law*. arXiv. — *la tassonomia di §5.1*
- *Reward Design For An Online RL Algorithm Supporting Oral Self-Care* (2023). **AAAI**, arXiv:2208.07406. — *Oralytics; precedente di reward con termine di costo esplicito*
- *Data Missing Not at Random in Mobile Health Research* (2021). **JMIR**, PMC8277392. — *§3.2*

### 10.8 Comportamento, aderenza, etica *(nuova)*

- Meyer, M. N., et al. (2019). *Objecting to experiments that compare two unobjectionable policies or treatments*. **PNAS** 116(22). — *16 studi, 5.873 partecipanti*
- *Experiment aversion does generalize, but it can also be mitigated* (2024). **PNAS**.
- Lally, P., et al. (2010). *How are habits formed?* **European Journal of Social Psychology** 40(6), 998–1009. — *mediana 66 giorni, range 18–254; saltare un giorno non rompe la curva*
- Baumel, A., et al. (2019). **JMIR** — *retention reale mHealth: mediana 3,3% a 30 giorni*
- Dietvorst, B. J., et al. (2015, 2018) — *algorithm aversion; dare anche un minimo controllo correttivo aumenta molto l'adesione*

### 10.9 Fattibilità di piattaforma *(nuova)*

- [Apple Developer Forums, thread 756619](https://developer.apple.com/forums/thread/756619) — citazione dell'ingegnere Apple sull'impossibilità di esportare i dati `DeviceActivity`
- [Android `UsageStatsManager`](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- [Android Health Connect — data types](https://developer.android.com/health-and-fitness/health-connect/data-types)

### 10.10 Strumenti (identificativi, non ri-verificati)

- **MCTQ**: Roenneberg, Wirz-Justice & Merrow (2003), *J Biol Rhythms* 18(1), 80–90
- **µMCTQ**: Ghotbi, N., et al. (2020), *J Biol Rhythms* 35(1), 98–110
- **PVT-B**: Basner, M., et al. (2011)
- **KSS**: Åkerstedt & Gillberg (1990)
- **Sleep Regularity Index**: Phillips, A. J. K., et al. (2017), *Scientific Reports*
- **SAFTE / Three-Process Model**: Hursh et al. (2004); Åkerstedt & Folkard — ⚠️ fuori dominio, cfr. §2.3

### 10.11 Documenti di origine

- `research/R1_cosa_raccomandare.md` — euristiche di contenuto, struttura, timing, contesto
- `research/R2_algoritmo_e_reward.md` — reward design e architettura di apprendimento
- `research/R3_punti_ciechi_e_aderenza.md` — red team, fattibilità, aderenza, opportunità
- `compass_artifact_wf-73072009-...md` — review strategica iniziale; conclusioni in gran parte confermate, eccezioni in §2.3

---

## 11. Le prossime azioni

Ordinate per rapporto valore/costo, non per urgenza cronologica.

1. **Test di ablazione della biometria (§3.4) come primo esperimento del progetto**, non come conferma finale. Previene mesi di ingegneria su feature che potrebbero non superare mai "ora del giorno + comportamento".
2. **Prototipare il guscio "iniziazione"** (§2.5, §8.2): prompt if-then + planning alla dichiarazione di sessione, senza aspettare il bandit completo. Riusa pezzi già esistenti e attacca l'effetto più grande e meno contestabile.
3. **Pipeline LLM flashcard-generation + grading** (§5.4): import materiale → generazione → revisione utente → deck attivo → grading con soglia di confidenza. Sblocca §5.2.
4. **Avviare legale/DPO e comitato etico ORA** (§7.8). Non comprimibile.
5. **Dichiarare la roadmap "Android-first, iOS-degradato"** (§3.5).
6. **Integrare FSRS pre-addestrato (FSRS-Anki-20k)** invece di stimare da zero (§8.1).
7. **Riscrivere il copy della randomizzazione** prima che diventi marketing fissato (§6.1).
8. **Calibrazione della planning fallacy come feature visibile** (§6).
9. **Progettare l'ancoraggio contestuale della randomizzazione** (§6.2).
10. **Misurare la retention in un soft-launch pubblico separato dal pilota**, con aspettative su Baumel 2019 (§6).

**Da NON fare nei prossimi 3 mesi**: desktop companion (§8.7); tutoring socratico conversazionale (§5.4); canali di segnale marginali (meteo, localizzazione) prima di aver validato calendario e — su Android — entropia d'uso app; finalizzare un business model senza aver reso esplicito quale modello il reclutamento del pilota sta di fatto testando (§7.9).

---

> **Nota architetturale**: il pattern *prior meccanicistico + identificazione parametri per-utente + residuo data-driven* è lo stesso già usato nel repo DIANA per il glucosio (white-box / ReplayBG). Riferimento utile per il design del modello personalizzato.
