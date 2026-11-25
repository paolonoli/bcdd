# La grammatica del BCDD, versione 1.0-beta

<!-- SPDX-License-Identifier: CC-BY-4.0 -->
*Copyright 2026 Noli Paolo. Documento distribuito con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it).*

**BCDD** = *Behavioural Contract-Driven Design* · **CSC** = *Capability State Contract*

**Stato**: versione 1.0-beta. Descrive la forma dei file `.csc` che il programma `bcdd` legge, gli errori che
segnala, il rapporto di `bcdd check` e l'uso dei comandi `check`, `new` e `ratify`.

## Che cosa contiene questo documento

Il documento definisce la sintassi delle CSC accettata da `bcdd`: `bcdd` accetta, rifiuta e riferisce
esattamente ciò che è scritto qui. Il documento non descrive come il programma è realizzato.

Le sezioni 1-7 definiscono ciò che `bcdd` sa leggere (la 4.9 le entità, la 4.10 le varianti e le parti
facoltative, la 4.11 le forme concrete, il piano di prova, i profili e le estensioni, la 4.12 le formule, la 4.13
i nomi e i tipi, la 4.14 l'uso delle estensioni); la sezione 8 elenca gli errori; la sezione 9 descrive il
rapporto di `bcdd check`, carattere per carattere (la 9.4 le entità e le citazioni, la 9.5 le composizioni, la 9.6
le forme concrete e il piano di prova, la 9.7 le voci da giudicare e i controlli non eseguiti); le sezioni 10, 11 e
12 descrivono i comandi `check`, `new` e `ratify`; la sezione 13 descrive il file del dialogo; la sezione 14 elenca
ciò che `bcdd` non controlla.

Il linguaggio, con i suoi esempi, è presentato nel *Manuale del BCDD*; questo documento ne usa i termini (il
glossario è l'appendice C del manuale). `bcdd` legge tutte le forme del linguaggio descritte nel manuale: le
formule, le abbreviazioni, le forme concrete, il piano di prova, i profili e le estensioni. Ne controlla la forma,
i nomi e i tipi; non valuta le formule sulle storie e non le confronta fra loro (sezioni 9.7 e 14).

**I termini.** I nomi dei concetti sono quelli del manuale: *promessa* (`GUARANTEE`), *presupposto* (`ASSUME`),
*richiesta* (`CAPABILITY`), *storia* (`SCENARIO`), *elenco di valori* (un tipo `TYPE … := { … }`), *costante con
nome* (`DEFINE`), *numero non deciso* (`UNDECIDED`), *nome breve* (il nome di una promessa, di un presupposto o di
una storia), *da approvare* (`STATUS HYPOTHESIS`), *approvata* (`STATUS RATIFIED BY`), *elenco delle parti*
(`COMPOSED OF`), *copia* di una parte, *gruppo di scelte* (le righe `VARIANT` con lo stesso nome a sinistra di
`=`). Il rapporto e i messaggi di `bcdd` usano alcune parole diverse, che restano scritte come il programma le
stampa: «IPOTESI, NON CONTRATTO» per le righe da approvare, «contratto» per una riga approvata, «ratificare» per
approvare, «connettore» per una CSC citata da un'entità, «dimensione» per un gruppo di scelte. *Contratto* è
l'insieme delle promesse e dei presupposti approvati su un confine. Per i costrutti dei capitoli 21-27 del manuale
valgono gli stessi termini: *formula*, *condizione sul passo*, *innesco*, *conseguenza*, *ambito*, *abbreviazione*,
*forma estesa*, *forma concreta* (`BINDING`), *piano di prova* (`VERIFICATION`), *mezzo di registrazione*
(`MEANS`), *risoluzione*, *profilo*, *estensione*, *estensione dichiarata*. I nomi dei controlli (C1…C8), delle
regole sulle estensioni (E1…E7) e sui dettagli (D1…D6) sono quelli della specifica del linguaggio: compaiono qui
per dire che cosa `bcdd` esegue, e nel rapporto sono descritti a parole.

**Dichiarazione.** In questo documento *dichiarazione* indica ogni unità del file che comincia con una parola
chiave all'inizio di una riga e prosegue fino alla dichiarazione successiva (sezione 3): una promessa, un
presupposto, una storia, un passo, l'intestazione di un blocco, una riga `OFFERS`, e così via. Il manuale usa
la parola in un senso più ristretto, per le sole righe che dichiarano un elemento della CSC (`TYPE`,
`CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `SCENARIO`).

---

## 0. In breve

- Un file `.csc` è testo UTF-8, diviso in righe.
- Il file contiene blocchi `CSC … END` ed `ENTITY … END`. Un blocco `REFINEMENT VIEW … END`, forma uscita dal
  linguaggio, è l'errore E15 e le sue righe non sono riconosciute (sezione 4.8).
  Una CSC descrive un confine; un'entità dice quali CSC offre (`OFFERS`), quali usa (`USES`) e di quali altre
  entità è fatta, anche con quante copie, e non dice mai dove si trova (sezione 4.9). Un'entità ha storie, che
  nominano gli elementi delle sue CSC con i nomi qualificati `Csc.nome` (sezione 4.6). Un'entità può scrivere
  pezzi `VARIANT gruppo = scelta` e parti facoltative `[0 .. n]`: vale allora per ciascuna delle sue
  **composizioni**, e `check` le controlla tutte (sezione 4.10).
- Il file può contenere anche le forme concrete di un confine (`BINDING … END`), il piano di prova
  (`VERIFICATION … END`) e i profili (`PROFILE … END`), che contengono le estensioni (`EXTENSION … END`). `bcdd`
  li legge e li controlla sui nomi della CSC a cui sono legati (sezione 4.11).
- Dentro un blocco ogni dichiarazione comincia **all'inizio di una riga** con una parola chiave in
  inglese, scritta in maiuscolo: `PURPOSE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`,
  `ASSUME`, `SCENARIO`, … Una dichiarazione rimasta aperta, per esempio con una parentesi non chiusa o con un
  `AND` in fondo, continua sulla riga successiva (sezione 3).
- `bcdd` legge le promesse scritte **a parole** (`VERBAL`) e quelle scritte **come formule** (`WHENEVER … THEN
  …`, `ALWAYS …`, le abbreviazioni e le estensioni dei profili importati). Di una formula controlla la forma, i nomi
  e i tipi (sezioni 4.12-4.14); non la valuta sulle storie. Il grado di ogni promessa (verbale, formale,
  estensione dichiarata) si legge dalla sua forma (sezione 6).
- Ogni riga del file finisce in uno e un solo posto: riconosciuta, commento, vuota o non riconosciuta. Nessuna riga
  si perde, e nessuna riga non riconosciuta è taciuta.
- Una riga non riconosciuta **non è un errore**. Gli errori sono quaranta (E01 … E40), elencati nella sezione 8.
- Ciò che solo una persona può decidere (per esempio se un dettaglio a parole è coerente con la promessa che
  dettaglia) è elencato nella sezione «da giudicare» del rapporto, e i controlli che `bcdd` non esegue sulle
  formule sono dichiarati «non eseguiti» (sezione 9.7). Né le une né gli altri sono errori.
- `check` cerca le CSC e le entità che le entità del file citano, i profili importati e la CSC a cui è legato
  un `BINDING` o una `VERIFICATION` (nello stesso file, nella sua cartella, nelle cartelle `--dir`) e dice dove li
  ha trovati; una citazione che manca, o un file citato con errori, non cambia l'esito. Dentro un'entità fatta di parti, una CSC che una parte usa e che nessuno offre è
  l'errore E14 (sezione 9.4).
- Una promessa o un presupposto deve dire come si verifica: `VERBAL "…"` senza `VERIFY` è l'errore E13.
- Con l'opzione `--strict` (sezione 10) un file che ha anche una sola riga non riconosciuta fa uscire
  `bcdd check` con il codice 3. Senza l'opzione, una riga non riconosciuta non cambia il codice; la riga
  `esito` la conta comunque (sezione 9.2).
- Ogni `GUARANTEE` e `ASSUME`, ogni dettaglio di `DEFINE` o di `SCENARIO`, ogni riga `BIND` e ogni profilo è
  **approvato** o **da approvare** (sezione 7.1). Solo `bcdd ratify` approva, e solo in un file che `check
  --strict` accetta (sezione 12). Un piano di prova non si approva mai.
- `check` accetta `DETAILS` a qualunque profondità; è `refine` che si ferma al secondo livello (sezione 7.3).

---

## 1. Il file

| Che cosa | Regola |
|---|---|
| Estensione | `.csc`. `bcdd new` crea sempre un file `.csc`; `bcdd check` legge un file di qualunque nome |
| Codifica | UTF-8. Un byte che non è UTF-8 valido ferma il controllo (sezione 10) |
| Segno BOM | i tre byte `EF BB BF` in testa al file, se ci sono, si ignorano |
| Fine riga | il carattere LF. Un carattere CR subito prima di LF si ignora (file scritti su Windows) |
| Righe | si contano da 1. L'ultima riga conta anche se non finisce con LF. Un file vuoto ha 0 righe |
| Spazi | sono spazi solo lo spazio e il tabulatore. Ogni altro carattere invisibile (per esempio lo spazio non separabile) è un carattere estraneo |

---

## 2. Le parole del file

Il testo si divide in **elementi**, come le parole di una frase. Gli spazi separano gli elementi e non
contano altro: l'allineamento in colonne è libero.

### 2.1 Notazione delle regole

Le regole sono scritte nella notazione EBNF (*Extended Backus-Naur Form*), che si legge così:

| Scrittura | Significato |
|---|---|
| `A = B C ;` | A è fatto di B seguito da C |
| `"CSC"` | la parola da scrivere esattamente così, con le stesse maiuscole |
| `[ x ]` | x si può omettere |
| `{ x }` | x zero, una o più volte |
| `x \| y` | x oppure y |
| `( … )` | raggruppa |

### 2.2 Regole delle parole

| N. | Regola | Esempio |
|---|---|---|
| L1 | **Commento**: da `--` alla fine della riga, se `--` non è dentro una stringa. Il commento non conta | `EVENT IN arrivo   -- dal pulsante` |
| L2 | **Stringa**: da `"` al `"` successivo. Può andare a capo e continuare per più righe. Non ha sequenze di escape: una stringa non può contenere `"`. Dentro una stringa niente è una parola chiave e niente è un commento | `"Una pressione accende la luce"` |
| L3 | **Parola**: comincia con una lettera (di qualunque alfabeto, anche accentata) o con `_`; continua con lettere, segni diacritici, cifre da 0 a 9, `_`, e con `-` solo se fra due di questi caratteri | `intensità`, `g-n1`, `ATTESA_MAX_LLM` |
| L4 | **Numero puntato**: un `-` facoltativo, **attaccato** alla prima cifra; poi cifre da 0 a 9, eventualmente divise da punti, ciascuno fra due cifre. Il `-` è del numero solo se il carattere prima non è una lettera, un segno diacritico, una cifra o `_` (altrimenti vale L3: `g-1` resta una parola) e se non è l'inizio di `--` (commento, L1) | `180`, `0.5`, `0.1.2`, `-20.0`, `-40` |
| L5 | **Segni**: `:=` `..` `(` `)` `,` `:` `=` `[` `]` `@` `.` `{` `}`, e i segni delle formule `<` `<=` `>` `>=` `<>` `+` `-` `*` `/` `^` `->` `;`. Si prende sempre il segno più lungo: `:=`, `..`, `<=`, `>=`, `<>` e `->` sono un segno solo; `.` è un segno solo quando non è seguito da un altro `.` e non è dentro un numero puntato (L4). Il `-` è il segno meno solo quando non è l'inizio di un commento (L1), non sta dentro una parola (L3), non appartiene a un numero (L4) e non è l'inizio di `->` | `DEFINE D := 3`, `Sessione.pronta`, `{L, R}`, `a - b`, `x <= 1.0` |
| L6 | **Carattere estraneo**: ogni altro carattere fuori da stringhe e commenti (per esempio `→`, `±`, `≤`, `$`, `%`). Non è un errore: rende non riconosciuta la dichiarazione che lo contiene | `±`, `→` |

**Esempi di lettura.** `g-1` è una parola (L3); `--20` è un commento (L1); in `x=-3` dopo `=` c'è il numero
`-3`, perché `=` non è una lettera; `- 3` è il segno meno e poi il numero `3`; `a - b` è la parola `a`, il segno
meno e la parola `b`, mentre `a-b` è una parola sola (L3) e `a -3` è la parola `a` seguita dal numero `-3`, senza
segno fra i due; `5-3` sono il numero `5`, il segno meno e il numero `3`, perché il `-` dopo una cifra non
appartiene al numero (L4); `-x` è il segno meno e la parola `x`; `A->B` sono `A`, `->` e `B`; `0.5` è un numero;
`a.b` sono tre elementi (`a`, `.`, `b`); `Sessione . pronta` sono gli stessi tre elementi di `Sessione.pronta`,
perché gli spazi non contano; `x.5` sono tre elementi (`x`, `.`, `5`) che nessuna regola accetta. Per leggere un
meno fra due valori senza dubbi lo si scrive staccato da entrambi: `a - b`, `x - 3`.

Le lettere si confrontano così come sono scritte: `città` scritta con la «à» composta e `città` scritta
con «a» più accento separato sono due nomi diversi. Maiuscole e minuscole contano: `Check` e `check`
sono nomi diversi, e `guarantee` non è la parola chiave `GUARANTEE`.

### 2.3 Parole chiave e parole riservate

Le **parole chiave** sono in inglese. Sono le parole che `bcdd` legge, divise qui per uso.

Le parole della CSC, dell'entità, dei blocchi e dell'intestazione:

```
CSC VERSION END STATUS HYPOTHESIS RATIFIED BY PURPOSE CAPABILITY AUTONOMOUS
EVENT IN OUT STATE INITIAL DEFINE UNDECIDED GUARANTEE ASSUME DETAILS VERBAL VERIFY
JUDGEMENT INSPECTION SCENARIO GIVEN EXPECT ADMITTED REJECTED COMPOSED OF
TYPE ENTITY OFFERS USES VARIANT
IMPORT PROFILE BINDING VERIFICATION EXTENSION
```

le parole delle formule e delle storie (sezioni 4.6 e 4.12), con il tipo `Record` (sezione 4.4):

```
WHILE ALWAYS EVENTUALLY WHENEVER THEN WITHIN AT ONCE REPEAT FOREVER EVERY
AND OR NOT IMPLIES IF ELSE COUNT LAST TIME SINCE PREV WITH ABSENT PRESENT Record
```

le parole delle abbreviazioni e le funzioni matematiche (sezione 4.12):

```
NEVER AFTER BEFORE BETWEEN UNTIL PRECEDES FOR LEAST ACCEPTS ONLY REQUIRES ENSURES RESOLVES
CHANGED TRANSITION ON WHEN FOLLOWS ALL
ABS MIN MAX LOG10 ROUND FLOOR CEIL
```

i campi di un'estensione, i valori del campo `KIND` e le categorie dei parametri (sezione 4.11):

```
KIND LEVEL PARAMS FORM MEANING REDUCES TO SOURCE
PATTERN SCOPE FUNCTION DECLARATION RELATION SCENARIO-FORM
Name Type Event Condition Expression Duration Property
```

le parole delle forme concrete e del piano di prova (sezione 4.11):

```
BIND AS MEANS OBSERVES RESOLUTION USING TRANSLATES
```

I valori del campo `LEVEL` (`CSC`, `ENTITY`, `BINDING`, `VERIFICATION`) sono già parole chiave. `Duration` è
anche il nome di un tipo di base (sezione 4.4) e, nel campo `PARAMS`, la categoria con lo stesso significato.
`SCENARIO-FORM` è una parola sola (L3) con un `-`: come Nome non si potrebbe scrivere comunque (L7); la riserva
esclude anche il nome breve `SCENARIO-FORM` (L8).

Sono **riservate**, senza essere lette, le parole di due forme che il linguaggio tiene per il futuro (`REFINED BY`,
che dirà su quali promesse delle parti si regge una promessa d'entità, e `REFINES`, la relazione fra due versioni di
una CSC):

```
REFINED REFINES
```

Sono **riservate perché uscite dal linguaggio**:

```
FACE LINK MAP REFINEMENT VIEW
```

Sono riservate anche, in minuscolo: `true false requested accepted rejected completed failed _`.

In tutto le parole chiave e le parole riservate sono **136**.

Una parola chiave o riservata non può essere un nome. Una riga che la usa come nome non è riconosciuta. Fanno
eccezione le dichiarazioni che cominciano con `REFINEMENT`: sono l'errore E15 (sezione 4.8).

**Una sola lista.** Le parole chiave e le parole riservate di questa sezione sono le stesse per `check`, `new`
(regola L7, sezione 11), `ratify` (nome breve e nome dopo `--csc`, sezione 12.5) e `refine` (nomi e nomi brevi
delle proposte): nessun comando ne ha un elenco suo.

**Che cosa non è riservato**, e perché:
- `V1`, `V2` e `C1` … `C8` si leggono soltanto nel campo `VERIFY` di un'estensione (sezione 4.11), dove la loro
  posizione basta a riconoscerle; altrove sono nomi validi (`STATE C1 : Boolean INITIAL false` è riconosciuta);
- i nomi delle estensioni dei profili (`SIGNAL`, `CONTINUOUS`, `STABILIZES`, `GRACE`, …): un profilo non importato
  non aggiunge parole, e in un blocco che lo importa il nome di un'estensione si riconosce dalla sua posizione
  (sezione 4.14);
- le unità (`ms`, `s`) e le parole `Boolean`, `String`, `Integer`, `Real`, `Sequence`, `of`, `Optional`, che
  nella posizione di un tipo hanno il significato della sezione 4.4. Come nome di un tipo dichiarato non valgono
  (G15, G30, G37, G41).

**Perché si riservano anche le parole che il programma legge in un solo posto.** Una richiesta che si chiamasse
`ENSURES` o uno stato che si chiamasse `LEVEL` darebbero alla stessa parola due significati nello stesso file. Il
minuscolo resta libero (sezione 2.2): `pattern` e `level` sono nomi validi.

**Perché `FACE`, `LINK`, `MAP`, `REFINEMENT` e `VIEW` restano riservate.** Sono forme uscite dal linguaggio,
sostituite dalle CSC e dalle entità. Restano riservate per evitare confusione: chi conosce le forme ritirate le
legge con il vecchio significato, e un nome libero `MAP` in una CSC sembrerebbe la relazione `MAP` ritirata.
Una parola ritirata resta riservata per sempre: liberarla non darebbe alcun vantaggio, e non si potrebbe più
riservarla senza invalidare CSC.

### 2.4 I nomi

| N. | Regola | Esempio valido | Esempio non valido |
|---|---|---|---|
| L7 | **Nome** = una parola senza `-`, che non sia riservata | `pressione`, `Città`, `ATTESA_MAX_LLM` | `g-n1` (ha `-`), `END` |
| L8 | **Id** (il nome breve di promesse, presupposti e storie) = una parola che non sia riservata; può contenere `-` | `g-n1`, `f-1`, `g1a` | `g-` (finisce con `-`) |
| L9 | **Decisione** (il riferimento della decisione) = una parola fatta di `D-` seguito da sole cifre | `D-125` | `D125`, `operatore`, `D-12a` |
| L10 | **Versione** = un numero puntato senza `-` | `0.1`, `1`, `0.1.2` | `v1`, `-0.1` |
| L11 | **Numero** = un numero puntato con al più un punto, senza `-` | `180`, `0.5` | `0.1.2`, `-3` |
| L12 | **Numero con segno** = un numero puntato con al più un punto, con o senza `-` | `-20.0`, `3`, `0.5` | `-0.1.2` |
| L13 | **Intero** = un numero puntato senza punti e senza `-` | `1`, `4` | `1.5`, `-1` |

Dove serve il segno lo dice la regola: solo L12 lo ammette, nei limiti di un intervallo (G14), nei valori (G26) e
nelle formule (G59), dove il meno davanti a un valore si scrive anche staccato (`- x`). Le versioni, i tempi dei
passi (G21: `@-1` non è un passo), i limiti di una molteplicità (G35) e di una ripetizione (G47) e le risoluzioni
(G52) restano senza segno.

---

## 3. Come il file si divide in dichiarazioni

Questa regola decide **a quale dichiarazione appartiene ogni riga**. È la regola più importante per il
conteggio delle righe.

| N. | Regola |
|---|---|
| U1 | Una riga che contiene solo spazi è **vuota**; una riga che contiene solo un commento è un **commento**. Righe vuote e commenti non appartengono a nessuna dichiarazione e non la interrompono |
| U2 | Ogni altra riga che **non comincia dentro una stringa** apre una **dichiarazione nuova**, salvo il caso U4 |
| U3 | Una riga che comincia dentro una stringa aperta su una riga precedente appartiene alla dichiarazione di quella stringa, anche se è vuota o contiene `--` |
| U4 | Una riga che comincia con `VERIFY` o con `VERBAL` continua la dichiarazione precedente **se quella comincia con `GUARANTEE` o `ASSUME`**; altrimenti apre una dichiarazione nuova, che è riconosciuta solo come campo `VERIFY` di un'estensione (sezione 4.11) |
| U5 | Una riga che non comincia dentro una stringa continua la dichiarazione precedente se questa è rimasta **aperta**: (a) ha una parentesi `(`, `[` o `{` non chiusa, oppure (b) il suo ultimo elemento, senza il commento, chiede un seguito: uno dei segni `:` `,` `:=` `=` `<>` `<` `<=` `>` `>=` `+` `-` `*` `/` `^` `->` `;`, oppure una delle parole `THEN` `WITHIN` `AND` `OR` `IMPLIES` `NOT` `IN`. Fa eccezione una riga il cui primo elemento è `@`, `END` o una parola che apre una dichiarazione nella sezione 5 (per esempio `GUARANTEE`, `SCENARIO`, `BIND`, `KIND`, `REPEAT`): quella apre sempre una dichiarazione nuova. Righe vuote e commenti fra le due righe non interrompono la continuazione (U1) |

La prima parola di una dichiarazione ne dice il tipo. Una parola chiave che non è la prima della riga
non apre nulla: fa parte della dichiarazione in corso.

Esempio, con le righe numerate:

```
 1  GUARANTEE g1: VERBAL "Una pressione
 2                       accende la luce"          ← U3: dentro la stringa
 3  -- nota                                         ← U1: commento, non interrompe
 4                VERIFY BY JUDGEMENT "l'operatore" ← U4: continua g1
 5  questa riga è inventata                         ← U2: dichiarazione nuova
```

Le righe 1, 2 e 4 sono una sola dichiarazione.

**La continuazione (U5).** Le parole che aprono sempre una dichiarazione, e quindi non continuano mai quella
precedente, sono: `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`, `EXTENSION`, `END`, `STATUS`,
`IMPORT`, `PURPOSE`, `TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`, `ASSUME`, `SCENARIO`, `REPEAT`,
`OFFERS`, `USES`, `COMPOSED`, `VARIANT`, `BIND`, `MEANS`, `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES`,
`SOURCE`, e il segno `@`. Così una parentesi dimenticata o un operatore lasciato in fondo non fanno sparire una
dichiarazione successiva né l'`END` di un blocco: la riga che li contiene resta quella che è, e il resto del file si
legge come prima. `VERIFY` e `VERBAL` seguono U4.

```
 1  GUARANTEE g2: WHENEVER pressione THEN        ← finisce con THEN: resta aperta
 2                  accesa WITHIN 1 s            ← U5: continua g2
 3  GUARANTEE g3: WHENEVER pressione             ← non chiede un seguito
 4                  THEN accesa WITHIN 1 s       ← U2: dichiarazione nuova, non riconosciuta
 5  GUARANTEE g4: ALWAYS (accesa AND             ← parentesi aperta
 6  END                                          ← END: apre una dichiarazione nuova; g4 non è riconosciuta
```

Le righe 1 e 2 sono una sola dichiarazione, riconosciuta; la riga 4 è una dichiarazione a sé, non riconosciuta, e
lascia non riconosciuta anche la 3; la riga 6 chiude il blocco.

Una dichiarazione **riconosciuta** rende riconosciute tutte le sue righe; una dichiarazione **non
riconosciuta** rende non riconosciute tutte le sue righe.

---

## 4. La grammatica delle dichiarazioni

Ogni regola descrive una dichiarazione intera, dalla prima parola all'ultima, anche se va su più righe.
Una dichiarazione è riconosciuta solo se **tutti** i suoi elementi rispettano la regola, senza niente in
più.

### 4.1 Blocchi

| N. | Regola | Esempio |
|---|---|---|
| G1 | `IntestazioneCsc = "CSC" Nome "VERSION" Versione ;` | `CSC LuceScale VERSION 0.1` |
| G2 | `IntestazioneVista = "REFINEMENT" "VIEW" Nome ;` non è una dichiarazione del linguaggio: serve solo a leggere il nome del blocco ritirato nel rapporto (sezione 4.8) | `REFINEMENT VIEW LuceParti` |
| G3 | `Fine = "END" ;` | `END` |

Il blocco `ENTITY` ha la sua intestazione G31 (sezione 4.9); i blocchi `BINDING`, `VERIFICATION`, `PROFILE` ed
`EXTENSION` hanno le intestazioni G40, G48, G49 e G50 (sezione 4.11). Tutti finiscono con G3.

### 4.2 Intestazione della CSC

| N. | Regola | Esempio |
|---|---|---|
| G4 | `StatoCsc = "STATUS" Stato ;` | `STATUS RATIFIED BY D-125` |
| G5 | `Stato = "HYPOTHESIS" \| "RATIFIED" "BY" Decisione ;` | `HYPOTHESIS` |
| G6 | `Scopo = "PURPOSE" Stringa ;` | `PURPOSE "Accende la luce delle scale"` |
| G39 | `ImportaProfilo = "IMPORT" "PROFILE" Nome "VERSION" Versione ;` | `IMPORT PROFILE Segnale VERSION 0.3` |

**Le righe d'intestazione.** In una CSC la **zona d'intestazione** va dalla riga `CSC` alla prima dichiarazione che
non comincia con `STATUS`, `IMPORT` o `PURPOSE` (commenti e righe vuote non contano). Lì `STATUS` (G4), `IMPORT
PROFILE` (G39) e `PURPOSE` (G6) stanno **in qualunque ordine**:

- `STATUS` è riconosciuto in qualunque punto della zona; un secondo `STATUS` riconosciuto nella zona è l'errore
  **E10** (`STATUS ripetuto: il primo è alla riga N`, sezione 8), e lo stato della CSC è quello del primo. Dopo la
  zona `STATUS` non è riconosciuto;
- `IMPORT PROFILE` è riconosciuto solo nella zona, zero o più volte; dopo la zona non è riconosciuto. Senza
  `VERSION`, o con una versione che non rispetta L10, non è riconosciuto. La versione è obbligatoria perché
  allentare la regola in seguito non invaliderà nessun file, mentre stringerla sì;
- `PURPOSE` è esattamente uno per CSC, in qualunque punto del blocco (E10 se manca o è ripetuto);
- una dichiarazione che comincia con `STATUS`, `IMPORT` o `PURPOSE` ma non è riconosciuta (`STATUS PIPPO`, `IMPORT
  PROFILE Segnale` senza versione) resta non riconosciuta e **non chiude** la zona: una riga scritta male non toglie
  il posto a quelle che seguono;
- una dichiarazione che apre un blocco (`CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`) chiude la
  CSC con E07 (sezione 5), e con lei la zona.

**La stessa zona negli altri blocchi.** Ogni blocco importa i profili per sé. La zona d'intestazione, con le stesse
regole, c'è anche in un'entità (`STATUS HYPOTHESIS`, `IMPORT PROFILE`, `PURPOSE`; sezione 4.9), in un `BINDING`
(`STATUS`, `IMPORT PROFILE`), in una `VERIFICATION` (`IMPORT PROFILE`; uno `STATUS` è l'errore E39) e in un `PROFILE`
(`STATUS`, `PURPOSE`; `IMPORT PROFILE` vi è non riconosciuto, perché un profilo non importa altri profili). Le
regole dei blocchi `BINDING`, `VERIFICATION` e `PROFILE` sono nella sezione 4.11.

**Il profilo importato.** `IMPORT PROFILE P VERSION v` è una **citazione**: `bcdd` cerca il blocco `PROFILE P` come
cerca una CSC citata (sezione 9.4), e lo trova solo con la versione `v` scritta (stesso testo). Un profilo trovato
con un'altra versione non è trovato: il rapporto lo elenca nella sezione 7, con la versione trovata. Del profilo
trovato `bcdd` legge le estensioni (sezione 4.14). Due righe che importano lo stesso profilo con la stessa versione
non sono un errore e valgono come una; due righe dello stesso blocco che importano lo stesso profilo con versioni
diverse non sono riconosciute, la seconda nell'ordine del file, perché lo stesso nome di estensione avrebbe due
significati. La riga non registra nessun nome nell'elenco dei nomi del blocco.

Un'eccezione voluta a G5: `STATUS RATIFIED` seguito da qualunque altra cosa che non sia `BY` e una
Decisione (fino ai due punti in una riga contrattuale, fino alla fine nell'intestazione) **è
riconosciuto**, con l'errore E04. Un'approvazione scritta male non deve sparire fra le righe non
riconosciute: è proprio l'errore che il controllo deve mostrare. `STATUS` seguito da una parola diversa
da `HYPOTHESIS` e `RATIFIED` invece non è riconosciuto.

### 4.3 Ingressi, uscite, stati, costanti

| N. | Regola | Esempio |
|---|---|---|
| G7 | `Capacita = "CAPABILITY" Nome [ Parametri ] [ "AUTONOMOUS" ] ;` | `CAPABILITY Check(file: String)` |
| G8 | `Evento = "EVENT" ( "IN" \| "OUT" ) Nome [ Parametri ] ;` | `EVENT IN pressione` |
| G9 | `Parametri = "(" [ Parametro { "," Parametro } ] ")" ;` | `(file: String, riga: Optional String)` |
| G10 | `Parametro = Nome ":" Tipo ;` | `accettata: Boolean` |
| G11 | `StatoOsservabile = "STATE" Nome ":" Tipo "INITIAL" Valore [ "FOLLOWS" Nome "." Nome ] \| "STATE" Nome "[" Nome "]" ":" Tipo "INITIAL" Valore ;` | `STATE accesa : Boolean INITIAL false`, `STATE clipCount[Ch] : Integer [0 ..] INITIAL 0`, `STATE volume : Integer [0 .. 100] INITIAL 50 FOLLOWS imposta.livello` |
| G12 | `Definizione = "DEFINE" Nome [ ParametriDefine ] [ "DETAILS" Id [ "STATUS" Stato ] ] ":=" ( "UNDECIDED" \| Espr ) \| "DEFINE" "EVENT" Nome ":=" Espr ;` | `DEFINE ATTESA_MAX_LLM := UNDECIDED`, `DEFINE vicino(a: Real, b: Real) := ABS(a - b) <= 0.01`, `DEFINE EVENT riavvio := accepted(Avvio)` |
| G12a | `ParametriDefine = "(" Parametro { "," Parametro } ")" ;` | `(a: Real, b: Real)` |

G7 dichiara una richiesta; G12 una costante con nome, una funzione con parametri o un evento derivato.

**Stati con indice e stati che seguono un evento (G11).**
- `STATE x[T] : …` dichiara uno stato con indice: equivale a uno stato per ogni valore di `T`. `T` è un tipo
  **finito**: un elenco di valori (G37), `Boolean`, o un nome dato con G41 a uno di questi o a un `Integer` con i
  due limiti; altrimenti è l'errore E29. Fra le parentesi quadre sta un nome (G11): `STATE q[Integer [0 .. 3]] : …`
  non è riconosciuta, e si scrive `TYPE Indice := Integer [0 .. 3]` e `STATE q[Indice] : …`. Nella dichiarazione si scrive il tipo dell'indice, non una variabile. Il valore
  di `INITIAL` vale per ogni elemento. Negli usi l'indice è un valore di `T` o una variabile di `FOR ALL` su `T`
  (sezione 4.12); nelle storie un valore di `T` (G20).
- `STATE s : T INITIAL v FOLLOWS e.campo` dichiara uno stato che segue il campo `campo` dell'evento `e`: `e` è un
  `EVENT` del blocco, `campo` un suo parametro, e il tipo del parametro è quello dello stato (E24 e E25 altrimenti).
  Il significato è quello della forma estesa `ALWAYS (e IMPLIES s = LAST(e).campo)` e `ALWAYS (CHANGED(s) IMPLIES e)`:
  la riga è anche una proprietà formale, senza nome breve, e il rapporto non la elenca fra le righe contrattuali.
- Un indice e `FOLLOWS` nella stessa riga non sono una forma: la riga non è riconosciuta. Eventi e richieste non
  hanno indici.

**Costanti, funzioni ed eventi derivati (G12).**
- Il valore di una `DEFINE` è un'espressione della sezione 4.12. Un Valore della sezione 4.7 è un caso particolare:
  le righe con un numero, una stringa, `true`, `false` o un valore di un elenco di valori si leggono come prima.
- `DEFINE nome(p: T, …) := espressione` è una funzione con parametri tipizzati; si usa con gli argomenti per nome,
  `nome(p: arg, …)`, come gli argomenti degli eventi nelle storie (sezione 4.12). I nomi dei parametri valgono solo
  nella riga.
- `DEFINE EVENT nome := condizione` dà un nome a un evento derivato: la condizione è un'espressione `Boolean` sul
  passo, la riga non ha parametri né `UNDECIDED`, e il nome si usa dove si usa un evento (sezione 4.12), tranne nei
  passi delle storie, che contengono solo eventi dichiarati (E03, come oggi).
- `DEFINE nome DETAILS padre [STATUS …] := …` dettaglia un'altra `DEFINE` dello stesso blocco (sezione 7.1 per lo
  stato; E02 se il padre non è una `DEFINE`). `UNDECIDED` non ha parametri.
- Le `DEFINE` non si nominano in giro: `DEFINE A := B + 1` con `DEFINE B := A - 1` è l'errore E28.
- Il tipo di una costante è quello della sua espressione (sezione 4.13); quello di `UNDECIDED` non è noto, e una
  costante `UNDECIDED` si usa senza controllo del tipo.

**Una costante con il suo valore.** Il caso più comune è un Valore della sezione 4.7: un numero, con o senza segno
e con o senza unità, una stringa, `true`, `false` o un valore di un elenco di valori. L'unità sta **sulla stessa
riga** del numero (G27). Esempi, per la luce delle scale:

```
DEFINE DURATA_LUCE := 60 s        -- riconosciuta: numero e unità
DEFINE DURATA_LUCE := 60s         -- riconosciuta: lo spazio si può omettere
DEFINE RITARDO_MAX := 250 ms      -- riconosciuta
DEFINE PIANI := 4                 -- riconosciuta: numero puro, senza unità
DEFINE LAMPEGGIO := UNDECIDED     -- riconosciuta: va nella sezione 3 del rapporto
DEFINE ATTENUAZIONE_MIN := -40    -- riconosciuta: numero con segno
DEFINE DURATA_LUCE := 1 min       -- non riconosciuta: min non è un'unità del linguaggio
DEFINE LIVELLO_MAX := 90 dB       -- non riconosciuta: le unità sono solo s e ms;
                                  --   si scrive DEFINE LIVELLO_MAX_DBA := 90
DEFINE DURATA_LUCE := 60          -- riconosciuta, ma la riga dopo, che comincia con «s»,
                      s           --   apre una dichiarazione nuova, non riconosciuta (U2)
DEFINE DURATA_AVVISO := DURATA_LUCE - 5 s   -- riconosciuta: un'espressione, di tipo Duration
DEFINE DOPPIA := DURATA_LUCE * 2  -- riconosciuta: una durata per un numero è una durata
DEFINE STRANA := DURATA_LUCE + 2  -- riconosciuta, con l'errore E25: una durata più un numero puro
```

`check` controlla il tipo dell'espressione (sezione 4.13), non il valore: non sa se `120 s` è tanto o poco, e un
nome di costante scritto dentro una stringa (`VERBAL "si spegne dopo DURATA_LUCE"`) è solo testo.

**Da `UNDECIDED` a un valore.** `UNDECIDED` indica un numero non deciso: `check` lo elenca nella sezione 3 del
rapporto finché c'è. Quando il numero è deciso, si scrive il valore al posto di `UNDECIDED`, a mano: nessun comando
lo fa. Che cosa serve dipende dalla CSC:
- in una CSC **da approvare** si cambia la riga, e basta;
- in una CSC **approvata** non si cambia la riga: si scrive una VERSION nuova, che torna da approvare
  finché non viene approvata (sezione 7.2).

### 4.4 Tipi

| N. | Regola | Esempio |
|---|---|---|
| G13 | `Tipo = "Boolean" \| "String" \| "Duration" \| ( "Integer" \| "Real" ) [ Intervallo ] \| "Sequence" "of" Tipo \| "Optional" Tipo \| TipoRecord \| TipoNonDichiarato ;` | `Sequence of String` |
| G14 | `Intervallo = "[" NumeroConSegno ".." NumeroConSegno "]" \| "[" NumeroConSegno ".." "]" \| "[" ".." NumeroConSegno "]" ;` | `Real [0.0 .. 1.0]`, `Integer [-40 .. 0]`, `Integer [0 ..]`, `Integer [.. 10]` |
| G15 | `TipoNonDichiarato = Nome ;` diverso dalle sette parole `Boolean String Duration Integer Real Sequence Optional` | `Testo` |

| G30 | `TipoDescritto = "TYPE" Nome ":=" "VERBAL" Stringa ;` dentro un blocco CSC; `Nome` non è uno dei sette tipi di base | `TYPE Testo := VERBAL "il contenuto di un file, riga per riga"` |
| G37 | `TipoEnumerato = "TYPE" Nome ":=" "{" Nome { "," Nome } "}" ;` dentro un blocco CSC; `Nome` del tipo non è uno dei sette tipi di base | `TYPE Fase := {inattiva, armata, in_corso}` |
| G41 | `TipoConNome = "TYPE" Nome ":=" Tipo ;` dentro un blocco CSC; `Nome` non è uno dei sette tipi di base | `TYPE Percentuale := Integer [0 .. 100]`, `TYPE Campione := Record {L: Real, R: Real}` |
| G42 | `TipoRecord = "Record" "{" Campo { "," Campo } "}" ;` con `Campo = Nome ":" Tipo ;` | `Record {L: Real, R: Real}` |

Un tipo non dichiarato è ammesso: non è un errore, e compare nella sezione 6 del rapporto con le righe dove si
usa, così non resta nascosto. `Sequence` senza `of`, o `Optional` senza tipo, non sono riconosciuti. `check` non
confronta i limiti di un intervallo fra loro: `Real [20.0 .. -20.0]` è riconosciuto (sezione 14). Un intervallo con
un limite omesso non ha quel limite: `Integer [0 ..]` è un intero non negativo senza massimo; `[ .. ]`, senza i due
limiti, non è un intervallo e rende la dichiarazione non riconosciuta.

**Tipi con nome (G41) e `Record` (G42).**
- `TYPE Nome := Tipo` dà un nome a un tipo qualunque di G13: il nome vale come il tipo che nomina, in tutto il
  blocco, anche se la riga viene dopo l'uso. Entra nell'elenco dei nomi del blocco (E01 se ripetuto) ed esce dalla
  sezione 6. Due nomi di tipo che si nominano in giro (`TYPE A := B`, `TYPE B := A`) sono l'errore E28.
- `Record {campo: Tipo, …}` è un tipo con campi; `x.campo` ne nomina un campo (sezione 4.12). I nomi dei campi
  valgono solo nel `Record`: due campi con lo stesso nome sono E01; un campo può avere lo stesso nome di un elemento
  del blocco. Un `Record` non ha valori scritti: uno stato di tipo `Record` non ha un `INITIAL` valido (E25), e
  nelle storie il valore di un parametro di tipo `Record` si scrive `_`.
- `TYPE Nome := VERBAL …` (G30) e `TYPE Nome := { … }` (G37) restano quelle sotto. Una `TYPE` che non rispetta
  nessuna delle tre, o che dà un nome nuovo a un tipo di base (`TYPE Boolean := Integer`), non è riconosciuta e non
  registra nessun nome.

**Tipi descritti a parole (G30):**
- il nome del tipo entra nell'elenco dei nomi del blocco: un altro nome uguale è E01;
- un tipo descritto a parole **non** è un tipo non dichiarato: esce dalla sezione 6 del rapporto, in tutto il
  blocco, anche se la descrizione viene dopo l'uso;
- una `TYPE` scritta in altro modo, che non sia G30, G37 né G41 (`TYPE Colore := {}`), o che descrive un tipo
  di base (`TYPE Boolean := VERBAL "…"`), non è riconosciuta e non registra nessun nome;
- un tipo non è una promessa: non chiede `VERIFY` e non dà E13. Una riga `VERIFY` dopo una `TYPE` apre
  una dichiarazione nuova, non riconosciuta (regola U4).

Esempio: `STATE contenuto : Testo INITIAL ""` con `TYPE Testo := VERBAL "il contenuto di un file"` nello
stesso blocco: `Testo` non compare nella sezione 6.

**Elenchi di valori (G37).** Un elenco di valori è un tipo fatto di un insieme chiuso di valori con nome; un valore
di quel tipo è uno di quelli. Esempio:

```
TYPE Fase := {inattiva, armata, in_corso, accettata, rifiutata}
EVENT OUT stato(fase: Fase)
STATE fase_ora : Fase INITIAL inattiva
```

| Che cosa | Regola |
|---|---|
| Il nome del tipo | come G30: entra nell'elenco dei nomi del blocco (E01 se ripetuto) ed esce dalla sezione 6 «tipi non dichiarati», in tutto il blocco |
| I valori | sono nomi (L7) ed entrano nello **stesso elenco** dei nomi del blocco: un valore uguale a uno stato, a un evento, a una richiesta, a una costante, a un nome breve o a un valore di un altro elenco di valori è **E01** sul secondo, nell'ordine del file (riga, poi colonna). Un valore ripetuto nello stesso elenco è E01 sul secondo. Riga e colonna dell'errore: quelle del valore |
| Un nome come valore | (G26) in `INITIAL`, `GIVEN`, assegnazioni e argomenti, e in una `DEFINE` il cui valore è un nome solo. In un blocco CSC, se il nome non è un valore di un elenco di valori dello stesso blocco (e, in una `DEFINE`, nemmeno un altro nome del blocco): **E03** `nome non dichiarato come valore di TYPE: X`. In una storia d'entità vale la sezione 4.6. In un'espressione più ampia vale la sezione 4.13 |
| Il tipo del valore | **si controlla** (sezione 4.13): `STATE fase_ora : Fase INITIAL rifiutata` è riconosciuta senza errori; `STATE accesa : Boolean INITIAL armata` (con `armata` valore di `Fase`) è riconosciuta con l'errore **E25** `valore non del tipo Boolean: armata` |
| Non è una promessa | niente `VERIFY`, niente E13, come G30. Una riga `VERIFY` dopo una `TYPE` apre una dichiarazione nuova, non riconosciuta (U4) |
| Non riconosciute, senza nomi registrati | `TYPE X := {}`, `TYPE X := {a b}`, `TYPE X := {a,}`, `TYPE Boolean := {a, b}` (tipo di base), `TYPE X := {"a", "b"}`, `TYPE X := {1, 2}` |
| `TYPE X := {a, a}` | riconosciuta, con E01 sul secondo `a` |
| Nel JSON | una dichiarazione di tipo `TYPE`, come G30; i valori non sono dichiarazioni a sé: stanno nel suo `testo` |

Un nome del ciclo di vita (`requested` …), `true`, `false` e `_` sono riservati e non possono essere valori
(L7).

### 4.5 Righe contrattuali

| N. | Regola | Esempio |
|---|---|---|
| G16 | `RigaContrattuale = ( "GUARANTEE" \| "ASSUME" ) Id [ "DETAILS" Id ] [ "STATUS" Stato ] ":" Proprieta ;` | `GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "…" VERIFY BY JUDGEMENT "…"` |
| G17 | `Proprieta = "VERBAL" Stringa Verifica \| Formula ;` (`Formula`: G55, sezione 4.12) | `VERBAL "Check non modifica mai il file" VERIFY BY INSPECTION "il file"`, `WHENEVER pressione THEN accesa WITHIN 1 s` |
| G18 | `Verifica = "VERIFY" "BY" ( "JUDGEMENT" \| "INSPECTION" ) Stringa ;` | `VERIFY BY JUDGEMENT "l'operatore"` |

Una riga contrattuale è una promessa (`GUARANTEE`) o un presupposto (`ASSUME`). Si legge in due parti.
L'**intestazione della riga** va dalla prima parola ai due punti; la **proprietà** viene dopo i due punti.
- Se l'intestazione della riga non rispetta G16, la riga non è riconosciuta e il suo nome breve non esiste per il
  controllo.
- Se l'intestazione della riga la rispetta ma la proprietà non rispetta G17, il nome breve esiste (si può nominare
  con `DETAILS`, conta per i nomi ripetuti) ma la riga è non riconosciuta e il suo grado è «non riconosciuta». È il
  caso di una formula scritta in una forma che la sezione 4.12 non prevede (sezione 6).
- Una formula non chiede `VERIFY`: il suo modo di verifica è dato dalla forma (sezione 6). Una riga `VERIFY` dopo
  una formula continua la dichiarazione (U4) e la rende non riconosciuta.

Lo stesso vale per G12: in `DEFINE LIMITE := DURATA * * 2` il nome `LIMITE` esiste, ma la riga è non
riconosciuta perché l'espressione non rispetta la sezione 4.12.

**Il controllo mancante (errore E13).** Un'eccezione voluta a G17, come quella di G5: se dopo i due punti la
proprietà è **esattamente** `VERBAL` seguito da una stringa chiusa, e la dichiarazione finisce lì, la riga **è
riconosciuta**, il suo grado è `verbale` e c'è l'errore E13. Esempio: `GUARANTEE g2: VERBAL "senza verifica"`. La
ragione: ogni promessa e ogni presupposto devono dire come si verificano. Una promessa che non lo dice non è una
forma che `bcdd` non sa leggere: `bcdd` la legge tutta e vede che manca un pezzo obbligatorio. Classificarla fra le
righe non riconosciute, con esito 0 senza `--strict`, lascerebbe passare come valida una promessa senza modo di
controllarla. È lo stesso ragionamento di E04 (un'approvazione senza decisione).

E13 è stretto di proposito. Se dopo la stringa c'è qualunque altra cosa, la regola resta G17: per
esempio `VERBAL "…" VERIFY BY MAGIC "…"` dichiara un modo di verifica che il linguaggio non prevede, ed è
non riconosciuta, senza E13. Nei passi delle storie l'elemento `VERBAL "…"` (G22) è un'asserzione a parole, non
una proprietà: non chiede `VERIFY` e non dà mai E13.

**Quali dichiarazioni non riconosciute registrano un nome.** Un nome registrato esiste per il controllo: si può
nominare (`DETAILS`, passi), e conta per E01. Lo registrano solo:
- `GUARANTEE` e `ASSUME` con intestazione della riga valida (G16), qualunque sia la proprietà;
- `DEFINE` letta fino a `:=` compreso secondo G12 (con i parametri, `DETAILS` e `STATUS` se ci sono, oppure
  `DEFINE EVENT Nome`), seguita da qualunque cosa.

Non registrano nulla, se non sono riconosciute per intero, `CAPABILITY`, `EVENT`, `STATE`, `SCENARIO` e
`TYPE`. La ragione della differenza: il nome breve di una riga contrattuale serve alla catena dei `DETAILS` e allo
stato di approvazione (sezione 7), e l'intestazione della riga si legge da sola, prima dei due punti. Per le altre
dichiarazioni la parte che conta (parametri, tipo, `GIVEN`) è proprio quella che non si è letta. La conseguenza:
un passo che nomina un evento o una richiesta la cui dichiarazione non è riconosciuta dà E03 («non dichiarato»).
L'errore indica il punto da correggere, e la dichiarazione scritta male è comunque nella sezione 5 del rapporto.

### 4.6 Storie

| N. | Regola | Esempio |
|---|---|---|
| G19 | `Scenario = "SCENARIO" Id [ "DETAILS" Id [ "STATUS" Stato ] ] [ "GIVEN" Assegnazione { "," Assegnazione } ] "EXPECT" ( "ADMITTED" \| "REJECTED" ) ;` | `SCENARIO s1 GIVEN accesa = false EXPECT ADMITTED`, `SCENARIO s1a DETAILS s1 STATUS HYPOTHESIS GIVEN accesa = false EXPECT ADMITTED` |
| G20 | `Assegnazione = Nome [ "[" Valore "]" ] "=" Valore ;` | `accesa = true`, `clipCount[L] = 2` |
| G21 | `Passo = "@" Numero [ Unita ] [ Elemento { [ "," ] Elemento } ] ;` | `@100 s   pressione(tasto: 1)   accesa = true` |
| G22 | `Elemento = "VERBAL" Stringa \| Ciclo \| Assegnazione \| Occorrenza ;` | `VERBAL "la luce è spenta da poco"` |
| G23 | `Ciclo = ( "requested" \| "accepted" \| "rejected" \| "completed" \| "failed" ) "(" Nome ")" ;` | `requested(Refine)` |
| G24 | `Occorrenza = Nome [ "(" Argomento { "," Argomento } ")" ] ;` | `risposta(proposta: "g2a", accettata: false)` |
| G25 | `Argomento = Nome ":" ( Valore \| "_" ) ;` | `tasto: _` |
| G36 | `NomeQualificato = Nome "." Nome ;` solo nelle storie e nelle formule d'entità: il primo nome è una CSC dell'entità, il secondo un suo elemento | `Sessione.pronta`, `Abbinamento.abbina` |
| G47 | `Ripetizione = "REPEAT" ( "FOREVER" \| Intero ".." Intero ) "EVERY" Numero Unita ;` | `REPEAT FOREVER EVERY 1 s`, `REPEAT 2..5 EVERY 100 ms` |

Una storia comincia con `SCENARIO` (G19) e prosegue con i suoi passi (G21). Come si distingue un elemento di un
passo dall'altro, guardando al più l'elemento successivo:
- `VERBAL` apre un'asserzione a parole;
- una delle cinque parole del ciclo di vita apre un `Ciclo`;
- un nome seguito da `=` è un'`Assegnazione`, cioè «in questo passo lo stato vale…»;
- un altro nome è un'`Occorrenza` di evento;
- dopo `=` viene sempre un Valore (G26): `@1 s fase_ora = armata premi(…)` è un'assegnazione e poi
  un'occorrenza; in `x = premi` il valore è il nome `premi` (ed E03 se non è un valore di un elenco di valori).

La virgola fra due elementi si può mettere o no; una virgola in fondo al passo lascia la dichiarazione aperta
(U5): se la riga dopo comincia con `@` il passo resta non riconosciuto. L'unità dopo il numero del passo vale solo
se è sulla stessa riga.

**Indici nelle storie (G20).** `x[v] = w` assegna l'elemento `v` di uno stato con indice: `v` è un valore del tipo
dell'indice (E29 altrimenti), `w` un valore del tipo dello stato. Uno stato con indice scritto senza indice, o uno
stato senza indice scritto con un indice, è l'errore E29.

**Dettagli di una storia (G19).** `SCENARIO id DETAILS padre [STATUS …]` dettaglia un'altra storia dello stesso
blocco (E02 se `padre` non è una storia). Lo stato della storia dettagliata segue la sezione 7.1. Una storia senza
`DETAILS` non ha `STATUS`: `SCENARIO s1 STATUS HYPOTHESIS EXPECT ADMITTED` non è riconosciuta.

**Le ripetizioni (G47).** Una riga `REPEAT` sta fra i passi di una storia e vale fino alla sua fine: i passi che la
seguono sono quelli ripetuti. `REPEAT FOREVER EVERY d` ripete i passi senza fine (lazo); `REPEAT m..n EVERY d` da
`m` a `n` volte. Ogni ripetizione comincia `d` dopo la precedente, e i tempi `@t` dei passi ripetuti contano
dall'inizio della ripetizione. Esempio:

```
SCENARIO lampeggio EXPECT ADMITTED
  @0 s     accendi
  REPEAT FOREVER EVERY 1 s
  @0 s     spegni
  @0.5 s   accendi
```

| Caso | Esito |
|---|---|
| una seconda riga `REPEAT` nella stessa storia | **E30** `REPEAT ripetuto nella storia: il primo è alla riga N`, sulla seconda |
| `REPEAT m..n` con `m` > `n` oppure `n` = 0 | **E30** `ripetizioni non valide: m..n. Scrivi REPEAT minimo..massimo, con il massimo almeno 1 e non più piccolo del minimo` |
| un passo ripetuto con tempo `t` maggiore o uguale a `d` | **E30** `il passo @t non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY d` |
| una riga `REPEAT` senza passi dopo | **E30** `REPEAT senza passi: i passi ripetuti si scrivono dopo la riga REPEAT` |
| una storia con passi senza unità e una riga `REPEAT … EVERY d` | **E30** `REPEAT … EVERY vuole una storia con le unità di tempo` |
| `REPEAT FOREVER` senza `EVERY`, `REPEAT 2..5 EVERY 1` (senza unità), `REPEAT -1..2 EVERY 1 s` | non è G47: la riga non è riconosciuta |
| E12 | vale nei passi prima di `REPEAT` come oggi, e fra i passi ripetuti fra loro, con i tempi relativi; il primo passo ripetuto non si confronta con quelli prima di `REPEAT` |

Una riga `REPEAT` non è un passo: non apre e non chiude la storia (sezione 5).

Limite noto: in `@0 s pressione` la parola `s` è l'unità di tempo. Un evento chiamato `s` o `ms` non può
quindi essere il primo elemento di un passo senza unità.

**Storie d'entità.** In un blocco `ENTITY` valgono `SCENARIO` (G19) e i passi (G21-G25) come nella CSC, con una
sola differenza: i nomi di stati, eventi e richieste sono **qualificati** (G36). Si scrive `NomeQualificato` al posto
di `Nome` in queste tre regole, e solo in esse:

```
G20e  Assegnazione = NomeQualificato "=" Valore ;
G23e  Ciclo        = ( "requested" | "accepted" | "rejected" | "completed" | "failed" ) "(" NomeQualificato ")" ;
G24e  Occorrenza   = NomeQualificato [ "(" Argomento { "," Argomento } ")" ] ;
```

G20e vale nel `GIVEN` e nei passi. Gli argomenti (G25) restano nomi semplici: sono i parametri dell'evento.
Un nome semplice in una storia d'entità si legge con G20, G23, G24 come nella CSC, e dà E03 (un'entità non
ha elementi propri). Esempio, nell'entità `Processore` che offre `Abbinamento`, `Sessione` e `Pulsanti`:

```
SCENARIO comandoDopoAbbinamento GIVEN Sessione.pronta = true EXPECT ADMITTED
  @0 s   Abbinamento.abbina(codice: "AB12")
  @1 s   Pulsanti.premi(pulsante: "flat", acceso: true)
```

Significato: come una storia di una CSC, una traccia aperta e datata che l'entità ammette o respinge, osservata su
più confini della stessa entità. Non è contratto: non si approva, e non indica un ordine fra le parti, né una
priorità, né un canale. Che cosa controlla `check`:

| Caso | Esito |
|---|---|
| `X.y`, `X` è una `OFFERS` o `USES` riconosciuta e senza E01 dell'entità, la CSC `X` è trovata (sezione 9.4) e ha `y` del tipo giusto: `STATE` nelle assegnazioni, `EVENT` nelle occorrenze, `CAPABILITY` nei cicli; ogni argomento è un parametro dell'evento | nessun errore |
| come sopra, ma `y` non c'è, o non è del tipo giusto | **E03** `nome non dichiarato come EVENT: X.y` (e così `STATE`, `CAPABILITY`) |
| come sopra, ma un argomento non è un parametro dell'evento | **E03** `nome non dichiarato come parametro di X.y: a` |
| `X` non è fra le `OFFERS` e `USES` dell'entità (riconosciute e senza E01) | **E20** `X.y: E non offre né usa il connettore X; uno scenario può citare solo i connettori di E`, con `E` il nome dell'entità (`?` se non si legge) |
| `X` è dell'entità ma la CSC `X` non è trovata | nessun errore: il controllo di `y` e dei suoi argomenti è **sospeso**, come E14 con una parte non trovata; la citazione è già nella sezione 7 |
| un nome **semplice** (`pronta`) | **E03**, come nella CSC senza quel nome: `nome non dichiarato come STATE: pronta` |
| un valore che è un nome (`fase: armata`) | si accetta come valore, senza controllo: i valori degli elenchi di valori di una CSC citata non si leggono (sezione 14) |
| un valore scritto (numero, stringa, `true`, `false`, `ABSENT`) per uno stato o un parametro di `X.y` | si controlla con il tipo letto nel blocco trovato, se è un tipo di base (`Boolean`, `String`, `Duration`, `Integer`, `Real`, con il loro intervallo, anche dentro `Optional`): **E25** se non è del tipo. Un tipo che non è di base (un elenco di valori, un tipo con nome, un tipo descritto a parole della CSC citata) non si controlla |
| `X.y` in una **CSC** (anche con `X` uguale alla CSC stessa), in un `GIVEN`, in un'assegnazione, in un'occorrenza, in un ciclo o in una fase di una formula (sezione 4.12) | **E20** `X.y: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità`. La dichiarazione è letta con G20e, G23e, G24e solo per dare l'errore |
| `X.y` fuori da una storia (per esempio `DEFINE N := X.y`, `STATE s : X.T INITIAL …`, `OFFERS X.y`) | non è una forma: la dichiarazione non è riconosciuta |

Riga e colonna di E20 e di E03 su un nome qualificato: quelle di `X`. Una dichiarazione con E20 o E03 resta
**riconosciuta** (la forma è giusta, il nome no), come con E03 nella CSC. Con più versioni della stessa CSC
offerte o usate (sezione 5) basta che `y` ci sia in uno dei blocchi trovati per quel nome. Se `y` non c'è in
nessuno dei blocchi trovati, ma almeno una delle righe `OFFERS` o `USES` con quel nome non è stata trovata, il
controllo di `y` e dei suoi argomenti è **sospeso**, senza E03: la versione che manca potrebbe avere `y`, e un
errore si segnala solo quando è certo. E03 si scrive solo quando tutte le righe con quel nome sono trovate. Una riga
trovata solo nel ripiego (`, attesa VERSION w`, sezione 9.4) non conta come trovata per questo controllo: è come
una riga non trovata, e il controllo di `y` è sospeso, senza E03 sul blocco di un'altra versione; nel rapporto la
riga ha comunque `attesa`. E12 vale nelle storie d'entità come nella CSC. Il nome breve di una storia d'entità
entra nell'elenco dei nomi dell'entità (sezione 5).

### 4.7 Valori

| N. | Regola | Esempio |
|---|---|---|
| G26 | `Valore = Stringa \| NumeroConSegno [ Unita ] \| "true" \| "false" \| "ABSENT" \| Nome ;` dove `Nome` è un valore di un elenco di valori (sezione 4.4) | `180 s`, `""`, `false`, `-40`, `armata`, `ABSENT` |
| G27 | `Unita = "ms" \| "s" ;` sulla stessa riga del numero, con o senza spazio | `250 ms`, `50ms` |

### 4.8 L'elenco delle parti, e la vista uscita dal linguaggio

| N. | Regola | Esempio |
|---|---|---|
| G28 | `ElencoParti = "COMPOSED" "OF" ;` | `COMPOSED OF` |
| G29 | `Parte = Nome ":" Nome ;` valeva solo nelle viste, uscite dal linguaggio: **non vale in nessun posto** | `archivio : Archivio` |

G28 vale nell'entità (sezione 4.9). `LINK`, `MAP` e `REFINED BY` non si leggono: sono righe non riconosciute.

**La vista è uscita dal linguaggio.** Una scomposizione si scrive con `ENTITY`. Una vista `REFINEMENT VIEW` si
tratta così:

- una dichiarazione che comincia con la parola `REFINEMENT`, in un posto dove comincia un blocco (fuori da un
  blocco, o dentro un blocco aperto, che chiude con E07), è l'**errore E15** sulla parola `REFINEMENT`, qualunque
  cosa la segua. La dichiarazione non è riconosciuta;
- la dichiarazione apre un **blocco ritirato**, che finisce con `END` (G3), come gli altri blocchi. Dentro il
  blocco ritirato ogni altra dichiarazione non è riconosciuta: non registra nessun nome, non si cerca, non
  compare nella sezione 7 e non dà E01. Un `CSC`, un `ENTITY` o un altro `REFINEMENT` lo chiude con E07,
  come per gli altri blocchi; senza `END` alla fine del file c'è E07;
- il blocco ritirato non registra il suo nome: non dà E01 con un altro blocco dello stesso nome;
- nel rapporto il blocco ritirato compare fra i blocchi, `riga N: REFINEMENT VIEW Nome` se la dichiarazione
  rispetta G2, altrimenti `REFINEMENT VIEW (intestazione non valida)`; E07 lo nomina (`manca END di REFINEMENT
  VIEW X`). Per E11 non conta.

**Perché un errore, e non una riga non riconosciuta o un avviso.** `check` non ha avvisi: servirebbe una sezione
del rapporto per un solo caso. Una riga non riconosciuta indica una forma che `bcdd` non sa leggere, e senza
`--strict` non cambia il codice: la vista passerebbe in silenzio, e chi l'ha scritta crederebbe di aver dichiarato
una scomposizione. Qui invece `bcdd` sa leggere la forma e sa che è sbagliata, perché è uscita dal linguaggio: è la
definizione di errore della sezione 8, e lo stesso ragionamento di E04 e di E13. Il messaggio dice che cosa
scrivere al suo posto.

**Perché le righe del blocco non sono riconosciute.** Leggere le parti di una vista vorrebbe dire continuare a dare
un significato a una forma che non ne ha più. Le righe restano tutte visibili nella sezione 5, con il loro numero.
Il blocco resta un blocco, con il suo `END`, perché altrimenti `END` darebbe E08 e `COMPOSED OF` e le parti
sembrerebbero scritte fuori posto.

### 4.9 Entità

Un'**entità** si riconosce dai confini su cui sta: le CSC che offre e quelle che usa. Chi offre una CSC
mantiene le sue promesse (`GUARANTEE`), chi la usa rispetta i suoi presupposti (`ASSUME`). Un'entità può essere
fatta di altre entità, le sue **parti**. Non ha elementi propri (eventi, stati, richieste): quelli stanno nelle
CSC, e una dichiarazione di elemento proprio in un'entità è l'errore E18 (sezione 5). Un'entità ha storie con i
nomi qualificati (sezione 4.6).

| N. | Regola | Esempio |
|---|---|---|
| G31 | `IntestazioneEntita = "ENTITY" Nome "VERSION" Versione ;` | `ENTITY LuceScale VERSION 0.2` |
| G32 | `Offerta = "OFFERS" Nome [ "VERSION" Versione ] ;` il nome è una CSC | `OFFERS Pressione VERSION 0.1` |
| G33 | `Uso = "USES" Nome [ "VERSION" Versione ] ;` il nome è una CSC | `USES Comando` |
| G34 | `ParteEntita = Nome ":" Nome [ "VERSION" Versione ] [ Molteplicita ] ;` il primo è il nome della parte, il secondo un'entità | `pulsante : Pulsante VERSION 0.1`, `telefono : Misuratore [1 .. 4]` |
| G35 | `Molteplicita = "[" Numero ".." Numero "]" ;` | `[1 .. 4]`, `[2 .. 2]` |

- `VERSION` senza versione, o con una versione che non rispetta L10 (`v1`), rende la dichiarazione non
  riconosciuta: `OFFERS Comando VERSION v1` non è riconosciuta e non si cerca.
- Una parte (G34) vale in qualunque punto dell'entità; l'elenco delle parti, `COMPOSED OF` (G28), si scrive una
  volta sola e dice a chi legge che l'entità è fatta di parti (sezione 5, «Le parti di un'entità»).
- Un'entità può avere `STATUS HYPOTHESIS` (G4) e righe `IMPORT PROFILE` (G39) nella sua zona d'intestazione, come
  la CSC (sezione 4.2). Ha esattamente un `PURPOSE` (G6), righe `GUARANTEE` (G16), con `DETAILS` fra loro, e storie
  con i loro passi (sezione 4.6). Le promesse d'entità sono a parole o formule. Si approvano una per una o con
  `--all` (sezione 12); l'entità intera no (sezione 7.1).
- **Le promesse d'entità scritte come formule.** Una formula in una `GUARANTEE` d'entità (sezione 4.12) nomina gli
  elementi delle CSC dell'entità con i nomi qualificati `X.y` (G36), con le regole delle storie d'entità della
  sezione 4.6: `X` è una `OFFERS` o `USES` dell'entità (E20 altrimenti, con il messaggio `X.y: E non offre né usa
  il connettore X; una promessa d'entità può citare solo i connettori di E`), `y` un elemento del genere giusto nella
  CSC `X` trovata (E24 altrimenti), e il controllo è sospeso se `X` non è trovata. Con le composizioni, `X` si
  controlla per composizione come negli scenari (sezione 4.10). In questa versione `X.y` in una formula d'entità ha
  tipo **non noto**, anche quando il blocco trovato gli dà un tipo di base: `check` ne controlla il nome e il genere,
  non il tipo, e su queste formule non dà E25 (sezione 14). Nelle storie d'entità i valori scritti si controllano
  sui tipi di base (sezione 4.6). Un nome semplice è un valore di un elenco di
  valori di una CSC citata, accettato senza controllo, oppure una variabile di `FOR ALL`; in una posizione che
  chiede un evento, una richiesta, uno stato o una condizione è l'errore E24 (`in un'entità i nomi delle CSC si
  scrivono con il connettore davanti: x`). Un'entità usa le estensioni dei profili che importa lei, con `LEVEL
  ENTITY` (sezione 4.14). Esempio: `GUARANTEE g1: WHENEVER Pressione.pressione AND NOT Luce.accesa THEN
  Luce.accesa WITHIN 1 s`.

**La molteplicità di una parte (G35).** `telefono : Misuratore [1 .. 4]` dice che l'entità è fatta di almeno `m` = 1
e al più `n` = 4 copie della parte. Ogni copia è vincolata per intero dalle CSC che la parte offre e usa. La
molteplicità non dice quando una copia c'è o se ne va, come si distinguono le copie né quale viene prima, né dove
stanno. Senza molteplicità una parte vale `[1 .. 1]`.

| Che cosa | Regola |
|---|---|
| Ordine | uno solo: prima la versione (dell'entità nominata), poi la molteplicità (della parte). `telefono : Misuratore [1 .. 4] VERSION 0.1` non rispetta G34: non è riconosciuta e non è una parte |
| Limiti giusti | due interi (L13) con 0 <= `m` <= `n` e `n` >= 1: `m` = 0 rende la parte **facoltativa** (sezione 4.10) |
| **E19** | la forma G35 c'è, ma un limite ha un punto (`[1.5 .. 4]`), o `m` > `n` (`[4 .. 1]`), o `n` = 0 (`[0 .. 0]`). Riga della parte, colonna di `[` |
| La parte con E19 | **resta una parte**: si cerca, compare sotto l'entità, conta nella chiusura (E14, E16, E17) e nella sezione 8 come se la molteplicità fosse giusta. Un limite sbagliato dà un errore solo, non una cascata di errori. Vale come parte **fissa** (presente in ogni composizione), anche con `m` = 0 |
| Non sono G35 | `[1 .. ]`, `[1, 4]`, `[-1 .. 4]` (`-1` non è un Numero, L11), `[1 .. 4` : la dichiarazione non rispetta G34, non è riconosciuta e non è una parte (come ogni dichiarazione che non rispetta G34, sezione 5) |
| Chiusura e sezione 8 | la riga resta **una** parte; il combaciare non cambia (9.4). La `OFFERS X` di una parte non soddisfa la sua stessa `USES X` **anche con `m` >= 2**: le copie di una stessa parte non si servono fra loro. Due nodi che si servono a vicenda sono due parti (`a : Nodo`, `b : Nodo`) |
| Nel rapporto | la riga della citazione si scrive senza molteplicità, come senza versione (9.4) |
| Nel JSON | la citazione `PART` ha il campo `molteplicita`: `{"min": m, "max": n}` con i due limiti come numeri, oppure `null` se la riga non la scrive. Con E19 il campo c'è lo stesso, con i limiti come scritti se sono interi; se un limite ha un punto il campo è `null` |

Un'entità con parti deve essere **chiusa**: ogni confine pubblico lo mantiene una parte dallo stesso lato (E16), e
ogni confine offerto da una parte lo usa un'altra parte o lo offre l'entità (E17). La chiusura si controlla in ogni
composizione (sezione 4.10).

L'esempio della luce delle scale (le CSC `Pressione`, `Luce`, `Comando` e le entità `Pulsante`, `Lampada` stanno
nella stessa cartella, un file ciascuna):

```
ENTITY LuceScale VERSION 0.2
  PURPOSE "La luce delle scale"
  OFFERS Pressione
  OFFERS Luce
  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada
  GUARANTEE g1: VERBAL "Una pressione a luce spenta accende la luce entro 1 s"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
END
```

La luce delle scale offre alla persona `Pressione` e `Luce`; dentro, la lampada usa `Comando`, che il
pulsante offre. Il rapporto di questo file è nella sezione 9.4.

### 4.10 Varianti, parti facoltative e composizioni

Un'entità può dire che una sua funzione la svolge l'uno o l'altro dispositivo (**varianti**), e che una parte può
mancare (**parte facoltativa**). Vale allora per ciascuna delle sue **composizioni**, e `check` le controlla tutte.

| N. | Regola | Esempio |
|---|---|---|
| G38 | `Variante = "VARIANT" Nome "=" Nome ;` il primo nome è il **gruppo di scelte**, il secondo la **scelta** | `VARIANT sensore = di` |

**I pezzi.** In un blocco `ENTITY` una riga G38 apre un **pezzo**, che finisce alla riga `VARIANT` successiva o a
`END`. Le righe prima del primo pezzo sono le **righe comuni**. In un pezzo valgono `OFFERS` (G32), `USES` (G33),
`COMPOSED OF` (G28, una volta per pezzo: una seconda nello stesso pezzo non è riconosciuta, senza effetto), le parti
(G34, anche facoltative), `GUARANTEE` (G16, con `DETAILS`) e `SCENARIO` (G19) con i passi. I pezzi con lo stesso
gruppo di scelte sono le **scelte** di quel gruppo e si escludono a vicenda; non devono stare uno dopo l'altro. I
gruppi di scelte e le scelte hanno nomi propri: non entrano nell'elenco dei nomi dell'entità (sezione 5).

| Caso | Esito |
|---|---|
| `VARIANT` in un blocco `CSC` | **E21**; non riconosciuta |
| `VARIANT` in un'entità che non rispetta G38 (`VARIANT sensore`, `VARIANT sensore = di microfono`) | **E21**; non riconosciuta; apre comunque un pezzo, senza gruppo di scelte: le sue righe si leggono (nomi, nomi brevi, gradi), ma l'entità **non ha composizioni**: niente E22, E23, E14, E16, E17 per lei, nessuna voce nelle sezioni 8, 9 e 10 |
| `VARIANT` fuori da un blocco, in un blocco ritirato | non riconosciuta, senza errore |
| `PURPOSE` in un pezzo | **E21**; non riconosciuta e non conta per E10 |
| `STATUS` in un pezzo | non riconosciuta, senza errore (come ogni `STATUS` fuori dalla zona d'intestazione) |
| `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` in un pezzo | **E18**, come nel resto dell'entità |
| un gruppo di scelte con una sola scelta | **E22** sul suo `VARIANT`; il gruppo conta come un fattore da 1 |
| la stessa scelta scritta due volte | **E22** sulla seconda riga; le righe del secondo pezzo valgono come righe della stessa scelta |
| un pezzo senza nessuna dichiarazione riconosciuta (contano le righe con E01; non contano commenti, righe vuote, righe non riconosciute e una `COMPOSED OF` da sola) | **E22** sul suo `VARIANT`: una scelta vuota si scrive con una parte `[0 .. 1]` |

**La parte facoltativa.** `parte : E [0 .. n]` (G35 con `m` = 0, sezione 4.9) vuol dire «senza la parte, oppure con
da 1 a `n` copie»: due composizioni, ciascuna ferma per tutta la traccia. Nella composizione «con» la parte vale
`[1 .. n]`; in quella «senza» non offre, non usa e non conta nella chiusura. Si cerca sempre. Può stare fra le righe
comuni o in un pezzo (allora c'è solo con quella scelta).

**I fattori.** Un **fattore** è ciò che si sceglie quando si compone l'entità:

| Fattore | Valori, nell'ordine | Nome di un valore |
|---|---|---|
| un gruppo di scelte dell'entità | le scelte, nell'ordine della prima riga di ciascuna | `D = S` |
| una parte facoltativa (senza E19) | presente, poi assente | `con P`, `senza P` |
| un gruppo di scelte di una parte **trovata** il cui blocco ha righe G38 riconosciute (le scelte della parte salgono all'entità) | le scelte, nell'ordine del blocco della parte | `P.D = S` |

I fattori si ordinano per riga nel file controllato: un gruppo di scelte alla riga del suo primo `VARIANT`, una parte
alla sua riga; i gruppi di scelte di una parte nell'ordine del suo blocco. Un fattore dentro un pezzo esiste solo
nelle composizioni di quella scelta; i fattori di una parte facoltativa solo nelle composizioni «con». **Le parti
facoltative di una parte non salgono**: non cambiano le sue righe `OFFERS` e `USES`, le sole che si leggono di una
parte (9.4, una sola profondità).

**Le composizioni.** Una composizione ha un valore per ogni fattore che esiste in essa. Si elencano in ordine
lessicografico sui fattori (il primo cambia più lentamente). Il **nome** è la lista dei valori, nell'ordine,
separati da `, `: `sensore = di, con di`. Un'entità senza fattori ha una composizione senza nome. In ogni
composizione:
- i confini pubblici sono le `OFFERS` e `USES` comuni più quelle dei pezzi scelti;
- le parti sono le comuni più quelle dei pezzi scelti, tolte le facoltative assenti;
- una parte offre e usa le sue righe comuni più quelle delle sue scelte. Nel blocco di una parte, le righe del pezzo
  di un `VARIANT` scritto male non sono offerte né usate.

**Il limite (E23).** Il numero delle composizioni si conta prima di elencarle, con la formula sui fattori, e ci si
ferma appena supera **64**. Oltre: **E23** sull'intestazione, colonna 0; nessuna chiusura per l'entità, nessuna
voce nella sezione 8.

**La chiusura in ogni composizione.** E14, E16 ed E17 (sezioni 8 e 9.4, con il combaciare della 9.4) si controllano
in ogni composizione che ha almeno una parte presente, con o senza `COMPOSED OF`. In una composizione senza nessuna
parte presente (per esempio quando l'unica parte è facoltativa e assente) la chiusura non si controlla, come in
un'entità senza parti. Se una parte dell'entità, in qualunque pezzo, non è trovata, E14, E16 ed E17 sono sospesi
per tutta l'entità. Lo stesso errore (codice, riga, colonna, messaggio) di più composizioni si scrive una volta,
con il suffisso `(in: …)` della sezione 9.5.

**L'assenza dichiarata.** Sia `C` una composizione con almeno una parte facoltativa assente, `A` le parti assenti e
`C+` la stessa composizione con tutte le parti di `A` presenti. Un errore E14, E16 o E17 di `C` che **non** c'è in
`C+` non è un errore: è un'**assenza dichiarata**, nella sezione 10 del rapporto. La parte nominata («senza P») è
ogni `p` di `A` tale che l'errore non c'è in `C` con la sola `p` rimessa; se nessuna basta da sola, tutte quelle di
`A`, in ordine di riga, separate da `, `. Nessun altro errore è mai un'assenza. Lo stesso errore può essere
assenza in una composizione ed errore in un'altra: compare in tutti e due i posti.

**Nomi, dettagli e storie nei pezzi.** Due righe **possono stare insieme** se non stanno in due scelte diverse
dello stesso gruppo. E01 fra due parti, o fra due `OFFERS` (o due `USES`), vale solo fra righe che possono stare
insieme (sezione 5); i nomi brevi di promesse e storie restano unici in tutta l'entità. La riga nominata da un
`DETAILS` deve stare fra le righe comuni o nella stessa scelta del dettaglio, altrimenti **E02**. In una storia
d'entità `X.y` si controlla per composizione: una storia di un pezzo vale con quella scelta, una comune in tutte;
**E20** con il suffisso `(in: …)` dove `X` non è un confine della composizione. E03 non dipende dalla composizione.

**Una riga in un pezzo** si scrive nel rapporto come le altre (righe delle citazioni, sezioni 2-7). Le promesse di
un pezzo si approvano per nome breve come le altre; le righe `VARIANT` non si approvano (sezione 12).

### 4.11 Forme concrete, piano di prova, profili ed estensioni

Un blocco `BINDING` contiene le forme concrete di un confine, un blocco `VERIFICATION` il piano di prova, un blocco
`PROFILE` le estensioni di un campo d'uso, ciascuna in un blocco `EXTENSION`. `BINDING`, `VERIFICATION` e
`PROFILE` sono blocchi come `CSC` ed `ENTITY`: stanno fuori da ogni altro blocco, finiscono con `END` (G3), e una
loro intestazione dentro un blocco aperto chiude quel blocco con l'errore E07 (sezione 5). `EXTENSION` sta solo
dentro un `PROFILE`.

| N. | Regola | Esempio |
|---|---|---|
| G40 | `IntestazioneBinding = "BINDING" Nome "VERSION" Versione [ "AS" Nome ] ;` il primo nome è la CSC legata | `BINDING Comando VERSION 0.1`, `BINDING Pressione VERSION 0.1 AS filo` |
| G48 | `IntestazioneVerification = "VERIFICATION" Nome "VERSION" Versione ;` il nome è la CSC legata | `VERIFICATION Luce VERSION 0.1` |
| G49 | `IntestazioneProfilo = "PROFILE" Nome "VERSION" Versione ;` | `PROFILE Segnale VERSION 0.3` |
| G50 | `IntestazioneEstensione = "EXTENSION" Nome ;` | `EXTENSION FADE` |
| G51 | `Legame = "BIND" Elemento [ "STATUS" Stato ] ":" "VERBAL" Stringa ;` con `Elemento = Nome [ "." Nome ] ;` | `BIND accesa: VERBAL "la plafoniera emette luce piena"`, `BIND chiuso.motivo: VERBAL "il testo sul display"` |
| G52 | `Mezzo = "MEANS" Nome "OBSERVES" Elemento { "," Elemento } "RESOLUTION" Numero Unita [ "USING" Nome ] ;` | `MEANS telecamera OBSERVES accesa RESOLUTION 40 ms` |
| G53 | `StoriaTradotta = "SCENARIO" Id "TRANSLATES" Id ;` seguita dai suoi passi | `SCENARIO s1-filo TRANSLATES s1` |
| G43 | `CampoKind = "KIND" Parola ;` | `KIND PATTERN` |
| G44 | `CampoLevel = "LEVEL" Parola ;` | `LEVEL CSC` |
| G45 | `CampoParams = "PARAMS" "(" [ ParametroEst { "," ParametroEst } ] ")" [ ":" Tipo ] ;` con `ParametroEst = Nome ":" ( Tipo \| Categoria ) ;` e `Categoria = "Name" \| "Type" \| "Event" \| "Condition" \| "Expression" \| "Duration" \| "Property" ;` | `PARAMS (s: Expression, d: Duration)`, `PARAMS (x: Real, a: Real, t: Real) : Boolean` |
| G46 | `CampoVerify = "VERIFY" ( "V1" Controllo { "," Controllo } [ ";" "V2" Stringa ] \| "BY" ( "JUDGEMENT" \| "INSPECTION" ) Stringa ) ;` con `Controllo` una delle parole `C1` … `C8` | `VERIFY V1 C1 ; V2 "misura di s nel tempo"` |
| G54 | `CampoTesto = ( "FORM" \| "MEANING" \| "SOURCE" ) Stringa \| "REDUCES" "TO" RiduzioneEst ;` | `FORM "FADE s WITHIN d"` |

`Parola` in G43 e G44 è una parola qualunque (L3), anche riservata: il valore si controlla dopo (E33), così un valore
scritto male non sparisce fra le righe non riconosciute. `V1`, `V2` e `C1` … `C8` si leggono come tali solo in G46
(sezione 2.3).

#### Il blocco `BINDING`

```
BINDING Luce VERSION 0.1
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "la plafoniera emette luce piena"
  BIND modo:   VERBAL "la spia sul pulsante: verde a luce spenta, spenta a luce accesa"
END
```

- La **zona d'intestazione** (sezione 4.2) contiene `STATUS` (al più uno, E10 se ripetuto) e `IMPORT PROFILE`. Un
  `BINDING` non ha `PURPOSE`: una riga `PURPOSE` vi è non riconosciuta.
- Il corpo contiene righe `BIND` (G51) e usi di estensioni di `KIND DECLARATION` e `LEVEL BINDING` dei profili che
  il blocco importa (sezione 4.14). Ogni altra dichiarazione vi è non riconosciuta.
- La **CSC legata** è la CSC nominata nell'intestazione, con la versione scritta. `bcdd` la cerca come una riga
  `USES Nome VERSION v` (sezione 9.4), e la riporta sotto la riga del blocco o nella sezione 7.
- Una riga `BIND elemento` lega un elemento della CSC legata alla sua forma concreta, a parole. L'elemento è uno
  `STATE`, un `EVENT`, una `CAPABILITY` o una `DEFINE` della CSC legata, oppure `e.p` con `e` un `EVENT` o una
  `CAPABILITY` e `p` un suo parametro. Se la CSC legata è trovata con la versione scritta e l'elemento non c'è, è
  l'errore **E31**. Se la CSC non è trovata, o è trovata solo in un'altra versione, il controllo è sospeso.
- Una riga `BIND` non è una proprietà: non chiede `VERIFY` e non dà E13; una riga `VERIFY` dopo una riga `BIND` apre
  una dichiarazione nuova, non riconosciuta (U4). Una riga `BIND` non ha `DETAILS`: precisa soltanto l'elemento che
  lega. `BIND accesa DETAILS l1: …` non è riconosciuta.
- Più righe `BIND` per lo stesso elemento sono ammesse: descrivono aspetti diversi della stessa forma.
- Gli `STATE`, `EVENT` e `CAPABILITY` della CSC legata che nessuna riga `BIND elemento` del blocco nomina sono
  elencati nella sezione 12 del rapporto, senza errore (sezione 9.6). Una riga `BIND e.p` non vale per `e`.
- Il nome del blocco non entra nell'elenco dei nomi dei blocchi del file: `BINDING Comando` nello stesso file della
  `CSC Comando` non è E01. Il nome dopo `AS` è il **nome proprio** del blocco.
- **Più blocchi per la stessa CSC.** Nel file controllato, due blocchi `BINDING` per la stessa CSC e la stessa
  versione (stesso testo) senza `AS`, oppure con lo stesso nome dopo `AS`, sono l'errore **E40** sul secondo. Un
  blocco senza `AS` e uno con `AS` per la stessa CSC e versione sono ammessi.
- Un `BINDING` ha uno stato (approvato o da approvare), come una CSC: il suo `STATUS` vale per le righe `BIND` che
  non ne hanno uno proprio (sezione 7.1), e `ratify` lo approva (sezione 12).

#### Il blocco `VERIFICATION`

```
VERIFICATION Luce VERSION 0.1
  MEANS telecamera OBSERVES accesa, modo RESOLUTION 40 ms
  MEANS registratore OBSERVES pressione RESOLUTION 1 ms
  SCENARIO s1-sonda TRANSLATES s1
    @0 s     VERBAL "il dito preme il pulsante"
    @0.5 s   VERBAL "la plafoniera è accesa"
END
```

- La **zona d'intestazione** contiene soltanto `IMPORT PROFILE`. Uno `STATUS` in qualunque punto del blocco, nella
  zona o fuori, è l'errore **E39**: un piano di prova non si approva. Una riga `PURPOSE` vi è non riconosciuta.
- La CSC legata si cerca come per un `BINDING`.
- Una riga `MEANS` (G52) dichiara un mezzo di registrazione: il nome del mezzo, gli elementi della CSC legata che
  osserva (gli stessi elementi di una riga `BIND`, con E31 se non ci sono), la risoluzione, una durata con unità,
  e con `USING b` il nome proprio del `BINDING` con cui osserva. I nomi dei mezzi e i nomi brevi delle storie
  tradotte stanno in un solo elenco: un nome ripetuto è E01.
- `USING b` è una citazione: `bcdd` cerca il blocco `BINDING` della stessa CSC e della stessa versione con il nome
  proprio `b`, nell'ordine della sezione 9.4 (il file controllato, poi il file `NomeCSC.csc` della sua cartella, poi
  le cartelle `--dir`); trovato, compare sotto la riga del blocco; non trovato, nella sezione 7.
- Una storia tradotta (G53) traduce la storia `id` della CSC legata: se la CSC è trovata con la versione scritta e
  non ha una storia `id`, è l'errore **E31**. Non ha `GIVEN` né `EXPECT`: il suo esito atteso è quello della storia
  che traduce. I suoi passi seguono G21; i loro elementi sono asserzioni a parole (`VERBAL`) e usi di estensioni di
  `KIND SCENARIO-FORM` e `LEVEL VERIFICATION` (sezione 4.14). Un passo con un altro elemento non è riconosciuto. E12
  e le ripetizioni (G47) valgono come nelle altre storie.
- Una `VERIFICATION` non contiene promesse né presupposti: una `GUARANTEE` o un'`ASSUME` vi è non riconosciuta. Non
  ha uno stato, non compare nella sezione 4 del rapporto e `ratify` la rifiuta (sezione 12).
- `bcdd` calcola la **copertura** del piano dalle righe `OBSERVES` e la scrive nella sezione 13 del rapporto (sezione
  9.6). La tabella non si scrive nel file.
- Il nome del blocco non entra nell'elenco dei nomi dei blocchi del file.

#### Il blocco `PROFILE` e le estensioni

```
PROFILE Segnale VERSION 0.3
  PURPOSE "Grandezze che variano con continuità, misure sui campioni, risposta nel tempo"
  STATUS HYPOTHESIS

  EXTENSION FADE
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (s: Expression, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "s scende senza risalire e senza salti, e vale 0 entro d dal primo passo dell'ambito"
    VERIFY   V1 C1 ; V2 "registrazione di s nel tempo"
    SOURCE   "la luce delle scale, promessa g10"
  END
END
```

- La **zona d'intestazione** di un profilo contiene `PURPOSE` (esattamente uno: E10 se manca o è ripetuto) e
  `STATUS` (al più uno: E10 se ripetuto), in qualunque ordine. `IMPORT PROFILE` vi è non riconosciuto: un profilo
  non importa altri profili. Come ogni riga che comincia con `IMPORT` e non è riconosciuta, non chiude la zona
  (sezione 4.2): uno `STATUS` che la segue è ancora lo stato del profilo.
- Il corpo contiene soltanto blocchi `EXTENSION`. Ogni altra dichiarazione (`TYPE`, `DEFINE`, `GUARANTEE`, …) vi è
  non riconosciuta.
- Il nome del profilo entra nell'elenco dei nomi dei blocchi del file: un profilo e una CSC con lo stesso nome nello
  stesso file sono E01.
- Lo `STATUS` del profilo vale per tutte le sue estensioni, che non hanno uno `STATUS` proprio. `ratify` approva il
  profilo intero (sezione 12).
- **Un'`EXTENSION` fuori da un `PROFILE`** (fuori da ogni blocco, in una CSC, in un'entità, in un `BINDING` o in una
  `VERIFICATION`) è l'errore **E32** sulla parola `EXTENSION`. Apre comunque un blocco, che finisce con il suo `END`
  (G3): le sue righe non sono riconosciute e non registrano nomi, come nel blocco ritirato della sezione 4.8. Il suo
  `END` non chiude il blocco che lo contiene.

**Un'estensione.** Fra la riga `EXTENSION Nome` e il suo `END` stanno i campi, in qualunque ordine, ciascuno al più
una volta. Sono obbligatori `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `VERIFY` e `SOURCE`; `REDUCES TO` è
facoltativo. Ogni altra dichiarazione è non riconosciuta. Che cosa controlla `check`:

| Caso | Esito |
|---|---|
| un campo obbligatorio manca, o la sua riga non è riconosciuta | **E33** `manca il campo K nell'EXTENSION X`, sulla riga `EXTENSION`, colonna 0 |
| un campo scritto due volte | **E33** `campo K ripetuto nell'EXTENSION X: il primo è alla riga N`, sul secondo |
| `KIND` con un valore diverso da `PATTERN`, `SCOPE`, `FUNCTION`, `DECLARATION`, `RELATION`, `SCENARIO-FORM` | **E33** `valore di KIND non ammesso: V` |
| `LEVEL` con un valore diverso da `CSC`, `ENTITY`, `BINDING`, `VERIFICATION` | **E33** `valore di LEVEL non ammesso: V` |
| `KIND FUNCTION` senza il tipo del risultato dopo `PARAMS ( … )` | **E33** `l'EXTENSION X ha KIND FUNCTION: dopo PARAMS serve il tipo del risultato, PARAMS (…) : Tipo` |
| la prima parola di `FORM` non è il nome dell'estensione | **E33** `FORM deve cominciare con il nome dell'estensione: X` |
| un parametro di `PARAMS` che non compare in `FORM`, o vi compare più di una volta | **E33** `il parametro p deve comparire una volta in FORM` |
| `VERIFY V1` con una parola diversa da `C1` … `C8` | **E33** `VERIFY V1 nomina un controllo che non esiste: W` |
| due estensioni con lo stesso nome nello stesso profilo | **E34** `nome di estensione già usato alla riga N: X`, sulla seconda |
| il nome dell'estensione è una parola chiave o riservata (sezione 2.3) | **E34** `il nome dell'estensione è una parola del linguaggio: X`; la riga è riconosciuta come intestazione, senza nome registrato |
| `REDUCES TO` nomina una parola che non è del linguaggio, un parametro dell'estensione né un'altra estensione dello stesso profilo (le unità `s` e `ms` dopo un numero sono parte del numero, G27, e non sono nomi) | **E35** `REDUCES TO nomina X: non è una parola del linguaggio, un parametro né un'estensione del PROFILE P` |
| le estensioni dello stesso profilo si nominano in giro con `REDUCES TO` | **E35** `REDUCES TO in giro: A -> B -> A`, sul membro del giro che viene prima nel file |
| `REDUCES TO`, tolte le parentesi intorno a un solo elemento, è **un solo costrutto** delle regole G55-G63 (un pattern, un ambito, una funzione, una storia, una fase, `IF`, un operatore come `NOT`, `AND`, `+`, `<=`), o un solo uso di un'altra estensione, i cui operandi e posti sono **tutti** parametri, ciascuno una volta, in qualunque ordine, anche quando il costrutto comincia con un posto (`p PRECEDES q`, `(p) PRECEDES q`, `x REQUIRES c`, `ABS(x)`, `MAX(x, y)`, `COUNT(p) IN LAST d`, `requested(x)`, `NOT c`, `x + y`, `(IF c THEN a ELSE b)`). Due estensioni con la stessa riduzione a parte i nomi dei parametri non sono segnalate in questa versione (sezione 14) | **E36** `l'EXTENSION X ripete una forma che il linguaggio ha già: F` (con `F` la prima parola o il segno del costrutto, per esempio `NEVER`, `PRECEDES`, `FOR AT LEAST`, `ABS`, `COUNT`, `requested`, `NOT`, `+`, `IF`), oppure `l'EXTENSION X ripete l'EXTENSION Y` |

- **`FORM`** è normativo: il testo della stringa si divide in elementi con le regole della sezione 2; una parola
  uguale a un nome di parametro è il **posto** di quel parametro, ogni altro elemento è **fisso**. La prima parola è
  il nome dell'estensione.
- **`PARAMS`**: ogni parametro ha un tipo (G13) o una **categoria**: `Name` (un nome dichiarato), `Type` (un tipo),
  `Event` (un evento, G62), `Condition` (un'espressione `Boolean`), `Expression` (un'espressione), `Duration` (una
  durata con unità: è il tipo `Duration`), `Property` (una proprietà intera, G55). Un tipo non dichiarato è ammesso e
  compare nella sezione 6. I nomi dei parametri valgono solo nell'estensione; due parametri con lo stesso nome sono
  E01.
- **`REDUCES TO`** (`RiduzioneEst` in G54) si legge secondo il `KIND`: una proprietà (G55) per `PATTERN`,
  `DECLARATION` e `RELATION`; un ambito (G56) per `SCOPE`; un'espressione (G59) per `FUNCTION`; uno o più elementi
  di passo (G22), separati da virgole, per `SCENARIO-FORM`. I parametri vi stanno al posto di nomi, eventi,
  espressioni o proprietà, secondo la loro categoria: un parametro di categoria `Event` sta dove sta un evento,
  uno di categoria `Property` dove sta una proprietà intera (G55), uno di categoria `Type` dove sta un tipo, ogni
  altro dove sta un `Primario` (G60). La forma `X REQUIRES c` vi è ammessa: E27 sulla `GUARANTEE` vale per le righe
  contrattuali, non per le riduzioni. `check` controlla i nomi (E35) e la forma; non controlla i tipi, che dipendono
  dagli argomenti di ogni uso. Una riduzione che non rispetta la sua regola non è riconosciuta: il campo conta come
  presente (niente E33), ma l'estensione vale come **senza** `REDUCES TO` per il grado dei suoi usi (sezione 4.14),
  ed E36 non si controlla su di lei. E35 invece si controlla prima della forma, su ogni riga `REDUCES TO`: un nome
  che non esiste è un errore certo qualunque sia la forma, e la riga con E35 resta riconosciuta (sezione 8). Così
  `REDUCES TO EVENTUALLY p WITHIN 1 min` dà E35 su `min`, e `WITHIN d s` (con `d` parametro) dà E35 su `s`, perché
  un'unità è tale solo dopo un numero sulla stessa riga (G27).
- **`VERIFY`** (G46): con `V1` elenca i controlli che sanno trattare la forma, con `V2` che cosa conta come
  osservazione; oppure `BY JUDGEMENT` o `BY INSPECTION` con la loro stringa. Il `;` fra le due parti è un segno
  (L5).
- **Le regole a giudizio** sulle estensioni (il significato non descrive la realizzazione né dà autorità o
  precedenza fra parti; un'estensione senza `REDUCES TO` non ripete una forma che il linguaggio ha già; `MEANING` e
  `REDUCES TO` dicono la stessa cosa) sono voci della sezione 14 del rapporto (sezione 9.7), mai errori.
- Un'estensione con almeno un errore E33-E36 nel suo file non si può usare: un blocco che la importa tratta le righe
  che la usano come righe con un profilo non trovato (sezione 4.14).

#### Le righe

Le righe di questi blocchi sono riconosciute, commenti, vuote o non riconosciute come in ogni altro blocco. Nella
riga `blocchi:` del rapporto un `BINDING`, una `VERIFICATION` e un `PROFILE` contano come blocchi; un'`EXTENSION` no,
perché sta nel suo profilo. Un file che contiene solo blocchi `BINDING`, `VERIFICATION` o `PROFILE` non ha E11.

Nessun blocco del linguaggio resta non letto: la sezione 11 del rapporto, che li elencava, non c'è più, e il suo
numero non si usa.

### 4.12 Le formule

Una **formula** è una proprietà scritta in una forma che `bcdd` legge per intero (G55): un ambito facoltativo e un
pattern, con le espressioni che li compongono. Sta dopo i due punti di una `GUARANTEE` o di un'`ASSUME` (G17);
le espressioni stanno anche nel valore di una `DEFINE` (G12) e nella `REDUCES TO` di un'estensione (G54).

```
G55  Formula      = { "FOR" "ALL" Nome "IN" Nome ":" } [ Ambito ":" ] Pattern ;
G56  Ambito       = "WHILE" Espr
                  | "AFTER" Evento [ "UNTIL" Evento ]
                  | "BEFORE" Evento
                  | "BETWEEN" Evento "AND" Evento
                  | UsoEstensione ;                                   (KIND SCOPE)
G57  Pattern      = "ALWAYS" Espr
                  | "EVENTUALLY" Espr [ "WITHIN" Espr ]
                  | "WHENEVER" Espr "THEN" Espr [ "WITHIN" Espr | "AT" "ONCE" ]
                  | "NEVER" Espr
                  | Espr "PRECEDES" Espr
                  | Espr "FOR" "AT" "LEAST" Espr
                  | "ACCEPTS" Nome "ONLY" "WHILE" Espr
                  | Nome "REQUIRES" Espr
                  | Nome "ENSURES" Espr
                  | "RESOLVES" Nome "WITHIN" Espr
                  | "TRANSITION" Nome ":" Transizione { "," Transizione }
                  | UsoEstensione ;                                   (KIND PATTERN)
G58  Transizione  = Nome "->" Nome "ON" Evento [ "WHEN" Espr ] ;
G59  Espr         = "FOR" "ALL" Nome "IN" Nome ":" Espr | Implicazione ;
     Implicazione = Logica [ "IMPLIES" Logica ] ;
     Logica       = Negazione { "AND" Negazione } | Negazione { "OR" Negazione } ;
     Negazione    = "NOT" Negazione | Confronto ;
     Confronto    = Somma [ ( "=" | "<>" | "<" | "<=" | ">" | ">=" ) Somma
                          | "IN" "{" Valore { "," Valore } "}" ] ;
     Somma        = Prodotto { ( "+" | "-" ) Prodotto } ;
     Prodotto     = Meno { ( "*" | "/" ) Meno } ;
     Meno         = "-" Meno | Potenza ;
     Potenza      = Postfisso [ "^" Postfisso ] ;
     Postfisso    = Primario { "[" Espr "]" | "." Nome } ;
G60  Primario     = NumeroConSegno [ Unita ] | Stringa | "true" | "false" | "ABSENT"
                  | Nome | "(" Espr ")" | "(" "IF" Espr "THEN" Espr "ELSE" Espr ")"
                  | Funzione | Storia | Fase | Chiamata | "(" Evento ")"
                  | UsoEstensione ;                                   (KIND FUNCTION)
     Funzione     = ( "ABS" | "LOG10" | "ROUND" | "FLOOR" | "CEIL" | "PREV" | "PRESENT" | "CHANGED" ) "(" Espr ")"
                  | ( "MIN" | "MAX" ) "(" Espr "," Espr { "," Espr } ")" ;
G61  Storia       = "COUNT" "(" Evento [ "SINCE" Evento ] ")" [ "IN" "LAST" Postfisso ]
                  | "TIME" "SINCE" Evento
                  | "LAST" "(" Evento ")"
                  | "ONCE" Evento ;
G62  Evento       = RifEvento [ "WITH" Espr ] ;
     RifEvento    = Nome | Fase | "(" Evento ")" ;
     Fase         = ( "requested" | "accepted" | "rejected" | "completed" | "failed" ) "(" Nome [ "." Nome ] ")" ;
G63  Chiamata     = Nome "(" Nome ":" Espr { "," Nome ":" Espr } ")" ;
G64  UsoEstensione = Nome { Elemento } ;      (si legge secondo il FORM dell'estensione, sezione 4.14)
```

**Come si legge.** Le regole della sezione 4 valgono anche qui: una formula è riconosciuta solo se tutti i suoi
elementi rispettano G55, senza niente in più. Alcune scelte si fanno guardando un elemento avanti:
- dopo `FOR` viene `ALL` (quantificazione) oppure `AT LEAST` (G57);
- dopo `IN` viene `LAST` (G61), `{` (insieme di valori) oppure, in `FOR ALL i IN T`, il nome di un tipo;
- fra parentesi, se al primo livello c'è `WITH`, il contenuto è un evento con filtro (`(frame WITH ch = L)`),
  altrimenti un'espressione;
- un nome seguito da `(` e da `Nome :` è una chiamata di una `DEFINE` con parametri (G63); un nome che è il nome di
  un'estensione di `KIND FUNCTION` di un profilo importato è un uso dell'estensione (sezione 4.14);
- un nome che è il nome di un'estensione di `KIND PATTERN` o `SCOPE` di un profilo importato, nella posizione di un
  pattern o di un ambito, è un uso dell'estensione.

**Precedenza**, dal legame più forte al più debole:

| Livello | Operatori | Associatività |
|---|---|---|
| 1 | `x[i]`, `x.campo` | da sinistra |
| 2 | `^` | **nessuna**: `a ^ b ^ c` è l'errore E26 |
| 3 | `-` davanti a un valore | da destra |
| 4 | `*`, `/` | da sinistra |
| 5 | `+`, `-` | da sinistra |
| 6 | `=`, `<>`, `<`, `<=`, `>`, `>=`, `IN` | **nessuna**: `a <= b <= c` è l'errore E26 |
| 7 | `NOT` | da destra |
| 8 | `AND` e `OR` | lo stesso operatore si ripete (`a AND b AND c`); `AND` e `OR` mescolati senza parentesi sono l'errore E26 |
| 9 | `IMPLIES` | **nessuna**: `a IMPLIES b IMPLIES c` è l'errore E26 |
| 10 | `FOR ALL i IN T:` | il corpo arriva fino alla fine dell'espressione che lo contiene; dentro un'altra espressione sta fra parentesi |

Così `NOT a AND b` è `(NOT a) AND b`, `a AND b IMPLIES c` è `(a AND b) IMPLIES c`, `-x ^ 2` è `-(x ^ 2)` e `x + y * 2`
è `x + (y * 2)`. `e WITH c` prende come condizione tutta l'espressione che segue, fino a `SINCE`, a `)`, a `:` o alla
fine della formula: `TIME SINCE (frame WITH ch = L) > 5 s` si scrive con le parentesi, perché senza di esse la
condizione sarebbe `ch = L > 5 s`, un confronto in catena (E26). `IF … THEN … ELSE` sta sempre fra parentesi:
`DEFINE soglia := (IF notte THEN 10 ELSE 30)`; senza parentesi la riga non è riconosciuta.

**`IN LAST` lega più di ogni operatore.** La durata di `COUNT( … ) IN LAST d` è un `Postfisso` (G61): un numero con
unità, un nome, una funzione, una chiamata o un'espressione fra parentesi. Così `ALWAYS COUNT(accendi) IN LAST 0.2 s
<= 1` è `(COUNT(accendi) IN LAST 0.2 s) <= 1`, e `COUNT(frame) IN LAST EVAL / (fs * EVAL)` divide il conteggio. Una
durata calcolata si scrive fra parentesi: `COUNT(e) IN LAST (2 * DURATA) > 3`.

**Una fase con il nome qualificato.** `Fase` (G62) ammette `Nome "." Nome` per le formule d'entità, dove il primo
nome è un connettore (sezione 4.9): `requested(Sessione.Abbina)`. In una CSC una fase con il nome qualificato è
l'errore **E20** con il messaggio della CSC (sezione 4.6), anche quando il primo nome è una richiesta della CSC
stessa. Dopo una fase, `WITH` sta solo dove sta un evento (G62) o dentro le parentesi di `"(" Evento ")"`:
`ALWAYS requested(Pulizie) WITH f = "x"` non è riconosciuta, come `ALWAYS e WITH c`.

**Errori di forma.** Una formula che `bcdd` legge per intero e che viola una regola del linguaggio dà un errore; la
dichiarazione resta riconosciuta, come con E13:

| Caso | Errore |
|---|---|
| `AND` e `OR` allo stesso livello senza parentesi | **E26** `AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)`, sul primo operatore che cambia |
| `IMPLIES` dopo `IMPLIES` senza parentesi | **E26** `IMPLIES dopo IMPLIES senza parentesi: scrivi a IMPLIES (b IMPLIES c)`, sul secondo |
| un confronto dopo un confronto senza parentesi | **E26** `confronti in catena: scrivi a <= b AND b <= c`, sul secondo |
| `^` dopo `^` senza parentesi | **E26** `^ dopo ^ senza parentesi: scrivi (a ^ b) ^ c`, sul secondo |
| una parola di pattern (`ALWAYS`, `EVENTUALLY`, `WHENEVER`, `NEVER`, `ACCEPTS`, `RESOLVES`, `TRANSITION`) dove sta un'espressione, oppure `PRECEDES`, `FOR AT LEAST`, `REQUIRES`, `ENSURES` dentro l'operando di un altro pattern | **E27** `K dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni`, con `K` la parola annidata |
| un secondo ambito dopo il primo (`WHILE c: AFTER e: …`) | **E27** `una proprietà ha un solo ambito: K è il secondo` |
| `WITHIN … AT ONCE` nello stesso pattern | **E27** `WITHIN e AT ONCE nella stessa proprietà: scegline uno` |
| `X REQUIRES c` in una `GUARANTEE` | **E27** `REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)` |

Ogni altra forma che non rispetta G55-G64 (per esempio `ALWAYS p WITHIN 1 s`, `WHENEVER p` senza `THEN`, una
parentesi in più, `MIN(x)` con un solo argomento) non è riconosciuta, senza errore. Riga e colonna di E26 e E27:
quelle della parola o del segno indicati. Una formula con E26 o E27 non dà E25: i tipi di una formula di forma
sbagliata non sono certi. I nomi vi si controllano comunque (E24, E29).

**Le forme di BASE.** `NEVER`, `AFTER`, `BEFORE`, `AFTER … UNTIL`, `BETWEEN … AND`, `PRECEDES`, `FOR AT LEAST`,
`ACCEPTS … ONLY WHILE`, `REQUIRES`, `ENSURES`, `RESOLVES`, `ONCE`, `CHANGED`, `TRANSITION`, `FOLLOWS` (G11), gli
indici (G11, G20), `FOR ALL` e `REPEAT m..n` (G47) sono abbreviazioni: il loro significato è la forma estesa del
manuale. `check` le legge come forme a sé e ne controlla nomi e tipi; non scrive la forma estesa. `TRANSITION s: A
-> B ON e [WHEN c], …` è una promessa sola su un insieme chiuso di transizioni dello stato `s`: `s` è uno `STATE`
con un elenco di valori come tipo, `A` e `B` sono valori di quell'elenco, `e` è un evento, `c` una condizione.

**`FOR ALL i IN T`.** `T` è un tipo finito (lo stesso della sezione 4.3 per gli indici: E29 altrimenti); `i` vale
nel corpo e non deve essere un nome del blocco (E01). In testa a una formula (G55) quantifica la proprietà intera;
dentro un'espressione (G59) quantifica la condizione che segue.

### 4.13 Nomi e tipi

`check` controlla in modo statico i **nomi** e i **tipi** delle formule, delle espressioni delle `DEFINE`, delle
dichiarazioni (G11) e dei valori delle storie. Non calcola nessun valore: sa che `COUNT(e)` è un intero, non quanto
vale.

**I nomi.** Un nome in una formula di una CSC è, nell'ordine: una variabile di `FOR ALL` che lo contiene; un
parametro della `DEFINE` che lo contiene; un parametro dell'evento di `e WITH c`, dentro `c`; un nome del blocco
(sezione 5); il nome di un'estensione dei profili importati e trovati (sezione 4.14). Altrimenti, se il blocco
importa un profilo non trovato, la dichiarazione non è riconosciuta, con il motivo (sezione 4.14); se no è l'errore
**E24** `nome non dichiarato: X`. Un nome scritto solo in una dichiarazione non riconosciuta (per esempio `EVENT IN
pressione FACE utente`) non è un nome del blocco (sezione 4.5): una formula che lo usa dà E24, come un passo dà E03.
L'errore indica la riga da correggere; la dichiarazione scritta male è nella sezione 5 del rapporto. Ogni posizione
chiede un **genere**:

| Posizione | Genere chiesto | Errore se il nome è d'altro genere |
|---|---|---|
| un evento: `AFTER`, `BEFORE`, `UNTIL`, `BETWEEN … AND`, `ON`, `COUNT( … )`, `SINCE`, `TIME SINCE`, `LAST( … )`, `ONCE`, a sinistra di `WITH` | un `EVENT`, una `DEFINE EVENT` o una fase di una richiesta | **E24** `X non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY` |
| una richiesta: dentro una fase (`requested(X)` …), `ACCEPTS X`, `X REQUIRES`, `X ENSURES`, `RESOLVES X` | una `CAPABILITY` | **E24** `X non è una CAPABILITY` |
| uno stato: lo stato di `TRANSITION`, l'argomento di `PREV` e di `CHANGED` | uno `STATE` (anche con indice o con un campo) | **E24** `X non è uno STATE` |
| un valore o una condizione: ogni altra posizione | uno `STATE`, una `DEFINE` senza parametri, una variabile o un parametro, un valore di un elenco di valori, un evento (solo come condizione), un nome dato da un'estensione | **E24** `X è una CAPABILITY: si nomina con una fase (requested(X), …) o in ACCEPTS, REQUIRES, ENSURES, RESOLVES`, per una richiesta; un tipo, una storia o un nome breve danno `X non è un valore` |
| un campo: `x.c`, `LAST(e).c` | un campo del `Record` di `x`, o un parametro di `e` | **E24** `nome non dichiarato come campo di T: c` |
| una chiamata `nome(p: a, …)` | una `DEFINE` con parametri; ogni `p` un suo parametro, ciascuno una volta | **E24** `X non è una DEFINE con parametri`; `nome non dichiarato come parametro di X: p`; `manca l'argomento p nella chiamata di X`. Se un argomento ha un nome che non è un parametro, la chiamata dà solo quell'errore, senza «manca l'argomento»: un nome sbagliato è un errore solo. Due argomenti con lo stesso nome sono E01 |
| un indice: `x[i]` | un valore del tipo dell'indice di `x`, o una variabile di `FOR ALL` su quel tipo | **E29** `indice di X non del tipo T: v`, anche quando `v` non è dichiarato: il messaggio dice che cosa serve |

Riga e colonna di E24: quelle del nome. Con un nome qualificato (in un'entità, sezione 4.9) quelle di `X`.

**I tipi.** Ogni espressione ha un tipo: `Boolean`, `Integer`, `Real`, `Duration`, `String`, un elenco di valori, un
`Record`, `Sequence of T`, `Optional T`, oppure un tipo **non noto**. Un tipo non noto è quello di un tipo non
dichiarato, di un tipo descritto a parole (G30), di una costante `UNDECIDED`, di un nome dato da un'estensione, e,
in una formula d'entità, di ogni elemento `X.y` di una CSC citata (sezione 4.9). Un'espressione di tipo non noto si accetta
in ogni posizione, e il risultato di un'operazione su di essa ha tipo non noto: `check` non dà errori che non sono
certi.

| Espressione | Tipo |
|---|---|
| un numero senza punto, senza unità | `Integer` |
| un numero con il punto, senza unità | `Real` |
| un numero con `s` o `ms` | `Duration` |
| una stringa | `String` |
| `true`, `false`; un confronto; `NOT`, `AND`, `OR`, `IMPLIES`; `IN { … }`; `PRESENT(x)`; `CHANGED(x)`; `ONCE e`; un evento usato come condizione (vero nel passo in cui accade) | `Boolean` |
| `ABSENT` | `Optional` di qualunque tipo |
| un valore di un elenco di valori | quell'elenco |
| uno stato, una costante, un parametro, un campo | il suo tipo; con un nome dato da G41, il tipo nominato; `Integer [a .. b]` e `Real [a .. b]` valgono come `Integer` e `Real` (i limiti non si propagano) |
| `COUNT( … )`, con o senza `IN LAST` | `Integer` |
| `TIME SINCE e` | `Duration` |
| `LAST(e).p` | il tipo del parametro `p` |
| `PREV(x)` | il tipo di `x` |
| `(IF c THEN x ELSE y)` | il tipo di `x` e di `y`, che devono avere lo stesso tipo (`Integer` e `Real` danno `Real`) |
| `a + b`, `a - b` | `Integer` se tutti e due sono `Integer`, `Real` se sono numeri, `Duration` se sono tutti e due `Duration` |
| `a * b` | come `+` per due numeri; `Duration` per una durata e un numero, in qualunque ordine |
| `a / b` | `Real` per due numeri; `Duration` per una durata divisa per un numero; `Real` per due durate |
| `a ^ b`, `LOG10(a)` | `Real`; gli operandi sono numeri |
| `- a`, `ABS(a)` | il tipo di `a`, numero o durata |
| `ROUND(a)`, `FLOOR(a)`, `CEIL(a)` | `Integer`; l'operando è un numero |
| `MIN( … )`, `MAX( … )` | il tipo comune degli argomenti, tutti numeri o tutti durate |
| una chiamata `nome( … )` | il tipo dell'espressione della `DEFINE`; ogni argomento ha il tipo del suo parametro |
| un uso di un'estensione di `KIND FUNCTION` | il tipo del risultato in `PARAMS` |

| Posizione | Tipo chiesto |
|---|---|
| condizione: `WHILE`, `ALWAYS`, `EVENTUALLY`, `WHENEVER` e `THEN`, `NEVER`, le due parti di `PRECEDES`, la parte sinistra di `FOR AT LEAST`, `ONLY WHILE`, `REQUIRES`, `ENSURES`, `WHEN`, `WITH`, la condizione di `IF`, gli operandi di `NOT`, `AND`, `OR`, `IMPLIES`, il corpo di `FOR ALL` dentro un'espressione, il valore di una `DEFINE EVENT` | `Boolean` |
| durata: `WITHIN`, `IN LAST`, la parte destra di `FOR AT LEAST`, `RESOLVES … WITHIN` | `Duration` |
| `=` e `<>` | due operandi dello stesso tipo: due numeri, due durate, due stringhe, due `Boolean`, due valori dello stesso elenco; `Optional T` con `T` o con `ABSENT` |
| `<`, `<=`, `>`, `>=` | due numeri o due durate |
| `x IN {v, …}` | ogni `v` è un valore del tipo di `x` |
| `x[i]` | `x` ha un indice, e `i` è un valore o una variabile di `FOR ALL` del tipo dell'indice (E29) |
| `PRESENT(x)` | `x` di tipo `Optional` |

In ogni altra posizione un'espressione `Optional T` vale come `T`: `check` non segue se il valore c'è. Così, con `c`
di tipo `Optional Campione` e `Campione` un `Record`, `c.L` è il campo `L` del record.

Un'espressione del tipo sbagliato è l'errore **E25** `tipo incoerente: serve A, trovato B`, con `A` e `B` scritti
come nella tabella (`Boolean`, `Duration`, `un numero`, `un numero o una durata`, il nome di un elenco di valori, …;
un evento in una posizione di valore si scrive `un evento`). Riga e colonna: quelle del primo elemento
dell'espressione. Esempi: `EVENTUALLY accesa WITHIN 60` dà `tipo incoerente: serve Duration, trovato Integer`;
`ALWAYS COUNT(pressione)` dà `tipo incoerente: serve Boolean, trovato Integer`; `WHENEVER pressione THEN fase =
accesa`, con `accesa` di un altro elenco di valori, dà `tipo incoerente: serve Fase, trovato Modo`.

**I valori scritti.** Gli stessi tipi si confrontano con i valori scritti (G26) in `INITIAL` (G11), nel `GIVEN` e
nelle assegnazioni delle storie (G20) e negli argomenti degli eventi nei passi (G25):

| Tipo dichiarato | Valori ammessi |
|---|---|
| `Boolean` | `true`, `false` |
| `String` | una stringa |
| `Duration` | un numero con `s` o `ms` |
| `Integer [a .. b]` | un numero senza punto e senza unità, fra i limiti scritti (compresi; un limite omesso non limita) |
| `Real [a .. b]` | un numero senza unità, fra i limiti scritti |
| un elenco di valori `E` | un valore di `E` |
| `Optional T` | `ABSENT`, o un valore ammesso per `T` |
| `Record`, `Sequence of T` | nessuno: nei passi si scrive `_` |
| un tipo non noto | qualunque valore |

Un valore non ammesso è l'errore **E25** `valore non del tipo T: V`, con `T` il tipo come è scritto nella
dichiarazione e `V` il valore come è scritto; riga e colonna quelle del valore. Un nome che non è un valore di nessun
elenco di valori del blocco resta l'errore E03 (sezione 4.4), senza un E25 in più. `_` è sempre ammesso negli
argomenti. In una storia d'entità vale la regola della sezione 4.6.

### 4.14 L'uso delle estensioni

Un blocco usa le estensioni dei profili che importa nella sua zona d'intestazione (sezione 4.2), e solo quelle:
un'estensione di un profilo non importato non esiste per il blocco, anche se il profilo sta nello stesso file.

**Dove si riconosce un uso.** Un nome è un uso di un'estensione quando è il nome di un'estensione di un profilo
importato e trovato, e sta nella posizione che il suo `KIND` prevede:

| `KIND` | Posizione |
|---|---|
| `PATTERN` | il posto del pattern in una formula (G57) |
| `SCOPE` | il posto dell'ambito in una formula (G56), seguito da `:` |
| `FUNCTION` | il posto di un `Primario` in un'espressione (G60) |
| `DECLARATION` | la prima parola di una dichiarazione del blocco |
| `RELATION` | la prima parola di una dichiarazione di un'entità |
| `SCENARIO-FORM` | il posto di un elemento di un passo (G22) |

Il blocco deve essere del `LEVEL` dell'estensione: `CSC` in una CSC, `ENTITY` in un'entità, `BINDING` in un
`BINDING`, `VERIFICATION` in una `VERIFICATION`. Un'estensione usata in un blocco di un altro livello, o in una
posizione di un altro `KIND`, è l'errore **E37** `X ha LEVEL L: non si usa in un blocco B` oppure `X ha KIND K: non
si usa in questa posizione`.

**Come si legge un uso.** Gli elementi che seguono il nome si confrontano con il `FORM`: ogni elemento fisso deve
esserci, uguale; ogni posto di un parametro prende un argomento, che si legge fino all'elemento fisso successivo
del `FORM` (o, per l'ultimo posto, fino alla fine della posizione: la fine della formula, della dichiarazione o
dell'elemento di passo; dentro parentesi, la `)` o la `,` allo stesso livello che chiude o separa ciò che contiene
l'uso). Così `MAX(SQ r, 1.0)` e `(SQ r) > 1.0` sono letti, mentre `SQ r > 1.0` dà a `SQ` l'argomento `r > 1.0`. Un
`FORM` di `KIND FUNCTION` che finisce con un elemento fisso (`"NEAR ( x , a , t )"`) non ha questo problema. L'argomento deve essere della categoria o del tipo del parametro:

| Il parametro | L'argomento |
|---|---|
| `Name` | un nome del blocco; in un uso di `KIND DECLARATION`, il primo posto `Name` del `FORM` è invece il **nome dichiarato** dalla riga (vedi sotto) |
| `Type` | un tipo (G13) |
| `Event` | un evento (G62) |
| `Condition` | un'espressione `Boolean` |
| `Expression` | un'espressione |
| `Duration` | un'espressione `Duration` |
| `Property` | una proprietà (G55) |
| un tipo | un'espressione di quel tipo; un tipo non dichiarato accetta qualunque espressione |

Un uso che non rispetta il `FORM` è l'errore **E37** `uso di X che non rispetta FORM "F"`, sul nome; un argomento di
una categoria sbagliata dà E24 o E25 come in una formula. Esempio, con il profilo `Segnale` della sezione 4.11
importato: `GUARANTEE g10: WHILE modo = spenta: FADE luminosita WITHIN 2 s` usa `FADE`, con `s` = `luminosita` e
`d` = `2 s`.

**I nomi dichiarati da un'estensione.** In un uso di `KIND DECLARATION` (per esempio `SIGNAL needle[Ch] : Real [0.0
.. 1.0]`, con `FORM "SIGNAL nome[I] : T"`), l'argomento del primo posto `Name` è un nome nuovo del blocco: entra
nell'elenco dei nomi (E01 se ripetuto) e si usa nelle formule come valore o come condizione, con tipo non noto e con
o senza indice, senza controllo. Non è un evento né una richiesta. Un uso di `KIND DECLARATION` che non rispetta il
`FORM` è l'errore E37 sul nome dell'estensione: la dichiarazione resta riconosciuta (sezione 8) ma non registra
nessun nome, perché non si sa quale elemento sia il nome; dove quel nome è usato c'è E24, come per un nome scritto
solo in una dichiarazione non riconosciuta (sezione 4.13). Il nome di un'estensione di `KIND PATTERN`, `SCOPE` o
`FUNCTION` come prima parola di una dichiarazione è l'errore E37 `X ha KIND K: non si usa in questa posizione`, e la
dichiarazione resta riconosciuta.

**Il grado.** Le estensioni che una formula usa sono tutte quelle che vi compaiono, anche dentro l'argomento di un
altro uso (`DURING (NEAR r TO 1.0): …` usa `DURING` e `NEAR`), più quelle che usano, a qualunque profondità, le
`DEFINE` che la formula nomina (costanti, chiamate, `DEFINE EVENT`): con `DEFINE K := SQ r`, `ALWAYS K > 0.0` usa
`SQ`. Questo insieme vale per il grado, per la sezione 15 del rapporto (sezione 9.7) e per lo stato (punto 0a della
sezione 7.1). Una formula che usa almeno un'estensione senza `REDUCES TO` riconosciuta è di grado **estensione
dichiarata**; se tutte le estensioni che usa hanno una `REDUCES TO` riconosciuta è **formale** (sezione 6).

**Gli usi che questa versione non legge.** `bcdd` 1.0-beta non legge gli usi delle estensioni di `KIND RELATION` e
`KIND SCENARIO-FORM`. Una dichiarazione d'entità che comincia con il nome di un'estensione `RELATION`, e un passo
con un elemento che è un uso di un'estensione `SCENARIO-FORM`, non sono riconosciuti e compaiono nella sezione 5
del rapporto (con `--strict`, codice 3). Questi usi non dichiarano nomi, quindi non lasciano errori nelle righe che
seguono (sezione 14).

**Un profilo non trovato.** Se un blocco importa un profilo che `bcdd` non trova (sezione 4.2), oppure un'estensione
con errori nel suo file, una dichiarazione del blocco che contiene un nome che non si risolve altrimenti (un nome che
la sezione 4.13 darebbe come E24, o la prima parola di una dichiarazione che nessuna regola della sezione 4 accetta)
**non è riconosciuta**, con il motivo nella sezione 5 del rapporto: ` (profilo P VERSION v non trovato)` oppure
` (EXTENSION X del PROFILE P con errori)`. Non è un errore: il nome potrebbe venire proprio da quel profilo, e un
errore si segnala solo quando è certo. Con `--strict` la riga fa uscire con il codice 3.

**Lo stato.** Una riga contrattuale che usa un'estensione di un profilo **da approvare** è da approvare, anche in una
CSC approvata (sezione 7.1).

**Totale: 13 regole delle parole (L1-L13), 5 regole di divisione (U1-U5), 64 regole delle dichiarazioni (G1-G64,
con G12a e le varianti G20e, G23e, G24e delle storie d'entità). G30, G37, G41 e G42 stanno nella sezione 4.4; G36 e
G47 nella 4.6; G31-G35 nella 4.9; G38 nella 4.10; G39 nella 4.2; G40, G43-G46 e G48-G54 nella 4.11; G55-G64 nella
4.12. G2 serve solo al rapporto di un blocco ritirato e G29 non vale in nessun posto (sezione 4.8); la numerazione è
conservata.**

---

## 5. Dove vale ogni dichiarazione

Una dichiarazione scritta bene ma nel posto sbagliato non è riconosciuta.

| Dove | Che cosa vi è riconosciuto | Note |
|---|---|---|
| **Fuori da un blocco** | G1, G31, G40, G48, G49 | `END` qui è l'errore E08; una dichiarazione che comincia con `REFINEMENT` è l'errore E15 e apre un blocco ritirato (sezione 4.8); una che comincia con `EXTENSION` è l'errore E32 (sezione 4.11); tutto il resto è non riconosciuto |
| **Dentro `CSC … END`** | G3, G4, G6, G7, G8, G11, G12, G16, G19, G21, G30, G37, G39, G41, G47, usi di estensioni di `KIND DECLARATION` e `LEVEL CSC` | vedi le tre righe seguenti; una dichiarazione che comincia con `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` o `PROFILE` chiude la CSC con E07; una che comincia con `EXTENSION` è E32; G32, G33 e G34 vi sono non riconosciute. Un nome qualificato in una storia è E20 (sezione 4.6) |
| — `STATUS`, `IMPORT PROFILE` | in qualunque punto della zona d'intestazione, in qualunque ordine con `PURPOSE` (sezione 4.2); `STATUS` al più una volta | un secondo `STATUS` nella zona è E10; dopo la zona non sono riconosciuti |
| — `PURPOSE` | esattamente uno per CSC | se manca o è ripetuto: E10 |
| — passi `@` e `REPEAT` | solo dopo una riga che comincia con `SCENARIO` (anche se quella non è riconosciuta), con soli passi, righe `REPEAT` (G47), commenti e righe vuote fra i due | ogni altra dichiarazione chiude la storia; una riga `REPEAT` fuori da una storia non è riconosciuta |
| **Dentro `BINDING … END`** | G3, G4, G39 nella zona d'intestazione, G51, usi di estensioni di `KIND DECLARATION` e `LEVEL BINDING` | sezione 4.11; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono il blocco con E07; `EXTENSION` è E32 |
| **Dentro `VERIFICATION … END`** | G3, G39 nella zona d'intestazione, G52, G53 con i suoi passi G21 e le righe G47, usi di estensioni di `KIND DECLARATION` e `LEVEL VERIFICATION` | `STATUS` è E39 in qualunque punto; per il resto come in un `BINDING` |
| **Dentro `PROFILE … END`** | G3, G4 e G6 nella zona d'intestazione, G50 che apre un'estensione | ogni altra dichiarazione è non riconosciuta; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono il profilo con E07 |
| **Dentro `EXTENSION … END`** (in un profilo) | G3, G43, G44, G45, G46, G54 | ogni altra dichiarazione è non riconosciuta; `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono l'estensione e il profilo, con un E07 sul profilo |
| **Dentro un blocco ritirato** (`REFINEMENT …` fino a `END`) | solo G3 | ogni altra dichiarazione è non riconosciuta e non registra nomi; `CSC`, `ENTITY` e `REFINEMENT` chiudono il blocco con E07 (sezione 4.8) |
| **Dentro `ENTITY … END`** | G3, G4 solo con `STATUS HYPOTHESIS`, G39 nella zona d'intestazione, G6, G32, G33, una sola G28, G34, G16 con `GUARANTEE` (con ogni `STATUS`, come nella CSC, e con le formule della sezione 4.9), G19, G21 e G47 con i nomi qualificati (sezione 4.6), G38 (sezione 4.10), usi di estensioni di `KIND RELATION` e `LEVEL ENTITY` | vedi le sei righe seguenti. `OFFERS` e `USES` in qualunque punto. Le parole che aprono un blocco vi chiudono l'entità con E07, come nella CSC; `EXTENSION` è E32 |
| — pezzi `VARIANT` | da una riga G38 alla successiva o a `END`: G32, G33, una G28 per pezzo, G34, G16 con `GUARANTEE`, G19 e G21 | `PURPOSE` è E21; gli altri casi nella sezione 4.10. In un blocco `CSC` una dichiarazione che comincia con `VARIANT` è E21 |
| — `STATUS` | solo `STATUS HYPOTHESIS`, in qualunque punto della zona d'intestazione (sezione 4.9); un secondo `STATUS HYPOTHESIS` nella zona è E10 | ogni altro `STATUS`, compresi `STATUS RATIFIED BY D-n` valido e `STATUS RATIFIED` senza decisione, non è riconosciuto, **senza** E04; lo stato del blocco resta `senza STATUS`: l'intestazione di un'entità non è mai approvata. **Dentro una `GUARANTEE`** valgono gli `STATUS` della CSC: `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-n`, e `STATUS RATIFIED` senza decisione con E04 (la promessa resta riconosciuta e da approvare) |
| — `PURPOSE` | esattamente uno per entità | se manca o è ripetuto: E10 |
| — parti G34 | in qualunque punto dell'entità, anche senza `COMPOSED OF` | ogni dichiarazione che rispetta G34 è una parte; `COMPOSED OF` si scrive una volta sola, dove si vuole, e una seconda non è riconosciuta, senza effetto. Le regole, il perché e i casi limite sono subito sotto la tabella |
| — `SCENARIO`, passi `@` | riconosciuti con G19, G21 e le varianti G20e, G23e, G24e (sezione 4.6) | come nella CSC: i passi solo dopo una riga che comincia con `SCENARIO`, con soli passi, commenti e righe vuote fra i due |
| — `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` | **non** riconosciute, ed **errore E18** sulla parola chiave, qualunque cosa la segua | un'entità non ha elementi propri. Non registrano nessun nome, nemmeno `ASSUME` con intestazione della riga valida né `DEFINE Nome :=`, e non compaiono nella sezione 2. Le righe `VERIFY` e `VERBAL` che continuano un'`ASSUME` (U4) restano non riconosciute con lei, senza un altro E18. Casi sotto la tabella |

**L'errore E18.** Un'entità non ha `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` né `ASSUME` propri: `bcdd` legge
la parola chiave e sa che è fuori posto, quindi è un errore, come E15. Casi di confine:
- `ASSUME` con intestazione della riga non valida (`ASSUME : …`), o con una proprietà scritta come formula: E18,
  perché basta la parola chiave in testa;
- `assume` in minuscolo non è la parola chiave (2.2): resta non riconosciuta, senza E18;
- dentro un blocco ritirato niente E18: lì ogni dichiarazione è non riconosciuta (4.8);
- in un'entità con intestazione non valida (E09) E18 vale lo stesso: il blocco si apre comunque;
- un `DETAILS` che nomina il nome breve di un'`ASSUME` con E18 dà E02: l'`ASSUME` non registra il suo nome breve;
- `SCENARIO` e i passi non sono in E18: un'entità ha storie.

Ciò che un'entità richiederebbe agli altri va in un presupposto (`ASSUME`) della CSC che usa; una sua promessa va
in una `GUARANTEE` d'entità o della CSC che offre.

**Le parti di un'entità.** In un'entità **ogni dichiarazione che rispetta G34 è una parte, dovunque stia**: prima o
dopo `COMPOSED OF`, fra le promesse, dopo `OFFERS` e `USES`, dopo righe non riconosciute, dopo una seconda
`COMPOSED OF`, e anche in un'entità che non ha `COMPOSED OF`. Non c'è un elenco che si apre e si chiude: le parti
stanno dove si vuole, come `OFFERS` e `USES`.

- **`COMPOSED OF`** (G28), l'elenco delle parti, si scrive una volta sola: dice a chi legge che l'entità è fatta di
  parti. A `bcdd` non serve: una parte senza `COMPOSED OF` è controllata come le altre. Perché: nessuna parte scritta
  bene deve restare senza controllo, e se `COMPOSED OF` fosse necessaria, dimenticarla toglierebbe il controllo a
  tutte le parti dell'entità. L'altra via, un errore per una parte senza `COMPOSED OF`, darebbe un errore su una
  riga che `bcdd` legge per intero e controlla comunque.
- **Una seconda `COMPOSED OF`** non è riconosciuta, e non ha nessun effetto sulle parti. Non è un errore: non dice
  niente di sbagliato, ripete soltanto.
- **Una dichiarazione che non rispetta G34** non è una parte: se non è un'altra dichiarazione dell'entità
  (tabella sopra), non è riconosciuta. Non registra nessun nome, non si cerca, non compare sotto l'entità né nella
  sezione 7, non conta fra le parti non trovate (quindi non sospende E14) e non cambia il modo in cui si legge
  nessun'altra dichiarazione. Sono di questo tipo, per esempio: `pulsante-uno : Pulsante`, `p : X VERSION v1`,
  `pulsante Pulsante`, `pulsante uno : X`, `pulsante := X`, `"pulsante" : X`, `FOO bar`, `offers Luce`, `OFFERS :
  Pulsante`, `VERSION 0.1`, `LINK a b`, `END X`, e `VERIFY` o `VERBAL` dopo una parte (U4: continuano solo una
  `GUARANTEE` o un'`ASSUME`).

**Perché non resta nessun caso** in cui una dichiarazione G34 dentro un'entità non diventa una parte controllata,
o una riga non riconosciuta toglie il controllo a una parte. Una dichiarazione è una parte se e solo se (1) è una
dichiarazione (sezione 3), (2) sta in un blocco `ENTITY` (sezione 5), (3) rispetta G34 e (4) il suo nome non ha E01.
Nessuna di queste quattro cose dipende dal fatto che un'altra dichiarazione sia riconosciuta o no, tranne nei casi
qui sotto, ciascuno con un segnale fuori dalla sezione 5 o escluso dalle entità per costruzione:

| Caso | Che cosa succede | Segnale |
|---|---|---|
| il testo `p : X` sta **dentro una stringa** che va a capo | non è una dichiarazione (L2, U3): è testo | nessuno, per principio: una stringa può contenere qualunque testo. Con una sola virgoletta sbagliata nel file le virgolette fuori dai commenti sono in numero dispari, e c'è sempre E06; un tratto di righe diventa stringa senza errori solo con **due** virgolette sbagliate. Limite dichiarato |
| il nome della parte è ripetuto, o è il nome breve di una promessa (anche di una promessa non riconosciuta con intestazione della riga G16 valida, sezione 4.5) | la parte non si cerca | **E01**, codice 1 |
| un `END` da solo prima della parte | l'entità è finita: la riga è fuori da un blocco | se dopo viene l'`END` dell'entità, **E08** |
| un `CSC`, un `REFINEMENT` o un `ENTITY` prima della parte | chiude l'entità e apre un altro blocco | **E07** (ed **E09** se l'intestazione è scritta male; con `REFINEMENT`, **E15**) |
| una parte non trovata | sospende E14 per la sua entità | è nella **sezione 7**, con il motivo se c'è |
| `p : X` in una CSC o in un blocco ritirato | non è un'entità: non è riconosciuta (una CSC non ha parti; un blocco ritirato non ha parti, sezione 4.8) | fuori dalle entità, per costruzione |

Il caso che resta: un'entità in cui nessuna riga è una parte non ha voci nella sezione 8 né E14, e senza
`--strict` una riga non riconosciuta non cambia il codice.

Altre regole sui blocchi:
- `END` deve stare da solo sulla riga (un commento dopo va bene). `END` seguito da altro non è
  riconosciuto e il blocco resta aperto.
- Un `CSC`, un `REFINEMENT`, un `ENTITY`, un `BINDING`, una `VERIFICATION` o un `PROFILE` dentro un blocco aperto
  (anche dentro un'estensione, che si chiude con il suo profilo) chiude quel blocco con l'errore E07 e apre il nuovo.
- Un'intestazione di blocco scritta male (errore E09) apre comunque il blocco, così le righe che seguono
  si leggono normalmente invece di diventare tutte estranee. Vale per `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`
  ed `EXTENSION` come per `CSC`. Una dichiarazione che
  comincia con `REFINEMENT` (E15) apre il blocco ritirato, ben scritta o no (sezione 4.8).
- Un file può contenere più blocchi. I nomi dei blocchi `CSC`, `ENTITY` e `PROFILE` di un file non si ripetono,
  qualunque sia il tipo: una CSC e un'entità con lo stesso nome nello stesso file sono E01. Un blocco ritirato, un
  `BINDING` e una `VERIFICATION` non registrano il loro nome (il loro nome è quello della CSC legata).
- **Nomi in un'entità.** I nomi delle parti e i nomi brevi delle promesse e delle storie stanno in un solo elenco:
  un nome ripetuto è E01. I nomi delle righe `OFFERS` stanno in un elenco proprio, e così quelli delle righe `USES`.
  **Più versioni**: due righe `OFFERS` con lo stesso nome sono E01 sulla seconda **salvo** che tutte e due scrivano
  `VERSION` e le versioni siano diverse come testo; lo stesso per `USES`. Quindi `OFFERS Pulsanti VERSION 0.1` e
  `OFFERS Pulsanti VERSION 0.2` sono ammesse; `OFFERS Pulsanti VERSION 0.1` due volte è E01; `OFFERS Pulsanti` e
  `OFFERS Pulsanti VERSION 0.2` sono E01 sulla seconda (la riga senza versione vale per ogni versione, quindi la
  ripete), in qualunque ordine. L'entità offre ciascuna versione per intero; come le versioni convivano non lo dice
  nessuna riga. `OFFERS X` e `USES X` nella stessa entità sono ammessi (per esempio un apparecchio su un bus).
  **Con i pezzi `VARIANT`** (sezione 4.10): due parti con lo stesso nome, e due `OFFERS` (o due `USES`) con lo
  stesso nome, si confrontano con le regole qui sopra solo se **possono stare insieme**, cioè se non stanno in due
  scelte diverse dello stesso gruppo: `microfono` in `sensore = di` e in `sensore = microfono` va bene, `OFFERS X`
  fra le righe comuni e di nuovo in un pezzo è E01. I nomi brevi di promesse e storie, e una parte con lo stesso
  nome di un nome breve, sono E01 in qualunque pezzo. Il messaggio nomina la prima riga del file con quel nome che
  può stare insieme alla riga dell'errore.
- **Una riga con E01 in un'entità** (una `OFFERS`, una `USES` o una parte) non offre e non chiede niente:
  non si cerca, non compare sotto l'entità, nella sezione 7 né nella 8, e non conta nel combaciare (sezione
  9.4), né nel file controllato né nel blocco trovato di una parte. Vale sempre la prima riga con quel nome.
- La regola U4 vale anche nell'entità: `VERIFY` e `VERBAL` continuano una `GUARANTEE` o una `ASSUME` (e
  l'`ASSUME` resta non riconosciuta con le sue continuazioni).
- Una `GUARANTEE` d'entità con intestazione della riga G16 valida e proprietà non `VERBAL` registra il suo nome
  breve ed è di grado `non riconosciuta`, come nella CSC; E13 vale anche nell'entità.
- I nomi dichiarati in un blocco valgono solo in quel blocco. In un blocco CSC richieste, eventi, stati,
  costanti, tipi, promesse, presupposti, storie e i valori degli elenchi di valori condividono **un solo elenco di
  nomi**: due elementi diversi con lo stesso nome sono l'errore E01. I nomi dei parametri valgono solo nella loro
  riga.
- Una dichiarazione può nominare un elemento dichiarato più avanti nel blocco.

---

## 6. Il grado di una promessa

**Regola.** Il grado di una `GUARANTEE` o di un'`ASSUME` si legge dalla sua forma; nessuna riga porta un'etichetta di
grado:

| Grado | Quando |
|---|---|
| `verbale` | la proprietà è `VERBAL "…"` con la sua verifica (G17), o `VERBAL "…"` senza verifica con l'errore E13 |
| `formale` | la proprietà è una formula riconosciuta (G55) che non usa estensioni, o usa solo estensioni con `REDUCES TO` |
| `estensione dichiarata` | la proprietà è una formula riconosciuta che usa almeno un'estensione senza `REDUCES TO` |
| `non riconosciuta` | la proprietà non è riconosciuta: una formula in una forma che la sezione 4.12 non prevede, oppure una riga con un nome che solo un profilo non trovato potrebbe dare (sezione 4.14). Il nome breve esiste, se l'intestazione della riga è valida |

Una formula con un errore (E24-E30, E37) resta riconosciuta e ha il suo grado: la forma è letta, un nome o un tipo è
sbagliato, ed è l'errore a dirlo.

**Che cosa vuol dire «formale».** Il grado dice come la promessa si potrà verificare, non che sia stata verificata.
`check` legge la formula e ne controlla forma, nomi e tipi; non la valuta sulle storie, non controlla che le promesse
siano coerenti fra loro né con i dettagli. Questi controlli sono dichiarati «non eseguiti» nel rapporto (sezione
9.7). Nessun esito vale più di ciò che si è controllato davvero.

**Perché il nome breve resta anche in una riga non riconosciuta.** Se il nome breve sparisse, un dettaglio di quella
riga (`GUARANTEE g5 DETAILS g1`) darebbe l'errore «DETAILS verso una riga che non esiste», che è falso; e due righe
con lo stesso nome breve passerebbero senza l'errore E01.

**Una formula su più righe** si scrive lasciando la riga aperta (U5): `WHENEVER pressione THEN` a fine riga, e
`accesa WITHIN 1 s` sulla riga dopo, sono una dichiarazione sola. Una riga che comincia con `THEN` non continua la
precedente: apre una dichiarazione nuova (U2), e la formula risulta non riconosciuta.

## 7. Righe approvate e righe da approvare

La sezione 7.1 definisce lo stato di ogni riga contrattuale. Le sezioni 7.2-7.4 dicono come cambia una CSC nel
tempo: una versione nuova, i livelli dei dettagli, una riga sostituita.

### 7.1 Lo stato effettivo di una riga

Ogni riga contrattuale (una `GUARANTEE` o `ASSUME` con intestazione della riga riconosciuta) ha uno **stato
effettivo**: approvata o da approvare. Si decide così, nell'ordine:

0. se la riga sta in un blocco, **CSC o entità**, la cui intestazione non è valida (non rispetta G1 o G31: errore
   E09), è **da approvare**, qualunque `STATUS` abbiano la riga e l'intestazione;
1. se la riga ha un suo `STATUS RATIFIED BY D-nnn` valido, è **approvata**;
2. se la riga ha un suo `STATUS HYPOTHESIS`, o un `STATUS RATIFIED` senza decisione valida (errore E04),
   è **da approvare**;
3. se la riga non ha `STATUS` ed è un dettaglio (`DETAILS`), è **da approvare**: un dettaglio non eredita
   l'approvazione della CSC;
4. altrimenti vale lo `STATUS` dell'intestazione della CSC: approvata se è `RATIFIED BY D-nnn` valido; **da
   approvare** in ogni altro caso, anche senza `STATUS`. (Dopo il punto 0 l'intestazione qui è sempre valida.)

Il punto 3 serve perché un dettaglio aggiunto dopo l'approvazione di una CSC non diventi approvato in silenzio.

**Un profilo da approvare.** Prima del punto 1 vale il punto **0a**: una riga contrattuale che usa un'estensione di
un profilo trovato e **da approvare** (il suo `STATUS` non è `RATIFIED BY D-nnn` valido) è da approvare, qualunque
`STATUS` abbiano la riga e l'intestazione. Il significato dell'estensione non è stato approvato, quindi non lo è
nemmeno la riga che lo usa. Approvato il profilo, la riga torna allo stato dei punti 1-4. Nel JSON lo `stato_di` di
questa riga vale `profilo`: lo stato non viene dalla riga, dal dettaglio né dall'intestazione.

**Le altre righe con uno stato.** Le stesse regole valgono per:
- i dettagli di `DEFINE` e di `SCENARIO` (G12, G19 con `DETAILS`): sono sempre dettagli, quindi senza un loro
  `STATUS` sono da approvare (punto 3). Una `DEFINE` o una storia senza `DETAILS` non ha uno stato proprio e non
  compare nella sezione 4 del rapporto;
- un `BINDING`: la sua intestazione ha lo stato del suo `STATUS` (punto 4), e ogni riga `BIND` segue i punti 0, 1, 2
  e 4 (una riga `BIND` non ha `DETAILS`). Un `BINDING` con l'intestazione non valida (E09) ha tutte le righe da
  approvare (punto 0);
- un `PROFILE`: ha lo stato del suo `STATUS`; le sue estensioni non hanno uno stato proprio e lo seguono. Le
  estensioni di un profilo da approvare sono elencate nella sezione 4 del rapporto;
- una `VERIFICATION` non ha stato: non è mai approvata né da approvare, e non compare nella sezione 4.

Le righe da approvare stanno nella sezione 4 del rapporto («IPOTESI, NON CONTRATTO»). `check` non approva mai:
legge soltanto.

**L'intestazione non valida (punto 0).** Un'intestazione che non rispetta G1 o G31 (errore E09, per esempio `CSC
Rotta VERSIONE 0.1`, `CSC Rotta 0.1` o `ENTITY Rotta VERSIONE 0.1`) non dice quale CSC o entità né quale versione:
nessuna riga del blocco è approvata, né quelle che seguono l'intestazione né quelle con un loro `STATUS RATIFIED BY
D-nnn`. Il blocco si apre lo stesso (sezione 5) e gli `STATUS` restano riconosciuti e scritti come sono: corretta
l'intestazione, ogni riga torna allo stato che le danno i punti 1-4. La regola guarda il blocco della riga, non il
file. I casi di confine:

| Caso | Stato effettivo | Perché |
|---|---|---|
| CSC con E09, poi `STATUS RATIFIED BY D-1`: riga senza `STATUS` e senza `DETAILS` | **da approvare**: nella sezione 4 del rapporto, `stato` `ipotesi` e `decisione` `null` nel JSON | punto 0 |
| la stessa CSC, riga con un suo `STATUS RATIFIED BY D-2` | **da approvare**, nella sezione 4; `decisione` `null` | punto 0 |
| la stessa CSC, riga con `STATUS HYPOTHESIS`, o un dettaglio senza `STATUS` | da approvare | punto 0 (lo sarebbero anche per i punti 2 e 3) |
| CSC con E09, poi `STATUS RATIFIED` senza `BY` (E04) | **tutte da approvare**; restano E09 ed E04 | punto 0 |
| CSC con E09, senza `STATUS` o con `STATUS HYPOTHESIS` | tutte da approvare | punto 0 |
| entità con E09 (`ENTITY Rotta VERSIONE 0.1`), anche con `STATUS RATIFIED BY D-1` | **tutte da approvare**, anche la promessa con un suo `STATUS RATIFIED BY` | punto 0; le righe senza `STATUS` lo sarebbero comunque (in un'entità il punto 4 dà sempre «da approvare») |
| due blocchi: il primo con E09 e `STATUS RATIFIED BY D-1`, il secondo valido con `STATUS RATIFIED BY D-5` | tutte da approvare nel primo; nel secondo valgono i punti 1-4 | la regola guarda l'intestazione del blocco della riga |
| intestazione valida con il nome già usato da un altro blocco (E01), poi `STATUS RATIFIED BY` | approvata | E01 non è un'intestazione non valida: G1 è rispettata. Il punto 0 vale solo per E09 |
| `--strict` | il codice resta 1 (E09 è un errore) e la sezione 4 è quella senza `--strict` | lo stato effettivo non dipende da `--strict` (sezione 9.2, «Resto del rapporto con `--strict`»; sezione 10, «Che cosa prevale») |

Il punto 0 **non** cambia: la riga del blocco nel rapporto (`riga N: CSC (intestazione non valida), STATUS RATIFIED
BY D-1`) e, nel JSON, lo `stato` e la `decisione` del blocco, che riportano lo `STATUS` scritto nell'intestazione e
non lo stato effettivo delle righe; il numero degli errori, la riga `esito` e il codice d'uscita; le sezioni 2, 3,
5, 6, 7 e 8; i livelli di `DETAILS` (7.3). Nel JSON il campo `stato_di` di ogni riga di un blocco con E09 vale
`intestazione_non_valida`, qualunque cosa sia scritta nella riga. `ratify` e `refine` non lavorano su un file con
errori, quindi non vedono mai una riga di questo tipo.

**Il caso che resta** (limite dichiarato, come quello della 7.2). Se chi scrive corregge a mano un'intestazione non
valida, le righe che erano approvate prima che l'intestazione si guastasse tornano approvate senza `ratify`, con i
loro `STATUS RATIFIED BY` e quello dell'intestazione: «corretta l'intestazione, la riga torna approvata». `check`
legge un file alla volta e non sa che cosa c'era prima; il caso si copre confrontando il file con la versione
precedente.

**Le promesse di un'entità.** I punti 0, 1, 2 e 3 valgono come nella CSC. Il punto 4 in un'entità dà **sempre «da
approvare»**: l'intestazione di un'entità non è mai approvata (`STATUS RATIFIED` vi è non riconosciuto, sezione 5).
Quindi una promessa d'entità è approvata se e solo se ha un suo `STATUS RATIFIED BY D-nnn` valido, e lo diventa con
`bcdd ratify` (sezione 12), solo se i confini dell'entità sono stati letti. Esempio: in un'entità `Ratificata` con
`STATUS RATIFIED BY D-1` come prima dichiarazione lo stato del blocco è `senza STATUS` e la riga `STATUS` è nella
sezione 5; `r1` (senza `STATUS`) è da approvare; `r2` (`STATUS RATIFIED BY D-2`) è approvata; `r3` (`STATUS RATIFIED`
senza decisione) dà E04 ed è da approvare.

Come nella CSC, `check` non sa chi ha scritto uno `STATUS RATIFIED BY`: scritto a mano, rende approvata una promessa
d'entità anche se un suo confine non si trova (la ricerca non cambia l'esito). La regola è che `STATUS RATIFIED BY`
non si scrive a mano (sezione 7.2); `ratify` la fa rispettare controllando i confini (sezione 12.2, passo 7).
Limite dichiarato.

**Un esempio lineare** (il file è valido: `check --strict` dà codice 0):

```
CSC LuceScale VERSION 0.1
  STATUS RATIFIED BY D-135
  ...
  GUARANTEE g1: VERBAL "Una pressione accende la luce"
  GUARANTEE g1a DETAILS g1: VERBAL "Entro 1 secondo da una pressione la luce è accesa"
  GUARANTEE g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne da sola dopo DURATA_LUCE"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-200: VERBAL "Una pressione a luce accesa fa ripartire il tempo"
```

(le righe `VERIFY` sono omesse qui per brevità; nel file ci sono; `D-135` e `D-200` sono riferimenti d'esempio).

| Riga | Che cosa ha | Punto | Stato effettivo |
|---|---|---|---|
| `g1` | niente `STATUS`, niente `DETAILS` | 4: eredita dall'intestazione, che è `RATIFIED BY D-135` | approvata |
| `g1a` | niente `STATUS`, ma `DETAILS g1` | 3: un dettaglio non eredita | da approvare |
| `g2` | il suo `STATUS HYPOTHESIS` | 2 | da approvare, anche se l'intestazione è approvata |
| `g2a` | il suo `STATUS RATIFIED BY D-200` | 1 | approvata, anche se dettaglia una riga da approvare |

Con l'intestazione `STATUS HYPOTHESIS`, o senza `STATUS`, anche `g1` sarebbe da approvare (punto 4); `g2a`
resterebbe approvata (punto 1).

**Chi usa lo stato effettivo** (la regola è la stessa per tutti):

| Comando | Che cosa ne fa | Dove |
|---|---|---|
| `bcdd check` | elenca le righe da approvare nella sezione 4 del rapporto | sezione 9 |
| `bcdd ratify FILE ID D-nnn` | rifiuta una riga già approvata, anche se lo è perché eredita (punto 4); in un'entità, una promessa con il suo `STATUS RATIFIED BY`. Un file con l'intestazione non valida ha E09 e `ratify` lo rifiuta prima di guardare la riga (sezione 12.2): il punto 0 non cambia `ratify` | sezione 12 |
| `bcdd ratify FILE --all D-nnn` | cambia solo l'intestazione, se è da approvare, e le righe che restano da approvare **dopo** (punti 2 e 3): le righe del punto 4 seguono l'intestazione e non si toccano | sezione 12 |
| `bcdd refine` | può sostituire solo una riga da approvare; una riga approvata non si sostituisce mai | sezione 7.4 |

### 7.2 Una versione nuova di una CSC approvata

1. Una CSC approvata **non si modifica**. Chi vuole cambiarla scrive una **VERSION nuova** nello stesso
   file, al posto della vecchia (lo stesso nome due volte nello stesso file è E01), con `STATUS HYPOTHESIS`
   nell'intestazione e un commento in testa che dice che cosa cambia e per quali decisioni.
2. Nella versione nuova:
   - una riga che **non cambia testo** tiene il suo `STATUS RATIFIED BY D-mmm`, se l'aveva: resta approvata, con la
     decisione di prima;
   - una riga che **cambia testo** torna da approvare: se aveva un suo `STATUS RATIFIED BY D-mmm`, chi scrive lo
     cambia in `STATUS HYPOTHESIS`. Una riga senza `STATUS` e senza `DETAILS` lo è già, perché segue l'intestazione
     (sezione 7.1, punto 4), e non serve scriverlo: così resta come le altre righe che seguono l'intestazione,
     anche quando l'intestazione viene approvata;
   - una riga nuova è da approvare: con `STATUS HYPOTHESIS`, o senza `STATUS` (sezione 7.1, punti 3 e 4).

   Finché la versione nuova non è approvata, il contratto in vigore resta la versione approvata prima; della
   versione nuova sono approvate solo le righe che non sono cambiate e hanno un loro `STATUS RATIFIED BY`.
3. La versione nuova diventa approvata **solo** con `bcdd ratify FILE D-nnn` o `bcdd ratify FILE --all D-nnn`, con
   il riferimento della decisione di approvazione. `STATUS RATIFIED BY` non si scrive a mano.

Esempio: la luce delle scale approvata è `VERSION 0.1`. Per aggiungere il lampeggio si scrive:

```
-- VERSION 0.2 (D-nnn): lampeggio prima dello spegnimento. Da approvare.
CSC LuceScale VERSION 0.2
  STATUS HYPOTHESIS
  ...
```

Che cosa vede `check`: l'intestazione `STATUS HYPOTHESIS`, e nella sezione 4 del rapporto le righe senza `STATUS`
(punto 4 della 7.1), i dettagli senza `STATUS` e le righe con `STATUS HYPOTHESIS`. **Una riga con un suo `STATUS
RATIFIED BY` resta approvata** anche nella versione nuova (punto 1 della 7.1): è il punto 2 qui sopra. Esempio: una
luce delle scale approvata con `--all`, con quattro righe base `g1`, `g2`, `g3`, `a1` senza `STATUS` e sei dettagli
(`g1a`…`g1c`, `g3a`…`g3c`) con un loro `STATUS RATIFIED BY`, portata a `VERSION 0.2, STATUS HYPOTHESIS` senza
cambiare altro: nella sezione 4 del rapporto ci sono le quattro righe base, che seguono l'intestazione; i sei
dettagli restano approvati.

**Il rischio che resta.** Se chi scrive cambia il testo di una riga e dimentica di passarla a `STATUS
HYPOTHESIS`, la riga resta approvata con un testo che chi approva non ha visto, e `check` non se ne accorge (sezione
14). Lo copre il confronto con la versione precedente prima dell'approvazione, non `bcdd`. `bcdd refine` non crea
questo caso: non sostituisce mai una riga approvata (sezione 7.4).

**Un commento non è contratto.** La regola «una CSC approvata non si modifica» vale per ciò che si approva:
intestazione, dichiarazioni, righe contrattuali. Un commento (`-- …`) si può correggere senza una VERSION nuova, se
nessuna riga riconosciuta cambia.

`check` legge un file alla volta e non conosce la versione precedente: non sa dire se una VERSION è nuova, né che
cosa è cambiato. Il confronto fra due versioni si fa con gli strumenti di gestione delle versioni dei file, non con
`bcdd`.

### 7.3 I livelli di `DETAILS`

- Una **riga base** è una `GUARANTEE` o una `ASSUME` senza `DETAILS`: il suo **livello** è 0.
- Per `X DETAILS Y` il livello di `X` è quello di `Y` più 1.

Esempio, sotto `g2` della luce delle scale (il file è valido):

```
GUARANTEE g2: …                      -- livello 0, riga base
GUARANTEE g2a DETAILS g2: …          -- livello 1
GUARANTEE g2a1 DETAILS g2a: …        -- livello 2
GUARANTEE g2a1a DETAILS g2a1: …      -- livello 3
```

| Chi | Che cosa fa con i livelli |
|---|---|
| `bcdd check` | **niente**: accetta `DETAILS` a qualunque profondità, senza errori né avvisi, e il rapporto non mostra i livelli. Un file con righe al livello 3 o 4 passa `check --strict` con codice 0 |
| `bcdd refine` | **propone al più due livelli**: una proposta che dettaglia una riga già al livello 2 o più in basso è scartata; quindi una riga aggiunta da `refine` arriva al più al livello 2. Le sostituzioni (sezione 7.4) valgono a ogni livello. Le righe già più in basso restano: `refine` non le tocca e non le dettaglia |
| `bcdd ratify` | niente: approva una riga a qualunque livello |

Il livello si conta solo in un file senza E02 né E05, dove ogni catena di `DETAILS` finisce in una riga
base. È il caso di `refine`, che lavora solo su file senza errori.

### 7.4 La riga sostituita

`bcdd refine` può proporre di **sostituire** una riga da approvare (sezione 7.1) scritta a parole; la persona vede
la riga attuale e quella nuova, e accetta o scarta.

Che cosa resta e che cosa cambia, quando la persona accetta:
- **resta**, byte per byte, la prima riga della dichiarazione **dal suo primo carattere fino al primo
  `:` compreso**: il rientro, il tipo (`GUARANTEE` o `ASSUME`), il nome breve, il `DETAILS` e lo `STATUS`, con gli
  spazi che c'erano. Il primo `:` è sempre quello dell'intestazione della riga, perché un nome breve, un nome e una
  decisione non contengono `:` (regole L7-L9), e l'intestazione della riga sta sempre su una riga (regola U2);
- **cambiano** il testo dopo `VERBAL` e la verifica; la riga `VERIFY` si allinea sotto `VERBAL`;
- **restano** dove sono, identiche, tutte le altre righe del file, compresi i dettagli della riga
  sostituita.

Esempio, `g2` della luce delle scale, riga base sotto un'intestazione `STATUS HYPOTHESIS`:

```
prima:
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
dopo:
  GUARANTEE g2: VERBAL "La luce si spegne da sola fra 59 e 61 secondi dopo l'ultima pressione"
                VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
```

Resta `  GUARANTEE g2:`. Poiché lo `STATUS` non cambia, la riga resta da approvare: `g2` continua a ereditare
dall'intestazione, e se poi l'intestazione viene approvata la segue come le altre righe. Un dettaglio `g2a DETAILS
g2` resta valido, perché il nome breve `g2` non cambia; `refine` lo elenca «da rileggere». Per `check` la riga
sostituita è una riga come le altre: non sa che è stata sostituita.

---

## 8. Gli errori

Un errore è un elemento scritto che il controllo sa leggere e che è sbagliato. Gli errori sono quaranta.

| Codice | Quando | Riga indicata | Testo esatto del messaggio |
|---|---|---|---|
| E01 | due elementi con lo stesso nome o nome breve nello stesso blocco; due parametri o due argomenti con lo stesso nome nella stessa riga; due blocchi con lo stesso nome nello stesso file, qualunque sia il tipo. Nell'entità: due parti, una parte e una promessa, o una storia e una parte o una promessa, con lo stesso nome; due `OFFERS` con lo stesso nome, salvo che tutte e due scrivano `VERSION` con versioni diverse (sezione 5); lo stesso per due `USES`. In una CSC anche un valore di un elenco di valori uguale a un altro nome del blocco | la seconda | `nome già usato alla riga N: X` |
| E02 | `DETAILS X` dove X non è una `GUARANTEE` né una `ASSUME` dello stesso blocco; in una `DEFINE`, X non è una `DEFINE` dello stesso blocco; in una storia, X non è una storia dello stesso blocco | quella del `DETAILS` | `DETAILS nomina un id che non è una GUARANTEE né una ASSUME di questa CSC: X`; in un'entità `DETAILS nomina un id che non è una GUARANTEE di questa ENTITY: X`; `DETAILS nomina un nome che non è una DEFINE di questa CSC: X`; `DETAILS nomina un id che non è uno SCENARIO di questo blocco: X`. Anche: in un'entità con pezzi `VARIANT`, la riga nominata sta in una scelta che non vale in tutte le composizioni del dettaglio (sezione 4.10): `DETAILS nomina una GUARANTEE che non vale in tutte le composizioni di questa riga: X (sta in VARIANT D = S)` |
| E03 | un passo o un `GIVEN` nomina come evento ciò che non è un `EVENT`, come richiesta ciò che non è una `CAPABILITY`, come stato ciò che non è uno `STATE`, o un argomento che l'evento non ha fra i parametri. Anche: in una storia d'entità, un nome qualificato `X.y` con `X` dell'entità e trovata, ma `y` assente o del tipo sbagliato, o un argomento che `X.y` non ha; un nome semplice in una storia d'entità; in un blocco CSC, un nome usato come valore (G26) che non è un valore di un elenco di valori del blocco | quella del nome (per un nome qualificato, quella di `X`) | `nome non dichiarato come EVENT: X` (e così `CAPABILITY`, `STATE`), oppure `nome non dichiarato come parametro di E: X`; con un nome qualificato `nome non dichiarato come EVENT: X.y`, `nome non dichiarato come parametro di X.y: a`; per un valore `nome non dichiarato come valore di TYPE: X` |
| E04 | `STATUS RATIFIED` non seguito esattamente da `BY` e da una Decisione | quella di `RATIFIED` | `STATUS RATIFIED senza decisione: serve BY D-numero` |
| E05 | i `DETAILS` formano un giro (anche una riga che dettaglia se stessa), fra righe contrattuali, fra `DEFINE` o fra storie | quella del membro del giro che viene prima nel file | `DETAILS in giro: A -> B -> A`, cominciando da quel membro e seguendo i `DETAILS` |
| E06 | una stringa aperta non si chiude prima della fine del file | quella dove la stringa si apre | `stringa non chiusa: il file finisce dentro la stringa aperta qui` |
| E07 | un blocco senza `END` (finisce il file, o comincia un altro blocco), anche un `BINDING`, una `VERIFICATION`, un profilo o un'estensione (sezione 4.11) | l'intestazione del blocco | `blocco non chiuso: manca END di CSC X` oppure `… di REFINEMENT VIEW X` oppure `… di ENTITY X`; `… di BINDING X`, `… di VERIFICATION X`, `… di PROFILE X`, `… di EXTENSION X`, con `X` la seconda parola dell'intestazione se è un Nome; `?` se il nome non si legge. Un'estensione senza `END` dentro un profilo senza `END` dà un solo E07, sul profilo |
| E08 | `END` senza un blocco aperto (un'estensione è un blocco aperto dentro il suo profilo, e anche quella fuori posto di E32: il suo `END` non dà E08) | quella di `END` | `END senza un blocco aperto` |
| E09 | una riga che comincia con `CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE` o `EXTENSION` (dentro un profilo) e non rispetta G1, G31, G40, G48, G49 o G50 | quella | `intestazione non valida: attesa CSC Nome VERSION numero` oppure `… attesa ENTITY Nome VERSION numero`, `… attesa BINDING NomeCSC VERSION numero [AS nome]`, `… attesa VERIFICATION NomeCSC VERSION numero`, `… attesa PROFILE Nome VERSION numero`, `… attesa EXTENSION Nome`. Per `EXTENSION` con una parola chiave o riservata come nome vale invece E34 |
| E10 | una CSC, un'entità o un profilo senza `PURPOSE` riconosciuto; un secondo `PURPOSE`; un secondo `STATUS` riconosciuto nella zona d'intestazione (sezioni 4.2, 4.9 e 4.11, anche in un `BINDING`) | l'intestazione del blocco; il secondo `PURPOSE`; il secondo `STATUS`, colonna di `STATUS` | `PURPOSE mancante nella CSC X` oppure `PURPOSE mancante nella ENTITY X`, `PURPOSE mancante nel PROFILE X`; `PURPOSE ripetuto: il primo è alla riga N`; `STATUS ripetuto: il primo è alla riga N` |
| E11 | il file non contiene nessuna CSC, nessuna entità, nessun `BINDING`, nessuna `VERIFICATION` e nessun `PROFILE` (un blocco con intestazione non valida conta; un blocco ritirato e un'estensione fuori da un profilo no) | nessuna | `il file non contiene nessuna CSC` |
| E12 | in una storia un passo ha un tempo minore del più grande dei passi precedenti; oppure la storia mescola passi con unità e passi senza | quella del passo | `il tempo del passo diminuisce: @T dopo @M`; `passi con e senza unità di tempo nello stesso SCENARIO` |
| E13 | una `GUARANTEE` o `ASSUME` con intestazione della riga valida la cui proprietà è soltanto `VERBAL` e una stringa, senza `VERIFY` (sezione 4.5) | quella della parola `VERBAL` | `VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa` |
| E15 | una dichiarazione che comincia con `REFINEMENT`, in un posto dove comincia un blocco (sezione 4.8) | quella di `REFINEMENT`; colonna di `REFINEMENT` | `REFINEMENT VIEW è uscita dal linguaggio: una scomposizione si scrive con ENTITY` |
| E14 | dentro un'entità E con **tutte** le parti trovate, una parte P usa una CSC X che nessun'altra parte di E offre e che E non usa da fuori, con il combaciare della sezione 9.4 | quella della parte P nel file controllato; colonna del nome P | `la parte P usa il connettore X: nessun'altra parte di E lo offre, né E lo usa da fuori`, con `X` scritto come nella riga `USES` di P, seguito da ` VERSION w` se c'è; `E` è il nome dell'entità, `?` se non si legge |
| E16 | in un'entità E con almeno una parte (G34), con o senza `COMPOSED OF`, e **tutte** le parti trovate; con le composizioni (4.10), in ciascuna che ha almeno una parte presente: una CSC pubblica di E (`OFFERS X` o `USES X`) che nessuna parte espone dallo stesso lato, con il combaciare della sezione 9.4 | quella della riga `OFFERS` o `USES` di E; colonna del nome | `il connettore pubblico X di E (offre) non è affidato a nessuna parte` (oppure `(usato)` per `USES`), con `X` scritto come nella riga, seguito da ` VERSION w` se c'è |
| E17 | nella stessa condizione, una parte P offre X, nessun'altra parte di E la usa e E non la offre, con il combaciare della sezione 9.4 | quella della parte P; colonna del nome P | `la parte P offre il connettore X: nessun'altra parte di E lo usa, né E lo offre da fuori`, con `X` seguito da ` VERSION w` se la parte lo dice |
| E18 | dentro un blocco `ENTITY`, una dichiarazione che comincia con `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE` o `TYPE` (sezione 5) | quella della parola chiave; colonna della parola chiave | `K non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori`, con `K` la parola chiave |
| E19 | una parte con la forma G35 ma limiti sbagliati: un limite con un punto, oppure `m` > `n`, oppure `n` = 0 (sezione 4.9) | quella della parte; colonna di `[` | `la parte P ha un numero di copie non valido: [m .. n]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo`, con `P` il nome della parte e `m` e `n` scritti come nel file |
| E20 | un nome qualificato `X.y` in una storia o in una formula d'entità con `X` che non è fra le `OFFERS` e `USES` dell'entità; oppure un nome qualificato in una storia di una CSC o in una fase di una formula di una CSC (sezioni 4.6, 4.12) | quella di `X`; colonna di `X` | nell'entità `X.y: E non offre né usa il connettore X; uno scenario può citare solo i connettori di E`; nella CSC `X.y: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità`. In un'entità con più composizioni, `X` si controlla per composizione e il messaggio ha il suffisso `(in: …)` (sezioni 4.10 e 9.5) |
| E21 | una dichiarazione che comincia con `VARIANT` in un blocco `CSC`; in un'entità, una che comincia con `VARIANT` e non rispetta G38; una che comincia con `PURPOSE` dentro un pezzo (sezione 4.10) | quella della parola chiave; colonna della parola chiave | `VARIANT non può stare in una CSC: le varianti si scrivono in un'entità`; `VARIANT scritto male: serve VARIANT dimensione = scelta`; `PURPOSE non può stare in un pezzo VARIANT: scrivilo prima del primo VARIANT` |
| E22 | un gruppo di scelte con una sola scelta; la stessa scelta scritta due volte; un pezzo senza dichiarazioni riconosciute (sezione 4.10) | quella del `VARIANT` (per la scelta ripetuta, la seconda); colonna di `VARIANT` | `la dimensione D ha una sola scelta (S): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]`; `la scelta D = S è già scritta alla riga N`; `il pezzo VARIANT D = S è vuoto: una scelta senza righe si scrive con una parte [0 .. 1]` |
| E23 | un'entità con più di 64 composizioni (sezione 4.10) | quella dell'intestazione; colonna 0 | `l'entità E ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole`, con `E` il nome dell'entità (`?` se non si legge) |
| E24 | in una formula, in una `DEFINE`, in una riga `STATE … FOLLOWS` o in un uso di un'estensione: un nome che non è dichiarato, o che non è del genere che la posizione chiede (sezione 4.13); un campo che non c'è; una chiamata con argomenti sbagliati; in un'entità, un nome semplice dove serve un elemento di una CSC (sezione 4.9) | quella del nome; colonna del nome (di `X` per `X.y`) | `nome non dichiarato: X`; `X non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY`; `X non è una CAPABILITY`; `X non è uno STATE`; `X è una CAPABILITY: si nomina con una fase (requested(X), …) o in ACCEPTS, REQUIRES, ENSURES, RESOLVES`; `X non è un valore`; `nome non dichiarato come campo di T: c`; `X non è una DEFINE con parametri`; `nome non dichiarato come parametro di X: p`; `manca l'argomento p nella chiamata di X`; `in un'entità i nomi delle CSC si scrivono con il connettore davanti: x`; con un nome qualificato `nome non dichiarato come EVENT: X.y` (e così `STATE`, `CAPABILITY`) |
| E25 | un'espressione del tipo sbagliato per la sua posizione; un valore scritto in `INITIAL`, `GIVEN`, in un'assegnazione o in un argomento che non è del tipo dichiarato (sezione 4.13) | quella del primo elemento dell'espressione o del valore | `tipo incoerente: serve A, trovato B`; `valore non del tipo T: V` |
| E26 | `AND` e `OR` allo stesso livello senza parentesi; `IMPLIES`, un confronto o `^` concatenati senza parentesi (sezione 4.12) | quella del secondo operatore; colonna dell'operatore | `AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)`; `IMPLIES dopo IMPLIES senza parentesi: scrivi a IMPLIES (b IMPLIES c)`; `confronti in catena: scrivi a <= b AND b <= c`; `^ dopo ^ senza parentesi: scrivi (a ^ b) ^ c` |
| E27 | un pattern annidato; due ambiti; `WITHIN` e `AT ONCE` insieme; `REQUIRES` in una `GUARANTEE` (sezione 4.12) | quella della parola; colonna della parola | `K dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni`; `una proprietà ha un solo ambito: K è il secondo`; `WITHIN e AT ONCE nella stessa proprietà: scegline uno`; `REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)` |
| E28 | `DEFINE` che si nominano in giro; tipi con nome (G41) che si nominano in giro | quella del membro del giro che viene prima nel file; colonna del nome | `DEFINE in giro: A -> B -> A`; `TYPE in giro: A -> B -> A` |
| E29 | il tipo dell'indice di uno stato (G11) o di `FOR ALL` non è finito; un indice su un nome che non ne ha; uno stato con indice senza indice; un indice del tipo sbagliato (sezioni 4.3, 4.6, 4.12) | quella del nome o dell'indice | `il tipo dell'indice di X non è finito: T`; `X non ha indice`; `X ha un indice: scrivi X[valore di T]`; `indice di X non del tipo T: v` |
| E30 | una ripetizione scritta male (sezione 4.6) | quella della riga `REPEAT` o del passo; colonna di `REPEAT` o di `@` | `REPEAT ripetuto nella storia: il primo è alla riga N`; `ripetizioni non valide: m..n. Scrivi REPEAT minimo..massimo, con il massimo almeno 1 e non più piccolo del minimo`; `il passo @t non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY d`; `REPEAT senza passi: i passi ripetuti si scrivono dopo la riga REPEAT`; `REPEAT … EVERY vuole una storia con le unità di tempo` |
| E31 | in un `BINDING` o in una `VERIFICATION` la cui CSC legata è trovata con la versione scritta: una riga `BIND` o `MEANS` nomina un elemento che la CSC non ha; una storia tradotta nomina una storia che la CSC non ha (sezione 4.11) | quella dell'elemento o del nome breve; colonna dell'elemento | `X non è un elemento della CSC N VERSION v`; `TRANSLATES nomina una storia che la CSC N VERSION v non ha: id` |
| E32 | un'`EXTENSION` fuori da un `PROFILE` (sezione 4.11) | quella di `EXTENSION`; colonna della parola | `EXTENSION fuori da un PROFILE: un'estensione si dichiara in un profilo` |
| E33 | un campo di un'estensione che manca, è ripetuto o ha un valore non ammesso; `FORM` che non comincia con il nome; un parametro che non compare una volta in `FORM`; `KIND FUNCTION` senza tipo del risultato; `VERIFY V1` con un controllo che non esiste (sezione 4.11) | per un campo mancante quella di `EXTENSION`, colonna 0; altrimenti quella del campo, colonna del campo | i messaggi della tabella della sezione 4.11 |
| E34 | due estensioni con lo stesso nome nello stesso profilo; un'estensione il cui nome è una parola chiave o riservata | quella della seconda `EXTENSION`, o di quella con il nome riservato; colonna del nome | `nome di estensione già usato alla riga N: X`; `il nome dell'estensione è una parola del linguaggio: X` |
| E35 | `REDUCES TO` nomina ciò che non è del linguaggio, un parametro né un'estensione dello stesso profilo; estensioni che si nominano in giro con `REDUCES TO` | quella del nome; per il giro quella del membro che viene prima | `REDUCES TO nomina X: non è una parola del linguaggio, un parametro né un'estensione del PROFILE P`; `REDUCES TO in giro: A -> B -> A` |
| E36 | un'estensione la cui `REDUCES TO` ripete una forma del linguaggio o un'altra estensione (sezione 4.11) | quella di `REDUCES`; colonna di `REDUCES` | `l'EXTENSION X ripete una forma che il linguaggio ha già: F`; `l'EXTENSION X ripete l'EXTENSION Y` |
| E37 | un uso di un'estensione che non rispetta il suo `FORM`, il suo `KIND` o il suo `LEVEL` (sezione 4.14) | quella del nome dell'estensione; colonna del nome | `uso di X che non rispetta FORM "F"`; `X ha KIND K: non si usa in questa posizione`; `X ha LEVEL L: non si usa in un blocco B` |
| E38 | un `BINDING` o una `VERIFICATION` importa un profilo con una versione diversa da quella con cui lo importa la CSC legata, trovata | quella della riga `IMPORT PROFILE` del blocco legato; colonna di `IMPORT` | `PROFILE P importato con VERSION v, ma la CSC N lo importa con VERSION w` |
| E39 | uno `STATUS` in una `VERIFICATION` | quella di `STATUS`; colonna di `STATUS` | `STATUS non può stare in una VERIFICATION: un piano di prova non si approva` |
| E40 | due `BINDING` per la stessa CSC e la stessa versione senza nome, o con lo stesso nome, nel file controllato (sezione 4.11) | quella del secondo; colonna 0 | `secondo BINDING senza nome per la CSC N VERSION v: il primo è alla riga M. Con due o più BINDING ognuno ha un nome, AS nome`; `nome di BINDING già usato alla riga M: x` |

Nei messaggi, `id` è il nome breve, «connettore» una CSC citata da un'entità, «dimensione» un gruppo di scelte e
`SCENARIO` una storia.

Precisazioni:
- **Che cosa non è un errore**: una riga non riconosciuta; un tipo non dichiarato; una CSC senza promesse; un
  `PURPOSE` vuoto. Neanche, perché non sono elementi sbagliati scritti nel file controllato: una citazione non
  trovata, un file citato non leggibile o con errori, una versione diversa da quella attesa; e una parte che non si
  trova **sospende** E14 per la sua entità.
- **E16 ed E17** completano la chiusura di un'entità: E14 guarda le righe `USES` delle parti, E17 le loro `OFFERS`,
  E16 i confini pubblici. Come E14 sono errori (codice 1), impediscono `ratify`, e una parte non trovata li sospende
  per la sua entità.
- **E14** è un errore come gli altri (codice 1) e impedisce `ratify`. Una parte usa una CSC quando lo dice il
  **suo** blocco, trovato altrove: l'errore sta nel file controllato perché è lì che le parti sono messe insieme.
- **E03** riguarda solo i passi, i `GIVEN` e i valori riconosciuti. Gli argomenti si controllano solo se l'evento è
  dichiarato come `EVENT`. In una storia d'entità, se la CSC `X` non è trovata, `X.y` e i suoi argomenti non si
  controllano (sezione 4.6).
- **E18, E19, E20** sono errori come gli altri (codice 1) e impediscono `ratify`. Una dichiarazione con E18 è anche
  non riconosciuta e compare nella sezione 5; una parte con E19 resta una parte; una dichiarazione con E20 resta
  riconosciuta.
- **E21, E22, E23** sono errori come gli altri (codice 1) e impediscono `ratify`. Una dichiarazione con E21 è anche
  non riconosciuta; un pezzo con E22 resta un pezzo; E23 toglie la chiusura all'entità.
- **E14, E16, E17 con le composizioni**: in una composizione con una parte facoltativa assente, quelli che
  spariscono rimettendo la parte non sono errori ma assenze dichiarate (sezioni 4.10 e 9.5): non contano nella riga
  `esito` e non cambiano il codice. Con più composizioni hanno il suffisso `(in: …)`.
- **E06, E08, E09, E15, E18, E21, E32**: la riga è anche non riconosciuta, quindi compare pure nella sezione 5 del
  rapporto. Una dichiarazione con una stringa non chiusa non dichiara nulla. Con E32 sono non riconosciute anche le
  righe dell'estensione fuori posto, fino al suo `END`.
- **E24-E31 ed E33-E40** sono errori come gli altri (codice 1) e impediscono `ratify`. La dichiarazione che li porta
  resta riconosciuta: `bcdd` ne ha letto la forma per intero, e l'errore dice che cosa è sbagliato. Fa eccezione un
  campo di un'estensione la cui riga non è riconosciuta: E33 «manca il campo» sta sulla riga `EXTENSION`.
- **Errori certi.** Quando un controllo dipende da un file citato che non è trovato (una CSC legata, il blocco di
  `X` in un nome qualificato, un profilo), il controllo è sospeso e non dà errori; la citazione è nella sezione 7.
- **E12**: il passo senza unità conta come numero puro; `s` vale 1000 `ms`. Il primo passo della storia decide se
  la storia usa le unità. Nel messaggio i tempi si scrivono `@` + numero + (spazio + unità, se c'è): `@3 s dopo @5
  s`, `@4000 ms dopo @5 s`. Due passi con lo stesso tempo sono ammessi.
- **E12 con unità mescolate**: «con unità» vuol dire con `s` oppure con `ms`; `s` e `ms` nella stessa storia non
  sono una mescolanza. Ogni passo che non segue la scelta del primo passo dà **il suo** E12, sulla sua riga: chi
  corregge vede tutti i passi da sistemare, non solo il primo. Quel passo **esce dal confronto dei tempi**: non può
  dare anche «il tempo diminuisce» e non cambia il tempo più grande con cui si confrontano i passi successivi. Un
  numero puro e un tempo con unità non si possono confrontare senza inventare un'unità. Esempio: dopo `@0 s`, il
  passo `@5` dà E12 per le unità, e `@3 s` che segue **non** dà errore, perché il più grande resta `@0 s`.
- **E13**: in un presupposto scritto su più righe la riga indicata è quella dove sta `VERBAL`, che può essere
  diversa da quella di `ASSUME`. La riga va nella sezione 2 come `verbale` e, se è da approvare, nella 4; non va
  nella 5.
- **Una virgoletta dimenticata** di solito non dà E06: si accoppia con la virgoletta successiva, e il
  risultato sono righe non riconosciute. E06 compare solo quando nel resto del file le virgolette sono
  in numero dispari.

---

## 9. Il rapporto di `bcdd check`

Il rapporto è il contenuto esatto dello standard output, definito in questa sezione fino al carattere.

### 9.1 Struttura

```
bcdd check NOMEFILE      (con le opzioni: bcdd check --strict --dir ARG NOMEFILE, vedi 9.2)
righe: T (riconosciute R, commenti C, vuote V, non riconosciute U)
blocchi: B
  riga N: CSC Nome VERSION v, STATO
    riga N: IMPORT PROFILE P in PERCORSO alla riga M: VERSION v, STATO, ESITO   (profili trovati, 9.6)
  riga N: REFINEMENT VIEW Nome
  riga N: ENTITY Nome VERSION v, STATO
    riga N: OFFERS X in PERCORSO alla riga M: VERSION v, STATO, ESITO      (citazioni trovate, 9.4)
  riga N: BINDING Nome VERSION v AS nome, STATO
    riga N: CSC Nome in PERCORSO alla riga M: VERSION v, STATO, ESITO      (CSC legata, 9.6)
  riga N: VERIFICATION Nome VERSION v
  riga N: PROFILE Nome VERSION v, STATO

1. ERRORI: E
  riga N: [Exx] messaggio

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: a
  formale: f
  estensione dichiarata: x
  non riconosciuta: b
  riga N: GUARANTEE id grado

3. UNDECIDED: c
  riga N: NOME

4. IPOTESI, NON CONTRATTO: d
  riga N: GUARANTEE id
  riga N: BIND elemento
  riga N: EXTENSION Nome

5. RIGHE NON RICONOSCIUTE: e
  riga N: testo della riga
  riga N: testo della riga (profilo P VERSION v non trovato)

6. TIPI NON DICHIARATI: f
  Nome: riga N            (oppure: righe N, M, …)

7. CSC NOMINATE E NON CONTROLLATE: g
  riga N: Nome
  riga N: Nome (MOTIVO)
  riga N: PROFILE Nome (MOTIVO)

8. USI DENTRO LE ENTITÀ: n          (solo se il file ha almeno un blocco ENTITY, 9.4)
  riga N: P usa X: la offre Q (riga M)

9. COMPOSIZIONI: c                  (solo se un'entità ha più di una composizione o E23, 9.5)
  riga N: ENTITY Nome: k
    nome di una composizione

10. ASSENZE DICHIARATE: a           (con la sezione 9, 9.5)
  riga N: senza P: messaggio

12. FORME CONCRETE MANCANTI: k     (solo se il file ha almeno un BINDING, 9.6)
  riga N: BINDING Luce VERSION 0.1: STATE modo, EVENT IN pressione

13. COPERTURA DEL PIANO DI PROVA: k (solo se il file ha almeno una VERIFICATION, 9.6)
  riga N: VERIFICATION Luce VERSION 0.1
    telecamera (riga M): g1, g3
    non eseguite: g2

14. DA GIUDICARE: k                 (solo se c'è almeno una voce, 9.7)
  riga N: GUARANTEE g1a DETAILS g1: coerenza fra la riga e la riga che dettaglia, una delle due a parole

15. CONTROLLI NON ESEGUITI: k       (solo se c'è almeno una voce, 9.7)
  storie: righe N, M

esito: nessun errore      (oppure: 1 errore, oppure: E errori; con righe non riconosciute e con --strict vedi 9.2)
```

Le sezioni da 1 a 5 sono, nell'ordine: errori, grado, numeri non decisi (`UNDECIDED`), righe da approvare
(«IPOTESI, NON CONTRATTO»), righe non riconosciute. Le sezioni 6, 7, 8, 9, 10, 12, 13, 14 e 15 vengono dopo. Il
numero 11 non si usa: era la sezione dei blocchi non letti, che non ci sono più. Un file senza entità non ha righe
di citazioni d'entità né sezione 8.

### 9.2 Regole di formato

| Che cosa | Regola |
|---|---|
| Prima riga | `bcdd check`, poi ` --strict` se c'è, poi ` --dir ARG` per ogni cartella nell'ordine in cui è scritta (`ARG` come è scritto), poi ` NOMEFILE`; sempre in questo ordine, dovunque le opzioni siano state scritte. Esempio: `bcdd check --strict --dir comuni Uso.csc` |
| Nome del file | solo il nome, senza cartelle, come è scritto sul disco |
| Rientro | due spazi per ogni voce sotto un titolo; quattro per una citazione sotto il suo blocco (9.4, 9.6) e per le voci di un blocco nella sezione 13 |
| Righe vuote | una riga vuota dopo la sezione «blocchi» e dopo ogni sezione da 1 a 7, e dopo le sezioni 8, 9, 10, 12, 13, 14 e 15 quando ci sono |
| Spazi in fondo | nessuna riga del rapporto finisce con uno spazio |
| Fine | il rapporto finisce con un LF dopo la riga `esito` |
| Sezioni vuote | il titolo c'è sempre, con il conteggio 0 e senza voci |
| Ordine delle voci | per numero di riga; gli errori sulla stessa riga per colonna dell'elemento che li causa, poi per codice; l'errore E11 (senza riga) viene prima di tutti e si scrive `file: [E11] …`. La colonna conta dall'inizio della riga, da 0. Alcuni errori non hanno un elemento solo e hanno **colonna 0**: E06 (stringa non chiusa), E07 (blocco non chiuso), E10 per `PURPOSE` mancante, E23, E33 per un campo mancante ed E40; vengono quindi prima degli altri errori della stessa riga, e fra loro per codice. E10 per `PURPOSE` ripetuto ha la colonna di quel `PURPOSE`. Esempio: un'intestazione rientrata e scritta male, senza `PURPOSE` e senza `END`, dà nell'ordine E07, E10, E09 |
| Stato del blocco | `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-nnn`, `senza STATUS`, oppure `STATUS non valido` (errore E04 nell'intestazione); per una `CSC`, un'`ENTITY`, un `BINDING` e un `PROFILE`. Una `VERIFICATION` non ha stato: la sua riga finisce dopo la versione |
| Intestazione non valida | `CSC (intestazione non valida), STATO`; `REFINEMENT VIEW (intestazione non valida)`; `ENTITY (intestazione non valida), STATO`; `BINDING (intestazione non valida), STATO`; `VERIFICATION (intestazione non valida)`; `PROFILE (intestazione non valida), STATO`. `STATO` è lo `STATUS` scritto, anche `STATUS RATIFIED BY D-nnn`: nessuna riga del blocco è approvata (sezione 7.1, punto 0), ma la riga del blocco riporta lo `STATUS` scritto. Per `ENTITY` lo `STATUS RATIFIED` non è riconosciuto e `STATO` è `senza STATUS` (sezione 5) |
| Sezione 2 | i quattro conteggi (`verbale`, `formale`, `estensione dichiarata`, `non riconosciuta`) sono separati e **non si sommano**: non c'è una riga di totale. Poi una voce per ogni `GUARANTEE` e `ASSUME` di un blocco CSC e per ogni `GUARANTEE` di un'entità, in ordine di riga fra tutte le righe del file, con grado `verbale`, `formale`, `estensione dichiarata` o `non riconosciuta` (sezione 6). Se l'intestazione della riga non è riconosciuta il nome breve è `?` e il grado è `non riconosciuta`, contato nel quarto conteggio: succede quando l'intestazione della riga non rispetta G16, nella CSC come nell'entità (per esempio `GUARANTEE r3 STATUS PIPPO: …` dà `GUARANTEE ? non riconosciuta`). Una promessa d'entità con `STATUS RATIFIED BY D-nnn` o `STATUS RATIFIED` senza decisione (E04) ha il suo nome breve e grado `verbale`, come nella CSC: per esempio `riga 6: GUARANTEE r2 verbale` (sezione 7.1). Un'`ASSUME` in un'entità non ha voce (sezione 5) |
| Sezione 3 | ogni `DEFINE` riconosciuta con valore `UNDECIDED` |
| Sezione 4 | ogni riga contrattuale con intestazione della riga riconosciuta e stato effettivo «da approvare» (sezione 7); **ogni** riga contrattuale di un blocco, CSC o entità, con l'intestazione non valida (E09), qualunque `STATUS` abbiano la riga e l'intestazione (sezione 7.1, punto 0). Inoltre, nell'ordine del file: i dettagli di `DEFINE` (`riga N: DEFINE nome`) e di storie (`riga N: SCENARIO id`) da approvare; le righe `BIND` da approvare (`riga N: BIND elemento`, con l'elemento come è scritto); le estensioni di un profilo da approvare (`riga N: EXTENSION Nome`) |
| Sezione 5 | ogni riga classificata non riconosciuta, con il suo testo senza gli spazi iniziali e finali. Una riga vuota dentro una stringa si scrive `riga N:`. Se la dichiarazione non è riconosciuta per un profilo non trovato o per un'estensione con errori (sezione 4.14), la sua prima riga finisce con ` (profilo P VERSION v non trovato)` oppure ` (EXTENSION X del PROFILE P con errori)` |
| Sezione 6 | i tipi non dichiarati delle dichiarazioni riconosciute, nell'ordine della prima comparsa; per ciascuno le righe, senza ripetizioni. Un tipo descritto a parole (G30) o un elenco di valori (G37) nello stesso blocco non è un tipo non dichiarato |
| Sezione 7 | in ordine di riga, le citazioni **non trovate**, con il motivo se c'è (9.4): le citazioni delle entità, la CSC legata di un `BINDING` o di una `VERIFICATION` (`riga N: Nome`), i `BINDING` nominati con `USING` (`riga N: BINDING Nome AS b`), i profili importati (`riga N: PROFILE Nome`, con il motivo `trovata solo la VERSION w in PERCORSO` se c'è soltanto un'altra versione). Un blocco ritirato non ha parti (4.8). Il titolo dice «CSC» anche per le entità, i blocchi e i profili citati |
| Sezione 8 | solo se il file ha almeno un blocco `ENTITY` (9.4); un file con entità e nessuna voce ha `8. USI DENTRO LE ENTITÀ: 0`. Per un'entità con più composizioni, voci per composizione con il suffisso `(in: …)` (9.5) |
| Sezioni 9 e 10 | solo se almeno un'entità del file ha più di una composizione o E23; la 10 anche con 0 voci (9.5) |
| Conteggi della seconda riga | R + C + V + U = T: ogni riga è in un solo posto |
| Sezioni 12, 13, 14 e 15 | la 12 solo se il file ha almeno un `BINDING`, la 13 solo se ha almeno una `VERIFICATION`, anche con 0 voci; la 14 e la 15 solo se hanno almeno una voce. Il numero è il nome della sezione: resta lo stesso anche quando le sezioni prima mancano. Le regole sono nella 9.6 e nella 9.7. La riga `esito` non cambia: le voci di queste sezioni non sono errori |
| Riga `esito` | conta gli errori, E14 compreso. Se U è almeno 1, anche senza `--strict` si aggiunge `; righe non riconosciute: U (vedi sezione 5)`, con U il numero della seconda riga e la sezione 5 quella delle righe non riconosciute: `esito: nessun errore; righe non riconosciute: 1 (vedi sezione 5)`, `esito: 2 errori; righe non riconosciute: 3 (vedi sezione 5)`. Il codice d'uscita senza `--strict` non cambia: la riga riporta le righe non riconosciute, non le conta come errori. Se U è 0 la parte aggiunta non c'è. Le citazioni non cambiano nient'altro: `U` è sempre quello del file controllato, mai quello dei file citati |
| Riga `esito` con `--strict` | se U è 0, è identica a quella senza opzione. Se U è almeno 1, la riga con l'opzione porta ` (--strict)` al posto di ` (vedi sezione 5)`: `esito: nessun errore; righe non riconosciute: 16 (--strict)`, `esito: 1 errore; righe non riconosciute: 1 (--strict)`. L'etichetta resta `righe` anche per U = 1 |
| Resto del rapporto con `--strict` | identico, byte per byte, al rapporto senza opzione: l'opzione cambia solo la prima riga, la riga `esito` (per il ` (--strict)` al posto di ` (vedi sezione 5)`) e il codice d'uscita |

### 9.3 Un rapporto intero

Per un file `05_ratified_senza_decisione.csc` con una CSC la cui intestazione ha `STATUS RATIFIED` senza decisione:

```
bcdd check 05_ratified_senza_decisione.csc
righe: 13 (riconosciute 9, commenti 2, vuote 2, non riconosciute 0)
blocchi: 1
  riga 4: CSC Ratifiche VERSION 0.1, STATUS non valido

1. ERRORI: 3
  riga 5: [E04] STATUS RATIFIED senza decisione: serve BY D-numero
  riga 9: [E04] STATUS RATIFIED senza decisione: serve BY D-numero
  riga 10: [E04] STATUS RATIFIED senza decisione: serve BY D-numero

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 4
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 8: GUARANTEE g1 verbale
  riga 9: GUARANTEE g2 verbale
  riga 10: GUARANTEE g3 verbale
  riga 12: GUARANTEE g4 verbale

3. UNDECIDED: 0

4. IPOTESI, NON CONTRATTO: 3
  riga 8: GUARANTEE g1
  riga 9: GUARANTEE g2
  riga 10: GUARANTEE g3

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: 3 errori
```

`g1` non ha `STATUS` e l'intestazione della CSC non è valida: è da approvare. `g4` ha la sua approvazione valida
(`D-7`) ed è approvata.

### 9.4 Entità e citazioni

Le **citazioni** di un'entità sono le sue righe G32 (`OFFERS`), G33 (`USES`) e G34 (le parti, anche con
E19) riconosciute. `check` le cerca sempre, per ogni entità del file, anche con intestazione non valida, salvo
quelle con E01. Un blocco ritirato non ha citazioni (sezione 4.8).

**Una sola profondità.** Di un'entità citata come parte si leggono soltanto le sue righe `OFFERS` e `USES` (e le
righe `VARIANT`, con il pezzo di ogni riga: 9.5): non le sue parti, né le CSC che cita. Di una CSC citata si usano
solo intestazione, versione, stato ed esito; **solo se l'entità del file controllato ha almeno un nome qualificato**
in una storia o in una formula (sezioni 4.6 e 4.9), anche le dichiarazioni riconosciute `CAPABILITY`, `EVENT` (con
i parametri) e `STATE` (con il tipo) del blocco trovato. Della CSC legata a un `BINDING` o a una `VERIFICATION` si
usano anche le dichiarazioni `STATE`, `EVENT`, `CAPABILITY` e `DEFINE` riconosciute, i nomi brevi delle storie, il
grado e i nomi delle sue promesse e dei suoi presupposti (per la copertura, 9.6) e le sue righe `IMPORT PROFILE`
(per E38). Di un profilo trovato si usano le estensioni e i loro errori (sezione 4.14). La profondità resta una:
non si cercano le citazioni della CSC citata. «Controllata» vuol dire
che `bcdd` ha letto il blocco citato e ne riferisce versione, stato ed esito; non che le promesse siano coerenti fra
loro, che resta un giudizio.

#### La ricerca

Per una citazione di nome `N` si cerca il blocco `CSC N` con intestazione G1 valida (per `OFFERS` e `USES`, e per
la CSC legata a un `BINDING` o a una `VERIFICATION`, che vale come una `USES N VERSION v`), oppure `ENTITY N` con
intestazione G31 valida (per una parte), `PROFILE N` con intestazione G49 valida (per `IMPORT PROFILE`), o il blocco
`BINDING N VERSION v AS b` (per `USING b`). Le regole qui sotto valgono per tutti; per un profilo la versione deve
essere quella scritta, e un ripiego non è trovato (sezione 4.2). Nell'ordine:

1. **Stesso file**: il primo blocco del tipo cercato con quel nome. Se c'è, la ricerca finisce qui, salvo il
   caso della versione qui sotto. Questo passo non dà mai un motivo.
2. **Stessa cartella**: il file `N.csc` nella cartella del percorso scritto dalla persona (la parte
   dell'argomento prima dell'ultimo `/`, o la cartella corrente se non c'è `/`), anche se l'argomento è un
   collegamento simbolico. `N` si usa byte per byte.
3. **Cartelle `--dir`**: il file `N.csc` in ciascuna, nell'ordine in cui sono scritte.

Un candidato può essere il file controllato stesso: si legge come gli altri.

| Il candidato `N.csc` | La ricerca |
|---|---|
| non esiste: il nome non c'è, una parte del percorso non è una cartella, oppure è un collegamento a un file che non c'è | passa al successivo |
| esiste, si legge, è UTF-8 valido, ma non contiene il blocco cercato | passa al successivo |
| esiste, si legge, è UTF-8 valido e contiene il blocco cercato | **trovata** |
| è una cartella o non è un file normale | **si ferma**, motivo `non è un file: PERCORSO` |
| non si legge (permessi, errore di lettura, ogni altro motivo) | **si ferma**, motivo `non leggibile: PERCORSO` |
| non si sa se esiste: la domanda al sistema fallisce per un motivo diverso da «non c'è» e «una parte del percorso non è una cartella» (per esempio una cartella del percorso senza permesso di attraversamento) | **si ferma**, motivo `non leggibile: PERCORSO` |
| non è UTF-8 valido | **si ferma**, motivo `non UTF-8: PERCORSO` |

**Una versione diversa non ferma la ricerca.** Per una citazione con `VERSION w`, un candidato (anche lo stesso file,
passo 1) che contiene il blocco cercato con un'altra versione non è trovato subito: si ricorda come **ripiego**, solo
il primo, e si passa al successivo. Se un candidato successivo ha la versione `w`, la citazione è trovata lì, senza
`attesa`. Se nessuno la ha, la citazione è trovata nel primo ripiego, con `, attesa VERSION w`. Un candidato che
ferma la ricerca (`non è un file`, `non leggibile`, `non UTF-8`) la ferma anche quando c'è un ripiego: la citazione
è trovata nel ripiego. Senza `VERSION` nella citazione il primo candidato con il blocco è trovato. La regola serve
perché un file `N.csc` contiene una versione sola (due blocchi con lo stesso nome sono E01): due versioni si trovano
tutte e due solo in file diversi, per esempio in due cartelle `--dir`.

**Se non è trovata**, il motivo è, nell'ordine: quello del candidato che ha fermato la ricerca; altrimenti
`PERCORSO non contiene CSC N` (o `… non contiene ENTITY N`) per il **primo** candidato che non conteneva il
blocco; altrimenti nessun motivo.

**`PERCORSO`.** Per la stessa cartella solo `N.csc`, senza cartelle. Per una `--dir` l'argomento come è
scritto, seguito da `/` se non finisce già con `/`, e da `N.csc`.

**Che cosa si usa del file trovato.** Si legge con le regole di `check` (BOM, CR LF, UTF-8) e si esamina per
intero, **senza** cercarne le citazioni (quindi E14 non vi è mai contato). Se ne usano: la riga
dell'intestazione del blocco trovato, la sua versione e il suo stato (regola «Stato del blocco» della 9.2);
il numero di errori di tutto il file e il numero `U` delle sue righe non riconosciute; per un'entità, le sue
righe `OFFERS` e `USES` riconosciute, nell'ordine, salvo quelle con E01 in quel file.

**Versioni fra una citazione e il blocco trovato.** Si confrontano come testo (`0.1` e `0.10` sono
diverse). Una citazione senza versione combacia con qualunque versione del blocco trovato, che ha sempre
una versione (G1 e G31 la chiedono). Una versione diversa non è un errore: il rapporto la segnala.

**Determinismo.** `bcdd` può tenere in memoria un file già letto; il rapporto è quello che si avrebbe leggendo ogni
candidato una volta sola, nell'ordine sopra.

#### Le righe delle citazioni trovate

Il conteggio `blocchi: B` conta anche le entità. Sotto la riga di un'entità, rientrata di **quattro**
spazi, una riga per ogni citazione **trovata**, in ordine di riga:

```
    riga N: OFFERS X in questo file alla riga M
    riga N: USES X in PERCORSO alla riga M: VERSION v, STATO, ESITO
    riga N: p : X in PERCORSO alla riga M: VERSION v, STATO, ESITO
```

- `N` è la riga della citazione nel file controllato; `M` la riga dell'intestazione trovata.
- La citazione si scrive senza la sua versione e senza la molteplicità: `OFFERS X`, `USES X`, `p : X` (nome della
  parte, spazio, due punti, spazio, nome dell'entità).
- `STATO`: regola «Stato del blocco» della 9.2. `ESITO`: `nessun errore`, `1 errore` oppure `E errori`,
  seguito da `, righe non riconosciute: U` se `U` > 0, con o senza `--strict`.
- Nello stesso file si scrive solo `in questo file alla riga M`: versione, stato ed errori di quel blocco
  sono già nel rapporto.
- Se la citazione dichiara `VERSION w` e il blocco trovato ha `VERSION v` diversa, la riga finisce con
  `, attesa VERSION w`. Nello stesso file: `riga N: OFFERS X in questo file alla riga M: VERSION v, attesa
  VERSION w`.

Ogni citazione sta in un posto solo: sotto la sua entità, se trovata, o nella sezione 7, `riga N: X` oppure
`riga N: X (MOTIVO)`, con `X` il nome citato senza versione. Una citazione con E01 non sta in nessuno dei
due: c'è il suo errore.

#### Sezione 8 ed errore E14

La sezione 8 c'è **solo se il file contiene almeno un blocco `ENTITY`**, dopo la sezione 7 e prima della
riga `esito`, seguita da una riga vuota.

```
8. USI DENTRO LE ENTITÀ: n
  riga N: P usa X: la offre Q (riga M)
  riga N: P usa X: la offrono Q (riga M), R (riga K)
  riga N: P usa X: la usa E da fuori (riga M)
  riga N: P usa X: nessuno la offre
  riga N: P usa X: nessuna parte trovata la offre (parti non controllate: k)
```

**Le voci.** Per ogni entità `E` del file, in ordine di riga; per ogni sua parte `P` **trovata**, in ordine
di riga (`N` è la riga di `P` nel file controllato); per ogni riga `USES` del blocco trovato di `P`,
nell'ordine in cui le scrive `P`. `X` si scrive come nella riga `USES` di `P`, con ` VERSION w` se c'è; le
parti si scrivono con il loro nome nell'entità (`lampada`, non `Lampada`). `n` è il numero di voci.

**Il combaciare (non è simmetrico).** La riga `USES X [VERSION w]` di `P` è una **domanda**. Combacia con una riga
`OFFERS Y [VERSION v]` di un'altra parte trovata, o con una riga `USES Y [VERSION v]` di `E` stessa, se `X` e `Y`
sono uguali byte per byte **e**:

| La riga `USES` di `P` | L'altra riga | Combaciano |
|---|---|---|
| `USES X` (senza versione) | `OFFERS X` o `OFFERS X VERSION v`, qualunque `v` | sì |
| `USES X VERSION w` | `OFFERS X VERSION w` (stesso testo) | sì |
| `USES X VERSION w` | `OFFERS X VERSION v` con `v` diversa da `w` | no |
| `USES X VERSION w` | `OFFERS X` (senza versione) | **no**: chi non dichiara una versione non promette la `w` |

Lo stesso vale con `USES X [VERSION v]` di `E` al posto di `OFFERS`. Le righe con E01 non contano mai.

| Caso, nell'ordine | Voce | Errore |
|---|---|---|
| una o più **altre** parti trovate di `E` hanno una riga `OFFERS` che combacia | `la offre Q (riga M)`, oppure `la offrono Q (riga M), R (riga K)` in ordine di riga, separate da `, `; `M`, `K` sono le righe delle parti nel file controllato | no |
| nessuna, ma `E` ha una riga `USES` che combacia | `la usa E da fuori (riga M)`, con `M` la riga di quella `USES` | no |
| nessuna delle due, e **tutte** le parti di `E` sono trovate | `nessuno la offre` | **E14** sulla riga `N` |
| nessuna delle due, e almeno una parte di `E` non è trovata | `nessuna parte trovata la offre (parti non controllate: k)`, con `k` il numero di parti di `E` nella sezione 7 | no: E14 è sospeso |

- «Altra parte» vuol dire un'altra riga di parte, anche se nomina la stessa entità (due parti `a : Nodo` e
  `b : Nodo` si soddisfano a vicenda). La `OFFERS X` di `P` non soddisfa la sua stessa `USES X`, anche se `P`
  ha una molteplicità con `m` >= 2 (sezione 4.9).
- **Più versioni** (sezione 5): ogni riga `OFFERS` o `USES` vale da sola, con il combaciare qui sopra. Se una parte
  `Q` ha due righe che combaciano con la stessa riga `USES` (`USES Pulsanti` senza versione e le due `OFFERS
  Pulsanti VERSION 0.1` e `0.2`), nella voce `Q` compare **una volta**. E16 ed E17 si contano riga per riga: una
  `OFFERS X VERSION 0.1` di una parte che nessuno usa più dà il suo E17.
- Una parte trovata con errori o con righe non riconosciute dà le voci delle sue righe `USES` riconosciute e
  offre con le sue righe `OFFERS` riconosciute.
- Una parte che nomina l'entità stessa che la contiene si tratta come le altre: la profondità è una sola.
- Non si controlla che le CSC che `E` offre siano offerte da qualche parte (sezione 14).

#### Il rapporto intero sulla luce delle scale

`bcdd check LuceScale.csc` sul file della sezione 4.9, con le CSC e le entità citate nella stessa cartella, dà
esattamente questo, codice 0:

```
bcdd check LuceScale.csc
righe: 10 (riconosciute 10, commenti 0, vuote 0, non riconosciute 0)
blocchi: 1
  riga 1: ENTITY LuceScale VERSION 0.2, senza STATUS
    riga 3: OFFERS Pressione in Pressione.csc alla riga 1: VERSION 0.1, senza STATUS, nessun errore
    riga 4: OFFERS Luce in Luce.csc alla riga 1: VERSION 0.1, senza STATUS, nessun errore
    riga 6: pulsante : Pulsante in Pulsante.csc alla riga 1: VERSION 0.1, senza STATUS, nessun errore
    riga 7: lampada : Lampada in Lampada.csc alla riga 1: VERSION 0.1, senza STATUS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 1
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 8: GUARANTEE g1 verbale

3. UNDECIDED: 0

4. IPOTESI, NON CONTRATTO: 1
  riga 8: GUARANTEE g1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 1
  riga 7: lampada usa Comando: la offre pulsante (riga 6)

esito: nessun errore
```

`pulsante` non ha righe `USES`, quindi non dà voci; `Pulsante` offre `Comando` nel suo file, e la voce cita
la riga della parte `pulsante` nel file controllato (6). Senza il pulsante (un'entità `SenzaPulsante` con la sola
parte `lampada` alla riga 5) la voce diventa `riga 5: lampada usa Comando: nessuno la offre`, con `riga 5: [E14] la
parte lampada usa il connettore Comando: nessun'altra parte di SenzaPulsante lo offre, né SenzaPulsante lo usa da
fuori` e codice 1. Se invece la lampada scrive `USES Comando VERSION 0.2` e il pulsante scrive solo `OFFERS Comando`,
la voce è `nessuno la offre` ed E14: il pulsante non ha promesso la 0.2.

### 9.5 Composizioni e assenze dichiarate

Le regole delle composizioni sono nella sezione 4.10; qui si descrive come si scrivono nel rapporto.

**Il suffisso `(in: …)`.** Dato un universo di composizioni (per un errore e per una voce della sezione 8: tutte
quelle dell'entità; per una voce della sezione 10: quelle senza la parte nominata) e l'insieme `S` delle
composizioni dove il fatto si verifica:
1. `S` è tutto l'universo: nessun suffisso;
2. altrimenti, il primo valore `a` di un fattore (fattori e valori nell'ordine della sezione 4.10) tale che `S` sia
   esattamente l'insieme delle composizioni dell'universo che hanno `a`: ` (in: a)`;
3. altrimenti ` (in: N1; N2; …)`, con i nomi delle composizioni di `S` nel loro ordine, separati da `; `.

Il suffisso si scrive dopo il messaggio di un errore (sezione 1), dopo una voce della sezione 8 e dopo una voce
della sezione 10. Il messaggio resta quello della sezione 8, con il nome dell'entità del file.

**Sezione 1.** Lo stesso errore trovato in più composizioni (codice, riga, colonna e messaggio uguali) si scrive
una volta, con il suffisso. L'ordine delle voci non cambia (9.2).

**Sezione 8.** Per un'entità con più di una composizione, le voci si calcolano in ogni composizione; le voci con lo
stesso testo si scrivono una volta, con il suffisso. Ordine: riga della parte, ordine delle righe `USES` della parte,
prima composizione in cui la voce compare. `n` conta le voci scritte. Esempio, per un kit di misura con un gruppo di
scelte `sensore` e una parte facoltativa `di`:

```
  riga 18: cattura usa SegnaleLivello: la offre di (riga 46) (in: con di)
  riga 18: cattura usa SegnaleLivello: nessuno la offre (in: senza di)
  riga 18: cattura usa SegnaleLivello: la offre microfono (riga 88) (in: sensore = microfono)
```

**Sezione 9.** `9. COMPOSIZIONI: c`. Una voce per ogni entità con più di una composizione o con E23, in ordine di
riga: `riga N: ENTITY Nome: k`, con sotto, rientrati di quattro spazi, i nomi delle `k` composizioni nel loro
ordine; per un'entità con E23 la sola riga `riga N: ENTITY Nome: più di 64, non controllate`. `c` è la somma delle
`k` (un'entità con E23 conta 0). Un'entità con E21 su una riga `VARIANT` non ha voce.

**Sezione 10.** `10. ASSENZE DICHIARATE: a`. Una voce per ogni assenza dichiarata (sezione 4.10), raggruppata come
gli errori: `riga N: senza P: messaggio`, con il suffisso sull'universo delle composizioni senza `P`. Ordine: riga,
colonna, codice (come la sezione 1), poi prima composizione. Le assenze non contano nella riga `esito` e non cambiano
il codice d'uscita. Esempio, per lo stesso kit (codice 0):

```
9. COMPOSIZIONI: 3
  riga 5: ENTITY Kit1b: 3
    sensore = di, con di
    sensore = di, senza di
    sensore = microfono

10. ASSENZE DICHIARATE: 2
  riga 18: senza di: la parte cattura usa il connettore SegnaleLivello: nessun'altra parte di Kit1b lo offre, né Kit1b lo usa da fuori
  riga 43: senza di: il connettore pubblico Morsetti di Kit1b (usato) non è affidato a nessuna parte
```

**Le parti con varianti** (9.4, «Una sola profondità»). Di un'entità citata come parte si leggono anche le sue righe
`VARIANT` riconosciute, e per ogni riga `OFFERS` e `USES` il pezzo dove sta; non le sue parti.

### 9.6 Forme concrete, piano di prova e profili nel rapporto

**Le righe dei blocchi.** Nella sezione «blocchi» un `BINDING` si scrive `riga N: BINDING Nome VERSION v, STATO`,
con ` AS b` dopo la versione se c'è; una `VERIFICATION` `riga N: VERIFICATION Nome VERSION v`; un profilo `riga N:
PROFILE Nome VERSION v, STATO`. Sotto la riga di un blocco, rientrate di quattro spazi e in ordine di riga, stanno le
sue citazioni trovate, con la forma della 9.4: la CSC legata (`riga N: CSC Nome in PERCORSO alla riga M: …`, dove
`N` è la riga dell'intestazione del blocco), i profili importati (`riga N: IMPORT PROFILE P in PERCORSO alla riga M:
VERSION v, STATO, ESITO`, anche sotto una CSC o un'entità), i `BINDING` nominati con `USING` (`riga N: USING b in
PERCORSO alla riga M`). Nello stesso file: `in questo file alla riga M`.

**Sezione 12, forme concrete mancanti.** `12. FORME CONCRETE MANCANTI: k`. Una voce per ogni `BINDING` del file la
cui CSC legata è trovata con la versione scritta, in ordine di riga: `riga N: BINDING Nome VERSION v[ AS b]: ` seguito
dagli elementi della CSC che nessuna riga `BIND` del blocco nomina, nell'ordine del blocco della CSC, ciascuno con la
sua parola chiave (`STATE modo`, `EVENT IN pressione`, `EVENT OUT accendi`, `CAPABILITY Pulizie`), separati da `, `;
oppure `nessuna` se ogni elemento ha una forma. Un `BINDING` la cui CSC non è trovata ha la voce `riga N: BINDING Nome
VERSION v: CSC non trovata, elementi non controllati`. `k` è il numero degli elementi elencati. Nessuna voce è un
errore.

**Sezione 13, copertura del piano di prova.** `13. COPERTURA DEL PIANO DI PROVA: k`. Per ogni `VERIFICATION` del file,
in ordine di riga, la riga del blocco e sotto, rientrate di quattro spazi:
- una riga per ogni mezzo, `nome (riga M): id, id, …`, con le promesse e i presupposti della CSC legata di grado
  formale o estensione dichiarata **osservati** da quel mezzo, nell'ordine della CSC, oppure `nessuna`. Una riga
  contrattuale è osservata da un mezzo se ogni stato, evento e richiesta che nomina è fra gli elementi `OBSERVES`
  del mezzo (un evento `e.p` osservato vale per il parametro; `e` osservato vale per tutti i suoi parametri);
- una riga `non eseguite: id, id, …` con le righe formali o di estensione dichiarata che nessun mezzo osserva,
  oppure `non eseguite: nessuna`.

Le righe verbali non hanno voce: si verificano a giudizio o per ispezione. Se la CSC legata non è trovata, sotto la
riga del blocco c'è soltanto `CSC non trovata: copertura non calcolata`. `k` è il numero dei nomi brevi elencati
nelle righe `non eseguite` di tutti i blocchi (`non eseguite: l2, l3` conta 2; `nessuna` conta 0). Esempio, per un piano della luce delle scale con un mezzo che osserva solo `accesa`:

```
13. COPERTURA DEL PIANO DI PROVA: 1
  riga 20: VERIFICATION Luce VERSION 0.1
    telecamera (riga 21): l1
    non eseguite: l2
```

### 9.7 Da giudicare e controlli non eseguiti

**Sezione 14, da giudicare.** `14. DA GIUDICARE: k`. Una voce per ogni regola del linguaggio che solo una persona
può applicare, in ordine di riga e, sulla stessa riga, nell'ordine della tabella:

| Voce | Quando | Testo |
|---|---|---|
| un dettaglio con una riga a parole | una riga con `DETAILS` (contrattuale, `DEFINE` o storia) di cui la riga stessa o quella che dettaglia è a parole | `riga N: TIPO id DETAILS p: coerenza fra la riga e la riga che dettaglia, una delle due a parole` |
| il significato di un'estensione | ogni estensione senza errori E33 | `riga N: EXTENSION X: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti` |
| un'estensione senza riduzione | ogni estensione senza `REDUCES TO` riconosciuta | `riga N: EXTENSION X: non ripete una forma che il linguaggio ha già` |
| significato e riduzione | ogni estensione con una `REDUCES TO` riconosciuta | `riga N: EXTENSION X: MEANING e REDUCES TO dicono la stessa cosa` |

`N` è la riga della dichiarazione con `DETAILS` o della riga `EXTENSION`; `TIPO` è `GUARANTEE`, `ASSUME`, `DEFINE` o
`SCENARIO`.

**Quando una riga è «a parole».** Una promessa o un presupposto è a parole se il suo grado è `verbale`. Una `DEFINE`
non è mai a parole: il suo valore è un'espressione o `UNDECIDED`. Una storia è a parole se almeno un suo passo ha un
elemento `VERBAL`. Quindi un dettaglio di `DEFINE` va sempre nella voce «coerenza dei dettagli» della sezione 15; un
dettaglio di storia va nella sezione 14 se la storia o quella che dettaglia è a parole, altrimenti nella sezione 15.
Una riga non riconosciuta non è né a parole né formale: un dettaglio in cui una delle due righe è non riconosciuta va
nella sezione 14 solo se l'altra è a parole, e mai nella 15. Le voci della sezione 14 non sono errori, non sono esiti e non cambiano il codice d'uscita: dicono che
cosa resta da giudicare.

**Sezione 15, controlli non eseguiti.** `15. CONTROLLI NON ESEGUITI: k`. `check` non valuta le formule: non controlla
se le storie hanno l'esito che dichiarano, se ogni innesco avviene in una storia, se le promesse e i presupposti
possono valere insieme, né se un dettaglio formale è coerente con la riga che dettaglia. La sezione elenca, per
ciascuno di questi controlli, le righe a cui si applicherebbe, in quest'ordine:

| Voce | Righe elencate |
|---|---|
| `storie` | le storie (`SCENARIO`) dei blocchi CSC ed entità che hanno almeno una promessa o un presupposto di grado formale, o di estensione dichiarata con `C3` nel `VERIFY V1` dell'estensione |
| `copertura degli inneschi` | le promesse di grado formale che hanno un innesco (`WHENEVER p THEN q`; `ALWAYS (p IMPLIES q)`; un ambito, anche un uso di un'estensione di `KIND SCOPE` con `REDUCES TO`; una forma di BASE con innesco nella sua forma estesa), e quelle di estensione dichiarata con `C4` |
| `coerenza di presupposti e promesse` | le promesse e i presupposti di grado formale, e quelli di estensione dichiarata con `C2` |
| `coerenza dei dettagli` | le righe con `DETAILS` di cui né la riga né quella che dettaglia è a parole o non riconosciuta |

Una riga di grado estensione dichiarata entra in una voce quando **almeno una** delle estensioni che usa (anche
dentro l'argomento di un altro uso, sezione 4.14) ha il controllo nel suo `VERIFY V1`: `C3` per «storie», `C4` per
«copertura degli inneschi», `C2` per «coerenza di presupposti e promesse». Elencare un controllo in più non fa
credere controllata nessuna riga; tacerne uno sì.

Ogni voce si scrive `nome: righe N, M, …` (oppure `nome: riga N` con una riga sola), con le righe in ordine
crescente; una voce senza righe non si scrive. `k` è il numero delle voci scritte. Esempio:

```
15. CONTROLLI NON ESEGUITI: 3
  storie: righe 30, 35
  copertura degli inneschi: righe 12, 14
  coerenza di presupposti e promesse: righe 12, 14, 20
```

Le righe della sezione 15 non sono né soddisfatte né violate: un controllo non eseguito non dice niente su di
loro.

---

## 10. Il comando `bcdd check`

Forma: `bcdd check [--strict] [--json] [--dir CARTELLA]... FILE`.
- L'opzione `--strict` si può scrivere prima o dopo `FILE`, una volta sola.
- L'opzione `--json` si può scrivere prima o dopo `FILE`, in qualunque ordine con le altre, una volta sola. Fa lo
  stesso controllo, con gli stessi codici d'uscita e gli stessi messaggi sullo standard error; sullo standard
  output, al posto del rapporto, scrive un solo oggetto JSON, con `"forma": "bcdd-check"` e `"versione": 5`.
  L'oggetto contiene, fra l'altro: il campo `molteplicita` delle citazioni `PART` (sezione 4.9); una dichiarazione
  `TYPE` per un elenco di valori, per un tipo con nome e per un `Record`, e `SCENARIO` per una storia d'entità;
  `varianti` nei blocchi `ENTITY`; `variante` (`{"dimensione", "scelta"}` o `null`) in dichiarazioni, promesse e
  citazioni; `in` (il suffisso senza parentesi né `in: `, o `null`) negli errori e negli usi, il cui `messaggio` e
  `testo` restano senza suffisso; nel `rapporto` `ha_composizioni`, `composizioni[]` (sezione 9) e `assenze[]`
  (sezione 10). Dalla versione 5: i valori `BINDING`, `VERIFICATION` e `PROFILE` di `blocchi[].tipo`, con `legata`
  (`{"nome", "versione"}` della CSC legata) e `nome_proprio` (il nome dopo `AS`, o `null`) per un `BINDING`, e
  `estensioni[]` per un `PROFILE` (per ciascuna `nome`, `da`, `a`, `kind`, `level`, `riduzione` vero o falso);
  `stato` `null` per una `VERIFICATION`; le citazioni di tipo `IMPORT`, `LEGATA` e `USING` nelle `citazioni[]` di ogni
  blocco; il valore `formale` ed `estensione_dichiarata` di `garanzie[].grado` e di `rapporto.gradi[].grado`, e il
  conteggio `rapporto.conteggi.estensione_dichiarata`, accanto a `verbale`, `formale` e `non_riconosciuta`; i
  conteggi `rapporto.conteggi.forme_mancanti` (il `k` della sezione 12) e `rapporto.conteggi.non_eseguite_piano`
  (il `k` della sezione 13); `rapporto.ha_binding` e `rapporto.ha_verification` (vero se il file ha almeno un
  blocco di quel tipo); in `rapporto.ipotesi[]` il campo `tipo` (`GUARANTEE`, `ASSUME`, `DEFINE`,
  `SCENARIO`, `BIND`, `EXTENSION`); il campo `motivo` (o `null`) nelle voci di `rapporto.non_riconosciute[]`;
  `rapporto.forme_mancanti[]` (sezione 12), `rapporto.copertura[]` (sezione 13), `rapporto.da_giudicare[]`
  (sezione 14) e `rapporto.non_eseguiti[]` (sezione 15), sempre presenti, vuoti quando la sezione non c'è. Dalla
  versione 5 non ci sono più `rapporto.conteggi.non_lette`, `rapporto.blocchi_non_letti[]` né il valore `non_letta`
  di `righe[].tipo`, perché nessun blocco resta non letto. `esito.riga` è quella del rapporto. Aggiungere un campo
  non cambia la versione della forma; toglierne uno, o cambiarne il significato, sì. Nelle righe della tabella qui
  sotto con «il rapporto», con `--json` si legge «l'oggetto JSON»; dove lo standard output è «niente», resta niente.
- Ogni `--dir CARTELLA` si scrive prima o dopo `FILE`, in qualunque ordine con `--strict`. L'argomento che
  segue `--dir` è sempre la cartella, anche se comincia con `-`: `--dir --strict` cerca una cartella che si
  chiama `--strict`.
- La stessa stringa dopo due `--dir` è uso sbagliato; due stringhe diverse per la stessa cartella (`a` e
  `./a`) sono ammesse e si cercano tutte e due. Una `--dir` uguale alla cartella del file non è un errore.
- Ogni altro argomento che comincia con `-`, anche `--dir=X`, è un uso sbagliato; un file il cui nome
  comincia con `-` si indica con il percorso, per esempio `./-x.csc`.
- Le cartelle servono solo alla ricerca delle citazioni (sezione 9.4): in un file senza entità non cambiano
  altro che la prima riga del rapporto.

| Caso | Standard output | Standard error | Codice d'uscita |
|---|---|---|---|
| file letto, nessun errore; senza `--strict`, oppure con `--strict` e nessuna riga non riconosciuta | il rapporto | niente | 0 |
| file letto, almeno un errore (con o senza `--strict`) | il rapporto | niente | 1 |
| file letto, nessun errore, `--strict` e almeno una riga non riconosciuta | il rapporto | niente | 3 |
| file che non esiste: il sistema risponde che il nome non c'è, oppure che una parte del percorso non è una cartella; anche un collegamento simbolico che punta a un file che non c'è | niente | `bcdd check: file non trovato: ARG` | 2 |
| è una cartella o non è un file normale | niente | `bcdd check: non è un file: ARG` | 2 |
| ogni altro motivo per cui il file non si può esaminare o leggere: permessi del file, permessi di una cartella del percorso, errore di lettura | niente | `bcdd check: non leggibile: ARG` | 2 |
| byte non UTF-8 | niente | `bcdd check: il file non è UTF-8 valido (riga N)`, con N la riga del primo byte sbagliato | 2 |
| `--dir ARG`: il nome non c'è, o una parte del percorso non è una cartella | niente | `bcdd check: cartella non trovata: ARG` | 2 |
| `--dir ARG` esiste ma non è una cartella | niente | `bcdd check: non è una cartella: ARG` | 2 |
| `--dir ARG` è una cartella ma non si può aprire per leggerne il contenuto; oppure non si sa se esiste, perché la domanda al sistema fallisce per un altro motivo (per esempio una cartella del percorso senza permesso di attraversamento) | niente | `bcdd check: cartella non leggibile: ARG` | 2 |
| argomenti mancanti o in più; `--strict` ripetuto; `--json` ripetuto; `--dir` senza argomento; la stessa `--dir` ripetuta; un'altra opzione che comincia con `-` | niente | `uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE` | 2 |

`ARG` è l'argomento così come è stato scritto. Ogni messaggio d'errore finisce con un LF.
I controlli si fanno in quest'ordine: gli argomenti; poi il file (che esista, che sia un file normale, che si
legga, che sia UTF-8); poi le cartelle `--dir`, una alla volta nell'ordine scritto. Il primo che fallisce decide il
messaggio. Un collegamento simbolico si segue: un collegamento a una cartella è una cartella, uno rotto è
«non trovata». «Non leggibile» non dice la causa di proposito: per `check` la persona
deve sapere solo che il file non è stato controllato, e il codice 2 lo dice.

**Che cosa prevale.** Se un file ha errori e anche righe non riconosciute, con `--strict` il codice è 1:
gli errori prevalgono, perché sono il problema più grave e vanno corretti per primi; le righe non
riconosciute restano visibili nella sezione 5 e nella riga `esito`. In generale, dal più forte: 2 (il
file non si è potuto controllare), 1 (errori), 3 (solo righe non riconosciute, con `--strict`), 0.
Il codice 3 esce quindi solo da un file letto per intero e senza errori. E14 è un errore come gli altri
(codice 1). Una citazione non trovata, con errori o con righe non riconosciute non cambia il codice, né con
né senza `--strict`.

Proprietà che `check` rispetta:
- il file non cambia mai, né i file che legge per le citazioni, nemmeno la data di modifica;
- il grado di ogni riga contrattuale, ogni `UNDECIDED` e ogni riga da approvare sono nel rapporto;
- ogni regola che resta da giudicare (sezione 14) e ogni controllo non eseguito sulle formule (sezione 15) sono nel
  rapporto: nessuna formula risulta controllata più di quanto lo è;
- ogni riga non riconosciuta è nella sezione 5, con il suo numero;
- lo stesso file, con gli stessi file citati e le stesse cartelle, dà sempre lo stesso rapporto, byte per byte, da
  qualunque cartella si lanci il comando, purché le `--dir` nominino le stesse cartelle (una `--dir` relativa nomina
  una cartella diversa da un'altra cartella di lavoro);
- con `--strict` un file con anche una sola riga non riconosciuta dà un esito di errore (codice 3, o 1 se ci sono
  anche errori); senza `--strict` una riga non riconosciuta non cambia il codice;
- ogni citazione di un'entità del file è sotto l'entità, se trovata, o nella sezione 7, con il motivo se c'è; una
  citazione con E01 non si cerca e si vede dal suo errore nella sezione 1; una citazione mancante, o un file citato
  con errori, non cambia l'esito;
- una versione citata diversa da quella trovata è nel rapporto (`, attesa VERSION w`);
- dentro un'entità con tutte le parti trovate, una CSC che una parte usa e che nessun'altra parte offre, né l'entità
  usa da fuori, è l'errore E14.

Per un comando sconosciuto e per `bcdd` senza argomenti: niente sullo standard output, e sullo standard error

```
uso: bcdd new NOME | bcdd check [--strict] [--json] [--dir CARTELLA]... FILE | bcdd refine FILE [--csc NOME] | bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero
```

su una riga sola, con un LF finale; codice 2.

---

## 11. Il comando `bcdd new`

`bcdd new NOME` crea nella cartella corrente il file `NOME.csc`.

| Caso | Standard output | Standard error | Codice | File |
|---|---|---|---|---|
| creato | `creato NOME.csc` | niente | 0 | creato, con il testo qui sotto |
| `NOME.csc` esiste già (file, cartella o collegamento) | niente | `bcdd new: NOME.csc esiste già: non lo sovrascrivo` | 1 | **non toccato** |
| NOME non è un Nome (regola L7) | niente | `bcdd new: nome non valido: NOME` | 2 | nessuno |
| argomenti mancanti o in più | niente | `uso: bcdd new NOME` | 2 | nessuno |
| il file non si può creare o scrivere: cartella senza permesso di scrittura, disco pieno, ogni altro errore del sistema | niente | `bcdd new: non riesco a creare NOME.csc: CAUSA` | 1 | nessuno, nemmeno un file temporaneo |

Il file nasce per intero o non nasce: non deve mai restare scritto a metà.

**Quali nomi.** «Non riservata» nella regola L7 vuol dire: non è una delle parole della sezione 2.3, la stessa
lista di `check`. Così `bcdd new` non crea mai un file la cui intestazione `check` rifiuta.

`CAUSA` è la descrizione dell'errore data dal sistema (per esempio `Permission denied`), in una riga.
È l'unico testo di `bcdd` che questo documento **non** fissa carattere per carattere: dipende dal sistema. Il testo
è fissato fino a `NOME.csc: ` compreso; dopo c'è almeno un carattere e un solo LF finale. Il codice è 1, come per il
file che esiste già: in tutti e due i casi il comando è stato scritto bene, ma il file non è stato creato; il 2
resta per l'uso sbagliato.

**Testo dello scheletro.** Al posto di `NOME` va il nome dato; ogni riga finisce con LF, anche l'ultima; codifica
UTF-8 senza BOM:

```
-- CSC creata da bcdd new. Si compila a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga è contratto: è un'ipotesi finché l'operatore non ratifica.

CSC NOME VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "da compilare: in una frase, di che cosa è responsabile NOME"

  -- Ingressi e uscite (togliere il commento e compilare):
  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere
  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori
  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce
  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori

  -- Promesse a parole:
  -- GUARANTEE g1: VERBAL "che cosa promette"
  --               VERIFY BY JUDGEMENT "chi giudica, e su che cosa"
END
```

Lo scheletro ha le sole righe obbligatorie (`CSC`, `VERSION`, `PURPOSE`, `END`) più `STATUS HYPOTHESIS`, che rende
esplicito ciò che varrebbe comunque. Il resto è commento: suggerisce le forme senza creare righe da controllare.

---

## 12. Il comando `bcdd ratify`

`bcdd ratify` registra l'approvazione di una riga, o di tutte, modificando soltanto le righe `STATUS`. Lavora sulle
CSC, sulle promesse di un'entità, sui `BINDING` e sui profili; una `VERIFICATION` non si approva. Gli esempi sono
sulla luce delle scale.

### 12.1 Forma

```
bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-nnn
```

`ratify` lavora sulle CSC e sulle **promesse di un'entità**: in un'entità approva, con `ID`, una promessa, con
`--all` tutte quelle ancora da approvare; mai l'intestazione, le righe `OFFERS` e `USES` o le parti dell'entità. Una
promessa d'entità si approva solo se ogni CSC che l'entità offre o usa è stata trovata, nella versione chiesta, in
un file senza errori (sezione 12.2, passo 7).

In una CSC `ID` può essere anche il nome di un dettaglio di `DEFINE` o il nome breve di un dettaglio di storia (G12,
G19 con `DETAILS`), che si approvano come le righe contrattuali. Un `BINDING` si approva come una CSC, con
l'intestazione o con `--all`; le righe `BIND` non hanno un nome breve e non si approvano una per una. Un profilo si
approva soltanto per intero, con l'intestazione o con `--all` (che per un profilo fa lo stesso): le estensioni non
hanno uno stato proprio.

| Comando | Che cosa approva | Esempio |
|---|---|---|
| `bcdd ratify FILE D-nnn` | l'**intestazione** della CSC; le righe che ereditano (sezione 7.1, punto 4) diventano approvate con lei | `bcdd ratify LuceScale.csc D-135` |
| `bcdd ratify FILE ID D-nnn` | la **riga** `ID`, che deve essere da approvare | `bcdd ratify LuceScale.csc g2 D-135` |
| `bcdd ratify FILE --all D-nnn` | l'intestazione e **ogni** riga che resterebbe da approvare, in una sola scrittura | `bcdd ratify LuceScale.csc --all D-135` |

- Gli argomenti che non cominciano con `-` sono **posizionali**: 2 (`FILE D-nnn`) o 3 (`FILE ID D-nnn`);
  con `--all` devono essere 2.
- L'ultimo posizionale è il **riferimento della decisione**: regola L9 (`D-` seguito da sole cifre).
- Con 3 posizionali, quello di mezzo è l'**ID**, il nome breve della riga: regola L8.
- `--csc NOME` sceglie la CSC quando il file ne contiene più d'una; `NOME` segue la regola L7. Si scrive in
  qualunque posizione, una volta sola, e il nome è l'argomento che lo segue.
- `--all` si scrive in qualunque posizione, una volta sola, e non ha argomento.
- `--dir CARTELLA` come in `check` (sezione 10): in qualunque posizione, anche più volte; l'argomento che segue
  `--dir` è sempre la cartella, anche se comincia con `-`, e non conta fra i posizionali; la stessa stringa dopo due
  `--dir`, `--dir` come ultimo argomento e `--dir=X` sono uso sbagliato. Le cartelle servono alla ricerca delle
  citazioni, nel passo 4 e nel passo 7 della 12.2.
- Un file il cui nome comincia con `-` si indica con il percorso, per esempio `./-x.csc`, come in `check`.

### 12.2 Ordine dei controlli

Il primo controllo che fallisce decide il messaggio e il codice; il file non si tocca.

1. Argomenti, in quest'ordine: numero dei posizionali e opzioni (`uso: …`), decisione, ID, nome dopo `--csc` (le
   righe con codice 2 della sezione 12.5).
2. Lettura del file: gli stessi casi di `bcdd check` (sezione 10), con il prefisso `bcdd ratify:` al posto
   di `bcdd check:`.
3. Le cartelle `--dir`, una alla volta nell'ordine scritto, con i casi e i messaggi della sezione 10 e il prefisso
   `bcdd ratify:` (per esempio `bcdd ratify: cartella non trovata: ARG`), codice 2.
4. **Il file passa `bcdd check --strict`**: nessun errore e nessuna riga non riconosciuta, in tutto il file. Si
   approva solo ciò che `bcdd` ha letto per intero. Il controllo cerca le citazioni delle entità come `check`: nello
   stesso file, nella sua cartella e nelle cartelle `--dir`. Un E14, un E04 o una riga non riconosciuta in
   un'entità impedisce l'approvazione di ogni blocco del file. Le voci delle sezioni 12-15 del rapporto non sono
   errori e non fermano il passo 4.
5. **Scelta del blocco** (vale anche per `refine`):

   | Il file | Senza `--csc` | Con `--csc NOME` |
   |---|---|---|
   | almeno una CSC | fra le CSC, dovunque stiano gli altri blocchi: una sola è quella; più d'una, `il file contiene N CSC: …` | il blocco `NOME` (vedi sotto) |
   | nessuna CSC, una sola entità | l'entità | il blocco `NOME` |
   | nessuna CSC, più entità | `il file contiene N ENTITY: indica quale con --csc NOME`, codice 2 | il blocco `NOME` |
   | nessuna CSC né entità, un solo blocco fra `BINDING` e `PROFILE` | quel blocco | il blocco `NOME` |
   | nessuna CSC né entità, più blocchi fra `BINDING` e `PROFILE` | `il file contiene N blocchi da ratificare: indica quale con --csc NOME`, codice 2 | il blocco `NOME` |
   | nessun blocco `NOME` | — | `nessun blocco da ratificare con il nome NOME nel file`, codice 1 |
   | nessuna CSC, entità, `BINDING` né `PROFILE` (solo `VERIFICATION`) | `il file non contiene nessun blocco da ratificare: una VERIFICATION non si ratifica`, codice 1 | come senza `--csc` |

   Con `--csc NOME` il blocco è, nell'ordine: la CSC, l'entità o il profilo `NOME`; altrimenti il `BINDING` con il
   nome proprio `NOME` (`AS NOME`); altrimenti l'unico `BINDING` senza nome proprio legato alla CSC `NOME`. Un
   `BINDING` senza nome proprio nello stesso file della sua CSC non si sceglie per nome, perché il nome è quello
   della CSC: si sceglie da solo quando il file non ha CSC né entità, oppure gli si dà un nome con `AS`. Il nome di
   una `VERIFICATION` non sceglie mai un blocco.

   Un file con una vista `REFINEMENT VIEW` ha E15 e si ferma al passo 4.

6. Il bersaglio. In una CSC: l'intestazione, la riga `ID` (che deve essere da approvare: una riga contrattuale o un
   dettaglio di `DEFINE` o di storia), oppure con `--all` l'insieme delle righe da cambiare, che non deve essere
   vuoto. In un `BINDING`: l'intestazione, oppure con `--all` l'intestazione e le righe `BIND` con un loro `STATUS`
   da approvare; con `ID` è un rifiuto. In un profilo: l'intestazione, con o senza `--all`; con `ID` è un rifiuto. **In un'entità**: senza `ID` né `--all` è un
   rifiuto; con `ID`, una promessa da approvare dell'entità; con `--all`, tutte le promesse da approvare
   dell'entità, che devono essere almeno una (i messaggi nella sezione 12.5).
7. **I confini letti**, solo se il blocco scelto è un'entità. Per ogni riga `OFFERS` e `USES` dell'entità,
   nell'ordine di riga, la ricerca del passo 4 deve averla **trovata**; se la riga dichiara `VERSION w`, il blocco
   trovato ha `VERSION w` (stesso testo); il file del blocco trovato ha **0 errori** (le sue righe non riconosciute
   non contano). La prima riga che non lo rispetta decide il messaggio (sezione 12.5), codice 1. Le parti non
   contano; un'entità senza `OFFERS` né `USES` passa. Per una CSC il passo non c'è: una CSC si approva anche se
   un'entità dello stesso file ha un confine mancante.
8. Composizione del testo nuovo (sezione 12.3) e suo controllo, con le stesse cartelle: nessun errore, nessuna riga
   non riconosciuta, il bersaglio approvato; con `--all`, l'intestazione e **tutte** le righe contrattuali della
   CSC approvate, o in un'entità tutte le sue promesse. Se no è un errore interno e il file non si tocca. È una
   difesa: non dovrebbe succedere mai.
9. Scrittura sicura: tutto o niente (sezione 12.6).

Una parte non trovata sospende E14 e non conta per il passo 7. Quindi senza `--dir` una promessa d'entità si
approva anche se, con la `--dir` dove la parte si trova, il file avrebbe un E14: chi approva indica le cartelle in
cui stanno le parti.

### 12.3 Che cosa cambia nel file

Cambia **il minimo**: senza `--all` cambia **una sola riga**, oppure se ne aggiunge **una sola**; ogni altro byte
resta identico, compresi il BOM e i fine riga. «D-nnn» è la decisione come è stata scritta nel comando.

Per l'intestazione si guarda lo `STATUS` riconosciuto della zona d'intestazione (sezione 4.2: il primo, dovunque
stia fra le righe d'intestazione). Nel caso c2 la riga si aggiunge subito dopo `CSC …`, anche se la zona ha righe
`IMPORT PROFILE`. Per una riga si guarda la prima riga della dichiarazione `GUARANTEE` o `ASSUME`, o del dettaglio
di `DEFINE` o di storia. In un dettaglio di `DEFINE` il caso r2 inserisce ` STATUS RATIFIED BY D-nnn` subito dopo il
nome breve che segue `DETAILS`, prima di `:=`; in un dettaglio di storia subito dopo il nome breve che segue `DETAILS`,
prima di `GIVEN` o di `EXPECT`. L'intestazione di un `BINDING` e di un profilo cambia con i casi c1 e c2; nel caso c2
il rientro è quello della prima dichiarazione dopo l'intestazione, e se quella è l'`END` del blocco, il rientro
dell'`END` seguito da due spazi. Una riga `BIND` con il suo `STATUS HYPOTHESIS` cambia con il caso r1; una riga
`BIND` senza `STATUS` segue l'intestazione e non si tocca.

| Caso | Bersaglio | Che cosa fa | Prima | Dopo |
|---|---|---|---|---|
| c1 | intestazione con `STATUS HYPOTHESIS` | la sola parola `HYPOTHESIS` diventa `RATIFIED BY D-nnn`; rientro, spazi, commento e fine riga restano | `  STATUS HYPOTHESIS` | `  STATUS RATIFIED BY D-135` |
| c2 | intestazione senza `STATUS` | si **aggiunge** una riga subito dopo `CSC …`: il rientro della prima riga di dichiarazione dopo l'intestazione (la prima che non è vuota né commento; c'è sempre, perché il file ha un `PURPOSE`), copiato byte per byte, poi `STATUS RATIFIED BY D-nnn`, poi il fine riga della riga `CSC …` (CR LF se quella finisce con CR LF, altrimenti LF) | `CSC LuceScale VERSION 0.1` / `  PURPOSE "…"` | `CSC LuceScale VERSION 0.1` / `  STATUS RATIFIED BY D-135` / `  PURPOSE "…"` |
| c3 | intestazione già `RATIFIED BY D-mmm` | **rifiuto**, codice 1 | | |
| r1 | riga con il suo `STATUS HYPOTHESIS` | la sola parola `HYPOTHESIS` diventa `RATIFIED BY D-nnn` | `  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL …` | `  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-135: VERBAL …` |
| r2 | riga senza `STATUS` | si inserisce ` STATUS RATIFIED BY D-nnn` (con uno spazio davanti) subito dopo l'ultimo carattere dell'ultimo elemento prima dei due punti (il nome breve, o il nome breve dopo `DETAILS`); gli spazi prima dei due punti restano dopo il testo inserito | `  GUARANTEE g2: VERBAL …`; `  GUARANTEE g3 : VERBAL …` | `  GUARANTEE g2 STATUS RATIFIED BY D-135: VERBAL …`; `  GUARANTEE g3 STATUS RATIFIED BY D-135 : VERBAL …` |
| r3 | riga già approvata, per un suo `STATUS RATIFIED BY` o perché eredita (sezione 7.1, punto 4) | **rifiuto**, codice 1 | | |

L'intestazione di una riga contrattuale sta sempre su una riga sola (regola U2), quindi `ratify` cambia sempre una
riga sola per ogni bersaglio. Una riga che dettaglia una riga da approvare si può approvare. Approvare
l'intestazione non cambia le righe che hanno un loro `STATUS HYPOTHESIS` né i dettagli senza `STATUS`: restano da
approvare, e il comando lo dice.

Un'interruzione con Ctrl-C prima della scrittura sicura chiude il comando senza toccare il file; durante la
scrittura è rimandata alla sua fine (sezione 12.6).

**Con `--all`**: dopo il comando l'intestazione e ogni `GUARANTEE` e `ASSUME` della CSC sono approvate, con il
minimo cambiamento:

| Che cosa | Se è da approvare | Se è già approvata |
|---|---|---|
| l'intestazione | caso c1 o c2 | non cambia, e conserva la sua decisione |
| una riga con il suo `STATUS HYPOTHESIS` | caso r1 | — |
| un dettaglio senza `STATUS` | caso r2 | — |
| una riga senza `STATUS` e senza `DETAILS` | — | eredita l'approvazione dell'intestazione: non cambia |
| una riga con il suo `STATUS RATIFIED BY D-mmm` | — | non cambia, e conserva la sua decisione |

Le altre CSC del file non cambiano, e le righe delle entità restano identiche byte per byte.

**Le promesse di un'entità** cambiano con i casi **r1** (con il loro `STATUS HYPOTHESIS`) e **r2** (senza `STATUS`,
base o dettaglio), una riga per promessa; con `--all` tutte le promesse da approvare dell'entità, e mai
l'intestazione. Le righe `VERIFY` non si riallineano. Esempio: in un'entità `Scale` con una promessa base senza
`STATUS` alla riga 5, un dettaglio con `STATUS HYPOTHESIS` alla riga 7 e un dettaglio già approvato alla riga 9,
`--all D-200` cambia la riga 5 (r2) e la riga 7 (r1); la riga 9 no. **Una sola scrittura, tutto o niente**: `bcdd`
compone tutto il testo nuovo in memoria, lo controlla una volta (passo 8 della sezione 12.2) e lo scrive con una
sola scrittura sicura (sezione 12.6); se la scrittura non riesce, o il comando si interrompe prima, il file è
com'era: non esiste un file con solo una parte delle righe approvate.

Esempio: su una luce delle scale con intestazione `HYPOTHESIS` e quattro righe base senza `STATUS`, `--all D-201`
cambia la sola riga 4; le quattro righe ereditano. Se la stessa CSC ha anche sei dettagli con `STATUS HYPOTHESIS`
(per esempio aggiunti da `refine`, che scrive sempre `STATUS HYPOTHESIS`), `--all` cambia anche quelli (caso r1):
dopo il comando l'intestazione e i sei dettagli hanno `STATUS RATIFIED BY`, le quattro righe base non hanno
`STATUS` ed ereditano. Per `check` sono tutte e dieci approvate.

### 12.4 Uscita quando riesce

Codice 0, niente sullo standard error. Sullo standard output, con i numeri di riga del file **dopo** la modifica.
Esempi su una luce delle scale (`D-200`, `D-201` e `D-202` sono riferimenti d'esempio):

```
$ bcdd ratify LuceScale.csc D-200
ratificata la CSC LuceScale (riga 3) con D-200
contratto: 4
ipotesi che restano: 0
```

`contratto` conta le `GUARANTEE` e le `ASSUME` della CSC che dopo la modifica sono approvate. Poi `ipotesi che
restano: K`, con `K` il numero di righe ancora da approvare, e se K non è 0 quelle righe, una per riga (`  riga N:
GUARANTEE id`), nell'ordine del file. Con righe che restano da approvare:

```
$ bcdd ratify R03_righe.csc D-130
ratificata la CSC Righe (riga 3) con D-130
contratto: 2
ipotesi che restano: 2
  riga 8: GUARANTEE g1a
  riga 11: ASSUME a1
```

```
$ bcdd ratify LuceScale.csc g2 D-200
ratificata la riga 12: GUARANTEE g2 con D-200
```

```
$ bcdd ratify LuceScale.csc --all D-201
ratificate con D-201 nella CSC LuceScale: 1 riga
  riga 4: CSC LuceScale
contratto: 4
```

In un'entità, con `ID`: `ratificata la riga N: GUARANTEE ID con D-nnn`. Con `--all`:

```
$ bcdd ratify Scale.csc --all D-200
ratificate con D-200 nella ENTITY Scale: 2 righe
  riga 5: GUARANTEE g1
  riga 7: GUARANTEE g1a
contratto: 3
```

`contratto` conta le promesse dell'entità, tutte approvate dopo il comando; nessuna riga dell'intestazione.

**`BINDING` e profili.** Per un `BINDING` le uscite sono quelle di una CSC, con `BINDING Nome VERSION v` (e ` AS b`)
al posto di `CSC NOME`: `ratificato il BINDING Luce VERSION 0.1 (riga 3) con D-200`, poi `contratto: K` con `K` le
righe `BIND` approvate dopo il comando, e `ipotesi che restano: K` con le righe `riga N: BIND elemento`. Per un
profilo: `ratificato il PROFILE Segnale VERSION 0.3 (riga 2) con D-200`, poi `estensioni: K`, con `K` le estensioni
del profilo, tutte approvate con lui. Le altre righe del file restano identiche byte per byte.

Con `--all` in un `BINDING` la forma è quella di `--all` in una CSC (qui sotto), con `nel BINDING Nome VERSION v[ AS
b]` al posto di `nella CSC NOME`: la prima riga conta le righe cambiate, poi `riga N: BINDING Nome VERSION v[ AS b]`
per l'intestazione (N è la riga di `STATUS`) e `riga N: BIND elemento` per ogni riga `BIND` con un suo `STATUS`
approvato dal comando, infine `contratto: K` con `K` le righe `BIND` del blocco. Per esempio:

```
$ bcdd ratify Luce.csc --csc filo --all D-200
ratificate con D-200 nel BINDING Luce VERSION 0.1 AS filo: 2 righe
  riga 10: BINDING Luce VERSION 0.1 AS filo
  riga 12: BIND accesa
contratto: 2
```

Con `--all` in una CSC: la prima riga conta le righe cambiate o aggiunte (`1 riga` al singolare, altrimenti `N
righe`); poi una riga per ognuna, nell'ordine del file, `riga N: CSC NOME` per l'intestazione (N è la riga di
`STATUS`, anche quando è stata aggiunta) e `riga N: TIPO ID` per una riga contrattuale (N è la sua prima riga);
poi `contratto: K`, con `K` le `GUARANTEE` e le `ASSUME` della CSC approvate dopo il comando. Di solito non resta
nessuna riga da approvare e la riga «ipotesi che restano» non si stampa. Restano da approvare solo le righe che usano
un'estensione di un profilo da approvare (sezione 7.1, punto 0a), che `--all` non può approvare: allora, dopo
`contratto`, si stampano `ipotesi che restano: K` e quelle righe, come senza `--all`. Per esempio:

```
$ bcdd ratify R03_righe.csc --all D-130
ratificate con D-130 nella CSC Righe: 3 righe
  riga 4: CSC Righe
  riga 8: GUARANTEE g1a
  riga 11: ASSUME a1
contratto: 4
```

```
$ bcdd ratify Luce.csc --csc Luce --all D-202
ratificate con D-202 nella CSC Luce: 1 riga
  riga 4: CSC Luce
contratto: 3
ipotesi che restano: 1
  riga 15: GUARANTEE g10
```

### 12.5 Errori e codici

Ogni messaggio va sullo standard error e finisce con LF; lo standard output resta vuoto; il file non
cambia. `ARG`, `ID`, `NOME`, `FILE` sono gli argomenti come sono stati scritti.

| Caso | Messaggio | Codice |
|---|---|---|
| posizionali non 2 né 3; `--csc` senza nome o ripetuto; `--all` ripetuto, o con 3 posizionali; `--dir` senza argomento, o con la stessa cartella due volte; un'altra opzione che comincia con `-`, anche `--dir=X` | `uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID \| --all] D-numero` | 2 |
| una cartella `--dir` che non c'è, non è una cartella, non si legge | come in `check` (sezione 10), con il prefisso `bcdd ratify:` | 2 |
| l'ultimo posizionale non è una decisione | `bcdd ratify: decisione non valida: ARG (serve D-numero)` | 2 |
| l'ID non è una parola della regola L8 | `bcdd ratify: id non valido: ARG` | 2 |
| il nome dopo `--csc` non è un Nome | `bcdd ratify: nome non valido: ARG` | 2 |
| file non trovato, non è un file, non leggibile, non UTF-8 | come in `check`, con il prefisso `bcdd ratify:` | 2 |
| il file non passa `bcdd check --strict` | `bcdd ratify: il file non passa bcdd check --strict (errori: E, righe non riconosciute: U): non ratifico` | 1 |
| nessun blocco da ratificare (solo `VERIFICATION`) | `bcdd ratify: il file non contiene nessun blocco da ratificare: una VERIFICATION non si ratifica` | 1 |
| nessuna CSC né entità e più blocchi fra `BINDING` e `PROFILE`, nessun `--csc` | `bcdd ratify: il file contiene N blocchi da ratificare: indica quale con --csc NOME` | 2 |
| un `BINDING` o un profilo con `ID` | `bcdd ratify: nel BINDING si ratificano l'intestazione o --all, non una riga` (oppure `nel PROFILE si ratifica il profilo intero, non una riga`) | 1 |
| il `BINDING` o il profilo è già approvato | `bcdd ratify: il BINDING NOME VERSION v è già ratificato (D-mmm): non cambio nulla` (oppure `il PROFILE NOME VERSION v`) | 1 |
| nessuna CSC e più entità, nessun `--csc` | `bcdd ratify: il file contiene N ENTITY: indica quale con --csc NOME` | 2 |
| più CSC e nessun `--csc` (`N` conta solo le CSC) | `bcdd ratify: il file contiene N CSC: indica quale con --csc NOME` | 2 |
| `--csc NOME` e nessun blocco da ratificare con quel nome | `bcdd ratify: nessun blocco da ratificare con il nome NOME nel file` | 1 |
| entità, senza `ID` né `--all` | `bcdd ratify: l'intestazione della ENTITY NOME non si ratifica: indica una GUARANTEE oppure --all` | 1 |
| entità, `ID` che non è un nome dell'entità | `bcdd ratify: nessuna GUARANTEE con id ID nella ENTITY NOME` | 1 |
| entità, `ID` nome di una parte | `bcdd ratify: ID non è una GUARANTEE: in una ENTITY si ratificano solo garanzie` | 1 |
| entità, `--all` e nessuna promessa da approvare | `bcdd ratify: la ENTITY NOME non ha garanzie ancora ipotesi: non cambio nulla` | 1 |
| entità, un confine non trovato (passo 7) | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE non trovata: non ratifico le sue garanzie`; con un motivo della ricerca (sezione 9.4): `… non trovata (MOTIVO): …` | 1 |
| entità, un confine di un'altra versione | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE trovata in PERCORSO alla riga M con VERSION v: non ratifico le sue garanzie` | 1 |
| entità, un confine in un file con errori | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE trovata in PERCORSO alla riga M, che ha E errori: non ratifico le sue garanzie` (`1 errore`) | 1 |
| la CSC è già approvata (caso c3) | `bcdd ratify: la CSC NOME è già ratificata (D-mmm): non cambio nulla` | 1 |
| con `--all`: l'intestazione e tutte le righe sono già approvate | `bcdd ratify: la CSC NOME è già tutta contratto: non cambio nulla` | 1 |
| `ID` non è un nome della CSC | `bcdd ratify: nessuna GUARANTEE né ASSUME con id ID nella CSC NOME` | 1 |
| `ID` è un nome della CSC ma non di una riga contrattuale né di un dettaglio di `DEFINE` o di storia | `bcdd ratify: ID non è una GUARANTEE né una ASSUME: si ratificano solo righe contrattuali e dettagli` | 1 |
| la riga è già approvata (caso r3; in un'entità, una promessa con il suo `STATUS RATIFIED BY`) | `bcdd ratify: ID è già contratto (riga N): non cambio nulla` | 1 |
| controllo del testo nuovo fallito | `bcdd ratify: errore interno: il testo modificato non passa check; file non toccato` | 1 |
| errori della scrittura sicura | sezione 12.6 | 1 |

Nei messaggi dei confini `CITAZIONE` è la riga com'è (`OFFERS X`, `USES X VERSION w`); `PERCORSO` come nelle
righe delle citazioni (sezione 9.4), e nello stesso file `in questo file alla riga M`. Nei messaggi «garanzia»
indica una promessa e «ipotesi» una riga da approvare.

Il codice 2 vuol dire «il comando non si è potuto eseguire così come è scritto»; il codice 1 «il comando
è chiaro, ma il file non lo permette». È la stessa divisione di `bcdd new`.

### 12.6 La scrittura sicura

`bcdd ratify` scrive il file in modo che non resti mai scritto a metà, e che niente cambi oltre ciò che il comando
dichiara:

1. il contenuto nuovo si scrive in un **file temporaneo nella stessa cartella** del file, con un nome che comincia
   con `.` e finisce con `.tmp` seguito da un numero; poi lo si forza sul disco;
2. il file temporaneo prende gli stessi permessi del file originale;
3. **subito prima di sostituire**, `bcdd` rilegge il file originale: se i suoi byte non sono più quelli letti
   all'inizio del comando, **non sostituisce** (per esempio perché la persona ha salvato il file dal suo editor nel
   frattempo);
4. il file temporaneo prende il posto del file originale con una sola operazione del sistema, che o riesce o
   lascia il file com'era;
5. in ogni caso di errore il file temporaneo si cancella: nella cartella non resta nulla.

Da quando crea il file temporaneo fino alla sostituzione, il comando **rimanda** Ctrl-C: finisce la scrittura e poi
esce normalmente. Se `FILE` è un **collegamento simbolico**, si scrive il file a cui punta e il collegamento resta;
se il file ha **più nomi** (collegamenti fisici), il comando rifiuta, perché sostituirlo staccherebbe gli altri
nomi, che resterebbero con il contenuto vecchio.

I messaggi, sullo standard error, con codice 1; il file resta com'era. `FILE` è il nome del file come è stato
scritto, `CAUSA` la descrizione dell'errore data dal sistema, come in `bcdd new`:

| Caso | Messaggio |
|---|---|
| il file temporaneo non si crea o non si scrive (cartella non scrivibile, disco pieno) | `bcdd ratify: non riesco a scrivere FILE: CAUSA` |
| il file è cambiato dopo la lettura (punto 3) | `bcdd ratify: FILE è cambiato durante il comando: niente scritto` |
| il file ha più collegamenti fisici | `bcdd ratify: FILE ha più collegamenti fisici: non lo riscrivo` |

---

## 13. Il file del dialogo

Il file `FILE.dialogo` sta accanto al file CSC. Lo scrive solo `bcdd refine`, che vi conserva le domande del modello
linguistico e le risposte della persona, e lo invia al modello nei giri successivi; `check` e `ratify` non lo
leggono, e non è un file CSC. Esempio, per la luce delle scale (le prime righe di un file con due giri):

```
-- bcdd refine: domande dell'LLM e risposte della persona. Si può modificare o cancellare a mano.

GIRO 2026-10-17T12:17:35+02:00 CSC LuceScale
DOMANDA Per g2: quanto tempo resta accesa la luce dopo l'ultima pressione, e con quale tolleranza?
RISPOSTA 1 minuto, con 5 s di tolleranza
DOMANDA Per g3: che cosa succede se qualcuno preme il pulsante mentre la luce è già accesa?
RISPOSTA il tempo di accensione riparte da capo
```

| Riga | Che cosa dice |
|---|---|
| la prima, un commento | c'è dalla creazione del file, e non cambia |
| `GIRO DATA CSC NOME` | l'inizio di un giro, dopo una riga vuota; per un'entità `GIRO DATA ENTITY NOME`. `DATA` è data e ora locali al secondo, con il fuso, nella forma `AAAA-MM-GGTHH:MM:SS+HH:MM` (o `-HH:MM`): quella d'inizio della prima chiamata al modello del giro. Un giro ha una riga `GIRO` sola |
| `DOMANDA testo` | una domanda a cui la persona ha risposto; le righe successive di una domanda lunga sono rientrate di due spazi |
| `RISPOSTA testo` | la risposta; per una scelta, il testo della scelta e non il numero |
| `CSC A PARTE NOME: MOTIVO` | dopo le coppie `DOMANDA`/`RISPOSTA` del giro: un argomento nuovo che il modello ha segnalato e la persona ha visto, una riga per ciascuno, nell'ordine in cui è stato mostrato |

Un giro si scrive se ha almeno una risposta o almeno una `CSC A PARTE`. Le domande saltate, le proposte e le
sostituzioni non ci vanno: le proposte accettate e le sostituzioni sono nel file CSC. Se il file esistente non
finisce con LF, se ne aggiunge uno prima del giro nuovo; il resto del contenuto resta identico, byte per byte, e la
scrittura è quella sicura della sezione 12.6. Il file è testo UTF-8 con fine riga LF; la persona lo può correggere o
cancellare (si ricomincia senza memoria).

---

## 14. Che cosa bcdd non controlla

L'elenco dice esplicitamente che cosa `bcdd` non controlla, perché nessuno lo creda controllato:
- **il significato delle formule**: `check` legge le formule e ne controlla forma, nomi e tipi, ma non le valuta.
  Non controlla che una storia abbia l'esito che dichiara, che ogni innesco avvenga in una storia, che le promesse e
  i presupposti possano valere insieme, né che un dettaglio formale sia coerente con la riga che dettaglia: sono i
  controlli «non eseguiti» della sezione 15 del rapporto. Non scrive la forma estesa delle abbreviazioni e non
  controlla che la `REDUCES TO` di un'estensione abbia tipi coerenti. E36 riconosce solo una riduzione che è un
  costrutto solo con i parametri come operandi: una riduzione equivalente scritta in un altro modo (`NOT NOT c`,
  `p AND p`, `x * 1`) non è segnalata, e neppure due estensioni dello stesso profilo con la stessa riduzione a parte i
  nomi dei parametri;
- **le forme uscite dal linguaggio o riservate**: `FACE`, `LINK`, `MAP`, `REFINED BY`, `REFINES` sono righe non
  riconosciute;
- **le regole a giudizio**: che un dettaglio a parole sia coerente con la riga che dettaglia, che il significato di
  un'estensione non descriva la realizzazione, che un'estensione senza riduzione non ripeta una forma del linguaggio,
  che `MEANING` e `REDUCES TO` dicano la stessa cosa: sono voci della sezione 14 del rapporto;
- **le registrazioni**: `check` non legge tracce registrate su un sistema costruito; la copertura della sezione 13
  dice quali promesse un mezzo osserva, non che siano rispettate;
- **i valori delle costanti**: `DEFINE ATTESA_MAX_LLM := 120 s` è riconosciuta, ma non si confronta con
  niente; un nome di costante dentro una stringa è testo (sezione 4.3);
- **le versioni**: se una VERSION è nuova, che cosa è cambiato rispetto alla versione approvata prima, e se una riga
  con un suo `STATUS RATIFIED BY` ha cambiato testo dopo l'approvazione (sezione 7.2);
- **i livelli dei dettagli**: nessun limite e nessun avviso (sezione 7.3);
- **i tipi non noti**: un valore di un tipo non dichiarato, di un tipo descritto a parole, di una costante
  `UNDECIDED` o di un nome dato da un'estensione non si controlla (sezione 4.13); in una storia d'entità un valore
  che è un nome, e un elemento di una CSC citata il cui tipo non è di base, non si controllano (sezione 4.6); in una
  formula d'entità nessun elemento `X.y` ha un tipo noto, quindi su quelle formule non c'è mai E25 (sezione 4.9); i
  limiti di un intervallo non si propagano nelle espressioni;
- **gli usi di due tipi di estensione**: in questa versione `bcdd` non legge gli usi delle estensioni di `KIND
  RELATION` e `KIND SCENARIO-FORM`: le righe che li contengono sono non riconosciute (sezione 4.14);
- **i limiti degli intervalli**, anche negativi: `Real [20.0 .. -20.0]` è riconosciuta, i limiti non si confrontano
  fra loro;
- **le unità**: solo `s` e `ms`; un'unità di misura diversa (`90 dB`) rende la riga non riconosciuta, e chi scrive
  la mette nel nome della costante e nel testo delle promesse;
- **le copie**: la molteplicità di una parte dice quante copie, non quando nascono e terminano, né come si
  distinguono; le copie di una stessa parte non si servono fra loro;
- **il ciclo di vita delle richieste**: `requested` di una richiesta `AUTONOMOUS`, o `completed` prima di
  `accepted`, non sono segnalati;
- **il contenuto delle stringhe**: un `PURPOSE "da compilare…"` lasciato com'è non è segnalato;
- **le altre CSC, oltre la ricerca**. `check` cerca le CSC e le entità che le entità del file citano e ne riferisce
  versione, stato ed esito (sezione 9.4), ma:
  - una profondità sola: di una parte non si leggono le parti, né le CSC che cita; le parti delle parti, la
    composizione circolare oltre una profondità e le parti con indice (`ago[ch] : Strumento`) non ci sono;
  - di una CSC citata si leggono le dichiarazioni solo per i nomi qualificati delle storie d'entità, non i valori
    dei suoi elenchi di valori;
  - un blocco ritirato (`REFINEMENT VIEW`) non ha parti né citazioni;
  - non controlla che le CSC che un'entità offre siano rette da qualche parte (un'entità può offrire una CSC che
    nessuna parte offre da sola: è un giudizio);
  - non controlla che una promessa d'entità si regga su quelle delle parti, né che chi usa una CSC ne rispetti i
    presupposti: sono giudizi;
  - non sa se la CSC trovata è quella giusta: la trova per nome, e per versione se la citazione la dice;
    una CSC con lo stesso nome in un'altra cartella di `--dir` resta non vista se una prima è già trovata;
  - non legge il file `.dialogo`, né i tipi descritti in un altro file; due `BINDING` per la stessa CSC in file
    diversi non si confrontano (E40 vale nel file controllato);
  - un'entità non dice dove si trova (apparecchio, processo, macchina) e nessuna riga dice chi viene prima fra più
    entità sullo stesso lato di un confine: è una scelta del linguaggio, non un limite di `bcdd`;
- **il significato**: se una promessa a parole è sensata, coerente con le altre o verificabile lo dice
  chi giudica, non `bcdd`.
