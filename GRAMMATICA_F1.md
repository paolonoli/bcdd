# La grammatica del BCDD, versione 1.0-beta

<!-- SPDX-License-Identifier: CC-BY-4.0 -->
*Copyright 2026 Noli Paolo. Documento distribuito con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it).*

**BCDD** = *Behavioural Contract-Driven Design* · **CSC** = *Capability State Contract*

**Stato**: versione 1.0-beta. Il documento descrive la sintassi dei file `.csc` letti dal programma `bcdd`, gli
errori segnalati, il rapporto di `bcdd check` e l'uso dei comandi `check`, `new` e `ratify`.

## Contenuto del documento

Il documento definisce la sintassi delle CSC accettata da `bcdd`. Ciò che `bcdd` accetta, rifiuta e riporta nel
rapporto è esattamente ciò che è scritto qui. Il documento non descrive la realizzazione del programma.

Le sezioni 1-7 definiscono ciò che `bcdd` riconosce, e in particolare:
- la sezione 4.9: le entità;
- la sezione 4.10: le varianti e le parti facoltative;
- la sezione 4.11: le forme concrete, il piano di prova, i profili e le estensioni;
- la sezione 4.12: le formule;
- la sezione 4.13: i nomi e i tipi;
- la sezione 4.14: l'uso delle estensioni.

La sezione 8 elenca gli errori. La sezione 9 descrive il rapporto di `bcdd check` con il testo esatto, voce per
voce:
- la sezione 9.4: le entità e le citazioni;
- la sezione 9.5: le composizioni;
- la sezione 9.6: le forme concrete e il piano di prova;
- la sezione 9.7: le voci da giudicare e i controlli non eseguiti.

Le sezioni 10, 11 e 12 descrivono i comandi `check`, `new` e `ratify`. La sezione 13 descrive il file del dialogo
di `refine`. La sezione 14 elenca ciò che `bcdd` non controlla.

Il linguaggio, con i suoi esempi, è presentato nel *Manuale del BCDD*. Questo documento ne usa i termini; il
glossario è l'appendice C del manuale. `bcdd` riconosce tutte le forme del linguaggio descritte nel manuale: le
formule, le abbreviazioni, le forme concrete, il piano di prova, i profili e le estensioni. Ne controlla la
sintassi, i nomi e i tipi. Non valuta le formule sulle storie e non confronta le formule fra loro (sezioni 9.7 e
14).

**I termini.** I nomi dei concetti sono quelli del manuale:

| Termine | Parola chiave o costrutto |
|---|---|
| promessa | `GUARANTEE` |
| presupposto | `ASSUME` |
| richiesta | `CAPABILITY` |
| storia | `SCENARIO` |
| elenco di valori | un tipo `TYPE … := { … }` |
| costante con nome | `DEFINE` |
| numero non deciso | `UNDECIDED` |
| nome breve | il nome di una promessa, di un presupposto o di una storia |
| da approvare | `STATUS HYPOTHESIS` |
| approvata | `STATUS RATIFIED BY` |
| elenco delle parti | `COMPOSED OF` |
| copia | una delle copie di una parte |
| gruppo, nome del gruppo | le righe `VARIANT` con lo stesso nome a sinistra di `=`; quel nome |

Per *contratto* si intende l'insieme delle promesse e dei presupposti approvati su un confine. Il rapporto e i
messaggi di `bcdd` usano gli stessi termini, con tre differenze, riportate come il programma le stampa:
«contratto» indica anche una singola riga approvata; «connettore» indica una CSC citata da un'entità; «gruppo di
scelte» indica un gruppo. Il comando che approva si chiama `ratify`.

Per i costrutti dei capitoli 21-27 del manuale valgono i termini seguenti, gli stessi del manuale: *formula*,
*condizione sul passo*, *innesco*, *conseguenza*, *ambito*, *abbreviazione*, *forma estesa*, *forma concreta*
(`BINDING`), *piano di prova* (`VERIFICATION`), *mezzo di registrazione* (`MEANS`), *risoluzione*, *profilo*,
*estensione*, *estensione dichiarata*. I nomi dei controlli (C1…C8), delle regole sulle estensioni (E1…E7) e
delle regole sui dettagli (D1…D6) sono quelli della specifica del linguaggio. Qui servono a indicare che cosa
`bcdd` esegue; nel rapporto sono descritti a parole.

Le uscite di `bcdd` riportate in questo documento sono quelle del programma in italiano, ottenute con
`bcdd --lang it …` oppure con la variabile d'ambiente `BCDD_LANG=it`. Senza queste impostazioni `bcdd` produce
i messaggi in inglese (sezione 10). Le stesse uscite in inglese sono in `GRAMMATICA_F1.en.md`.

