# Ricerca FocusMaxxer — stato e brief per la ripresa

> **Stato al 2026-08-06**: sei agenti di ricerca lanciati in parallelo il 2026-08-05 (~23:24–23:29).
> **Tutti e sei terminati per limite di sessione API prima di produrre output.** Nessun report scritto,
> transcript a 0 byte: il progresso di ricerca è perduto e va rifatto da zero.
> Questo file contiene i brief integrali, pronti da rilanciare.

## Come riprendere

In una sessione nuova, rilanciare i sei agenti in parallelo (Agent tool, `general-purpose`), uno per
report, passando come prompt: **Contesto comune** + **brief specifico** + **Requisiti di qualità**.
Il documento sorgente da allegare è `FOCUSMAXXER_HANDOFF.md` nella root del repo.

Se i crediti sono limitati, l'ordine di priorità è: **R3 → R4 → R6 → R1 → R2 → R5**.
Motivo: R3 (reward design) è dichiarato dal handoff stesso come questione aperta n.1 *bloccante*
per l'algoritmo; R4 dipende da R3; R6 può invalidare feature intere per infattibilità tecnica.

| # | File di output | Argomento | Macro-domanda |
|---|---|---|---|
| R1 | `research/R1_contenuti_euristiche_apprendimento.md` | Euristiche di contenuto | 1 — cosa raccomandare |
| R2 | `research/R2_struttura_sessione_timing_contesto.md` | Timing, pause, ambiente | 1 — cosa raccomandare |
| R3 | `research/R3_outcome_reward_design.md` | Metrica di outcome + reward | 2 — algoritmo |
| R4 | `research/R4_algoritmo_bandit_personalizzazione.md` | Bandit, MRT, inferenza | 2 — algoritmo |
| R5 | `research/R5_aderenza_motivazione_engagement.md` | Aderenza e retention | 3 — punti ciechi |
| R6 | `research/R6_punti_ciechi_opportunita.md` | Red team, opportunità | 3 — punti ciechi |

---

## Contesto comune (da premettere a ogni brief)

FocusMaxxer è un'app mobile (Flutter, Android+iOS) per sessioni di studio/deep work, target studenti.

**Concept corrente.** L'utente DICHIARA con un tap l'inizio di una sessione quando vuole, indicando
tipo di compito (nuovo materiale / esercizi / ripasso / memorizzazione) e durata prevista; **può
liberamente ignorare le raccomandazioni**. L'app struttura la sessione secondo euristiche con
supporto meta-analitico solido, mostra un'allocazione oraria che assegna a *ogni* fascia un tipo di
lavoro adatto (mai zone morte, per evitare il nocebo), ed emette raccomandazioni di finestra e
modalità **parzialmente randomizzate fin dall'inizio e per sempre** (~10–15%). Un contextual bandit
(Thompson sampling + action centering + pooling a effetti misti) impara dalla reward comportamentale.
Biometria da wearable **opzionale**, degradata a sensore di *validità della sessione*, non di stato
cognitivo. R² realistico della personalizzazione: **<10–15%**.

**Evidenza già in mano (da verificare, non da ripetere passivamente).**
- Retrieval practice: g=0.50 complessivo; 0.73 con feedback vs 0.39 senza (Rowland 2014, *Psych Bull* 140(6):1432–1463).
- Implementation intentions: d=0.65, 94 test, >8.000 partecipanti (Gollwitzer & Sheeran 2006).
- Spacing: tra le 2 tecniche più efficaci su 10 (Donoghue & Hattie 2021, *Front Educ* 6:581216); media del pool 0.56 su 242 studi. **Valore puntuale per il solo distributed practice NON confermato.**
- Stress da wearable cross-dataset: F1≈61% (*Sensors* 23(4):1807). Ansia cross-activity: AUROC 0.59–0.62 (arXiv:2504.03695).
- Sonno→cognizione giorno dopo, within-person: +0.11 risposte corrette per ora (95% CI 0.06–0.15); between-person **nullo**; gli autori attendevano 0.8 → ~8× più piccolo (Schwarz et al. 2026, *SLEEP* 49(1):zsaf321).
- Microbreak: riduce fatica/aumenta vigore, effetto su **performance ≈ nullo** per compiti impegnativi (Albulescu et al. 2022, *PLOS ONE* 17(8):e0272460).
- Pomodoro 25/5 non superiore a pause auto-regolate; ritmo ultradiano 90 min senza supporto.
- Windred et al. 2024 riguarda la **mortalità**, non la cognizione: citarlo per la readiness è transfer di dominio invalido.
- SAFTE-FAST / UMP / Three-Process Model: validati per vigilanza sotto privazione di sonno, **non** per attenzione intra-task in soggetti riposati.

