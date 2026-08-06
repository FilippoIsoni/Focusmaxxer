# R1 — Cosa raccomandare: euristiche di contenuto, struttura, timing e contesto

> Report unificato R1 (contenuto: cosa/come studiare) + R2 (struttura/timing/contesto: quando
> studiare, come ambientare). Risponde alla domanda 1: cosa dovrebbe raccomandare l'app, quali
> euristiche sono validate, qual è il loro impatto quantitativo.

## Indice
1. [Sintesi per il chiamante](#1-sintesi)
2. [Metodo e vincoli di questo report](#2-metodo)
3. [PARTE A — Euristiche di contenuto](#3-parte-a)
4. [PARTE B — Struttura, timing, contesto](#4-parte-b)
5. [Tabella arms candidati per il bandit con prior numerici](#5-arms)
6. [Miti da non implementare](#6-miti)
7. [Questioni aperte](#7-aperte)
8. [Bibliografia](#8-biblio)

---

## 1. Sintesi

**Il fatto che cambia di più il prodotto**: il breakdown per tecnica di Donoghue & Hattie (2021,
*Front Educ* 6:581216), recuperato dal full text, mostra che **distributed practice ha d = 0.85**
(150 casi, N = 152.952) — non 0.54, non 0.56 (quella era la media di *tutte e dieci* le tecniche).
Practice testing segue con **d = 0.74** (374 casi, N = 6.033). Questi sono i due arm di contenuto
più forti in assoluto disponibili al prodotto, più forti di implementation intentions (d = 0.65) e
di qualunque euristica di timing. Vedi §3.2 per la tabella completa a dieci tecniche.

Altri punti chiave: interleaving è validato ma più debole e più condizionato (g = 0.42, dipende
fortemente dalla similarità tra categorie); il "brain drain" di Ward et al. 2017 **non replica**
(Ruiz Pardo & Minda 2022, nessuna differenza tra condizioni); la letteratura CO2/cognizione è
**internamente contraddittoria** (Allen 2016 Harvard vs. studio danese 2016 e submariners USA —
nessun effetto a 5.000–15.000 ppm) e va esclusa dagli arm; la musica di sottofondo ha **effetto medio
nullo** con forte eterogeneità (negativo con testo/lettura, neutro/positivo altrove); l'esercizio
acuto richiede **almeno 11 minuti** per produrre benefici cognitivi misurabili (Chang et al. 2012).

## 2. Metodo

Report in italiano. Priorità tabelle dense su prosa. Marcatore ⚠️ NON VERIFICATO dove il dato non è
stato recuperato da fonte primaria in questa sessione (solo da search snippet secondario o non
recuperabile nel budget). Distinzione meta-analisi vs studio singolo, laboratorio vs campo,
performance oggettiva vs self-report, dove i dati lo permettono.

---

## 3. PARTE A — Euristiche di contenuto

### 3.1 Retrieval practice / testing effect

| Fonte | Disegno | Effect size | N studi / partecipanti | Note |
|---|---|---|---|---|
| Rowland 2014, *Psych Bull* 140(6):1432–1463 | Meta-analisi, test vs restudy | **g = 0.50** complessivo; **0.73** con feedback vs **0.39** senza | ampio pool, non riportato N esatto nello snippet | Recall test iniziale > recognition test come predittore dell'effetto |
| Adesope, Trevisan & Sundararajan 2017, *Rev Educ Res* 87(3):659–701 | Meta-analisi, practice testing | **g = 0.61** overall (retention 0.63, transfer 0.53) | 223 studi lab + 30 in classe (253 studi) | Lab 0.62 vs classe 0.67 — **nessun crollo fuori laboratorio**; primaria 0.64, secondaria 0.83, post-secondaria 0.60 |
| Donoghue & Hattie 2021 (full text recuperato) | Meta-analisi, practice testing come 1 di 10 tecniche | **d = 0.74** | 374 casi / N = 6.033 | Secondo per forza dopo distributed practice; feedback aumenta ulteriormente l'effetto (non quantificato in tabella) |

**Moderatori consistenti tra le tre fonti**: (a) il feedback quasi raddoppia l'effetto (0.73 vs 0.39,
Rowland); (b) l'effetto **non degrada** passando dal laboratorio alla classe reale, anzi tende a
essere leggermente più alto in classe (Adesope: 0.67 vs 0.62); (c) il transfer a materiale/quesiti
diversi da quelli praticati è più debole ma resta consistente (0.53 vs 0.63, Adesope; near 0.61 vs
far 0.39, Donoghue & Hattie — quest'ultimo dato aggregato su tutte le tecniche, non solo retrieval).

**Implementabilità in un'app senza il materiale dell'utente**: alta. Non serve conoscere il
contenuto per raccomandare *la pratica del richiamo* come modalità (es. "chiuditi il libro e prova a
ricordare" come istruzione generica, o integrazione flashcard §8.1 dell'handoff). L'effetto del
feedback impone però che, se l'app vuole massimizzare l'impatto, la modalità raccomandata debba
includere un momento di verifica — anche generico ("hai ricordato correttamente? sì/no").

**Chiusura operativa**: arm primario. Prior warm-start: d ≈ 0.55–0.65 (media pesata tra le tre fonti,
scontata per la genericità dell'implementazione — l'app non fornisce feedback specifico sul
contenuto, solo la struttura). Randomizzabile come "modalità raccomandata: retrieval-first vs
restudy-first" per un dato blocco. Rischio nocebo: basso — è un consiglio di metodo, non di giudizio
sulla persona.

---

### 3.2 Spacing / distributed practice — **breakdown per tecnica recuperato**

⚑ **Questione aperta risolta**: il full text di Donoghue & Hattie 2021 (recuperato via WebFetch da
frontiersin.org) riporta la Tabella 1 con effect size per singola tecnica. Il valore complessivo
0.56 citato nell'handoff era la **media di tutte e dieci le tecniche**, non il valore per il solo
distributed practice.

**Tabella 1 di Donoghue & Hattie 2021 — le dieci tecniche, ordinate per effect size:**

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

*Media complessiva: d = 0.56 su 1.619 effetti / 169.179 partecipanti unici (242 studi).*

**Moderatori generali del pool (tutte le tecniche insieme, non solo spacing):**
- Near transfer d = 0.61 vs far transfer d = 0.39
- Surface/factual learning d = 0.60 vs deep/relational learning d = 0.26 (**cautela**: la
  maggioranza degli studi misura outcome di superficie — l'estrapolazione a comprensione profonda è
  debole)
- Bassa abilità d = 0.47 vs alta abilità d = **−0.11** (per gli studenti già forti l'effetto può
  invertirsi — coerente con l'expertise reversal, §3.8)
- Presenza di feedback: modera positivamente (non quantificato in cifra separata nello snippet
  recuperato — ⚠️ da verificare se serve la cifra esatta)

**Intervallo ottimale (Cepeda et al. 2006, 2008)**:
- Cepeda et al. 2006 (*Psych Bull*): meta-analisi di 839 confronti in 317 esperimenti / 184 articoli.
  L'intervallo tra studio (ISI) e l'intervallo di ritenzione (RI) interagiscono: l'ISI che massimizza
  la ritenzione **cresce** al crescere del RI.
- Cepeda et al. 2008 (*Psychological Science*, "A Temporal Ridgeline of Optimal Retention"): studio
  su oltre 1.350 soggetti, gap fino a 3,5 mesi, test finale fino a 1 anno dopo. Il gap ottimale,
  espresso come **proporzione del ritardo del test**, scende da **20–40% di un ritardo di 1
  settimana** a **5–10% di un ritardo di 1 anno**. Non è un intervallo fisso: dipende da quanto a
  lungo l'utente deve ricordare.

**Algoritmi di spaced repetition adattivi**:
- **SM-2** (SuperMemo, storico): intervalli fissi crescenti per un "easiness factor" per-item,
  aggiornato a ogni review. Base di Anki classico.
- **Half-Life Regression** (Settles & Meeder 2016, ACL): modella l'emivita di ritenzione per-item
  come funzione log-lineare di feature lessicali e storico di performance. Deployato in produzione a
  Duolingo: **−45% errore predittivo** vs baseline, **+12% engagement giornaliero**. Progettato per
  esercizi brevi di vocabolario in un'app gamificata — non generalizzato a un general-purpose
  scheduler.
- **FSRS** (Free Spaced Repetition Scheduler, comunità open-spaced-repetition): successore moderno,
  usa un modello di memoria a più parametri (stabilità/difficoltà) aggiornato per-item. Confronti
  diretti FSRS vs SM-2 sono contestati (la comunità FSRS segnala che i benchmark storici confrontano
  un SM-2 "ottimizzato proprietario" con un FSRS non ottimizzato usando la tassonomia del sistema
  proprietario) — ⚠️ un test testa-a-testa nello stesso software non risulta ancora completato.

**Chiusura operativa**: **d = 0.85 è il numero più forte dell'intero report**, va usato con cautela
comunicativa perché include 150 casi molto eterogenei (da liste di parole a corsi universitari) e un
solo studio enorme (probabile dominanza di pochi campioni molto ampi — SEM = 0.053 è comunque
stretto). Prior warm-start: d ≈ 0.7 (leggero sconto per eterogeneità ed effetto studi di grandi
dimensioni). Arm primario: "pianifica sessioni di ripasso distanziate" — implementabile senza
conoscere il contenuto se l'app traccia *quando* un argomento è stato toccato l'ultima volta. Se
integrato con flashcard (§8.1 handoff), l'algoritmo di spacing (FSRS) diventa sia intervento sia
strumento di misura.

---

### 3.3 Implementation intentions e goal setting

| Fonte | Effect size | N | Note |
|---|---|---|---|
| Gollwitzer & Sheeran 2006, *Adv Exp Soc Psychol* 38:69–119 | **d = 0.65** | 94 test indipendenti, >8.000 partecipanti | **Confermato**, non un artefatto di citazione. Efficace su iniziazione, protezione del goal, disimpegno da corsi falliti, conservazione di capacità |
| Sheeran, Listrom & Gollwitzer 2024 (aggiornamento) | Dipendente da formato/contesto motivazionale, non un valore universale | **642 test indipendenti** | L'effetto **non decade** nel senso di essere invalidato, ma si frammenta: la dimensione dipende da come il piano if-then è formulato e dal contesto — non esiste più "un" d di riferimento |

⚠️ NON VERIFICATO in questa sessione: la cifra esatta dell'effetto medio nell'aggiornamento 2024 e il
confronto diretto con mental contrasting/MCII (Oettingen) — non recuperato per budget di ricerca. Da
recuperare prima di citare pubblicamente un confronto quantitativo MCII vs implementation intentions.

**Chiusura operativa**: arm primario per la fase di *inizio sessione* (si veda §8.2 handoff — il
decision point pre-sessione è quello con l'evidenza migliore per questo costrutto specifico, dato che
d = 0.65 è misurato sull'iniziazione del goal striving, non sulla performance durante il compito).
Prior: d ≈ 0.5–0.65, scontato per consegna digitale generica (non misurato specificamente qui, ma
plausibile un decadimento nel passaggio da protocollo di laboratorio a un tap in-app — trattare come
ipotesi da verificare col pilota, non come fatto).

---

### 3.4 Interleaving / practice variability

| Fonte | Effect size | N | Note |
|---|---|---|---|
| Brunmair & Richter 2019, meta-analisi | **g = 0.42** (95% CI [0.34, 0.50]), p = 0.001 | 59 studi | Effetto medio solido; **più forte quando le categorie mescolate sono simili e facilmente confondibili** (es. tipi di formula simili) |
| Donoghue & Hattie 2021 | d = 0.47 | 104 casi / 972 N | Coerente con Brunmair & Richter, leggermente più alto |
| Rohrer, Dedrick & Stershic 2015 | d ≈ 0.79 sul test ritardato | 126 studenti di 7ª classe | RCT in classe reale, matematica: stessi problemi, ordine diverso. Interleaving > blocking sia su test immediato che (soprattutto) ritardato |

**Tensione con il blocking**: l'interleaving funziona meglio quando la discriminazione tra categorie
è il compito difficile (es. riconoscere quale formula usare), non quando serve prima automatizzare
una singola procedura. Per novizi assoluti su una procedura nuova, un blocco iniziale di pratica
ripetuta prima di interleave è coerente con cognitive load theory (§3.8) — la letteratura non
sostiene "interleaving sempre e comunque".

**Chiusura operativa**: arm secondario, applicabile solo se l'app conosce la *categoria* di compito
(es. tipo di esercizio dichiarato dall'utente), non il contenuto specifico. Prior: d ≈ 0.45. Rischio:
percepito come "più difficile" nel breve termine (è letteralmente una difficoltà desiderabile,
§3.9) — comunicare l'aspettativa per ridurre la reattanza.

---

### 3.5 La mappa Dunlosky et al. 2013, aggiornata

Il monografo originale (Dunlosky, Rawson, Marsh, Nathan & Willingham 2013, *Psychol Sci Public
Interest* 14(1):4–58) assegnava rating qualitativi di utilità (alta/media/bassa) a dieci tecniche,
senza un effect size comune. Donoghue & Hattie 2021 fornisce ora la **quantificazione diretta** delle
stesse dieci tecniche sotto una metrica comune (tabella in §3.2). Confronto:

| Tecnica | Rating Dunlosky 2013 | d quantitativo (Donoghue & Hattie 2021) | Verdetto aggiornato |
|---|---|---|---|
| Practice testing | Alta | 0.74 | Confermato, tra i due migliori |
| Distributed practice | Alta | 0.85 | Confermato, il migliore in assoluto |
| Elaborative interrogation | Media | 0.56 | Confermato: buono ma non top-tier |
| Self-explanation | Media | 0.54 | Confermato |
| Interleaved practice | Media | 0.47 | Confermato come "media", non "alta" |
| Summarization | Bassa | 0.44 | **Sorprendente**: d = 0.44 non è trascurabile in assoluto, ma è il più basso del pool — il rating "bassa utilità" di Dunlosky si riferiva a *inconsistenza* tra studi (molti studenti la fanno male), non a un effetto medio nullo |
| Highlighting/underlining | Bassa | 0.44 | Idem — stesso effetto medio di summarization, ma alta eterogeneità (SEM = 0.115, il più alto del pool: dipende moltissimo da *come* si sottolinea) |
| Rereading | Bassa | 0.47 | Effetto medio non nullo, ma è la baseline a cui tutte le altre tecniche vanno confrontate — resta la meno raccomandabile in termini relativi |
| Imagery | Media | 0.56 | Confermato |
| Keyword mnemonic | Media | 0.50 | Confermato |

**Lettura corretta**: il quadro Dunlosky 2013 non è stato smentito da Donoghue & Hattie 2021, è stato
**quantificato**. La gerarchia relativa (practice testing e distributed practice in cima) è la
stessa; la novità è che anche le tecniche "a bassa utilità" hanno effetti medi positivi non
trascurabili — il problema di Dunlosky con highlighting/rereading era la **variabilità
implementativa** (facili da fare male), non l'assenza di effetto quando fatte bene.

---

### 3.6 Metacognizione, calibrazione, illusioni di fluenza

⚠️ Ricerca in questa sessione non ha prodotto un effect size di riferimento singolo, solido e
citabile (nessuna meta-analisi con numero aggregato è emersa nei primi risultati; esiste "Calibrating
Calibration: A Meta-Analysis of Learning Strategy Instruction Interventions" — ⚠️ NON VERIFICATO, non
recuperato l'effect size esatto nel tempo disponibile). Quadro qualitativo solido e convergente su
più fonti:
- Gli studenti (specialmente i più deboli) **sovrastimano sistematicamente** quanto ricorderanno —
  l'illusione di fluenza (l'informazione sembra "familiare" durante lo studio, ma la familiarità non
  predice il richiamo).
- Interventi di calibrazione (giudizi di apprendimento item-specifici + feedback + psicoeducazione)
  **migliorano l'accuratezza della monitorizzazione** oltre il solo effetto del testing ripetuto.
- Il fallire un tentativo di retrieval practice **riduce l'overconfidence** più del semplice
  restudio (fonte: ScienceDirect, "Improving metacognitive accuracy... failing to retrieve").

**Chiusura operativa**: non un arm indipendente allo stato attuale (manca un effect size aggregato
citabile), ma un **meccanismo di supporto**: se l'app implementa retrieval practice con giudizio di
confidenza pre-risposta ("quanto sei sicuro?"), ottiene calibrazione come sottoprodotto gratuito del
suo arm primario (§3.1), senza bisogno di disegnarlo come intervento separato.

---

### 3.7 Note-taking, generative learning, mapping

| Fonte | Costrutto | Effect size | N | Note |
|---|---|---|---|---|
| Fiorella & Mayer (review 2015) | Self-explanation | positivo in 44/54 esperimenti | 54 esperimenti | Non un g aggregato in questo snippet |
| Meta-analisi (69 confronti, fonte secondaria) | Self-explanation prompting | **g = 0.55** generale; **g = 0.35** quando la spiegazione è fornita dall'istruttore invece che generata dallo studente | 69 confronti | Conferma il principio generativo: **generare** batte **ricevere**, coerente con retrieval practice e con la teoria dell'apprendimento attivo |

⚠️ NON VERIFICATO: effect size specifici per drawing/mapping isolati da self-explanation — la ricerca
di questa sessione non li ha isolati con un numero pulito. Il "protégé effect" (insegnare per
imparare) non è stato quantificato in questa sessione — segnalarlo come questione aperta (§7).

**Chiusura operativa**: arm secondario. "Genera una spiegazione con parole tue" è implementabile come
prompt generico di fine-sessione senza conoscere il contenuto. Prior: d ≈ 0.5, coerente col principio
generativo condiviso con retrieval practice.

---

### 3.8 Worked examples, cognitive load, expertise reversal

| Fonte | Effect size | N | Note |
|---|---|---|---|
| Meta-analisi worked examples in matematica | **g = 0.48** | 43 articoli / 55 studi / 181 effetti | Media, specifico per matematica |
| Fonte alternativa | d = 0.37 | — | Variazione a seconda degli studi inclusi |
| Expertise reversal effect (meta-analisi, ScienceDirect 2025) | l'effetto **si inverte** con l'esperienza | non quantificato nello snippet | Il supporto (worked example) che aiuta il novizio introduce carico estraneo per l'esperto quando è ridondante col suo schema |

**Meccanismo**: cognitive load theory — l'assistenza che riduce il carico per un novizio (senza schemi
pregressi) diventa carico ridondante/estraneo per chi ha già lo schema, perché deve processare
informazione che già possiede.

**Chiusura operativa**: implementabile solo se l'app conosce (o l'utente dichiara) il **livello di
familiarità** col materiale — coerente col "tipo di compito dichiarato" già nel concept (nuovo
materiale vs ripasso). Per "nuovo materiale": raccomandare worked examples / esempi risolti prima
della pratica autonoma. Per "ripasso/esercizi": raccomandare pratica diretta, l'assistenza sarebbe
controproducente. Prior: d ≈ 0.4–0.45, condizionato al livello dichiarato.

---

### 3.9 Difficoltà desiderabili (Bjork) — quadro unificante

Cinque difficoltà hanno "decenni di evidenza" a supporto secondo la sintesi recuperata: **spacing,
interleaving, retrieval, generazione, pratica variata** — ciascuna batte l'alternativa più facile sui
test *ritardati* (non necessariamente su quelli immediati, dove a volte la versione facile è pari o
migliore — questo è il segno distintivo di una difficoltà "desiderabile" vs una difficoltà solo
scomoda).

**Condizione di fallimento nota**: le difficoltà desiderabili **smettono di essere desiderabili**
quando il carico di lavoro cognitivo è già saturo per alta interattività degli elementi (high element
interactivity) — cioè quando il materiale è già intrinsecamente complesso per il livello dello
studente. In quel caso aggiungere difficoltà (es. interleaving aggressivo su materiale nuovo e
complesso) può essere puramente dannoso, non "desiderabile".

**Chiusura operativa**: non un arm a sé, è il **quadro teorico che giustifica perché retrieval,
spacing e interleaving funzionano insieme e non in competizione** — utile per la narrazione
prodotto/UX, non per una singola azione randomizzabile.

---

### 3.10 Feedback

| Fonte | Effect size | N | Note |
|---|---|---|---|
| Wisniewski, Zierer & Hattie 2020, *Front Psychol* 10:3087 | **d = 0.48** | 435 studi, k = 994, N > 61.000 | Modello random-effects. Eterogeneità molto alta: il feedback **non è un trattamento singolo** |
| Moderatore chiave | il contenuto informativo del feedback conta più della sua semplice presenza | — | Feedback ha impatto maggiore su esiti cognitivi/motori che su esiti motivazionali/comportamentali |

**Chiusura operativa**: coerente con §3.1 — il feedback è il moltiplicatore più forte di retrieval
practice (0.73 vs 0.39, Rowland). Non un arm indipendente ma un **parametro di implementazione**
dell'arm retrieval practice: la versione "con feedback" deve essere il default, non un extra.

---

## 4. PARTE B — Struttura, timing, contesto

### 4.1 Cronotipo e time-of-day

| Costrutto | Risultato | Fonte | Robustezza |
|---|---|---|---|
| Cronotipo mattutino vs GPA | mattutini più rappresentati nella fascia "eccellente" (49,1% vs 29% dei serotini) | systematic review/meta-analisi (ScienceDirect, non ri-verificata su full text) | ⚠️ solo snippet, correlazionale |
| Synchrony effect, intelligenza fluida | supportato in **laboratorio** | systematic review 2025 (Chronobiology International) | Laboratorio, non campo |
| Synchrony effect, intelligenza cristallizzata | **non** supportato in laboratorio, ma sì negli studi su voti scolastici reali | idem | Divergenza lab vs campo — segno di confondenti nello studio sui voti (endogeneità, §3.1 handoff) |
| Asynchrony effect su problem solving creativo | performance **maggiore** in orari **non ottimali** per problemi insight; nessun effetto consistente sui problemi analitici | Wieth & Zacks 2011, *Thinking & Reasoning* 17(4) | Meccanismo: controllo inibitorio ridotto agli orari non-ottimali permette intrusione di stimoli irrilevanti → più associazioni divergenti/creative |
| Social jetlag | serotini meno capaci di adattarsi a orari sub-ottimali imposti (scuola), con self-control ridotto | review | Aggregato, non un singolo effect size |

**Implicazione diretta e controintuitiva per il prodotto**: se il synchrony effect vale per
l'intelligenza fluida ma non per la cristallizzata in laboratorio, e l'*asynchrony* effect vale per il
problem solving creativo, allora **"studia sempre alla tua ora migliore" è una semplificazione falsa
persino nella letteratura pro-cronotipo**: la raccomandazione ottimale dipende dal *tipo* di compito,
non solo dall'ora. Questo rinforza la scelta già presa dal team (§1 handoff) di allocare *tipo di
compito per fascia* invece di "ore buone/cattive" — è coerente con l'evidenza, non solo un
compromesso anti-nocebo.

⚠️ NON VERIFICATO: un effect size aggregato pulito del mismatch cronotipo-orario sul rendimento
accademico (numero preciso non recuperato in questa sessione, solo direzione dell'effetto).

**Chiusura operativa**: cold-start via µMCTQ (già deciso in handoff §6). Arm: "compiti
analitici/di memorizzazione nelle ore di picco dichiarato dal cronotipo; problem solving
creativo/brainstorming anche fuori picco". Rischio: nessuno, se implementato come allocazione (mai
ore morte) coerentemente col concept già scelto.

### 4.2 Post-lunch dip

| Domanda | Risposta | Fonte |
|---|---|---|
| Esiste? | Sì, per un sottoinsieme di misure di performance in un sottoinsieme di individui | review classiche (Monk, Chronobiology International) |
| Circadiano o da pasto? | **Circadiano** (secondo armonico a 12h del sistema circadiano) — presente **anche senza pranzo** e anche ignorando l'ora | più fonti convergenti |
| Il pasto lo aggrava? | Sì — un pasto a pranzo peggiora ulteriormente le performance già in calo per motivi circadiani | idem |
| Sensibilità per tipo di compito | Compiti di **attenzione sostenuta** sono i più sensibili | idem |
| Modulatori | Aggravato da sonno notturno disturbato la notte precedente | idem |
| Variabilità individuale | Fenomeno endogeno, ma di entità **individualmente variabile**, correlato alla forza dell'armonica 12h personale | idem |

**Chiusura operativa**: non quantificabile con un singolo effect size affidabile in questa sessione
(⚠️ nessuna meta-analisi con d/g recuperata). Trattare come moderatore qualitativo debole: evitare di
allocare compiti ad alta attenzione sostenuta nella fascia post-pranzo per default, ma **non
inibirla** (coerente col principio "mai zone morte").

### 4.3 Pause (verifica di Albulescu 2022 + evidenza limitrofa)

Dato principale già in mano (handoff, confermato qui non ri-derivato): Albulescu et al. 2022, *PLOS
ONE* 17(8):e0272460 — 22 studi, le microbreak **riducono fatica e aumentano vigore** ma l'effetto su
**performance oggettiva è ≈ nullo** per compiti cognitivamente impegnativi. Distinzione cruciale:
**affetto/fatica percepita ≠ performance**. Non risulta contraddetto da fonti limitrofe consultate in
questa sessione.

⚠️ NON VERIFICATO in questa sessione (non ricercato per budget, priorità bassa secondo l'ordine
richiesto): durata ottimale della pausa, pause attive vs passive, nap/sleep inertia, ART/natura
(Kaplan), detachment psicologico. Questi restano com'erano nell'handoff — nessun dato nuovo aggiunto,
nessuna contraddizione trovata. Da completare in un giro di ricerca successivo se il budget lo
permette.

**Chiusura operativa (aggiornata da questa sessione)**: la pausa **non** va venduta come booster di
performance (l'evidenza non lo sostiene), va venduta come recupero di benessere/vigore soggettivo —
framing onesto e già implicito nella decisione del team di rendere le terminazioni/pause opt-in.

### 4.4 Durata sessione, vigilance decrement, mind-wandering

| Costrutto | Risultato | Fonte |
|---|---|---|
| Vigilance decrement | Declino monotono di accuratezza/sensibilità nel tempo-su-compito, dimostrato su un'ampia varietà di compiti da minuti a ore | meta-analisi sensibilità in vigilanza (See & Warm) |
| Mind-wandering vs time-on-task | Aumento **lineare** della frequenza con la continuazione del tempo-su-compito, in quasi tutti i task studiati | meta-analisi di **68 studi**, quasi mezzo milione di risposte a thought-probe, >10.000 individui unici |
| Soglia minima di rilevabilità | Il mind-wandering contribuisce al vigilance decrement anche in compiti **brevi** (10 minuti) | studio SART su universitari |
| Meccanismo | Le risorse attentive si spostano dal compito primario al pensiero task-unrelated, consumando esse stesse risorse | teorie di resource-depletion |

**Implicazione per il prodotto**: non esiste "il minuto x" universale in cui la performance crolla —
il declino è continuo e dipende dal compito, non un gradino a soglia fissa. Questo supporta
direttamente la decisione già presa (handoff) di trattare la **durata come arm randomizzabile**
piuttosto che come output di un modello predittivo di soglia — non c'è una soglia "vera" da stimare,
c'è una funzione di declino continua da esplorare per range.

**Chiusura operativa**: arm "durata suggerita" con 3-4 livelli (es. 25/45/60/90 min) randomizzato,
nessun prior forte su un valore "corretto" perché la letteratura non lo fornisce come costante
universale — il prior deve venire dal pilota stesso, non dalla letteratura di vigilanza (che
peraltro, ricorda l'handoff, è validata per privazione di sonno più che per attenzione intra-task in
soggetti riposati — coerenza mantenuta).

### 4.5 Sonno

| Fonte | Disegno | Risultato | Robustezza |
|---|---|---|---|
| Schwarz et al. 2026 (già in handoff) | Intensive longitudinal, 21gg | within-person +0.11 risposte/ora sonno (CI 0.06–0.15); between-person nullo | Alta — confermato, nessuna revisione necessaria |
| Okano et al. 2019, *npj Sci Learn* | 100 studenti MIT con Fitbit, 88 completatori, un semestre | qualità/durata/**consistenza** del sonno correlate a voti migliori; andare a letto dopo una soglia individuale (~2:00 per questo campione) associato a performance peggiore **indipendentemente dal totale di sonno** | Correlazionale, N piccolo (88), popolazione MIT (non generalizzabile) |

**Convergenza tra le due fonti**: entrambe puntano più alla **regolarità/consistenza** che alla
durata assoluta come predittore, coerente con l'enfasi crescente in letteratura su Sleep Regularity
Index (già citato nell'handoff, Phillips et al. 2017) rispetto alla sola durata media.

**Chiusura operativa**: nessun cambiamento rispetto all'handoff — il sonno resta recuperato solo al
boot (già architetturalmente corretto), l'effetto reale è piccolo (+0.11/h) ma la **regolarità** è un
segnale potenzialmente più forte della durata, e potrebbe giustificare un futuro arm/feature "sonno
regolare ieri notte" come contesto S_t, non come target.

### 4.6 Caffeina

| Domanda | Risposta | Fonte |
|---|---|---|
| Effetto su sonno successivo, per timing (0/3/6h prima di coricarsi) | Riduce il sonno totale di **~1,2h**, **indipendentemente** dal timing entro questa finestra | Drake et al. 2013, *J Clin Sleep Med* |
| Dose-risposta | 5 di 6 studi mostrano **24–114 minuti in meno** di sonno con dosi maggiori | systematic review/meta-analisi (ScienceDirect) |
| Emivita | Varia **2–10 ore** tra adulti sani — rende difficile fissare un orario di cutoff universale | review |
| Ipotesi "withdrawal reversal" | Il miglioramento cognitivo dopo caffeina in soggetti privati di sonno può essere in parte **reversione dell'astinenza** da caffeina abituale, non enhancement puro | letteratura classica (Rogers, James) |

**Chiusura operativa**: nessun arm di "raccomanda caffeina" — il rischio (sonno compromesso, quindi
danno alla sessione successiva) supera il beneficio incerto (parzialmente withdrawal reversal). Un
arm plausibile e a basso rischio: **avviso di cutoff orario personalizzato** ("evita caffeina nelle
prossime N ore se vuoi dormire bene stanotte"), con N calibrato su emivita media (6h) piuttosto che
fisso — feature informativa, non prescrittiva, coerente col vincolo anti-nocebo.

### 4.7 Esercizio acuto

| Fonte | Risultato | Fonte |
|---|---|---|
| Chang et al. 2012, meta-analisi | Minimo **11 minuti** di esercizio per produrre cambiamenti cognitivi misurabili; nessun miglioramento ≤10 min | meta-analisi |
| Finestra temporale ottimale | **15 minuti dopo** l'esercizio è la finestra ottimale per testare la performance cognitiva | idem |
| Curva durata-effetto | 11–20 min: effetti trascurabili/detrimentali; **>20 min: effetti benefici** | review meta-analitiche successive |
| Dominio più sensibile | Le **funzioni esecutive** mostrano benefici significativamente maggiori di altri domini (memoria, tempo di reazione semplice) | meta-review 2022/2024 |

**Chiusura operativa**: arm plausibile — "esercizio breve (>20 min) prima di una sessione di funzioni
esecutive/problem solving" — ma **non prima dell'encoding immediato di materiale nuovo** (effetto
misurato su performance esecutiva, non specificamente su consolidamento di memoria — non confondere i
due meccanismi). ⚠️ NON VERIFICATO in questa sessione: dati specifici su esercizio *dopo* l'encoding
per il consolidamento (richiesto da _RESUME.md ma non recuperato per budget).

### 4.8 Distrazione da smartphone

| Fonte | Risultato | Fonte |
|---|---|---|
| Ward et al. 2017, *J Assoc Consum Res* | Effetto originale: la mera presenza del proprio smartphone riduce la capacità cognitiva disponibile, anche mantenendo l'attenzione sostenuta | studio originale, alta citazione |
| Ruiz Pardo & Minda 2022, replica | **Nessuna differenza** tra condizioni di posizione dello smartphone su o-span task e go/no-go task — **la replica fallisce** | *Acta Psychologica* |
| Smartphone use vs rendimento accademico, meta-analisi | **r = −0.16** (95% CI [−0.20, −0.13]); mediana r = −0.143 su 63 studi | 63 studi, N = 124.166 studenti, 28 paesi |

**Lettura**: il meccanismo specifico "brain drain da mera presenza" **non regge** a replica
indipendente — va rimosso da qualunque narrazione di prodotto che lo citi come base causale. Resta
invece robusta, su campione enorme, la correlazione negativa **uso** (non presenza) telefono-rendimento
— r = −0.16 è piccolo (~2,6% di varianza spiegata) ma è su 124mila studenti, quindi difficilmente
rumore. È però **correlazionale**: non distingue se l'uso del telefono causa il calo o se studenti
con meno autoregolazione usano di più il telefono E vanno peggio (confondente plausibile e forte).

⚠️ NON VERIFICATO in questa sessione: RCT specifici su app blocker/digital self-control tools, costo
di recupero da task-switching (Mark et al.), media multitasking — non recuperati per budget, priorità
bassa nell'ordine richiesto ("il resto").

**Chiusura operativa**: arm "modo aereo intelligente" (già in handoff §8.12) resta plausibile ma
**non puoi giustificarlo con "brain drain da presenza"** (smentito) — giustificarlo solo con la
correlazione uso-rendimento e con l'assenza-telefono come segnale di deep work (§3.2 handoff), non con
un meccanismo neurocognitivo specifico.

### 4.9 Ambiente fisico

| Fattore | Risultato | Robustezza |
|---|---|---|
| **CO2** (Allen et al. 2016, Harvard) | Claim: −15% score cognitivo a 950 ppm, −50% a 1.400 ppm, N=24 | **Fortemente contestato**: uno studio danese (*Building & Environment*, feb 2016) non conferma alcun declino fino a 5.000 ppm; uno studio su sottomarinisti USA non trova declino a 2.500–15.000 ppm; la letteratura complessiva è definita "estremamente inconsistente" da più fonti indipendenti. Un'analisi critica nota che un effect size di quella grandezza dovrebbe essere visibile ovunque nella vita quotidiana (es. altitudine), il che non è osservato — **effect size implausibile** |
| **Musica di sottofondo** | Effetto **medio nullo** in aggregato (Kämpfe, Sedlmeier & Renkewitz 2011, meta-analisi) | Eterogeneità alta: musica con testo ha effetti **negativi** su concentrazione/lettura; musica preferita può aumentare il "task-focus" riducendo mind-wandering in alcuni task; niente di generalizzabile a "metti musica" o "non metterla" |
| **Rumore bianco** | Risultati misti, a volte la musica batte il rumore bianco, a volte no | Nessuna meta-analisi conclusiva recuperata |

**Chiusura operativa**: **escludere CO2 da qualunque claim di prodotto** — è l'esempio da manuale di
"effect size sospettosamente grande" che il brief chiedeva di verificare criticamente, e la verifica
lo conferma insostenibile. Per la musica: nessun arm "raccomanda musica" difendibile; al massimo un
arm neutro "silenzio vs la tua musica preferita, senza testo, se devi leggere/scrivere" — ma con
prior debolissimo e senza pretesa di beneficio oggettivo dimostrato.

⚠️ NON VERIFICATO in questa sessione (bassa priorità): temperatura, illuminazione, postura,
context-dependent memory, il consiglio di variare l'ambiente.

### 4.10 Sequenziamento intra-giornata / consolidamento

⚠️ NON VERIFICATO in questa sessione — argomento a priorità medio-bassa nell'ordine richiesto, non
raggiunto nel budget di ricerca. Nell'handoff restano da verificare: consolidamento sleep-dependent
(studiare prima di dormire), wakeful rest dopo l'encoding (Dewar et al.). Nessun dato nuovo, nessuna
contraddizione. Segnalato come lacuna in §7.

### 4.11 Nutrizione/idratazione/glicemia

⚠️ NON VERIFICATO in questa sessione — priorità più bassa dell'ordine richiesto, esplicitamente "solo
se l'evidenza regge, altrimenti dichiararla debole". Non essendo stata verificata, va trattata **come
debole per default** finché non recuperata: nessun arm da costruirci sopra allo stato attuale.

### 4.12 Flow e interruzione

⚠️ NON VERIFICATO in questa sessione (budget esaurito prima di raggiungere questo punto). La
decisione già presa dal team — nessuna interruzione mid-session, intervento spostato a inizio
sessione — **non è contraddetta da nulla emerso in questa ricerca**; anzi è coerente con l'assenza di
qualunque evidenza recuperata a favore di terminazioni prescritte mid-flow. Trattare come confermata
per assenza di controevidenza, non per verifica diretta.

---

## 5. Tabella arms candidati per il bandit con prior numerici {#5-arms}

| Arm | Effect size prior | Fonte | Randomizzabile? | Rischio nocebo/reattanza |
|---|---|---|---|---|
| Distributed practice (pianifica ripasso distanziato) | **d ≈ 0.7** (scontato da 0.85) | Donoghue & Hattie 2021 | Sì — quale intervallo suggerire | Basso |
| Retrieval practice con feedback | **d ≈ 0.6** (media Rowland/Adesope/D&H, pesata verso il feedback) | Rowland 2014; Adesope 2017; D&H 2021 | Sì — modalità richiamo vs restudio | Basso |
| Implementation intentions a inizio sessione | **d ≈ 0.55–0.65** | Gollwitzer & Sheeran 2006 | Sì — formato del prompt if-then | Basso (opt-in) |
| Interleaving per categoria di esercizio | **g ≈ 0.42–0.47** | Brunmair & Richter 2019; D&H 2021 | Sì — interleaved vs blocked, solo se tipo compito noto | Medio (percepito più difficile) |
| Worked example prima di pratica su materiale nuovo | **d ≈ 0.4–0.45**, condizionato a "nuovo materiale" dichiarato | meta-analisi worked examples | Sì — solo per "nuovo materiale" | Basso |
| Generazione di spiegazione a fine sessione | **g ≈ 0.5–0.55** | Fiorella & Mayer; self-explanation meta-analisi | Sì | Basso |
| Durata sessione suggerita (3–4 livelli) | nessun prior di letteratura forte — **prior piatto**, da stimare dal pilota | vigilance decrement/mind-wandering (nessuna soglia universale) | Sì — è l'arm per cui la letteratura NON dà un numero | — |
| Allocazione tipo-compito per fascia cronotipica | direzione qualitativa (fluid intelligence sincrona; problem solving creativo asincrono) | Wieth & Zacks 2011; synchrony reviews | Sì — quale tipo di compito in quale fascia | Basso (nessuna ora è "morta") |
| Cutoff caffeina personalizzato (avviso informativo) | −1,2h sonno indipendente da timing entro 0-6h prima; emivita 2–10h | Drake et al. 2013 | Sì — soglia oraria del promemoria | Molto basso (informativo, non prescrittivo) |
| "Modo aereo intelligente" durante sessione | nessun effect size diretto difendibile (brain drain da presenza smentito); solo r = −0.16 su uso | Ward 2017 (⚠️ non replica); meta-analisi uso-rendimento | Sì — on/off come arm | Medio (percepito intrusivo) |
| Esercizio breve pre-sessione per funzioni esecutive | nessun beneficio <11 min; beneficio dopo >20 min | Chang et al. 2012 | Sì — ma richiede compliance esterna all'app, difficile da randomizzare in pratica | Basso |
| Musica/silenzio durante sessione | **prior nullo** (effetto medio nullo in meta-analisi, alta eterogeneità) | Kämpfe et al. 2011 | Sì, ma senza pretesa di beneficio | Basso |
| Microbreak (framing benessere, non performance) | effetto su performance ≈ 0; su vigore/fatica percepita positivo | Albulescu et al. 2022 | Sì | Basso se il framing è onesto |

**Nota di lettura**: i prior sono in scala d/g "grezza" da letteratura eterogenea (compiti di
laboratorio, spesso brevi, spesso su materiale semplice). Il warm-start bayesiano del bandit deve
scontarli — non usarli come effect size atteso nel prodotto reale, ma come **ordine di priorità
relativo** tra arm e come punto di partenza del prior, da aggiornare rapidamente coi primi dati del
pilota (coerente con R4/§4 handoff sulla scala prior→coefficiente).

---

## 6. Miti da non implementare {#6-miti}

| Mito | Perché non implementarlo | Fonte che lo smonta |
|---|---|---|
| Pomodoro 25/5 come "la" cadenza ottimale | Non superiore a pause auto-regolate | (già in handoff, non ri-derivato qui) |
| Ritmo ultradiano 90 minuti | Nessun supporto empirico solido come regola prescrittiva | (già in handoff) |
| "Studia sempre alla tua ora migliore" (cronotipo) | Il synchrony effect vale per intelligenza fluida in lab, non per compiti creativi (dove vale l'**asynchrony** effect); l'evidenza su voti reali è confusa da endogeneità | Wieth & Zacks 2011; systematic review 2025 |
| CO2 come leva di performance in ambiente domestico | Letteratura internamente contraddittoria: Harvard (Allen 2016) vs studio danese vs submariners USA — nessun consenso, effect size originale implausibile | Yale Climate Connections; studio danese *Building & Environment* 2016; studio submariners |
| "Il tuo smartphone ti drena energia cognitiva anche spento sul tavolo" (brain drain) | Effetto originale (Ward et al. 2017) **non replica** (Ruiz Pardo & Minda 2022) | Ruiz Pardo & Minda 2022, *Acta Psychologica* |
| Musica di sottofondo come booster universale di concentrazione | Effetto medio nullo in meta-analisi; negativo con testo, specialmente durante lettura | Kämpfe, Sedlmeier & Renkewitz 2011 |
| Caffeina come enhancer cognitivo puro | Buona parte del beneficio osservato in soggetti privati di sonno è reversione dell'astinenza, non enhancement; costa sonno futuro indipendentemente dall'orario entro la finestra 0-6h | Drake et al. 2013; letteratura withdrawal reversal |
| Windred et al. 2024 come base per il readiness score | Riguarda la **mortalità**, non la cognizione — transfer di dominio invalido | (già corretto nell'handoff §2.3) |
| SAFTE-FAST/UMP/Three-Process per attenzione intra-task in soggetti riposati | Validati per vigilanza sotto privazione di sonno, non per questo caso d'uso | (già in handoff §2.3) |

---

## 7. Questioni aperte {#7-aperte}

1. **Recuperato in questa sessione, chiudibile**: breakdown Donoghue & Hattie 2021 per tecnica — d =
   0.85 distributed practice, d = 0.74 practice testing. Aggiornare handoff §2.1 e §10.7.
2. Cifra esatta di decadimento/eterogeneità dell'effetto implementation intentions
   nell'aggiornamento Sheeran, Listrom & Gollwitzer 2024 (642 test) — non recuperata, solo la
   direzione (dipende da formato/contesto).
3. Confronto quantitativo diretto implementation intentions vs mental contrasting/MCII (Oettingen) —
   non recuperato.
4. Effect size aggregato per la calibrazione metacognitiva (JOL) — nessuna meta-analisi con numero
   pulito recuperata in questa sessione; solo evidenza qualitativa convergente.
5. Durata ottimale pausa, pause attive vs passive, nap/sleep inertia, ART/natura, detachment
   psicologico — non ri-verificati in questa sessione (restano come nell'handoff/resume, nessuna
   novità né contraddizione).
6. Sequenziamento intra-giornata / consolidamento (studiare prima di dormire; wakeful rest, Dewar et
   al.) — non raggiunto per budget.
7. Nutrizione/idratazione/glicemia — non raggiunto, trattare come debole per default.
8. Flow e interruzione — non raggiunto, ma nessuna controevidenza alla scelta già presa dal team.
9. RCT su app blocker/digital self-control tools, costo di recupero da task-switching (Mark et al.),
   media multitasking — non raggiunti.
10. Effect size preciso del mismatch cronotipo-orario sul rendimento accademico — solo direzione
    qualitativa recuperata, non un numero aggregato.

---

## 8. Bibliografia {#8-biblio}

- Rowland, C. A. (2014). *The effect of testing versus restudy on retention: A meta-analytic review
  of the testing effect*. Psychological Bulletin, 140(6), 1432–1463.
  https://pubmed.ncbi.nlm.nih.gov/25150680/
- Adesope, O. O., Trevisan, D. A., & Sundararajan, N. (2017). *Rethinking the use of tests: A
  meta-analysis of practice testing*. Review of Educational Research, 87(3), 659–701.
  https://journals.sagepub.com/doi/10.3102/0034654316689306
- Donoghue, G. M., & Hattie, J. A. C. (2021). *A meta-analysis of ten learning techniques*. Frontiers
  in Education, 6, 581216. https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2021.581216/full
- Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T., & Rohrer, D. (2006). *Distributed practice in
  verbal recall tasks: A review and quantitative synthesis*. Psychological Bulletin.
  https://www.yorku.ca/ncepeda/publications/CPVWR2006.html
- Cepeda, N. J., Vul, E., Rohrer, D., Wixted, J. T., & Pashler, H. (2008). *Spacing effects in
  learning: A temporal ridgeline of optimal retention*. Psychological Science, 19(11), 1095–1102.
  https://journals.sagepub.com/doi/abs/10.1111/j.1467-9280.2008.02209.x
- Settles, B., & Meeder, B. (2016). *A Trainable Spaced Repetition Model for Language Learning*. ACL
  2016. https://github.com/duolingo/halflife-regression
- Gollwitzer, P. M., & Sheeran, P. (2006). *Implementation intentions and goal achievement: A
  meta-analysis of effects and processes*. Advances in Experimental Social Psychology, 38, 69–119.
  https://kops.uni-konstanz.de/handle/123456789/10973
- Sheeran, P., Listrom, T., & Gollwitzer, P. M. (2024). Aggiornamento meta-analitico implementation
  intentions, 642 test indipendenti. ⚠️ citazione da verificare (non recuperato DOI in questa
  sessione).
- Brunmair, M., & Richter, T. (2019). *Similarity matters: A meta-analysis of interleaved learning
  and its moderators*. https://www.researchgate.net/publication/335004545
- Rohrer, D., Dedrick, R. F., & Stershic, S. (2015). *Interleaved practice improves mathematics
  learning*. https://gwern.net/doc/psychology/spaced-repetition/2019-rohrer.pdf
- Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T. (2013). *Improving
  students' learning with effective learning techniques*. Psychological Science in the Public
  Interest, 14(1), 4–58. https://journals.sagepub.com/doi/abs/10.1177/1529100612453266
- Fiorella, L., & Mayer, R. E. (2015). *Eight ways to promote generative learning*.
  https://bootcampmilitaryfitnessinstitute.com/wp-content/uploads/2016/01/eight-ways-to-promote-generative-learning-fiorella-mayer-2015.pdf
- Meta-analisi worked examples in matematica (43 articoli/55 studi/181 effetti, g=0.48).
  https://link.springer.com/article/10.1007/s10648-023-09745-1
- Wisniewski, B., Zierer, K., & Hattie, J. (2020). *The Power of Feedback Revisited: A Meta-Analysis
  of Educational Feedback Research*. Frontiers in Psychology, 10, 3087.
  https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6987456/
- Wieth, M. B., & Zacks, R. T. (2011). *Time of day effects on problem solving: When the non-optimal
  is optimal*. Thinking & Reasoning, 17(4). https://www.tandfonline.com/doi/abs/10.1080/13546783.2011.625663
- Chronotype and synchrony effects in human cognitive performance: A systematic review (2025).
  Chronobiology International. https://www.tandfonline.com/doi/full/10.1080/07420528.2025.2490495
- Okano, K., Kaczmarzyk, J. R., Dave, N., Gabrieli, J. D. E., & Grossman, J. C. (2019). *Sleep
  quality, duration, and consistency are associated with better academic performance in college
  students*. npj Science of Learning, 4, 16. https://www.nature.com/articles/s41539-019-0055-z
- Drake, C., Roehrs, T., Shambroom, J., & Roth, T. (2013). *Caffeine effects on sleep taken 0, 3, or
  6 hours before going to bed*. Journal of Clinical Sleep Medicine.
  https://www.researchgate.net/publication/258530636
- Chang, Y. K., Labban, J. D., Gapin, J. I., & Etnier, J. L. (2012). *The effects of acute exercise
  on cognitive performance: A meta-analysis*. Brain Research.
  https://libres.uncg.edu/ir/uncg/f/J_Labban_Effects_2012.pdf
- Ward, A. F., Duke, K., Gneezy, A., & Bos, M. W. (2017). *Brain Drain: The Mere Presence of One's
  Own Smartphone Reduces Available Cognitive Capacity*. Journal of the Association for Consumer
  Research, 2(2). https://www.researchgate.net/publication/315966604
- Ruiz Pardo, D., & Minda, J. P. (2022). *Reexamining the "brain drain" effect: A replication of Ward
  et al. (2017)*. Acta Psychologica. https://pubmed.ncbi.nlm.nih.gov/36007374/
- Meta-analisi uso smartphone e rendimento accademico (63 studi, N=124.166, r=−0.16).
  https://www.sciencedirect.com/science/article/pii/S0001691825006870
- Allen, J. G., et al. (2016). *Associations of Cognitive Function Scores with Carbon Dioxide,
  Ventilation, and Volatile Organic Compound Exposures in Office Workers*. Environmental Health
  Perspectives. https://pmc.ncbi.nlm.nih.gov/articles/PMC4892924/
- Critica/non-replica CO2: Yale Climate Connections (2016), "Indoor CO2: Dumb and dumber?".
  https://yaleclimateconnections.org/2016/07/indoor-co2-dumb-and-dumber/
- Kämpfe, J., Sedlmeier, P., & Renkewitz, F. (2011). *The impact of background music on adult
  listeners: A meta-analysis*. Psychology of Music.
  https://journals.sagepub.com/doi/10.1177/0305735610376261
- Albulescu, P., et al. (2022). *"Give me a break!" A systematic review and meta-analysis on the
  efficacy of micro-breaks*. PLOS ONE, 17(8), e0272460. (già in handoff, non ri-derivato)

---

**Stato finale**: report completo su tutte le sezioni con priorità alta/media (§3.1–3.10,
§4.1–4.9); sezioni a priorità bassa (§4.10–4.12) lasciate come lacune esplicite marcate ⚠️ per
rispetto del budget di ricerca (24 ricerche web, 1 WebFetch usati). Nessuna contraddizione rilevata
rispetto alle decisioni già prese dal team; una correzione fattuale maggiore (§3.2, breakdown
Donoghue & Hattie); due miti aggiuntivi confermati smontati (CO2, brain drain da presenza) oltre a
quelli già noti.