**Dichiarazione.** In questo documento *dichiarazione* indica ogni unità del file che comincia all'inizio di una
riga e prosegue fino alla dichiarazione successiva (sezione 3). Di norma comincia con una parola chiave. Sono
dichiarazioni, per esempio, una promessa, un presupposto, una storia, un passo, l'intestazione di un blocco, una
riga `OFFERS`. Il manuale usa la parola in un senso più ristretto: le sole righe che dichiarano un elemento della
CSC (`TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `SCENARIO`).

---

## 0. In breve

- Un file `.csc` è testo UTF-8, diviso in righe.
- Il file contiene blocchi `CSC … END` ed `ENTITY … END`. Un blocco `REFINEMENT VIEW … END` è una forma
  ritirata: `bcdd` segnala E15 e le sue righe non sono riconosciute (sezione 4.8).
- Una CSC descrive un confine. Un'entità dichiara quali CSC offre (`OFFERS`), quali usa (`USES`) e di quali
  altre entità è composta, e in quante copie. Non indica mai dove è collocata (sezione 4.9).
- Un'entità ha storie, che nominano gli elementi delle sue CSC con i nomi qualificati `Csc.nome` (sezione 4.6).
- Un'entità può contenere segmenti `VARIANT gruppo = scelta` e parti facoltative `[0 .. n]`. L'entità ha allora
  più **composizioni**, una per ogni combinazione di scelte e di parti facoltative, e `check` le controlla tutte
  (sezione 4.10).
- Il file può contenere anche le forme concrete di un confine (`BINDING … END`), il piano di prova
  (`VERIFICATION … END`) e i profili (`PROFILE … END`), che contengono le estensioni (`EXTENSION … END`). `bcdd`
  li legge e ne controlla i nomi rispetto a quelli della CSC a cui sono legati (sezione 4.11).
- Dentro un blocco ogni dichiarazione comincia **a inizio riga** con una parola chiave in inglese, scritta in
  lettere maiuscole: `PURPOSE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`, `ASSUME`, `SCENARIO`, …
  Una dichiarazione ancora aperta continua sulla riga successiva, per esempio perché ha una parentesi non chiusa o
  perché termina con `AND` (sezione 3).
- `bcdd` riconosce le promesse scritte **a parole** (`VERBAL`) e quelle scritte **come formule** (`WHENEVER …
  THEN …`, `ALWAYS …`, le abbreviazioni e le estensioni dei profili importati). Di una formula controlla la
  sintassi, i nomi e i tipi (sezioni 4.12-4.14), ma non la valuta sulle storie. Il grado di ogni promessa
  (verbale, formale, estensione dichiarata) si ricava dalla sua forma (sezione 6).
- Ogni riga del file ricade in una sola di queste categorie: riconosciuta, commento, vuota, non riconosciuta.
  Nessuna riga è ignorata e ogni riga non riconosciuta è segnalata.
- Una riga non riconosciuta **non è un errore**. Gli errori definiti sono quaranta (E01 … E40), elencati nella
  sezione 8.
- Alcune valutazioni spettano solo a una persona: per esempio, se un dettaglio a parole è coerente con la promessa
  che dettaglia. Il rapporto le elenca nella sezione «da giudicare». I controlli che `bcdd` non esegue sulle
  formule sono dichiarati «non eseguiti» (sezione 9.7). Le voci da giudicare e i controlli non eseguiti non sono
  errori.
- `check` cerca le CSC e le entità citate dalle entità del file, i profili importati e la CSC a cui è legato un
  `BINDING` o una `VERIFICATION`. Cerca nello stesso file, nella sua cartella e nelle cartelle indicate con
  `--dir`. Il rapporto riporta dove li ha trovati. Una citazione mancante, o un file citato con errori, non cambia
  l'esito.
- Dentro un'entità composta di parti, una parte può usare una CSC che nessun'altra parte offre e che l'entità non
  usa da fuori: `bcdd` segnala E14 (sezione 9.4).
- Una promessa o un presupposto deve indicare come si verifica: per `VERBAL "…"` senza `VERIFY` `bcdd` segnala
  E13.
- Con l'opzione `--strict` (sezione 10) basta una riga non riconosciuta perché `bcdd check` termini con codice
  d'uscita 3. Senza l'opzione una riga non riconosciuta non cambia il codice d'uscita; la riga `esito` del rapporto
  la conta comunque (sezione 9.2).
- Ogni `GUARANTEE` e `ASSUME`, ogni dettaglio di `DEFINE` o di `SCENARIO`, ogni riga `BIND` e ogni profilo ha
  lo stato **approvato** o **da approvare** (sezione 7.1). Solo `bcdd ratify` approva, e solo in un file che
  `check --strict` accetta (sezione 12). Un piano di prova non si approva mai.
- `check` accetta `DETAILS` a qualunque profondità; `refine`, invece, si ferma al secondo livello (sezione 7.3).

---

## 1. Il file

| Che cosa | Regola |
|---|---|
| Estensione | `.csc`. `bcdd new` crea sempre un file `.csc`; `bcdd check` legge un file di qualunque nome |
| Codifica | UTF-8. Una sequenza di byte non valida in UTF-8 interrompe il controllo (sezione 10) |
| Marcatore BOM | i tre byte `EF BB BF` all'inizio del file, se presenti, sono ignorati |
| Fine riga | il carattere LF. Un carattere CR subito prima di LF è ignorato (file creati su Windows) |
| Righe | la numerazione parte da 1. L'ultima riga conta anche se non termina con LF. Un file vuoto ha 0 righe |
| Spazi | sono spazi soltanto lo spazio (U+0020) e il tabulatore. Ogni altro carattere invisibile (per esempio lo spazio unificatore U+00A0) è un carattere estraneo |

---

## 2. Le parole del file

Il testo è scomposto in **elementi** lessicali. Gli spazi separano gli elementi e non hanno altro effetto:
l'allineamento in colonne è libero.

### 2.1 Notazione delle regole

Le regole sono scritte nella notazione EBNF (*Extended Backus-Naur Form*), con i simboli seguenti:

| Scrittura | Significato |
|---|---|
| `A = B C ;` | A è formato da B seguito da C |
| `"CSC"` | il testo da scrivere esattamente come indicato, rispettando maiuscole e minuscole |
| `[ x ]` | x è facoltativo |
| `{ x }` | x ripetuto zero o più volte |
| `x \| y` | x oppure y |
| `( … )` | raggruppamento |

### 2.2 Regole delle parole

| N. | Regola | Esempio |
|---|---|---|
| L1 | **Commento**: da `--` alla fine della riga, se `--` non è dentro una stringa. Il commento è ignorato nella lettura delle dichiarazioni | `EVENT IN arrivo   -- dal pulsante` |
| L2 | **Stringa**: da `"` al `"` successivo. Può estendersi su più righe. Non esistono sequenze di escape: una stringa non può quindi contenere `"`. Dentro una stringa non si riconoscono né parole chiave né commenti | `"Una pressione accende la luce"` |
| L3 | **Parola**: comincia con una lettera di qualunque alfabeto, comprese quelle accentate, o con `_`. Continua con lettere, segni diacritici, cifre da 0 a 9, `_` e `-`, purché ogni `-` sia compreso fra due degli altri caratteri | `intensità`, `g-n1`, `ATTESA_MAX_LLM` |
| L4 | **Numero puntato**: un `-` facoltativo, immediatamente prima della prima cifra, senza spazi; poi cifre da 0 a 9, eventualmente divise da punti, ciascun punto fra due cifre. Il `-` fa parte del numero solo a due condizioni. Il carattere che lo precede non è una lettera, un segno diacritico, una cifra o `_` (altrimenti vale L3: `g-1` resta una parola). Il `-` non è l'inizio di `--` (commento, L1) | `180`, `0.5`, `0.1.2`, `-20.0`, `-40` |
| L5 | **Simboli**: `:=` `..` `(` `)` `,` `:` `=` `[` `]` `@` `.` `{` `}`, e gli operatori delle formule `<` `<=` `>` `>=` `<>` `+` `-` `*` `/` `^` `->` `;`. Si riconosce sempre il simbolo più lungo possibile: `:=`, `..`, `<=`, `>=`, `<>` e `->` sono ciascuno un unico simbolo. `.` è un simbolo a sé soltanto quando non è seguito da un altro `.` e non è dentro un numero puntato (L4). Il `-` è il segno meno solo se non è l'inizio di un commento (L1), non sta dentro una parola (L3), non appartiene a un numero (L4) e non è l'inizio di `->` | `DEFINE D := 3`, `Sessione.pronta`, `{L, R}`, `a - b`, `x <= 1.0` |
| L6 | **Carattere estraneo**: ogni altro carattere all'esterno di stringhe e commenti (per esempio `→`, `±`, `≤`, `$`, `%`). Non è un errore: rende non riconosciuta la dichiarazione che lo contiene | `±`, `→` |

**Esempi di lettura.**
- `g-1` è una parola (L3).
- `--20` è un commento (L1).
- In `x=-3` dopo `=` c'è il numero `-3`, perché `=` non è una lettera.
- `- 3` è il segno meno seguito dal numero `3`.
- `a - b` è la parola `a`, il segno meno e la parola `b`; `a-b` è invece un'unica parola (L3).
- `a -3` è la parola `a` seguita dal numero `-3`, senza simboli fra i due.
- `5-3` è il numero `5`, il segno meno e il numero `3`: il `-` dopo una cifra non appartiene al numero (L4).
- `-x` è il segno meno seguito dalla parola `x`.
- `A->B` è formato da `A`, `->` e `B`.
- `0.5` è un numero.
- `a.b` è formato da tre elementi (`a`, `.`, `b`). `Sessione . pronta` è formato dagli stessi tre elementi di
  `Sessione.pronta`, perché gli spazi non hanno effetto.
- `x.5` è formato da tre elementi (`x`, `.`, `5`) che nessuna regola accetta.

Per evitare ambiguità, il segno meno fra due valori si scrive separato da spazi su entrambi i lati: `a - b`,
`x - 3`.

Il confronto fra lettere non applica la normalizzazione Unicode: `città` con la «à» precomposta e `città` con «a»
seguita dall'accento combinante sono due nomi diversi. Il confronto distingue maiuscole e minuscole: `Check` e
`check` sono nomi diversi, e `guarantee` non è la parola chiave `GUARANTEE`.

### 2.3 Parole chiave e parole riservate

Le **parole chiave** sono in inglese. Sono le parole a cui `bcdd` attribuisce un significato proprio. Qui sono
raggruppate per uso:

- le parole della CSC, dell'entità, dei blocchi e dell'intestazione:

```
CSC VERSION END STATUS HYPOTHESIS RATIFIED BY PURPOSE CAPABILITY AUTONOMOUS
EVENT IN OUT STATE INITIAL DEFINE UNDECIDED GUARANTEE ASSUME DETAILS VERBAL VERIFY
JUDGEMENT INSPECTION SCENARIO GIVEN EXPECT ADMITTED REJECTED COMPOSED OF
TYPE ENTITY OFFERS USES VARIANT
IMPORT PROFILE BINDING VERIFICATION EXTENSION
```

- le parole delle formule e delle storie (sezioni 4.6 e 4.12), con il tipo `Record` (sezione 4.4):

```
WHILE ALWAYS EVENTUALLY WHENEVER THEN WITHIN AT ONCE REPEAT FOREVER EVERY
AND OR NOT IMPLIES IF ELSE COUNT LAST TIME SINCE PREV WITH ABSENT PRESENT Record
```

- le parole delle abbreviazioni e le funzioni matematiche (sezione 4.12):

```
NEVER AFTER BEFORE BETWEEN UNTIL PRECEDES FOR LEAST ACCEPTS ONLY REQUIRES ENSURES RESOLVES
CHANGED TRANSITION ON WHEN FOLLOWS ALL
ABS MIN MAX LOG10 ROUND FLOOR CEIL
```

- i campi di un'estensione, i valori del campo `KIND` e le categorie dei parametri (sezione 4.11):

```
KIND LEVEL PARAMS FORM MEANING REDUCES TO SOURCE
PATTERN SCOPE FUNCTION DECLARATION RELATION SCENARIO-FORM
Name Type Event Condition Expression Duration Property
```

- le parole delle forme concrete e del piano di prova (sezione 4.11):

```
BIND AS MEANS OBSERVES RESOLUTION USING TRANSLATES
```

I valori del campo `LEVEL` (`CSC`, `ENTITY`, `BINDING`, `VERIFICATION`) sono già parole chiave. `Duration` è
anche il nome di un tipo di base (sezione 4.4) e, nel campo `PARAMS`, la categoria con lo stesso significato.
`SCENARIO-FORM` è un'unica parola (L3) che contiene `-`: non potrebbe comunque essere un Nome (L7). La riserva
esclude anche il nome breve `SCENARIO-FORM` (L8).

Sono **riservate** le parole di due forme previste per sviluppi futuri del linguaggio; `bcdd` non le riconosce in
nessuna dichiarazione. Sono `REFINED BY`, che indicherà su quali promesse delle parti si fonda una promessa
d'entità, e `REFINES`, la relazione fra due versioni di una CSC:

```
REFINED REFINES
```

Sono **riservate perché ritirate dal linguaggio**:

```
FACE LINK MAP REFINEMENT VIEW
```

Sono inoltre riservate, in minuscolo, `true false requested accepted rejected completed failed _`.

In totale le parole chiave e le parole riservate sono **136**.

Una parola chiave o riservata non può essere un nome. Una riga che la usa come nome non è riconosciuta. Fanno
eccezione le dichiarazioni che cominciano con `REFINEMENT`: per queste `bcdd` segnala E15 (sezione 4.8).

**Una sola lista.** Le parole chiave e le parole riservate di questa sezione sono le stesse per `check`, `new`
(regola L7, sezione 11), `ratify` (nome breve e nome dopo `--csc`, sezione 12.5) e `refine` (nomi e nomi brevi
delle proposte). Nessun comando ha un elenco proprio.

**Parole non riservate e motivo:**
- `V1`, `V2` e `C1` … `C8` sono riconosciute soltanto nel campo `VERIFY` di un'estensione (sezione 4.11), dove
  la loro posizione basta a riconoscerle. Altrove sono nomi validi (`STATE C1 : Boolean INITIAL false` è
  riconosciuta).
- I nomi delle estensioni dei profili (`SIGNAL`, `CONTINUOUS`, `STABILIZES`, `GRACE`, …): un profilo non
  importato non aggiunge parole. In un blocco che lo importa il nome di un'estensione si riconosce dalla sua
  posizione (sezione 4.14).
- Le unità di tempo (`ms`, `s`) e le parole `Boolean`, `String`, `Integer`, `Real`, `Sequence`, `of`,
  `Optional`. Nella posizione di un tipo hanno il significato della sezione 4.4. Non sono ammesse come nome di un
  tipo dichiarato (G15, G30, G37, G41).

**Motivo della riserva delle parole riconosciute in un solo punto.** Una richiesta chiamata `ENSURES` o uno stato
chiamato `LEVEL` darebbero alla stessa parola due significati nello stesso file. Le forme in minuscolo restano
libere (sezione 2.2): `pattern` e `level` sono nomi validi.

**Motivo della riserva di `FACE`, `LINK`, `MAP`, `REFINEMENT` e `VIEW`.** Sono forme ritirate dal linguaggio,
sostituite dalle CSC e dalle entità. Restano riservate per evitare confusione. Chi conosce le forme ritirate
interpreterebbe la parola con il vecchio significato: un nome `MAP` in una CSC sembrerebbe la relazione `MAP`
ritirata. Una parola ritirata resta riservata in modo permanente. Liberarla non darebbe alcun vantaggio; riservarla
di nuovo, in seguito, invaliderebbe le CSC che la usano come nome.

### 2.4 I nomi

| N. | Regola | Esempio valido | Esempio non valido |
|---|---|---|---|
| L7 | **Nome** = una parola senza `-`, che non sia riservata | `pressione`, `Città`, `ATTESA_MAX_LLM` | `g-n1` (ha `-`), `END` |
| L8 | **Id** (il nome breve di promesse, presupposti e storie) = una parola che non sia riservata; può contenere `-` | `g-n1`, `f-1`, `g1a` | `g-` (termina con `-`) |
| L9 | **Decisione** (il riferimento della decisione) = una parola formata da `D-` seguito da sole cifre | `D-125` | `D125`, `operatore`, `D-12a` |
| L10 | **Versione** = un numero puntato senza `-` | `0.1`, `1`, `0.1.2` | `v1`, `-0.1` |
| L11 | **Numero** = un numero puntato con al più un punto, senza `-` | `180`, `0.5` | `0.1.2`, `-3` |
| L12 | **Numero con segno** = un numero puntato con al più un punto, con o senza `-` | `-20.0`, `3`, `0.5` | `-0.1.2` |
| L13 | **Intero** = un numero puntato senza punti e senza `-` | `1`, `4` | `1.5`, `-1` |

Il segno `-` è ammesso soltanto dove una regola lo prevede. Solo L12 lo ammette: negli estremi di un intervallo
(G14), nei valori (G26) e nelle formule (G59). Nelle formule il segno meno davanti a un valore può anche essere
separato da uno spazio (`- x`). Non ammettono il segno le versioni, i tempi dei passi (G21: `@-1` non è un
passo), i limiti di una molteplicità (G35) e di una ripetizione (G47) e le risoluzioni (G52).

---

## 3. Come il file si divide in dichiarazioni

Le regole U1-U5 stabiliscono **a quale dichiarazione appartiene ogni riga**. Da esse dipende il conteggio delle
righe riconosciute e non riconosciute.

| N. | Regola |
|---|---|
| U1 | Una riga che contiene solo spazi è **vuota**; una riga che contiene solo un commento è un **commento**. Righe vuote e commenti non appartengono a nessuna dichiarazione e non interrompono la dichiarazione in corso |
| U2 | Ogni altra riga che **non comincia dentro una stringa** apre una **nuova dichiarazione**, salvo i casi U4 e U5 |
| U3 | Una riga che comincia dentro una stringa aperta su una riga precedente appartiene alla dichiarazione che contiene quella stringa, anche se è vuota o contiene `--` |
| U4 | Una riga che comincia con `VERIFY` o con `VERBAL` continua la dichiarazione precedente **se questa comincia con `GUARANTEE` o `ASSUME`**. Altrimenti apre una nuova dichiarazione, riconosciuta solo come campo `VERIFY` di un'estensione (sezione 4.11) |
| U5 | Una riga che non comincia dentro una stringa continua la dichiarazione precedente se questa è ancora **aperta**, cioè se: (a) ha una parentesi `(`, `[` o `{` non chiusa; oppure (b) il suo ultimo elemento, escluso l'eventuale commento, richiede un seguito. Richiedono un seguito i simboli `:` `,` `:=` `=` `<>` `<` `<=` `>` `>=` `+` `-` `*` `/` `^` `->` `;` e le parole `THEN` `WITHIN` `AND` `OR` `IMPLIES` `NOT` `IN`. Fa eccezione una riga il cui primo elemento è `@`, `END` o una parola che apre una dichiarazione nella sezione 5 (per esempio `GUARANTEE`, `SCENARIO`, `BIND`, `KIND`, `REPEAT`): tale riga apre sempre una nuova dichiarazione. Righe vuote e commenti fra le due righe non interrompono la continuazione (U1) |

La prima parola di una dichiarazione ne determina il tipo. Una parola chiave che non è la prima della riga non
apre alcuna dichiarazione: fa parte della dichiarazione in corso.

Esempio, con le righe numerate:

```
 1  GUARANTEE g1: VERBAL "Una pressione
 2                       accende la luce"          ← U3: dentro la stringa
 3  -- nota                                         ← U1: commento, non interrompe
 4                VERIFY BY JUDGEMENT "l'operatore" ← U4: continua g1
 5  questa riga è inventata                         ← U2: dichiarazione nuova
```

Le righe 1, 2 e 4 formano una sola dichiarazione.

**La continuazione (U5).** Le parole che aprono sempre una dichiarazione, e quindi non continuano mai la
precedente, sono le seguenti: `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`, `EXTENSION`,
`END`, `STATUS`, `IMPORT`, `PURPOSE`, `TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `GUARANTEE`, `ASSUME`,
`SCENARIO`, `REPEAT`, `OFFERS`, `USES`, `COMPOSED`, `VARIANT`, `BIND`, `MEANS`, `KIND`, `LEVEL`, `PARAMS`,
`FORM`, `MEANING`, `REDUCES`, `SOURCE`, più il simbolo `@`. Così una parentesi non chiusa o un operatore a fine
riga non assorbono una dichiarazione successiva né l'`END` di un blocco. Resta non riconosciuta solo la
dichiarazione rimasta aperta, e il resto del file si legge come prima. `VERIFY` e `VERBAL` seguono U4.

```
 1  GUARANTEE g2: WHENEVER pressione THEN        ← finisce con THEN: resta aperta
 2                  accesa WITHIN 1 s            ← U5: continua g2
 3  GUARANTEE g3: WHENEVER pressione             ← non richiede un seguito
 4                  THEN accesa WITHIN 1 s       ← U2: dichiarazione nuova, non riconosciuta
 5  GUARANTEE g4: ALWAYS (accesa AND             ← parentesi aperta
 6  END                                          ← END: apre una dichiarazione nuova; g4 non è riconosciuta
```

Le righe 1 e 2 formano una sola dichiarazione, riconosciuta. La riga 4 è una dichiarazione a sé, non
riconosciuta, e la riga 3, rimasta incompleta, non è riconosciuta. La riga 5 non è riconosciuta perché la
parentesi resta aperta; la riga 6 chiude il blocco.

Una dichiarazione **riconosciuta** rende riconosciute tutte le sue righe; una dichiarazione **non
riconosciuta** rende non riconosciute tutte le sue righe.

---

## 4. La grammatica delle dichiarazioni

Ogni regola descrive una dichiarazione intera, dalla prima parola all'ultima, anche se occupa più righe.
Una dichiarazione è riconosciuta solo se **tutti** i suoi elementi rispettano la regola, senza elementi
aggiuntivi.

### 4.1 Blocchi

| N. | Regola | Esempio |
|---|---|---|
| G1 | `IntestazioneCsc = "CSC" Nome "VERSION" Versione ;` | `CSC LuceScale VERSION 0.1` |
| G2 | `IntestazioneVista = "REFINEMENT" "VIEW" Nome ;` non è una dichiarazione del linguaggio: serve solo a ricavare il nome del blocco ritirato da riportare nel rapporto (sezione 4.8) | `REFINEMENT VIEW LuceParti` |
| G3 | `Fine = "END" ;` | `END` |

Il blocco `ENTITY` ha la sua intestazione G31 (sezione 4.9); i blocchi `BINDING`, `VERIFICATION`, `PROFILE` ed
`EXTENSION` hanno le intestazioni G40, G48, G49 e G50 (sezione 4.11). Tutti i blocchi terminano con G3 (`END`).

### 4.2 Intestazione della CSC

| N. | Regola | Esempio |
|---|---|---|
| G4 | `StatoCsc = "STATUS" Stato ;` | `STATUS RATIFIED BY D-125` |
| G5 | `Stato = "HYPOTHESIS" \| "RATIFIED" "BY" Decisione ;` | `HYPOTHESIS` |
| G6 | `Scopo = "PURPOSE" Stringa ;` | `PURPOSE "Accende la luce delle scale"` |
| G39 | `ImportaProfilo = "IMPORT" "PROFILE" Nome "VERSION" Versione ;` | `IMPORT PROFILE Segnale VERSION 0.3` |

**Le righe d'intestazione.** In una CSC la **zona d'intestazione** va dalla riga `CSC` alla prima dichiarazione che
non comincia con `STATUS`, `IMPORT` o `PURPOSE`; commenti e righe vuote non contano. In essa `STATUS` (G4),
`IMPORT PROFILE` (G39) e `PURPOSE` (G6) possono comparire **in qualunque ordine**:

- `STATUS` è riconosciuto in qualunque punto della zona. Per un secondo `STATUS` riconosciuto nella zona `bcdd`
  segnala **E10** (`STATUS ripetuto: il primo è alla riga N`, sezione 8), e lo stato della CSC è quello del primo.
  Dopo la zona `STATUS` non è riconosciuto.
- `IMPORT PROFILE` è riconosciuto solo nella zona, zero o più volte; dopo la zona non è riconosciuto. Senza
  `VERSION`, o con una versione che non rispetta L10, non è riconosciuto. La versione è obbligatoria: una regola
  più permissiva introdotta in futuro non renderebbe non valido alcun file esistente, una più restrittiva sì.
- `PURPOSE` è obbligatorio e unico in ogni CSC (E10 se manca o è ripetuto). È riconosciuto anche fuori dalla
  zona, in qualunque punto del blocco.
- Una dichiarazione che comincia con `STATUS`, `IMPORT` o `PURPOSE` ma non è riconosciuta (`STATUS PIPPO`,
  `IMPORT PROFILE Segnale` senza versione) resta non riconosciuta e **non chiude** la zona. Così una riga scritta
  in modo errato non impedisce di riconoscere come intestazione le righe successive.
- Una dichiarazione che apre un blocco (`CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION`, `PROFILE`)
  chiude la CSC con E07 (sezione 5), e con essa la zona.

**La stessa zona negli altri blocchi.** Ogni blocco importa i propri profili. La stessa zona d'intestazione, con le
stesse regole, è presente anche negli altri blocchi:
- in un'entità: `STATUS HYPOTHESIS`, `IMPORT PROFILE`, `PURPOSE` (sezione 4.9);
- in un `BINDING`: `STATUS`, `IMPORT PROFILE`;
- in una `VERIFICATION`: `IMPORT PROFILE`; per uno `STATUS` `bcdd` segnala E39;
- in un `PROFILE`: `STATUS`, `PURPOSE`. In un `PROFILE` `IMPORT PROFILE` non è riconosciuto, perché un profilo
  non importa altri profili.

Le regole dei blocchi `BINDING`, `VERIFICATION` e `PROFILE` sono nella sezione 4.11.

**Il profilo importato.** `IMPORT PROFILE P VERSION v` è una **citazione**: `bcdd` cerca il blocco `PROFILE P`
come cerca una CSC citata (sezione 9.4). Lo trova solo se ha la versione `v` scritta, con testo identico. Un
profilo presente solo con un'altra versione è considerato non trovato: il rapporto lo elenca nella sezione 7, con
la versione trovata. Del profilo trovato `bcdd` legge le estensioni (sezione 4.14).

Due righe che importano lo stesso profilo con la stessa versione non sono un errore e valgono come una sola. Se due
righe dello stesso blocco importano lo stesso profilo con versioni diverse, la seconda nell'ordine del file non è
riconosciuta: lo stesso nome di estensione avrebbe due significati. La riga non registra alcun nome nell'elenco dei
nomi del blocco.

Eccezione intenzionale a G5: `STATUS RATIFIED` seguito da qualsiasi elemento diverso da `BY` e da una
Decisione **è riconosciuto**, e `bcdd` segnala E04. Il controllo arriva fino ai due punti in una riga
contrattuale e fino alla fine della dichiarazione nell'intestazione. Un'approvazione scritta in modo errato non
deve scomparire fra le righe non riconosciute: è un errore che il controllo deve segnalare. `STATUS` seguito da
una parola diversa da `HYPOTHESIS` e `RATIFIED`, invece, non è riconosciuto.

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

G7 dichiara una richiesta; G12 dichiara una costante con nome, una funzione con parametri o un evento derivato.

**Stati con indice e stati che seguono un evento (G11).**
- `STATE x[T] : …` dichiara uno stato con indice: equivale a uno stato per ogni valore di `T`. `T` è un tipo
  **finito**: un elenco di valori (G37), `Boolean`, oppure un nome definito con G41 per uno di questi tipi o per
  un `Integer` con entrambi i limiti. In caso contrario `bcdd` segnala E29.
- Fra le parentesi quadre della dichiarazione si scrive il nome del tipo dell'indice (G11), non una variabile né
  un tipo con limiti. La forma `STATE q[Integer [0 .. 3]] : …` non è riconosciuta: si scrive
  `TYPE Indice := Integer [0 .. 3]` e `STATE q[Indice] : …`.
- Il valore di `INITIAL` vale per ogni elemento. Quando lo stato è usato, l'indice è un valore di `T` o una
  variabile di `FOR ALL` su `T` (sezione 4.12); nelle storie è un valore di `T` (G20).
- `STATE s : T INITIAL v FOLLOWS e.campo` dichiara uno stato che segue il parametro `campo` dell'evento `e`. `e`
  è un `EVENT` del blocco, `campo` un suo parametro, e il tipo del parametro è quello dello stato (altrimenti
  `bcdd` segnala E24 ed E25). Equivale alla forma estesa `ALWAYS (e IMPLIES s = LAST(e).campo)` e
  `ALWAYS (CHANGED(s) IMPLIES e)`. La riga è quindi anche una proprietà formale, senza nome breve, e il rapporto
  non la elenca fra le righe contrattuali.
- Non si possono combinare un indice e `FOLLOWS` nella stessa riga: la riga non è riconosciuta. Eventi e
  richieste non hanno indici.

**Costanti, funzioni ed eventi derivati (G12).**
- Il valore di una `DEFINE` è un'espressione della sezione 4.12. Un Valore della sezione 4.7 ne è un caso
  particolare: un numero, una stringa, `true`, `false` o un valore di un elenco di valori.
- `DEFINE nome(p: T, …) := espressione` è una funzione con parametri tipizzati. Si usa con gli argomenti per
  nome, `nome(p: arg, …)`, come gli argomenti degli eventi nelle storie (sezione 4.12). I nomi dei parametri
  valgono solo nella riga.
- `DEFINE EVENT nome := condizione` dà un nome a un evento derivato. La condizione è un'espressione `Boolean` sul
  passo; la riga non ha parametri né `UNDECIDED`. Il nome si usa dove si usa un evento (sezione 4.12), tranne che
  nei passi delle storie, che contengono solo eventi dichiarati (E03).
- `DEFINE nome DETAILS padre [STATUS …] := …` dettaglia un'altra `DEFINE` dello stesso blocco, il **padre**
  (sezione 7.1 per lo stato). Se il padre non è una `DEFINE`, `bcdd` segnala E02. `UNDECIDED` non ha parametri.
- Le `DEFINE` non possono riferirsi l'una all'altra in modo circolare: per `DEFINE A := B + 1` con
  `DEFINE B := A - 1` `bcdd` segnala E28.
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

`check` controlla il tipo dell'espressione (sezione 4.13), non il valore: non valuta se `120 s` sia un valore
adeguato. Un nome di costante scritto dentro una stringa (`VERBAL "si spegne dopo DURATA_LUCE"`) è solo testo.

**Da `UNDECIDED` a un valore.** `UNDECIDED` indica un numero non deciso: `check` lo elenca nella sezione 3 del
rapporto finché è presente. Quando il numero è deciso, si scrive manualmente il valore al posto di `UNDECIDED`:
nessun comando esegue la sostituzione. La procedura dipende dallo stato della CSC:
- in una CSC **da approvare** si modifica la riga, e non serve altro;
- in una CSC **approvata** la riga non si modifica: si scrive una nuova versione (`VERSION`), che resta da
  approvare finché non viene approvata (sezione 7.2).

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

Un tipo non dichiarato è ammesso e non è un errore. Compare nella sezione 6 del rapporto, con le righe in cui è
usato, in modo da essere visibile. `Sequence` senza `of`, o `Optional` senza tipo, non sono riconosciuti. `check`
non confronta fra loro i limiti di un intervallo: `Real [20.0 .. -20.0]` è riconosciuto (sezione 14). Se un limite
è omesso, l'intervallo non è limitato da quel lato: `Integer [0 ..]` è un intero non negativo senza massimo.
`[ .. ]`, senza i due limiti, non è un intervallo e rende la dichiarazione non riconosciuta.

**Tipi con nome (G41) e `Record` (G42).**
- `TYPE Nome := Tipo` dà un nome a un tipo qualunque di G13. Il nome vale come il tipo che nomina, in tutto il
  blocco, anche se la riga è successiva all'uso. Entra nell'elenco dei nomi del blocco (E01 se ripetuto) e non
  compare più nella sezione 6. Per due nomi di tipo definiti in modo circolare (`TYPE A := B`, `TYPE B := A`)
  `bcdd` segnala E28.
- `Record {campo: Tipo, …}` è un tipo con campi; `x.campo` ne nomina un campo (sezione 4.12). I nomi dei campi
  valgono solo nel `Record`: due campi con lo stesso nome sono E01; un campo può avere lo stesso nome di un
  elemento del blocco. Non esistono valori letterali di tipo `Record`: uno stato di tipo `Record` non ha un
  `INITIAL` valido (E25), e nelle storie il valore di un parametro di tipo `Record` si scrive `_`.
- Le forme `TYPE Nome := VERBAL …` (G30) e `TYPE Nome := { … }` (G37) sono descritte più sotto. Una `TYPE` che non
  rispetta nessuna delle tre forme, o che ridefinisce il nome di un tipo di base (`TYPE Boolean := Integer`), non
  è riconosciuta e non registra alcun nome.

**Tipi descritti a parole (G30):**
- il nome del tipo entra nell'elenco dei nomi del blocco: un altro nome uguale è E01;
- un tipo descritto a parole **non** è un tipo non dichiarato: non compare nella sezione 6 del rapporto, in tutto
  il blocco, anche se la descrizione è successiva all'uso;
- una `TYPE` che non rispetta G30, G37 né G41 (`TYPE Colore := {}`), o che descrive un tipo di base
  (`TYPE Boolean := VERBAL "…"`), non è riconosciuta e non registra alcun nome;
- un tipo non è una promessa: non richiede `VERIFY` e non comporta mai E13. Una riga `VERIFY` dopo una `TYPE`
  apre una nuova dichiarazione, non riconosciuta (regola U4).

Esempio: `STATE contenuto : Testo INITIAL ""` con `TYPE Testo := VERBAL "il contenuto di un file"` nello
stesso blocco: `Testo` non compare nella sezione 6.

**Elenchi di valori (G37).** Un elenco di valori è un tipo costituito da un insieme chiuso di valori con nome; un
valore di quel tipo è uno di tali valori. Esempio:

```
TYPE Fase := {inattiva, armata, in_corso, accettata, rifiutata}
EVENT OUT stato(fase: Fase)
STATE fase_ora : Fase INITIAL inattiva
```

| Che cosa | Regola |
|---|---|
| Il nome del tipo | come G30: entra nell'elenco dei nomi del blocco (E01 se ripetuto) e non compare nella sezione 6 «tipi non dichiarati», in tutto il blocco |
| I valori | sono nomi (L7) ed entrano nello **stesso elenco** dei nomi del blocco. Un valore uguale a uno stato, a un evento, a una richiesta, a una costante, a un nome breve o a un valore di un altro elenco è **E01** sul secondo, nell'ordine del file (riga, poi colonna). Un valore ripetuto nello stesso elenco è E01 sul secondo. Riga e colonna dell'errore sono quelle del valore |
| Un nome come valore | un nome è accettato come valore (G26) in `INITIAL`, `GIVEN`, assegnazioni e argomenti, e in una `DEFINE` il cui valore è un solo nome. In un blocco CSC il nome deve essere un valore di un elenco dello stesso blocco (in una `DEFINE`, anche un altro nome del blocco). Altrimenti: **E03** `nome non dichiarato come valore di TYPE: X`. In una storia d'entità vale la sezione 4.6; in un'espressione più ampia, la sezione 4.13 |
| Il tipo del valore | **si controlla** (sezione 4.13). `STATE fase_ora : Fase INITIAL rifiutata` è riconosciuta senza errori. `STATE accesa : Boolean INITIAL armata` (con `armata` valore di `Fase`) è riconosciuta con l'errore **E25** `valore non del tipo Boolean: armata` |
| Non è una promessa | niente `VERIFY`, niente E13, come G30. Una riga `VERIFY` dopo una `TYPE` apre una nuova dichiarazione, non riconosciuta (U4) |
| Non riconosciute, senza nomi registrati | `TYPE X := {}`, `TYPE X := {a b}`, `TYPE X := {a,}`, `TYPE Boolean := {a, b}` (tipo di base), `TYPE X := {"a", "b"}`, `TYPE X := {1, 2}` |
| `TYPE X := {a, a}` | riconosciuta, con E01 sul secondo `a` |
| Nel JSON | una dichiarazione di tipo `TYPE`, come G30; i valori non sono dichiarazioni autonome e compaiono nel suo `testo` |

I nomi del ciclo di vita (`requested` …), `true`, `false` e `_` sono riservati e non possono essere valori di un
elenco di valori (L7).

### 4.5 Righe contrattuali

| N. | Regola | Esempio |
|---|---|---|
| G16 | `RigaContrattuale = ( "GUARANTEE" \| "ASSUME" ) Id [ "DETAILS" Id ] [ "STATUS" Stato ] ":" Proprieta ;` | `GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "…" VERIFY BY JUDGEMENT "…"` |
| G17 | `Proprieta = "VERBAL" Stringa Verifica \| Formula ;` (`Formula`: G55, sezione 4.12) | `VERBAL "Check non modifica mai il file" VERIFY BY INSPECTION "il file"`, `WHENEVER pressione THEN accesa WITHIN 1 s` |
| G18 | `Verifica = "VERIFY" "BY" ( "JUDGEMENT" \| "INSPECTION" ) Stringa ;` | `VERIFY BY JUDGEMENT "l'operatore"` |

Una riga contrattuale è una promessa (`GUARANTEE`) o un presupposto (`ASSUME`) e si legge in due parti.
L'**intestazione della riga** va dalla prima parola ai due punti; la **proprietà** segue i due punti.
- Se l'intestazione della riga non rispetta G16, la riga non è riconosciuta e il controllo non registra il suo
  nome breve.
- Se l'intestazione della riga rispetta G16 ma la proprietà non rispetta G17, il nome breve è registrato: può
  essere citato con `DETAILS` e conta per i nomi ripetuti. La riga, però, non è riconosciuta e il suo grado è
  «non riconosciuta». È il caso di una formula scritta in una forma non prevista dalla sezione 4.12 (sezione 6).
- Una formula non richiede `VERIFY`: il suo modo di verifica è dato dalla forma (sezione 6). Una riga `VERIFY`
  dopo una formula continua la dichiarazione (U4) e la rende non riconosciuta.

Lo stesso vale per G12: in `DEFINE LIMITE := DURATA * * 2` il nome `LIMITE` è registrato, ma la riga non è
riconosciuta perché l'espressione non rispetta la sezione 4.12.

**Il controllo mancante (errore E13).** Eccezione intenzionale a G17, come quella di G5. Se dopo i due punti la
proprietà è **esattamente** `VERBAL` seguito da una stringa completa, e la dichiarazione termina lì, la riga **è
riconosciuta**: il suo grado è `verbale` e `bcdd` segnala E13. Esempio: `GUARANTEE g2: VERBAL "senza verifica"`.

Motivo: ogni promessa e ogni presupposto devono indicare come si verificano. Una promessa priva del modo di
verifica non è una forma che `bcdd` non riconosce: `bcdd` la legge per intero e rileva la mancanza di un elemento
obbligatorio. Classificarla fra le righe non riconosciute, con codice d'uscita 0 senza `--strict`, farebbe passare
come valida una promessa senza modo di controllarla. È lo stesso criterio di E04 (un'approvazione senza
decisione).

E13 ha una definizione volutamente restrittiva. Se dopo la stringa è presente qualsiasi altro elemento, vale G17.
Per esempio `VERBAL "…" VERIFY BY MAGIC "…"` dichiara un modo di verifica che il linguaggio non prevede: la riga
non è riconosciuta, senza E13. Nei passi delle storie l'elemento `VERBAL "…"` (G22) è un'asserzione a parole, non
una proprietà: non richiede `VERIFY` e non comporta mai E13.

**Dichiarazioni non riconosciute che registrano un nome.** Un nome registrato è noto al controllo: può essere
citato (`DETAILS`, passi) e conta per E01. Lo registrano solo:
- `GUARANTEE` e `ASSUME` con intestazione della riga valida (G16), qualunque sia la proprietà;
- `DEFINE` letta secondo G12 fino a `:=` compreso (con i parametri, `DETAILS` e `STATUS` se presenti, oppure
  `DEFINE EVENT Nome`), seguita da qualsiasi contenuto.

`CAPABILITY`, `EVENT`, `STATE`, `SCENARIO` e `TYPE` non registrano alcun nome se non sono riconosciute per
intero. Motivo della differenza: il nome breve di una riga contrattuale serve alla catena dei `DETAILS` e allo
stato di approvazione (sezione 7), e l'intestazione della riga si legge indipendentemente dalla proprietà, prima dei
due punti. Per le altre dichiarazioni la parte essenziale (parametri, tipo, `GIVEN`) è proprio quella che non è
stato possibile leggere. Di conseguenza, per un passo che nomina un evento o una richiesta la cui dichiarazione
non è riconosciuta `bcdd` segnala E03 («non dichiarato»). L'errore indica il punto da correggere, e la
dichiarazione scritta in modo errato compare comunque nella sezione 5 del rapporto.

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

Una storia comincia con `SCENARIO` (G19) e prosegue con i suoi passi (G21). Un elemento di un passo si distingue
dagli altri esaminando al massimo l'elemento successivo:
- `VERBAL` apre un'asserzione a parole;
- una delle cinque parole del ciclo di vita apre un `Ciclo`;
- un nome seguito da `=` è un'`Assegnazione`, cioè «in questo passo lo stato vale…»;
- un nome non seguito da `=` è un'`Occorrenza` di evento;
- dopo `=` segue sempre un Valore (G26). `@1 s fase_ora = armata premi(…)` contiene un'assegnazione seguita da
  un'occorrenza. In `x = premi` il valore è il nome `premi`; se non è un valore di un elenco di valori, `bcdd`
  segnala E03.

La virgola fra due elementi è facoltativa. Una virgola alla fine del passo lascia la dichiarazione aperta (U5): se
la riga successiva comincia con `@`, il passo resta non riconosciuto. L'unità dopo il numero del passo è
riconosciuta solo se si trova sulla stessa riga.

**Indici nelle storie (G20).** `x[v] = w` assegna l'elemento `v` di uno stato con indice: `v` è un valore del tipo
dell'indice (altrimenti E29), `w` un valore del tipo dello stato. Per uno stato con indice usato senza indice, o
per uno stato senza indice usato con un indice, `bcdd` segnala E29.

**Dettagli di una storia (G19).** `SCENARIO id DETAILS padre [STATUS …]` dettaglia un'altra storia dello stesso
blocco; se `padre` non è una storia, `bcdd` segnala E02. Lo stato della storia dettagliata è regolato dalla sezione
7.1. Una storia senza `DETAILS` non ha `STATUS`: `SCENARIO s1 STATUS HYPOTHESIS EXPECT ADMITTED` non è
riconosciuta.

**Le ripetizioni (G47).** Una riga `REPEAT` sta fra i passi di una storia e vale fino alla fine della storia: i
passi che la seguono sono quelli ripetuti. `REPEAT FOREVER EVERY d` ripete i passi senza fine (**ripetizione senza
fine**); `REPEAT m..n EVERY d` li ripete da `m` a `n` volte. Ogni ripetizione comincia `d` dopo la precedente, e i
tempi `@t` dei passi ripetuti sono misurati dall'inizio della ripetizione. Esempio:

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
| E12 | vale per i passi che precedono `REPEAT`, come nelle storie senza ripetizione, e per i passi ripetuti confrontati fra loro, con i tempi relativi. Il primo passo ripetuto non si confronta con quelli che precedono `REPEAT` |

Una riga `REPEAT` non è un passo: non apre e non chiude la storia (sezione 5).

Limite noto: in `@0 s pressione` la parola `s` è l'unità di tempo. Un evento chiamato `s` o `ms` non può quindi
essere il primo elemento di un passo privo di unità di tempo.

**Storie d'entità.** In un blocco `ENTITY` valgono `SCENARIO` (G19) e i passi (G21-G25) come nella CSC, con una
sola differenza: i nomi di stati, eventi e richieste sono **qualificati** (G36). Si scrive `NomeQualificato` al posto
di `Nome` in queste tre regole, e solo in esse:

```
G20e  Assegnazione = NomeQualificato "=" Valore ;
G23e  Ciclo        = ( "requested" | "accepted" | "rejected" | "completed" | "failed" ) "(" NomeQualificato ")" ;
G24e  Occorrenza   = NomeQualificato [ "(" Argomento { "," Argomento } ")" ] ;
```

G20e vale nel `GIVEN` e nei passi. Gli argomenti (G25) restano nomi semplici: sono i parametri dell'evento. Un nome
semplice in una storia d'entità è interpretato secondo G20, G23, G24 come nella CSC, e `bcdd` segnala E03: un'entità
non ha elementi propri. Esempio, nell'entità `Processore` che offre `Abbinamento`, `Sessione` e `Pulsanti`:

```
SCENARIO comandoDopoAbbinamento GIVEN Sessione.pronta = true EXPECT ADMITTED
  @0 s   Abbinamento.abbina(codice: "AB12")
  @1 s   Pulsanti.premi(pulsante: "flat", acceso: true)
```

Significato: come una storia di una CSC, è una traccia aperta, con istanti definiti, che l'entità ammette o
respinge; è osservata su più confini della stessa entità. Non è un contratto: non si approva e non stabilisce un
ordine fra le parti, né una priorità, né un canale. Controlli eseguiti da `check`:

| Caso | Esito |
|---|---|
| `X.y`, dove `X` compare in una riga `OFFERS` o `USES` dell'entità riconosciuta e priva di E01; la CSC `X` è trovata (sezione 9.4) e ha `y` del genere corretto: `STATE` nelle assegnazioni, `EVENT` nelle occorrenze, `CAPABILITY` nei cicli; ogni argomento è un parametro dell'evento | nessun errore |
| come sopra, ma `y` non esiste o non è del genere corretto | **E03** `nome non dichiarato come EVENT: X.y` (e così `STATE`, `CAPABILITY`) |
| come sopra, ma un argomento non è un parametro dell'evento | **E03** `nome non dichiarato come parametro di X.y: a` |
| `X` non è fra le `OFFERS` e `USES` dell'entità (riconosciute e prive di E01) | **E20** `X.y: E non offre né usa il connettore X; uno scenario può citare solo i connettori di E`, con `E` il nome dell'entità (`?` se non si legge) |
| `X` è dell'entità ma la CSC `X` non è trovata | nessun errore: il controllo di `y` e dei suoi argomenti è **sospeso**, come E14 con una parte non trovata; la citazione è già nella sezione 7 |
| un nome **semplice** (`pronta`) | **E03**, come in una CSC che non dichiara quel nome: `nome non dichiarato come STATE: pronta` |
| un valore che è un nome (`fase: armata`) | è accettato come valore, senza controllo: i valori degli elenchi di valori di una CSC citata non vengono letti (sezione 14) |
| un valore letterale (numero, stringa, `true`, `false`, `ABSENT`) per uno stato o un parametro di `X.y` | si controlla con il tipo letto nel blocco trovato, se è un tipo di base (`Boolean`, `String`, `Duration`, `Integer`, `Real`, con il loro intervallo, anche dentro `Optional`): **E25** se il valore non è del tipo. Un tipo che non è di base (un elenco di valori, un tipo con nome, un tipo descritto a parole della CSC citata) non si controlla |
| `X.y` in una **CSC** (anche con `X` uguale alla CSC stessa), in un `GIVEN`, in un'assegnazione, in un'occorrenza, in un ciclo o in una fase di una formula (sezione 4.12) | **E20** `X.y: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità`. La dichiarazione è letta con G20e, G23e, G24e al solo scopo di segnalare l'errore |
| `X.y` fuori da una storia (per esempio `DEFINE N := X.y`, `STATE s : X.T INITIAL …`, `OFFERS X.y`) | non è una forma ammessa: la dichiarazione non è riconosciuta |

Per E20 ed E03 su un nome qualificato, riga e colonna sono quelle di `X`. Una dichiarazione con E20 o E03 resta
**riconosciuta** (la forma è corretta, il nome no), come con E03 nella CSC.

Con più versioni della stessa CSC offerte o usate (sezione 5) basta che `y` esista in uno dei blocchi trovati per
quel nome. Se `y` non esiste in nessuno dei blocchi trovati, ma almeno una delle righe `OFFERS` o `USES` con quel
nome non è stata trovata, il controllo di `y` e dei suoi argomenti è **sospeso**, senza E03. La versione mancante
potrebbe avere `y`, e un errore si segnala solo quando è certo. E03 è segnalato solo quando sono state trovate
tutte le righe con quel nome.

Una riga trovata solo nella versione di riserva (`, attesa VERSION w`, sezione 9.4) non conta come trovata ai fini
di questo controllo. È trattata come una riga non trovata: il controllo di `y` è sospeso, senza E03 sul blocco di
un'altra versione. Nel rapporto la riga riporta comunque `attesa`. E12 vale nelle storie d'entità come nella CSC.
Il nome breve di una storia d'entità entra nell'elenco dei nomi dell'entità (sezione 5).

### 4.7 Valori

| N. | Regola | Esempio |
|---|---|---|
| G26 | `Valore = Stringa \| NumeroConSegno [ Unita ] \| "true" \| "false" \| "ABSENT" \| Nome ;` dove `Nome` è un valore di un elenco di valori (sezione 4.4) | `180 s`, `""`, `false`, `-40`, `armata`, `ABSENT` |
| G27 | `Unita = "ms" \| "s" ;` sulla stessa riga del numero, con o senza spazio | `250 ms`, `50ms` |

### 4.8 L'elenco delle parti e la vista ritirata

| N. | Regola | Esempio |
|---|---|---|
| G28 | `ElencoParti = "COMPOSED" "OF" ;` | `COMPOSED OF` |
| G29 | `Parte = Nome ":" Nome ;` apparteneva solo alle viste, ritirate dal linguaggio: **non è ammessa in nessun contesto** | `archivio : Archivio` |

G28 vale nell'entità (sezione 4.9). `LINK`, `MAP` e `REFINED BY` sono righe non riconosciute.

**La vista è ritirata.** Una scomposizione si scrive con `ENTITY`. Una vista `REFINEMENT VIEW` è trattata come
segue:

- Una dichiarazione che comincia con la parola `REFINEMENT` in una posizione in cui può iniziare un blocco (fuori
  da un blocco, oppure dentro un blocco aperto, che viene chiuso con E07) comporta l'**errore E15** sulla parola
  `REFINEMENT`, qualunque sia il seguito. La dichiarazione non è riconosciuta.
- La dichiarazione apre un **blocco ritirato**, che termina con `END` (G3), come gli altri blocchi. Dentro il
  blocco ritirato ogni altra dichiarazione non è riconosciuta: non registra alcun nome, non viene cercata, non
  compare nella sezione 7 e non comporta E01. Una riga `CSC`, `ENTITY` o `REFINEMENT` chiude il blocco ritirato
  con E07, come per gli altri blocchi; se manca `END` alla fine del file, `bcdd` segnala E07.
- Il blocco ritirato non registra il suo nome: non comporta E01 con un altro blocco dello stesso nome.
- Nel rapporto il blocco ritirato compare fra i blocchi: `riga N: REFINEMENT VIEW Nome` se la dichiarazione
  rispetta G2, altrimenti `REFINEMENT VIEW (intestazione non valida)`. E07 lo nomina (`manca END di REFINEMENT
  VIEW X`). Non è considerato ai fini di E11.

**Motivo dell'errore, anziché di una riga non riconosciuta o di un avviso.** `check` non ha avvisi: servirebbe una
sezione del rapporto per un solo caso. Una riga non riconosciuta indica una forma che `bcdd` non riconosce, e senza
`--strict` non modifica il codice d'uscita. La vista non verrebbe segnalata, e chi l'ha scritta potrebbe ritenere
di aver dichiarato una scomposizione. Qui invece `bcdd` riconosce la forma e rileva che è stata ritirata dal
linguaggio. Il caso corrisponde alla definizione di errore della sezione 8, con lo stesso criterio di E04 e di
E13. Il messaggio indica che cosa scrivere al suo posto.

**Motivo per cui le righe del blocco non sono riconosciute.** Leggere le parti di una vista equivarrebbe ad
attribuire ancora un significato a una forma che non ne ha più. Le righe restano tutte visibili nella sezione 5,
con il numero di riga. Il blocco viene mantenuto, con il suo `END`: altrimenti per `END` `bcdd` segnalerebbe E08, e
`COMPOSED OF` e le parti risulterebbero scritte fuori da un blocco.

### 4.9 Entità

Un'**entità** è identificata dai suoi confini: le CSC che offre e quelle che usa. Chi offre una CSC mantiene le
sue promesse (`GUARANTEE`), chi la usa rispetta i suoi presupposti (`ASSUME`). Un'entità può essere composta di
altre entità, le sue **parti**. Non ha elementi propri (eventi, stati, richieste): questi sono dichiarati nelle
CSC, e per una dichiarazione di elemento proprio in un'entità `bcdd` segnala E18 (sezione 5). Un'entità ha storie
in cui i nomi sono qualificati (sezione 4.6).

| N. | Regola | Esempio |
|---|---|---|
| G31 | `IntestazioneEntita = "ENTITY" Nome "VERSION" Versione ;` | `ENTITY LuceScale VERSION 0.2` |
| G32 | `Offerta = "OFFERS" Nome [ "VERSION" Versione ] ;` il nome è una CSC | `OFFERS Pressione VERSION 0.1` |
| G33 | `Uso = "USES" Nome [ "VERSION" Versione ] ;` il nome è una CSC | `USES Comando` |
| G34 | `ParteEntita = Nome ":" Nome [ "VERSION" Versione ] [ Molteplicita ] ;` il primo è il nome della parte, il secondo un'entità | `pulsante : Pulsante VERSION 0.1`, `telefono : Misuratore [1 .. 4]` |
| G35 | `Molteplicita = "[" Numero ".." Numero "]" ;` | `[1 .. 4]`, `[2 .. 2]` |

- `VERSION` senza versione, o con una versione che non rispetta L10 (`v1`), rende la dichiarazione non
  riconosciuta: `OFFERS Comando VERSION v1` non è riconosciuta e non viene cercata.
- Una parte (G34) vale in qualunque punto dell'entità. L'elenco delle parti, `COMPOSED OF` (G28), si scrive una
  sola volta e dichiara che l'entità è composta di parti (sezione 5, «Le parti di un'entità»).
- Un'entità può avere `STATUS HYPOTHESIS` (G4) e righe `IMPORT PROFILE` (G39) nella sua zona d'intestazione, come
  la CSC (sezione 4.2). Ha esattamente un `PURPOSE` (G6), righe `GUARANTEE` (G16), eventualmente collegate fra loro
  con `DETAILS`, e storie con i loro passi (sezione 4.6).
- Le promesse d'entità sono scritte a parole o come formule. Si approvano una per una o con `--all` (sezione 12);
  l'entità nel suo insieme non si approva (sezione 7.1).
- **Le promesse d'entità scritte come formule.** Una formula in una `GUARANTEE` d'entità (sezione 4.12) nomina gli
  elementi delle CSC dell'entità con i nomi qualificati `X.y` (G36). Valgono le regole delle storie d'entità della
  sezione 4.6:
  - `X` è una `OFFERS` o `USES` dell'entità; altrimenti `bcdd` segnala E20, con il messaggio `X.y: E non offre né
    usa il connettore X; una promessa d'entità può citare solo i connettori di E`;
  - `y` è un elemento del genere corretto nella CSC `X` trovata; altrimenti `bcdd` segnala E24;
  - il controllo è sospeso se `X` non è trovata;
  - con le composizioni, `X` si controlla per composizione come nelle storie d'entità (sezione 4.10).
- In una formula d'entità `X.y` ha tipo **non noto**, anche quando il blocco trovato gli assegna un tipo di base:
  `check` ne controlla il nome e il genere, non il tipo, e su queste formule non segnala E25 (sezione 14). Nelle
  storie d'entità, invece, i valori letterali si controllano sui tipi di base (sezione 4.6).
- Un nome semplice in una formula d'entità è un valore di un elenco di valori di una CSC citata, accettato senza
  controllo, oppure una variabile di `FOR ALL`. In una posizione in cui è richiesto un evento, una richiesta, uno
  stato o una condizione, `bcdd` segnala E24 (`in un'entità i nomi delle CSC si scrivono con il connettore davanti:
  x`).
- Un'entità applica le estensioni dei profili che essa stessa importa, con `LEVEL ENTITY` (sezione 4.14).
  Esempio: `GUARANTEE g1: WHENEVER Pressione.pressione AND NOT Luce.accesa THEN Luce.accesa WITHIN 1 s`.

**La molteplicità di una parte (G35).** `telefono : Misuratore [1 .. 4]` indica che l'entità è composta di almeno
`m` = 1 e al più `n` = 4 copie della parte. Ogni copia è vincolata interamente dalle CSC che la parte offre e usa.
La molteplicità non specifica quando una copia è presente o viene rimossa, né come le copie si distinguano, né
quale venga prima, né dove si trovino. Senza molteplicità una parte equivale a `[1 .. 1]`.

| Che cosa | Regola |
|---|---|
| Ordine | uno solo: prima la versione (dell'entità nominata), poi la molteplicità (della parte). `telefono : Misuratore [1 .. 4] VERSION 0.1` non rispetta G34: non è riconosciuta e non è una parte |
| Limiti validi | due interi (L13) con 0 <= `m` <= `n` e `n` >= 1: `m` = 0 rende la parte **facoltativa** (sezione 4.10) |
| **E19** | la forma G35 è presente, ma un limite contiene un punto (`[1.5 .. 4]`), o `m` > `n` (`[4 .. 1]`), o `n` = 0 (`[0 .. 0]`). Riga della parte, colonna di `[` |
| La parte con E19 | **resta una parte**: viene cercata, compare sotto l'entità, conta nella chiusura (E14, E16, E17) e nella sezione 8 come se la molteplicità fosse valida. Un limite errato comporta un solo errore, non una cascata di errori. Vale come parte **fissa** (presente in ogni composizione), anche con `m` = 0 |
| Non sono G35 | `[1 .. ]`, `[1, 4]`, `[-1 .. 4]` (`-1` non è un Numero, L11), `[1 .. 4` : la dichiarazione non rispetta G34, non è riconosciuta e non è una parte (come ogni dichiarazione che non rispetta G34, sezione 5) |
| Chiusura e sezione 8 | la riga resta **una** parte; la corrispondenza non cambia (9.4). La riga `OFFERS X` di una parte non soddisfa la sua stessa `USES X`, **anche con `m` >= 2**: le copie di una stessa parte non si servono fra loro. Due nodi che si servono a vicenda sono due parti (`a : Nodo`, `b : Nodo`) |
| Nel rapporto | la riga della citazione si scrive senza molteplicità, come si scrive senza versione (9.4) |
| Nel JSON | la citazione `PART` ha il campo `molteplicita`: `{"min": m, "max": n}` con i due limiti come numeri, oppure `null` se la riga non indica una molteplicità. Con E19 il campo è comunque presente, con i limiti come scritti se sono interi; se un limite contiene un punto, il campo è `null` |

Un'entità con parti deve essere **chiusa**. Ogni confine pubblico è mantenuto da una parte che sta dallo stesso
lato (E16); ogni confine offerto da una parte è usato da un'altra parte oppure offerto dall'entità (E17). La
chiusura si controlla in ogni composizione (sezione 4.10).

L'esempio della luce delle scale; le CSC `Pressione`, `Luce`, `Comando` e le entità `Pulsante`, `Lampada` sono
nella stessa cartella, un file ciascuna:

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

La luce delle scale offre `Pressione` e `Luce` a chi sta sulle scale. Al suo interno la lampada usa `Comando`,
offerto dal pulsante. Il rapporto di questo file è nella sezione 9.4.

### 4.10 Varianti, parti facoltative e composizioni

Un'entità può dichiarare che una sua funzione è svolta da uno fra più dispositivi alternativi (**varianti**) e che
una parte può essere assente (**parte facoltativa**). L'entità ha allora più **composizioni**, e `check` le
controlla tutte.

| N. | Regola | Esempio |
|---|---|---|
| G38 | `Variante = "VARIANT" Nome "=" Nome ;` il primo nome è il **nome del gruppo**, il secondo la **scelta** | `VARIANT sensore = di` |

**I segmenti.** In un blocco `ENTITY` una riga G38 apre un **segmento**, che termina alla riga `VARIANT`
successiva o a `END`. Le righe prima del primo segmento sono le **righe comuni**. In un segmento valgono:
- `OFFERS` (G32) e `USES` (G33);
- `COMPOSED OF` (G28), una volta per segmento: una seconda nello stesso segmento non è riconosciuta e non ha alcun
  effetto;
- le parti (G34), anche facoltative;
- `GUARANTEE` (G16, con `DETAILS`) e `SCENARIO` (G19) con i passi.

I segmenti con lo stesso nome del gruppo sono le **scelte** di quel **gruppo** e si escludono a vicenda; non devono
essere consecutivi. I nomi dei gruppi e delle scelte non entrano nell'elenco dei nomi dell'entità (sezione 5).

| Caso | Esito |
|---|---|
| `VARIANT` in un blocco `CSC` | **E21**; non riconosciuta |
| una riga `VARIANT` che non rispetta G38, in un'entità (`VARIANT sensore`, `VARIANT sensore = di microfono`) | **E21**; non riconosciuta. Apre comunque un segmento, senza gruppo: le sue righe si leggono (nomi, nomi brevi, gradi), ma l'entità **non ha composizioni**. Per essa niente E22, E23, E14, E16, E17, e nessuna voce nelle sezioni 8, 9 e 10 |
| `VARIANT` fuori da un blocco o in un blocco ritirato | non riconosciuta, senza errore |
| `PURPOSE` in un segmento | **E21**; non riconosciuta e non conta per E10 |
| `STATUS` in un segmento | non riconosciuta, senza errore (come ogni `STATUS` fuori dalla zona d'intestazione) |
| `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` in un segmento | **E18**, come nel resto dell'entità |
| un gruppo con una sola scelta | **E22** sul suo `VARIANT`; il gruppo conta come un fattore con un solo valore |
| la stessa scelta scritta due volte | **E22** sulla seconda riga; le righe del secondo segmento valgono come righe della stessa scelta |
| un segmento privo di dichiarazioni riconosciute (contano le righe con E01; non contano commenti, righe vuote, righe non riconosciute e una `COMPOSED OF` da sola) | **E22** sul suo `VARIANT`: per ottenere una scelta vuota si dichiara una parte facoltativa `[0 .. 1]` |

**La parte facoltativa.** `parte : E [0 .. n]` (G35 con `m` = 0, sezione 4.9) significa «senza la parte, oppure
con da 1 a `n` copie»: due composizioni, ciascuna invariata per tutta la traccia. Nella composizione «con» la parte
ha molteplicità `[1 .. n]`; in quella «senza» la parte non offre, non usa e non conta nella chiusura. La parte
viene comunque cercata. Può stare fra le righe comuni o in un segmento; in tal caso è presente solo con quella
scelta.

**I fattori.** Un **fattore** è un elemento di scelta nella composizione dell'entità:

| Fattore | Valori, nell'ordine | Nome di un valore |
|---|---|---|
| un gruppo dell'entità | le scelte, nell'ordine della prima riga di ciascuna | `D = S` |
| una parte facoltativa (senza E19) | presente, poi assente | `con P`, `senza P` |
| un gruppo di una parte **trovata** il cui blocco ha righe G38 riconosciute (le scelte della parte salgono all'entità) | le scelte, nell'ordine del blocco della parte | `P.D = S` |

I fattori sono ordinati secondo la riga del file controllato: un gruppo alla riga del suo primo `VARIANT`, una
parte alla sua riga; i gruppi di una parte nell'ordine del suo blocco. Un fattore dentro un segmento esiste solo
nelle composizioni di quella scelta; i fattori di una parte facoltativa esistono solo nelle composizioni «con».
**Le parti facoltative di una parte non salgono**: non cambiano le sue righe `OFFERS` e `USES`, le uniche che si
leggono di una parte (9.4, una sola profondità).

**Le composizioni.** Una composizione ha un valore per ogni fattore presente in essa. Le composizioni sono elencate
in ordine lessicografico sui fattori (il primo cambia più lentamente). Il **nome** è l'elenco dei valori,
nell'ordine, separati da `, `: `sensore = di, con di`. Un'entità senza fattori ha una composizione senza nome. In
ogni composizione:
- i confini pubblici sono le `OFFERS` e `USES` comuni più quelle dei segmenti scelti;
- le parti sono quelle comuni più quelle dei segmenti scelti, escluse le parti facoltative assenti;
- una parte offre e usa le sue righe comuni più quelle delle sue scelte. Nel blocco di una parte, le righe del
  segmento di un `VARIANT` scritto in modo errato non sono né offerte né usate.

**Il limite (E23).** Le composizioni si contano prima di elencarle, con la formula sui fattori; il conteggio si
interrompe appena supera **64**. In questo caso `bcdd` segnala **E23** sull'intestazione, colonna 0. Per l'entità
non si controlla la chiusura e la sezione 8 non ha voci.

**La chiusura in ogni composizione.** E14, E16 ed E17 (sezioni 8 e 9.4) si controllano in ogni composizione con
almeno una parte presente, con o senza `COMPOSED OF`; la corrispondenza della sezione 9.4 vale allo stesso modo.
In una composizione senza parti presenti (per esempio quando l'unica parte è facoltativa e assente) la chiusura
non si controlla, come in un'entità senza parti. Se una parte dell'entità, in qualunque segmento, non è trovata,
E14, E16 ed E17 sono sospesi per tutta l'entità. Se più composizioni producono lo stesso errore (stesso codice,
riga, colonna e messaggio), l'errore si scrive una sola volta, con il suffisso `(in: …)` della sezione 9.5.

**L'assenza dichiarata.** Sia `C` una composizione con almeno una parte facoltativa assente, `A` l'insieme delle
parti assenti e `C+` la stessa composizione con tutte le parti di `A` presenti. Un errore E14, E16 o E17 di `C` che
**non** compare in `C+` non è un errore: è un'**assenza dichiarata**, nella sezione 10 del rapporto. Le parti
nominate («senza P») sono le `p` di `A` tali che l'errore non compare in `C` con la sola `p` reinserita. Se nessuna
basta da sola, sono tutte quelle di `A`, in ordine di riga, separate da `, `. Nessun altro errore è mai
un'assenza. Lo stesso errore può essere assenza in una composizione ed errore in un'altra: compare allora in
entrambe le sezioni del rapporto.

**Nomi, dettagli e storie nei segmenti.** Due righe sono **compatibili** (possono comparire nella stessa
composizione) se non appartengono a due scelte diverse dello stesso gruppo. E01 fra due parti, o fra due `OFFERS`
(o due `USES`), vale solo fra righe compatibili (sezione 5); i nomi brevi di promesse e storie restano unici in
tutta l'entità. La riga nominata da un `DETAILS` deve essere fra le righe comuni o nella stessa scelta del
dettaglio; altrimenti `bcdd` segnala **E02**.

In una storia d'entità `X.y` si controlla in ogni composizione: una storia di un segmento vale nelle composizioni
che hanno quella scelta, una storia comune vale in tutte. **E20**, con il suffisso `(in: …)`, è segnalato nelle
composizioni in cui `X` non è un confine. E03 non dipende dalla composizione.

**Una riga in un segmento** compare nel rapporto come le altre righe (sezioni 2-7, righe delle citazioni). Le
promesse di un segmento si approvano per nome breve come le altre; le righe `VARIANT` non si approvano (sezione 12).

### 4.11 Forme concrete, piano di prova, profili ed estensioni

Un blocco `BINDING` contiene le forme concrete di un confine, un blocco `VERIFICATION` il piano di prova, un blocco
`PROFILE` le estensioni di un campo d'uso, ciascuna in un blocco `EXTENSION`. `BINDING`, `VERIFICATION` e
`PROFILE` sono blocchi come `CSC` ed `ENTITY`: stanno fuori da ogni altro blocco e terminano con `END` (G3).
L'intestazione di uno di questi blocchi dentro un blocco aperto chiude quest'ultimo con l'errore E07 (sezione 5).
`EXTENSION` sta solo dentro un `PROFILE`.

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

`Parola` in G43 e G44 è una parola qualunque (L3), anche riservata. Il valore si controlla in seguito (E33): in
questo modo un valore errato non finisce fra le righe non riconosciute. `V1`, `V2` e `C1` … `C8` sono riconosciute
come tali solo in G46 (sezione 2.3).

#### Il blocco `BINDING`

```
BINDING Luce VERSION 0.1
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "la plafoniera emette luce piena"
  BIND modo:   VERBAL "la spia sul pulsante: verde a luce spenta, spenta a luce accesa"
END
```

- La **zona d'intestazione** (sezione 4.2) contiene `STATUS` (al più uno, E10 se ripetuto) e `IMPORT PROFILE`. Un
  `BINDING` non ha `PURPOSE`: in un `BINDING` una riga `PURPOSE` non è riconosciuta.
- Il corpo contiene righe `BIND` (G51) e usi delle estensioni che i profili importati dal blocco dichiarano con
  `KIND DECLARATION` e `LEVEL BINDING` (sezione 4.14). Ogni altra dichiarazione non è riconosciuta.
- La **CSC legata** è la CSC nominata nell'intestazione, con la versione scritta. `bcdd` la cerca come una riga
  `USES Nome VERSION v` (sezione 9.4) e la riporta sotto la riga del blocco o nella sezione 7.
- Una riga `BIND elemento` lega un elemento della CSC legata alla sua forma concreta, descritta a parole.
  L'elemento è uno `STATE`, un `EVENT`, una `CAPABILITY` o una `DEFINE` della CSC legata, oppure `e.p`, con `e` un
  `EVENT` o una `CAPABILITY` e `p` un suo parametro. Se la CSC legata è trovata con la versione scritta e
  l'elemento non esiste, `bcdd` segnala **E31**. Se la CSC non è trovata, o è trovata solo in un'altra versione, il
  controllo è sospeso.
- Una riga `BIND` non è una proprietà: non richiede `VERIFY` e non comporta mai E13. Una riga `VERIFY` dopo una
  riga `BIND` apre una nuova dichiarazione, non riconosciuta (U4).
- Una riga `BIND` non ha `DETAILS`: riguarda soltanto l'elemento che lega. `BIND accesa DETAILS l1: …` non è
  riconosciuta.
- Più righe `BIND` per lo stesso elemento sono ammesse: descrivono aspetti diversi della stessa forma.
- Gli `STATE`, `EVENT` e `CAPABILITY` della CSC legata non nominati da alcuna riga `BIND elemento` del blocco
  compaiono nella sezione 12 del rapporto, senza errori (sezione 9.6). Una riga `BIND e.p` non vale per `e`.
- Il nome indicato nell'intestazione non entra nell'elenco dei nomi dei blocchi del file: per `BINDING Comando`
  nello stesso file della `CSC Comando` `bcdd` non segnala E01. Il nome che segue `AS` è il **nome distintivo** del
  blocco.
- **Più blocchi per la stessa CSC.** Nel file controllato `bcdd` segnala **E40** sul secondo di due blocchi
  `BINDING` per la stessa CSC e la stessa versione, scritta con testo identico, se entrambi sono senza `AS` oppure
  hanno lo stesso nome dopo `AS`. Un blocco senza `AS` e uno con `AS` per la stessa CSC e versione sono ammessi.
- Un `BINDING` ha uno stato (approvato o da approvare), come una CSC. Il suo `STATUS` vale per le righe `BIND` che
  non hanno uno `STATUS` proprio (sezione 7.1), e `ratify` lo approva (sezione 12).

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

- La **zona d'intestazione** contiene soltanto `IMPORT PROFILE`. Per uno `STATUS` in qualunque punto del blocco,
  nella zona d'intestazione o fuori, `bcdd` segnala **E39**: un piano di prova non si approva. In una
  `VERIFICATION` una riga `PURPOSE` non è riconosciuta.
- La CSC legata si cerca come per un `BINDING`.
- Una riga `MEANS` (G52) dichiara un mezzo di registrazione e indica:
  - il nome del mezzo;
  - gli elementi della CSC legata che il mezzo osserva (gli stessi di una riga `BIND`, con E31 se non esistono);
  - la risoluzione, cioè una durata con unità;
  - con `USING b`, il nome distintivo del `BINDING` con cui il mezzo osserva.

  I nomi dei mezzi e i nomi brevi delle storie tradotte formano un solo elenco: un nome ripetuto è E01.
- `USING b` è una citazione: `bcdd` cerca il blocco `BINDING` della stessa CSC e della stessa versione con nome
  distintivo `b`. L'ordine di ricerca è quello della sezione 9.4: il file controllato, poi il file `NomeCSC.csc`
  della sua cartella, poi le cartelle `--dir`. Se lo trova, lo riporta sotto la riga del blocco; se non lo trova,
  lo elenca nella sezione 7.
- Una storia tradotta (G53) traduce la storia `id` della CSC legata. Se la CSC è trovata con la versione scritta e
  non ha una storia `id`, `bcdd` segnala **E31**. La storia tradotta non ha `GIVEN` né `EXPECT`: il suo esito
  atteso è quello della storia che traduce. I suoi passi seguono G21; i loro elementi sono asserzioni a parole
  (`VERBAL`) e usi delle estensioni di `KIND SCENARIO-FORM` e `LEVEL VERIFICATION` (sezione 4.14). Un passo con
  un elemento di altro tipo non è riconosciuto. E12 e le ripetizioni (G47) valgono come nelle altre storie.
- Una `VERIFICATION` non contiene promesse né presupposti: in una `VERIFICATION` una `GUARANTEE` o un'`ASSUME` non
  sono riconosciute. Il blocco non ha uno stato, non compare nella sezione 4 del rapporto e `ratify` lo rifiuta
  (sezione 12).
- `bcdd` calcola la **copertura** del piano dalle righe `OBSERVES` e la scrive come tabella nella sezione 13 del
  rapporto (sezione 9.6). La tabella non si scrive nel file.
- Il nome indicato nell'intestazione non entra nell'elenco dei nomi dei blocchi del file.

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
  `STATUS` (al più uno: E10 se ripetuto), in qualunque ordine. In un `PROFILE` `IMPORT PROFILE` non è
  riconosciuto: un profilo non importa altri profili. Come ogni riga che comincia con `IMPORT` e non è
  riconosciuta, la riga `IMPORT PROFILE` non chiude la zona d'intestazione (sezione 4.2): uno `STATUS` che la segue
  vale ancora come stato del profilo.
- Il corpo contiene soltanto blocchi `EXTENSION`. Ogni altra dichiarazione (`TYPE`, `DEFINE`, `GUARANTEE`, …) non è
  riconosciuta.
- Il nome del profilo entra nell'elenco dei nomi dei blocchi del file: per un profilo e una CSC con lo stesso nome
  nello stesso file `bcdd` segnala E01.
- Lo `STATUS` del profilo vale per tutte le sue estensioni, che non hanno uno `STATUS` proprio. `ratify` approva il
  profilo intero (sezione 12).
- **Un'`EXTENSION` fuori da un `PROFILE`** (fuori da ogni blocco, in una CSC, in un'entità, in un `BINDING` o in una
  `VERIFICATION`): `bcdd` segnala **E32** sulla parola `EXTENSION`. La riga apre comunque un blocco, che termina con
  il suo `END` (G3). Le righe del blocco non sono riconosciute e i loro nomi non sono registrati, come nel blocco
  ritirato della sezione 4.8. Il suo `END` non chiude il blocco che lo contiene.

**Un'estensione.** Fra la riga `EXTENSION Nome` e il suo `END` stanno i campi, in qualunque ordine, ciascuno al più
una volta. Sono obbligatori `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `VERIFY` e `SOURCE`; `REDUCES TO` è
facoltativo. Ogni altra dichiarazione non è riconosciuta. Controlli eseguiti da `check`:

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
| `REDUCES TO` nomina una parola che non appartiene al linguaggio e non è né un parametro dell'estensione né un'altra estensione dello stesso profilo (le unità `s` e `ms` dopo un numero fanno parte del numero, G27, e non sono nomi) | **E35** `REDUCES TO nomina X: non è una parola del linguaggio, un parametro né un'estensione del PROFILE P` |
| le estensioni dello stesso profilo si nominano a vicenda in modo circolare con `REDUCES TO` | **E35** `REDUCES TO in modo circolare: A -> B -> A`, sul membro del ciclo che compare per primo nel file |
| `REDUCES TO` ripete una forma che il linguaggio possiede già (definizione sotto la tabella) | **E36** `l'EXTENSION X ripete una forma che il linguaggio ha già: F`, oppure `l'EXTENSION X ripete l'EXTENSION Y` |

**La ripetizione di una forma (E36).** `bcdd` segnala E36 quando `REDUCES TO`, tolte le parentesi intorno a un
solo elemento, è:
- un solo costrutto delle regole G55-G63: un pattern, un ambito, una funzione, una storia, una fase, `IF`, un
  operatore come `NOT`, `AND`, `+`, `<=`; oppure
- un solo uso di un'altra estensione.

In entrambi i casi tutti gli operandi e i posti devono essere parametri dell'estensione, ciascuno una sola volta e
in qualunque ordine, anche quando il costrutto comincia con un posto. Esempi: `p PRECEDES q`, `(p) PRECEDES q`,
`x REQUIRES c`, `ABS(x)`, `MAX(x, y)`, `COUNT(p) IN LAST d`, `requested(x)`, `NOT c`, `x + y`,
`(IF c THEN a ELSE b)`. Nel messaggio `F` è la prima parola o il simbolo del costrutto, per esempio `NEVER`,
`PRECEDES`, `FOR AT LEAST`, `ABS`, `COUNT`, `requested`, `NOT`, `+`, `IF`. Due estensioni con la stessa
riduzione, salvo i nomi dei parametri, non sono segnalate (sezione 14).

- **`FORM`** è normativo: il testo della stringa si divide in elementi secondo le regole della sezione 2. Una
  parola uguale a un nome di parametro è il **posto** di quel parametro; ogni altro elemento è **fisso**. La prima
  parola è il nome dell'estensione.
- **`PARAMS`**: ogni parametro ha un tipo (G13) o una **categoria**: `Name` (un nome dichiarato), `Type` (un tipo),
  `Event` (un evento, G62), `Condition` (un'espressione `Boolean`), `Expression` (un'espressione), `Duration` (una
  durata con unità: è il tipo `Duration`), `Property` (una proprietà completa, G55). Un tipo non dichiarato è
  ammesso e compare nella sezione 6. I nomi dei parametri valgono solo nell'estensione; due parametri con lo
  stesso nome sono E01.
- **`REDUCES TO`** (`RiduzioneEst` in G54) si legge secondo il `KIND`: una proprietà (G55) per `PATTERN`,
  `DECLARATION` e `RELATION`; un ambito (G56) per `SCOPE`; un'espressione (G59) per `FUNCTION`; uno o più elementi
  di passo (G22), separati da virgole, per `SCENARIO-FORM`.
- I parametri vi compaiono al posto di nomi, eventi, espressioni o proprietà, secondo la loro categoria. Un
  parametro di categoria `Event` è ammesso dove è ammesso un evento; uno di categoria `Property` dove è ammessa
  una proprietà completa (G55); uno di categoria `Type` dove è ammesso un tipo; ogni altro dove è ammesso un
  `Primario` (G60). La forma `X REQUIRES c` è ammessa: E27 sulla `GUARANTEE` vale per le righe contrattuali, non
  per le riduzioni. `check` controlla i nomi (E35) e la forma; non controlla i tipi, che dipendono dagli argomenti
  di ogni uso.
- Una riduzione che non rispetta la sua regola non è riconosciuta. Il campo conta come presente (niente E33), ma per
  il grado dei suoi usi l'estensione si considera priva di `REDUCES TO` (sezione 4.14), e su di essa E36 non si
  controlla.
- E35, invece, si controlla prima della forma, su ogni riga `REDUCES TO`: un nome inesistente è un errore certo
  qualunque sia la forma, e la riga con E35 resta riconosciuta (sezione 8). Così per
  `REDUCES TO EVENTUALLY p WITHIN 1 min` `bcdd` segnala E35 su `min`, e per `WITHIN d s` (con `d` parametro)
  segnala E35 su `s`: un'unità è tale solo dopo un numero sulla stessa riga (G27).
- **`VERIFY`** (G46): `V1` elenca i controlli in grado di trattare la forma; `V2` indica che cosa conta come
  osservazione. In alternativa, `BY JUDGEMENT` o `BY INSPECTION` con la loro stringa. Il `;` fra le due parti è un
  simbolo (L5).
- **Le regole a giudizio** sulle estensioni sono voci della sezione 14 del rapporto (sezione 9.7), mai errori: il
  significato non deve descrivere la realizzazione né attribuire autorità o precedenza fra le parti; un'estensione
  senza `REDUCES TO` non deve ripetere una forma che il linguaggio possiede già; `MEANING` e
  `REDUCES TO` devono esprimere lo stesso contenuto.
- Un'estensione con almeno un errore E33-E36 nel suo file non si può usare: un blocco che la importa tratta le righe
  che la usano come righe con un profilo non trovato (sezione 4.14).

#### Le righe

Le righe di questi blocchi sono riconosciute, commenti, vuote o non riconosciute come in ogni altro blocco. Nella
riga `blocchi:` del rapporto un `BINDING`, una `VERIFICATION` e un `PROFILE` contano come blocchi; un'`EXTENSION`
no, perché appartiene al suo profilo. Per un file che contiene solo blocchi `BINDING`, `VERIFICATION` o `PROFILE`
`bcdd` non segnala E11.

Nessun blocco del linguaggio resta non letto. La sezione 11 del rapporto, che elencava i blocchi non letti, è
stata eliminata, e il suo numero non è riutilizzato.

### 4.12 Le formule

Una **formula** è una proprietà scritta in una forma che `bcdd` legge integralmente (G55): un ambito facoltativo e
un pattern, con le espressioni che li compongono. Sta dopo i due punti di una `GUARANTEE` o di un'`ASSUME` (G17);
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
elementi rispettano G55 e non contiene altro. Alcune alternative della grammatica si decidono esaminando l'elemento
successivo:
- dopo `FOR` segue `ALL` (quantificazione) oppure `AT LEAST` (G57);
- dopo `IN` segue `LAST` (G61), `{` (insieme di valori) oppure, in `FOR ALL i IN T`, il nome di un tipo;
- fra parentesi, se al primo livello compare `WITH`, il contenuto è un evento con filtro (`(frame WITH ch = L)`);
  altrimenti è un'espressione;
- un nome seguito da `(` e da `Nome :` è una chiamata di una `DEFINE` con parametri (G63);
- un nome uguale a quello di un'estensione di `KIND FUNCTION` di un profilo importato è un uso di quell'estensione
  (sezione 4.14);
- un nome uguale a quello di un'estensione di `KIND PATTERN` o `SCOPE` di un profilo importato, nella posizione di
  un pattern o di un ambito, è un uso di quell'estensione.

**Precedenza**, dal legame più forte al più debole:

| Livello | Operatori | Associatività e note |
|---|---|---|
| 1 | `x[i]`, `x.campo` | da sinistra |
| 2 | `^` | **nessuna**: per `a ^ b ^ c` `bcdd` segnala E26 |
| 3 | `-` davanti a un valore | da destra |
| 4 | `*`, `/` | da sinistra |
| 5 | `+`, `-` | da sinistra |
| 6 | `=`, `<>`, `<`, `<=`, `>`, `>=`, `IN` | **nessuna**: per `a <= b <= c` `bcdd` segnala E26 |
| 7 | `NOT` | da destra |
| 8 | `AND` e `OR` | ripetizione ammessa se l'operatore è lo stesso (`a AND b AND c`); per `AND` e `OR` mescolati senza parentesi `bcdd` segnala E26 |
| 9 | `IMPLIES` | **nessuna**: per `a IMPLIES b IMPLIES c` `bcdd` segnala E26 |
| 10 | `FOR ALL i IN T:` | il corpo si estende fino alla fine dell'espressione che lo contiene; dentro un'altra espressione sta fra parentesi |

Così `NOT a AND b` è `(NOT a) AND b`, `a AND b IMPLIES c` è `(a AND b) IMPLIES c`, `-x ^ 2` è `-(x ^ 2)` e
`x + y * 2` è `x + (y * 2)`. `e WITH c` assume come condizione tutta l'espressione che segue, fino a `SINCE`, a
`)`, a `:` o alla fine della formula. Per questo `TIME SINCE (frame WITH ch = L) > 5 s` si scrive con le parentesi:
senza di esse la condizione sarebbe `ch = L > 5 s`, un confronto in catena (E26). `IF … THEN … ELSE` sta sempre
fra parentesi: `DEFINE soglia := (IF notte THEN 10 ELSE 30)`; senza parentesi la riga non è riconosciuta.

**`IN LAST` ha precedenza su ogni operatore.** La durata di `COUNT( … ) IN LAST d` è un `Postfisso` (G61): un numero con
unità, un nome, una funzione, una chiamata o un'espressione fra parentesi. Così `ALWAYS COUNT(accendi) IN LAST 0.2 s
<= 1` è `(COUNT(accendi) IN LAST 0.2 s) <= 1`, e `COUNT(frame) IN LAST EVAL / (fs * EVAL)` divide il conteggio. Una
durata calcolata si scrive fra parentesi: `COUNT(e) IN LAST (2 * DURATA) > 3`.

**Una fase con il nome qualificato.** `Fase` (G62) ammette `Nome "." Nome` per le formule d'entità, dove il primo
nome è un connettore (sezione 4.9): `requested(Sessione.Abbina)`. Per una fase con il nome qualificato in una CSC
`bcdd` segnala **E20** con il messaggio della CSC (sezione 4.6), anche quando il primo nome è una richiesta della
CSC stessa. Dopo una fase, `WITH` è ammesso solo dove è ammesso un evento (G62) o dentro le parentesi di
`"(" Evento ")"`: `ALWAYS requested(Pulizie) WITH f = "x"` non è riconosciuta, come `ALWAYS e WITH c`.

**Errori di forma.** Se una formula letta integralmente da `bcdd` viola una regola del linguaggio, `bcdd` segnala
un errore e la dichiarazione resta riconosciuta, come con E13:

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
parentesi in più, `MIN(x)` con un solo argomento) non è riconosciuta e non comporta errori. Riga e colonna di E26 ed
E27 sono quelle della parola o del simbolo indicati. Per una formula con E26 o E27 `bcdd` non segnala E25: i tipi
di una formula di forma errata non si possono determinare con certezza. I nomi si controllano comunque (E24, E29).

**Le forme di BASE.** Nella specifica del linguaggio **BASE** è l'insieme delle abbreviazioni (manuale,
capitolo 23): `NEVER`, `AFTER`, `BEFORE`, `AFTER … UNTIL`, `BETWEEN … AND`, `PRECEDES`,
`FOR AT LEAST`, `ACCEPTS … ONLY WHILE`, `REQUIRES`,
`ENSURES`, `RESOLVES`, `ONCE`, `CHANGED`, `TRANSITION`, `FOLLOWS` (G11), gli indici (G11, G20), `FOR ALL` e
`REPEAT m..n` (G47). Il loro significato è la forma estesa del manuale. `check` le legge come forme autonome e ne
controlla nomi e tipi; non scrive la forma estesa. `TRANSITION s: A -> B ON e [WHEN c], …` è un'unica promessa su un
insieme chiuso di transizioni dello stato `s`: `s` è uno `STATE` con un elenco di valori come tipo, `A` e `B` sono
valori di quell'elenco, `e` è un evento, `c` una condizione.

**`FOR ALL i IN T`.** `T` è un tipo finito, come quello degli indici (sezione 4.3); altrimenti `bcdd` segnala
**E29**. `i` vale solo nel corpo e non deve essere un nome del blocco (E01). All'inizio di una formula (G55)
`FOR ALL` quantifica l'intera proprietà; dentro un'espressione (G59) quantifica la condizione che segue.

### 4.13 Nomi e tipi

`check` controlla in modo statico i **nomi** e i **tipi** delle formule, delle espressioni delle `DEFINE`, delle
dichiarazioni (G11) e dei valori delle storie. Non calcola alcun valore: determina che `COUNT(e)` è un intero, non
il suo valore.

**I nomi.** Un nome in una formula di una CSC è, nell'ordine:
1. una variabile di `FOR ALL` che lo contiene;
2. un parametro della `DEFINE` che lo contiene;
3. un parametro dell'evento di `e WITH c`, dentro `c`;
4. un nome del blocco (sezione 5);
5. il nome di un'estensione dei profili importati e trovati (sezione 4.14).

Se il nome non rientra in nessuno di questi casi e il blocco importa un profilo non trovato, la dichiarazione non è
riconosciuta, con il motivo (sezione 4.14). In tutti gli altri casi `bcdd` segnala **E24** `nome non dichiarato:
X`. Un nome scritto solo in una dichiarazione non riconosciuta (per esempio `EVENT IN pressione FACE utente`) non è
un nome del blocco (sezione 4.5): per una formula che lo usa `bcdd` segnala E24, come E03 per un passo. L'errore
indica la riga da correggere; la dichiarazione scritta in modo errato compare nella sezione 5 del rapporto. Ogni
posizione richiede un **genere**:

| Posizione | Genere richiesto | Errore se il nome è d'altro genere |
|---|---|---|
| un evento: `AFTER`, `BEFORE`, `UNTIL`, `BETWEEN … AND`, `ON`, `COUNT( … )`, `SINCE`, `TIME SINCE`, `LAST( … )`, `ONCE`, a sinistra di `WITH` | un `EVENT`, una `DEFINE EVENT` o una fase di una richiesta | **E24** `X non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY` |
| una richiesta: dentro una fase (`requested(X)` …), `ACCEPTS X`, `X REQUIRES`, `X ENSURES`, `RESOLVES X` | una `CAPABILITY` | **E24** `X non è una CAPABILITY` |
| uno stato: lo stato di `TRANSITION`, l'argomento di `PREV` e di `CHANGED` | uno `STATE` (anche con indice o con un campo) | **E24** `X non è uno STATE` |
| un valore o una condizione: ogni altra posizione | uno `STATE`, una `DEFINE` senza parametri, una variabile o un parametro, un valore di un elenco di valori, un evento (solo come condizione), un nome dato da un'estensione | **E24** `X è una CAPABILITY: si nomina con una fase (requested(X), …) o in ACCEPTS, REQUIRES, ENSURES, RESOLVES`, per una richiesta; per un tipo, una storia o un nome breve `bcdd` segnala `X non è un valore` |
| un campo: `x.c`, `LAST(e).c` | un campo del `Record` di `x`, o un parametro di `e` | **E24** `nome non dichiarato come campo di T: c` |
| una chiamata `nome(p: a, …)` | una `DEFINE` con parametri; ogni `p` un suo parametro, ciascuno una volta | **E24** `X non è una DEFINE con parametri`; `nome non dichiarato come parametro di X: p`; `manca l'argomento p nella chiamata di X`. Se un argomento ha un nome che non è un parametro, per la chiamata `bcdd` segnala solo quell'errore, senza «manca l'argomento»: un nome errato è un solo errore. Due argomenti con lo stesso nome sono E01 |
| un indice: `x[i]` | un valore del tipo dell'indice di `x`, o una variabile di `FOR ALL` su quel tipo | **E29** `indice di X non del tipo T: v`, anche quando `v` non è dichiarato: il messaggio indica che cosa serve |

Riga e colonna di E24 sono quelle del nome; con un nome qualificato (in un'entità, sezione 4.9) sono quelle di `X`.

**I tipi.** Ogni espressione ha un tipo: `Boolean`, `Integer`, `Real`, `Duration`, `String`, un elenco di valori, un
`Record`, `Sequence of T`, `Optional T`, oppure un tipo **non noto**. Un'espressione ha tipo non noto quando è:
- un nome di tipo non dichiarato o di tipo descritto a parole (G30);
- una costante `UNDECIDED`;
- un nome dato da un'estensione;
- in una formula d'entità, un elemento `X.y` di una CSC citata (sezione 4.9).

Un'espressione di tipo non noto è accettata in ogni posizione, e il risultato di un'operazione su di essa ha tipo
non noto: `check` segnala solo errori certi.

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
| `a + b`, `a - b` | `Integer` se entrambi sono `Integer`, `Real` se sono numeri, `Duration` se entrambi sono `Duration` |
| `a * b` | come `+` per due numeri; `Duration` per una durata e un numero, in qualunque ordine |
| `a / b` | `Real` per due numeri; `Duration` per una durata divisa per un numero; `Real` per due durate |
| `a ^ b`, `LOG10(a)` | `Real`; gli operandi sono numeri |
| `- a`, `ABS(a)` | il tipo di `a`, numero o durata |
| `ROUND(a)`, `FLOOR(a)`, `CEIL(a)` | `Integer`; l'operando è un numero |
| `MIN( … )`, `MAX( … )` | il tipo comune degli argomenti, tutti numeri o tutti durate |
| una chiamata `nome( … )` | il tipo dell'espressione della `DEFINE`; ogni argomento ha il tipo del suo parametro |
| un uso di un'estensione di `KIND FUNCTION` | il tipo del risultato in `PARAMS` |

| Posizione | Tipo richiesto |
|---|---|
| condizione: `WHILE`, `ALWAYS`, `EVENTUALLY`, `WHENEVER` e `THEN`, `NEVER`, le due parti di `PRECEDES`, la parte sinistra di `FOR AT LEAST`, `ONLY WHILE`, `REQUIRES`, `ENSURES`, `WHEN`, `WITH`, la condizione di `IF`, gli operandi di `NOT`, `AND`, `OR`, `IMPLIES`, il corpo di `FOR ALL` dentro un'espressione, il valore di una `DEFINE EVENT` | `Boolean` |
| durata: `WITHIN`, `IN LAST`, la parte destra di `FOR AT LEAST`, `RESOLVES … WITHIN` | `Duration` |
| `=` e `<>` | due operandi dello stesso tipo: due numeri, due durate, due stringhe, due `Boolean`, due valori dello stesso elenco; `Optional T` con `T` o con `ABSENT` |
| `<`, `<=`, `>`, `>=` | due numeri o due durate |
| `x IN {v, …}` | ogni `v` è un valore del tipo di `x` |
| `x[i]` | `x` ha un indice, e `i` è un valore o una variabile di `FOR ALL` del tipo dell'indice (E29) |
| `PRESENT(x)` | `x` di tipo `Optional` |

In ogni altra posizione un'espressione `Optional T` vale come `T`: `check` non verifica se il valore è presente.
Così, con `c` di tipo `Optional Campione` e `Campione` un `Record`, `c.L` è il campo `L` del record.

Per un'espressione di tipo errato `bcdd` segnala **E25** `tipo incoerente: serve A, trovato B`, con `A` e `B`
scritti come nella tabella (`Boolean`, `Duration`, `un numero`, `un numero o una durata`, il nome di un elenco di
valori, …; un evento in una posizione di valore si scrive `un evento`). Riga e colonna sono quelle del primo
elemento dell'espressione. Esempi: `EVENTUALLY accesa WITHIN 60` produce `tipo incoerente: serve Duration, trovato
Integer`; `ALWAYS COUNT(pressione)` produce `tipo incoerente: serve Boolean, trovato Integer`; `WHENEVER pressione
THEN fase = accesa`, con `accesa` di un altro elenco di valori, produce `tipo incoerente: serve Fase, trovato Modo`.

**I valori letterali.** I valori letterali (G26) si confrontano con i tipi dichiarati in `INITIAL` (G11), nel
`GIVEN` e nelle assegnazioni delle storie (G20), e negli argomenti degli eventi nei passi (G25):

| Tipo dichiarato | Valori ammessi |
|---|---|
| `Boolean` | `true`, `false` |
| `String` | una stringa |
| `Duration` | un numero con `s` o `ms` |
| `Integer [a .. b]` | un numero senza punto e senza unità, fra i limiti scritti (estremi inclusi; un limite omesso non pone vincoli) |
| `Real [a .. b]` | un numero senza unità, fra i limiti scritti |
| un elenco di valori `E` | un valore di `E` |
| `Optional T` | `ABSENT`, o un valore ammesso per `T` |
| `Record`, `Sequence of T` | nessuno: nei passi si scrive `_` |
| un tipo non noto | qualunque valore |

Per un valore non ammesso `bcdd` segnala **E25** `valore non del tipo T: V`, con `T` il tipo come è scritto nella
dichiarazione e `V` il valore come è scritto; riga e colonna sono quelle del valore. Per un nome che non è un valore
di alcun elenco di valori del blocco `bcdd` segnala E03 (sezione 4.4), senza aggiungere E25. `_` è sempre ammesso
negli argomenti. In una storia d'entità vale la regola della sezione 4.6.

### 4.14 L'uso delle estensioni

Un blocco usa soltanto le estensioni dei profili che importa nella propria zona d'intestazione (sezione 4.2). Per il
blocco, un'estensione di un profilo non importato non esiste, anche se il profilo sta nello stesso file.

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
`BINDING`, `VERIFICATION` in una `VERIFICATION`. Per un'estensione usata in un blocco di un altro livello, o in una
posizione di un altro `KIND`, `bcdd` segnala **E37** `X ha LEVEL L: non si usa in un blocco B` oppure `X ha KIND K:
non si usa in questa posizione`.

**Come si legge un uso.** Gli elementi che seguono il nome si confrontano con il `FORM`:
1. ogni elemento fisso del `FORM` deve comparire, identico;
2. ogni posto di un parametro prende un argomento, che si estende fino all'elemento fisso successivo del `FORM`;
3. per l'ultimo posto l'argomento si estende fino alla fine della posizione: la fine della formula, della
   dichiarazione o dell'elemento di passo. Dentro parentesi termina alla `)` o alla `,` dello stesso livello che
   chiude o separa il contenuto in cui sta l'uso.

Così `MAX(SQ r, 1.0)` e `(SQ r) > 1.0` sono letti come previsto, mentre in `SQ r > 1.0` l'argomento di `SQ` è
`r > 1.0`. Un `FORM` di `KIND FUNCTION` che termina con un elemento fisso (`"NEAR ( x , a , t )"`) non ha questo
problema.

L'argomento deve essere della categoria o del tipo del parametro:

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

Per un uso che non rispetta il `FORM` `bcdd` segnala **E37** `uso di X che non rispetta FORM "F"`, sul nome; per
un argomento di una categoria errata segnala E24 o E25, come in una formula. Esempio, con il profilo `Segnale`
della sezione 4.11 importato dal blocco: `GUARANTEE g10: WHILE modo = spenta: FADE luminosita WITHIN 2 s` usa
`FADE`, con `s` = `luminosita` e `d` = `2 s`.

**I nomi dichiarati da un'estensione.** In un uso di `KIND DECLARATION` (per esempio `SIGNAL needle[Ch] : Real
[0.0 .. 1.0]`, con `FORM "SIGNAL nome[I] : T"`), l'argomento del primo posto `Name` è un nome nuovo del blocco.
Entra nell'elenco dei nomi (E01 se ripetuto) e si usa nelle formule come valore o come condizione, con tipo non
noto, con o senza indice; `check` non controlla il tipo dei suoi usi. Non è un evento né una richiesta.

Per un uso di `KIND DECLARATION` che non rispetta il `FORM` `bcdd` segnala E37 sul nome dell'estensione. La
dichiarazione resta riconosciuta (sezione 8) ma non registra alcun nome, perché non è possibile stabilire quale
elemento sia il nome. Per ogni uso di quel nome `bcdd` segnala E24, come per un nome scritto solo in una
dichiarazione non riconosciuta (sezione 4.13). Per il nome di un'estensione di `KIND PATTERN`, `SCOPE` o
`FUNCTION` usato come prima parola di una dichiarazione `bcdd` segnala E37 `X ha KIND K: non si usa in questa
posizione`, e la dichiarazione resta riconosciuta.

**Il grado.** Le estensioni usate da una formula sono tutte quelle che vi compaiono, anche dentro l'argomento di un
altro uso (`DURING (NEAR r TO 1.0): …` usa `DURING` e `NEAR`). A queste si aggiungono quelle usate, a qualunque
profondità, dalle `DEFINE` che la formula nomina (costanti, chiamate, `DEFINE EVENT`): con `DEFINE K := SQ r`,
`ALWAYS K > 0.0` usa `SQ`. Questo insieme determina il grado, la sezione 15 del rapporto (sezione 9.7) e lo stato
(punto 0a della sezione 7.1). Una formula che usa almeno un'estensione senza `REDUCES TO` riconosciuta ha grado
**estensione dichiarata**; se tutte le estensioni che usa hanno una `REDUCES TO` riconosciuta, ha grado
**formale** (sezione 6).

**Gli usi non letti da `bcdd` 1.0-beta.** `bcdd` 1.0-beta non legge gli usi delle estensioni di `KIND RELATION` e
`KIND SCENARIO-FORM`. Una dichiarazione d'entità che comincia con il nome di un'estensione `RELATION`, e un passo
con un elemento che è un uso di un'estensione `SCENARIO-FORM`, non sono riconosciuti e compaiono nella sezione 5
del rapporto (con `--strict`, codice d'uscita 3). Questi usi non dichiarano nomi, quindi non provocano errori
nelle righe successive (sezione 14).

**Un profilo non trovato.** Il caso riguarda un blocco che importa un profilo che `bcdd` non trova (sezione 4.2),
oppure un profilo con un'estensione che ha errori nel suo file. Una dichiarazione del blocco che contiene un nome
non attribuibile in altro modo **non è riconosciuta**. Il nome è uno di quelli per cui, secondo la sezione 4.13, `bcdd` segnalerebbe E24,
o la prima parola di una dichiarazione che nessuna regola della sezione 4 accetta. Il motivo compare nella sezione
5 del rapporto: ` (profilo P VERSION v non trovato)` oppure ` (EXTENSION X del PROFILE P con errori)`. Non è un
errore: il nome potrebbe provenire proprio da quel profilo, e un errore si segnala solo quando è certo. Con
`--strict` la riga fa terminare `bcdd check` con codice d'uscita 3.

**Lo stato.** Una riga contrattuale che usa un'estensione di un profilo **da approvare** è da approvare, anche in una
CSC approvata (sezione 7.1).

**Totale delle regole:**
- 13 regole delle parole (L1-L13);
- 5 regole di divisione (U1-U5);
- 64 regole delle dichiarazioni (G1-G64, con G12a e le varianti G20e, G23e, G24e delle storie d'entità).

Collocazione: G30, G37, G41 e G42 nella sezione 4.4; G36 e G47 nella 4.6; G31-G35 nella 4.9; G38 nella 4.10; G39
nella 4.2; G40, G43-G46 e G48-G54 nella 4.11; G55-G64 nella 4.12. G2 serve solo al rapporto di un blocco ritirato e
G29 non è più in uso (sezione 4.8); la numerazione è conservata.

---

## 5. Dove vale ogni dichiarazione

Una dichiarazione corretta nella forma ma collocata nel posto sbagliato non è riconosciuta.

| Dove | Che cosa vi è riconosciuto | Note |
|---|---|---|
| **Fuori da un blocco** | G1, G31, G40, G48, G49 | per `END` `bcdd` segnala E08; per una dichiarazione che comincia con `REFINEMENT` segnala E15, e la dichiarazione apre un blocco ritirato (sezione 4.8); per una che comincia con `EXTENSION` segnala E32 (sezione 4.11). Ogni altra dichiarazione non è riconosciuta |
| **Dentro `CSC … END`** | G3, G4, G6, G7, G8, G11, G12, G16, G19, G21, G30, G37, G39, G41, G47, usi delle estensioni di `KIND DECLARATION` e `LEVEL CSC` | vedi le tre righe seguenti. Una dichiarazione che comincia con `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` o `PROFILE` chiude la CSC con E07; per una che comincia con `EXTENSION` `bcdd` segnala E32. In una CSC G32, G33 e G34 non sono riconosciute. Per un nome qualificato in una storia `bcdd` segnala E20 (sezione 4.6) |
| — `STATUS`, `IMPORT PROFILE` | in qualunque punto della zona d'intestazione, in qualunque ordine rispetto a `PURPOSE` (sezione 4.2); `STATUS` al più una volta | per un secondo `STATUS` nella zona `bcdd` segnala E10; dopo la zona non sono riconosciuti |
| — `PURPOSE` | esattamente uno per CSC | se manca o è ripetuto: E10 |
| — passi `@` e `REPEAT` | solo dopo una riga che comincia con `SCENARIO`, anche se questa non è riconosciuta. Fra `SCENARIO` e un passo possono stare solo altri passi, righe `REPEAT` (G47), commenti e righe vuote | ogni altra dichiarazione chiude la storia; una riga `REPEAT` fuori da una storia non è riconosciuta |
| **Dentro `BINDING … END`** | G3, G4, G39 nella zona d'intestazione, G51, usi delle estensioni di `KIND DECLARATION` e `LEVEL BINDING` | sezione 4.11. `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono il blocco con E07; per `EXTENSION` `bcdd` segnala E32 |
| **Dentro `VERIFICATION … END`** | G3, G39 nella zona d'intestazione, G52, G53 con i suoi passi G21 e le righe G47, usi delle estensioni di `KIND DECLARATION` e `LEVEL VERIFICATION` | per `STATUS`, in qualunque punto, `bcdd` segnala E39; per il resto come in un `BINDING` |
| **Dentro `PROFILE … END`** | G3, G4 e G6 nella zona d'intestazione, G50 che apre un'estensione | ogni altra dichiarazione non è riconosciuta. `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono il profilo con E07 |
| **Dentro `EXTENSION … END`** (in un profilo) | G3, G43, G44, G45, G46, G54 | ogni altra dichiarazione non è riconosciuta. `CSC`, `ENTITY`, `REFINEMENT`, `BINDING`, `VERIFICATION` e `PROFILE` chiudono l'estensione e il profilo, con un E07 sul profilo |
| **Dentro un blocco ritirato** (`REFINEMENT …` fino a `END`) | solo G3 | ogni altra dichiarazione non è riconosciuta e non registra nomi. `CSC`, `ENTITY` e `REFINEMENT` chiudono il blocco con E07 (sezione 4.8) |
| **Dentro `ENTITY … END`** | G3; G4 solo con `STATUS HYPOTHESIS`; G39 nella zona d'intestazione; G6, G32, G33; una sola G28; G34; G16 con `GUARANTEE` (con qualunque `STATUS`, come nella CSC, e con le formule della sezione 4.9); G19, G21 e G47 con i nomi qualificati (sezione 4.6); G38 (sezione 4.10); usi delle estensioni di `KIND RELATION` e `LEVEL ENTITY` | vedi le sei righe seguenti. `OFFERS` e `USES` in qualunque punto. Le parole chiave che aprono un blocco chiudono l'entità con E07, come nella CSC; per `EXTENSION` `bcdd` segnala E32 |
| — segmenti `VARIANT` | da una riga G38 alla successiva o a `END`: G32, G33, una G28 per segmento, G34, G16 con `GUARANTEE`, G19 e G21 | per `PURPOSE` `bcdd` segnala E21; gli altri casi sono nella sezione 4.10. In un blocco `CSC`, per una dichiarazione che comincia con `VARIANT` `bcdd` segnala E21 |
| — `STATUS` | solo `STATUS HYPOTHESIS`, in qualunque punto della zona d'intestazione (sezione 4.9); per un secondo `STATUS HYPOTHESIS` nella zona `bcdd` segnala E10 | ogni altro `STATUS` non è riconosciuto e non comporta E04, compresi `STATUS RATIFIED BY D-n` valido e `STATUS RATIFIED` senza decisione. Lo stato del blocco resta `senza STATUS`, perché l'intestazione di un'entità non è mai approvata. **In una `GUARANTEE`** valgono gli `STATUS` della CSC: `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-n`, e `STATUS RATIFIED` senza decisione con E04 (la promessa resta riconosciuta e da approvare) |
| — `PURPOSE` | esattamente uno per entità | se manca o è ripetuto: E10 |
| — parti G34 | in qualunque punto dell'entità, anche senza `COMPOSED OF` | ogni dichiarazione che rispetta G34 è una parte. `COMPOSED OF` si scrive una sola volta, in un punto qualsiasi; una seconda non è riconosciuta e non ha effetto. Le regole, la motivazione e i casi limite sono subito sotto la tabella |
| — `SCENARIO`, passi `@` | riconosciuti con G19, G21 e le varianti G20e, G23e, G24e (sezione 4.6) | come nella CSC: i passi solo dopo una riga che comincia con `SCENARIO`; fra i due possono stare solo altri passi, commenti e righe vuote |
| — `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` | **non** riconosciute; `bcdd` segnala l'**errore E18** sulla parola chiave, qualunque sia il seguito | un'entità non ha elementi propri. Queste dichiarazioni non registrano alcun nome, nemmeno `ASSUME` con intestazione della riga valida né `DEFINE Nome :=`, e non compaiono nella sezione 2. Le righe `VERIFY` e `VERBAL` che continuano un'`ASSUME` (U4) restano non riconosciute con essa, senza un altro E18. I casi di confine sono sotto la tabella |

**L'errore E18.** Un'entità non ha `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `TYPE` né `ASSUME` propri: `bcdd`
riconosce la parola chiave e rileva che è fuori posto, quindi segnala un errore, come per E15. Casi di confine:
- `ASSUME` con intestazione della riga non valida (`ASSUME : …`), o con una proprietà scritta come formula: E18,
  perché basta la parola chiave all'inizio della dichiarazione;
- `assume` in minuscolo non è la parola chiave (sezione 2.2): resta non riconosciuta, senza E18;
- in un blocco ritirato non c'è E18: ogni dichiarazione è non riconosciuta (sezione 4.8);
- in un'entità con intestazione non valida (E09) E18 si applica ugualmente: il blocco si apre comunque;
- per un `DETAILS` che indica il nome breve di un'`ASSUME` con E18 `bcdd` segnala E02: l'`ASSUME` non registra il
  suo nome breve;
- `SCENARIO` e i passi non comportano E18: un'entità ha storie.

Ciò che una promessa dell'entità dà per scontato sull'altro lato di un confine si scrive come presupposto
(`ASSUME`) nella CSC di quel confine. Una promessa dell'entità si scrive come `GUARANTEE` dell'entità o nella CSC
che l'entità offre.

**Le parti di un'entità.** In un'entità **ogni dichiarazione che rispetta G34 è una parte, in qualunque posizione si
trovi**: prima o dopo `COMPOSED OF`, fra le promesse, dopo `OFFERS` e `USES`, dopo righe non riconosciute, dopo una
seconda `COMPOSED OF`, e anche in un'entità che non ha `COMPOSED OF`. Le parti non formano un elenco con un inizio
e una fine: si scrivono in qualunque punto, come `OFFERS` e `USES`.

- **`COMPOSED OF`** (G28), l'elenco delle parti, si scrive una sola volta e dichiara che l'entità è composta di
  parti. `bcdd` non ne ha bisogno: una parte senza `COMPOSED OF` è controllata come le altre. Motivazione: ogni
  parte scritta correttamente deve essere controllata. Se `COMPOSED OF` fosse obbligatoria, dimenticarla
  sottrarrebbe al controllo tutte le parti dell'entità. Segnalare invece un errore per una parte senza
  `COMPOSED OF` significherebbe segnalarlo su una riga che `bcdd` legge per intero e controlla comunque.
- **Una seconda `COMPOSED OF`** non è riconosciuta e non ha alcun effetto sulle parti. Non è un errore: la
  dichiarazione è corretta, ma ridondante.
- **Una dichiarazione che non rispetta G34** non è una parte: se non è un'altra dichiarazione dell'entità
  (tabella sopra), non è riconosciuta. Non registra alcun nome e non viene cercata; non compare sotto l'entità né
  nella sezione 7; non conta fra le parti non trovate (quindi non sospende E14); non modifica la lettura delle
  altre dichiarazioni. Ne sono esempi: `pulsante-uno : Pulsante`, `p : X VERSION v1`, `pulsante Pulsante`,
  `pulsante uno : X`, `pulsante := X`, `"pulsante" : X`, `FOO bar`, `offers Luce`, `OFFERS : Pulsante`,
  `VERSION 0.1`, `LINK a b`, `END X`, e `VERIFY` o `VERBAL` dopo una parte (U4: continuano solo una
  `GUARANTEE` o un'`ASSUME`).

**Nessuna eccezione nascosta.** Una dichiarazione G34 in un'entità diventa sempre una parte controllata, e una riga
non riconosciuta non sottrae mai una parte al controllo. Motivazione: una dichiarazione è una parte se e solo se
(1) è una dichiarazione (sezione 3), (2) sta in un blocco `ENTITY` (sezione 5), (3) rispetta G34 e (4) il suo nome
non ha E01. Nessuna di queste quattro condizioni dipende dal riconoscimento di un'altra dichiarazione, salvo nei casi
seguenti. Ciascuno ha un segnale esterno alla sezione 5 oppure è escluso dalle entità per definizione:

| Caso | Che cosa succede | Segnale |
|---|---|---|
| il testo `p : X` sta **dentro una stringa** che continua su più righe | non è una dichiarazione (L2, U3): è testo | nessuno, per principio: una stringa può contenere qualunque testo. Con una sola virgoletta in più o in meno nel file, le virgolette fuori dai commenti sono in numero dispari e `bcdd` segnala E06. Un tratto di righe diventa una stringa senza errori solo con **due** virgolette errate. Limite noto |
| il nome della parte è ripetuto, o è il nome breve di una promessa (anche di una promessa non riconosciuta con intestazione della riga G16 valida, sezione 4.5) | la parte non viene cercata | **E01**, codice d'uscita 1 |
| un `END` da solo prima della parte | l'entità è terminata: la riga è fuori da un blocco | se segue l'`END` dell'entità, **E08** |
| una riga `CSC`, `REFINEMENT` o `ENTITY` prima della parte | chiude l'entità e apre un altro blocco | **E07** (ed **E09** se l'intestazione non è valida; con `REFINEMENT`, **E15**) |
| una parte non trovata | sospende E14 per la sua entità | compare nella **sezione 7**, con il motivo se presente |
| `p : X` in una CSC o in un blocco ritirato | non è un'entità: la riga non è riconosciuta (una CSC non ha parti; un blocco ritirato non ha parti, sezione 4.8) | fuori dalle entità, per definizione |

Resta un solo caso: un'entità in cui nessuna riga è una parte. Non ha voci nella sezione 8 né errore E14, e senza
`--strict` una riga non riconosciuta non cambia il codice d'uscita.

Altre regole sui blocchi:
- `END` deve occupare da solo la riga; dopo `END` è ammesso un commento. `END` seguito da altro non è
  riconosciuto e il blocco resta aperto.
- Una dichiarazione che comincia con `CSC`, `REFINEMENT`, `ENTITY`, `BINDING`, `VERIFICATION` o `PROFILE` dentro un
  blocco aperto (anche dentro un'estensione, che si chiude con il suo profilo) chiude quel blocco con l'errore E07
  e ne apre uno nuovo.
- Un'intestazione di blocco non valida (errore E09) apre comunque il blocco: le righe seguenti si leggono
  normalmente e non diventano tutte non riconosciute. Vale per `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE` ed
  `EXTENSION` come per `CSC`. Una dichiarazione che comincia con `REFINEMENT` (E15) apre il blocco ritirato, che
  sia scritta correttamente o no (sezione 4.8).
- Un file può contenere più blocchi. I nomi dei blocchi `CSC`, `ENTITY` e `PROFILE` di un file non si ripetono,
  qualunque sia il tipo: per una CSC e un'entità con lo stesso nome nello stesso file `bcdd` segnala E01. Un blocco
  ritirato, un `BINDING` e una `VERIFICATION` non registrano il loro nome (il loro nome è quello della CSC legata).
- **Nomi in un'entità.** I nomi delle parti e i nomi brevi delle promesse e delle storie formano un solo elenco: un
  nome ripetuto è E01. I nomi delle righe `OFFERS` formano un elenco proprio, e così quelli delle righe `USES`.
- **Più versioni.** Per due righe `OFFERS` con lo stesso nome `bcdd` segnala E01 sulla seconda, **salvo** che
  entrambe scrivano `VERSION` e le versioni siano diverse come testo; lo stesso per `USES`. Quindi:
  - `OFFERS Pulsanti VERSION 0.1` e `OFFERS Pulsanti VERSION 0.2` sono ammesse;
  - `OFFERS Pulsanti VERSION 0.1` scritta due volte è E01;
  - `OFFERS Pulsanti` e `OFFERS Pulsanti VERSION 0.2` sono E01 sulla seconda, in qualunque ordine: la riga senza
    versione vale per ogni versione, quindi ripete l'altra.

  L'entità offre ciascuna versione per intero; nessuna riga stabilisce come le versioni coesistano. `OFFERS X` e
  `USES X` nella stessa entità sono ammessi (per esempio un apparecchio su un bus).
- **Con i segmenti `VARIANT`** (sezione 4.10), due parti con lo stesso nome, o due `OFFERS` (o due `USES`) con lo
  stesso nome, si controllano con le regole precedenti solo se sono **compatibili**, cioè se non stanno in due
  scelte diverse dello stesso gruppo. Esempio: `microfono` in `sensore = di` e in `sensore = microfono` è ammesso;
  `OFFERS X` fra le righe comuni e di nuovo in un segmento è E01. I nomi brevi di promesse e storie, e una parte con
  lo stesso nome di un nome breve, sono E01 in qualunque segmento. Il messaggio indica la prima riga del file che
  ha quel nome ed è compatibile con la riga dell'errore.
- **Una riga con E01 in un'entità** (una `OFFERS`, una `USES` o una parte) non offre e non usa nulla. Non viene
  cercata, non compare sotto l'entità né nelle sezioni 7 e 8, e non conta nella corrispondenza (sezione 9.4), né
  nel file controllato né nel blocco trovato di una parte. Fa sempre fede la prima riga con quel nome.
- La regola U4 vale anche nell'entità: `VERIFY` e `VERBAL` continuano una `GUARANTEE` o una `ASSUME` (e
  l'`ASSUME` resta non riconosciuta insieme alle sue continuazioni).
- Una `GUARANTEE` d'entità con intestazione della riga G16 valida e proprietà non `VERBAL` registra il suo nome
  breve ed è di grado `non riconosciuta`, come nella CSC; E13 vale anche nell'entità.
- I nomi dichiarati in un blocco valgono solo in quel blocco. In un blocco CSC, richieste, eventi, stati, costanti,
  tipi, promesse, presupposti, storie e i valori degli elenchi di valori condividono **un solo elenco di nomi**: per
  due elementi diversi con lo stesso nome `bcdd` segnala E01. I nomi dei parametri valgono solo nella loro riga.
- Una dichiarazione può nominare un elemento dichiarato più avanti nel blocco.

---

## 6. Il grado di una promessa

**Regola.** Il grado di una `GUARANTEE` o di un'`ASSUME` si ricava dalla sua forma; nessuna riga reca un'etichetta
di grado:

| Grado | Quando |
|---|---|
| `verbale` | la proprietà è `VERBAL "…"` con la sua verifica (G17), o `VERBAL "…"` senza verifica con l'errore E13 |
| `formale` | la proprietà è una formula riconosciuta (G55) che non usa estensioni, o usa solo estensioni con `REDUCES TO` |
| `estensione dichiarata` | la proprietà è una formula riconosciuta che usa almeno un'estensione senza `REDUCES TO` |
| `non riconosciuta` | la proprietà non è riconosciuta: una formula in una forma non prevista dalla sezione 4.12, oppure una riga con un nome che potrebbe essere definito solo da un profilo non trovato (sezione 4.14). Il nome breve è registrato, se l'intestazione della riga è valida |

Una formula con un errore (E24-E30, E37) resta riconosciuta e ha il suo grado: la forma è stata letta, e l'errore
segnala il nome o il tipo errato.

**Il significato di «formale».** Il grado indica come la promessa si potrà verificare, non che sia stata
verificata. `check` legge la formula e ne controlla forma, nomi e tipi. Non la valuta rispetto alle storie e non
controlla che le promesse siano coerenti fra loro né con i dettagli. Il rapporto elenca questi controlli come «non
eseguiti» (sezione 9.7). Un esito non afferma più di quanto è stato effettivamente controllato.

**Motivo per cui il nome breve resta anche in una riga non riconosciuta.** Se il nome breve non fosse registrato,
per un dettaglio di quella riga (`GUARANTEE g5 DETAILS g1`) `bcdd` segnalerebbe E02 (`DETAILS nomina un id che non è
una GUARANTEE né una ASSUME di questa CSC: g1`), un errore infondato. Inoltre due righe con lo stesso nome breve non
comporterebbero E01.

**Una formula su più righe** si scrive lasciando la riga aperta (U5): `WHENEVER pressione THEN` a fine riga e
`accesa WITHIN 1 s` sulla riga successiva formano una sola dichiarazione. Una riga che comincia con `THEN` non
continua la precedente: apre una nuova dichiarazione (U2), e la formula risulta non riconosciuta.

## 7. Righe approvate e righe da approvare

La sezione 7.1 definisce lo stato di ogni riga contrattuale. Le sezioni 7.2-7.4 trattano la nuova versione di una
CSC (7.2), i livelli di `DETAILS` (7.3) e la sostituzione di una riga (7.4).

### 7.1 Lo stato effettivo di una riga

Ogni riga contrattuale (una `GUARANTEE` o `ASSUME` con intestazione della riga riconosciuta) ha uno **stato
effettivo**: approvata o da approvare. Lo stato si determina con le regole seguenti, applicate in quest'ordine:

0. se la riga si trova in un blocco (CSC o entità) la cui intestazione non è valida (non rispetta G1 o G31: errore
   E09), è **da approvare**, qualunque sia lo `STATUS` della riga e dell'intestazione;
1. se la riga ha un proprio `STATUS RATIFIED BY D-nnn` valido, è **approvata**;
2. se la riga ha un proprio `STATUS HYPOTHESIS`, o un `STATUS RATIFIED` senza decisione valida (errore E04), è
   **da approvare**;
3. se la riga non ha `STATUS` ed è un dettaglio (`DETAILS`), è **da approvare**: un dettaglio non eredita
   l'approvazione della CSC;
4. altrimenti vale lo `STATUS` dell'intestazione della CSC: approvata se è `RATIFIED BY D-nnn` valido; **da
   approvare** in ogni altro caso, anche senza `STATUS`. A questo punto l'intestazione è sempre valida (punto 0).

Il punto 3 serve a evitare che un dettaglio aggiunto dopo l'approvazione di una CSC diventi approvato
implicitamente.

**Un profilo da approvare.** Prima del punto 1 vale il punto **0a**: una riga contrattuale che usa un'estensione di
un profilo trovato e **da approvare** (il suo `STATUS` non è `RATIFIED BY D-nnn` valido) è da approvare, qualunque
sia lo `STATUS` della riga e dell'intestazione. Il significato dell'estensione non è stato approvato, quindi non lo
è nemmeno la riga che lo usa. Approvato il profilo, la riga torna allo stato dei punti 1-4. Nel JSON lo `stato_di`
di questa riga vale `profilo`: lo stato non deriva dalla riga, dal dettaglio né dall'intestazione.

**Le altre righe con uno stato.** Le stesse regole valgono per:
- i dettagli di `DEFINE` e di `SCENARIO` (G12, G19 con `DETAILS`): sono sempre dettagli, quindi senza un proprio
  `STATUS` sono da approvare (punto 3). Una `DEFINE` o una storia senza `DETAILS` non ha uno stato proprio e non
  compare nella sezione 4 del rapporto;
- un `BINDING`: l'intestazione ha lo stato indicato dal suo `STATUS` (punto 4), e ogni riga `BIND` segue i punti
  0, 1, 2 e 4 (una riga `BIND` non ha `DETAILS`). In un `BINDING` con l'intestazione non valida (E09) tutte le
  righe sono da approvare (punto 0);
- un `PROFILE`: ha lo stato indicato dal suo `STATUS`; le sue estensioni non hanno uno stato proprio e seguono
  quello del profilo. Le estensioni di un profilo da approvare sono elencate nella sezione 4 del rapporto;
- una `VERIFICATION` non ha stato: non è mai approvata né da approvare, e non compare nella sezione 4.

Le righe da approvare sono elencate nella sezione 4 del rapporto («DA APPROVARE, NON CONTRATTO»). `check` non
approva mai: si limita a leggere.

**L'intestazione non valida (punto 0).** Un'intestazione che non rispetta G1 o G31 (errore E09, per esempio
`CSC Rotta VERSIONE 0.1`, `CSC Rotta 0.1` o `ENTITY Rotta VERSIONE 0.1`) non identifica né la CSC o l'entità né la
versione. Nessuna riga del blocco è quindi approvata, né quelle che seguono l'intestazione né quelle con un proprio
`STATUS RATIFIED BY D-nnn`. Il blocco si apre comunque (sezione 5) e gli `STATUS` restano riconosciuti e invariati:
corretta l'intestazione, ogni riga torna allo stato assegnato dai punti 1-4. La regola si applica al blocco che
contiene la riga, non all'intero file. I casi di confine:

| Caso | Stato effettivo | Motivo |
|---|---|---|
| CSC con E09 e `STATUS RATIFIED BY D-1`; riga senza `STATUS` e senza `DETAILS` | **da approvare**: nella sezione 4 del rapporto, `stato` `ipotesi` e `decisione` `null` nel JSON | punto 0 |
| la stessa CSC, riga con un proprio `STATUS RATIFIED BY D-2` | **da approvare**, nella sezione 4; `decisione` `null` | punto 0 |
| la stessa CSC, riga con `STATUS HYPOTHESIS`, o un dettaglio senza `STATUS` | da approvare | punto 0 (lo sarebbero anche per i punti 2 e 3) |
| CSC con E09 e `STATUS RATIFIED` senza `BY` (E04) | **tutte da approvare**; restano E09 ed E04 | punto 0 |
| CSC con E09, senza `STATUS` o con `STATUS HYPOTHESIS` | tutte da approvare | punto 0 |
| entità con E09 (`ENTITY Rotta VERSIONE 0.1`), anche con `STATUS RATIFIED BY D-1` | **tutte da approvare**, anche la promessa con un proprio `STATUS RATIFIED BY` | punto 0; le righe senza `STATUS` lo sarebbero comunque (in un'entità il punto 4 assegna sempre «da approvare») |
| due blocchi: il primo con E09 e `STATUS RATIFIED BY D-1`, il secondo valido con `STATUS RATIFIED BY D-5` | tutte da approvare nel primo; nel secondo valgono i punti 1-4 | la regola si applica all'intestazione del blocco della riga |
| intestazione valida con il nome già usato da un altro blocco (E01), e `STATUS RATIFIED BY` | approvata | E01 non rende l'intestazione non valida: G1 è rispettata. Il punto 0 vale solo per E09 |
| `--strict` | il codice d'uscita resta 1 (E09 è un errore) e la sezione 4 è quella senza `--strict` | lo stato effettivo non dipende da `--strict` (sezione 9.2, «Resto del rapporto con `--strict`»; sezione 10, «Che cosa prevale») |

Il punto 0 **non modifica**:
- la riga del blocco nel rapporto (`riga N: CSC (intestazione non valida), STATUS RATIFIED BY D-1`);
- nel JSON, lo `stato` e la `decisione` del blocco, che riportano lo `STATUS` scritto nell'intestazione e non lo
  stato effettivo delle righe;
- il numero degli errori, la riga `esito` e il codice d'uscita;
- le sezioni 2, 3, 5, 6, 7 e 8;
- i livelli di `DETAILS` (sezione 7.3).

Nel JSON il campo `stato_di` di ogni riga di un blocco con E09 vale `intestazione_non_valida`, qualunque cosa sia
scritta nella riga. `ratify` e `refine` non operano su un file con errori, quindi non incontrano mai una riga di
questo tipo.

**Il caso residuo** (limite noto, come quello della sezione 7.2). Se chi scrive corregge a mano un'intestazione non
valida, le righe che erano approvate prima che l'intestazione diventasse non valida tornano approvate senza
`ratify`, con i propri `STATUS RATIFIED BY` e con quello dell'intestazione. `check` legge un file alla volta e non
conosce il contenuto precedente; il caso si individua confrontando il file con la versione precedente.

**Le promesse di un'entità.** I punti 0, 1, 2 e 3 valgono come nella CSC. Il punto 4, in un'entità, assegna
**sempre «da approvare»**: l'intestazione di un'entità non è mai approvata (in un'entità `STATUS RATIFIED` non è
riconosciuto, sezione 5). Quindi una promessa d'entità è approvata se e solo se ha un proprio `STATUS RATIFIED BY
D-nnn` valido. Lo diventa solo con `bcdd ratify` (sezione 12), a condizione che i confini dell'entità siano stati
letti.

Esempio: in un'entità `Ratificata` che ha `STATUS RATIFIED BY D-1` come prima dichiarazione, lo stato del blocco è
`senza STATUS` e la riga `STATUS` compare nella sezione 5 del rapporto. La promessa `r1` (senza `STATUS`) è da
approvare; `r2` (`STATUS RATIFIED BY D-2`) è approvata; per `r3` (`STATUS RATIFIED` senza decisione) `bcdd`
segnala E04, e la promessa è da approvare.

Come nella CSC, `check` non può stabilire chi ha scritto uno `STATUS RATIFIED BY`. Se è scritto a mano, rende
approvata una promessa d'entità anche quando un suo confine non è trovato (la ricerca non modifica l'esito). La
regola è che `STATUS RATIFIED BY` non si scrive a mano (sezione 7.2); `ratify` la fa rispettare controllando i
confini (sezione 12.2, passo 7). Limite noto.

**Un esempio semplice** (il file è valido: `check --strict` termina con codice d'uscita 0):

```
CSC LuceScale VERSION 0.1
  STATUS RATIFIED BY D-135
  ...
  GUARANTEE g1: VERBAL "Una pressione accende la luce"
  GUARANTEE g1a DETAILS g1: VERBAL "Entro 1 secondo da una pressione la luce è accesa"
  GUARANTEE g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne da sola dopo DURATA_LUCE"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-200: VERBAL "Una pressione a luce accesa fa ripartire il tempo"
```

(Le righe `VERIFY` sono omesse per brevità e nel file completo sono presenti; `D-135` e `D-200` sono riferimenti
d'esempio.)

| Riga | Che cosa ha | Punto | Stato effettivo |
|---|---|---|---|
| `g1` | niente `STATUS`, niente `DETAILS` | 4: eredita dall'intestazione, che è `RATIFIED BY D-135` | approvata |
| `g1a` | niente `STATUS`, ma `DETAILS g1` | 3: un dettaglio non eredita | da approvare |
| `g2` | il suo `STATUS HYPOTHESIS` | 2 | da approvare, anche se l'intestazione è approvata |
| `g2a` | il suo `STATUS RATIFIED BY D-200` | 1 | approvata, anche se dettaglia una riga da approvare |

Con l'intestazione `STATUS HYPOTHESIS`, o senza `STATUS`, anche `g1` sarebbe da approvare (punto 4); `g2a`
resterebbe approvata (punto 1).

**Comandi che usano lo stato effettivo** (la regola è la stessa per tutti):

| Comando | Uso dello stato | Dove |
|---|---|---|
| `bcdd check` | elenca le righe da approvare nella sezione 4 del rapporto | sezione 9 |
| `bcdd ratify FILE ID D-nnn` | rifiuta una riga già approvata, anche quando lo è per eredità (punto 4); in un'entità rifiuta una promessa con un proprio `STATUS RATIFIED BY`. Un file con l'intestazione non valida ha E09, e `ratify` lo rifiuta prima di esaminare la riga (sezione 12.2): il punto 0 non modifica il comportamento di `ratify` | sezione 12 |
| `bcdd ratify FILE --all D-nnn` | modifica solo l'intestazione, se è da approvare, e le righe che restano da approvare dopo l'approvazione dell'intestazione (punti 2 e 3). Le righe del punto 4 seguono l'intestazione e non vengono modificate | sezione 12 |
| `bcdd refine` | può proporre di sostituire solo una riga da approvare; una riga approvata non si sostituisce mai | sezione 7.4 |

### 7.2 Una versione nuova di una CSC approvata

1. Una CSC approvata **non si modifica**. Per cambiarla si scrive una **`VERSION` nuova** nello stesso file, al
   posto della vecchia (lo stesso nome due volte nello stesso file è E01). L'intestazione ha `STATUS HYPOTHESIS`;
   un commento iniziale indica che cosa cambia e per quali decisioni.
2. Nella versione nuova:
   - una riga il cui testo **non cambia** conserva il proprio `STATUS RATIFIED BY D-mmm`, se lo aveva, e resta
     approvata con la decisione precedente;
   - una riga il cui testo **cambia** torna da approvare: se aveva un proprio `STATUS RATIFIED BY D-mmm`, chi scrive
     lo sostituisce con `STATUS HYPOTHESIS`. Una riga senza `STATUS` e senza `DETAILS` è già da approvare, perché
     segue l'intestazione (sezione 7.1, punto 4), e non occorre aggiungere `STATUS`. Segue lo stato
     dell'intestazione, come le altre righe che la seguono, anche quando l'intestazione viene approvata;
   - una riga nuova è da approvare: con `STATUS HYPOTHESIS`, o senza `STATUS` (sezione 7.1, punti 3 e 4).

   Finché la versione nuova non è approvata, il contratto in vigore resta la versione approvata precedente. Della
   versione nuova sono approvate solo le righe che non sono cambiate e hanno un proprio `STATUS RATIFIED BY`.
3. La versione nuova diventa approvata **solo** con `bcdd ratify FILE D-nnn` o `bcdd ratify FILE --all D-nnn`,
   indicando il riferimento della decisione di approvazione. `STATUS RATIFIED BY` non si scrive a mano.

Esempio: la luce delle scale approvata è `VERSION 0.1`. Per aggiungere il lampeggio si scrive:

```
-- VERSION 0.2 (D-nnn): lampeggio prima dello spegnimento. Da approvare.
CSC LuceScale VERSION 0.2
  STATUS HYPOTHESIS
  ...
```

Che cosa rileva `check`: l'intestazione `STATUS HYPOTHESIS`, e nella sezione 4 del rapporto le righe senza `STATUS`
(punto 4 della sezione 7.1), i dettagli senza `STATUS` e le righe con `STATUS HYPOTHESIS`. **Una riga con un proprio
`STATUS RATIFIED BY` resta approvata** anche nella versione nuova (punto 1 della sezione 7.1), come prescrive il
punto 2 sopra.

Esempio: la CSC della luce delle scale è approvata con `--all`. Ha quattro righe base (`g1`, `g2`, `g3`, `a1`),
senza `STATUS`, e sei dettagli (`g1a`…`g1c`, `g3a`…`g3c`), ciascuno con un proprio `STATUS RATIFIED BY`. Si porta
la CSC a `VERSION 0.2` con `STATUS HYPOTHESIS`, senza altre modifiche. Nella sezione 4 del rapporto compaiono le
quattro righe base, che seguono l'intestazione; i sei dettagli restano approvati.

**Il rischio residuo.** Se chi scrive cambia il testo di una riga e dimentica di portarla a `STATUS HYPOTHESIS`, la
riga resta approvata con un testo che chi approva non ha visto, e `check` non lo rileva (sezione 14). Il rischio si
evita confrontando il file con la versione precedente prima dell'approvazione; `bcdd` non esegue questo confronto.
`bcdd refine` non crea questo caso: non sostituisce mai una riga approvata (sezione 7.4).

**Un commento non fa parte del contratto.** La regola «una CSC approvata non si modifica» vale per ciò che si
approva: intestazione, dichiarazioni, righe contrattuali. Un commento (`-- …`) si può correggere senza una `VERSION`
nuova, se nessuna riga riconosciuta cambia.

`check` legge un file alla volta e non conosce la versione precedente: non può stabilire se una `VERSION` è nuova né
che cosa è cambiato. Il confronto fra due versioni si esegue con un sistema di controllo di versione, non con
`bcdd`.

### 7.3 I livelli di `DETAILS`

- Una **riga base** è una `GUARANTEE` o una `ASSUME` senza `DETAILS`: il suo **livello** è 0.
- Per `X DETAILS Y` il livello di `X` è quello di `Y` più 1.

Esempio, a partire da `g2` della luce delle scale (il file è valido):

```
GUARANTEE g2: …                      -- livello 0, riga base
GUARANTEE g2a DETAILS g2: …          -- livello 1
GUARANTEE g2a1 DETAILS g2a: …        -- livello 2
GUARANTEE g2a1a DETAILS g2a1: …      -- livello 3
```

| Comando | Trattamento dei livelli |
|---|---|
| `bcdd check` | **nessun controllo**: accetta `DETAILS` a qualunque livello, senza errori né avvisi, e il rapporto non mostra i livelli. Un file con righe di livello 3 o 4 supera `check --strict`, con codice d'uscita 0 |
| `bcdd refine` | **propone dettagli fino al livello 2**: una proposta che dettaglia una riga già di livello 2 o superiore è scartata, quindi una riga aggiunta da `refine` arriva al massimo al livello 2. Le sostituzioni (sezione 7.4) valgono a ogni livello. Le righe di livello superiore restano: `refine` non le modifica e non le dettaglia |
| `bcdd ratify` | nessuna limitazione: approva una riga di qualunque livello |

Il livello si calcola solo in un file senza E02 né E05, in cui ogni catena di `DETAILS` termina in una riga base.
`refine` opera solo su file senza errori, quindi si trova sempre in questa situazione.

### 7.4 La riga sostituita

`bcdd refine` può proporre di **sostituire** una riga da approvare (sezione 7.1) scritta a parole (`VERBAL`). La
riga attuale e quella nuova sono mostrate a chi scrive, che può accettare o scartare la proposta.

Che cosa resta e che cosa cambia quando la proposta è accettata:
- **resta invariato**, byte per byte, il tratto della prima riga della dichiarazione **dal primo carattere fino al
  primo `:` compreso**: il rientro, il tipo (`GUARANTEE` o `ASSUME`), il nome breve, il `DETAILS` e lo `STATUS`,
  spazi compresi. Il primo `:` è sempre quello dell'intestazione della riga: un nome breve, un nome e una decisione
  non contengono `:` (regole L7-L9), e l'intestazione della riga occupa sempre una sola riga (regola U2);
- **cambiano** il testo dopo `VERBAL` e la verifica; la riga `VERIFY` si allinea sotto `VERBAL`;
- **restano invariate** tutte le altre righe del file, compresi i dettagli della riga sostituita.

Esempio: `g2` della luce delle scale, riga base di una CSC con intestazione `STATUS HYPOTHESIS`:

```
prima:
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
dopo:
  GUARANTEE g2: VERBAL "La luce si spegne da sola fra 59 e 61 secondi dopo l'ultima pressione"
                VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
```

Resta `  GUARANTEE g2:`. Poiché lo `STATUS` non cambia, la riga resta da approvare. `g2` continua a ereditare lo
stato dall'intestazione: se questa viene approvata, anche `g2` lo è, come le altre righe. Un dettaglio
`g2a DETAILS g2` resta valido, perché il nome breve `g2` non cambia; `refine` lo elenca «da rileggere». Per `check`
la riga sostituita è una riga come le altre: `check` non distingue le righe sostituite.

---

## 8. Gli errori

Un errore è una costruzione che `bcdd` riconosce nella forma ma che viola una regola del linguaggio. Gli errori
sono quaranta (E01-E40). In questa sezione «Quando» descrive il caso in cui `bcdd` segnala l'errore.

| Codice | Quando | Riga indicata | Testo esatto del messaggio |
|---|---|---|---|
| E01 | due elementi con lo stesso nome o nome breve nello stesso blocco; due parametri o due argomenti con lo stesso nome nella stessa riga; due blocchi con lo stesso nome nello stesso file, qualunque sia il tipo. In un'entità: due parti, una parte e una promessa, o una storia e una parte o una promessa, con lo stesso nome; due `OFFERS` con lo stesso nome, salvo che entrambe scrivano `VERSION` con versioni diverse (sezione 5); lo stesso per due `USES`. In una CSC, anche un valore di un elenco di valori con lo stesso nome di un altro elemento del blocco | la seconda | `nome già usato alla riga N: X` |
| E02 | `DETAILS X` dove X non è una `GUARANTEE` né una `ASSUME` dello stesso blocco; in una `DEFINE`, X non è una `DEFINE` dello stesso blocco; in una storia, X non è una storia dello stesso blocco. Inoltre, in un'entità con segmenti `VARIANT`, la riga nominata si trova in una scelta che non è presente in tutte le composizioni del dettaglio (sezione 4.10) | quella del `DETAILS` | `DETAILS nomina un id che non è una GUARANTEE né una ASSUME di questa CSC: X`; in un'entità `DETAILS nomina un id che non è una GUARANTEE di questa ENTITY: X`; `DETAILS nomina un nome che non è una DEFINE di questa CSC: X`; `DETAILS nomina un id che non è uno SCENARIO di questo blocco: X`; per la riga in una scelta `DETAILS nomina una GUARANTEE che non vale in tutte le composizioni di questa riga: X (sta in VARIANT D = S)` |
| E03 | un passo o un `GIVEN` nomina come evento ciò che non è un `EVENT`, come richiesta ciò che non è una `CAPABILITY`, come stato ciò che non è uno `STATE`; oppure un argomento che non corrisponde a un parametro dell'evento. Inoltre, in una storia d'entità: un nome qualificato `X.y` in cui `X` è un connettore dell'entità (`OFFERS` o `USES`) e la sua CSC è trovata, ma `y` manca o è del genere errato, oppure un argomento che `X.y` non prevede; un nome semplice usato come evento, richiesta o stato, perché un'entità non ha elementi propri (sezione 4.6). In un blocco CSC: un nome usato come valore (G26) che non è un valore di un elenco di valori del blocco | quella del nome (per un nome qualificato, quella di `X`) | `nome non dichiarato come EVENT: X` (e così `CAPABILITY`, `STATE`), oppure `nome non dichiarato come parametro di E: X`; con un nome qualificato `nome non dichiarato come EVENT: X.y`, `nome non dichiarato come parametro di X.y: a`; per un valore `nome non dichiarato come valore di TYPE: X` |
| E04 | `STATUS RATIFIED` non seguito esattamente da `BY` e da una Decisione | quella di `RATIFIED` | `STATUS RATIFIED senza decisione: serve BY D-numero` |
| E05 | i `DETAILS` formano un ciclo (anche una riga che dettaglia se stessa), fra righe contrattuali, fra `DEFINE` o fra storie | quella del primo membro del ciclo nel file | `DETAILS in modo circolare: A -> B -> A`, cominciando da quel membro e seguendo i `DETAILS` |
| E06 | una stringa aperta non si chiude prima della fine del file | quella dove la stringa si apre | `stringa non chiusa: il file finisce dentro la stringa aperta qui` |
| E07 | un blocco senza `END` (finisce il file, o comincia un altro blocco), anche un `BINDING`, una `VERIFICATION`, un profilo o un'estensione (sezione 4.11) | l'intestazione del blocco | `blocco non chiuso: manca END di CSC X` oppure `… di REFINEMENT VIEW X` oppure `… di ENTITY X`; `… di BINDING X`, `… di VERIFICATION X`, `… di PROFILE X`, `… di EXTENSION X`, con `X` la seconda parola dell'intestazione se è un Nome; `?` se il nome non si legge. Un'estensione senza `END` dentro un profilo senza `END` dà un solo E07, sul profilo |
| E08 | `END` senza un blocco aperto (un'estensione è un blocco aperto dentro il suo profilo; lo è anche quella fuori posto di E32, quindi il suo `END` non comporta E08) | quella di `END` | `END senza un blocco aperto` |
| E09 | una riga che comincia con `CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE` o `EXTENSION` (dentro un profilo) e non rispetta G1, G31, G40, G48, G49 o G50 | quella | `intestazione non valida: attesa CSC Nome VERSION numero` oppure `… attesa ENTITY Nome VERSION numero`, `… attesa BINDING NomeCSC VERSION numero [AS nome]`, `… attesa VERIFICATION NomeCSC VERSION numero`, `… attesa PROFILE Nome VERSION numero`, `… attesa EXTENSION Nome`. Per `EXTENSION` con una parola chiave o riservata come nome vale invece E34 |
| E10 | una CSC, un'entità o un profilo senza `PURPOSE` riconosciuto; un secondo `PURPOSE`; un secondo `STATUS` riconosciuto nella zona d'intestazione (sezioni 4.2, 4.9 e 4.11, anche in un `BINDING`) | l'intestazione del blocco; il secondo `PURPOSE`; il secondo `STATUS`, colonna di `STATUS` | `PURPOSE mancante nella CSC X` oppure `PURPOSE mancante nella ENTITY X`, `PURPOSE mancante nel PROFILE X`; `PURPOSE ripetuto: il primo è alla riga N`; `STATUS ripetuto: il primo è alla riga N` |
| E11 | il file non contiene nessuna CSC, nessuna entità, nessun `BINDING`, nessuna `VERIFICATION` e nessun `PROFILE` (un blocco con intestazione non valida conta; non contano un blocco ritirato né un'estensione fuori da un profilo) | nessuna | `il file non contiene nessuna CSC` |
| E12 | in una storia un passo ha un tempo minore del più grande dei passi precedenti; oppure la storia mescola passi con unità di tempo e passi senza unità | quella del passo | `il tempo del passo diminuisce: @T dopo @M`; `passi con e senza unità di tempo nello stesso SCENARIO` |
| E13 | una `GUARANTEE` o `ASSUME` con intestazione della riga valida la cui proprietà è soltanto `VERBAL` e una stringa, senza `VERIFY` (sezione 4.5) | quella della parola `VERBAL` | `VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa` |
| E14 | dentro un'entità E con **tutte** le parti trovate, una parte P usa una CSC X che nessun'altra parte di E offre e che E non usa da fuori, secondo la corrispondenza della sezione 9.4 | quella della parte P nel file controllato; colonna del nome P | `la parte P usa il connettore X: nessun'altra parte di E lo offre, né E lo usa da fuori`, con `X` scritto come nella riga `USES` di P, seguito da ` VERSION w` se presente; `E` è il nome dell'entità, `?` se non si legge |
| E15 | una dichiarazione che comincia con `REFINEMENT`, in una posizione in cui può iniziare un blocco (sezione 4.8) | quella di `REFINEMENT`; colonna di `REFINEMENT` | `REFINEMENT VIEW è stata ritirata: una scomposizione si scrive con ENTITY` |
| E16 | un'entità E con almeno una parte (G34), con o senza `COMPOSED OF`, e con **tutte** le parti trovate. Con le composizioni (sezione 4.10), il controllo vale in ciascuna composizione con almeno una parte presente. Una CSC pubblica di E (`OFFERS X` o `USES X`) non è esposta da alcuna parte dallo stesso lato, secondo la corrispondenza della sezione 9.4 | quella della riga `OFFERS` o `USES` di E; colonna del nome | `il connettore pubblico X di E (offre) non è affidato a nessuna parte` (oppure `(usato)` per `USES`), con `X` scritto come nella riga, seguito da ` VERSION w` se presente |
| E17 | nelle stesse condizioni di E16, una parte P offre X, nessun'altra parte di E la usa ed E non la offre, secondo la corrispondenza della sezione 9.4 | quella della parte P; colonna del nome P | `la parte P offre il connettore X: nessun'altra parte di E lo usa, né E lo offre da fuori`, con `X` seguito da ` VERSION w` se la parte lo indica |
| E18 | dentro un blocco `ENTITY`, una dichiarazione che comincia con `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE` o `TYPE` (sezione 5) | quella della parola chiave; colonna della parola chiave | `K non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori`, con `K` la parola chiave |
| E19 | una parte con la forma G35 ma limiti non validi: un limite con un punto, oppure `m` > `n`, oppure `n` = 0 (sezione 4.9) | quella della parte; colonna di `[` | `la parte P ha un numero di copie non valido: [m .. n]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo`, con `P` il nome della parte e `m` e `n` scritti come nel file |
| E20 | un nome qualificato `X.y` in una storia o in una formula d'entità con `X` che non è fra le `OFFERS` e `USES` dell'entità; oppure un nome qualificato in una storia di una CSC o in una fase di una formula di una CSC (sezioni 4.6, 4.12) | quella di `X`; colonna di `X` | nell'entità `X.y: E non offre né usa il connettore X; uno scenario può citare solo i connettori di E`; nella CSC `X.y: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità`. In un'entità con più composizioni, `X` si controlla per composizione e il messaggio ha il suffisso `(in: …)` (sezioni 4.10 e 9.5) |
| E21 | una dichiarazione che comincia con `VARIANT` in un blocco `CSC`; in un'entità, una che comincia con `VARIANT` e non rispetta G38; una che comincia con `PURPOSE` dentro un segmento (sezione 4.10) | quella della parola chiave; colonna della parola chiave | `VARIANT non può stare in una CSC: le varianti si scrivono in un'entità`; `VARIANT scritto male: serve VARIANT gruppo = scelta`; `PURPOSE non può stare in un segmento VARIANT: scrivilo prima del primo VARIANT` |
| E22 | un gruppo con una sola scelta; la stessa scelta scritta due volte; un segmento senza dichiarazioni riconosciute (sezione 4.10) | quella del `VARIANT` (per la scelta ripetuta, la seconda); colonna di `VARIANT` | `il gruppo di scelte D ha una sola scelta (S): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]`; `la scelta D = S è già scritta alla riga N`; `il segmento VARIANT D = S è vuoto: una scelta senza righe si scrive con una parte [0 .. 1]` |
| E23 | un'entità con più di 64 composizioni (sezione 4.10) | quella dell'intestazione; colonna 0 | `l'entità E ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole`, con `E` il nome dell'entità (`?` se non si legge) |
| E24 | in una formula, in una `DEFINE`, in una riga `STATE … FOLLOWS` o in un uso di un'estensione: un nome non dichiarato, o non del genere richiesto dalla posizione (sezione 4.13); un campo inesistente; una chiamata con argomenti non validi; in un'entità, un nome semplice dove serve un elemento di una CSC (sezione 4.9) | quella del nome; colonna del nome (di `X` per `X.y`) | `nome non dichiarato: X`; `X non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY`; `X non è una CAPABILITY`; `X non è uno STATE`; `X è una CAPABILITY: si nomina con una fase (requested(X), …) o in ACCEPTS, REQUIRES, ENSURES, RESOLVES`; `X non è un valore`; `nome non dichiarato come campo di T: c`; `X non è una DEFINE con parametri`; `nome non dichiarato come parametro di X: p`; `manca l'argomento p nella chiamata di X`; `in un'entità i nomi delle CSC si scrivono con il connettore davanti: x`; con un nome qualificato `nome non dichiarato come EVENT: X.y` (e così `STATE`, `CAPABILITY`) |
| E25 | un'espressione di tipo errato per la sua posizione; un valore letterale in `INITIAL`, `GIVEN`, in un'assegnazione o in un argomento che non è del tipo dichiarato (sezione 4.13) | quella del primo elemento dell'espressione o del valore | `tipo incoerente: serve A, trovato B`; `valore non del tipo T: V` |
| E26 | `AND` e `OR` allo stesso livello senza parentesi; `IMPLIES`, un confronto o `^` concatenati senza parentesi (sezione 4.12) | quella del secondo operatore; colonna dell'operatore | `AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)`; `IMPLIES dopo IMPLIES senza parentesi: scrivi a IMPLIES (b IMPLIES c)`; `confronti in catena: scrivi a <= b AND b <= c`; `^ dopo ^ senza parentesi: scrivi (a ^ b) ^ c` |
| E27 | un pattern annidato in un altro; due ambiti; `WITHIN` e `AT ONCE` insieme; `REQUIRES` in una `GUARANTEE` (sezione 4.12) | quella della parola; colonna della parola | `K dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni`; `una proprietà ha un solo ambito: K è il secondo`; `WITHIN e AT ONCE nella stessa proprietà: scegline uno`; `REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)` |
| E28 | `DEFINE` che si nominano a vicenda in modo circolare; tipi con nome (G41) che si nominano a vicenda in modo circolare | quella del primo membro del ciclo nel file; colonna del nome | `DEFINE in modo circolare: A -> B -> A`; `TYPE in modo circolare: A -> B -> A` |
| E29 | il tipo dell'indice di uno stato (G11) o di `FOR ALL` non è finito; un indice su un nome che non ne ha; uno stato con indice usato senza indice; un indice di tipo errato (sezioni 4.3, 4.6, 4.12) | quella del nome o dell'indice | `il tipo dell'indice di X non è finito: T`; `X non ha indice`; `X ha un indice: scrivi X[valore di T]`; `indice di X non del tipo T: v` |
| E30 | una ripetizione non valida (sezione 4.6) | quella della riga `REPEAT` o del passo; colonna di `REPEAT` o di `@` | `REPEAT ripetuto nella storia: il primo è alla riga N`; `ripetizioni non valide: m..n. Scrivi REPEAT minimo..massimo, con il massimo almeno 1 e non più piccolo del minimo`; `il passo @t non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY d`; `REPEAT senza passi: i passi ripetuti si scrivono dopo la riga REPEAT`; `REPEAT … EVERY vuole una storia con le unità di tempo` |
| E31 | in un `BINDING` o in una `VERIFICATION` la cui CSC legata è trovata con la versione scritta: una riga `BIND` o `MEANS` nomina un elemento che la CSC non ha; una storia tradotta nomina una storia che la CSC non ha (sezione 4.11) | quella dell'elemento o del nome breve; colonna dell'elemento | `X non è un elemento della CSC N VERSION v`; `TRANSLATES nomina una storia che la CSC N VERSION v non ha: id` |
| E32 | un'`EXTENSION` fuori da un `PROFILE` (sezione 4.11) | quella di `EXTENSION`; colonna della parola | `EXTENSION fuori da un PROFILE: un'estensione si dichiara in un profilo` |
| E33 | un campo di un'estensione che manca, è ripetuto o ha un valore non ammesso; `FORM` che non comincia con il nome; un parametro che non compare esattamente una volta in `FORM`; `KIND FUNCTION` senza tipo del risultato; `VERIFY V1` con un controllo che non esiste (sezione 4.11) | per un campo mancante quella di `EXTENSION`, colonna 0; altrimenti quella del campo, colonna del campo | i messaggi della tabella della sezione 4.11 |
| E34 | due estensioni con lo stesso nome nello stesso profilo; un'estensione il cui nome è una parola chiave o riservata | quella della seconda `EXTENSION`, o di quella con il nome riservato; colonna del nome | `nome di estensione già usato alla riga N: X`; `il nome dell'estensione è una parola del linguaggio: X` |
| E35 | `REDUCES TO` nomina ciò che non è né una parola del linguaggio, né un parametro, né un'estensione dello stesso profilo; estensioni che si nominano a vicenda in modo circolare con `REDUCES TO` | quella del nome; per il ciclo quella del primo membro nel file | `REDUCES TO nomina X: non è una parola del linguaggio, un parametro né un'estensione del PROFILE P`; `REDUCES TO in modo circolare: A -> B -> A` |
| E36 | un'estensione la cui `REDUCES TO` ripete una forma del linguaggio o un'altra estensione (sezione 4.11) | quella di `REDUCES`; colonna di `REDUCES` | `l'EXTENSION X ripete una forma che il linguaggio ha già: F`; `l'EXTENSION X ripete l'EXTENSION Y` |
| E37 | un uso di un'estensione che non rispetta il suo `FORM`, il suo `KIND` o il suo `LEVEL` (sezione 4.14) | quella del nome dell'estensione; colonna del nome | `uso di X che non rispetta FORM "F"`; `X ha KIND K: non si usa in questa posizione`; `X ha LEVEL L: non si usa in un blocco B` |
| E38 | un `BINDING` o una `VERIFICATION` importa un profilo con una versione diversa da quella con cui lo importa la CSC legata, se questa è trovata | quella della riga `IMPORT PROFILE` del blocco legato; colonna di `IMPORT` | `PROFILE P importato con VERSION v, ma la CSC N lo importa con VERSION w` |
| E39 | uno `STATUS` in una `VERIFICATION` | quella di `STATUS`; colonna di `STATUS` | `STATUS non può stare in una VERIFICATION: un piano di prova non si approva` |
| E40 | due `BINDING` per la stessa CSC e la stessa versione senza nome, o con lo stesso nome, nel file controllato (sezione 4.11) | quella del secondo; colonna 0 | `secondo BINDING senza nome per la CSC N VERSION v: il primo è alla riga M. Con due o più BINDING ognuno ha un nome, AS nome`; `nome di BINDING già usato alla riga M: x` |

Nei messaggi `id` indica il nome breve, «connettore» una CSC citata da un'entità, «gruppo di scelte» un gruppo e
`SCENARIO` una storia.

Precisazioni:
- **Non sono errori**: una riga non riconosciuta; un tipo non dichiarato; una CSC senza promesse; un `PURPOSE`
  vuoto. Non lo sono nemmeno una citazione non trovata, un file citato non leggibile o con errori, una versione
  diversa da quella attesa, perché non sono elementi errati scritti nel file controllato. Una parte non trovata non
  è un errore, ma **sospende** E14 per la sua entità.
- Tutti gli errori hanno codice d'uscita 1 e impediscono `ratify`. Le voci seguenti riportano solo ciò che è proprio
  di ciascun errore.
- **E16 ed E17** completano la chiusura di un'entità: E14 controlla le righe `USES` delle parti, E17 le loro
  `OFFERS`, E16 i confini pubblici. Come E14, una parte non trovata li sospende per la sua entità.
- **E14**: una parte usa una CSC quando lo indica il **proprio** blocco, trovato altrove. L'errore si segnala nel
  file controllato, perché è in quel file che le parti sono riunite.
- **E03** riguarda solo i passi, i `GIVEN` e i valori riconosciuti. Gli argomenti si controllano solo se l'evento è
  dichiarato come `EVENT`. In una storia d'entità, se la CSC `X` non è trovata, `X.y` e i suoi argomenti non si
  controllano (sezione 4.6).
- **E18, E19, E20**: una dichiarazione con E18 è anche non riconosciuta e compare nella sezione 5; una parte con E19
  resta una parte; una dichiarazione con E20 resta riconosciuta.
- **E21, E22, E23**: una dichiarazione con E21 è anche non riconosciuta; un segmento con E22 resta un segmento; con
  E23 la chiusura dell'entità non si controlla.
- **E14, E16, E17 con le composizioni**: in una composizione con una parte facoltativa assente, gli errori che
  scomparirebbero reinserendo la parte non sono errori ma assenze dichiarate (sezioni 4.10 e 9.5). Non contano nella
  riga `esito` e non cambiano il codice d'uscita. Con più composizioni hanno il suffisso `(in: …)`.
- **E06, E08, E09, E15, E18, E21, E32**: oltre all'errore, la riga è non riconosciuta, quindi compare anche nella
  sezione 5 del rapporto. Una dichiarazione con una stringa non chiusa non dichiara nulla. Con E32 sono non
  riconosciute anche le righe dell'estensione fuori posto, fino al suo `END`.
- **E24-E31 ed E33-E40**: la dichiarazione in cui compaiono resta riconosciuta, perché `bcdd` ne ha letto la forma
  per intero e l'errore indica che cosa è errato. Fa eccezione un campo di un'estensione la cui riga non è
  riconosciuta: E33 «manca il campo» è segnalato sulla riga `EXTENSION`.
- **Solo errori certi.** Quando un controllo dipende da un file citato che non viene trovato (una CSC legata, il
  blocco di `X` in un nome qualificato, un profilo), il controllo è sospeso e non produce errori; la citazione è
  elencata nella sezione 7 del rapporto.
- **E12**: il passo senza unità vale come numero senza unità; 1 `s` equivale a 1000 `ms`. Il primo passo della
  storia stabilisce se la storia usa le unità. Nel messaggio i tempi si scrivono `@` + numero + (spazio + unità, se
  presente): `@3 s dopo @5 s`, `@4000 ms dopo @5 s`. Due passi con lo stesso tempo sono ammessi.
- **E12 con unità mescolate**: «con unità» significa con `s` oppure con `ms`; `s` e `ms` nella stessa storia non
  sono una mescolanza. Ogni passo che non segue la scelta del primo passo produce **un proprio** E12, sulla propria
  riga: chi corregge ottiene l'elenco completo dei passi da correggere, non solo il primo. Quel passo **è escluso dal
  confronto dei tempi**: non può produrre anche «il tempo diminuisce» e non modifica il tempo più grande con cui si
  confrontano i passi successivi. Un numero senza unità e un tempo con unità non sono confrontabili senza assumere
  un'unità arbitraria. Esempio: dopo `@0 s`, per il passo `@5` `bcdd` segnala E12 per le unità, e per il passo
  `@3 s` che segue **non** segnala errori, perché il più grande resta `@0 s`.
- **E13**: in un presupposto scritto su più righe la riga indicata è quella in cui si trova `VERBAL`, che può
  essere diversa dalla riga di `ASSUME`. La riga compare nella sezione 2 del rapporto come `verbale` e, se è da
  approvare, nella sezione 4; non compare nella sezione 5.
- **Una virgoletta dimenticata** sposta l'abbinamento delle virgolette successive: le righe intermedie diventano
  testo di stringa o righe non riconosciute. Di norma resta aperta l'ultima stringa del file, e `bcdd` segnala E06
  sulla riga in cui questa si apre, che può essere lontana dalla virgoletta mancante. Un tratto di righe diventa una
  stringa senza errori solo con due virgolette errate (sezione 5, «Le parti di un'entità»).

---

## 9. Il rapporto di `bcdd check`

Il rapporto coincide con lo standard output ed è definito da questa sezione carattere per carattere.

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

4. DA APPROVARE, NON CONTRATTO: d
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

Le sezioni da 1 a 5 contengono, nell'ordine: errori, grado, numeri non decisi (`UNDECIDED`), righe da approvare
(«DA APPROVARE, NON CONTRATTO»), righe non riconosciute. Seguono le sezioni 6, 7, 8, 9, 10, 12, 13, 14 e 15. Il
numero 11 non è utilizzato: apparteneva alla sezione dei blocchi non letti, eliminata. Un file senza entità non ha
citazioni d'entità né la sezione 8.

### 9.2 Regole di formato

| Che cosa | Regola |
|---|---|
| Prima riga | `bcdd check`, poi ` --strict` se presente, poi ` --dir ARG` per ogni cartella, nell'ordine in cui compaiono (`ARG` come scritto), poi ` NOMEFILE`. L'ordine è sempre questo, qualunque sia la posizione delle opzioni nella riga di comando. Esempio: `bcdd check --strict --dir comuni Uso.csc` |
| Nome del file | solo il nome, senza cartelle, con la grafia (maiuscole e minuscole) presente nel file system |
| Rientro | due spazi per ogni voce sotto un titolo; quattro per una citazione sotto il suo blocco (9.4, 9.6) e per le voci di un blocco nella sezione 13 |
| Righe vuote | una riga vuota dopo la sezione «blocchi» e dopo ogni sezione da 1 a 7, e dopo le sezioni 8, 9, 10, 12, 13, 14 e 15 quando presenti |
| Spazi in fondo | nessuna riga del rapporto termina con uno spazio |
| Fine | il rapporto termina con un LF dopo la riga `esito` |
| Sezioni vuote | il titolo è sempre presente, con conteggio 0 e nessuna voce |
| Ordine delle voci | per numero di riga; gli errori sulla stessa riga per colonna dell'elemento che li causa, poi per codice. L'errore E11 (privo di riga) precede tutti gli altri e si scrive `file: [E11] …`. La colonna si conta dall'inizio della riga, a partire da 0. Alcuni errori non si riferiscono a un solo elemento e hanno **colonna 0**: E06 (stringa non chiusa), E07 (blocco non chiuso), E10 per `PURPOSE` mancante, E23, E33 per un campo mancante ed E40. Questi errori precedono quindi gli altri errori della stessa riga e sono ordinati fra loro per codice. E10 per `PURPOSE` ripetuto ha la colonna di quel `PURPOSE`. Esempio: per un'intestazione rientrata e non valida, senza `PURPOSE` e senza `END`, `bcdd` segnala nell'ordine E07, E10, E09 |
| Stato del blocco | `STATUS HYPOTHESIS`, `STATUS RATIFIED BY D-nnn`, `senza STATUS`, oppure `STATUS non valido` (errore E04 nell'intestazione); per una `CSC`, un'`ENTITY`, un `BINDING` e un `PROFILE`. Una `VERIFICATION` non ha stato: la sua riga termina dopo la versione |
| Intestazione non valida | `CSC (intestazione non valida), STATO`; `REFINEMENT VIEW (intestazione non valida)`; `ENTITY (intestazione non valida), STATO`; `BINDING (intestazione non valida), STATO`; `VERIFICATION (intestazione non valida)`; `PROFILE (intestazione non valida), STATO`. `STATO` è lo `STATUS` come scritto nel file, anche quando è `STATUS RATIFIED BY D-nnn`. Nessuna riga contrattuale del blocco è approvata (sezione 7.1, punto 0), ma la riga del blocco nel rapporto riporta comunque lo `STATUS` scritto. Per `ENTITY` lo `STATUS RATIFIED` non è riconosciuto e `STATO` è `senza STATUS` (sezione 5 di questo documento) |
| Sezione 2 | i quattro conteggi (`verbale`, `formale`, `estensione dichiarata`, `non riconosciuta`) sono separati e **non si sommano**: non esiste una riga di totale. Segue una voce per ogni `GUARANTEE` e `ASSUME` di un blocco CSC e per ogni `GUARANTEE` di un'entità, in ordine di riga fra tutte le righe del file, con grado `verbale`, `formale`, `estensione dichiarata` o `non riconosciuta` (sezione 6) |
| Sezione 2, casi particolari | se l'intestazione della riga non è riconosciuta, il nome breve è `?` e il grado è `non riconosciuta`, contato nel quarto conteggio. Avviene quando l'intestazione della riga non rispetta G16, sia nella CSC sia nell'entità: per esempio `GUARANTEE r3 STATUS PIPPO: …` produce `GUARANTEE ? non riconosciuta`. Una promessa d'entità con `STATUS RATIFIED BY D-nnn` o `STATUS RATIFIED` senza decisione (E04) ha il suo nome breve e grado `verbale`, come nella CSC: per esempio `riga 6: GUARANTEE r2 verbale` (sezione 7.1). Un'`ASSUME` in un'entità non ha voce (sezione 5 di questo documento) |
| Sezione 3 | ogni `DEFINE` riconosciuta con valore `UNDECIDED` |
| Sezione 4 | ogni riga contrattuale con intestazione della riga riconosciuta e stato effettivo «da approvare» (sezione 7). Vi compare **ogni** riga contrattuale di un blocco, CSC o entità, con intestazione non valida (E09), indipendentemente dallo `STATUS` della riga e da quello dell'intestazione (sezione 7.1, punto 0). Inoltre, nell'ordine del file: i dettagli di `DEFINE` (`riga N: DEFINE nome`) e di storie (`riga N: SCENARIO id`) da approvare; le righe `BIND` da approvare (`riga N: BIND elemento`, con l'elemento come scritto); le estensioni di un profilo da approvare (`riga N: EXTENSION Nome`) |
| Sezione 5 | ogni riga classificata non riconosciuta, con il suo testo senza gli spazi iniziali e finali. Una riga vuota dentro una stringa si scrive `riga N:`. Se la dichiarazione non è riconosciuta per un profilo non trovato o per un'estensione con errori (sezione 4.14), la sua prima riga termina con ` (profilo P VERSION v non trovato)` oppure ` (EXTENSION X del PROFILE P con errori)` |
| Sezione 6 | i tipi non dichiarati delle dichiarazioni riconosciute, nell'ordine della prima comparsa; per ciascun tipo le righe in cui compare, senza ripetizioni. Un tipo descritto a parole (G30) o un elenco di valori (G37) nello stesso blocco non è un tipo non dichiarato |
| Sezione 7 | le citazioni **non trovate**, in ordine di riga, con il motivo se presente (9.4). Sono: le citazioni delle entità; la CSC legata di un `BINDING` o di una `VERIFICATION` (`riga N: Nome`); i `BINDING` nominati con `USING` (`riga N: BINDING Nome AS b`); i profili importati (`riga N: PROFILE Nome`). Per un profilo presente soltanto in un'altra versione il motivo è `trovata solo la VERSION w in PERCORSO`. Un blocco ritirato non ha citazioni (4.8). Il titolo riporta «CSC» anche per le entità, i blocchi e i profili citati |
| Sezione 8 | solo se il file ha almeno un blocco `ENTITY` (9.4); un file con entità e senza voci riporta `8. USI DENTRO LE ENTITÀ: 0`. Per un'entità con più composizioni, le voci sono calcolate per composizione, con il suffisso `(in: …)` (9.5) |
| Sezioni 9 e 10 | solo se almeno un'entità del file ha più di una composizione o E23; la sezione 10 anche con 0 voci (9.5) |
| Conteggi della seconda riga | R + C + V + U = T: ogni riga è contata una sola volta |
| Sezioni 12, 13, 14 e 15 | la 12 solo se il file ha almeno un `BINDING`, la 13 solo se ha almeno una `VERIFICATION`, anche con 0 voci; la 14 e la 15 solo se hanno almeno una voce. Il numero identifica la sezione e non cambia anche quando mancano le sezioni precedenti. Le regole sono nella 9.6 e nella 9.7. La riga `esito` non è influenzata: le voci di queste sezioni non sono errori |
| Riga `esito` | conta gli errori, E14 compreso. Se U è almeno 1, anche senza `--strict` si aggiunge `; righe non riconosciute: U (vedi sezione 5)`. U è il numero indicato nella seconda riga del rapporto, e «sezione 5» rimanda alla sezione delle righe non riconosciute. Esempi: `esito: nessun errore; righe non riconosciute: 1 (vedi sezione 5)`, `esito: 2 errori; righe non riconosciute: 3 (vedi sezione 5)`. Senza `--strict` il codice d'uscita non cambia: la riga riporta le righe non riconosciute, ma non le conta come errori. Se U è 0 la parte aggiunta non c'è. Le citazioni non influiscono su U, che è sempre quello del file controllato e mai quello dei file citati |
| Riga `esito` con `--strict` | se U è 0, è identica a quella senza opzione. Se U è almeno 1, la riga con l'opzione riporta ` (--strict)` al posto di ` (vedi sezione 5)`: `esito: nessun errore; righe non riconosciute: 16 (--strict)`, `esito: 1 errore; righe non riconosciute: 1 (--strict)`. La parola `righe` resta al plurale anche per U = 1 |
| Resto del rapporto con `--strict` | byte per byte identico al rapporto senza l'opzione: l'opzione cambia solo la prima riga, la riga `esito` (per il ` (--strict)` al posto di ` (vedi sezione 5)`) e il codice d'uscita |

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

4. DA APPROVARE, NON CONTRATTO: 3
  riga 8: GUARANTEE g1
  riga 9: GUARANTEE g2
  riga 10: GUARANTEE g3

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: 3 errori
```

`g1` non ha `STATUS`, e lo `STATUS` dell'intestazione non è valido (E04): `g1` è da approvare (sezione 7.1, punto
4). `g4` ha un'approvazione valida (`D-7`) ed è approvata.

### 9.4 Entità e citazioni

Le **citazioni** di un'entità sono le sue righe G32 (`OFFERS`), G33 (`USES`) e G34 (le parti, anche con E19)
riconosciute. Per ogni entità del file, anche con intestazione non valida, `check` cerca sempre i blocchi citati,
escluse le citazioni con E01. Un blocco ritirato non ha citazioni (sezione 4.8).

**Una sola profondità.** La lettura dei blocchi citati si ferma al primo livello:
- di un'entità citata come parte si leggono soltanto le righe `OFFERS` e `USES` (e le righe `VARIANT`, con il
  segmento di ogni riga: 9.5), non le sue parti né le CSC che cita;
- di una CSC citata da un'entità si usano solo intestazione, versione, stato ed esito;
- in più, **solo se l'entità del file controllato ha almeno un nome qualificato** in una storia o in una formula
  (sezioni 4.6 e 4.9), si usano le dichiarazioni riconosciute `CAPABILITY`, `EVENT` (con i parametri) e `STATE`
  (con il tipo) del blocco trovato;
- della CSC legata a un `BINDING` o a una `VERIFICATION` si usano anche le dichiarazioni `STATE`, `EVENT`,
  `CAPABILITY` e `DEFINE` riconosciute, i nomi brevi delle storie, il grado e i nomi delle promesse e dei
  presupposti (per la copertura, 9.6) e le righe `IMPORT PROFILE` (per E38);
- di un profilo trovato si usano le estensioni e i loro errori (sezione 4.14).

La profondità resta una: non si cercano i blocchi citati dalla CSC citata. «Controllata» significa che `bcdd` ha
letto il blocco citato e ne riporta versione, stato ed esito. Non significa che le promesse siano coerenti fra loro:
la coerenza resta un giudizio.

#### La ricerca

Il blocco cercato per una citazione di nome `N` dipende dal tipo di citazione:
- `OFFERS`, `USES` e CSC legata di un `BINDING` o di una `VERIFICATION` (che vale come una `USES N VERSION v`): il
  blocco `CSC N` con intestazione G1 valida;
- parte: il blocco `ENTITY N` con intestazione G31 valida;
- `IMPORT PROFILE`: il blocco `PROFILE N` con intestazione G49 valida;
- `USING b`: il blocco `BINDING N VERSION v AS b`.

Le regole seguenti valgono per tutti i tipi di citazione. Per un profilo la versione deve essere esattamente quella
scritta: una versione di riserva non vale come trovata (sezione 4.2). La ricerca procede in quest'ordine:

1. **Stesso file**: il primo blocco del tipo cercato con quel nome. Se esiste, la ricerca termina qui, salvo il
   caso della versione descritto più sotto. Questo passo non produce mai un motivo.
2. **Stessa cartella**: il file `N.csc` nella cartella del percorso indicato come argomento (la parte
   dell'argomento che precede l'ultimo `/`, oppure la cartella corrente se l'argomento non contiene `/`), anche se
   l'argomento è un collegamento simbolico. `N` si usa senza alcuna trasformazione, byte per byte.
3. **Cartelle `--dir`**: il file `N.csc` in ciascuna, nell'ordine in cui sono scritte.

Anche il file controllato può essere un candidato, e si legge come gli altri.

| Il candidato `N.csc` | La ricerca |
|---|---|
| non esiste: nessun file con quel nome, una parte del percorso non è una cartella, oppure è un collegamento simbolico a un file inesistente | passa al candidato successivo |
| esiste, è leggibile, è in UTF-8 valido, ma non contiene il blocco cercato | passa al candidato successivo |
| esiste, è leggibile, è in UTF-8 valido e contiene il blocco cercato | **trovata** |
| è una cartella o non è un file normale | **si interrompe**, motivo `non è un file: PERCORSO` |
| non è leggibile (permessi, errore di lettura o altro motivo) | **si interrompe**, motivo `non leggibile: PERCORSO` |
| non è possibile accertarne l'esistenza: l'interrogazione del sistema operativo fallisce per un motivo diverso da «il file non esiste» e da «una parte del percorso non è una cartella» (per esempio una cartella del percorso senza permesso di attraversamento) | **si interrompe**, motivo `non leggibile: PERCORSO` |
| non è in UTF-8 valido | **si interrompe**, motivo `non UTF-8: PERCORSO` |

**Una versione diversa non interrompe la ricerca.** Per una citazione con `VERSION w`, un candidato (anche lo
stesso file, passo 1) che contiene il blocco cercato con un'altra versione non è ancora considerato trovato. Viene
memorizzato come **versione di riserva** (solo il primo) e la ricerca prosegue con il candidato successivo. Se un
candidato successivo contiene il blocco con la versione `w`, la citazione è trovata in quel candidato, senza
`attesa`. Se nessun candidato la contiene, la citazione è trovata nella prima versione di riserva, con
`, attesa VERSION w`. Un candidato che interrompe la ricerca (`non è un file`, `non leggibile`, `non UTF-8`) la
interrompe anche quando esiste una versione di riserva; in tal caso la citazione è trovata nella versione di
riserva. Senza `VERSION` nella citazione è trovato il primo candidato che contiene il blocco. La regola è necessaria
perché un file `N.csc` contiene una sola versione del blocco (due blocchi con lo stesso nome sono E01). Due versioni
dello stesso blocco possono quindi trovarsi solo in file diversi, per esempio in due cartelle `--dir`.

**Se la citazione non è trovata**, il motivo è, in quest'ordine: quello del candidato che ha interrotto la ricerca;
altrimenti `PERCORSO non contiene CSC N` (o `… non contiene ENTITY N`) per il **primo** candidato che non contiene
il blocco; altrimenti nessun motivo.

**`PERCORSO`.** Per il passo «stessa cartella» è il solo `N.csc`, senza cartelle. Per una cartella `--dir` è
l'argomento come scritto, con `/` aggiunta se manca, seguito da `N.csc`.

**Che cosa si usa del file trovato.** Il file si legge con le regole di `check` (BOM, CR LF, UTF-8) e si esamina per
intero, **senza** cercarne le citazioni: E14 non vi viene quindi mai contato. Del file trovato si usano:
- la riga dell'intestazione del blocco, la sua versione e il suo stato (regola «Stato del blocco» della 9.2);
- il numero di errori di tutto il file e il numero `U` delle sue righe non riconosciute;
- per un'entità, le sue righe `OFFERS` e `USES` riconosciute, nell'ordine, escluse quelle con E01 in quel file.

**Versioni fra una citazione e il blocco trovato.** Si confrontano come testo (`0.1` e `0.10` sono versioni
diverse). Una citazione senza versione corrisponde a qualunque versione del blocco trovato, che ha sempre una
versione (G1 e G31 la richiedono). Una versione diversa non è un errore: il rapporto la riporta.

**Determinismo.** `bcdd` può mantenere in memoria un file già letto. Il rapporto è identico a quello che si
otterrebbe leggendo ogni candidato una sola volta, nell'ordine indicato sopra.

#### Le righe delle citazioni trovate

Il conteggio `blocchi: B` comprende anche le entità. Sotto la riga di un'entità compare una riga per ogni citazione
**trovata**, in ordine di riga e rientrata di **quattro** spazi:

```
    riga N: OFFERS X in questo file alla riga M
    riga N: USES X in PERCORSO alla riga M: VERSION v, STATO, ESITO
    riga N: p : X in PERCORSO alla riga M: VERSION v, STATO, ESITO
```

- `N` è la riga della citazione nel file controllato; `M` è la riga dell'intestazione del blocco trovato.
- La citazione si scrive senza versione e senza molteplicità: `OFFERS X`, `USES X`, `p : X` (nome della parte,
  spazio, due punti, spazio, nome dell'entità).
- `STATO` segue la regola «Stato del blocco» della 9.2. `ESITO` è uno fra `nessun errore`, `1 errore` ed
  `E errori`, seguito da `, righe non riconosciute: U` se `U` > 0, con o senza `--strict`.
- Se il blocco è nello stesso file, si scrive soltanto `in questo file alla riga M`: versione, stato ed errori di
  quel blocco compaiono già nel rapporto.
- Se la citazione dichiara `VERSION w` e il blocco trovato ha una `VERSION v` diversa, la riga termina con
  `, attesa VERSION w`. Per un blocco nello stesso file: `riga N: OFFERS X in questo file alla riga M: VERSION v,
  attesa VERSION w`.

Ogni citazione compare in un solo punto del rapporto: sotto la propria entità, se trovata, oppure nella sezione 7,
come `riga N: X` o `riga N: X (MOTIVO)`, con `X` il nome citato senza versione. Una citazione con E01 non compare in
nessuno dei due punti: compare il suo errore.

#### Sezione 8 ed errore E14

La sezione 8 è presente **solo se il file contiene almeno un blocco `ENTITY`**. Si trova dopo la sezione 7 e prima
della riga `esito`, ed è seguita da una riga vuota.

```
8. USI DENTRO LE ENTITÀ: n
  riga N: P usa X: la offre Q (riga M)
  riga N: P usa X: la offrono Q (riga M), R (riga K)
  riga N: P usa X: la usa E da fuori (riga M)
  riga N: P usa X: nessuno la offre
  riga N: P usa X: nessuna parte trovata la offre (parti non controllate: k)
```

**Le voci.** Si scrive una voce per ogni riga `USES` del blocco trovato di ciascuna parte `P` **trovata** di
ciascuna entità `E` del file. Le entità sono considerate in ordine di riga, le parti in ordine di riga (`N` è la riga
di `P` nel file controllato) e le righe `USES` nell'ordine in cui `P` le scrive. `X` si scrive come nella riga
`USES` di `P`, con ` VERSION w` se presente. Le parti sono indicate con il nome che hanno nell'entità (`lampada`,
non `Lampada`). `n` è il numero di voci.

**La corrispondenza (non simmetrica).** La riga `USES X [VERSION w]` di `P` è una **domanda**: deve trovare chi
offre `X`. Corrisponde a una riga `OFFERS Y [VERSION v]` di un'altra parte trovata, oppure a una riga
`USES Y [VERSION v]` della stessa `E`, se `X` e `Y` sono uguali byte per byte **e** vale una delle condizioni della
tabella:

| La riga `USES` di `P` | L'altra riga | Corrispondono |
|---|---|---|
| `USES X` (senza versione) | `OFFERS X` o `OFFERS X VERSION v`, qualunque `v` | sì |
| `USES X VERSION w` | `OFFERS X VERSION w` (stesso testo) | sì |
| `USES X VERSION w` | `OFFERS X VERSION v` con `v` diversa da `w` | no |
| `USES X VERSION w` | `OFFERS X` (senza versione) | **no**: chi non dichiara una versione non si impegna sulla `w` |

Le stesse regole valgono se, al posto della riga `OFFERS`, si considera una riga `USES X [VERSION v]` di `E`. Le
righe con E01 sono sempre escluse.

| Caso, nell'ordine | Voce | Errore |
|---|---|---|
| una o più **altre** parti trovate di `E` hanno una riga `OFFERS` corrispondente | `la offre Q (riga M)`, oppure `la offrono Q (riga M), R (riga K)` in ordine di riga, separate da `, `; `M`, `K` sono le righe delle parti nel file controllato | no |
| nessuna parte, ma `E` ha una riga `USES` corrispondente | `la usa E da fuori (riga M)`, con `M` la riga di quella `USES` | no |
| nessuno dei due casi, e **tutte** le parti di `E` sono trovate | `nessuno la offre` | **E14** sulla riga `N` |
| nessuno dei due casi, e almeno una parte di `E` non è trovata | `nessuna parte trovata la offre (parti non controllate: k)`, con `k` il numero di parti di `E` elencate nella sezione 7 | no: E14 è sospeso |

- «Altra parte» significa un'altra riga di parte, anche se cita la stessa entità (due parti `a : Nodo` e
  `b : Nodo` si soddisfano a vicenda). La riga `OFFERS X` di `P` non soddisfa la `USES X` della stessa parte,
  nemmeno se `P` ha una molteplicità con `m` >= 2 (sezione 4.9).
- **Più versioni** (sezione 5): ogni riga `OFFERS` o `USES` è valutata singolarmente, secondo la corrispondenza
  descritta sopra. Se una parte `Q` ha due righe corrispondenti alla stessa riga `USES` (`USES Pulsanti` senza
  versione e le due `OFFERS Pulsanti VERSION 0.1` e `0.2`), nella voce `Q` compare **una sola volta**. E16 ed E17
  si contano riga per riga: per una `OFFERS X VERSION 0.1` di una parte che nessun'altra parte usa, `bcdd` segnala
  un proprio E17.
- Una parte trovata con errori o con righe non riconosciute produce le voci delle sole righe `USES` riconosciute, e
  offre soltanto con le righe `OFFERS` riconosciute.
- Una parte che cita l'entità stessa che la contiene è trattata come le altre: la profondità è una sola.
- Non si controlla che le CSC offerte da `E` siano offerte anche da qualche parte (sezione 14 di questo documento).

#### Il rapporto intero sulla luce delle scale

`bcdd check LuceScale.csc`, eseguito sul file della sezione 4.9 con le CSC e le entità citate nella stessa cartella,
produce esattamente il rapporto seguente, con codice d'uscita 0:

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

4. DA APPROVARE, NON CONTRATTO: 1
  riga 8: GUARANTEE g1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 1
  riga 7: lampada usa Comando: la offre pulsante (riga 6)

esito: nessun errore
```

`pulsante` non ha righe `USES`, quindi non produce voci. `Pulsante` offre `Comando` nel proprio file, e la voce
riporta la riga (6) della parte `pulsante` nel file controllato.

Senza il pulsante (un'entità `SenzaPulsante` con la sola parte `lampada` alla riga 5) la voce diventa
`riga 5: lampada usa Comando: nessuno la offre`. Compare l'errore `riga 5: [E14] la parte lampada usa il connettore
Comando: nessun'altra parte di SenzaPulsante lo offre, né SenzaPulsante lo usa da fuori`, e il codice d'uscita è 1.
Se invece la lampada dichiara `USES Comando VERSION 0.2` e il pulsante dichiara solo `OFFERS Comando`, la voce è
`nessuno la offre` e `bcdd` segnala E14: il pulsante non ha dichiarato la versione 0.2.

### 9.5 Composizioni e assenze dichiarate

Le regole delle composizioni sono nella sezione 4.10; qui si descrive come compaiono nel rapporto.

**Il suffisso `(in: …)`.** Si consideri un insieme di riferimento di composizioni (l'**universo**): per un errore e
per una voce della sezione 8 sono tutte le composizioni dell'entità; per una voce della sezione 10 sono quelle senza
la parte nominata. Sia `S` l'insieme delle composizioni in cui si verifica l'errore o la voce. Il suffisso si
determina così:
1. se `S` è tutto l'universo, non c'è suffisso;
2. altrimenti si cerca il primo valore `a` di un fattore tale che `S` coincida con l'insieme delle composizioni
   dell'universo che hanno `a`. Fattori e valori sono considerati nell'ordine della sezione 4.10. Il suffisso è
   allora ` (in: a)`;
3. altrimenti il suffisso è ` (in: N1; N2; …)`, con i nomi delle composizioni di `S` nell'ordine della sezione
   4.10, separati da `; `.

Il suffisso si scrive dopo il messaggio di un errore (sezione 1 del rapporto), dopo una voce della sezione 8 e dopo
una voce della sezione 10. Il messaggio resta quello definito nella sezione 8 di questo documento, con il nome
dell'entità del file.

**Sezione 1.** Lo stesso errore trovato in più composizioni (stesso codice, stessa riga, stessa colonna e stesso
messaggio) si scrive una sola volta, con il suffisso. L'ordine delle voci non cambia (9.2).

**Sezione 8.** Per un'entità con più di una composizione, le voci si calcolano per ogni composizione; le voci con lo
stesso testo si scrivono una sola volta, con il suffisso. L'ordine è: riga della parte, ordine delle righe `USES`
della parte, prima composizione in cui la voce compare. `n` è il numero delle voci scritte. Esempio, per un kit di
misura con un gruppo `sensore` e una parte facoltativa `di`:

```
  riga 18: cattura usa SegnaleLivello: la offre di (riga 46) (in: con di)
  riga 18: cattura usa SegnaleLivello: nessuno la offre (in: senza di)
  riga 18: cattura usa SegnaleLivello: la offre microfono (riga 88) (in: sensore = microfono)
```

**Sezione 9.** `9. COMPOSIZIONI: c`. La sezione contiene una voce per ogni entità con più di una composizione o con
E23, in ordine di riga. La voce è `riga N: ENTITY Nome: k`, seguita dai nomi delle `k` composizioni nel loro ordine,
rientrati di quattro spazi. Per un'entità con E23 la voce è la sola riga `riga N: ENTITY Nome: più di 64, non
controllate`. `c` è la somma delle `k`; un'entità con E23 contribuisce con 0. Un'entità con E21 su una riga
`VARIANT` non ha voce.

**Sezione 10.** `10. ASSENZE DICHIARATE: a`. La sezione contiene una voce per ogni assenza dichiarata (sezione
4.10), raggruppata come gli errori: `riga N: senza P: messaggio`, con il suffisso calcolato sull'universo delle
composizioni senza `P`. L'ordine è: riga, colonna, codice (come nella sezione 1), poi prima composizione. Le assenze
non sono contate nella riga `esito` e non modificano il codice d'uscita. Esempio, per lo stesso kit (codice d'uscita
0):

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

**Le parti con varianti** (9.4, «Una sola profondità»). Di un'entità citata come parte si leggono anche le righe
`VARIANT` riconosciute e, per ogni riga `OFFERS` e `USES`, il segmento in cui si trova; non se ne leggono le parti.

### 9.6 Forme concrete, piano di prova e profili nel rapporto

**Le righe dei blocchi.** Nella sezione «blocchi» un `BINDING` si scrive `riga N: BINDING Nome VERSION v, STATO`,
con ` AS b` dopo la versione se presente. Una `VERIFICATION` si scrive `riga N: VERIFICATION Nome VERSION v`; un
profilo `riga N: PROFILE Nome VERSION v, STATO`.

Sotto la riga di un blocco compaiono, rientrate di quattro spazi e in ordine di riga, le sue citazioni trovate,
nella forma descritta in 9.4:
- la CSC legata: `riga N: CSC Nome in PERCORSO alla riga M: …`, dove `N` è la riga dell'intestazione del blocco;
- i profili importati, anche sotto una CSC o un'entità: `riga N: IMPORT PROFILE P in PERCORSO alla riga M:
  VERSION v, STATO, ESITO`;
- i `BINDING` nominati con `USING`: `riga N: USING b in PERCORSO alla riga M`.

Se il blocco trovato è nello stesso file, si scrive `in questo file alla riga M`.

**Sezione 12, forme concrete mancanti.** `12. FORME CONCRETE MANCANTI: k`. La sezione contiene una voce per ogni
`BINDING` del file la cui CSC legata è trovata con la versione scritta, in ordine di riga. La voce è
`riga N: BINDING Nome VERSION v[ AS b]: ` seguita dagli elementi della CSC che nessuna riga `BIND` del blocco cita,
nell'ordine del blocco della CSC. Ogni elemento ha la propria parola chiave (`STATE modo`, `EVENT IN pressione`,
`EVENT OUT accendi`, `CAPABILITY Pulizie`) e gli elementi sono separati da `, `. Se ogni elemento ha una forma
concreta, la voce termina con `nessuna`. Un `BINDING` la cui CSC non è trovata ha la voce `riga N: BINDING Nome
VERSION v: CSC non trovata, elementi non controllati`. `k` è il numero degli elementi elencati. Nessuna voce è un
errore.

**Sezione 13, copertura del piano di prova.** `13. COPERTURA DEL PIANO DI PROVA: k`. Per ogni `VERIFICATION` del
file, in ordine di riga, si scrive la riga del blocco e, sotto, rientrate di quattro spazi, le righe seguenti:
- una riga per ogni mezzo di registrazione, `nome (riga M): id, id, …`, con le promesse e i presupposti della CSC
  legata di grado formale o di estensione dichiarata **osservati** da quel mezzo, nell'ordine della CSC, oppure
  `nessuna`. Una riga contrattuale è osservata da un mezzo se ogni stato, evento e richiesta che cita è fra gli
  elementi `OBSERVES` del mezzo. La copertura considera gli elementi, non i loro parametri: un mezzo che osserva
  `e.p` conta come mezzo che osserva l'evento `e`;
- una riga `non eseguite: id, id, …` con le righe contrattuali di grado formale o di estensione dichiarata che
  nessun mezzo osserva, oppure `non eseguite: nessuna`.

Le righe di grado verbale non hanno voce: sono verificate a giudizio o per ispezione. Se la CSC legata non è
trovata, sotto la riga del blocco compare soltanto `CSC non trovata: copertura non calcolata`. `k` è il numero dei
nomi brevi elencati nelle righe `non eseguite` di tutti i blocchi (`non eseguite: l2, l3` conta 2; `nessuna` conta
0). Esempio, per un piano di prova della luce delle scale con un mezzo di registrazione che osserva solo `accesa`:

```
13. COPERTURA DEL PIANO DI PROVA: 1
  riga 20: VERIFICATION Luce VERSION 0.1
    telecamera (riga 21): l1
    non eseguite: l2
```

### 9.7 Da giudicare e controlli non eseguiti

**Sezione 14, da giudicare.** `14. DA GIUDICARE: k`. La sezione contiene una voce per ogni regola del linguaggio
che richiede il giudizio di una persona, in ordine di riga e, a parità di riga, nell'ordine della tabella:

| Voce | Quando | Testo |
|---|---|---|
| un dettaglio con una riga a parole | una riga con `DETAILS` (contrattuale o storia) in cui la riga stessa o quella che dettaglia è a parole | `riga N: TIPO id DETAILS p: coerenza fra la riga e la riga che dettaglia, una delle due a parole` |
| il significato di un'estensione | ogni estensione senza errori E33 | `riga N: EXTENSION X: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti` |
| un'estensione senza riduzione | ogni estensione senza `REDUCES TO` riconosciuta | `riga N: EXTENSION X: non ripete una forma che il linguaggio ha già` |
| significato e riduzione | ogni estensione con una `REDUCES TO` riconosciuta | `riga N: EXTENSION X: MEANING e REDUCES TO dicono la stessa cosa` |

`N` è la riga della dichiarazione con `DETAILS` o della riga `EXTENSION`; `TIPO` è `GUARANTEE`, `ASSUME` o
`SCENARIO`.

**Quando una riga è «a parole».** Una promessa o un presupposto è a parole se il suo grado è `verbale`. Una
`DEFINE` non è mai a parole: il suo valore è un'espressione o `UNDECIDED`. Una storia è a parole se almeno un suo
passo ha un elemento `VERBAL`. Un dettaglio di `DEFINE` dettaglia un'altra `DEFINE` (E02 altrimenti): va quindi
sempre nella voce «coerenza dei dettagli» della sezione 15. Un dettaglio di storia va nella sezione 14 se la storia
o quella che dettaglia è a parole, altrimenti nella sezione 15.

Una riga non riconosciuta non è né a parole né formale: un dettaglio in cui una delle due righe non è riconosciuta va
nella sezione 14 solo se l'altra è a parole, e mai nella 15. Le voci della sezione 14 non sono errori, non compaiono
nella riga `esito` e non modificano il codice d'uscita: indicano ciò che resta da giudicare.

**Sezione 15, controlli non eseguiti.** `15. CONTROLLI NON ESEGUITI: k`. `check` non valuta le formule. In
particolare non controlla:
- se le storie hanno l'esito che dichiarano;
- se ogni innesco avviene in una storia;
- se le promesse e i presupposti possono valere insieme;
- se un dettaglio formale è coerente con la riga che dettaglia.

La sezione elenca, per ciascuno di questi controlli, le righe a cui si applicherebbe, in quest'ordine:

| Voce | Righe elencate |
|---|---|
| `storie` | le storie (`SCENARIO`) dei blocchi CSC ed entità che hanno almeno una promessa o un presupposto di grado formale, o di estensione dichiarata con `C3` nel `VERIFY V1` dell'estensione |
| `copertura degli inneschi` | le promesse di grado formale che hanno un innesco, e quelle di estensione dichiarata con `C4`. Hanno un innesco: `WHENEVER p THEN q`; `ALWAYS (p IMPLIES q)`; un ambito, anche un uso di un'estensione di `KIND SCOPE` con `REDUCES TO`; una forma di BASE con innesco nella sua forma estesa |
| `coerenza di presupposti e promesse` | le promesse e i presupposti di grado formale, e quelli di estensione dichiarata con `C2` |
| `coerenza dei dettagli` | le righe con `DETAILS` in cui nessuna delle due righe è a parole o non riconosciuta |

Una riga di grado «estensione dichiarata» è elencata in una voce quando **almeno una** delle estensioni che usa
(anche dentro l'argomento di un altro uso, sezione 4.14) dichiara il controllo nel proprio `VERIFY V1`: `C3` per
«storie», `C4` per «copertura degli inneschi», `C2` per «coerenza di presupposti e promesse». Elencare un controllo
in più non induce a ritenere controllata alcuna riga; ometterne uno sì.

Ogni voce si scrive `nome: righe N, M, …` (oppure `nome: riga N` con una sola riga), con le righe del file in ordine
crescente; una voce senza righe non viene scritta. `k` è il numero delle voci scritte. Esempio:

```
15. CONTROLLI NON ESEGUITI: 3
  storie: righe 30, 35
  copertura degli inneschi: righe 12, 14
  coerenza di presupposti e promesse: righe 12, 14, 20
```

Le righe contrattuali elencate nella sezione 15 non sono né rispettate né violate: un controllo non eseguito non
fornisce alcuna indicazione su di esse.

---

## 10. Il comando `bcdd check`

Forma: `bcdd check [--strict] [--json] [--dir CARTELLA]... FILE`.
- L'opzione `--strict` si può scrivere prima o dopo `FILE`, una volta sola.
- L'opzione `--json` si può scrivere prima o dopo `FILE`, in qualunque ordine rispetto alle altre opzioni, una
  volta sola. Il controllo è lo stesso, con gli stessi codici d'uscita e gli stessi messaggi sullo standard error.
  Sullo standard output, al posto del rapporto, `bcdd` scrive un solo oggetto JSON, con `"forma": "bcdd-check"` e
  `"versione": 5`. L'oggetto contiene, fra l'altro:
  - il campo `molteplicita` delle citazioni `PART` (sezione 4.9);
  - una dichiarazione `TYPE` per un elenco di valori, per un tipo con nome e per un `Record`, e `SCENARIO` per una
    storia d'entità;
  - `varianti` nei blocchi `ENTITY`; `variante` (`{"dimensione", "scelta"}` o `null`) in dichiarazioni, promesse e
    citazioni;
  - `in` (il suffisso senza parentesi né `in: `, o `null`) negli errori e negli usi, il cui `messaggio` e `testo`
    restano senza suffisso;
  - nel `rapporto`: `ha_composizioni`, `composizioni[]` (sezione 9 del rapporto) e `assenze[]` (sezione 10 del
    rapporto).
- Dalla versione 5 della forma l'oggetto contiene anche:
  - i valori `BINDING`, `VERIFICATION` e `PROFILE` di `blocchi[].tipo`; per un `BINDING` `legata`
    (`{"nome", "versione"}` della CSC legata) e `nome_proprio` (il nome distintivo dopo `AS`, o `null`); per un
    `PROFILE` `estensioni[]` (per ciascuna `nome`, `da`, `a`, `kind`, `level`, `riduzione` vero o falso);
  - `stato` `null` per una `VERIFICATION`;
  - le citazioni di tipo `IMPORT`, `LEGATA` e `USING` nelle `citazioni[]` di ogni blocco;
  - i valori `formale` ed `estensione_dichiarata` di `garanzie[].grado` e di `rapporto.gradi[].grado`, e il
    conteggio `rapporto.conteggi.estensione_dichiarata`, accanto a `verbale`, `formale` e `non_riconosciuta`;
  - i conteggi `rapporto.conteggi.forme_mancanti` (il `k` della sezione 12 del rapporto) e
    `rapporto.conteggi.non_eseguite_piano` (il `k` della sezione 13 del rapporto);
  - `rapporto.ha_binding` e `rapporto.ha_verification`, veri se il file ha almeno un blocco di quel tipo;
  - in `rapporto.ipotesi[]` (le righe da approvare) il campo `tipo` (`GUARANTEE`, `ASSUME`, `DEFINE`, `SCENARIO`,
    `BIND`, `EXTENSION`);
  - il campo `motivo` (o `null`) nelle voci di `rapporto.non_riconosciute[]`;
  - `rapporto.forme_mancanti[]`, `rapporto.copertura[]`, `rapporto.da_giudicare[]` e `rapporto.non_eseguiti[]`
    (sezioni 12, 13, 14 e 15 del rapporto), sempre presenti e vuoti quando la sezione manca.
- Dalla versione 5 non esistono più `rapporto.conteggi.non_lette`, `rapporto.blocchi_non_letti[]` né il valore
  `non_letta` di `righe[].tipo`, perché nessun blocco resta non letto. `esito.riga` è la riga `esito` del rapporto.
  Aggiungere un campo non cambia la versione della forma; toglierne uno, o cambiarne il significato, la cambia.
- Nella tabella qui sotto, dove lo standard output è «il rapporto», con `--json` va letto «l'oggetto JSON»; dove è
  «niente», resta vuoto.
- Ogni `--dir CARTELLA` si scrive prima o dopo `FILE`, in qualunque ordine rispetto alle altre opzioni. L'argomento
  che segue `--dir` è sempre la cartella, anche se comincia con `-`: `--dir --strict` cerca una cartella che si
  chiama `--strict`.
- Ripetere la stessa stringa dopo due `--dir` è un errore d'uso. Due stringhe diverse che indicano la stessa
  cartella (`a` e `./a`) sono ammesse, e la cartella si cerca con entrambe. Una `--dir` uguale alla cartella del
  file non è un errore.
- Ogni altro argomento che comincia con `-`, anche `--dir=X`, è un errore d'uso. Un file il cui nome comincia con
  `-` si indica con un percorso, per esempio `./-x.csc`.
- Le cartelle servono solo alla ricerca delle citazioni (sezione 9.4): in un file senza entità l'unico effetto delle
  cartelle è sulla prima riga del rapporto.

| Caso | Standard output | Standard error | Codice d'uscita |
|---|---|---|---|
| file letto, nessun errore; senza `--strict`, oppure con `--strict` e nessuna riga non riconosciuta | il rapporto | niente | 0 |
| file letto, almeno un errore (con o senza `--strict`) | il rapporto | niente | 1 |
| file letto, nessun errore, `--strict` e almeno una riga non riconosciuta | il rapporto | niente | 3 |
| file che non esiste: il sistema risponde che il nome non esiste, oppure che un componente del percorso non è una cartella; anche un collegamento simbolico il cui bersaglio non esiste | niente | `bcdd check: file non trovato: ARG` | 2 |
| è una cartella o non è un file regolare | niente | `bcdd check: non è un file: ARG` | 2 |
| ogni altro motivo per cui il file non si può esaminare o leggere: permessi del file, permessi di una cartella del percorso, errore di lettura | niente | `bcdd check: non leggibile: ARG` | 2 |
| byte non UTF-8 | niente | `bcdd check: il file non è UTF-8 valido (riga N)`, con N la riga del primo byte non valido | 2 |
| `--dir ARG`: il nome non esiste, o un componente del percorso non è una cartella | niente | `bcdd check: cartella non trovata: ARG` | 2 |
| `--dir ARG` esiste ma non è una cartella | niente | `bcdd check: non è una cartella: ARG` | 2 |
| `--dir ARG` è una cartella ma non si può aprire per leggerne il contenuto; oppure non si può stabilire se esiste, perché l'interrogazione del sistema fallisce per un altro motivo (per esempio una cartella del percorso senza permesso di attraversamento) | niente | `bcdd check: cartella non leggibile: ARG` | 2 |
| argomenti mancanti o in più; `--strict` ripetuto; `--json` ripetuto; `--dir` senza argomento; la stessa `--dir` ripetuta; ogni altra opzione che comincia con `-` | niente | `uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE` | 2 |

`ARG` è l'argomento così come è stato scritto. Ogni messaggio d'errore termina con un LF. I controlli si eseguono in
quest'ordine: gli argomenti; poi il file (che esista, che sia un file regolare, che sia leggibile, che sia in
UTF-8); poi le cartelle `--dir`, una alla volta nell'ordine scritto. Il primo controllo che fallisce determina il
messaggio. Un collegamento simbolico si risolve: un collegamento a una cartella vale come una cartella; un
collegamento il cui bersaglio non esiste dà «non trovata». Il messaggio «non leggibile» non indica volutamente la
causa: a chi esegue `check` basta sapere che il file non è stato controllato, e il codice 2 lo comunica.

**Che cosa prevale.** Se un file ha errori e anche righe non riconosciute, con `--strict` il codice d'uscita è 1:
gli errori prevalgono, perché sono il problema più grave e vanno corretti per primi. Le righe non riconosciute
restano visibili nella sezione 5 del rapporto e nella riga `esito`. In ordine di precedenza decrescente: 2 (il file
non si è potuto controllare), 1 (errori), 3 (solo righe non riconosciute, con `--strict`), 0. Il codice 3 si ottiene
quindi solo da un file letto per intero e senza errori. E14 è un errore come gli altri (codice 1). Né una citazione
non trovata, né una citazione trovata in un file con errori o con righe non riconosciute cambiano il codice d'uscita,
con o senza `--strict`.

Proprietà che `check` rispetta:
- il file non cambia mai, e non cambiano i file letti per le citazioni, nemmeno nella data di modifica;
- il grado di ogni riga contrattuale, ogni `UNDECIDED` e ogni riga da approvare sono nel rapporto;
- ogni regola che resta da giudicare (sezione 14 del rapporto) e ogni controllo non eseguito sulle formule (sezione
  15 del rapporto) sono nel rapporto: nessuna formula risulta controllata più di quanto lo sia davvero;
- ogni riga non riconosciuta è nella sezione 5 del rapporto, con il suo numero;
- lo stesso file, con gli stessi file citati e le stesse cartelle, produce sempre lo stesso rapporto, byte per byte,
  da qualunque cartella si esegua il comando, purché le `--dir` indichino le stesse cartelle (una `--dir` relativa
  indica una cartella diversa se cambia la cartella di lavoro);
- con `--strict` un file con anche una sola riga non riconosciuta produce un esito di errore (codice 3, o 1 se ci
  sono anche errori); senza `--strict` una riga non riconosciuta non cambia il codice d'uscita;
- ogni citazione di un'entità del file compare sotto l'entità, se è stata trovata; altrimenti compare nella sezione
  7 del rapporto, con il motivo se presente. Una citazione con E01 non viene cercata ed è segnalata dal suo errore
  nella sezione 1 del rapporto. Una citazione mancante, o un file citato con errori, non cambia l'esito;
- una versione citata diversa da quella trovata è nel rapporto (`, attesa VERSION w`);
- dentro un'entità con tutte le parti trovate, per una CSC che una parte usa, che nessun'altra parte offre e che
  l'entità non usa da fuori (con `USES`), `bcdd` segnala E14.

Con un comando sconosciuto, o con `bcdd` senza argomenti, lo standard output resta vuoto e sullo standard error
compare il testo seguente, su una sola riga terminata da LF; il codice d'uscita è 2:

```
uso: bcdd [--lang it|en] COMANDO; comandi: new NOME | check [--strict] [--json] [--dir CARTELLA]... FILE | refine FILE [--csc NOME] | ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero
```


**La lingua dei testi.** `bcdd` produce i suoi testi in inglese, oppure in italiano se richiesto. Forma:
`bcdd [--lang it|en] COMANDO …`.
- `--lang` si scrive soltanto prima del comando, come primi due argomenti. Dopo il comando è un'opzione
  sconosciuta, quindi un errore d'uso di quel comando. I valori sono esattamente `it` ed `en`.
- Precedenza: `--lang`, poi la variabile d'ambiente `BCDD_LANG` (`it` o `en`; una variabile vuota equivale a una
  variabile non impostata), poi l'inglese. Le variabili `LANG`, `LC_ALL` e `LANGUAGE` non si leggono.
- Un valore non valido è un errore d'uso: codice 2 e standard output vuoto. Sullo standard error compare
  `bcdd: --lang accetta it oppure en: ARG`, nella lingua che sarebbe in vigore senza l'opzione; per la variabile
  compare `bcdd: BCDD_LANG must be it or en, not: X`, sempre in inglese. `bcdd --lang` senza valore e
  `bcdd --lang it` senza comando producono la riga d'uso generale, codice 2.
- La lingua cambia soltanto i testi destinati a chi legge:
  - titoli e voci del rapporto, messaggi d'errore, uscite e rifiuti dei comandi;
  - righe d'uso (`uso:`/`usage:`, `NOME`/`NAME`, `CARTELLA`/`FOLDER`);
  - commenti e stringa di `PURPOSE` dello scheletro di `new` (sezione 11);
  - commento iniziale di un file del dialogo nuovo (sezione 13);
  - lettere delle risposte di `refine` (`s`, `n`, `f` in italiano; `y`, `n`, `q` in inglese);
  - nomi delle composizioni (`con P` e `senza P`, in inglese `with P` e `without P`, sezione 4.10);
  - con `refine`, anche il testo inviato al modello linguistico.
- Non cambiano: parole chiave, codici d'errore, numeri di riga e di colonna, prima riga del rapporto (che non
  riporta `--lang`), struttura del rapporto, codici d'uscita, valori letterali delle opzioni (`--expect nuovo`,
  `--modello veloce|accurato`), marcatori del file del dialogo, righe `STATUS RATIFIED BY` scritte da `ratify`.
- Con `--json` l'oggetto contiene in più, subito dopo `"versione"`, il campo `"lingua"` (`"it"` o `"en"`). Chiavi e
  valori enumerati non cambiano; cambiano soltanto i campi di testo destinati a chi legge (fra gli altri
  `messaggio`, `testo`, `motivo`, `esito.riga`). La versione della forma resta 5.
- `bcdd save`, usato da bcdd-editor e non descritto in questo documento, produce la sua riga d'uso nella lingua
  scelta.

---

## 11. Il comando `bcdd new`

`bcdd new NOME` crea nella cartella corrente il file `NOME.csc`.

| Caso | Standard output | Standard error | Codice | File |
|---|---|---|---|---|
| creato | `creato NOME.csc` | niente | 0 | creato, con il testo qui sotto |
| `NOME.csc` esiste già (file, cartella o collegamento) | niente | `bcdd new: NOME.csc esiste già: non lo sovrascrivo` | 1 | **non toccato** |
| NOME non è un Nome (regola L7) | niente | `bcdd new: nome non valido: NOME` | 2 | nessuno |
| argomenti mancanti o in più | niente | `uso: bcdd new NOME` | 2 | nessuno |
| NOME coincide, a prescindere da maiuscole e minuscole, con un nome che Windows riserva a un dispositivo (`CON`, `PRN`, `AUX`, `NUL`, `COM1`…`COM9`, `LPT1`…`LPT9`). Il controllo vale su ogni sistema, perché una cartella di CSC deve poter essere trasferita da Linux a Windows | niente | `bcdd new: il nome «NOME» non si può usare: Windows lo riserva per sé (nomi riservati: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Scegline un altro` | 2 | nessuno |
| il file non si può creare o scrivere: cartella senza permesso di scrittura, disco pieno, ogni altro errore del sistema | niente | `bcdd new: non riesco a creare NOME.csc: CAUSA` | 1 | nessuno, nemmeno un file temporaneo |

Il file viene creato per intero oppure non viene creato affatto: non deve mai restare scritto solo in parte.

**Quali nomi.** Nella regola L7 «non riservata» significa: non è una delle parole della sezione 2.3, la stessa lista
usata da `check`. Di conseguenza `bcdd new` non crea mai un file la cui intestazione sia rifiutata da `check`.

`CAUSA` è la descrizione dell'errore fornita dal sistema (per esempio `Permission denied`), su una riga. È l'unico
testo di `bcdd` che questo documento **non** fissa carattere per carattere, perché dipende dal sistema. Il testo è
fissato fino a `NOME.csc: ` compreso; dopo segue almeno un carattere e un solo LF finale. Il codice d'uscita è 1,
come per il file che esiste già: in entrambi i casi il comando è formulato correttamente, ma il file non viene
creato. Il codice 2 è riservato agli errori d'uso.

**Testo dello scheletro.** Al posto di `NOME` compare il nome indicato nel comando. Ogni riga termina con LF, anche
l'ultima; la codifica è UTF-8 senza BOM:

```
-- CSC creata da bcdd new. Si scrive a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga è contratto: è da approvare finché l'operatore non la approva.

CSC NOME VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "da scrivere: in una frase, di che cosa è responsabile NOME"

  -- Ingressi e uscite (togliere il commento e scrivere):
  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere
  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori
  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce
  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori

  -- Promesse a parole:
  -- GUARANTEE g1: VERBAL "che cosa promette"
  --               VERIFY BY JUDGEMENT "chi giudica, e su che cosa"
END
```

Lo scheletro contiene soltanto le righe obbligatorie (`CSC`, `VERSION`, `PURPOSE`, `END`) più `STATUS HYPOTHESIS`,
che rende esplicito lo stato che varrebbe comunque in assenza della riga. Il resto è commento: suggerisce le forme
senza creare righe da controllare.

---

## 12. Il comando `bcdd ratify`

`bcdd ratify` registra l'approvazione di una riga, o di tutte, modificando o aggiungendo soltanto indicazioni
`STATUS`. Opera sulle CSC, sulle promesse di un'entità, sui `BINDING` e sui profili; una `VERIFICATION` non si
approva. Gli esempi riguardano la luce delle scale.

### 12.1 Forma

```
bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-nnn
```

In un'entità `ratify` approva, con `ID`, una promessa e, con `--all`, tutte le promesse ancora da approvare. Non
approva mai l'intestazione, le righe `OFFERS` e `USES` né le parti dell'entità. Una promessa d'entità si approva
solo se ogni CSC che l'entità offre o usa è stata trovata, nella versione indicata, in un file senza errori (sezione
12.2, passo 7).

In una CSC `ID` può essere anche il nome di un dettaglio di `DEFINE` o il nome breve di un dettaglio di storia, che
si approvano come le righe contrattuali. Un `BINDING` si approva come una CSC, con l'intestazione o con `--all`; le
righe `BIND` non hanno un nome breve e non si approvano una per una. Un profilo si approva soltanto per intero, con
l'intestazione o con `--all` (che per un profilo ha lo stesso effetto): le estensioni non hanno uno stato proprio.

| Comando | Che cosa approva | Esempio |
|---|---|---|
| `bcdd ratify FILE D-nnn` | l'**intestazione** della CSC; le righe che ereditano (sezione 7.1, punto 4) diventano approvate con essa | `bcdd ratify LuceScale.csc D-135` |
| `bcdd ratify FILE ID D-nnn` | la **riga** `ID`, che deve essere da approvare | `bcdd ratify LuceScale.csc g2 D-135` |
| `bcdd ratify FILE --all D-nnn` | l'intestazione e **ogni** riga che resterebbe da approvare, in una sola scrittura | `bcdd ratify LuceScale.csc --all D-135` |

- Gli argomenti che non cominciano con `-` sono **posizionali**: due (`FILE D-nnn`) o tre (`FILE ID D-nnn`); con
  `--all` devono essere due.
- L'ultimo posizionale è il **riferimento della decisione**: regola L9 (`D-` seguito da sole cifre).
- Con tre posizionali, quello di mezzo è l'**ID**, il nome breve della riga: regola L8.
- `--csc NOME` sceglie il blocco (CSC, entità, `BINDING` o profilo) quando il file ne contiene più d'uno; `NOME`
  deve rispettare la regola L7. L'opzione si scrive in qualunque posizione, una sola volta, e `NOME` è l'argomento
  che la segue.
- `--all` si scrive in qualunque posizione, una sola volta, e non ha argomento.
- `--dir CARTELLA` vale come in `check` (sezione 10): in qualunque posizione, anche più volte. L'argomento che segue
  `--dir` è sempre la cartella, anche se comincia con `-`, e non conta fra i posizionali. Sono errori d'uso: la
  stessa stringa dopo due `--dir`, `--dir` come ultimo argomento e `--dir=X`. Le cartelle servono alla ricerca delle
  citazioni, nei passi 4 e 7 della sezione 12.2.
- Un file il cui nome comincia con `-` si indica con il percorso, per esempio `./-x.csc`, come in `check`.

### 12.2 Ordine dei controlli

Il primo controllo che fallisce determina il messaggio e il codice d'uscita; il file non si tocca.

1. Argomenti, in quest'ordine: numero dei posizionali e opzioni (`uso: …`), decisione, ID, nome indicato dopo
   `--csc` (le righe della sezione 12.5 con codice 2).
2. Lettura del file: gli stessi casi di `bcdd check` (sezione 10), con il prefisso `bcdd ratify:` al posto
   di `bcdd check:`.
3. Le cartelle `--dir`, una alla volta nell'ordine scritto, con i casi e i messaggi della sezione 10 e il prefisso
   `bcdd ratify:` (per esempio `bcdd ratify: cartella non trovata: ARG`), codice 2.
4. **Il file supera `bcdd check --strict`**: nessun errore e nessuna riga non riconosciuta in tutto il file. Si
   approva solo ciò che `bcdd` ha letto per intero. Il controllo cerca le citazioni delle entità come `check`: nello
   stesso file, nella sua cartella e nelle cartelle `--dir`. Un E14, un E04 o una riga non riconosciuta in
   un'entità impediscono l'approvazione di ogni blocco del file. Le voci delle sezioni 12-15 del rapporto non sono
   errori e non interrompono il passo 4.
5. **Scelta del blocco** (vale anche per `refine`):

   | Il file | Senza `--csc` | Con `--csc NOME` |
   |---|---|---|
   | almeno una CSC | fra le CSC, indipendentemente dalla posizione degli altri blocchi: se ce n'è una sola, è quella; se ce ne sono più d'una, `il file contiene N CSC: …` | il blocco `NOME` (vedi sotto) |
   | nessuna CSC, una sola entità | l'entità | il blocco `NOME` |
   | nessuna CSC, più entità | `il file contiene N ENTITY: indica quale con --csc NOME`, codice 2 | il blocco `NOME` |
   | nessuna CSC né entità, un solo blocco fra `BINDING` e `PROFILE` | quel blocco | il blocco `NOME` |
   | nessuna CSC né entità, più blocchi fra `BINDING` e `PROFILE` | `il file contiene N blocchi da approvare: indica quale con --csc NOME`, codice 2 | il blocco `NOME` |
   | nessun blocco `NOME` | — | `nessun blocco da approvare con il nome NOME nel file`, codice 1 |
   | nessuna CSC, entità, `BINDING` né `PROFILE` (solo `VERIFICATION`) | `il file non contiene nessun blocco da approvare: una VERIFICATION non si approva`, codice 1 | come senza `--csc` |

   Con `--csc NOME` il blocco è, nell'ordine: la CSC, l'entità o il profilo `NOME`; altrimenti il `BINDING` con il
   nome distintivo `NOME` (`AS NOME`); altrimenti l'unico `BINDING` senza nome distintivo legato alla CSC `NOME`. Un
   `BINDING` senza nome distintivo, nello stesso file della sua CSC, non si può scegliere per nome, perché il suo
   nome coincide con quello della CSC. Viene scelto senza `--csc` quando il file non ha CSC né entità; altrimenti
   gli si assegna un nome con `AS`. Il nome di una `VERIFICATION` non permette mai di scegliere un blocco.

   Per un file con una vista `REFINEMENT VIEW`, `bcdd` segnala E15, quindi `ratify` si ferma al passo 4.

6. Il bersaglio:
   - in una CSC: l'intestazione, la riga `ID` (che deve essere da approvare: una riga contrattuale o un dettaglio di
     `DEFINE` o di storia), oppure con `--all` l'insieme delle righe da cambiare, che non deve essere vuoto;
   - in un `BINDING`: l'intestazione, oppure con `--all` l'intestazione e le righe `BIND` con un proprio `STATUS` da
     approvare; con `ID` il comando rifiuta;
   - in un profilo: l'intestazione, con o senza `--all`; con `ID` il comando rifiuta;
   - **in un'entità**: senza `ID` né `--all` il comando rifiuta; con `ID`, una promessa da approvare dell'entità;
     con `--all`, tutte le promesse da approvare dell'entità, che devono essere almeno una (messaggi nella sezione
     12.5).
7. **I confini letti**, solo se il blocco scelto è un'entità. Per ogni riga `OFFERS` e `USES` dell'entità,
   nell'ordine di riga, valgono tre condizioni: la ricerca del passo 4 deve averla **trovata**; se la riga dichiara
   `VERSION w`, il blocco trovato ha `VERSION w` (stesso testo); il file del blocco trovato non contiene **errori**
   (le sue righe non riconosciute non contano). La prima riga che non rispetta le condizioni determina il messaggio
   (sezione 12.5), codice 1. Le parti non sono considerate; un'entità senza `OFFERS` né `USES` supera il passo. Per
   una CSC il passo non si applica: una CSC si approva anche se un'entità dello stesso file ha un confine mancante.
8. Costruzione del testo nuovo (sezione 12.3) e suo controllo, con le stesse cartelle: nessun errore, nessuna riga
   non riconosciuta, il bersaglio approvato; con `--all`, l'intestazione e **tutte** le righe contrattuali della
   CSC approvate, o in un'entità tutte le sue promesse. In caso contrario è un errore interno e il file non si
   tocca. È un controllo di sicurezza: non dovrebbe mai verificarsi.
9. Scrittura sicura: tutto o niente (sezione 12.6).

Una parte non trovata sospende E14 e non conta per il passo 7. Di conseguenza, senza `--dir`, una promessa d'entità
si approva anche se, indicando con `--dir` la cartella in cui la parte si trova, il file avrebbe un E14. Per questo
chi approva deve indicare le cartelle in cui si trovano le parti.

### 12.3 Le modifiche al file

Il comando apporta la modifica minima: senza `--all` cambia **una sola riga**, oppure ne aggiunge **una sola**; ogni
altro byte resta identico, compresi il BOM e i fine riga. `D-nnn` è il riferimento della decisione, riportato come è
stato scritto nel comando.

Il bersaglio della modifica dipende dal blocco:
- per l'intestazione si considera lo `STATUS` riconosciuto della zona d'intestazione (sezione 4.2: il primo, in
  qualunque posizione si trovi fra le righe d'intestazione). Nel caso c2 la riga si aggiunge subito dopo `CSC …`,
  anche se la zona contiene righe `IMPORT PROFILE`;
- per una riga si considera la prima riga della dichiarazione `GUARANTEE` o `ASSUME`, o del dettaglio di `DEFINE`
  o di storia. In un dettaglio di `DEFINE` il caso r2 inserisce ` STATUS RATIFIED BY D-nnn` subito dopo il nome
  breve che segue `DETAILS`, prima di `:=`; in un dettaglio di storia subito dopo il nome breve che segue
  `DETAILS`, prima di `GIVEN` o di `EXPECT`;
- l'intestazione di un `BINDING` e di un profilo cambia con i casi c1 e c2. Nel caso c2 il rientro è quello della
  prima dichiarazione dopo l'intestazione; se questa è l'`END` del blocco, è il rientro dell'`END` seguito da due
  spazi;
- una riga `BIND` con un proprio `STATUS HYPOTHESIS` cambia con il caso r1; una riga `BIND` senza `STATUS` eredita
  lo stato dell'intestazione e non viene modificata.

| Caso | Bersaglio | Che cosa fa | Prima | Dopo |
|---|---|---|---|---|
| c1 | intestazione con `STATUS HYPOTHESIS` | la sola parola `HYPOTHESIS` diventa `RATIFIED BY D-nnn`; rientro, spazi, commento e fine riga restano | `  STATUS HYPOTHESIS` | `  STATUS RATIFIED BY D-135` |
| c2 | intestazione senza `STATUS` | si **aggiunge** una riga subito dopo `CSC …`, con rientro, `STATUS RATIFIED BY D-nnn` e fine riga descritti sotto la tabella | `CSC LuceScale VERSION 0.1` / `  PURPOSE "…"` | `CSC LuceScale VERSION 0.1` / `  STATUS RATIFIED BY D-135` / `  PURPOSE "…"` |
| c3 | intestazione già `RATIFIED BY D-mmm` | **rifiuto**, codice 1 | | |
| r1 | riga con un proprio `STATUS HYPOTHESIS` | la sola parola `HYPOTHESIS` diventa `RATIFIED BY D-nnn` | `  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL …` | `  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-135: VERBAL …` |
| r2 | riga senza `STATUS` | si inserisce ` STATUS RATIFIED BY D-nnn` (con uno spazio davanti) subito dopo l'ultimo carattere dell'ultimo elemento prima dei due punti (il nome breve, o il nome breve dopo `DETAILS`); gli spazi prima dei due punti restano dopo il testo inserito | `  GUARANTEE g2: VERBAL …`; `  GUARANTEE g3 : VERBAL …` | `  GUARANTEE g2 STATUS RATIFIED BY D-135: VERBAL …`; `  GUARANTEE g3 STATUS RATIFIED BY D-135 : VERBAL …` |
| r3 | riga già approvata, per un proprio `STATUS RATIFIED BY` o per eredità (sezione 7.1, punto 4) | **rifiuto**, codice 1 | | |

Nel caso c2 il rientro della riga aggiunta è quello della prima riga di dichiarazione dopo l'intestazione (la prima
riga che non sia vuota né commento; esiste sempre, perché il file ha un `PURPOSE`), copiato byte per byte. Il fine
riga è quello della riga `CSC …`: CR LF se questa termina con CR LF, altrimenti LF.

L'intestazione di una riga contrattuale occupa sempre una sola riga del file (regola U2), quindi `ratify` cambia
sempre una sola riga per ogni bersaglio. Un dettaglio di una riga ancora da approvare si può approvare. Approvare
l'intestazione non cambia le righe che hanno un proprio `STATUS HYPOTHESIS` né i dettagli senza `STATUS`: restano da
approvare, e il comando lo segnala.

Un'interruzione con Ctrl-C prima della scrittura sicura termina il comando senza toccare il file; durante la
scrittura la sua gestione è rinviata fino al completamento (sezione 12.6).

**Con `--all`**: dopo il comando l'intestazione e ogni `GUARANTEE` e `ASSUME` della CSC sono approvate, con il
minimo cambiamento:

| Che cosa | Se è da approvare | Se è già approvata |
|---|---|---|
| l'intestazione | caso c1 o c2 | non cambia, e conserva la sua decisione |
| una riga con un proprio `STATUS HYPOTHESIS` | caso r1 | — |
| un dettaglio senza `STATUS` | caso r2 | — |
| una riga senza `STATUS` e senza `DETAILS` | — | eredita l'approvazione dell'intestazione: non cambia |
| una riga con un proprio `STATUS RATIFIED BY D-mmm` | — | non cambia, e conserva la sua decisione |

Le altre CSC del file non cambiano, e le righe delle entità restano identiche byte per byte.

**Le promesse di un'entità** si approvano con i casi **r1** (con un proprio `STATUS HYPOTHESIS`) e **r2** (senza
`STATUS`, base o dettaglio), una riga per promessa. Con `--all` si approvano tutte le promesse ancora da approvare
dell'entità, mai l'intestazione. Le righe `VERIFY` non vengono riallineate, anche quando il caso r2 sposta `VERBAL`
verso destra. Esempio: in un'entità `Scale` con una promessa base senza `STATUS` alla riga 5, un dettaglio con
`STATUS HYPOTHESIS` alla riga 7 e un dettaglio già approvato alla riga 9, `--all D-200` cambia la riga 5 (r2) e la
riga 7 (r1); la riga 9 non cambia.

**Una sola scrittura, tutto o niente.** `bcdd` costruisce in memoria tutto il testo nuovo, lo controlla una volta
(passo 8 della sezione 12.2) e lo scrive con una sola scrittura sicura (sezione 12.6). Se la scrittura non riesce, o
il comando viene interrotto prima, il file resta invariato: non può esistere un file con solo una parte delle righe
approvate.

Esempio: su una luce delle scale con intestazione `HYPOTHESIS` e quattro righe base senza `STATUS`, `--all D-201`
cambia la sola riga 4; le quattro righe ereditano l'approvazione dell'intestazione. Se la stessa CSC ha anche sei
dettagli con `STATUS HYPOTHESIS` (per esempio aggiunti da `refine`, che scrive sempre `STATUS HYPOTHESIS`), `--all`
cambia anche quelli (caso r1). Dopo il comando l'intestazione e i sei dettagli hanno `STATUS RATIFIED BY`; le
quattro righe base non hanno `STATUS` ed ereditano. Per `check` tutte e dieci le righe risultano approvate.

### 12.4 Uscita in caso di successo

Codice d'uscita 0, standard error vuoto. Lo standard output riporta i numeri di riga del file **dopo** la modifica.
Esempi su una luce delle scale (`D-200`, `D-201` e `D-202` sono riferimenti d'esempio):

```
$ bcdd ratify LuceScale.csc D-200
approvata la CSC LuceScale (riga 3) con D-200
contratto: 4
righe ancora da approvare: 0
```

`contratto` conta le `GUARANTEE` e le `ASSUME` della CSC che dopo la modifica sono approvate. Segue la riga
`righe ancora da approvare: K`, dove `K` è il numero di righe ancora da approvare; se `K` non è 0, seguono quelle
righe, una per riga (`  riga N: GUARANTEE id`), nell'ordine del file. Con righe che restano da approvare:

```
$ bcdd ratify R03_righe.csc D-130
approvata la CSC Righe (riga 3) con D-130
contratto: 2
righe ancora da approvare: 2
  riga 8: GUARANTEE g1a
  riga 11: ASSUME a1
```

```
$ bcdd ratify LuceScale.csc g2 D-200
approvata la riga 12: GUARANTEE g2 con D-200
```

```
$ bcdd ratify LuceScale.csc --all D-201
approvate con D-201 nella CSC LuceScale: 1 riga
  riga 4: CSC LuceScale
contratto: 4
```

In un'entità, con `ID`: `approvata la riga N: GUARANTEE ID con D-nnn`. Con `--all`:

```
$ bcdd ratify Scale.csc --all D-200
approvate con D-200 nella ENTITY Scale: 2 righe
  riga 5: GUARANTEE g1
  riga 7: GUARANTEE g1a
contratto: 3
```

`contratto` conta le promesse dell'entità, tutte approvate dopo il comando; l'intestazione non viene contata.

**`BINDING` e profili.** Per un `BINDING` le uscite sono quelle di una CSC, con `BINDING Nome VERSION v` (e
` AS b`) al posto di `CSC NOME`: `approvato il BINDING Luce VERSION 0.1 (riga 3) con D-200`. Segue `contratto: K`,
dove `K` è il numero di righe `BIND` approvate dopo il comando, e `righe ancora da approvare: K`, dove `K` è il
numero di righe `BIND` ancora da approvare, seguito dalle righe `riga N: BIND elemento`. Per un profilo l'uscita è
`approvato il PROFILE Segnale VERSION 0.3 (riga 2) con D-200`, seguita da `estensioni: K`, dove `K` è il numero di
estensioni del profilo, tutte approvate con esso. Le altre righe del file restano identiche byte per byte.

Con `--all` in un `BINDING` la forma è quella di `--all` in una CSC (descritta più sotto), con
`nel BINDING Nome VERSION v[ AS b]` al posto di `nella CSC NOME`. La prima riga conta le righe cambiate. Seguono
`riga N: BINDING Nome VERSION v[ AS b]` per l'intestazione (N è la riga di `STATUS`) e `riga N: BIND elemento` per
ogni riga `BIND` con un proprio `STATUS` approvato dal comando. L'ultima riga è `contratto: K`, con `K` il numero
delle righe `BIND` del blocco. Per esempio:

```
$ bcdd ratify Luce.csc --csc filo --all D-200
approvate con D-200 nel BINDING Luce VERSION 0.1 AS filo: 2 righe
  riga 10: BINDING Luce VERSION 0.1 AS filo
  riga 12: BIND accesa
contratto: 2
```

Con `--all` in una CSC l'uscita è la seguente. La prima riga conta le righe cambiate o aggiunte (`1 riga` al
singolare, altrimenti `N righe`). Segue una riga per ognuna, nell'ordine del file: `riga N: CSC NOME` per
l'intestazione (N è la riga di `STATUS`, anche quando è stata aggiunta) e `riga N: TIPO ID` per una riga
contrattuale (N è la sua prima riga). Poi compare `contratto: K`, con `K` il numero delle `GUARANTEE` e delle
`ASSUME` della CSC approvate dopo il comando.

Di norma non resta alcuna riga da approvare, e la riga «righe ancora da approvare» non compare. Restano da approvare
solo le righe che usano un'estensione di un profilo da approvare (sezione 7.1, punto 0a): sono righe che `--all`
non può approvare. In questo caso, dopo `contratto`, compaiono `righe ancora da approvare: K` e quelle righe, come
senza `--all`. Per esempio:

```
$ bcdd ratify R03_righe.csc --all D-130
approvate con D-130 nella CSC Righe: 3 righe
  riga 4: CSC Righe
  riga 8: GUARANTEE g1a
  riga 11: ASSUME a1
contratto: 4
```

```
$ bcdd ratify Luce.csc --csc Luce --all D-202
approvate con D-202 nella CSC Luce: 1 riga
  riga 4: CSC Luce
contratto: 3
righe ancora da approvare: 1
  riga 15: GUARANTEE g10
```

### 12.5 Errori e codici

Ogni messaggio va sullo standard error e termina con LF; lo standard output resta vuoto; il file non cambia.
`ARG`, `ID`, `NOME`, `FILE` sono gli argomenti come sono stati scritti.

| Caso | Messaggio | Codice |
|---|---|---|
| numero di posizionali diverso da 2 e da 3; `--csc` senza nome o ripetuto; `--all` ripetuto, o con tre posizionali; `--dir` senza argomento, o con la stessa cartella due volte; ogni altra opzione che comincia con `-`, anche `--dir=X` | `uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID \| --all] D-numero` | 2 |
| una cartella `--dir` che non esiste, non è una cartella o non è leggibile | come in `check` (sezione 10), con il prefisso `bcdd ratify:` | 2 |
| l'ultimo posizionale non è una decisione | `bcdd ratify: decisione non valida: ARG (serve D-numero)` | 2 |
| l'ID non rispetta la regola L8 | `bcdd ratify: id non valido: ARG` | 2 |
| il nome dopo `--csc` non è un Nome | `bcdd ratify: nome non valido: ARG` | 2 |
| file non trovato, non è un file, non leggibile, non UTF-8 | come in `check`, con il prefisso `bcdd ratify:` | 2 |
| il file non supera `bcdd check --strict` | `bcdd ratify: il file non passa bcdd check --strict (errori: E, righe non riconosciute: U): non approvo` | 1 |
| nessun blocco da approvare (solo `VERIFICATION`) | `bcdd ratify: il file non contiene nessun blocco da approvare: una VERIFICATION non si approva` | 1 |
| nessuna CSC né entità e più blocchi fra `BINDING` e `PROFILE`, nessun `--csc` | `bcdd ratify: il file contiene N blocchi da approvare: indica quale con --csc NOME` | 2 |
| un `BINDING` o un profilo con `ID` | `bcdd ratify: nel BINDING si approvano l'intestazione o --all, non una riga` (oppure `nel PROFILE si approva il profilo intero, non una riga`) | 1 |
| il `BINDING` o il profilo è già approvato | `bcdd ratify: il BINDING NOME VERSION v è già approvato (D-mmm): non cambio nulla` (oppure `il PROFILE NOME VERSION v`) | 1 |
| nessuna CSC e più entità, nessun `--csc` | `bcdd ratify: il file contiene N ENTITY: indica quale con --csc NOME` | 2 |
| più CSC e nessun `--csc` (`N` conta solo le CSC) | `bcdd ratify: il file contiene N CSC: indica quale con --csc NOME` | 2 |
| `--csc NOME` e nessun blocco da approvare con quel nome | `bcdd ratify: nessun blocco da approvare con il nome NOME nel file` | 1 |
| entità, senza `ID` né `--all` | `bcdd ratify: l'intestazione della ENTITY NOME non si approva: indica una GUARANTEE oppure --all` | 1 |
| entità, `ID` che non è alcun nome dell'entità | `bcdd ratify: nessuna GUARANTEE con id ID nella ENTITY NOME` | 1 |
| entità, `ID` nome di una parte o di una storia | `bcdd ratify: ID non è una GUARANTEE: in una ENTITY si approvano solo promesse` | 1 |
| entità, `--all` e nessuna promessa da approvare | `bcdd ratify: la ENTITY NOME non ha promesse ancora da approvare: non cambio nulla` | 1 |
| entità, un confine non trovato (passo 7) | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE non trovata: non approvo le sue promesse`; con un motivo della ricerca (sezione 9.4): `… non trovata (MOTIVO): …` | 1 |
| entità, un confine di un'altra versione | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE trovata in PERCORSO alla riga M con VERSION v: non approvo le sue promesse` | 1 |
| entità, un confine in un file con errori | `bcdd ratify: ENTITY NOME, riga N: CITAZIONE trovata in PERCORSO alla riga M, che ha E errori: non approvo le sue promesse` (`1 errore`) | 1 |
| la CSC è già approvata (caso c3) | `bcdd ratify: la CSC NOME è già approvata (D-mmm): non cambio nulla` | 1 |
| con `--all`: l'intestazione e tutte le righe sono già approvate | `bcdd ratify: la CSC NOME è già tutta contratto: non cambio nulla` | 1 |
| `ID` non è un nome della CSC | `bcdd ratify: nessuna GUARANTEE né ASSUME con id ID nella CSC NOME` | 1 |
| `ID` è un nome della CSC ma non di una riga contrattuale né di un dettaglio di `DEFINE` o di storia | `bcdd ratify: ID non è una GUARANTEE né una ASSUME: si approvano solo righe contrattuali e dettagli` | 1 |
| la riga è già approvata (caso r3; in un'entità, una promessa con un proprio `STATUS RATIFIED BY`) | `bcdd ratify: ID è già contratto (riga N): non cambio nulla` | 1 |
| controllo del testo nuovo fallito | `bcdd ratify: errore interno: il testo modificato non passa check; file non toccato` | 1 |
| errori della scrittura sicura | sezione 12.6 | 1 |

Nei messaggi sui confini `CITAZIONE` è la riga così come è scritta (`OFFERS X`, `USES X VERSION w`). `PERCORSO` è
scritto come nelle righe delle citazioni (sezione 9.4); se il blocco trovato è nello stesso file, al posto di
`in PERCORSO alla riga M` compare `in questo file alla riga M`. Nei messaggi «contratto» indica una riga approvata.

Il codice 2 significa «il comando non si è potuto eseguire così come è scritto»; il codice 1 significa «il comando
è chiaro, ma il file non lo permette». Vale la stessa distinzione di `bcdd new`.

### 12.6 La scrittura sicura

`bcdd ratify` scrive il file in modo che non resti mai scritto solo in parte e che non cambi nulla oltre a quanto il
comando dichiara:

1. il contenuto nuovo si scrive in un **file temporaneo nella stessa cartella** del file, con un nome che comincia
   con `.` e termina con `.tmp` seguito da un numero; poi se ne forza la scrittura fisica su disco;
2. il file temporaneo riceve gli stessi permessi del file originale;
3. **subito prima della sostituzione**, `bcdd` rilegge il file originale: se i suoi byte non sono più quelli letti
   all'inizio del comando, **non sostituisce** il file (per esempio perché nel frattempo chi scrive ha salvato il
   file con il suo editor);
4. il file temporaneo prende il posto del file originale con una sola operazione atomica del sistema, che riesce del
   tutto oppure lascia il file invariato;
5. in ogni caso di errore il file temporaneo viene cancellato: nella cartella non resta nulla.

Dalla creazione del file temporaneo fino alla sostituzione, il comando **rinvia** la gestione di Ctrl-C: completa la
scrittura e poi termina normalmente. Se `FILE` è un **collegamento simbolico**, si scrive il file a cui punta e il
collegamento non viene modificato. Se il file ha **più nomi** (collegamenti fisici), il comando rifiuta: la
sostituzione separerebbe gli altri nomi, che manterrebbero il contenuto precedente.

I messaggi vanno sullo standard error, con codice d'uscita 1; il file resta invariato. `FILE` è il nome del file come
è stato scritto, `CAUSA` la descrizione dell'errore fornita dal sistema, come in `bcdd new`:

| Caso | Messaggio |
|---|---|
| il file temporaneo non si crea o non si scrive (cartella non scrivibile, disco pieno) | `bcdd ratify: non riesco a scrivere FILE: CAUSA` |
| il file è cambiato dopo la lettura (punto 3) | `bcdd ratify: FILE è cambiato durante il comando: niente scritto` |
| il file ha più collegamenti fisici | `bcdd ratify: FILE ha più collegamenti fisici: non lo riscrivo` |

---

## 13. Il file del dialogo

Il file `FILE.dialogo` sta accanto al file CSC. Lo scrive solo `bcdd refine`, che vi conserva le domande del modello
linguistico e le risposte di chi scrive e ne invia il contenuto al modello nei giri successivi. `check` e `ratify`
non lo leggono, e non è un file CSC. Esempio, per la luce delle scale (le prime righe di un file con due giri):

```
-- bcdd refine: domande dell'LLM e risposte della persona. Si può modificare o cancellare a mano.

GIRO 2026-10-17T12:17:35+02:00 CSC LuceScale
DOMANDA Per g2: quanto tempo resta accesa la luce dopo l'ultima pressione, e con quale tolleranza?
RISPOSTA 1 minuto, con 5 s di tolleranza
DOMANDA Per g3: che cosa succede se qualcuno preme il pulsante mentre la luce è già accesa?
RISPOSTA il tempo di accensione riparte da capo
```

| Riga | Contenuto |
|---|---|
| la prima, un commento | presente dalla creazione del file, non cambia |
| `GIRO DATA CSC NOME` | l'inizio di un giro di `refine`, dopo una riga vuota; per un'entità `GIRO DATA ENTITY NOME`. `DATA` è la data e l'ora locali, al secondo, con il fuso orario, nella forma `AAAA-MM-GGTHH:MM:SS+HH:MM` (o `-HH:MM`): è quella d'inizio della prima chiamata al modello del giro. Ogni giro ha una sola riga `GIRO` |
| `DOMANDA testo` | una domanda a cui chi scrive ha risposto; le righe successive di una domanda lunga sono rientrate di due spazi |
| `RISPOSTA testo` | la risposta; per una scelta, il testo della scelta e non il numero |
| `CSC A PARTE NOME: MOTIVO` | una riga per ogni argomento nuovo che il modello ha segnalato e che è stato mostrato a chi scrive. Le righe seguono le coppie `DOMANDA`/`RISPOSTA` del giro, nell'ordine in cui gli argomenti sono stati mostrati |

Un giro si scrive se ha almeno una risposta o almeno una `CSC A PARTE`. Non si registrano le domande saltate, le
proposte e le sostituzioni: le proposte accettate e le sostituzioni accettate compaiono nel file CSC. Se il file
esistente non termina con LF, se ne aggiunge uno prima del nuovo giro; il resto del contenuto resta identico, byte
per byte, e la scrittura è quella sicura della sezione 12.6. Il file è testo UTF-8 con fine riga LF. Chi scrive può
correggerlo o cancellarlo; in questo caso il dialogo riparte senza le domande e le risposte precedenti.

---

## 14. Ciò che `bcdd` non controlla

L'elenco indica esplicitamente che cosa `bcdd` non controlla, affinché nessuno di questi aspetti sia ritenuto
controllato:
- **il significato delle formule**: `check` legge le formule e ne controlla forma, nomi e tipi, ma non le valuta.
  - Non controlla che una storia abbia l'esito che dichiara, che ogni innesco avvenga in una storia, che le
    promesse e i presupposti possano valere insieme, né che un dettaglio formale sia coerente con la riga che
    dettaglia: sono i controlli «non eseguiti» della sezione 15 del rapporto.
  - Non scrive la forma estesa delle abbreviazioni e non controlla che la riga `REDUCES TO` di un'estensione abbia
    tipi coerenti.
  - E36 segnala soltanto una riduzione costituita da un solo costrutto i cui operandi sono tutti parametri. Non è
    segnalata una riduzione equivalente scritta in un altro modo (`NOT NOT c`, `p AND p`, `x * 1`), né lo sono due
    estensioni dello stesso profilo con la stessa riduzione, salvo i nomi dei parametri;
- **le forme ritirate dal linguaggio o riservate**: `FACE`, `LINK`, `MAP`, `REFINED BY`, `REFINES` sono righe non
  riconosciute;
- **le regole da giudicare**: che un dettaglio a parole sia coerente con la riga che dettaglia, che il significato di
  un'estensione non descriva la realizzazione, che un'estensione senza riduzione non ripeta una forma del
  linguaggio, che `MEANING` e `REDUCES TO` esprimano lo stesso contenuto. Sono voci della sezione 14 del rapporto;
- **le registrazioni**: `check` non legge le tracce registrate su un sistema realizzato. La copertura della sezione
  13 del rapporto indica quali promesse un mezzo di registrazione osserva, non che siano rispettate;
- **i valori delle costanti**: `DEFINE ATTESA_MAX_LLM := 120 s` è riconosciuta, ma il suo valore non viene
  confrontato con alcun altro dato; un nome di costante dentro una stringa è testo (sezione 4.3);
- **le versioni**: se una `VERSION` è nuova, che cosa è cambiato rispetto alla versione approvata in precedenza, e
  se una riga con un proprio `STATUS RATIFIED BY` ha cambiato testo dopo l'approvazione (sezione 7.2);
- **i livelli dei dettagli**: non esiste un limite al numero di livelli e `bcdd` non emette avvisi (sezione 7.3);
- **i tipi non noti**:
  - un valore di un tipo non dichiarato, di un tipo descritto a parole, di una costante `UNDECIDED` o di un nome
    dato da un'estensione non si controlla (sezione 4.13);
  - in una storia d'entità non si controllano né un valore che è un nome né un elemento di una CSC citata il cui tipo
    non è un tipo di base (sezione 4.6);
  - in una formula d'entità nessun elemento `X.y` ha un tipo noto, quindi su quelle formule `bcdd` non segnala mai
    E25 (sezione 4.9);
- **gli usi di due tipi di estensione**: `bcdd` 1.0-beta non legge gli usi delle estensioni di `KIND RELATION` e
  `KIND SCENARIO-FORM`; le righe che li contengono sono non riconosciute (sezione 4.14);
- **i limiti degli intervalli**: `Real [20.0 .. -20.0]` è riconosciuta, perché i due limiti non vengono confrontati
  fra loro, nemmeno quando sono negativi. I limiti di un intervallo non si propagano nelle espressioni;
- **le unità**: sono riconosciute solo `s` e `ms`. Un'unità di misura diversa (`90 dB`) rende la riga non
  riconosciuta; l'unità va quindi indicata nel nome della costante e nel testo delle promesse;
- **le copie**: la molteplicità di una parte indica quante sono le copie, non quando vengono create e cessano, né
  come si distinguono. Le copie di una stessa parte non si soddisfano fra loro: l'`OFFERS` di una copia non vale per
  la `USES` di un'altra copia della stessa parte;
- **il ciclo di vita delle richieste**: non vengono segnalati né un `requested` di una richiesta `AUTONOMOUS`, né un
  `completed` che precede `accepted`;
- **il contenuto delle stringhe**: un `PURPOSE "da scrivere…"` lasciato invariato non è segnalato;
- **le altre CSC, oltre a quanto riporta la ricerca**: `check` cerca le CSC e le entità citate dalle entità del file e
  ne riporta versione, stato ed esito (sezione 9.4), ma:
  - la lettura ha un solo livello di profondità: di una parte non si leggono le parti né le CSC che essa cita. Non
    sono gestite le parti delle parti, un'entità che contiene se stessa oltre il primo livello e le parti con indice
    (`ago[ch] : Strumento`);
  - di una CSC citata si leggono le dichiarazioni soltanto per i nomi qualificati delle storie d'entità, non per i
    valori dei suoi elenchi di valori;
  - un blocco ritirato (`REFINEMENT VIEW`) non contiene parti né citazioni;
  - non controlla che le CSC offerte da un'entità siano sostenute da qualche parte: un'entità può offrire una CSC
    che nessuna parte offre da sola, e la valutazione spetta a chi giudica;
  - non controlla che una promessa d'entità derivi dalle promesse delle parti, né che chi usa una CSC ne rispetti i
    presupposti: sono giudizi;
  - non può stabilire se la CSC trovata è quella giusta: la cerca per nome e, se la citazione la indica, per
    versione. Una CSC con lo stesso nome in un'altra cartella indicata con `--dir` non viene esaminata se ne è già
    stata trovata una;
  - non legge il file `.dialogo` né i tipi dichiarati in un altro file; due `BINDING` per la stessa CSC in file
    diversi non si confrontano (E40 si applica soltanto al file controllato);
- **la collocazione e l'ordine delle entità**: il linguaggio non permette di indicare dove si trova un'entità
  (apparecchio, processo, macchina), né quale entità venga prima fra più entità sullo stesso lato di un confine. È
  una scelta del linguaggio, non un limite di `bcdd`;
- **il significato**: spetta a chi giudica, non a `bcdd`, stabilire se una promessa a parole è sensata, coerente con
  le altre o verificabile.