**Vincoli metodologici non negoziabili.**
1. **Endogeneità della selezione** (dominante): l'utente studia quando ha *già* le condizioni giuste.
   Ogni stima "le tue ore migliori" da dati osservazionali è circolare, inutile e *convincente*.
   Non puoi randomizzare *quando* studia; puoi randomizzare **la raccomandazione**.
2. **Esplorazione permanente, non una fase**: appena prescrivi contamini i dati osservazionali; senza
   frazione randomizzata permanente il sistema si fossilizza sul primo errore e lo auto-conferma.
3. **Intention-to-treat**: l'unità di analisi è la raccomandazione *emessa*, non quella *seguita*.
   La non-aderenza non è casuale (si segue soprattutto quando si sarebbe agito così comunque).
4. **Inferenza su dati adattivi**: l'OLS non è asintoticamente normale su dati da bandit sotto H0
   (Zhang, Janson & Murphy 2020, NeurIPS 33:9818–9829) → serve **BOLS**, quindi raccolta **batched by
   design** fin dall'inizio. Più: probability clipping, split subject-wise, forward-chaining
   temporale (mai k-fold casuale), pre-registrazione delle ipotesi primarie.
5. **Paradosso di misura**: il segnale più forte di deep work è l'**assenza del telefono**,
   indistinguibile dall'**abbandono dell'app** — e "allontana il telefono" è proprio il consiglio da
   dare. La strumentazione muore quando il consiglio funziona.
6. **Gate della biometria**: test di ablazione dei confondenti prima di ammettere qualunque feature.
   Baseline da battere: ora del giorno + comportamento + baseline personale, solo-telefono.
7. **Reframe centrale**: non predire la concentrazione, ma **apprendere una policy di scheduling**.
   La fisiologia entra come *contesto S_t*, non come target → non devi difendere che la feature misuri
   qualcosa, solo che migliori la decisione.
8. Le euristiche validate hanno **tre ruoli**: arms del bandit, prior di warm-start, policy floor.
9. **Pilota**: 40–50 studenti × 6 settimane × 3 decision point/giorno × ~60% availability ≈ 3.000
   decision point (~75/utente). Insufficiente per personalizzazione piena → pooling a effetti misti.

**Anti-pattern imposti.** Niente dataset generici fuori dominio (WESAD, SMILE, TILES, SWELL); niente
foundation model generici da wearable; niente predittore d'umore; unsupervised non risolve il problema
delle etichette; mai k-fold casuale; mai transfer da vigilanza sotto privazione di sonno; mai fase
osservazionale passiva; mai OLS su dati da bandit.

---

## Requisiti di qualità (identici per tutti i report)

- **Caricare prima gli strumenti web**: `ToolSearch` con query `select:WebSearch,WebFetch`.
  Poi ricerca reale: **30–45 ricerche distinte minimo**, con apertura dei full text chiave.
  **Non scrivere a memoria**: ogni numero da una fonte effettivamente recuperata.
- **Numeri, non aggettivi**: effect size (d/g/r), CI, N studi, N partecipanti, rivista e anno.
- **Distinguere**: meta-analisi vs studio singolo; laboratorio vs campo; performance oggettiva vs
  self-report; materiale semplice vs complesso; popolazione trasferibile vs no.
- **Riportare sempre il contro-dibattito** dove esiste (nudge, gamification, mindset, ego depletion,
  brain drain, background music, CO2 sono tutti casi ridimensionati dopo la crisi di replicazione).
- **Marcatore ⚠️ NON VERIFICATO** dove non si è potuto accedere al dato. Mai inventare.
- **Chiusura operativa** per ogni euristica/tema: è implementabile? è un arm randomizzabile? con quale
  prior numerico per il warm-start? quale rischio nocebo/reattanza comporta?
- Fonti complete: autore, anno, rivista, volume/pagine o DOI, link (PubMed/PMC/DOI/arXiv).
- Report **in italiano**, 6.000–15.000 parole secondo il tema. Non riassumere per brevità: devono
  poter sostituire la lettura della letteratura.
- Al termine, riassunto al chiamante di max 25–30 righe.

---

## R1 — Euristiche di CONTENUTO (cosa/come studiare)

**Domanda**: cosa dovrebbe raccomandare l'app riguardo a *cosa e come* studiare? Quali euristiche
sono validate, con quale forza e impatto quantitativo, e quali sono implementabili in un'app che
**non possiede il materiale di studio dell'utente**?

1. **Retrieval practice / testing effect**: effect size aggiornati, moderatori (feedback, formato,
   ritardo, tipo di materiale, complessità), transfer a materiale complesso, evidenza in corsi reali,
   critica alla generalizzabilità.
2. **Spacing / distributed practice**: ⚑ **recuperare il breakdown per tecnica dal full text di
   Donoghue & Hattie 2021** (questione aperta esplicita). Poi intervalli ottimali (Cepeda et al.
   2006/2008, rapporto spacing/retention interval), algoritmi di spaced repetition (SM-2, FSRS,
   half-life regression — Settles & Meeder 2016), adattivi vs intervalli fissi.
3. **Interleaving / practice variability**: per quali materiali funziona e per quali no; tensione con
   il blocking.
4. **Implementation intentions e goal setting**: d=0.65 verificato? decadimento nel tempo, evidenza in
   interventi digitali, confronto con mental contrasting/MCII (Oettingen), Locke & Latham,
   specificità/difficoltà dell'obiettivo.
5. **La mappa Dunlosky et al. 2013** (*PSPI* 14(1):4–58) come base, aggiornata con meta-analisi
   successive: elaborative interrogation, self-explanation, practice testing, summarization,
   highlighting, rereading, keyword mnemonic, imagery.
6. **Metacognizione e calibrazione (JOL), illusioni di fluenza**: interventi che correggono la
   sovrastima — un'app può misurare e correggere la calibrazione.
7. **Note-taking, generative learning** (Fiorella & Mayer), mapping, protégé effect.
8. **Worked examples, expertise reversal, cognitive load theory**: adattare la raccomandazione al
   livello dell'utente.
9. **Difficoltà desiderabili (Bjork)**: quadro unificante; quali sono davvero supportate.
10. **Feedback**: tipo, tempistica, effect size (Hattie & Timperley; Wisniewski et al. 2020).
11. Qualunque euristica con supporto meta-analitico non considerata dal team.

**Sezioni finali**: tabella arms candidati con prior numerici; "cosa NON è supportato / miti";
questioni aperte; bibliografia.

---

## R2 — STRUTTURA, TIMING e CONTESTO (quando studiare, come ambientare)

**Domanda**: cosa raccomandare su *quando* fare la sessione e *come* strutturarla/ambientarla?

1. **Ritmi circadiani e performance**: time-of-day su memoria, attenzione sostenuta, funzioni
   esecutive, problem solving creativo (synchrony effect e l'effetto *inverso* sulla creatività —
   Wieth & Zacks 2011). Cronotipo: MCTQ, µMCTQ, MEQ; social jetlag; effect size del mismatch
   cronotipo-orario sul rendimento accademico.
2. **Post-lunch dip**: esiste? quanto grande? circadiano o effetto del pasto?
3. **Pause**: verifica Albulescu 2022 e meta-analisi limitrofe; lunghezza ottimale; pause attive vs
   passive; natura/verde (ART, Kaplan); nap (durata ottimale, sleep inertia); detachment psicologico.
   ⚑ **Distinguere sempre affetto/fatica percepita da performance oggettiva.**
4. **Durata della sessione, vigilance decrement, time-on-task**: da quale minuto decade la
   performance; mind-wandering (tasso, andamento, thought probes); resource-depletion vs
   mind-wandering account. La durata suggerita è un arm randomizzabile.
5. **Sonno**: oltre a Schwarz 2026, altri studi intensive-longitudinal within-person su studenti
   reali (es. Okano et al. 2019 MIT); Sleep Regularity Index. Quanto è grande l'effetto *davvero*?
6. **Caffeina**: dose-risposta, timing rispetto a sessione e sonno (emivita; Drake et al. 2013),
   dibattito sul withdrawal reversal, interazione con cronotipo.
7. **Esercizio acuto**: meta-analisi (Chang et al. 2012; Ludyga et al.), intensità/durata/finestra,
   esercizio dopo l'encoding e consolidamento.
8. **Distrazione da smartphone**: brain drain (Ward et al. 2017) **e le sue repliche fallite**;
   meta-analisi su phone use e rendimento; RCT su app blocker e digital self-control tools; costo del
   task switching e tempo di recupero (Mark et al.); media multitasking.
9. **Ambiente fisico**: musica di sottofondo (attenzione a effetti nulli/negativi), rumore bianco,
   temperatura, illuminazione, CO2 (Allen et al./Harvard — effect size sospettosamente grandi, da
   verificare criticamente), postura, context-dependent memory e il consiglio controintuitivo di
   *variare* l'ambiente.
10. **Sequenziamento intra-giornata**: consolidamento sleep-dependent (studiare prima di dormire),
    sonno tra sessioni di pratica distribuita, wakeful rest dopo l'encoding (Dewar et al.).
11. **Nutrizione/idratazione/glicemia**: solo se l'evidenza regge; altrimenti dichiararla debole.
12. **Flow e interruzione**: il costo reale di interrompere la concentrazione supporta o smentisce la
    decisione del team di non intervenire mid-session?

**Sezioni finali**: tabella arms con prior; **"miti da non implementare"** (Pomodoro, ultradiano…)
con le fonti che li smontano; questioni aperte; bibliografia.

---

## R3 — METRICA DI OUTCOME e REWARD DESIGN ⚑ *priorità massima*

**Domanda**: quale metrica di risultato è ricavabile dal dispositivo, con quale validità dimostrata,
e come si progetta una reward function che non collassi in ottimi degeneri?

**Candidato attuale**: rapporto durata pianificata / durata effettiva. Auto-normalizzato, non richiede
di sapere cosa fosse "la vera concentrazione", randomizzabile pulitamente (si randomizza la durata
*suggerita*).

**Ottimi degeneri già identificati** (da ampliare): massimizzare l'aderenza insegna al bandit a
*predire* il comportamento invece di *cambiarlo* (il più insidioso); minuti assoluti → sessioni lunghe
e improduttive; premiare il completamento → l'utente dichiara durate banalmente brevi; premiare il
numero di sessioni → frammentazione.

**Idea §8.1 del handoff, considerata la più promettente e non ancora valutata a fondo**: se l'app
gestisce le flashcard, la **recall a distanza diventa un outcome di apprendimento oggettivo e
ripetuto** — reward vero, non manipolabile, per-item (molte osservazioni per sessione), difendibile
("misuro apprendimento, non engagement"). Costo: attrito di inserimento del materiale.

1. **Mind-wandering detection** da segnali digitali: thought probes come ground truth, PVT-B,
   detection da interazione/gaze/keystroke. Accuratezze reali e su quali popolazioni.
2. **Digital phenotyping**: StudentLife (Wang et al. 2014) e successori; app usage entropy, unlock
   frequency, ritmo circadiano da uso del telefono. R² reali per GPA/stress/attenzione — **essere
   spietati**: molti sono r≈0.2–0.4 su campioni piccoli; riportare repliche fallite.
3. **Misure oggettive di apprendimento in-app**: modelli di memoria (ACT-R, half-life regression,
   DASH, FSRS), affidabilità della recall probability come misura della qualità dell'encoding, rumore
   per-item, quanti item per una stima stabile; knowledge tracing (BKT, DKT) come outcome.
4. **Proxy comportamentali** di sessione di qualità: screen-off duration, app-switching, notification
   interaction, dwell time. Sono mai stati ancorati a ground truth?
5. **Validità dei self-report** di concentrazione/flow: Flow Short Scale, ESM; decoupling
   self-report/arousal; bias peak-end. Quanto valgono come *ancora sparsa*?
6. **Reward hacking**: Goodhart formalizzata (Manheim & Garrabrant 2018), reward misspecification,
   proxy reward. Applicare esplicitamente ai 4 degeneri noti e trovarne altri.
7. **Proximal vs distal outcome nei JITAI** (Nahum-Shani et al.): criteri di scelta, errori
   documentati; casi reali (HeartSteps, Sense2Stop, DIAMANTE) — che reward hanno usato e cosa è andato
   storto.
8. **Reward vincolato / multi-obiettivo**: constrained bandits, safety constraints, budget di
   notifiche, scalarizzazione. Quali garanzie si perdono.
9. **Surrogate endpoint validation**: criteri di Prentice — "il completion ratio predice davvero
   l'apprendimento?".
10. **Habituation**: engagement decay e novelty effect in mHealth → reward non stazionaria.
11. **Il paradosso di misura**: missing-not-at-random nel mobile sensing, censoring informativo,
    tecniche (imputazione, modelli di sopravvivenza, sensitivity analysis à la Rosenbaum bounds).
    ⚑ Punto più delicato: *se il consiglio funziona il dato sparisce* — quali strumenti esistono?
12. **Verifica del gate biometrico**: HRV/EDA come predittori di performance cognitiva in **sani non
    stressati** (non stress detection da laboratorio). Esiste qualcosa che batte "ora del giorno +
    comportamento"? Studi di ablazione dei confondenti.

**Sezione conclusiva = cuore del report**: **almeno 3 reward function alternative in forma
quasi-matematica** (termini, pesi indicativi, vincoli, meccanismi anti-gaming, piano di validazione
anti-degenerazione), con pro/contro e **una scelta motivata**.

---

## R4 — ALGORITMO

**Domanda**: come deve funzionare l'algoritmo, come impara, quali garanzie teoriche, quali fallimenti
documentati e quali alternative?

1. **MRT e JITAI**: Nahum-Shani, Klasnja, Liao, Qian. ⚑ **Verificare il dimensionamento del pilota con
   un calcolo di potenza esplicito**: 3.000 decision point bastano davvero? Riportare i numeri.
2. **Contextual bandit in mHealth, casi reali**: HeartSteps I/II, DIAMANTE, Sense2Stop, MyBehavior,
   Oralytics, StayWell. Per ciascuno: algoritmo, reward, N, **risultati reali** (molti nulli o
   falliti — dirlo) e lezioni operative.
3. **Thompson sampling**: linear/GLM TS, regret bounds, comportamento con prior informativi,
   sensibilità alla misspecificazione, posterior inflation, clipping e perché serve all'inferenza.
4. **Action centering ed excursion effects** (Boruvka et al. 2018, *JASA* 113(523):1112–1121): cosa
   risolve, formalizzazione, implementazione nei minimi quadrati pesati e centrati.
5. **Pooling e personalizzazione**: IntelligentPooling (Tomkins et al. 2021, −26% regret),
   mixed-effects TS, hierarchical Bayes, RoME, multi-task bandits. Quanto pooling con 40–50 utenti?
6. **Inferenza valida su dati adattivi**: Zhang/Janson/Murphy 2020 e successori (Hadad/Athey,
   adaptively weighted estimators; M-estimators su dati adattivi; Bibaut; Zhan). Quali stimatori in
   pratica, quali garanzie, quale costo in efficienza. **Come si dimensiona un batch, quanti servono.**
7. **Off-policy evaluation**: IPS, doubly robust, SNIPS, switch estimators; varianza con probabilità
   piccole; valutare una policy prima del deploy.
8. **Non-stazionarietà**: drift stagionale (semestre, esami); discounted/sliding-window UCB-TS,
   change-point detection, restart. Interazione con BOLS (dichiarato robusto — verificarlo).
9. **Availability ρ_t**: modellazione, missingness, effetto sull'inferenza quando l'availability è
   essa stessa influenzata dal trattamento passato.
10. **Non-aderenza e stime causali**: ITT vs per-protocol vs CACE/IV. ⚑ **La raccomandazione
    randomizzata è uno strumento naturale (encouragement design)**: si può stimare l'effetto del
    *comportamento*, non solo della raccomandazione? Quali assunzioni (exclusion restriction,
    monotonicity) e sono plausibili qui?
11. **N-of-1 trials e single-case designs**: metodologia, potenza, analisi (modelli misti su serie
    N-of-1, randomization tests), personalized trials in digital health.
12. **Warm start da prior di letteratura**: ⚑ come si traduce un effect size meta-analitico in un
    prior bayesiano su un coefficiente di bandit? Scala, unità, shrinkage, prior predictive checks;
    MAP priors / meta-analytic-predictive priors. Domanda pratica cruciale e poco trattata.
13. **Safety / policy floor**: conservative bandits, safe policy improvement, HCOPE/Seldonian
    framework. Come si formalizza "se fai peggio delle euristiche, torna alle euristiche".
14. **Comunicazione dell'incertezza**: esporre ciò che il modello ha imparato *insieme a quanto ne è
    sicuro* (il team vuole fasce ordinate, non punteggi continui).
15. **Alternative non considerate**: RL a orizzonte lungo vs bandit; POMDP; state-space/Kalman per lo
    stato latente; ⚑ **Gaussian process periodici sull'ora del giorno** (regressione circolare, molto
    adatta al problema); modelli gerarchici bayesiani puri senza bandit; recommendation as inference.

**Requisito aggiuntivo**: **formalizzare** — equazioni chiave in LaTeX (modello di reward, posterior
update, stimatore BOLS, action centering). Il report deve bastare per implementare.
**Sezione conclusiva = cuore**: pseudocodice, specifica di S_t, arms, batching, probabilità di
esplorazione, prior, test di sanità (recovery test, policy floor, plausibilità dei coefficienti),
roadmap a fasi con criteri di passaggio e campione richiesto per ciascuna.

---

## R5 — ADERENZA, MOTIVAZIONE, ENGAGEMENT

**Domanda**: come far sì che le persone (a) *inizino* le sessioni, (b) *seguano* le raccomandazioni,
(c) *continuino a usare l'app* abbastanza a lungo perché il modello impari?

Contesto specifico: il team ha identificato (§8.2) che **il decision point più prezioso è prima che
la sessione inizi** — "il fallimento più comune non è la sessione mediocre, è la sessione che non
comincia mai" — e lì l'implementation intention ha la sua evidenza migliore (d=0.65 è misurato
proprio sull'*iniziazione*). Il concept attuale ha decision point solo dentro o intorno alla sessione,
cioè condizionati sul campione già selezionato.

1. **Procrastinazione accademica**: prevalenza, correlati, meta-analisi sugli interventi (van Eerde &
   Klingsieck 2018; Rozental et al.), temporal motivation theory (Steel & König), task aversiveness.
2. **Implementation intentions applicate all'iniziazione**: consegna **digitale** (l'effect size cala?
   di quanto?), planning prompts (Nickerson & Rogers 2010), ⚑ **planning fallacy** (Buehler, Griffin &
   Ross) e sottostima sistematica delle durate — cruciale perché il reward poggia sulla durata
   dichiarata.
3. **Self-Determination Theory e reattanza psicologica** (Brehm): come formulare una raccomandazione
   senza generare reattanza (autonomy-supportive language — esistono meta-analisi?).
4. **Habit formation**: Lally et al. 2010 (mediana 66 giorni, range 18–254), cue consistency, habit vs
   intention. ⚑ **Analizzare a fondo il conflitto centrale: randomizzare l'orario contro formare
   l'abitudine** — la stabilità del contesto è esattamente ciò che la randomizzazione distrugge.
5. **Attrito e retention in digital health**: law of attrition (Eysenbach 2005), tassi reali di uso a
   30 giorni (Baumel et al. 2019 JMIR: numeri molto bassi, riportarli), novelty effect, curve di
   decadimento. Cosa distingue le poche app che trattengono.
6. **Gamification**: Sailer & Homner 2020; Koivisto & Hamari; e i rischi — overjustification /
   undermining della motivazione intrinseca (Deci, Koestner & Ryan 1999 e il dibattito successivo),
   streak e loss aversion, decadimento a lungo termine.
7. **Notifiche e nudge**: ⚑ **riportare entrambi i lati** — Mertens et al. 2022 PNAS (d≈0.43) *e*
   Maier et al. 2022 che dopo correzione per publication bias porta l'effetto a ~0. Notification
   fatigue, receptivity, timing, opt-out. Quanti prompt al giorno sono sostenibili.
8. **Self-monitoring e feedback**: tassonomia BCT (Michie) — quali tecniche hanno più supporto;
   visualizzazione dei progressi; goal-gradient; confronti sociali (rischio demotivante).
9. **Self-efficacy e mindset**: l'evidenza recente è molto più debole del pubblicizzato (Sisk et al.
   2018; National Study of Learning Mindsets); attribuzione; impotenza appresa → rischio nocebo.
10. **Adesione alle raccomandazioni algoritmiche**: algorithm aversion (Dietvorst et al. 2015) vs
    appreciation (Logg et al. 2019); effetto della trasparenza e dell'incertezza dichiarata
    ("non sono sicuro" aumenta o riduce la fiducia?); ⚑ Dietvorst 2018 — **dare anche un minimo
    controllo correttivo aumenta molto l'adesione**: cruciale per il design.
11. **Comunicare l'incertezza senza perdere credibilità**: van der Bles et al., Royal Society;
    formati numerici vs verbali.
12. **Etica dell'esperimento sugli utenti**: Facebook emotional contagion; ⚑ **Meyer et al. 2019 PNAS
    "experiment aversion"** — le persone giudicano l'esperimento peggio di *entrambe* le sue braccia.
    Direttamente rilevante: l'idea di "vendere la randomizzazione" potrebbe ritorcersi contro.
    Analizzarla a fondo e dare una raccomandazione concreta su come presentarla.
13. **Onboarding**: quanto si può chiedere al giorno 1 prima dell'abbandono; costo attentivo dei
    questionari validati brevi (µMCTQ ecc.).

**Sezione conclusiva**: raccomandazioni di design ordinate per evidenza/costo, con effect size atteso
e fonte; più **"conflitti di design non risolvibili"** (randomizzare vs abitudine; prescrittività vs
reattanza; onboarding informativo vs attrito) con analisi del trade-off e proposta.

---

## R6 — RED TEAM: punti ciechi, opportunità, idee inesplorate

**Ruolo**: red team intellettuale. Trovare ciò che il team **non** ha visto. Non ripetere R1–R5.

**Idee che il team ha elencato ma non approfondito** (§8 del handoff — valutarle criticamente e
quantificarle, senza limitarsi a queste): spaced repetition come strumento di *misura*; il decision
point prima dell'inizio; vendere la randomizzazione come feature; gli esami come outcome distale
gratuito; digital phenotyping passivo; il carico accademico come moderatore dominante; telemetria del
compito da desktop companion; peer benchmark per il cold start; slider retrospettivo di fine sessione;
detection della fine naturale della sessione; foundation model dopo il pilota; "modo aereo
intelligente" come arm; reward vincolato.

1. **Panorama competitivo**: Forest, Focusmate, Brain.fm, RescueTime, Rize, Sunsama, Motion, Reclaim,
   Anki/RemNote/Traverse, Rise Science, Whoop/Oura "readiness", Opal, one sec, Endel, Focus Bear. Per
   ciascuno: claim, evidenza, metrica ottimizzata, limite. Poi: **dov'è lo spazio vuoto reale?**
   ⚑ Cercare specificamente **StudyU / StudyMe** (piattaforma accademica per N-of-1 trials digitali) e
   simili: potrebbero essere insieme concorrenti *e* infrastruttura riusabile.
2. ⚑ **Fattibilità tecnica su Android e iOS — punto cieco quasi certo.** Verificare sulla
   **documentazione ufficiale**, non speculare: `UsageStatsManager` e permesso `PACKAGE_USAGE_STATS`
   (+ policy Play Store); su iOS **ScreenTime / DeviceActivity / FamilyControls / ManagedSettings** —
   *cosa si può davvero leggere ed esportare fuori dall'estensione?* Quasi nulla, probabilmente: se è
   così, metà delle idee di digital phenotyping è infattibile su iOS. Più: limiti di esecuzione in
   background, HealthKit/Health Connect (sonno, HR, HRV, passi: latenza e granularità), Focus modes,
   e se è possibile bloccare app di terze parti e con quali API.
3. **Privacy, GDPR, regolamentazione**: dati comportamentali granulari e (opzionalmente) sanitari, con
   possibili minorenni. Art. 9, base giuridica per la ricerca, consenso al trattamento vs alla
   ricerca, DPIA. Poi ⚑ **confine dispositivo medico**: EU MDR / MDCG 2019-11, FDA general wellness
   guidance. L'app fa claim su performance cognitiva: dove passa il confine e come si formulano i
   claim per restarne fuori (citare il testo delle guidance).
4. **Etica della ricerca su utenti reali**: serve un comitato etico per il pilota? cosa cambia se i
   dati vengono pubblicati? consenso informato in-app; linee guida su A/B testing etico.
5. **Canali di segnale non considerati** (creativi ma ancorati a evidenza): calendario; meteo ed
   esposizione luminosa; **localizzazione/luogo di studio** (moderatore forte e a costo zero); studio
   sociale/con altri; audio ambientale privacy-preserving; keyboard extension; sensori inerziali per
   postura; fotocamera frontale; input vocale; **integrazione LMS** (Moodle/Canvas: scadenze e
   materiali); e-reader/PDF reader; **browser extension** come alternativa economica al desktop
   companion.
6. ⚑ **Il ruolo degli LLM — assente dal handoff, probabile punto cieco maggiore**: generazione
   automatica di flashcard/domande dal materiale dell'utente (**risolverebbe l'attrito che blocca
   l'idea §8.1, la più promettente**); valutazione automatica di risposte aperte (la forma di
   retrieval practice con effect size migliore); tutoring socratico; estrazione di dati strutturati
   dalle note. Cercare l'evidenza: qualità delle domande LLM-generated; effect size dell'AI tutoring
   (Kestin et al. 2025 Harvard; VanLehn 2011 sugli ITS, d≈0.76). Quantificare.
7. **Pre-mortem strutturato**: il progetto è fallito tra 18 mesi — almeno **10 cause plausibili e
   distinte**, ordinate per probabilità×impatto, ciascuna con mitigazione. Includere rischi *fuori*
   dalla lista del team (che contiene solo: sovra-affermazione visiva, auto-avveramento, nocebo,
   interruzione del flow, terminazioni prescritte, gating sul wearable, churn, claim regolatori).
8. **Validazione a basso costo prima di costruire l'app**: Wizard-of-Oz, studi via SMS/Telegram, diary
   study, Prolific per testare i formati di raccomandazione, e ⚑ **riuso di dataset pubblici in
   dominio** (dataset Anki pubblici, MOOC/learning analytics, StudentLife). Un dataset in dominio
   varrebbe mesi di pilota: cercarlo seriamente.
9. ⚑ **Il baricentro del prodotto**: il team ammette la tensione non risolta — l'evidenza più forte
   riguarda *cosa/come* studiare, il concept è centrato su *quando*. Prendere posizione argomentata e
   valutare **almeno 3 riformulazioni alternative** del concept (es.: un'app di spaced repetition che
   incidentalmente ottimizza il timing, invece di un'app di timing che incidentalmente fa flashcard).
10. **Modello di business**: chi paga il pilota; freemium vs abbonamento vs licenza istituzionale
    (l'università come cliente apre a dati d'esame e comitati etici) e implicazioni sul design dei
    dati. Breve ma concreto.

**Registro**: essere sgradevoli. Il valore sta nelle cose che il team non vuole sentirsi dire; se il
concept ha un difetto strutturale, dirlo esplicitamente e argomentarlo.
**Chiusura**: tutto ordinato per valore/costo + **le 10 azioni più importanti nei prossimi 3 mesi**.

---

## Dopo i sei report

Sintesi trasversale a cura dell'orchestratore: contraddizioni tra report, decisioni che ne discendono,
e aggiornamento di `FOCUSMAXXER_HANDOFF.md` (§7 questioni aperte, §2 stato dell'evidenza).
