# Il manuale del BCDD

<!-- SPDX-License-Identifier: CC-BY-4.0 -->
*Copyright 2026 Noli Paolo. Documento distribuito con licenza Creative Commons Attribuzione 4.0 Internazionale ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it)).*

---

## Come leggere questo manuale

Il **BCDD** è un linguaggio per specificare il comportamento di un sistema attraverso le sue interfacce con
l'esterno, chiamate *confini* (capitolo 1). Una descrizione BCDD è composta da file di testo che contengono **CSC**
(capitolo 1) ed entità (capitolo 12).

`bcdd` è il programma a riga di comando che controlla i file CSC; il suo uso è descritto nel capitolo 2, e i suoi
quattro comandi sono riassunti nel capitolo 29.

Il testo è costruito attorno a un esempio pratico, la luce delle scale di un condominio, considerata come
sistema: premendo un pulsante la luce si accende e, trascorso un certo tempo, si spegne da sola. Il capitolo 28
applica le stesse forme a un sistema reale, un kit di misura audio; il capitolo 29 riscrive la luce delle scale
dall'inizio alla fine.

I termini usati con un'accezione particolare sono illustrati nel testo alla loro prima occorrenza e raccolti
nel glossario (appendice C). L'appendice A elenca le parole chiave con il capitolo in cui ciascuna è
descritta; l'appendice B elenca gli errori segnalati da `bcdd` e ciò che il programma non controlla.

Il manuale descrive `bcdd` nella versione 1.0-beta, che riconosce tutte le forme del linguaggio descritte nel
manuale. Delle formule `bcdd` controlla la forma, i nomi e i tipi, ma non le valuta sulle storie: il rapporto
elenca i controlli non eseguiti (capitolo 24). Il manuale descrive inoltre la verifica sulle registrazioni
(capitolo 24), che nessun programma descritto qui esegue.

Le uscite di `bcdd` riportate nel manuale sono quelle del programma in italiano, ottenute con `bcdd --lang it …`
(l'opzione precede il comando) oppure con la variabile d'ambiente `BCDD_LANG=it`; senza queste indicazioni le uscite
di `bcdd` sono in inglese. Negli esempi i comandi compaiono senza l'opzione.

Il manuale illustra le regole della specifica del linguaggio senza aggiungerne di proprie:
in caso di discordanza fra i due testi prevale la specifica.

---

## Indice

L'indice riporta, per ogni capitolo, il contenuto e gli argomenti introdotti. I capitoli vanno letti
nell'ordine, perché ciascuno si basa sui precedenti. Le eccezioni sono due. Chi deve descrivere un solo
confine può passare dal capitolo 10 alla parte terza; la parte quarta richiede invece anche la parte seconda, perché
i suoi esempi riprendono le entità della parte seconda. I
capitoli 14, 15, 19 e 20 trattano casi particolari e si possono rimandare al momento in cui servono; i
capitoli 19 e 20 restano però necessari per il capitolo 28.

### Parte prima — Un confine, descritto a parole

Questa parte descrive la luce delle scale dal punto di vista di chi la usa, prima a parole e poi in un file.
Vengono presentate la scrittura, il controllo, l'approvazione e la modifica della descrizione di un sistema.

**1. Il confine e la promessa** — Il capitolo considera la luce delle scale dal punto di vista di chi la usa.
Ne ricava i due concetti su cui si fonda il linguaggio: il confine, cioè l'interfaccia fra un sistema e chi lo
usa, e la promessa, cioè ciò che il sistema garantisce su quel confine, insieme al modo di controllarla.

**2. La prima CSC** — Viene presentato il primo file CSC: la luce delle scale
descritta con due promesse a parole. Il file viene poi sottoposto al programma `bcdd`, che ne controlla
la forma.

**3. I presupposti** — Si introduce il presupposto, cioè la condizione su chi sta dall'altro lato del confine
da cui una promessa dipende. Nell'esempio la promessa è che la luce si accenda se il pulsante viene tenuto
premuto per almeno un decimo di secondo: se il pulsante viene solo sfiorato, la promessa non è violata.

**4. I due lati di un confine** — Il capitolo indica che una CSC si scrive dal lato di chi mantiene le
promesse, mentre chi sta dall'altro lato legge le stesse righe in senso inverso. Su questa base si aggiunge
alla luce un segnale per chi sta sulle scale: un avviso poco prima dello spegnimento.

**5. Le richieste** — A partire dalla richiesta del custode di tenere la luce accesa per le
pulizie, si descrive la scrittura di una richiesta, che ha prima una risposta, accettata o rifiutata, e poi
un esito, riuscita o fallita.

**6. I tipi dei valori** — La luce ha ora tre modi: spenta, accesa e accesa per le pulizie. Per descriverli
si introducono i tipi, che stabiliscono quali valori può assumere ciò che si osserva al confine, e gli elenchi
di valori con un nome.

**7. Da approvare e approvata** — Il capitolo indica chi approva una promessa da approvare: una persona che ne
ha l'autorità, mai il programma né il modello linguistico. Nel file si indica la decisione che l'ha approvata.
Al termine del capitolo la CSC della luce è approvata per intero, e viene presentato il comando di `bcdd` che
prepara lo scheletro di un file nuovo.

**8. Rendere precisa una promessa** — «Si spegne dopo un po'» diventa «si spegne 60 secondi dopo l'ultima
pressione, con 5 secondi di tolleranza», e una nuova pressione fa ripartire il tempo. A questo scopo si
introducono una riga più precisa, che si aggiunge senza cancellare la promessa a parole, e le costanti con
nome. Si introducono inoltre i numeri non ancora decisi e l'uso del modello linguistico, che pone domande sui
punti ancora vaghi.

**9. Esempi che fissano l'intenzione** — Si introducono le storie, descritte istante per istante, che
mostrano che cosa la luce deve fare e che cosa non deve fare: due pressioni a 100 secondi di distanza sono
ammesse, uno spegnimento troppo anticipato non è ammesso. Il capitolo ne indica anche il limite: una storia
non vieta nulla di ciò che non descrive.

**10. Cambiare una CSC già approvata** — La durata dell'accensione passa da 60 a 90 secondi. Poiché una CSC
approvata non si modifica, se ne scrive una versione nuova; il capitolo indica che cosa va approvato di nuovo
e che cosa resta approvato.

### Parte seconda — Più confini: le entità

Nella parte prima la luce ha un solo confine, ma un sistema ne ha spesso più d'uno. Questa parte descrive ciò
che sta dietro quei confini e li collega, e che si chiama entità.

**11. Confine unico o confini separati** — Il pulsante e la luce si possono descrivere separatamente, e la CSC viene divisa
in due: una per il pulsante premuto, una per la luce osservata. Il capitolo indica quando conviene dividere un
confine e mette in evidenza un problema: una promessa che riguarda entrambi i confini non può più essere
scritta in nessuna delle due CSC.

**12. Che cosa c'è dietro i confini: l'entità** — Si introduce l'entità, cioè ciò che sta dietro uno o più
confini; nell'entità si scrive la promessa «quando si preme il pulsante, la luce si accende». Un'entità si
descrive indicando i confini su cui mantiene promesse, quelli su cui si affida alle promesse di altri (per
esempio della rete elettrica) e le promesse che legano due suoi confini. Non si indica mai dove si trova.

**13. Un'entità fatta di parti** — La luce delle scale viene divisa in due parti, un pulsante e
una lampada, e il comando passa dall'uno all'altra; il confine fra le due parti resta interno all'entità. Si
introduce inoltre la regola per cui un confine usato da una parte deve essere offerto da un'altra parte,
oppure usato dall'entità stessa verso l'esterno: `bcdd` controlla la regola e segnala i casi in cui non è
rispettata.

**14. Un canale che perde o ritarda: il pulsante senza fili** — Il pulsante diventa senza fili, con un
ricevitore accanto alla lampada. Un canale che può perdere un messaggio, ritardarlo o alterare l'ordine dei
messaggi è un confine a sé, con la propria CSC: il capitolo descrive come trattarlo e come scrivere un confine
esterno all'entità.

**15. Le versioni dei confini** — Una lampada nuova usa la versione 0.2 del comando, mentre il
vecchio pulsante offre solo la 0.1. A partire da questo caso si descrive come indicare una versione precisa di
una CSC, in quali casi la versione usata e quella offerta corrispondono e come una parte può offrire insieme
due versioni dello stesso confine.

**16. Il numero di copie di una parte** — Nel caso di un pulsante per piano, da uno a cinque, si descrive come
indicare il numero di copie di una parte e che cosa promette ciascuna: ogni copia mantiene tutte le promesse
della parte, nessuna ha precedenza sulle altre e nessuna svolge compiti per conto delle altre.

**17. La dimensione di un'entità** — Il capitolo fornisce il criterio con cui si stabilisce se un'entità ha una
dimensione adeguata: lo è quando chi la realizza, una persona o un modello linguistico, riesce a considerare
insieme i suoi confini, le sue promesse e i confini delle parti vicine. Con questo criterio si spiega perché
la luce delle scale si divide in pulsante e lampada, e non oltre.

**18. Storie su più confini** — Nell'entità si scrive la storia «si preme il pulsante, ed entro un secondo la
luce è accesa». Poiché una CSC riguarda soltanto il proprio confine, l'ordine degli eventi su due confini
diversi si scrive nell'entità; davanti a ogni nome si indica la CSC da cui proviene.

**19. Una parte che può mancare** — Si introduce il sensore crepuscolare, che indica se
all'esterno è buio. Chi compone il sistema sceglie se montarlo, e la scelta non cambia più; il capitolo
descrive come scrivere che l'entità deve funzionare in entrambi i casi. `bcdd` controlla i due casi separatamente e,
quando il sensore non c'è, elenca ciò che manca senza considerarlo un errore.

**20. Più forme della stessa cosa: le varianti** — Il capitolo tratta quattro impianti diversi in un'unica
entità: plafoniera o applique, pulsante o sensore di presenza. Fra plafoniera e applique se ne sceglie una
sola, e questa scelta si combina con quella fra pulsante e sensore; la descrizione, però, non indica quale
alternativa viene scelta. Il capitolo descrive la scrittura di queste varianti; `bcdd` controlla ogni
combinazione e le elenca tutte.

### Parte terza — Promesse che uno strumento può controllare

Nei capitoli 1-20 le promesse sono scritte a parole e controllate da una persona. Questa parte descrive come
scriverle in forma di formule, che un programma può controllare senza l'intervento di una persona, e come
leggere i risultati del controllo. `bcdd` legge le formule dei capitoli 21-23 e ne controlla la forma, i nomi e
i tipi; la loro valutazione sulle storie e la verifica sulle registrazioni del capitolo 24 non sono eseguite da
alcun programma descritto nel manuale.

**21. Il passo e le prime formule** — La promessa «quando si preme il pulsante, la luce si
accende» diventa una formula. Una formula descrive il comportamento del sistema passo per passo; le sue parole chiave
di base sono «sempre», «prima o poi», «ogni volta che… allora» e «mentre», e «nello stesso passo» precisa la
conseguenza di «ogni volta che… allora». Si introducono gli operatori di confronto e di calcolo e la loro
precedenza. La promessa cambia forma, ma conserva il proprio nome.

**22. Il tempo nelle formule** — Viene scritta come formula la promessa «la luce si spegne 90
secondi dopo l'ultima pressione». A questo scopo si introducono le forme per esprimere «entro un certo tempo»,
il tempo trascorso da un evento e il numero di volte in cui un evento è accaduto. Si introducono inoltre il
filtro sui parametri di un evento, il valore che uno stato aveva nel passo precedente e le storie che si
ripetono.

**23. Le abbreviazioni** — La promessa «la luce non è mai accesa se nessuno ha premuto» si può scrivere in
forma breve e in forma estesa. Alcune forme sono infatti abbreviazioni: ognuna ha una forma estesa, scritta
con le formule dei capitoli 21 e 22, che ha lo stesso significato. Il capitolo introduce anche l'insieme chiuso
delle transizioni di uno stato, le costanti calcolate, le funzioni, gli eventi derivati, i tipi con nome, i record e gli
stati con indice.

**24. Il significato di «verificato»** — A partire dalla CSC della luce scritta con formule si
mostra che la verifica avviene in due momenti: sul testo, prima della costruzione, e sulle registrazioni di
un sistema costruito. Il capitolo spiega inoltre perché il giudizio di una persona non si combina mai con il
risultato di un programma e perché «rispettata sulla traccia» vale solo per ciò che è stato osservato. Descrive
infine che cosa accade quando un presupposto non è rispettato e quali controlli esegue `bcdd`.

### Parte quarta — Oltre il comportamento

Le parti precedenti descrivono che cosa fa il sistema. Questa parte descrive come il sistema si presenta
concretamente all'esterno, come lo si prova e come procedere quando le parole chiave del linguaggio non
bastano. `bcdd` legge i
blocchi di questi tre capitoli e li controlla sui nomi della CSC a cui sono legati.

**25. La forma concreta dei confini** — Il comando che il pulsante invia alla lampada è, in concreto, un
contatto chiuso sul morsetto 3 per almeno 50 millisecondi; il relè che accende la lampada, invece, non è
osservabile da chi sta sulle scale. Il capitolo descrive le forme concrete in cui un confine si presenta, che
si tratti di un morsetto, di un testo sullo schermo o di un formato di file, e l'unico criterio con cui si
decide che cosa scrivere: «chi lo vede?». Le forme concrete si scrivono in un blocco `BINDING`.

**26. Il piano di prova** — Per provare la luce si prepara un piano di prova: un sensore di luce
davanti alla lampada e una telecamera che riprende il pulsante e la lampada. Nel blocco `VERIFICATION` si indicano
quali mezzi registrano un confine e con quale risoluzione; `bcdd` calcola quali promesse ciascun mezzo osserva e
quali restano non eseguite.

**27. Estensioni e profili** — Si vuole specificare che la luce non si spegne istantaneamente ma si attenua
gradualmente in due secondi, e il linguaggio non prevede una forma per esprimerlo. Il capitolo descrive come
aggiungere una forma nuova, con il suo significato e il modo di verificarla. Descrive inoltre come raccogliere
le forme di un campo d'uso in un profilo che una CSC importa, e che cosa sono le parole in prova, che una
revisione del linguaggio può spostare in un profilo.

### Parte quinta — Applicazione a un sistema reale

La parte applica gli argomenti dei capitoli precedenti, prima a un caso reale, poi riprendendo l'esempio
dall'inizio alla fine.

**28. Un caso reale: il kit di misura audio** — Viene esaminata la descrizione di un sistema reale, di
dimensioni maggiori: un kit di misura audio, con due scelte per il sensore di livello e una parte facoltativa,
la direct box, che preleva il segnale ai morsetti dei diffusori. Il capitolo non introduce argomenti nuovi: nella descrizione e nel rapporto di `bcdd`
ricompaiono gli argomenti dei capitoli precedenti.

**29. Il procedimento completo, dall'inizio alla fine** — La luce delle scale viene riscritta da capo,
usando in sequenza i quattro comandi di `bcdd`. Il capitolo indica anche che cosa il programma non fa: non
giudica se una promessa è corretta, non interpreta il testo fra virgolette e non confronta due versioni della
stessa CSC.

### Appendici

**A. Le parole chiave, nell'ordine in cui sono introdotte** — Per ogni parola chiave del linguaggio, il
capitolo in cui è descritta.

**B. Che cosa controlla `bcdd`** — Gli errori segnalati dal programma, descritti a parole e
accompagnati dal codice che compare nel rapporto; ciò che `bcdd` non controlla.

**C. Glossario** — I termini del manuale con il loro significato.

---

## Capitolo 1 — Il confine e la promessa

Si consideri la luce delle scale di un condominio. Chi entra nell'androne preme il pulsante e la luce si
accende; dopo un certo tempo, senza ulteriori azioni, la luce si spegne da sola. Se il pulsante viene premuto
di nuovo mentre la luce è ancora accesa, la luce resta accesa più a lungo; questo comportamento è trattato nei
capitoli 8 e 9.

Chi usa la luce non sa come funziona all'interno. Dietro il muro può esserci un relè, un temporizzatore
elettronico o un piccolo computer, e saperlo non è necessario. Servono soltanto due informazioni: che cosa si
può fare, cioè premere, e che cosa ci si aspetta come risultato, cioè che la luce resti accesa per il tempo
necessario a salire le scale.

Il manuale descrive come scrivere con precisione queste due informazioni.

### Il confine

L'impianto di illuminazione è un **sistema**. Nel manuale il termine indica qualunque elemento della
descrizione, piccolo o grande: un impianto, un programma, un apparecchio sono tutti sistemi.

Fra chi usa la luce e l'impianto di illuminazione c'è un'interfaccia, costituita dal pulsante premuto e dalla
luce osservata: è il **confine**. In generale, un confine è l'interfaccia fra un sistema e un altro
interlocutore, una persona o un altro sistema, nella quale si può osservare ciò che passa fra i due. Ogni confine
ha due **lati**: nell'esempio, da un lato c'è chi sta sulle scale, dall'altro l'impianto.

Il confine della luce delle scale è attraversato da due elementi:

- da chi sta sulle scale all'impianto, il pulsante premuto;
- dall'impianto a chi sta sulle scale, la luce, accesa o spenta.

Per ora il pulsante e la luce sono trattati come un unico confine; nel capitolo 11 il confine viene diviso
in due.

Ciò che accade dietro il confine non è osservabile dall'esterno. Per chi sta sulle scale l'impianto è una
**scatola nera**: un sistema di cui si conosce solo ciò che entra e ciò che esce.

### La promessa

Su un confine, uno dei due lati assume un impegno verso l'altro. L'impianto di illuminazione, per esempio, si
impegna così: «se si preme il pulsante, la luce si accende». Una frase di questo tipo è una **promessa**:
indica ciò che un lato del confine garantisce a chi sta dall'altro lato.

Una promessa riguarda solo ciò che si osserva al confine. «Se si preme il pulsante, la luce si accende» è
ammissibile, perché il pulsante premuto e la luce stanno entrambi al confine; «il relè si chiude» non lo è,
perché il relè sta dentro la scatola e chi è sulle scale non lo può osservare.

### Il controllo

Una promessa è utile solo se è controllabile. «La luce funziona bene» non lo è: non indica per chi, né con
quale misura. «La luce si accende quando si preme il pulsante», al contrario, è controllabile: si preme e si
osserva. Lo è anche «la luce si spegne sessanta secondi dopo l'ultima pressione», con un cronometro.

Per questo ogni promessa è accompagnata dal suo **controllo**: chi verifica che sia rispettata, e in che modo. Una
promessa senza controllo non è sbagliata, ma è incompleta.

### Perché scriverla

Si considerino due persone: l'amministratore del condominio, che vuole la luce delle scale, e l'elettricista,
che la deve costruire. Un accordo a voce lascia a ciascuno dei due un ricordo diverso; se invece le promesse
vengono scritte prima dell'inizio dei lavori, entrambi dispongono di un testo su cui sono d'accordo. A lavoro
finito lo stesso testo serve per il collaudo: per ogni promessa si esegue il relativo controllo.

Una promessa appena scritta è **da approvare**: diventa un impegno effettivo solo quando la approva chi
ne ha l'autorità, in questo caso l'amministratore. La scrittura dell'approvazione è descritta nel
capitolo 7.

Il BCDD è destinato soprattutto a sistemi molto più grandi di una luce, nei quali questo accordo è ancora più
importante. Un sistema grande si divide in **parti**, cioè in sistemi più piccoli, e ogni parte si descrive solo
attraverso i propri confini, come la luce delle scale. Chi costruisce una parte riceve soltanto la descrizione
dei suoi confini. Può trattarsi di una persona o di un **modello linguistico**, cioè un programma, addestrato su
grandi quantità di testo, che genera testo e codice a partire da istruzioni scritte in linguaggio naturale. La regola è la stessa per entrambi: la descrizione dei confini deve
bastare a stabilire che cosa fare, senza che occorra conoscere l'interno delle altre parti.

Costruire il sistema che mantiene le promesse si dice **realizzarlo**; il sistema costruito, con tutte le sue
scelte interne, è la **realizzazione**.

### Che cosa non si scrive

La costruzione interna del sistema non si scrive: non si scrivono fili, programmi, schede elettroniche,
formule di calcolo né sequenze interne di operazioni fra una parte e l'altra. Sono scelte di chi realizza il sistema; se fossero scritte,
chi lo realizza non potrebbe più modificarle, nemmeno trovando un modo migliore per mantenere le stesse
promesse.

Per la stessa ragione non si scrive **dove** si trova il sistema: su quale muro, in quale programma, su quale
apparecchio. Anche questa è una scelta di chi lo realizza.

### I nomi

La sigla **BCDD** deriva dall'inglese *Behavioural Contract-Driven Design*, cioè progettazione guidata da
contratti sul comportamento. Il **comportamento** è ciò che si osserva dall'esterno: che cosa entra, che cosa
esce e in quale momento. Un **contratto** è l'insieme delle promesse approvate su un confine, cioè un impegno
accettato da entrambi i lati; dal capitolo 3 ne fanno parte anche i presupposti approvati.

La descrizione scritta di un confine si chiama **CSC**, dall'inglese *Capability State Contract*: un
contratto su ciò che si può richiedere e su ciò che si può osservare. Il nome contiene la parola «contratto»
perché una CSC, una volta approvata, è un contratto a tutti gli effetti. La prima CSC è presentata nel
capitolo 2.

### Riepilogo

- Il **confine** è l'interfaccia fra un sistema e una persona o un altro sistema, e ha due lati.
- Su quel confine, una **promessa** indica che cosa un lato garantisce all'altro; riguarda solo ciò che si
  osserva al confine.
- Una promessa è completa solo con il suo **controllo**: chi la verifica, e come. Finché non è approvata, la
  promessa è «da approvare».
- La costruzione interna del sistema e la sua collocazione non si scrivono: le decide chi lo realizza.
- La descrizione scritta di un confine si chiama **CSC**.

### Casi particolari

**Promessa non controllabile.** Una promessa come «la luce è comoda» è un testo valido, ma non è utile a
nessuno dei due lati: l'elettricista non ha indicazioni su che cosa costruire e il collaudo non ha nulla da
misurare. Come mostra il capitolo 2, `bcdd` segnala un errore per una promessa priva della riga di controllo;
spetta invece a chi scrive la CSC giudicare se il controllo scritto abbia senso.

**Elemento interno: non si indica.** Un relè, anche se l'elettricista lo deve installare e cablare, è una
scelta di chi realizza il sistema e non va scritto nella promessa. Diverso è il caso in cui qualcuno,
all'esterno della scatola, deve usare un morsetto preciso: quel morsetto fa allora parte di ciò che si osserva
al confine, e il caso è trattato nel capitolo 25.

**Sistema con più confini.** La luce delle scale ha più di un confine, come mostra il capitolo 11. In
questo capitolo se ne considera uno solo: quello fra chi sta sulle scale e l'impianto.

---

## Capitolo 2 — La prima CSC

Nel capitolo 1 la luce delle scale è descritta a parole. In questo capitolo la stessa descrizione viene
scritta in un file, in una forma che un programma può leggere.

### Il file

Una CSC è un file di testo con estensione `.csc`, che si apre e si modifica con un qualsiasi editor di testo.
Il file `UsoLuce.csc` descrive la luce delle scale dal punto di vista di chi sta sulle scale:

```
-- La luce delle scale, vista da chi sta sulle scale.

CSC UsoLuce VERSION 0.1
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  EVENT IN  premuto
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
END
```

Il file è composto da tredici righe, descritte di seguito una alla volta.

### Riga per riga

La prima riga comincia con due trattini, `--`: è un **commento**, cioè una nota per chi legge, che il
programma ignora. Un commento può comparire in qualsiasi punto, anche in fondo a una riga.

`CSC UsoLuce VERSION 0.1` apre la descrizione. `CSC` indica l'inizio di una CSC; `UsoLuce` è il nome
assegnato alla CSC; `VERSION 0.1` è il suo numero di versione. Quando la CSC cambia, cambia anche il numero
(capitolo 10).

Le parole scritte in maiuscolo, come `CSC`, `VERSION` e `PURPOSE`, sono le **parole chiave** del linguaggio:
parole fisse, in inglese, che il programma riconosce. Tutto il resto è scelto da chi scrive.

`PURPOSE` introduce lo **scopo**, una frase che indica a che cosa serve il confine. È la prima riga da
scrivere e anche la più importante, perché il resto della CSC serve a precisare questa frase.

`EVENT IN premuto` indica che cosa **arriva** al confine dall'altro lato: qualcuno preme il pulsante. Si
tratta di un **evento in ingresso**. Un evento è qualcosa che accade in un istante e poi è concluso; `premuto`
è il nome assegnato all'evento.

`STATE accesa : Boolean INITIAL false` indica invece che cosa **si osserva** al confine in ogni istante: se
la luce è accesa. Uno **stato**, a differenza di un evento, non accade per poi concludersi: ha sempre un valore.
Dopo i due punti si indica il suo **tipo**, cioè l'insieme dei valori che può assumere. `Boolean` indica un
valore logico, vero o falso, scritto `true` o `false`. `INITIAL false`, infine, è il **valore iniziale**: all'avvio dell'impianto la
luce è spenta.

La prima promessa è `GUARANTEE g1: VERBAL "…"`. `GUARANTEE` significa «garanzia», cioè promessa. `g1` è il suo
**nome breve**, che serve a citare la promessa nei rapporti del programma e nei documenti. `VERBAL` indica
che la promessa è scritta a parole, in una lingua naturale, come la si scriverebbe per una persona. Il testo
è racchiuso fra virgolette; un testo fra virgolette si chiama **stringa**.

Subito sotto, `VERIFY BY JUDGEMENT "…"` è il controllo di quella promessa. `JUDGEMENT` significa «a
giudizio»: una persona esegue una prova e giudica. Fra le virgolette si indica chi giudica e su che cosa. Se
invece è sufficiente esaminare qualcosa di già scritto o registrato, si usa `VERIFY BY INSPECTION`, «per
ispezione»: per esempio `VERIFY BY INSPECTION "il registro delle accensioni"`.

La seconda promessa, `g2`, ha la stessa forma. L'espressione «dopo un po'» è vaga; per ora è
accettabile, e nel capitolo 8 viene resa precisa.

Infine, `END` chiude la descrizione.

### Tre regole di scrittura

Una CSC come questa si scrive seguendo tre regole.

1. Ogni riga, tranne i commenti e le righe vuote, comincia con una parola chiave, in inglese e in maiuscolo.
   Altre parole chiave (`VERSION`, `INITIAL`, `VERBAL`, `BY`) compaiono all'interno della riga. Gli spazi a
   inizio riga servono solo a chi legge: il programma li ignora.
2. Il testo libero, cioè scopo, promesse e controlli, va fra virgolette, nella lingua scelta da chi scrive. Anche i nomi
   scelti da chi scrive, come `UsoLuce`, `premuto` e `accesa`, possono essere in italiano.
3. Ogni `GUARANTEE` ha il suo `VERIFY`, scritto di norma nella riga seguente.

### Questa CSC è già valida

Una CSC scritta interamente a parole, come questa, è già valida ed è sufficiente come punto di partenza: una
persona o un modello linguistico può già realizzare la luce a partire da essa. Resta però vaga, perché «dopo
un po'» non indica quanto; la precisione viene aggiunta nei capitoli seguenti. Le due promesse, inoltre, sono
ancora da approvare.

A partire dal capitolo 21 le promesse vengono scritte anche in forme che un programma può controllare
autonomamente. Ogni forma nuova si aggiunge quando serve, una riga alla volta.

### Il primo controllo

Il programma si chiama `bcdd`. È un programma a riga di comando: si avvia scrivendo il suo nome nel
terminale. Se è distribuito insieme al manuale, l'eseguibile è il file `bcdd`, e le possibilità sono due. La
prima è avviarlo dalla cartella che contiene il file `.csc`, indicando il percorso dell'eseguibile. La seconda
è copiarlo in una cartella inclusa nel percorso di ricerca dei programmi (`PATH`) e avviarlo solo con il nome,
come negli esempi di questo manuale.

Il comando `bcdd check` legge un file `.csc` e riporta se è scritto correttamente e che cosa contiene; il file
non viene mai modificato. L'**opzione** `--strict`, cioè un'aggiunta al comando che ne cambia il
comportamento, rende il controllo più severo, nel modo descritto più avanti.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 13 (riconosciute 9, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, senza STATUS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 2
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 9: GUARANTEE g1 verbale
  riga 11: GUARANTEE g2 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 2
  riga 9: GUARANTEE g1
  riga 11: GUARANTEE g2

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

Il rapporto si legge dall'alto.

All'inizio del rapporto `bcdd` riporta il numero delle righe del file. Ogni riga appartiene a una sola categoria (riconosciuta, commento,
vuota o non riconosciuta), in modo che nessuna riga vada persa. Segue l'elenco dei **blocchi**, cioè delle
descrizioni contenute nel file: qui ce n'è una sola, la CSC alla riga 3. L'etichetta «senza STATUS» indica che
non è ancora stato scritto se la CSC è da approvare o approvata. In assenza di indicazione vale «da
approvare»; la sintassi relativa è descritta nel capitolo 7.

La sezione 1 elenca gli **errori**, cioè i costrutti che il programma riconosce ma che sono scritti in modo
scorretto. In questo caso non ce ne sono.

La sezione 2 riguarda le **righe contrattuali**, quelle che entrano nel contratto quando vengono approvate:
per ora, le promesse. Per ciascuna è indicato il **grado**, cioè il modo in cui la promessa è scritta: a
parole (`verbale`, nel senso di «fatta di parole») oppure con una formula che un programma può controllare
(`formale`). Le due promesse dell'esempio sono scritte a parole.

La sezione 4 elenca le promesse **da approvare**, che il rapporto riporta sotto «DA APPROVARE, NON CONTRATTO»: una promessa
da approvare, finché non viene approvata, non fa parte del contratto. Per ora è la
situazione attesa.

La sezione 5 elenca le righe che il programma **non ha riconosciuto**. Le sezioni 3, 6 e 7 sono descritte nei
capitoli in cui diventano rilevanti.

L'ultima riga è l'**esito**. L'esito «nessun errore» significa che il file è scritto correttamente, non che
le promesse siano corrette: questa valutazione spetta a chi scrive la CSC.

Con l'opzione `--strict` è sufficiente una sola riga non riconosciuta perché il controllo abbia esito
negativo. Se ne
raccomanda l'uso sistematico.

### Riepilogo

- Una CSC è un file `.csc`: comincia con `CSC Nome VERSION numero` e termina con `END`.
- Contiene lo scopo (`PURPOSE`), ciò che arriva (`EVENT IN`), ciò che si osserva con il suo valore iniziale
  (`STATE … INITIAL`) e le promesse a parole (`GUARANTEE … VERBAL`).
- Subito sotto ogni promessa si trova il suo controllo: `VERIFY BY JUDGEMENT` o `VERIFY BY INSPECTION`.
- Una CSC scritta interamente a parole è già valida, ma le sue promesse restano da approvare.
- `bcdd check --strict` controlla la forma del file senza modificarlo; «nessun errore» non significa che le
  promesse siano corrette.

### Casi particolari

**Controllo mancante.** Se si toglie la riga `VERIFY` sotto `g2`, il rapporto riporta:

```
1. ERRORI: 1
  riga 11: [E13] VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa
```

Si tratta di un errore, perché una promessa senza controllo è incompleta (capitolo 1). Il codice fra
parentesi quadre, `E13`, permette di cercare l'errore nell'appendice B.

**Scopo mancante.** Anche l'assenza della riga `PURPOSE` è un errore:

```
1. ERRORI: 1
  riga 3: [E10] PURPOSE mancante nella CSC UsoLuce
```

**Nome breve ripetuto.** Se anche la seconda promessa si chiama `g1`, il programma lo segnala alla seconda,
perché un nome breve serve a citare una sola promessa:

```
1. ERRORI: 1
  riga 11: [E01] nome già usato alla riga 9: g1
```

**Parola chiave in minuscolo.** Se si scrive `guarantee g2:` invece di `GUARANTEE g2:`, il programma non
segnala un errore, perché la riga non corrisponde ad alcuna forma del linguaggio. La riga viene classificata
fra quelle non riconosciute, e con essa anche la riga di controllo, che resta priva della sua promessa:

```
5. RIGHE NON RICONOSCIUTE: 2
  riga 11: guarantee g2: VERBAL "La luce si spegne da sola dopo un po'"
  riga 12: VERIFY BY JUDGEMENT "una persona con un orologio"
```

Senza `--strict` la segnalazione compare nell'esito: `esito: nessun errore; righe non riconosciute: 2 (vedi sezione 5)`.
Una riga non riconosciuta viene quindi sempre segnalata; con `--strict` il controllo ha esito negativo.

**Stato senza valore iniziale.** La riga `STATE accesa : Boolean`, senza `INITIAL false`, non viene
riconosciuta:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 7: STATE     accesa : Boolean
…
esito: nessun errore; righe non riconosciute: 1 (--strict)
```

Uno stato ha sempre un valore, anche nel primo istante: per questo il valore iniziale è obbligatorio.

**Promessa scritta come formula.** Una promessa come `GUARANTEE g1: WHENEVER premuto THEN accesa AT ONCE`
non è scritta a parole ma come formula: `bcdd` la legge e ne controlla i nomi. Le formule sono descritte a partire
dal capitolo 21; fino al capitolo 20 le promesse si scrivono a parole.

---

## Capitolo 3 — I presupposti

La promessa `g1` del capitolo 2, «quando qualcuno preme il pulsante, la luce si accende», presuppone un
comportamento di chi sta sulle scale: che il pulsante venga premuto effettivamente, e non soltanto sfiorato.
Un contatto di pochi millisecondi può non essere distinguibile da un disturbo elettrico, e l'impianto non è
tenuto a riconoscerlo. Il capitolo descrive come scrivere ciò che una promessa presuppone.

### Il presupposto

Un **presupposto** è una condizione sul comportamento di chi sta dall'altro lato del confine da cui una
promessa dipende. Per la luce delle scale il presupposto è: chi preme il pulsante lo tiene premuto per almeno un decimo
di secondo.

Il presupposto condiziona la promessa. Se il pulsante viene tenuto premuto per un decimo di secondo o più, la
luce deve accendersi; se viene soltanto sfiorato, la luce può non accendersi, e in quel caso la promessa non è
violata, perché il presupposto su cui si fonda non è rispettato.

Un presupposto si scrive solo se una promessa ne dipende. Un comportamento dell'altro lato da cui nessuna
promessa dipende non è un presupposto e non si scrive in questa CSC.

### La riga ASSUME

Il file `UsoLuce.csc` con il presupposto:

```
-- La luce delle scale, vista da chi sta sulle scale.

CSC UsoLuce VERSION 0.1
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  EVENT IN  premuto
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

`ASSUME` significa «presuppone». La riga ha la stessa forma di una promessa: un nome breve (`a1`), il testo a
parole introdotto da `VERBAL` e, di norma nella riga seguente, il controllo. Il controllo di un presupposto indica chi verifica
che l'altro lato si comporti come previsto, e in che modo.

Promesse e presupposti sono insieme le **righe contrattuali** della CSC: entrano nel contratto quando vengono
approvati. I nomi brevi di promesse e presupposti appartengono allo stesso insieme, quindi un presupposto non
può chiamarsi come una promessa.

Il file non indica da quale promessa dipende un presupposto: il legame si ricava dal testo. Nell'esempio,
`a1` riguarda la pressione del pulsante, quindi condiziona `g1`.

### Il rapporto

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 15 (riconosciute 11, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, senza STATUS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 3
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 9: GUARANTEE g1 verbale
  riga 11: GUARANTEE g2 verbale
  riga 13: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 3
  riga 9: GUARANTEE g1
  riga 11: GUARANTEE g2
  riga 13: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

Il presupposto compare nelle sezioni 2 e 4 accanto alle promesse: è una riga contrattuale scritta a parole e,
come le promesse, è ancora da approvare.

### Quando un presupposto non è rispettato

Se un presupposto non è rispettato, la promessa che ne dipende non risulta violata: l'esito indica che l'altro
lato non si è comportato come previsto. Nella verifica di un impianto reale questo esito si chiama **presupposto non
rispettato** ed è distinto da una promessa violata (capitolo 24).

Per questo un presupposto va scritto con la stessa cura di una promessa. Un presupposto troppo largo, per
esempio «chi preme il pulsante lo usa correttamente», annulla di fatto la promessa: qualunque mancanza dell'impianto
potrebbe essere attribuita a un errore d'uso.

### Riepilogo

- Un **presupposto** (`ASSUME`) è una condizione su chi sta dall'altro lato del confine da cui una promessa
  dipende.
- Si scrive solo se una promessa ne dipende, con la stessa forma di una promessa: nome breve, testo e
  controllo.
- Se il presupposto non è rispettato, la promessa che ne dipende non è violata.
- Promesse e presupposti sono le righe contrattuali della CSC e condividono lo stesso insieme di nomi brevi.

### Casi particolari

**Presupposto senza controllo.** Se si toglie la riga `VERIFY` sotto `a1`, il rapporto riporta lo stesso
errore di una promessa senza controllo:

```
1. ERRORI: 1
  riga 13: [E13] VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa
```

**Nome breve già usato da una promessa.** Se il presupposto si chiama `g1`, come la prima promessa:

```
1. ERRORI: 1
  riga 13: [E01] nome già usato alla riga 9: g1
```

**Obbligo dell'altro lato senza promesse che ne dipendano.** «Chi sta sulle scale spegne la luce uscendo» non
è un presupposto di questa CSC: nessuna promessa della luce dipende da esso. `bcdd` non è in grado di
rilevarlo, perché non interpreta il testo fra virgolette; la valutazione spetta a chi scrive la CSC.

---

## Capitolo 4 — I due lati di un confine

Una CSC descrive un confine, che ha due lati (capitolo 1). Il capitolo indica da quale lato si scrive e
come la legge chi sta dall'altro lato. Sulla base di questa regola si aggiunge alla luce un elemento che va
dall'impianto verso chi sta sulle scale: un avviso poco prima dello spegnimento.

### Chi offre e chi usa

Dei due lati di un confine, uno mantiene le promesse e l'altro se ne serve:

- **chi offre** è il lato che mantiene le promesse della CSC; nell'esempio, l'impianto di illuminazione;
- **chi usa** è il lato che rispetta i presupposti e si affida alle promesse; nell'esempio, chi sta sulle
  scale.

Una CSC si scrive sempre dal lato di chi offre. Le righe del file vanno quindi lette dal punto di vista
dell'impianto:

| Riga | Dal lato di chi offre | Dal lato di chi usa |
|---|---|---|
| `EVENT IN` | ciò che gli arriva | ciò che invia |
| `EVENT OUT` | ciò che invia | ciò che gli arriva |
| `STATE` | ciò che mostra | ciò che osserva |
| `GUARANTEE` | ciò che promette | ciò su cui si può contare |
| `ASSUME` | ciò che presuppone | ciò che deve rispettare |

Chi usa legge le stesse righe in senso inverso. La CSC non si riscrive dal lato di chi usa: esiste una sola
descrizione per ogni confine, condivisa da entrambi i lati.

### L'evento in uscita

L'avviso è qualcosa che accade in un istante e va dall'impianto verso chi sta sulle scale. Dal lato di chi
offre è quindi un **evento in uscita**, scritto con `EVENT OUT`:

```
-- La luce delle scale, vista da chi sta sulle scale.

CSC UsoLuce VERSION 0.1
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  EVENT IN  premuto
  EVENT OUT avviso
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

La riga `EVENT OUT avviso` dichiara soltanto che l'evento esiste. Il momento in cui l'impianto lo invia è
stabilito dalla promessa `g3`: senza una promessa, nulla obbliga l'impianto a inviarlo. In che cosa consista concretamente
l'avviso, un breve lampeggio o un segnale acustico, non si scrive qui (capitolo 25).

La direzione di un evento indica chi ne ha l'obbligo. Un evento in uscita è un impegno di chi offre, regolato
dalle sue promesse; un evento in ingresso è qualcosa che chi offre riceve, e per il quale può soltanto
formulare presupposti.

### Il rapporto

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 18 (riconosciute 14, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, senza STATUS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 4
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 10: GUARANTEE g1 verbale
  riga 12: GUARANTEE g2 verbale
  riga 14: GUARANTEE g3 verbale
  riga 16: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 4
  riga 10: GUARANTEE g1
  riga 12: GUARANTEE g2
  riga 14: GUARANTEE g3
  riga 16: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

### Riepilogo

- Una CSC si scrive dal lato di **chi offre**, che mantiene le promesse; **chi usa** rispetta i presupposti e
  si affida alle promesse.
- Chi usa legge le stesse righe in senso inverso: un evento in uscita di chi offre è, per chi usa, un evento
  che arriva.
- L'**evento in uscita** (`EVENT OUT`) è un evento che chi offre invia all'altro lato; il momento dell'invio è
  stabilito dalle promesse.
- Ogni confine ha una sola CSC, condivisa dai due lati.

### Casi particolari

**Lo stesso nome in ingresso e in uscita.** Un evento ha un solo nome in tutta la CSC. Se l'avviso si chiama
anch'esso `premuto`:

```
1. ERRORI: 1
  riga 7: [E01] nome già usato alla riga 6: premuto
```

**Evento senza direzione.** La riga `EVENT avviso`, senza `IN` né `OUT`, non viene riconosciuta:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 7: EVENT avviso
…
esito: nessun errore; righe non riconosciute: 1 (--strict)
```

**La CSC scritta dal lato di chi usa.** Una seconda CSC con `EVENT OUT premuto` ed `EVENT IN avviso`, scritta
dal punto di vista di chi sta sulle scale, non aggiunge informazione: descrive lo stesso confine con le
direzioni invertite e richiede di mantenere allineate due descrizioni. Si scrive una sola CSC, dal lato di chi
offre.

---

## Capitolo 5 — Le richieste

Il custode del condominio richiede che, durante le pulizie, la luce resti accesa per un tempo stabilito. Questa
richiesta non è una semplice pressione del pulsante: l'impianto può accettarla o rifiutarla e, se la accetta,
può concluderla con esito riuscito oppure fallito. Il capitolo descrive come scrivere una richiesta.

### La richiesta

Una **richiesta** è ciò che chi usa può chiedere a chi offre. Si svolge in due fasi successive:

1. la **risposta**: la richiesta viene accettata oppure rifiutata;
2. l'**esito**: una richiesta accettata si conclude con esito riuscito oppure fallito.

Un evento in ingresso, invece, si limita ad accadere: non ha né risposta né esito.

Nel file la richiesta si scrive con `CAPABILITY`, che indica una capacità di chi offre:

```
  CAPABILITY Pulizie(durata: Duration)
```

`Pulizie` è il nome della richiesta. Fra parentesi sono indicati i suoi **parametri**, cioè i valori che
accompagnano la richiesta: qui un solo parametro, `durata`, del tipo `Duration`, cioè una durata di tempo. Ogni
parametro si scrive come `nome : tipo`; più parametri si separano con una virgola. I tipi sono descritti nel
capitolo 6.

### Il ciclo di vita

Le fasi di una richiesta hanno cinque nomi fissi, in inglese; insieme formano il **ciclo di vita** della
richiesta:

| Nome | Significato | Chi lo produce |
|---|---|---|
| `requested` | la richiesta è stata fatta | chi usa |
| `accepted` | la richiesta è stata accettata | chi offre |
| `rejected` | la richiesta è stata rifiutata | chi offre |
| `completed` | la richiesta accettata è riuscita | chi offre |
| `failed` | la richiesta accettata è fallita | chi offre |

Questi nomi si usano nelle storie (capitolo 9).

Il ciclo di vita fissa soltanto l'ordine delle fasi e non impone alcun obbligo. Le promesse stabiliscono
quando una richiesta è accettata o rifiutata, quanto dura e quando fallisce: ogni obbligo va scritto come
promessa.

### La CSC con la richiesta

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.

CSC UsoLuce VERSION 0.1
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

Le tre promesse nuove riguardano le due fasi della richiesta: `g4` stabilisce la risposta, `g5` e `g6`
l'esito. Senza `g4` la CSC consentirebbe all'impianto di rifiutare qualunque richiesta.

Il custode si trova dallo stesso lato di chi sta sulle scale e rientra quindi fra chi usa, come indica il
commento in testa al file.

### Il rapporto

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 25 (riconosciute 21, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, senza STATUS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 7
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 11: GUARANTEE g1 verbale
  riga 13: GUARANTEE g2 verbale
  riga 15: GUARANTEE g3 verbale
  riga 17: GUARANTEE g4 verbale
  riga 19: GUARANTEE g5 verbale
  riga 21: GUARANTEE g6 verbale
  riga 23: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 7
  riga 11: GUARANTEE g1
  riga 13: GUARANTEE g2
  riga 15: GUARANTEE g3
  riga 17: GUARANTEE g4
  riga 19: GUARANTEE g5
  riga 21: GUARANTEE g6
  riga 23: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

### Riepilogo

- Una **richiesta** (`CAPABILITY`) è ciò che chi usa può chiedere a chi offre; ha una **risposta**
  (accettata o rifiutata) e, se accettata, un **esito** (riuscita o fallita).
- I **parametri** sono i valori che accompagnano una richiesta o un evento, scritti come `nome : tipo`.
- I cinque nomi del **ciclo di vita** (`requested`, `accepted`, `rejected`, `completed`, `failed`) fissano
  l'ordine delle fasi, non gli obblighi: questi si scrivono come promesse.

### Casi particolari

**Parametro senza i due punti.** La riga `CAPABILITY Pulizie(durata Duration)` non viene riconosciuta:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 6: CAPABILITY Pulizie(durata Duration)
…
esito: nessun errore; righe non riconosciute: 1 (--strict)
```

**Due parametri con lo stesso nome.** In `CAPABILITY Pulizie(durata: Duration, durata: Duration)` il secondo
parametro è un nome già usato:

```
1. ERRORI: 1
  riga 6: [E01] nome già usato alla riga 6: durata
```

**Comportamento senza richiesta.** Lo spegnimento automatico della luce non è una richiesta: nessuno lo
richiede e non ha né risposta né esito. Si scrive come promessa (`g2`), non con `CAPABILITY`.

**Richiesta avviata da chi offre.** Una richiesta avviata da chi offre, cioè senza che alcuno la richieda, si
scrive aggiungendo `AUTONOMOUS` in fondo alla riga, per esempio `CAPABILITY Collaudo AUTONOMOUS`. Una
**richiesta autonoma** non ha `requested` né `rejected`: inizia già accettata e si conclude con esito riuscito
o fallito. `bcdd` riconosce questa riga.

---

## Capitolo 6 — I tipi dei valori

La luce ha ora tre modi di funzionamento: spenta, accesa e accesa per le pulizie. Lo stato `accesa`, che
può valere soltanto vero o falso, non basta più a descriverli. Il capitolo introduce i tipi, che stabiliscono
quali valori possono assumere gli stati e i parametri osservati al confine.

### Il tipo

Il **tipo** di uno stato o di un parametro è l'insieme dei valori che può assumere (capitolo 2). Il tipo si
scrive dopo i due punti: `accesa : Boolean`, `durata: Duration`. `bcdd` riconosce i tipi seguenti:

| Tipo | Valori | Esempio di valore |
|---|---|---|
| `Boolean` | vero o falso | `true`, `false` |
| `Integer [a .. b]` | numeri interi da `a` a `b` | `3` |
| `Real [a .. b]` | numeri reali da `a` a `b` | `0.5` |
| `String` | stringhe | `"secondo piano"` |
| `Duration` | durate, in secondi (`s`) o millisecondi (`ms`) | `60 s`, `250 ms` |
| `Sequence of T` | sequenze ordinate di valori del tipo `T` | — |
| `Optional T` | un valore del tipo `T`, oppure nessun valore | — |

L'**intervallo** fra parentesi quadre, `[a .. b]`, è facoltativo per `Integer` e `Real`: limita i valori
ammessi. Il separatore decimale nei numeri è il punto. Le unità di una durata sono soltanto `s` e `ms`, scritte
dopo il numero sulla stessa riga, con o senza spazio (`250 ms`, `50ms`).

### L'elenco di valori

Per i tre modi della luce nessuno dei tipi della tabella è adatto. Si dichiara allora un tipo nuovo, definito
da un **elenco di valori** a cui si dà un nome:

```
  TYPE       Modo := {spenta, accesa, in_pulizia}
```

`TYPE` introduce la dichiarazione di un tipo; `Modo` è il nome del tipo; fra le parentesi graffe sono elencati i
suoi valori, separati da virgole. Un valore di questo tipo è soltanto uno dei tre nomi dell'elenco.
I valori sono nomi, non stringhe: si scrivono senza virgolette.

Lo stato `accesa` è sostituito dallo stato `modo`, di tipo `Modo`:

```
  STATE      modo : Modo INITIAL spenta
```

Il valore iniziale è uno dei valori dell'elenco.

### La CSC con i tipi

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.

CSC UsoLuce VERSION 0.1
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"
  GUARANTEE g7: VERBAL "Durante le pulizie il modo è in_pulizia, e una pressione del pulsante non lo cambia"
                VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

La promessa nuova `g7` si riferisce al modo `in_pulizia`. Le promesse da `g1` a `g6` restano invariate:
descrivono a parole la luce accesa o spenta, senza usare lo stato `modo`, e il loro significato non cambia.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 29 (riconosciute 24, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, senza STATUS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 8
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 13: GUARANTEE g1 verbale
  riga 15: GUARANTEE g2 verbale
  riga 17: GUARANTEE g3 verbale
  riga 19: GUARANTEE g4 verbale
  riga 21: GUARANTEE g5 verbale
  riga 23: GUARANTEE g6 verbale
  riga 25: GUARANTEE g7 verbale
  riga 27: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 8
  riga 13: GUARANTEE g1
  riga 15: GUARANTEE g2
  riga 17: GUARANTEE g3
  riga 19: GUARANTEE g4
  riga 21: GUARANTEE g5
  riga 23: GUARANTEE g6
  riga 25: GUARANTEE g7
  riga 27: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

### Tipi descritti a parole e tipi non dichiarati

Un tipo può anche essere descritto a parole, quando i suoi valori non si possono elencare:

```
  TYPE       Testo := VERBAL "il testo mostrato dal display accanto al pulsante"
```

Un **tipo descritto a parole** ha un nome e una descrizione fra virgolette; `bcdd` ne registra il nome ma non
ne interpreta la descrizione.

Un tipo usato in uno stato o in un parametro senza essere dichiarato è un **tipo non dichiarato**. Non è un
errore: `bcdd` lo elenca nella sezione 6 del rapporto, con la riga in cui è usato. Se si aggiunge a `UsoLuce.csc`
lo stato `STATE messaggio : Testo INITIAL ""` senza la riga `TYPE Testo`, il rapporto riporta:

```
6. TIPI NON DICHIARATI: 1
  Testo: riga 12
…
esito: nessun errore
```

Con la riga `TYPE Testo := VERBAL "…"` nello stesso blocco, la sezione 6 non elenca più nulla.

### Riepilogo

- Il **tipo** stabilisce i valori ammessi per uno stato o un parametro; i tipi di base sono `Boolean`,
  `Integer`, `Real`, `String`, `Duration`, `Sequence of`, `Optional`.
- Un **elenco di valori** si dichiara con `TYPE Nome := {valore, valore, …}`; i valori sono nomi, senza
  virgolette.
- Un tipo si può descrivere a parole con `TYPE Nome := VERBAL "…"`.
- Un tipo non dichiarato non è un errore, ma compare nella sezione 6 del rapporto.

### Casi particolari

**Valore con il nome di un altro elemento.** I valori di un elenco appartengono allo stesso insieme di nomi di
stati, eventi, richieste e nomi brevi: un nome non si può usare due volte. Se, accanto al tipo `Modo`, si
lascia anche lo stato `STATE accesa : Boolean INITIAL false`, il nome `accesa` risulta usato due volte:

```
1. ERRORI: 1
  riga 12: [E01] nome già usato alla riga 6: accesa
```

**Valore fuori dall'elenco.** Con `INITIAL buia` il valore non appartiene a nessun elenco della CSC:

```
1. ERRORI: 1
  riga 11: [E03] nome non dichiarato come valore di TYPE: buia
```

**Valore di un tipo diverso.** `bcdd` controlla che il valore iniziale appartenga al tipo dello stato. Nella riga
`STATE modo : Modo INITIAL false` il valore `false` non è un valore di `Modo`:

```
1. ERRORI: 1
  riga 11: [E25] valore non del tipo Modo: false
```

Lo stesso controllo vale per i valori scritti nelle storie (capitolo 9).

**Limiti di un intervallo invertiti.** `bcdd` non controlla che il primo limite di un intervallo sia
minore o uguale al secondo.

**Unità non riconosciute.** Una durata scritta in minuti, `1 min`, non è riconosciuta: si scrive `60 s`.

**Altre forme dei tipi.** Il linguaggio prevede anche il tipo `Record {…}`, che raggruppa più campi, ciascuno
con un nome, e il tipo con nome `TYPE Nome := Tipo`, descritti nel capitolo 23. Il valore `ABSENT` indica che
un valore di tipo `Optional` è assente: `STATE ultimo : Optional Modo INITIAL ABSENT` è uno stato che
all'inizio non ha valore.

---

## Capitolo 7 — Da approvare e approvata

Le righe contrattuali scritte finora sono tutte da approvare: il rapporto le elenca nella sezione 4,
«DA APPROVARE, NON CONTRATTO». Il capitolo indica chi le approva, come l'approvazione si scrive nel file e con
quale comando di `bcdd` la si registra.

### Chi approva

Una riga contrattuale diventa **approvata** solo per decisione di chi ne ha l'autorità:
nell'esempio, l'amministratore del condominio. Né `bcdd` né un modello linguistico approvano mai una riga.

La decisione di approvazione è registrata altrove, per esempio nel registro delle decisioni del condominio, con
un identificativo. Nel file si scrive il **riferimento della decisione**: la sigla `D-` seguita da sole cifre,
per esempio `D-7`. A distanza di tempo, il riferimento permette di risalire a chi ha approvato e per quale
motivo.

### La riga STATUS

Lo stato di approvazione si registra nel file con `STATUS`, in due forme:

- `STATUS HYPOTHESIS`: da approvare;
- `STATUS RATIFIED BY D-7`: approvata con la decisione `D-7`.

`HYPOTHESIS` significa «ipotesi», cioè da approvare; `RATIFIED BY` significa «ratificata da», cioè approvata. Nelle
uscite di `bcdd`, di una riga approvata si dice che «è contratto».

`STATUS` si scrive in due posizioni. Nell'intestazione vale per l'intera CSC. L'**intestazione** è formata dalla
riga `CSC` e dalle righe che la seguono prima del **corpo** (le righe che descrivono il confine).
Sono `PURPOSE`, l'eventuale `STATUS` e l'eventuale `IMPORT PROFILE` (capitolo 27), in qualunque ordine. Negli esempi
del manuale `STATUS` segue subito la riga `CSC`. Dopo il nome breve di una riga contrattuale, invece, `STATUS`
vale soltanto per quella riga:

```
  GUARANTEE g1 STATUS RATIFIED BY D-7: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
```

Se una riga contrattuale ha un proprio `STATUS`, vale quello; altrimenti vale lo `STATUS` dell'intestazione.
In assenza di qualsiasi `STATUS`, la riga è da approvare: nulla diventa approvato senza una decisione scritta.

### Lo scheletro di un file nuovo

Il comando `bcdd new` crea lo scheletro di una CSC nuova nella cartella corrente:

```
$ bcdd new UsoLuce
creato UsoLuce.csc
```

Il file creato è il seguente:

```
-- CSC creata da bcdd new. Si scrive a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga è contratto: è da approvare finché l'operatore non la approva.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "da scrivere: in una frase, di che cosa è responsabile UsoLuce"

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

Lo scheletro contiene soltanto l'intestazione con `STATUS HYPOTHESIS`, lo scopo da scrivere e `END`; le altre
forme sono suggerite in commenti, da completare e attivare togliendo i due trattini. `bcdd new` non
sovrascrive mai un file esistente.

### La CSC da approvare

Con lo `STATUS` esplicito nell'intestazione, la CSC del capitolo 6 diventa:

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"
  GUARANTEE g7: VERBAL "Durante le pulizie il modo è in_pulizia, e una pressione del pulsante non lo cambia"
                VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

### L'approvazione con bcdd ratify

Il comando `bcdd ratify` registra nel file una decisione di approvazione già presa. Richiede come argomenti il
file, ciò che si approva e il riferimento della decisione. Di solito si approva l'intera CSC, con l'opzione
`--all`:

```
$ bcdd ratify UsoLuce.csc --all D-7
approvate con D-7 nella CSC UsoLuce: 1 riga
  riga 4: CSC UsoLuce
contratto: 8
```

Nel file cambia una sola riga, l'intestazione:

```
  STATUS RATIFIED BY D-7
```

Il comando riporta `1 riga` perché ha modificato soltanto lo `STATUS` dell'intestazione. Le otto righe
contrattuali non hanno uno `STATUS` proprio e assumono quello dell'intestazione: sono tutte approvate, come indica
`contratto: 8`. Il rapporto lo conferma:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 30 (riconosciute 25, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-7

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 8
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 14: GUARANTEE g1 verbale
  riga 16: GUARANTEE g2 verbale
  riga 18: GUARANTEE g3 verbale
  riga 20: GUARANTEE g4 verbale
  riga 22: GUARANTEE g5 verbale
  riga 24: GUARANTEE g6 verbale
  riga 26: GUARANTEE g7 verbale
  riga 28: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 0

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

La sezione 4 è vuota: la CSC della luce è approvata per intero, ed è ora il contratto fra l'amministratore e
chi realizza l'impianto.

Si può anche approvare una sola riga, indicandone il nome breve. Se la CSC è ancora da approvare:

```
$ bcdd ratify UsoLuce.csc g1 D-7
approvata la riga 14: GUARANTEE g1 con D-7
```

In questo caso il comando scrive lo `STATUS` nella riga di `g1`, come nell'esempio della sezione «La riga STATUS»;
le altre righe restano da approvare.

`bcdd ratify` esegue prima lo stesso controllo di `bcdd check --strict` e non modifica un file che non lo
supera. Se lo supera, modifica soltanto le righe `STATUS`: il resto del file rimane identico.

### Una riga approvata non si modifica

Una riga approvata non si modifica più. Per cambiare una CSC approvata se ne scrive una versione nuova, con il
procedimento del capitolo 10.

Neppure `STATUS RATIFIED BY` si scrive a mano: lo scrive `bcdd ratify`, in base a una decisione già presa.
`bcdd check` non distingue uno `STATUS RATIFIED BY` scritto a mano da uno scritto dal comando.

### Riepilogo

- Una riga contrattuale diventa **approvata** solo per decisione di chi ne ha l'autorità, mai del programma o
  di un modello linguistico.
- Nel file l'approvazione si registra con `STATUS RATIFIED BY D-numero`, dove `D-numero` è il **riferimento
  della decisione**; `STATUS HYPOTHESIS` indica una riga da approvare.
- Lo `STATUS` dell'**intestazione** vale per le righe che non ne hanno uno proprio; senza alcuno `STATUS`, una
  riga è da approvare.
- `bcdd new` crea lo scheletro di una CSC; `bcdd ratify` registra l'approvazione, di una riga o di tutte
  (`--all`), modificando soltanto le righe `STATUS`.

### Casi particolari

**File con errori.** `bcdd ratify` non registra l'approvazione di un file che non supera il controllo. Se il
file contiene `INITIAL buia` (capitolo 6):

```
$ bcdd ratify UsoLuce.csc --all D-7
bcdd ratify: il file non passa bcdd check --strict (errori: 1, righe non riconosciute: 0): non approvo
```

**Riga già approvata.** Una riga già approvata non si approva di nuovo, nemmeno con un'altra decisione:

```
$ bcdd ratify UsoLuce.csc g1 D-8
bcdd ratify: g1 è già contratto (riga 14): non cambio nulla
```

**Riferimento non valido.** Il riferimento deve avere la forma `D-` seguita da cifre:

```
$ bcdd ratify UsoLuce.csc --all D7
bcdd ratify: decisione non valida: D7 (serve D-numero)
```

Lo stesso messaggio compare per un nome di persona al posto del riferimento, per esempio `amministratore`.

**Approvazione senza riferimento.** Una riga `STATUS RATIFIED` priva di `BY` e del riferimento è un errore:

```
1. ERRORI: 1
  riga 4: [E04] STATUS RATIFIED senza decisione: serve BY D-numero
```

**File già esistente.** `bcdd new` non sovrascrive un file con lo stesso nome:

```
$ bcdd new UsoLuce
bcdd new: UsoLuce.csc esiste già: non lo sovrascrivo
```

---

## Capitolo 8 — Rendere precisa una promessa

La promessa `g2`, «la luce si spegne da sola dopo un po'», è approvata ma vaga: non indica quanto
deve durare l'accensione, quindi chi realizza l'impianto non lo conosce e il collaudo non ha un valore da
misurare. Il capitolo descrive come rendere precisa una promessa senza cancellarla e come sottoporre la CSC a un
modello linguistico, che pone domande sui punti ancora vaghi. Descrive poi come dare un nome ai valori e come segnare i numeri non ancora decisi.

### Il dettaglio

Un **dettaglio** è una riga contrattuale che precisa una promessa o un presupposto già scritti. Si scrive con
`DETAILS` seguito dal nome breve della riga che precisa:

```
  GUARANTEE g2a DETAILS g2: VERBAL "La luce si spegne 60 s dopo l'ultima pressione, con una tolleranza di 5 s"
                            VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
```

La riga si legge: la promessa `g2a`, dettaglio di `g2`. Un dettaglio rispetta tre regole:

1. **aggiunge, non sostituisce**: `g2` resta in vigore, e `g2a` si aggiunge a essa;
2. **non contraddice**: deve esistere un comportamento dell'impianto che rispetti entrambe le righe;
3. **è da approvare alla creazione**: un dettaglio senza `STATUS` proprio è da approvare anche se la promessa
   che precisa è approvata. Un dettaglio non segue lo `STATUS` dell'intestazione.

La terza regola consente di aggiungere dettagli sotto le promesse di una CSC approvata senza che risultino
approvati in assenza di una decisione. Allo stesso modo si possono precisare anche i presupposti.

Un dettaglio può a sua volta avere dettagli. Il **livello** di una riga indica quanti passaggi di `DETAILS` la
separano da una riga senza `DETAILS`: `g2` ha livello 0, `g2a` livello 1, un dettaglio di `g2a` livello 2.

### Le domande del modello linguistico

Il comando `bcdd refine` sottopone la CSC a un modello linguistico, che pone domande sui punti vaghi e, in base
alle risposte, propone righe nuove. Un'esecuzione di `bcdd refine` si svolge così:

1. il modello pone al massimo cinque domande, ciascuna con alcune risposte proposte. Si risponde con il numero
   di una risposta proposta o scrivendone una propria; premendo Invio senza scrivere nulla si salta la domanda;
2. in base alle risposte, il modello propone dettagli nuovi o la sostituzione di righe da approvare;
3. ogni proposta si accetta (`s`) o si scarta (`n`);
4. al termine il comando chiede conferma prima di scrivere nel file le proposte accettate; senza la conferma
   finale il file non cambia.

Per la CSC della luce l'esecuzione si presenta così (le righe iniziali, che riportano il controllo del file e la
chiamata al modello, sono omesse):

```
$ bcdd refine UsoLuce.csc
…
DOMANDA 1 di 2
  Quanto tempo dopo l'ultima pressione la luce si deve spegnere, e con quale tolleranza?
  1) 30 secondi, con 5 secondi di tolleranza
  2) 60 secondi, con 5 secondi di tolleranza
  3) 3 minuti, con 10 secondi di tolleranza
risposta (da 1 a 3, oppure scrivi tu; invio vuoto per saltare): 2
  scelta 2: 60 secondi, con 5 secondi di tolleranza

DOMANDA 2 di 2
  Una pressione mentre la luce è accesa che effetto ha sul tempo di accensione?
  1) fa ripartire il conteggio da capo
  2) non cambia nulla
risposta (da 1 a 2, oppure scrivi tu; invio vuoto per saltare): 1
  scelta 1: fa ripartire il conteggio da capo
…
PROPOSTA 1 di 2, dettaglia g2 (riga 16)
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne 60 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                              VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
accetti? s = sì, n = no, f = fine (scarta le restanti): s

PROPOSTA 2 di 2, dettaglia g2 (riga 16)
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il conteggio dei 60 s"
                                              VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
accetti? s = sì, n = no, f = fine (scarta le restanti): s

riepilogo: accettate 2, scartate da te 0, scartate dal controllo 0
scrivo 2 proposte (4 righe) in UsoLuce.csc e 2 risposte in UsoLuce.csc.dialogo? s = sì, n = no: s
scritto UsoLuce.csc: 2 proposte (4 righe)
scritto UsoLuce.csc.dialogo: 2 risposte
```

Le domande e le proposte dipendono dal modello linguistico e variano da un'esecuzione all'altra; quelle
riportate sono un esempio.

Le domande e le risposte date sono conservate nel file `UsoLuce.csc.dialogo`, accanto alla CSC; l'uscita
riporta il numero delle risposte scritte. All'esecuzione successiva `bcdd refine` passa al modello le risposte
già date, perché non riproponga le stesse domande.

Le proposte entrano nel file con `STATUS HYPOTHESIS` esplicito, subito sotto la promessa che precisano.
Le righe 14-21 del file diventano:

```
  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne 60 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                              VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il conteggio dei 60 s"
                                              VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
```

`bcdd refine` ha quattro limiti:

- tutto ciò che scrive nel file è da approvare: il comando non approva mai;
- non sostituisce mai una riga approvata: sotto una promessa approvata, come `g2`, può soltanto aggiungere
  dettagli;
- non propone dettagli oltre il livello 2;
- non crea altri file CSC: se individua un argomento che meriterebbe una CSC propria, lo segnala con un nome e
  un motivo.

### Il rapporto

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 34 (riconosciute 29, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-7

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 10
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 14: GUARANTEE g1 verbale
  riga 16: GUARANTEE g2 verbale
  riga 18: GUARANTEE g2a verbale
  riga 20: GUARANTEE g2b verbale
  riga 22: GUARANTEE g3 verbale
  riga 24: GUARANTEE g4 verbale
  riga 26: GUARANTEE g5 verbale
  riga 28: GUARANTEE g6 verbale
  riga 30: GUARANTEE g7 verbale
  riga 32: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 2
  riga 18: GUARANTEE g2a
  riga 20: GUARANTEE g2b

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

14. DA GIUDICARE: 2
  riga 18: GUARANTEE g2a DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 20: GUARANTEE g2b DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole

esito: nessun errore
```

La CSC resta approvata con la decisione `D-7`; nella sezione 4 compaiono soltanto i due dettagli nuovi.

La sezione 14, «da giudicare», elenca ciò che si può stabilire soltanto a giudizio. Un dettaglio a parole deve
aggiungere precisione alla riga che precisa, senza contraddirla; ma `bcdd` non interpreta il significato del
testo. Perciò, quando il dettaglio o la riga che precisa è scritta a parole, il rapporto segnala che la coerenza
fra le due resta da giudicare. Una voce della sezione 14 non è un errore e non cambia il codice d'uscita. La
sezione compare soltanto quando ha almeno una voce.

L'amministratore approva i due dettagli con una nuova decisione:

```
$ bcdd ratify UsoLuce.csc --all D-9
approvate con D-9 nella CSC UsoLuce: 2 righe
  riga 18: GUARANTEE g2a
  riga 20: GUARANTEE g2b
contratto: 10
```

Con `--all` il comando modifica soltanto le righe ancora da approvare: lo `STATUS` di `g2a` e di `g2b` diventa
`STATUS RATIFIED BY D-9`, mentre l'intestazione, già approvata, non cambia.

### Le costanti con nome

Un valore che ricorre in più righe si può dichiarare una volta sola, con un nome, mediante `DEFINE`:

```
  DEFINE     DURATA_LUCE := 60 s
  DEFINE     TOLLERANZA := 5 s
```

Una **costante con nome** si scrive con `DEFINE`, il nome, il segno `:=` e il valore: un numero, con o senza
unità, una stringa, `true`, `false` o uno dei valori di un elenco. Le unità ammesse sono le stesse delle durate,
`s` e `ms`. Il valore può essere anche un'espressione calcolata a partire da altri valori (capitolo 23).

`bcdd` non collega il nome al testo delle promesse: in `VERBAL "la luce si spegne dopo DURATA_LUCE"` il nome è
semplice testo, e `bcdd` non verifica che esista una riga `DEFINE` corrispondente.

La riga `DEFINE` è una **dichiarazione**, come le righe `TYPE`, `CAPABILITY`, `EVENT` e `STATE`: dichiara un
elemento della CSC. A differenza di una riga contrattuale, una dichiarazione non ha uno `STATUS` proprio e
assume sempre quello dell'intestazione. Se fosse aggiunta a una CSC approvata, risulterebbe approvata senza una
decisione: per questo non si aggiunge a una CSC approvata, ma si scrive in una CSC ancora da approvare o in una
versione nuova (capitolo 10). Nella CSC della luce, approvata con `D-7`, i numeri restano scritti nel testo dei
dettagli.

### I numeri non ancora decisi

Un numero che non è ancora stato deciso si dichiara con il valore `UNDECIDED`, «non deciso»:

```
  DEFINE     ANTICIPO_AVVISO := UNDECIDED
```

Un **numero non deciso** indica che manca una decisione. `bcdd` lo elenca nella sezione 3 del rapporto finché
resta tale. In una copia di lavoro ancora da approvare della CSC della luce, con le tre righe `DEFINE` di questo
capitolo alle righe 7-9:

```
1. ERRORI: 0
…
3. UNDECIDED: 1
  riga 9: ANTICIPO_AVVISO
…
esito: nessun errore
```

Un numero non deciso non è un errore. Quando la decisione è presa, si scrive a mano il valore al posto di
`UNDECIDED`; nessun comando lo fa.

### Riepilogo

- Un **dettaglio** (`DETAILS`) precisa una promessa o un presupposto: aggiunge senza sostituire e senza
  contraddire, ed è da approvare alla creazione, anche sotto una riga approvata.
- `bcdd refine` sottopone la CSC a un modello linguistico, che pone domande sui punti vaghi e propone righe; nel file
  entra soltanto ciò che si accetta e si conferma, e resta sempre da approvare.
- Una **costante con nome** si dichiara con `DEFINE`; un **numero non deciso** con `UNDECIDED`, ed è elencato
  nella sezione 3 del rapporto.
- `DEFINE` è una **dichiarazione**: assume lo `STATUS` dell'intestazione e non si aggiunge a una CSC approvata.

### Casi particolari

**Dettaglio di una promessa inesistente.** Se `g2b` ha `DETAILS g9` e `g9` non esiste:

```
1. ERRORI: 1
  riga 20: [E02] DETAILS nomina un id che non è una GUARANTEE né una ASSUME di questa CSC: g9
```

**Dettagli circolari.** Se `g2a` è dettaglio di `g2b` e `g2b` è dettaglio di `g2a`, i due dettagli formano un
ciclo e nessuno dei due precisa una promessa; `bcdd` segnala l'errore E05:

```
1. ERRORI: 1
  riga 18: [E05] DETAILS in modo circolare: g2a -> g2b -> g2a
```

**Unità in minuti.** La riga `DEFINE DURATA_LUCE := 1 min` non è riconosciuta:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 7: DEFINE     DURATA_LUCE := 1 min
```

**Nessuna domanda.** Quando il modello non rileva punti vaghi, `bcdd refine` lo indica in una riga e il file
non cambia:

```
la CSC UsoLuce è precisa abbastanza: nessuna domanda e nessuna proposta, UsoLuce.csc non cambia
```

**Dettagli oltre il livello 2.** `bcdd check` accetta dettagli a qualunque livello; il limite del livello 2
vale solo per le proposte di `bcdd refine`.

---

## Capitolo 9 — Esempi che fissano l'intenzione

Le promesse descrivono il comportamento in generale. Un caso concreto, descritto istante per istante, permette
di controllare che chi scrive e chi legge le intendano allo stesso modo: due pressioni a 100 secondi di
distanza sono ammesse, uno spegnimento dopo 30 secondi non lo è. Il capitolo introduce le storie.

### La storia

Una **storia** è una breve sequenza di istanti che il contratto deve ammettere oppure respingere. Si scrive con
`SCENARIO`:

```
  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @55 s    avviso
    @60 s    modo = spenta
    @100 s   premuto    modo = accesa
```

`SCENARIO s1` apre la storia, con il suo nome breve. `EXPECT ADMITTED` significa che la storia deve essere
**ammessa**, cioè che rispetta il contratto; `EXPECT REJECTED` significa che deve essere **respinta**, cioè che
lo viola.

Ogni riga che segue comincia con `@` e descrive un **istante** della storia: `@0 s` è l'inizio, `@55 s` è
55 secondi dopo. Gli istanti si scrivono in ordine cronologico, tutti con un'unità (`s` o `ms`) oppure tutti
senza. In un istante si scrivono ciò che accade e ciò che si osserva:

| Elemento | Significato | Esempio |
|---|---|---|
| nome di un evento | l'evento accade in quell'istante | `premuto` |
| stato `=` valore | in quell'istante lo stato ha quel valore | `modo = accesa` |
| fase del ciclo di vita, con la richiesta fra parentesi | la richiesta raggiunge quella fase in quell'istante | `requested(Pulizie)` |
| `VERBAL "…"` | un'**asserzione a parole** su quell'istante | `VERBAL "il custode chiede tre ore di pulizie"` |

La sequenza degli istanti scritti in una storia è la sua **traccia**. Nei messaggi di `bcdd` l'istante di una
storia è chiamato «passo» (capitolo 21).

La storia `s1` si legge così: all'istante 0 qualcuno preme il pulsante e la luce si accende; all'istante 55 la
luce emette l'avviso; all'istante 60 la luce è spenta; all'istante 100 una nuova pressione la riaccende. Il
contratto la ammette.

### Lo stato di partenza

Una storia comincia con gli stati al loro valore iniziale. Per partire da una situazione diversa si indica lo
**stato di partenza** con `GIVEN`, prima di `EXPECT`:

```
  SCENARIO s3 GIVEN modo = in_pulizia EXPECT ADMITTED
    @0 s     premuto    modo = in_pulizia
```

La storia parte con le pulizie in corso: una pressione del pulsante non cambia il modo, come stabilisce `g7`.
Gli stati non nominati in `GIVEN` partono dal loro valore iniziale.

### Dove si scrivono le storie

Una storia è una dichiarazione (capitolo 8): non ha uno `STATUS` proprio e assume quello
dell'intestazione della CSC.
Come una riga `DEFINE`, una storia non si aggiunge a una CSC approvata. Le storie della luce si scrivono quindi in una
versione nuova, la 0.2, da approvare: il numero di versione e lo `STATUS` dell'intestazione cambiano, e un
commento in testa indica che cosa cambia. Il procedimento completo per scrivere una versione nuova è descritto
nel capitolo 10.

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.
-- VERSION 0.2: aggiunti gli scenari s1-s4. Da approvare.

CSC UsoLuce VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "La luce si spegne 60 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                              VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE g2b DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il conteggio dei 60 s"
                                              VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"
  GUARANTEE g7: VERBAL "Durante le pulizie il modo è in_pulizia, e una pressione del pulsante non lo cambia"
                VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"

  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @55 s    avviso
    @60 s    modo = spenta
    @100 s   premuto    modo = accesa
  SCENARIO s2 EXPECT REJECTED
    @0 s     premuto    modo = accesa
    @30 s    modo = spenta
  SCENARIO s3 GIVEN modo = in_pulizia EXPECT ADMITTED
    @0 s     premuto    modo = in_pulizia
  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "il custode chiede tre ore di pulizie"
    @0 s     rejected(Pulizie)
END
```

La storia `s2` deve essere respinta: la luce si spegne 30 secondi dopo la pressione, in contrasto con il dettaglio `g2a`.
La storia `s4` usa il ciclo di vita del capitolo 5: il custode chiede tre ore di pulizie e la richiesta viene
rifiutata, come stabilisce `g4`. La durata richiesta, che è un parametro della richiesta, è indicata con
un'asserzione a parole.

### Che cosa controlla bcdd

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 49 (riconosciute 42, commenti 2, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.2, STATUS HYPOTHESIS

1. ERRORI: 0
…
esito: nessun errore
```

Sulle storie `bcdd` controlla la forma. Controlla che i nomi usati siano eventi, stati e richieste dichiarati
nella CSC; che i valori dello stato di partenza appartengano a un elenco di valori della CSC; che il tempo degli
istanti non diminuisca. Non controlla, invece, che una storia sia ammessa o respinta dalle promesse: con
promesse scritte a parole questa valutazione spetta a chi scrive la CSC. La verifica degli esiti è trattata nel
capitolo 24. La sezione 4 del rapporto di questa versione è descritta nel capitolo 10.

### Il limite di una storia

Una storia non vieta nulla di ciò che non descrive. In `s1` non compare alcun avviso fra l'istante 0 e
l'istante 55: la storia non esclude che in quell'intervallo ne vengano emessi. Allo stesso modo, una storia
ammessa non stabilisce che l'impianto debba comportarsi sempre così: mostra un comportamento possibile.

Le storie esprimono l'intenzione di chi scrive e permettono di discuterla su casi concreti; gli obblighi restano
nelle promesse.

### Riepilogo

- Una **storia** (`SCENARIO`) è una sequenza di istanti che il contratto deve ammettere (`EXPECT ADMITTED`) o
  respingere (`EXPECT REJECTED`).
- Ogni **istante** (`@`) indica un tempo e ciò che accade o si osserva: eventi, valori degli stati, fasi di
  una richiesta, asserzioni a parole.
- Lo **stato di partenza** (`GIVEN`) indica i valori iniziali della storia, quando non sono quelli dichiarati.
- Una storia è una dichiarazione: assume lo `STATUS` dell'intestazione e non si aggiunge a una CSC approvata.
- Una storia non vieta ciò che non descrive; `bcdd` ne controlla la forma, non l'esito.

### Casi particolari

**Evento non dichiarato.** Se all'istante 55 si scrive `allarme` invece di `avviso`:

```
1. ERRORI: 1
  riga 38: [E03] nome non dichiarato come EVENT: allarme
```

Lo stesso errore, con `CAPABILITY` o `STATE` al posto di `EVENT`, compare anche per una richiesta con nome errato
in `requested(Pulizia)` e per uno stato non dichiarato in `GIVEN accesa = true`.

**Tempo che diminuisce.** Se la seconda pressione è scritta `@50 s`, dopo `@60 s`:

```
1. ERRORI: 1
  riga 40: [E12] il tempo del passo diminuisce: @50 s dopo @60 s
```

Due istanti con lo stesso tempo sono invece ammessi, come in `s4`.

**Istanti con e senza unità.** Se l'istante `@60 s` è scritto `@60`, senza unità:

```
1. ERRORI: 1
  riga 39: [E12] passi con e senza unità di tempo nello stesso SCENARIO
```

**Storia dichiarata respinta ma ammessa dalle promesse.** Se in `s2` lo spegnimento avviene a `@60 s`, la
storia rispetta il contratto, benché sia dichiarata con `EXPECT REJECTED`. `bcdd check` non lo rileva, perché
non valuta le promesse scritte a parole.

---

## Capitolo 10 — Cambiare una CSC già approvata

L'amministratore decide che 60 secondi sono troppo pochi per salire all'ultimo piano: la durata
dell'accensione passa a 90 secondi. La CSC della luce è approvata e un contratto approvato non si modifica. Il capitolo
descrive come scriverne una versione nuova e che cosa, nella versione nuova, va approvato di nuovo e che cosa
resta approvato.

### La versione nuova

Per cambiare una CSC approvata se ne scrive una **versione nuova**, nello stesso file, al posto della
precedente:

1. il numero dopo `VERSION` cambia, per esempio da `0.1` a `0.2`;
2. lo `STATUS` dell'intestazione torna `HYPOTHESIS`;
3. un commento in testa al file indica che cosa cambia;
4. ogni riga contrattuale di cui cambia il testo e che ha uno `STATUS RATIFIED BY` proprio passa a
   `STATUS HYPOTHESIS`;
5. le righe di cui non cambia il testo restano come sono.

Finché la versione nuova non è approvata, il contratto in vigore resta la versione precedente approvata, che
si trova nella cronologia delle versioni o nell'archivio dei documenti.

### Che cosa resta approvato

Nella versione nuova lo stato di ogni riga contrattuale segue le regole del capitolo 7:

- una riga con uno `STATUS RATIFIED BY` proprio, di cui non cambia il testo, **resta approvata**, con la
  decisione originaria;
- una riga senza `STATUS` proprio assume quello dell'intestazione, tornato `HYPOTHESIS`: **torna da approvare**,
  anche se il suo testo non cambia;
- una riga di cui cambia il testo passa a `STATUS HYPOTHESIS` (punto 4) ed è **da approvare**;
- le dichiarazioni (tipi, eventi, stati, costanti con nome, storie) assumono lo `STATUS` dell'intestazione e
  sono da approvare.

La versione 0.2 della luce, aperta nel capitolo 9 per aggiungere le storie, ne è già un esempio. Il suo rapporto
riporta, nella sezione 4:

```
4. DA APPROVARE, NON CONTRATTO: 8
  riga 15: GUARANTEE g1
  riga 17: GUARANTEE g2
  riga 23: GUARANTEE g3
  riga 25: GUARANTEE g4
  riga 27: GUARANTEE g5
  riga 29: GUARANTEE g6
  riga 31: GUARANTEE g7
  riga 33: ASSUME a1
```

Le otto righe approvate nel capitolo 7 con la decisione `D-7` non hanno uno `STATUS` proprio: assumevano
quello dell'intestazione, e con l'intestazione sono tornate da approvare. I dettagli `g2a` e `g2b` non compaiono, perché
hanno uno `STATUS RATIFIED BY D-9` proprio e il loro testo non è cambiato: restano approvati.

### La modifica da 60 a 90 secondi

Nella stessa versione 0.2 si scrive la nuova durata dell'accensione. Cambiano il testo dei due dettagli e il
commento in testa:

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.
-- VERSION 0.2: aggiunti gli scenari s1-s4; tempo di accensione da 60 s a 90 s. Da approvare.
```

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                                VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il conteggio dei 90 s"
                                                VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
```

Le due righe avevano uno `STATUS RATIFIED BY D-9` proprio; poiché il loro testo cambia, passano a
`STATUS HYPOTHESIS`.

La modifica riguarda anche la storia `s1`, che con 90 secondi non sarebbe più ammessa: la luce non può spegnersi
a 60 secondi. I suoi istanti si aggiornano:

```
  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @85 s    avviso
    @90 s    modo = spenta
    @100 s   premuto    modo = accesa
```

La storia `s2`, con lo spegnimento a 30 secondi, resta respinta anche con il tempo nuovo.

Il rapporto della versione 0.2 riporta ora tutte e dieci le righe contrattuali da approvare:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
…
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.2, STATUS HYPOTHESIS

1. ERRORI: 0
…
4. DA APPROVARE, NON CONTRATTO: 10
  riga 15: GUARANTEE g1
  riga 17: GUARANTEE g2
  riga 19: GUARANTEE g2a
  riga 21: GUARANTEE g2b
  riga 23: GUARANTEE g3
  riga 25: GUARANTEE g4
  riga 27: GUARANTEE g5
  riga 29: GUARANTEE g6
  riga 31: GUARANTEE g7
  riga 33: ASSUME a1
…
esito: nessun errore
```

### L'approvazione della versione nuova

L'amministratore approva la versione 0.2 con la decisione `D-12`:

```
$ bcdd ratify UsoLuce.csc --all D-12
approvate con D-12 nella CSC UsoLuce: 3 righe
  riga 5: CSC UsoLuce
  riga 19: GUARANTEE g2a
  riga 21: GUARANTEE g2b
contratto: 10
```

Il comando modifica tre righe: l'intestazione e i due dettagli che avevano `STATUS HYPOTHESIS` proprio. Le
altre otto righe contrattuali assumono lo `STATUS` dell'intestazione e risultano approvate con essa. Nel rapporto la sezione 4
torna vuota:

```
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.2, STATUS RATIFIED BY D-12
…
4. DA APPROVARE, NON CONTRATTO: 0
```

La versione 0.2 è ora il contratto in vigore e sostituisce la 0.1.

### Che cosa si può modificare senza versione nuova

I commenti non fanno parte del contratto: si possono correggere in qualunque momento, senza versione nuova,
purché nessun'altra riga cambi.

`bcdd` legge un file alla volta e non ha accesso alla versione precedente: non può quindi indicare che cosa è
cambiato fra due versioni. Il confronto si esegue con un sistema di controllo di versione, per esempio
`git diff`, prima di approvare.

### Riepilogo

- Una CSC approvata non si modifica: se ne scrive una **versione nuova**, con un numero diverso e
  l'intestazione `STATUS HYPOTHESIS`, al posto della precedente.
- Resta approvata una riga con uno `STATUS RATIFIED BY` proprio, di cui non cambia il testo.
- Torna da approvare una riga che assume lo `STATUS` dell'intestazione; una riga di cui cambia il testo passa a
  `STATUS HYPOTHESIS`.
- Finché la versione nuova non è approvata, vale la precedente; `bcdd ratify --all` registra l'approvazione della versione nuova.
- I commenti si correggono senza versione nuova.

### Casi particolari

**Testo cambiato senza STATUS HYPOTHESIS.** Se il testo di `g2a` passa a 90 secondi ma la riga conserva
`STATUS RATIFIED BY D-9`, la riga resta approvata con un testo che nessuno ha approvato. `bcdd check` non lo
rileva: nella sezione 4 del rapporto `g2a` non compare.

```
4. DA APPROVARE, NON CONTRATTO: 8
  riga 15: GUARANTEE g1
  riga 17: GUARANTEE g2
  riga 23: GUARANTEE g3
  riga 25: GUARANTEE g4
  riga 27: GUARANTEE g5
  riga 29: GUARANTEE g6
  riga 31: GUARANTEE g7
  riga 33: ASSUME a1
```

Questo difetto si rileva solo confrontando la versione nuova con la precedente, prima di approvarla.

**Due versioni nello stesso file.** La versione nuova sostituisce la precedente nel file. Se le due versioni
restano una dopo l'altra, la seconda ripete un nome già dichiarato:

```
1. ERRORI: 1
  riga 34: [E01] nome già usato alla riga 3: UsoLuce
```

**Numero non deciso in una CSC approvata.** Per sostituire `UNDECIDED` con un valore in una CSC approvata si
scrive una versione nuova, come per qualunque altro cambiamento; in una CSC da approvare si modifica la riga
direttamente.

---

## Capitolo 11 — Confine unico o confini separati

Nella prima parte la luce delle scale ha un solo confine, descritto dalla CSC `UsoLuce`, nel quale compaiono
insieme la pressione del pulsante e la luce osservata. Il capitolo divide quel confine in due, indica quando la
divisione è opportuna e mette in evidenza il problema che ne deriva.

### Quando un confine si divide

Un confine è l'interfaccia nella quale si osserva ciò che passa fra un sistema e chi lo usa (capitolo 1). La
pressione del pulsante si osserva sul muro dell'androne, accanto al pulsante; la luce si osserva sulle scale,
guardando la lampada. Per controllare che la luce si spenga da sola non serve osservare il pulsante, e per
controllare che una pressione sia riconosciuta non serve osservare la luce.

Il criterio è il seguente: un confine si divide in due quando ciò che vi passa si osserva in due punti
distinti. Occorre inoltre che le promesse di ciascuno dei due confini nuovi si possano controllare senza
osservare l'altro. Gli elementi che si osservano
nello stesso punto restano nello stesso confine: la richiesta di pulizie, l'avviso e il modo della luce
riguardano tutti la luce, e restano insieme.

La divisione è utile soprattutto quando i due confini sono offerti da sistemi diversi, che vengono realizzati
separatamente: chi costruisce il pulsante riceve soltanto la descrizione del confine del pulsante. Questo
caso è trattato nel capitolo 13.

### Le due CSC

Il confine della pressione del pulsante è descritto dalla CSC `Pressione`:

```
-- Il pulsante delle scale, visto da chi lo preme.

CSC Pressione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante per chiedere luce"

  EVENT IN   premuto

  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

Il confine della luce osservata è descritto dalla CSC `Luce`:

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale vede la luce accesa per il tempo necessario a salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"

  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "il custode chiede tre ore di pulizie"
    @0 s     rejected(Pulizie)
END
```

Le righe di `UsoLuce` 0.2 si distribuiscono così:

| Righe di `UsoLuce` 0.2 | Dove vanno |
|---|---|
| `EVENT IN premuto`, il presupposto `a1` | `Pressione` |
| `TYPE Modo`, `CAPABILITY Pulizie`, `EVENT OUT avviso`, `STATE modo` | `Luce` |
| le promesse `g2`, `g3`, `g4`, `g5`, `g6` e la storia `s4` | `Luce` |
| le promesse `g1`, `g2a`, `g2b`, `g7` e le storie `s1`, `s2`, `s3` | in nessuna delle due |

Le due CSC sono nuove: hanno la versione 0.1 e l'intestazione `STATUS HYPOTHESIS`. Le righe copiate da
`UsoLuce` non conservano la propria approvazione, perché la divisione cambia il contratto e richiede una
decisione nuova. Finché le due CSC non sono approvate, resta in vigore `UsoLuce` 0.2, approvata con la
decisione `D-12`.

### Il rapporto

```
$ bcdd check --strict Pressione.csc
bcdd check --strict Pressione.csc
righe: 11 (riconosciute 7, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC Pressione VERSION 0.1, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 1
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 9: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 1
  riga 9: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

```
$ bcdd check --strict Luce.csc
bcdd check --strict Luce.csc
righe: 27 (riconosciute 21, commenti 1, vuote 5, non riconosciute 0)
blocchi: 1
  riga 3: CSC Luce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORI: 0
…
4. DA APPROVARE, NON CONTRATTO: 5
  riga 13: GUARANTEE g2
  riga 15: GUARANTEE g3
  riga 17: GUARANTEE g4
  riga 19: GUARANTEE g5
  riga 21: GUARANTEE g6
…
esito: nessun errore
```

Entrambe le CSC superano il controllo. La CSC `Pressione`, tuttavia, contiene un presupposto che non
condiziona alcuna promessa: la promessa che `a1` condizionava era `g1`, che non si trova più in nessuna delle due
CSC.

### Il problema: le promesse che legano i due confini

La promessa `g1`, «quando qualcuno preme il pulsante, la luce si accende», nomina un elemento di ciascun
confine: la pressione, che sta in `Pressione`, e la luce, che sta in `Luce`. Lo stesso vale per `g2a` e
`g2b`, che riguardano il tempo trascorso dall'ultima pressione, per `g7`, che descrive l'effetto di una pressione durante
le pulizie, e per le storie `s1`, `s2` e `s3`, nelle quali compaiono sia `premuto` sia `modo`.

Nessuna di queste righe può essere scritta in una delle due CSC. Una CSC descrive un solo confine e nomina soltanto
i propri elementi: in `Luce` l'evento `premuto` non esiste, e in `Pressione` non esiste lo stato `modo`.
Scrivere `g1` in `Luce` violerebbe la regola del capitolo 1, secondo cui una promessa riguarda solo ciò che si
osserva al confine.

Le promesse che legano due confini si scrivono in ciò che sta dietro entrambi, l'entità, descritta nel
capitolo 12.

### Riepilogo

- Un confine si divide in due quando ciò che vi passa si osserva in due punti distinti e le promesse di
  ciascuno dei due si controllano senza osservare l'altro.
- Ogni confine ha la propria CSC; una CSC nomina soltanto i propri elementi.
- Le CSC nate da una divisione sono nuove e da approvare; fino alla loro approvazione resta in vigore la CSC
  precedente.
- Una promessa che nomina elementi di due confini non può essere scritta in nessuna delle due CSC.

### Casi particolari

**Storia con elementi di due confini.** Se in coda alla CSC `Luce` si aggiunge la storia `s1` di `UsoLuce`,
con l'istante `@0 s premuto modo = accesa` alla riga 28, il rapporto riporta:

```
1. ERRORI: 1
  riga 28: [E03] nome non dichiarato come EVENT: premuto
```

**Nome preceduto dal nome della CSC.** Se nella stessa riga si scrive `Pressione.premuto`, il rapporto
riporta un errore diverso:

```
1. ERRORI: 1
  riga 28: [E20] Pressione.premuto: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità
```

Nei messaggi di `bcdd` una CSC citata da un'entità è chiamata «connettore»; il manuale usa «confine»
(capitolo 12).
Il messaggio rimanda alla forma descritta nel capitolo 18.

**Promessa a parole che nomina l'altro confine.** Se la promessa `g1` viene copiata in `Luce` senza modifiche,
`bcdd` non segnala nulla: non interpreta il testo fra virgolette e non riconosce che la promessa si riferisce
alla pressione. La valutazione spetta a chi scrive la CSC.

---

## Capitolo 12 — Che cosa c'è dietro i confini: l'entità

Le promesse che legano il pulsante e la luce non possono essere scritte in nessuna delle due CSC del
capitolo 11. Il
capitolo introduce ciò che sta dietro i due confini e che mantiene quelle promesse: l'entità.

### L'entità

Un'**entità** è il sistema che sta dietro uno o più confini. Si descrive indicando tre cose:

- i confini su cui mantiene le promesse, cioè quelli in cui ha il ruolo di chi offre;
- i confini su cui si affida alle promesse di altri, cioè quelli in cui ha il ruolo di chi usa;
- le promesse che legano due o più dei suoi confini, chiamate **promesse d'entità**.

La descrizione di un'entità non indica mai dove l'entità si trova: su quale muro, in quale apparecchio, in
quale programma. La sua
collocazione è una scelta di chi la realizza (capitolo 1); un'entità può anche estendersi su più apparecchi.

La luce delle scale è un'entità, `LuceScale`, che sta dietro i confini `Pressione` e `Luce`. La promessa
«quando qualcuno preme il pulsante, la luce si accende» è una sua promessa d'entità.

### Un confine usato: l'alimentazione

L'impianto della luce è alimentato dalla rete elettrica del condominio. La rete è un altro
sistema, e fra la rete e l'impianto c'è un confine, descritto dalla CSC `Alimentazione`:

```
-- La rete elettrica del condominio, vista dall'impianto della luce.

CSC Alimentazione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La rete elettrica del condominio fornisce la tensione all'impianto della luce delle scale"

  STATE      presente : Boolean INITIAL true

  GUARANTEE r1: VERBAL "La tensione è presente, salvo le interruzioni della rete"
                VERIFY BY INSPECTION "il registro delle interruzioni del condominio"
  ASSUME    r-a1: VERBAL "L'impianto della luce delle scale assorbe al più 100 W"
                  VERIFY BY INSPECTION "i dati di targa delle lampade installate"
END
```

La CSC è scritta dal lato di chi offre, la rete (capitolo 4). Su questo confine la luce delle scale è chi
usa: si affida alla promessa `r1` e deve rispettare il presupposto `r-a1`.

### Il file dell'entità

```
-- La luce delle scale: ciò che sta dietro il pulsante e la luce.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE ls3: VERBAL "Durante le pulizie una pressione del pulsante non cambia il modo"
                 VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
END
```

`ENTITY LuceScale VERSION 0.1` apre la descrizione dell'entità, con il suo nome e la sua versione. `STATUS` e
`PURPOSE` hanno lo stesso significato che hanno nella CSC.

`OFFERS Pressione` indica che l'entità è chi offre sul confine `Pressione`: ne mantiene le promesse e si
affida ai suoi presupposti. `USES Alimentazione` indica che l'entità è chi usa sul confine `Alimentazione`:
ne rispetta i presupposti e si affida alle sue promesse. Dopo `OFFERS` e `USES` si scrive il nome di una CSC.

Le righe `GUARANTEE` sono le promesse d'entità. Hanno la stessa forma delle promesse di una CSC, con il nome
breve e il controllo, ma nominano elementi di più confini: `ls1` lega la pressione e la luce. Il presupposto
`a1` della CSC `Pressione` condiziona ora una promessa: `ls1`.

Un'entità non ha elementi propri: non ha richieste, eventi, stati, tipi, costanti con nome né
presupposti. Ciò che si osserva è descritto nelle CSC dei suoi confini. Ciò che l'entità richiede agli altri
sistemi è nei presupposti delle CSC che offre, come `a1`. Ciò che gli altri sistemi richiedono all'entità è
nei presupposti delle CSC che usa, come `r-a1`.

Una CSC e un'entità non possono avere lo stesso nome: quando i due nomi stanno nello stesso file, `bcdd`
segnala E01.

### Il rapporto

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 17 (riconosciute 13, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 3
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 11: GUARANTEE ls1 verbale
  riga 13: GUARANTEE ls2 verbale
  riga 15: GUARANTEE ls3 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 3
  riga 11: GUARANTEE ls1
  riga 13: GUARANTEE ls2
  riga 15: GUARANTEE ls3

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 0

esito: nessun errore
```

Sotto la riga dell'entità, rientrate, compaiono le **citazioni**: una riga per ogni CSC citata da `OFFERS` o
da `USES`. Per ciascuna `bcdd` cerca il file della CSC, lo controlla e ne riporta la versione, lo `STATUS` e
l'esito. La prima citazione riporta che la CSC nominata alla riga 7 si trova nel file `Pressione.csc`, alla
riga 3; la CSC è nella versione 0.1, è da approvare e non ha errori. Il controllo di una CSC citata
riguarda la sua forma, non il fatto che le sue promesse siano compatibili con quelle dell'entità: questa
valutazione spetta a chi scrive.

La sezione 8 compare quando il file contiene un'entità; è descritta nel capitolo 13.

Nei messaggi di `bcdd` una CSC citata da un'entità è chiamata «connettore»; il manuale usa «confine».

Nell'intestazione di un'entità è ammesso soltanto `STATUS HYPOTHESIS`: l'entità nel suo insieme non si approva. Si
approvano una per una le sue promesse d'entità; le CSC che cita si approvano nei propri file.

### Riepilogo

- Un'**entità** (`ENTITY`) è il sistema che sta dietro uno o più confini; la sua descrizione non indica mai
  dove si trova.
- `OFFERS` indica un confine di cui l'entità è chi offre, `USES` un confine di cui l'entità è chi usa.
- Le **promesse d'entità** legano due o più confini dell'entità e hanno la forma delle promesse di una CSC.
- Un'entità non ha elementi propri: ciò che si osserva è descritto nelle CSC dei suoi confini.
- `bcdd` cerca e controlla le CSC citate e ne riporta versione, `STATUS` ed esito.

### Casi particolari

**Elemento proprio in un'entità.** Se nell'entità si scrive `STATE accesa : Boolean INITIAL false`:

```
1. ERRORI: 1
  riga 10: [E18] STATE non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori
…
5. RIGHE NON RICONOSCIUTE: 1
  riga 10: STATE  accesa : Boolean INITIAL false
```

Lo stesso errore compare per `ASSUME`, `CAPABILITY`, `EVENT`, `DEFINE` e `TYPE`.

**`STATUS` approvato nell'intestazione.** La riga `STATUS RATIFIED BY D-20` nell'intestazione di un'entità non
viene riconosciuta, e il blocco risulta senza `STATUS`:

```
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, senza STATUS
…
5. RIGHE NON RICONOSCIUTE: 1
  riga 4: STATUS RATIFIED BY D-20
```

**Approvazione delle promesse d'entità.** Poiché l'intestazione dell'entità non può essere approvata,
`bcdd ratify` con `--all` registra l'approvazione delle promesse d'entità scrivendo lo `STATUS` in ciascuna
di esse:

```
$ bcdd ratify LuceScale.csc --all D-20
approvate con D-20 nella ENTITY LuceScale: 3 righe
  riga 11: GUARANTEE ls1
  riga 13: GUARANTEE ls2
  riga 15: GUARANTEE ls3
contratto: 3
```

**CSC citata che non si trova.** Se l'entità cita con `OFFERS Citofono` una CSC di cui non esiste il file,
la citazione compare nella sezione 7, intitolata «CSC NOMINATE E NON CONTROLLATE»:

```
7. CSC NOMINATE E NON CONTROLLATE: 1
  riga 9: Citofono
```

Non è un errore: la sezione riporta che la CSC non è stata controllata. La sezione 7 elenca anche le entità
citate come parti e non trovate (capitolo 13).

**Collocazione dell'entità.** Il fatto che il pulsante stia nell'androne e la lampada sul soffitto non si
scrive: nessuna forma del linguaggio indica dove si trova un'entità.

---

## Capitolo 13 — Un'entità fatta di parti

La luce delle scale è costituita da due apparecchi, un pulsante e una lampada, che possono essere realizzati
da persone diverse. Il capitolo descrive come dividere un'entità in parti, come scrivere il confine fra le
parti e come `bcdd` controlla che l'entità sia chiusa.

### Le parti

Una **parte** è un'entità contenuta in un'altra entità. Le parti si elencano sotto la riga `COMPOSED OF`, una
per riga, nella forma `nome : Entità`. La riga `COMPOSED OF` e le righe che la seguono formano l'**elenco
delle parti**. Il primo nome, il **nome della parte**, indica il ruolo della parte nell'entità che la contiene
(`pulsante`); il secondo è il nome dell'entità che descrive la parte (`Pulsante`). La riga `COMPOSED OF` si
scrive una volta sola.

A ogni pressione il pulsante comanda alla lampada di accendersi. Fra le due parti esiste quindi un confine,
descritto dalla CSC `Comando`, scritta dal lato di chi offre, cioè dal pulsante:

```
-- Il comando che il pulsante invia alla lampada.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante comanda alla lampada di accendersi"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "Fra due accendi passano almeno 0,2 s"
                VERIFY BY INSPECTION "i comandi registrati"
END
```

Le due parti sono entità, ciascuna nel proprio file. Il pulsante offre la pressione a chi sta sulle scale e
il comando alla lampada:

```
-- Il pulsante delle scale, una delle due parti della luce.

ENTITY Pulsante VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante riceve la pressione e comanda la lampada"

  OFFERS Pressione
  OFFERS Comando

  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s"
                 VERIFY BY INSPECTION "le pressioni e i comandi registrati"
END
```

La lampada usa il comando e l'alimentazione e offre la luce:

```
-- La lampada delle scale, una delle due parti della luce.

ENTITY Lampada VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La lampada si accende al comando e si spegne da sola"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE la1: VERBAL "Dopo un accendi la luce si accende entro 0,5 s"
                 VERIFY BY JUDGEMENT "una persona che osserva la lampada mentre si invia il comando"
  GUARANTEE la2: VERBAL "La luce si spegne 90 s dopo l'ultimo accendi, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"
END
```

L'entità `LuceScale` elenca le due parti:

```
-- La luce delle scale, fatta di un pulsante e di una lampada.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE ls3: VERBAL "Durante le pulizie una pressione del pulsante non cambia il modo"
                 VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
END
```

Le promesse d'entità restano quelle del capitolo 12. Poiché non sono ancora approvate, l'entità resta
alla versione 0.1 e si modifica direttamente (capitolo 10).

`LuceScale` non offre né usa `Comando`: il confine fra le due parti è **interno** all'entità e non è
osservabile dall'esterno. Chi sta sulle scale continua a osservare soltanto la pressione e la luce. Non occorre
indicare come il comando giunga dal pulsante alla lampada: le due parti citano la stessa CSC e si riferiscono
quindi agli stessi eventi. Le caratteristiche concrete del mezzo, un filo o un segnale, non si scrivono nella CSC (capitolo 25).

### Chi usa trova chi offre

In un'entità fatta di parti vale la regola **chi usa trova chi offre**: ogni CSC usata da una parte è offerta
da un'altra parte oppure è usata dall'entità stessa verso l'esterno (nel rapporto: «da fuori»). Nell'esempio, la
lampada usa `Comando`, che il pulsante offre, e usa `Alimentazione`, che l'entità usa da fuori. La riga
`OFFERS` di una parte non soddisfa la riga `USES` della stessa parte.

La regola ha due complementi:

- ogni confine che l'entità offre o usa verso l'esterno, detto **confine pubblico**, è affidato a una parte.
  La parte lo offre, se lo offre l'entità; lo usa, se lo usa l'entità. `Pressione`, offerta dall'entità, è
  offerta anche dal pulsante;
- ogni confine offerto da una parte è usato da un'altra parte oppure offerto dall'entità: `Comando` è usato
  dalla lampada, `Luce` è offerta da `LuceScale`.

Un'entità che rispetta la regola e i suoi due complementi è **chiusa**. `bcdd` segnala la mancata chiusura
con tre errori: E14 per una CSC usata da una parte e non offerta da alcuna parte, E16 per un confine pubblico
non affidato ad alcuna parte, E17 per una CSC offerta da una parte e non usata da alcuna parte.

I presupposti della CSC `Alimentazione` devono essere rispettati da chi la usa: dall'entità verso la rete e
dalla lampada all'interno dell'entità. `bcdd` non lo controlla, perché i presupposti sono scritti a parole.

### Il rapporto

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 21 (riconosciute 16, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: pulsante : Pulsante in Pulsante.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 13: lampada : Lampada in Lampada.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 3
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 15: GUARANTEE ls1 verbale
  riga 17: GUARANTEE ls2 verbale
  riga 19: GUARANTEE ls3 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 3
  riga 15: GUARANTEE ls1
  riga 17: GUARANTEE ls2
  riga 19: GUARANTEE ls3

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 2
  riga 13: lampada usa Comando: la offre pulsante (riga 12)
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)

esito: nessun errore
```

Sotto l'entità compaiono anche le citazioni delle parti: `riga 12: pulsante : Pulsante in Pulsante.csc alla
riga 3` indica che l'entità `Pulsante` è stata trovata nel file `Pulsante.csc`.

La sezione 8, «usi dentro le entità», riporta, per ogni CSC usata da una parte, chi la offre:

- `lampada usa Comando: la offre pulsante (riga 12)`: la CSC è offerta da un'altra parte, indicata con il nome
  che ha nell'entità e con la riga in cui è elencata;
- `lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)`: la CSC è usata dall'entità verso l'esterno.

### Dove bcdd cerca i file citati

Per ogni CSC citata e per ogni parte `bcdd` cerca il blocco con quel nome in quest'ordine:

1. nel file controllato;
2. nel file con lo stesso nome e l'estensione `.csc`, nella cartella del file controllato (`Comando.csc` per la
   CSC `Comando`);
3. nel file con lo stesso nome e l'estensione `.csc`, nelle cartelle indicate con l'opzione `--dir`,
   nell'ordine in cui sono scritte.

Di una parte `bcdd` legge soltanto le righe `OFFERS` e `USES`, non le sue parti né le CSC citate. Ogni
entità si controlla quindi nel proprio file: `bcdd check Pulsante.csc` controlla il pulsante e le CSC che
cita.

### Riepilogo

- Una **parte** è un'entità contenuta in un'altra; le parti si elencano dopo `COMPOSED OF`, nella forma
  `nome : Entità`.
- Il confine fra due parti è interno all'entità e non è osservabile dall'esterno.
- **Chi usa trova chi offre**: ogni CSC usata da una parte è offerta da un'altra parte o usata dall'entità verso
  l'esterno; ogni confine pubblico è affidato a una parte; ogni CSC offerta da una parte è usata da un'altra
  parte o offerta dall'entità.
- `bcdd` segnala la mancata chiusura con gli errori E14, E16 ed E17 e riporta gli usi nella sezione 8 del
  rapporto.

### Casi particolari

**Parte tolta dall'elenco.** Se dall'elenco si toglie il pulsante, nessuna parte offre la CSC usata dalla
lampada, e il confine pubblico `Pressione` non è affidato ad alcuna parte:

```
1. ERRORI: 2
  riga 7: [E16] il connettore pubblico Pressione di LuceScale (offre) non è affidato a nessuna parte
  riga 12: [E14] la parte lampada usa il connettore Comando: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori
…
8. USI DENTRO LE ENTITÀ: 2
  riga 12: lampada usa Comando: nessuno la offre
  riga 12: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)
```

**Confine offerto da una parte e non dall'entità.** Se si toglie la riga `OFFERS Luce` dall'entità, la luce
offerta dalla lampada non è usata da alcuna parte né offerta dall'entità:

```
1. ERRORI: 1
  riga 12: [E17] la parte lampada offre il connettore Luce: nessun'altra parte di LuceScale lo usa, né LuceScale lo offre da fuori
```

**Parte non trovata.** Se il file `Pulsante.csc` non esiste, la parte è elencata nella sezione 7 con il nome
dell'entità non trovata, e il controllo della chiusura viene sospeso:

```
1. ERRORI: 0
…
7. CSC NOMINATE E NON CONTROLLATE: 1
  riga 12: Pulsante

8. USI DENTRO LE ENTITÀ: 2
  riga 13: lampada usa Comando: nessuna parte trovata la offre (parti non controllate: 1)
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)

esito: nessun errore
```

`bcdd` non segnala gli errori E14, E16 ed E17 finché non sono state trovate tutte le parti: una parte non
controllata potrebbe offrire la CSC mancante. L'esito «nessun errore», in questo caso, va letto insieme alla
sezione 7.

---

## Capitolo 14 — Un canale che perde o ritarda: il pulsante senza fili

Nell'androne non si può posare un filo; il pulsante è quindi senza fili e invia un messaggio radio a un
ricevitore installato accanto alla lampada. Un messaggio radio può andare perso o arrivare in ritardo. Il
capitolo descrive come rappresentare un mezzo di questo tipo e come scrivere un confine esterno all'entità.

### Il canale

Un **canale** è un mezzo che trasferisce messaggi da un sistema a un altro e che può perderli, ritardarli o
alterarne l'ordine. Il suo comportamento si descrive in un confine a sé, con la propria CSC.

Se il pulsante senza fili offrisse direttamente `Comando` alla lampada, la promessa del pulsante «a ogni
pressione segue un accendi entro 0,1 s» sarebbe violata ogni volta che un messaggio va perso, senza che alcuna
riga lo indichi. La perdita e il ritardo si osservano sul tratto radio, fra il pulsante e il ricevitore: le
promesse che li riguardano si scrivono nella CSC di quel tratto.

Le caratteristiche concrete del mezzo (frequenza, protocollo radio, formato dei messaggi) non si scrivono qui
(capitolo 25).

### Le CSC e le entità del pulsante senza fili

Il canale radio è descritto dalla CSC `Trasmissione`, scritta dal lato di chi offre, cioè dal pulsante:

```
-- Il canale senza fili fra il pulsante e il ricevitore.

CSC Trasmissione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante senza fili invia messaggi radio al ricevitore accanto alla lampada"

  EVENT OUT  messaggio

  GUARANTEE t1: VERBAL "Un messaggio inviato arriva entro 0,3 s oppure va perso"
                VERIFY BY INSPECTION "i messaggi registrati all'invio e alla ricezione"
  GUARANTEE t2: VERBAL "Due messaggi possono arrivare in ordine diverso da quello di invio"
                VERIFY BY INSPECTION "i messaggi registrati all'invio e alla ricezione"
  GUARANTEE t3: VERBAL "Non arriva mai un messaggio che non sia stato inviato"
                VERIFY BY INSPECTION "i messaggi registrati all'invio e alla ricezione"
END
```

Le promesse di `Trasmissione` stabiliscono su che cosa può contare chi usa la trasmissione. Un messaggio può
andare perso; se arriva, arriva entro 0,3 s. L'ordine di arrivo non è garantito. Non arrivano messaggi che nessuno ha
inviato. Sono promesse che impegnano poco chi offre, ma sono precise.

Il pulsante senza fili offre la pressione e la trasmissione, e riduce l'effetto delle perdite inviando tre
messaggi per ogni pressione:

```
-- Il pulsante senza fili.

ENTITY PulsanteRadio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante senza fili riceve la pressione e la trasmette al ricevitore"

  OFFERS Pressione
  OFFERS Trasmissione

  GUARANTEE pr1: VERBAL "A ogni pressione il pulsante invia tre messaggi, a 50 ms l'uno dall'altro"
                 VERIFY BY INSPECTION "le pressioni e i messaggi registrati"
END
```

Il ricevitore usa la trasmissione e offre il comando alla lampada:

```
-- Il ricevitore accanto alla lampada.

ENTITY Ricevitore VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il ricevitore riceve i messaggi del pulsante senza fili e comanda la lampada"

  USES   Trasmissione
  USES   Alimentazione
  OFFERS Comando

  GUARANTEE ri1: VERBAL "Un messaggio ricevuto produce un accendi entro 0,05 s; i messaggi ricevuti nei 0,2 s successivi non ne producono altri"
                 VERIFY BY INSPECTION "i messaggi ricevuti e i comandi registrati"
END
```

### Un confine esterno all'entità

La lampada e il suo ricevitore formano un'entità, `LampadaRadio`. La trasmissione è offerta dal pulsante, che
non fa parte di questa entità: è quindi un **confine esterno** e si dichiara sull'entità con `USES`.
All'interno, la riga `USES` del ricevitore è soddisfatta dalla riga `USES` dell'entità («da fuori»):

```
-- La lampada con il suo ricevitore.

ENTITY LampadaRadio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La lampada riceve i messaggi del pulsante senza fili, si accende e si spegne da sola"

  USES   Trasmissione
  USES   Alimentazione
  OFFERS Luce

  COMPOSED OF
    ricevitore : Ricevitore
    lampada    : Lampada

  GUARANTEE lr1: VERBAL "Dopo un messaggio ricevuto la luce si accende entro 0,6 s"
                 VERIFY BY JUDGEMENT "una persona che osserva la lampada mentre si invia un messaggio"
END
```

```
$ bcdd check --strict LampadaRadio.csc
bcdd check --strict LampadaRadio.csc
righe: 17 (riconosciute 12, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LampadaRadio VERSION 0.1, STATUS HYPOTHESIS
    riga 7: USES Trasmissione in Trasmissione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: ricevitore : Ricevitore in Ricevitore.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 13: lampada : Lampada in Lampada.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 1
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 15: GUARANTEE lr1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 1
  riga 15: GUARANTEE lr1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 4
  riga 12: ricevitore usa Trasmissione: la usa LampadaRadio da fuori (riga 7)
  riga 12: ricevitore usa Alimentazione: la usa LampadaRadio da fuori (riga 8)
  riga 13: lampada usa Comando: la offre ricevitore (riga 12)
  riga 13: lampada usa Alimentazione: la usa LampadaRadio da fuori (riga 8)

esito: nessun errore
```

La sezione 8 riporta `ricevitore usa Trasmissione: la usa LampadaRadio da fuori (riga 7)`. Il confine
`Comando` è interno a `LampadaRadio`: la riga `USES Comando` della lampada è soddisfatta dal ricevitore, che lo
offre.

L'entità completa, `LuceSenzaFili`, contiene il pulsante senza fili e la lampada con il suo ricevitore:

```
-- La luce delle scale con il pulsante senza fili.

ENTITY LuceSenzaFili VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante senza fili e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : PulsanteRadio
    lampada  : LampadaRadio

  GUARANTEE lf1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende entro 1 s, salvo che vadano persi tutti e tre i messaggi"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
END
```

```
$ bcdd check --strict LuceSenzaFili.csc
…
8. USI DENTRO LE ENTITÀ: 2
  riga 13: lampada usa Trasmissione: la offre pulsante (riga 12)
  riga 13: lampada usa Alimentazione: la usa LuceSenzaFili da fuori (riga 9)

esito: nessun errore
```

In `LuceSenzaFili` il confine `Comando` non compare: è interno a `LampadaRadio`, e di una parte `bcdd` legge
soltanto le righe `OFFERS` e `USES` (capitolo 13).

La promessa d'entità `lf1` considera le perdite del canale: la luce si accende entro un secondo, salvo che vadano persi
tutti e tre i messaggi. Una promessa che ignorasse le perdite prometterebbe più di quanto il canale consente.

### Riepilogo

- Un **canale** è un mezzo che può perdere, ritardare o alterare l'ordine di ciò che trasporta; il suo
  comportamento si descrive in un confine a sé, con la propria CSC, nella quale si scrivono le perdite e i
  ritardi ammessi.
- Un confine esterno a un'entità si dichiara sull'entità con `USES`; la riga `USES` della parte è soddisfatta
  dalla riga `USES` dell'entità («usato da fuori»).
- Le caratteristiche concrete del mezzo non si scrivono nella CSC (capitolo 25).

### Casi particolari

**Confine esterno non dichiarato.** Se in `LampadaRadio` manca la riga `USES Trasmissione`, il ricevitore usa
una CSC che nessuna parte offre:

```
1. ERRORI: 1
  riga 11: [E14] la parte ricevitore usa il connettore Trasmissione: nessun'altra parte di LampadaRadio lo offre, né LampadaRadio lo usa da fuori
```

La riga mancante ha effetto anche sull'entità che contiene `LampadaRadio`: in `LuceSenzaFili` la trasmissione
offerta dal pulsante non è più usata da alcuna parte.

```
1. ERRORI: 1
  riga 12: [E17] la parte pulsante offre il connettore Trasmissione: nessun'altra parte di LuceSenzaFili lo usa, né LuceSenzaFili lo offre da fuori
```

**Canale non scritto.** Se il pulsante senza fili dichiara `OFFERS Comando` e la lampada usa `Comando`
direttamente, senza ricevitore né `Trasmissione`, il rapporto non segnala errori. `bcdd` controlla la
corrispondenza fra usi e offerte, non che il mezzo sia descritto: stabilire che il tratto radio può perdere
messaggi spetta a chi scrive la CSC.

---

## Capitolo 15 — Le versioni dei confini

Una lampada nuova tiene la luce accesa più a lungo per chi sale agli ultimi piani e per farlo richiede
l'indicazione del piano da cui proviene il comando. Il comando cambia: la CSC `Comando` passa alla versione 0.2.
Il vecchio pulsante, però, offre soltanto la versione 0.1. Il capitolo descrive come indicare una versione
precisa di una CSC, in quali casi due righe che citano la stessa CSC corrispondono e come una parte può offrire
due versioni dello stesso confine.

### La versione indicata

Dopo il nome della CSC, in una riga `OFFERS` o `USES`, si può indicare una versione: `USES Comando VERSION
0.2`. La **versione indicata** identifica la versione della CSC a cui la riga si riferisce. Una riga senza versione
non ne fissa alcuna: `bcdd` accetta il file della CSC in qualsiasi versione, e una riga `USES` senza versione
corrisponde a ogni riga `OFFERS` della stessa CSC. Una riga `OFFERS` senza versione, invece, non soddisfa
una riga `USES` che indica una versione (tabella seguente).

La versione 0.2 di `Comando` aggiunge all'evento `accendi` il parametro `piano`:

```
-- Il comando che il pulsante invia alla lampada.
-- VERSION 0.2: il comando indica il piano del pulsante premuto. Da approvare.

CSC Comando VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante comanda alla lampada di accendersi e indica da quale piano"

  EVENT OUT  accendi(piano: Integer [0 .. 5])

  GUARANTEE c1: VERBAL "Fra due accendi passano almeno 0,2 s"
                VERIFY BY INSPECTION "i comandi registrati"
  GUARANTEE c2: VERBAL "Il parametro piano è il piano del pulsante premuto"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante di ogni piano e legge i comandi registrati"
END
```

In una cartella può esserci un solo file `Comando.csc`; la versione 0.2 si trova quindi in un'altra
cartella, `versioni`, mentre la 0.1 rimane nella cartella degli altri file.

La lampada nuova indica la versione 0.2:

```
-- La lampada nuova, che tiene la luce accesa più a lungo per chi sale agli ultimi piani.

ENTITY LampadaNuova VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La lampada si accende al comando e resta accesa più a lungo se il comando viene dagli ultimi piani"

  USES   Comando VERSION 0.2
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE ln1: VERBAL "Dopo un accendi la luce si accende entro 0,5 s"
                 VERIFY BY JUDGEMENT "una persona che osserva la lampada mentre si invia il comando"
  GUARANTEE ln2: VERBAL "La luce si spegne 90 s dopo l'ultimo accendi, oppure 120 s dopo se l'ultimo accendi viene dal quarto o dal quinto piano, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"
END
```

### La corrispondenza fra due righe

Una riga `USES` di una parte è soddisfatta se esiste una riga `OFFERS` di un'altra parte, o una riga `USES`
dell'entità, con lo stesso nome e una versione che **corrisponde**:

| La riga `USES` della parte | L'altra riga | Corrispondenza |
|---|---|---|
| `USES Comando` | `OFFERS Comando`, con o senza versione | sì |
| `USES Comando VERSION 0.2` | `OFFERS Comando VERSION 0.2` | sì |
| `USES Comando VERSION 0.2` | `OFFERS Comando VERSION 0.1` | no |
| `USES Comando VERSION 0.2` | `OFFERS Comando`, senza versione | no |

L'ultima riga della tabella mostra che una riga `OFFERS` senza versione non soddisfa una riga `USES` che
indica una versione. Le versioni si confrontano come stringhe di caratteri: `0.1` e `0.10` sono versioni diverse. `bcdd` non valuta se due
versioni diverse siano compatibili nel contenuto: una versione che aggiunge soltanto un parametro resta una
versione diversa.

### La lampada nuova con il pulsante vecchio

Il pulsante del capitolo 13 dichiara `OFFERS Comando`, senza versione: quando è stato scritto esisteva soltanto
la 0.1. In un'entità con il pulsante vecchio e la lampada nuova il rapporto riporta:

```
1. ERRORI: 2
  riga 12: [E17] la parte pulsante offre il connettore Comando: nessun'altra parte di LuceScale lo usa, né LuceScale lo offre da fuori
  riga 13: [E14] la parte lampada usa il connettore Comando VERSION 0.2: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori
…
8. USI DENTRO LE ENTITÀ: 2
  riga 13: lampada usa Comando VERSION 0.2: nessuno la offre
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)
```

La lampada indica la versione 0.2 e nessuna parte la offre (E14); il comando offerto dal pulsante non
corrisponde alla riga `USES` della lampada, quindi nessuna parte lo usa (E17). Lo stesso rapporto si ottiene se il pulsante scrive `OFFERS
Comando VERSION 0.1`.

### Due versioni dello stesso confine

Nel condominio la lampada del piano terra resta quella vecchia e all'ultimo piano si installa la lampada
nuova. Il pulsante deve allora soddisfare entrambe le lampade e offre le due versioni del comando:

```
-- Il pulsante delle scale, una delle parti della luce.
-- VERSION 0.2: offre il comando nelle versioni 0.1 e 0.2. Da approvare.

ENTITY Pulsante VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante riceve la pressione e comanda la lampada"

  OFFERS Pressione
  OFFERS Comando VERSION 0.1
  OFFERS Comando VERSION 0.2

  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s"
                 VERIFY BY INSPECTION "le pressioni e i comandi registrati"
END
```

Un'entità che offre due versioni della stessa CSC mantiene per intero le promesse di ciascuna: chi usa la 0.1
può contare sulle promesse della 0.1, chi usa la 0.2 su quelle della 0.2. Il modo in cui le due versioni
coesistono nel pulsante non si scrive: è una scelta di chi lo realizza.

Per controllare il pulsante, `bcdd` deve trovare entrambe le versioni di `Comando`. Senza l'opzione `--dir`
trova soltanto il file nella cartella del file controllato, che contiene la versione 0.1, e lo segnala con
`attesa VERSION 0.2`, cioè con la versione indicata nella riga:

```
$ bcdd check --strict Pulsante.csc
bcdd check --strict Pulsante.csc
…
    riga 9: OFFERS Comando in Comando.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 10: OFFERS Comando in Comando.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore, attesa VERSION 0.2
```

L'opzione `--dir` indica un'altra cartella in cui cercare (capitolo 13):

```
$ bcdd check --strict --dir versioni Pulsante.csc
bcdd check --strict --dir versioni Pulsante.csc
righe: 14 (riconosciute 9, commenti 2, vuote 3, non riconosciute 0)
blocchi: 1
  riga 4: ENTITY Pulsante VERSION 0.2, STATUS HYPOTHESIS
    riga 8: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: OFFERS Comando in Comando.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 10: OFFERS Comando in versioni/Comando.csc alla riga 4: VERSION 0.2, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 1
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 12: GUARANTEE pu1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 1
  riga 12: GUARANTEE pu1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 0

esito: nessun errore
```

L'entità con le due lampade:

```
-- La luce delle scale, con la lampada vecchia al piano terra e quella nuova all'ultimo piano.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante      : Pulsante
    lampada       : Lampada
    lampada_alta  : LampadaNuova

  GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
END
```

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 18 (riconosciute 13, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: pulsante : Pulsante in Pulsante.csc alla riga 4: VERSION 0.2, STATUS HYPOTHESIS, nessun errore
    riga 13: lampada : Lampada in Lampada.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 14: lampada_alta : LampadaNuova in LampadaNuova.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 1
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 16: GUARANTEE ls1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 1
  riga 16: GUARANTEE ls1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 4
  riga 13: lampada usa Comando: la offre pulsante (riga 12)
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)
  riga 14: lampada_alta usa Comando VERSION 0.2: la offre pulsante (riga 12)
  riga 14: lampada_alta usa Alimentazione: la usa LuceScale da fuori (riga 9)

esito: nessun errore
```

La lampada vecchia usa `Comando` senza versione e la lampada nuova indica la 0.2: il pulsante soddisfa
entrambe le lampade. Nella riga della sezione 8 relativa alla lampada vecchia il pulsante compare una volta
sola, anche se offre due versioni che corrispondono alla riga `USES` della lampada.

### Riepilogo

- In una riga `OFFERS` o `USES` si può indicare la **versione** della CSC citata.
- Una riga `USES` senza versione corrisponde a ogni riga `OFFERS` della stessa CSC; una riga `USES` con
  versione corrisponde soltanto a una riga `OFFERS` che indica la stessa versione.
- Un'entità può offrire due versioni della stessa CSC e mantiene per intero le promesse di ciascuna.
- Una versione diversa da quella indicata non è un errore della CSC citata: il rapporto la segnala con
  l'indicazione `attesa VERSION`.

### Casi particolari

**Versione indicata non trovata.** Se si controlla la lampada nuova senza `--dir`, viene trovata la
versione 0.1:

```
    riga 7: USES Comando in Comando.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore, attesa VERSION 0.2
```

Non è un errore: `bcdd` segnala che il file trovato non contiene la versione indicata.

**Stessa CSC con e senza versione.** Fra righe dello stesso tipo, una riga senza versione vale per tutte le
versioni: scritta insieme a una riga con versione dello stesso nome, ne è un duplicato (E01). Lo stesso vale per due righe con la stessa
versione. Se la riga 3 è `OFFERS Comando` e la riga 4 `OFFERS Comando VERSION 0.2`, e le righe 5 e 6 sono
entrambe `OFFERS Pressione VERSION 0.1`, il rapporto riporta:

```
1. ERRORI: 2
  riga 4: [E01] nome già usato alla riga 3: Comando
  riga 6: [E01] nome già usato alla riga 5: Pressione
```

---

## Capitolo 16 — Il numero di copie di una parte

Il condominio ha cinque piani, e su ogni piano c'è un pulsante. I pulsanti sono uguali: ciascuno offre
`Pressione` e `Comando`. Il capitolo descrive come indicare il numero di copie di una parte e che cosa promette
ciascuna copia.

### La molteplicità

Nella riga di una parte, dopo il nome dell'entità che la descrive (qui `Pulsante`), si può indicare fra
parentesi quadre il numero di copie della parte contenute nell'entità: `pulsante : Pulsante [1 .. 5]` indica da una a cinque copie. Questa
indicazione si chiama **molteplicità**. I due numeri, il minimo e il massimo, sono interi, e il minimo non
supera il massimo. Senza molteplicità una parte ha esattamente una copia.

```
-- La luce delle scale, con un pulsante per piano.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante del suo piano e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante [1 .. 5]
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "Quando qualcuno preme uno qualunque dei pulsanti, la luce si accende"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante di ogni piano e guarda"
  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultima pressione su uno qualunque dei pulsanti, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona che preme pulsanti di piani diversi e misura con un cronometro"
END
```

Le promesse d'entità si riferiscono ora a «uno qualunque dei pulsanti».

### Che cosa promette ogni copia

Ogni copia mantiene per intero le promesse dell'entità che descrive la parte: ogni pulsante offre `Pressione`
e `Comando` e mantiene la promessa `pu1`. La molteplicità non stabilisce altro:

- non indica quando una copia è presente: le copie restano per tutto il funzionamento;
- non distingue le copie fra loro: nessuna ha un nome che la distingua dalle altre, nessuna ha precedenza
  sulle altre;
- non indica dove si trovano le copie: che ci sia un pulsante per piano è scritto nel testo dello scopo, non
  nella molteplicità.

Una copia non usa ciò che offre un'altra copia della stessa parte: la riga `OFFERS` di una copia non soddisfa
la riga `USES` di un'altra copia.

### Il rapporto

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 19 (riconosciute 14, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: pulsante : Pulsante in Pulsante.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 13: lampada : Lampada in Lampada.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 2
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 15: GUARANTEE ls1 verbale
  riga 17: GUARANTEE ls2 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 2
  riga 15: GUARANTEE ls1
  riga 17: GUARANTEE ls2

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 2
  riga 13: lampada usa Comando: la offre pulsante (riga 12)
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)

esito: nessun errore
```

Nel rapporto la citazione della parte non riporta la molteplicità: `riga 12: pulsante : Pulsante in
Pulsante.csc`. Ai fini della chiusura la riga conta come una sola parte, qualunque sia il numero delle copie.

### Riepilogo

- La **molteplicità** `[m .. n]` indica che l'entità contiene da `m` a `n` copie di una parte; senza
  molteplicità la parte ha una copia.
- Ogni copia mantiene per intero le promesse della parte; nessuna ha precedenza e nessuna usa ciò che offre un'altra
  copia.
- La molteplicità non indica quando una copia è presente, come si distinguono le copie, né dove si trovano.

### Casi particolari

**Minimo maggiore del massimo.** Con `[5 .. 1]`:

```
1. ERRORI: 1
  riga 12: [E19] la parte pulsante ha un numero di copie non valido: [5 .. 1]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo
```

La riga conta comunque come una parte: la chiusura si controlla come se la molteplicità fosse corretta. Lo stesso errore
compare per un limite con la parte decimale, come `[1.5 .. 5]`. Il minimo 0 indica una parte che può
mancare (capitolo 19).

**Molteplicità incompleta.** La riga `pulsante : Pulsante [1 .. ]` non viene riconosciuta e non è una parte:
l'entità risulta priva del pulsante, con gli errori del capitolo 13.

```
1. ERRORI: 2
  riga 7: [E16] il connettore pubblico Pressione di LuceScale (offre) non è affidato a nessuna parte
  riga 13: [E14] la parte lampada usa il connettore Comando: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori
…
5. RIGHE NON RICONOSCIUTE: 1
  riga 12: pulsante : Pulsante [1 .. ]
```

**Copie che devono usare ciascuna il comando delle altre.** Un pulsante ha una spia che lampeggia a ogni
comando, anche a quelli degli altri pulsanti. Per questo offre e usa `Comando`:

```
-- Il pulsante con la spia.

ENTITY PulsanteSpia VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante riceve la pressione, comanda la lampada e accende la sua spia a ogni comando"

  OFFERS Pressione
  OFFERS Comando
  USES   Comando

  GUARANTEE ps1: VERBAL "A ogni pressione segue un accendi entro 0,1 s"
                 VERIFY BY INSPECTION "le pressioni e i comandi registrati"
  GUARANTEE ps2: VERBAL "A ogni accendi, inviato da questo pulsante o da un altro, la spia del pulsante lampeggia per 1 s"
                 VERIFY BY JUDGEMENT "una persona che preme un pulsante e guarda la spia degli altri"
END
```

In un'entità con `pulsante : PulsanteSpia [1 .. 5]` la copia che invia il comando non soddisfa le righe `USES`
delle altre copie:

```
1. ERRORI: 1
  riga 12: [E14] la parte pulsante usa il connettore Comando: nessun'altra parte di LuceSpia lo offre, né LuceSpia lo usa da fuori
```

Se ogni pulsante deve usare il comando degli altri, i pulsanti si scrivono come parti distinte, una per piano
(`piano1 : PulsanteSpia`, `piano2 : PulsanteSpia`, …): ciascuna parte soddisfa le righe `USES` delle altre.

---

## Capitolo 17 — La dimensione di un'entità

La luce delle scale è divisa in un pulsante e in una lampada. La lampada si potrebbe dividere ancora, in un
relè, un temporizzatore e una lampadina. Il capitolo fornisce il criterio per stabilire quando un'entità ha la
dimensione adeguata e quando non va divisa ulteriormente.

### Il criterio

Chi realizza un'entità, una persona o un modello linguistico, lavora a partire dalla sua descrizione.
Un'entità ha la dimensione adeguata quando chi la realizza riesce a considerare insieme:

- le CSC dei confini che l'entità offre e usa;
- le promesse d'entità;
- i confini delle parti vicine.

Le **parti vicine** di una parte sono le altre parti della stessa entità che citano una delle sue CSC: il
pulsante e la lampada sono parti vicine, perché citano entrambi `Comando`. Di una parte vicina conta soltanto
ciò che è osservabile dall'esterno: le CSC che cita e le sue promesse d'entità, non le sue parti né il modo in cui è
realizzata.

Se un'entità è troppo grande per essere considerata per intero, si divide in parti, ciascuna delle quali
rispetta lo stesso criterio. Il linguaggio non fissa una soglia numerica: il criterio indica un limite
superiore, non uno inferiore.

### Perché la luce si divide in pulsante e lampada

Il pulsante e la lampada sono realizzati da persone diverse, con competenze diverse, e il comando che passa
fra loro è osservabile. Ciascuna delle due parti si descrive con pochi confini e poche promesse, e la divisione
riduce ciò che ciascun realizzatore deve considerare.

La lampada, invece, non si divide ulteriormente. Il relè, il temporizzatore e la lampadina sono scelte di chi
realizza la lampada (capitolo 1): fra loro non passa nulla che debba essere osservabile dall'esterno
della lampada. Descriverli come parti fisserebbe scelte che spettano a chi realizza, senza ridurre ciò che chi
realizza deve considerare.

### Il segnale di una divisione eccessiva

Un'entità costituita da una sola parte, che offre e usa gli stessi confini della parte, ripete la parte senza
aggiungere nulla: è il segnale di una **divisione eccessiva**.

```
-- La lampada divisa ancora: un'entità con una sola parte.

ENTITY Apparecchio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'apparecchio della lampada delle scale"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  COMPOSED OF
    lampada : Lampada
END
```

```
$ bcdd check --strict Apparecchio.csc
…
8. USI DENTRO LE ENTITÀ: 2
  riga 12: lampada usa Comando: la usa Apparecchio da fuori (riga 7)
  riga 12: lampada usa Alimentazione: la usa Apparecchio da fuori (riga 8)

esito: nessun errore
```

Il rapporto non segnala errori: una divisione eccessiva non è un errore di scrittura, e spetta a chi scrive
riconoscerla. L'entità `Apparecchio` si elimina, e al suo posto si usa direttamente `Lampada`.

### Riepilogo

- Un'entità ha la dimensione adeguata quando chi la realizza riesce a considerare insieme i suoi confini, le
  sue promesse d'entità e i confini delle parti vicine.
- Le **parti vicine** di una parte sono le altre parti della stessa entità che citano una stessa CSC.
- Un'entità troppo grande si divide in parti; una scelta interna di chi realizza non diventa una parte.
- Un'entità con una sola parte che offre e usa gli stessi confini segnala una divisione eccessiva.

### Casi particolari

**Entità troppo grande.** `bcdd` non misura la dimensione di un'entità: un'entità con molti confini e molte
promesse è scritta correttamente quanto una piccola. Il criterio si applica a giudizio di chi scrive.

**Parti senza confini osservabili.** Se fra due parti candidate non passa nulla che si possa osservare, non
c'è una CSC da scrivere fra loro: le due parti sono, di fatto, una sola entità.

---

## Capitolo 18 — Storie su più confini

Le storie della parte prima (capitoli 1-10) nominano elementi di un solo confine. Con la divisione del
capitolo 11 le storie `s1`, `s2` e `s3`, che nominano sia la pressione sia la luce, non si possono più scrivere
in nessuna delle due CSC. Il capitolo descrive dove si scrivono: nell'entità.

### La storia d'entità

Una **storia d'entità** è una storia scritta in un'entità, nella quale ogni nome di evento, stato o richiesta
è preceduto dal nome della CSC a cui appartiene e da un punto: `Pressione.premuto`, `Luce.modo`. Un nome
scritto in questa forma si chiama **nome qualificato**.

Una CSC descrive soltanto il proprio confine e non può stabilire un ordine fra ciò che accade su due confini
diversi. L'entità offre o usa entrambi i confini, e la storia d'entità è la forma in cui si scrive quell'ordine.

Nell'entità `LuceScale` del capitolo 13 si aggiungono quattro storie, dopo le promesse d'entità:

```
  SCENARIO ls-s1 EXPECT ADMITTED
    @0 s     Pressione.premuto
    @1 s     Luce.modo = accesa
  SCENARIO ls-s2 EXPECT ADMITTED
    @0 s     Pressione.premuto    Luce.modo = accesa
    @85 s    Luce.avviso
    @90 s    Luce.modo = spenta
    @100 s   Pressione.premuto    Luce.modo = accesa
  SCENARIO ls-s3 EXPECT REJECTED
    @0 s     Pressione.premuto    Luce.modo = accesa
    @30 s    Luce.modo = spenta
  SCENARIO ls-s4 GIVEN Luce.modo = in_pulizia EXPECT ADMITTED
    @0 s     Pressione.premuto    Luce.modo = in_pulizia
END
```

La storia `ls-s1` si legge: all'istante 0 si preme il pulsante e all'istante 1 la luce è accesa. Le storie `ls-s2`,
`ls-s3` e `ls-s4` sono le storie `s1`, `s2` e `s3` di `UsoLuce`, riscritte con i nomi qualificati e con il
tempo di spegnimento di 90 secondi.

Per il resto una storia d'entità si scrive come una storia di CSC (capitolo 9): istanti in ordine di tempo,
stato di partenza con `GIVEN`, esito atteso con `EXPECT`. Una storia d'entità è un esempio, non un obbligo: non è una riga
contrattuale e non vieta ciò che non descrive. Non stabilisce un ordine fra le parti né una
priorità, e non descrive un canale: riporta ciò che si osserva sui confini dell'entità.

### Che cosa controlla bcdd

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 35 (riconosciute 29, commenti 1, vuote 5, non riconosciute 0)
…
1. ERRORI: 0
…
esito: nessun errore
```

Per ogni nome qualificato `X.y` `bcdd` controlla due condizioni: che `X` sia una CSC offerta o usata
dall'entità, e che nella CSC `X` esista l'elemento `y` del genere atteso. Il genere atteso è uno stato in
`Luce.modo = accesa`, un evento in `Pressione.premuto`, una richiesta fra le parentesi di una fase del ciclo
di vita. Controlla anche i parametri degli eventi e
l'ordine dei tempi, come nella CSC.

Una storia d'entità nomina soltanto i confini pubblici dell'entità, mai i confini interni fra le sue parti.

### Riepilogo

- Una **storia d'entità** si scrive nell'entità e usa i **nomi qualificati** `Csc.nome`.
- È il luogo in cui si scrive l'ordine fra ciò che accade su due confini diversi.
- Nomina soltanto i confini pubblici dell'entità.
- Come ogni storia, è un esempio: non è una riga contrattuale e non vieta ciò che non descrive.

### Casi particolari

**Confine interno.** Se la storia nomina `Comando.accendi`, un evento del confine fra le parti:

```
1. ERRORI: 1
  riga 23: [E20] Comando.accendi: LuceScale non offre né usa il connettore Comando; uno scenario può citare solo i connettori di LuceScale
```

**Elemento non dichiarato nella CSC.** Con `Luce.premuto` al posto di `Pressione.premuto`:

```
1. ERRORI: 1
  riga 23: [E03] nome non dichiarato come EVENT: Luce.premuto
```

**Nome senza la CSC.** Con `premuto` al posto di `Pressione.premuto`: un'entità non ha elementi propri, e il
nome non è dichiarato.

```
1. ERRORI: 1
  riga 23: [E03] nome non dichiarato come EVENT: premuto
```

**Valore non compreso nell'elenco di valori.** Con `Luce.modo = buia` il rapporto non segnala errori: nelle
storie d'entità `bcdd` non legge gli elenchi di valori delle CSC citate e non controlla i valori che sono nomi.
Controlla invece i valori letterali (numeri, stringhe, `true` e `false`) quando il tipo dell'elemento nella
CSC citata è un tipo di base. Il controllo di un valore che è un nome spetta a chi scrive.

**CSC citata non trovata.** Se il file `Luce.csc` manca, la citazione compare nella sezione 7 e i nomi
`Luce.…` delle storie non vengono controllati.

---

## Capitolo 19 — Una parte che può mancare

All'impianto si può aggiungere un sensore crepuscolare, che indica se all'esterno è buio: con il sensore, la
luce si accende solo quando è buio; senza, si accende sempre. Chi compone il sistema decide se montarlo,
e la scelta resta fissa per tutto il funzionamento. Il capitolo descrive come scrivere che l'entità deve funzionare in entrambi i casi.

### La parte facoltativa

Una **parte facoltativa** è una parte che chi compone il sistema può montare o non montare; la scelta resta
fissa per tutto il funzionamento.
Si scrive con il minimo 0 nella molteplicità: `crepuscolare : Crepuscolare [0 .. 1]` significa «senza
crepuscolare, oppure con un crepuscolare». In generale `[0 .. n]` significa «senza la parte, oppure con un
numero di copie da 1 a `n`».

Il sensore indica al pulsante se all'esterno è buio, con la CSC `Buio`:

```
-- Il sensore crepuscolare, visto dal pulsante.

CSC Buio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il sensore crepuscolare indica al pulsante se all'esterno è buio"

  STATE      buio : Boolean INITIAL true

  GUARANTEE b1: VERBAL "Lo stato buio diventa vero quando la luce esterna scende sotto i 20 lux e falso quando supera i 40 lux"
                VERIFY BY JUDGEMENT "una persona con un luxmetro accanto al sensore, al tramonto e all'alba"
END
```

```
-- Il sensore crepuscolare, una parte che può mancare.

ENTITY Crepuscolare VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il sensore crepuscolare misura la luce esterna e la indica al pulsante"

  OFFERS Buio
  USES   Alimentazione
END
```

Il pulsante usa ora `Buio` e passa alla versione 0.2:

```
-- Il pulsante delle scale, una delle parti della luce.
-- VERSION 0.2: tiene conto del sensore crepuscolare, se c'è. Da approvare.

ENTITY Pulsante VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante riceve la pressione e comanda la lampada"

  OFFERS Pressione
  OFFERS Comando
  USES   Buio

  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s, se è buio o se il sensore crepuscolare non c'è"
                 VERIFY BY INSPECTION "le pressioni, lo stato del sensore e i comandi registrati"
END
```

L'entità elenca il sensore come parte facoltativa:

```
-- La luce delle scale, con o senza il sensore crepuscolare.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante     : Pulsante
    lampada      : Lampada
    crepuscolare : Crepuscolare [0 .. 1]

  GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende, se è buio o se il sensore crepuscolare non c'è"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda, di giorno e di notte"
  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
END
```

### Le composizioni

Una **composizione** è ciascuna delle forme complete in cui si può montare un'entità. Con una parte
facoltativa le composizioni sono due: con la parte e senza. L'entità deve valere in ciascuna, e `bcdd` le
controlla separatamente.

Una promessa d'entità vale in ogni composizione. La promessa «quando qualcuno preme il pulsante, la luce si
accende» è violata con il sensore crepuscolare e di giorno. Per questo `ls1` è riscritta: «…se è buio o se il
sensore crepuscolare non c'è». `bcdd` non lo rileva, perché la promessa è scritta a parole.

Nella composizione senza il sensore nessuna parte offre `Buio` e nessuno ne mantiene le promesse. La promessa
`b1` non è violata, perché la CSC `Buio` non è offerta.

### Il rapporto

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 20 (riconosciute 15, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: pulsante : Pulsante in Pulsante.csc alla riga 4: VERSION 0.2, STATUS HYPOTHESIS, nessun errore
    riga 13: lampada : Lampada in Lampada.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 14: crepuscolare : Crepuscolare in Crepuscolare.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 2
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 16: GUARANTEE ls1 verbale
  riga 18: GUARANTEE ls2 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 2
  riga 16: GUARANTEE ls1
  riga 18: GUARANTEE ls2

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 5
  riga 12: pulsante usa Buio: la offre crepuscolare (riga 14) (in: con crepuscolare)
  riga 12: pulsante usa Buio: nessuno la offre (in: senza crepuscolare)
  riga 13: lampada usa Comando: la offre pulsante (riga 12)
  riga 13: lampada usa Alimentazione: la usa LuceScale da fuori (riga 9)
  riga 14: crepuscolare usa Alimentazione: la usa LuceScale da fuori (riga 9) (in: con crepuscolare)

9. COMPOSIZIONI: 2
  riga 3: ENTITY LuceScale: 2
    con crepuscolare
    senza crepuscolare

10. ASSENZE DICHIARATE: 1
  riga 12: senza crepuscolare: la parte pulsante usa il connettore Buio: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori

esito: nessun errore
```

Il rapporto ha due sezioni nuove.

La sezione 9, «composizioni», elenca le composizioni di ogni entità che ne ha più di una: qui `con
crepuscolare` e `senza crepuscolare`.

La sezione 10, «assenze dichiarate», elenca ciò che manca soltanto quando la parte facoltativa è assente.
Senza il sensore, il pulsante usa `Buio` e nessuna parte lo offre; con il sensore presente la mancanza non c'è.
Ciò che manca soltanto senza la parte non è un errore, ma un'**assenza dichiarata**. Compare nella sezione 10,
preceduto da `senza` e dal nome della parte, e non entra nel conteggio della riga `esito`.

Nella sezione 8 alcune voci terminano con `(in: …)`: il **suffisso** indica le composizioni in cui la voce
vale. `pulsante usa Buio: la offre crepuscolare (riga 14) (in: con crepuscolare)` vale soltanto quando il
sensore c'è. Una voce senza suffisso vale in tutte le composizioni. Lo stesso suffisso accompagna gli errori.

Le sezioni 9 e 10 compaiono soltanto se nel file c'è un'entità con più di una composizione.

### Che cosa non è una parte facoltativa

Una parte facoltativa c'è o non c'è per tutto il funzionamento dell'impianto. Non descrive una parte che
compare e scompare mentre l'impianto funziona, per esempio un sensore che si scollega di giorno e si
ricollega di notte, né una parte che opera soltanto in certi modi di funzionamento: il linguaggio non prevede
una forma per questi casi.

### Riepilogo

- Una **parte facoltativa** si scrive con la molteplicità `[0 .. n]`: l'entità ha due **composizioni**, con la
  parte e senza, ciascuna fissa per tutto il funzionamento.
- Le promesse d'entità valgono in ogni composizione.
- `bcdd` controlla ogni composizione; ciò che manca soltanto senza la parte è un'**assenza dichiarata**,
  elencata nella sezione 10 e non contata fra gli errori.
- Il **suffisso** `(in: …)` indica le composizioni in cui vale una voce o un errore.

### Casi particolari

**Errore in una sola composizione.** Se l'entità contiene il pulsante della versione 0.1, che non usa `Buio`,
nella composizione con il sensore nessuna parte usa ciò che il sensore offre:

```
1. ERRORI: 1
  riga 14: [E17] la parte crepuscolare offre il connettore Buio: nessun'altra parte di LuceScale lo usa, né LuceScale lo offre da fuori (in: con crepuscolare)
```

L'errore vale soltanto nella composizione con il sensore, come indica il suffisso.

**Parte facoltativa senza la riga `OFFERS` necessaria.** Se il sensore non dichiara `OFFERS Buio`, nessuna
parte offre `Buio` al pulsante, nemmeno quando il sensore c'è:

```
1. ERRORI: 1
  riga 12: [E14] la parte pulsante usa il connettore Buio: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori
…
8. USI DENTRO LE ENTITÀ: 4
  riga 12: pulsante usa Buio: nessuno la offre
…
10. ASSENZE DICHIARATE: 0
```

L'errore compare in entrambe le composizioni, quindi senza suffisso. Non è un'assenza dichiarata, perché
l'errore non scompare nemmeno quando la parte è presente: l'assenza dichiarata riguarda soltanto ciò che si
spiega con la mancanza della parte.

**Nessuna copia.** La molteplicità `[0 .. 0]` è un errore, perché descrive una parte che non c'è mai:

```
1. ERRORI: 1
  riga 14: [E19] la parte crepuscolare ha un numero di copie non valido: [0 .. 0]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo
```

---

## Capitolo 20 — Più forme della stessa cosa: le varianti

La luce delle scale si installa in quattro forme: la lampada può essere una plafoniera sul soffitto o
un'applique sulla parete, e il comando può essere un pulsante o un sensore di presenza. Il capitolo descrive
come scrivere queste forme in un'unica entità.

### Le varianti

Una **variante** è una delle alternative di un aspetto dell'entità, per esempio la lampada. Si dichiara
con la riga `VARIANT gruppo = scelta`: il nome a sinistra del segno `=` è il **nome del gruppo**, quello a
destra la **scelta**. `VARIANT lampada = soffitto` dichiara la variante in cui la lampada è la plafoniera. Le righe che
seguono, fino al `VARIANT` successivo o a `END`, formano il **segmento** della variante e valgono soltanto
con quella scelta. Le righe che precedono il primo `VARIANT` sono le **righe comuni** e valgono in ogni
composizione.

Le varianti che hanno lo stesso nome del gruppo formano un **gruppo** (o **gruppo di scelte**): fra le scelte di
un gruppo ne vale una sola. Gruppi diversi sono indipendenti e si combinano fra loro. Con il gruppo `lampada`
(soffitto o parete) e il gruppo `comando` (pulsante o presenza) le composizioni sono quattro.

In un segmento si scrivono soltanto righe dell'entità: `OFFERS`, `USES`, `COMPOSED OF` con le sue parti,
promesse d'entità e storie d'entità. Lo scopo, `PURPOSE`, si scrive fra le righe comuni.

### I file

Il sensore di presenza offre a chi sta sulle scale un confine diverso dalla pressione:

```
-- Il sensore di presenza, visto da chi sta sulle scale.

CSC Presenza VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi entra sulle scale viene rilevato dal sensore di presenza senza premere nulla"

  EVENT IN   passaggio

  GUARANTEE pz1: VERBAL "Una persona che cammina a meno di 4 m dal sensore è rilevata come passaggio"
                 VERIFY BY JUDGEMENT "una persona che cammina a distanze diverse dal sensore"
END
```

```
-- Il sensore di presenza, una delle due forme del comando.

ENTITY SensorePresenza VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il sensore rileva chi passa e comanda la lampada"

  OFFERS Presenza
  OFFERS Comando
  USES   Alimentazione

  GUARANTEE sp1: VERBAL "A ogni passaggio segue un accendi entro 0,2 s"
                 VERIFY BY INSPECTION "i passaggi e i comandi registrati"
END
```

La plafoniera e l'applique offrono lo stesso confine, ma con promesse diverse:

```
-- La plafoniera, una delle due forme della lampada.

ENTITY Plafoniera VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La plafoniera sul soffitto si accende al comando e si spegne da sola"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE pl1: VERBAL "Dopo un accendi la luce è piena entro 0,5 s"
                 VERIFY BY JUDGEMENT "una persona che osserva la plafoniera mentre si invia il comando"
  GUARANTEE pl2: VERBAL "La luce si spegne 90 s dopo l'ultimo accendi, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"
END
```

```
-- L'applique, una delle due forme della lampada.

ENTITY Applique VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'applique sulla parete si accende al comando e si spegne da sola"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE ap1: VERBAL "Dopo un accendi la luce è piena entro 0,05 s"
                 VERIFY BY JUDGEMENT "una persona che osserva l'applique mentre si invia il comando"
  GUARANTEE ap2: VERBAL "La luce si spegne 90 s dopo l'ultimo accendi, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"
END
```

Un'unica entità descrive le quattro forme:

```
-- La luce delle scale: plafoniera o applique, pulsante o sensore di presenza.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale ha luce per salire o scendere"

  OFFERS Luce
  USES   Alimentazione

  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultimo comando, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"

  VARIANT lampada = soffitto
    COMPOSED OF
      lampada : Plafoniera
  VARIANT lampada = parete
    COMPOSED OF
      lampada : Applique

  VARIANT comando = pulsante
    OFFERS Pressione
    COMPOSED OF
      pulsante : Pulsante
    GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                   VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  VARIANT comando = presenza
    OFFERS Presenza
    COMPOSED OF
      presenza : SensorePresenza
    GUARANTEE ls1p: VERBAL "Quando qualcuno passa davanti al sensore, la luce si accende"
                    VERIFY BY JUDGEMENT "una persona che entra sulle scale e guarda"
END
```

La scelta del comando cambia ciò che l'entità offre a chi sta sulle scale, `Pressione` oppure `Presenza`: per
questo la riga `OFFERS` si scrive dentro il segmento. Il nome della parte `lampada` compare in due scelte dello stesso
gruppo: è lo stesso ruolo, svolto da entità diverse. I nomi brevi delle promesse e delle storie, invece, sono
unici in tutta l'entità: `ls1` e `ls1p` hanno nomi diversi.

### Chi sceglie

Nessuna riga dell'entità indica quale composizione si realizza: l'entità descrive tutte le composizioni
ammesse; chi compone il sistema ne realizza una. La decisione si prende quando si compone il sistema e non
cambia mentre il sistema funziona. Nessuna riga indica chi decide, quando o perché; fra le scelte non c'è
preferenza né ordine, e nessuna è predefinita. Una condizione come «applique se c'è una presa a muro,
altrimenti plafoniera» è una regola di decisione e non si scrive con le varianti; se serve, si scrive a parole
in una promessa.

### Il rapporto

```
$ bcdd check --strict LuceScale.csc
bcdd check --strict LuceScale.csc
righe: 32 (riconosciute 26, commenti 1, vuote 5, non riconosciute 0)
blocchi: 1
  riga 3: ENTITY LuceScale VERSION 0.1, STATUS HYPOTHESIS
    riga 7: OFFERS Luce in Luce.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 8: USES Alimentazione in Alimentazione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 15: lampada : Plafoniera in Plafoniera.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 18: lampada : Applique in Applique.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 21: OFFERS Pressione in Pressione.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 23: pulsante : Pulsante in Pulsante.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 27: OFFERS Presenza in Presenza.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 29: presenza : SensorePresenza in SensorePresenza.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 3
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 10: GUARANTEE ls2 verbale
  riga 24: GUARANTEE ls1 verbale
  riga 30: GUARANTEE ls1p verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 3
  riga 10: GUARANTEE ls2
  riga 24: GUARANTEE ls1
  riga 30: GUARANTEE ls1p

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 7
  riga 15: lampada usa Comando: la offre pulsante (riga 23) (in: lampada = soffitto, comando = pulsante)
  riga 15: lampada usa Comando: la offre presenza (riga 29) (in: lampada = soffitto, comando = presenza)
  riga 15: lampada usa Alimentazione: la usa LuceScale da fuori (riga 8) (in: lampada = soffitto)
  riga 18: lampada usa Comando: la offre pulsante (riga 23) (in: lampada = parete, comando = pulsante)
  riga 18: lampada usa Comando: la offre presenza (riga 29) (in: lampada = parete, comando = presenza)
  riga 18: lampada usa Alimentazione: la usa LuceScale da fuori (riga 8) (in: lampada = parete)
  riga 29: presenza usa Alimentazione: la usa LuceScale da fuori (riga 8) (in: comando = presenza)

9. COMPOSIZIONI: 4
  riga 3: ENTITY LuceScale: 4
    lampada = soffitto, comando = pulsante
    lampada = soffitto, comando = presenza
    lampada = parete, comando = pulsante
    lampada = parete, comando = presenza

10. ASSENZE DICHIARATE: 0

esito: nessun errore
```

La sezione 9 elenca le quattro composizioni. Il nome di una composizione è la sequenza delle sue scelte,
nell'ordine in cui i gruppi compaiono nel file. Le voci della sezione 8 hanno il suffisso descritto nel capitolo 19:
`lampada usa Alimentazione: la usa LuceScale da fuori (riga 8) (in: lampada = soffitto)` vale in entrambe le
composizioni con la plafoniera.

### Una parte con varianti

Se un'entità che ha varianti è a sua volta parte di un'altra entità, le sue scelte compaiono nelle
composizioni dell'entità che la contiene. Nell'entità `Condominio`, che contiene `scale : LuceScale`, le
composizioni sono quattro, e i loro nomi sono preceduti dal nome della parte:

```
9. COMPOSIZIONI: 4
  riga 3: ENTITY Condominio: 4
    scale.lampada = soffitto, scale.comando = pulsante
    scale.lampada = soffitto, scale.comando = presenza
    scale.lampada = parete, scale.comando = pulsante
    scale.lampada = parete, scale.comando = presenza
```

L'entità che contiene la parte deve valere in ogni composizione della parte. Se `Condominio` offre soltanto
`Luce`, i confini `Pressione` e `Presenza` offerti dalla luce delle scale non sono usati da nessuna parte:

```
1. ERRORI: 2
  riga 11: [E17] la parte scale offre il connettore Pressione: nessun'altra parte di Condominio lo usa, né Condominio lo offre da fuori (in: scale.comando = pulsante)
  riga 11: [E17] la parte scale offre il connettore Presenza: nessun'altra parte di Condominio lo usa, né Condominio lo offre da fuori (in: scale.comando = presenza)
```

Dall'entità che contiene la parte non si può fissare una sola scelta della parte: il linguaggio non prevede
una forma per farlo.

Nelle composizioni dell'entità che contiene una parte entrano soltanto i gruppi di scelte della parte, non le
sue parti facoltative. Dall'esterno una parte conta per ciò che offre e usa, e una sua parte facoltativa non
lo cambia: un `Condominio` che contiene la luce delle
scale del capitolo 19, con il sensore crepuscolare facoltativo, ha una sola composizione, e il suo rapporto
non ha le sezioni 9 e 10.

### Il limite delle composizioni

Le composizioni si moltiplicano: ogni gruppo di due scelte e ogni parte facoltativa ne raddoppiano il numero. `bcdd`
controlla al più 64 composizioni per entità. Oltre questo numero non controlla la chiusura dell'entità e
segnala un errore; per esempio, con sette gruppi di due scelte ciascuno:

```
1. ERRORI: 1
  riga 1: [E23] l'entità Troppe ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole
…
9. COMPOSIZIONI: 0
  riga 1: ENTITY Troppe: più di 64, non controllate
```

### Riepilogo

- Una **variante** (`VARIANT gruppo = scelta`) apre un **segmento** di righe che valgono solo con quella scelta;
  le **righe comuni** precedono il primo `VARIANT` e valgono sempre.
- Le scelte dello stesso **gruppo** si escludono a vicenda; gruppi diversi si combinano, e ogni combinazione è una
  composizione.
- Nessuna riga indica chi sceglie; la scelta non cambia mentre il sistema funziona.
- Le scelte di una parte compaiono nelle composizioni dell'entità che la contiene; le sue parti facoltative no.
- `bcdd` controlla ogni composizione, fino a 64, e le elenca nella sezione 9.

### Casi particolari

**Scelta incompleta.** Se il sensore di presenza non dichiara `OFFERS Comando`, nelle composizioni con il
sensore nessuna parte offre il comando alla lampada:

```
1. ERRORI: 2
  riga 15: [E14] la parte lampada usa il connettore Comando: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori (in: lampada = soffitto, comando = presenza)
  riga 18: [E14] la parte lampada usa il connettore Comando: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori (in: lampada = parete, comando = presenza)
```

L'errore compare due volte, una per ciascuna lampada, e ciascuna volta in una sola composizione. Non è
un'assenza dichiarata: nell'entità non c'è una parte facoltativa che lo spieghi.

**Gruppo con una sola scelta.** Se il gruppo `lampada` ha soltanto la scelta `soffitto`:

```
1. ERRORI: 1
  riga 13: [E22] il gruppo di scelte lampada ha una sola scelta (soffitto): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]
```

Un gruppo ha almeno due scelte. Una parte che
può esserci oppure no si scrive come parte facoltativa (capitolo 19), non con una variante priva di righe.

**Scopo in un segmento.** Un `PURPOSE` scritto subito dopo `VARIANT lampada = parete`:

```
1. ERRORI: 1
  riga 17: [E21] PURPOSE non può stare in un segmento VARIANT: scrivilo prima del primo VARIANT
```

**Variante in una CSC.** Le varianti si scrivono soltanto nelle entità. Una riga `VARIANT` nella CSC `Luce`:

```
1. ERRORI: 1
  riga 11: [E21] VARIANT non può stare in una CSC: le varianti si scrivono in un'entità
```

**Storia comune che nomina un confine di una sola scelta.** Una storia fra le righe comuni vale in tutte le
composizioni. Se nomina `Pressione.premuto`, nelle composizioni con il sensore di presenza il confine
`Pressione` non c'è:

```
1. ERRORI: 1
  riga 13: [E20] Pressione.premuto: LuceScale non offre né usa il connettore Pressione; uno scenario può citare solo i connettori di LuceScale (in: comando = presenza)
```

La storia si sposta nel segmento `comando = pulsante`, dove vale soltanto con il pulsante.

---

## Capitolo 21 — Il passo e le prime formule

Le promesse della CSC della luce sono scritte a parole: si controllano con un giudizio. Una promessa scritta
come formula ha invece un significato che un programma può controllare. Il capitolo introduce il passo, cioè
l'unità con cui una formula osserva il sistema. Introduce poi le prime parole chiave delle formule e gli operatori
con cui si combinano le condizioni.

`bcdd` riconosce le formule di questo capitolo e dei due capitoli successivi: ne controlla la forma, i nomi e i
tipi, e ne riporta il grado. Non le valuta sulle storie: il capitolo 24 descrive che cosa resta da controllare.

### Il passo

Un **passo** è l'unità di osservazione del sistema: un istante, con l'insieme degli eventi che vi accadono e il
valore degli stati subito dopo quegli eventi. Ogni istante di una storia (capitolo 9), cioè ogni riga che
comincia con `@`, è un passo, e la traccia di una storia è una sequenza di passi. Un passo rispetta tre
regole:

1. l'istante di un passo non precede quello del passo precedente; due passi successivi possono avere lo
   stesso istante, come i due istanti `@0 s` della storia `s4`;
2. in un passo lo stesso evento compare al più una volta;
3. il valore di uno stato in un passo è quello che lo stato assume dopo gli eventi del passo.

Nella storia `s1` il primo passo è `@0 s premuto modo = accesa`: l'evento `premuto` accade all'istante 0 e,
dopo la pressione, il modo è `accesa`.

Il passo è un modello dell'osservazione, non una descrizione della realizzazione: non implica che la
realizzazione esegua tutto nello stesso istante.

### La formula

Una **formula** è una promessa scritta in una forma che un programma può controllare passo per passo.
Si scrive dopo i due punti della riga, al posto di `VERBAL` e `VERIFY`:

```
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

Una formula non ha la riga `VERIFY`: il modo di controllarla è stabilito dal linguaggio, non da chi scrive
la CSC.

All'interno di una formula compaiono **condizioni sul passo**, cioè espressioni che in ogni passo sono vere o
false. Quando una condizione è vera in un passo si dice che **vale** in quel passo; per un evento si dice
invece che **accade**.

| Condizione | Vale nel passo in cui |
|---|---|
| `premuto` | accade l'evento `premuto` |
| `modo = accesa` | lo stato `modo` vale `accesa` |
| `modo <> spenta` | lo stato `modo` ha un valore diverso da `spenta` |
| `modo IN {accesa, in_pulizia}` | lo stato `modo` vale `accesa` oppure `in_pulizia` |
| `NOT p` | `p` non vale |
| `p AND q` | `p` e `q` valgono entrambe |
| `p OR q` | vale almeno una fra `p` e `q` |
| `p IMPLIES q` | `p` non vale, oppure vale `q` |

Nelle forme di questo capitolo e dei due successivi le lettere minuscole `p`, `q` e `c` indicano condizioni
sul passo e la maiuscola `P` una formula; dal capitolo 22 `e` indica un evento, `x` uno stato, `X` una
richiesta e `d` una durata.

Le fasi del ciclo di vita di una richiesta (capitolo 5) sono anch'esse condizioni: `requested(Pulizie)` vale
nel passo in cui la richiesta `Pulizie` raggiunge la fase `requested`.

Una formula contiene soltanto elementi dichiarati nella CSC (eventi, stati, valori degli elenchi di valori,
richieste, costanti con nome), numeri e durate.

### Gli operatori e la precedenza

Oltre agli operatori logici, una condizione usa gli operatori di confronto e di calcolo:

| Operatore | Significato |
|---|---|
| `=`, `<>` | uguale, diverso |
| `<`, `<=`, `>`, `>=` | minore, minore o uguale, maggiore, maggiore o uguale; fra numeri o fra durate |
| `+`, `-`, `*`, `/` | somma, differenza, prodotto, quoziente |
| `^` | potenza |
| `- x` | l'opposto di `x` |
| `x IN {v1, v2, …}` | `x` vale uno dei valori elencati |
| `(IF c THEN x ELSE y)` | `x` nei passi in cui vale `c`, `y` negli altri; si scrive sempre fra parentesi |

Le funzioni matematiche `ABS`, `MIN`, `MAX`, `LOG10`, `ROUND`, `FLOOR` e `CEIL` hanno il significato matematico
consueto. Il meno fra due valori si scrive separato da spazi da entrambi: `a - b`. Scritto senza spazi, `a-b` è un
unico nome, perché un nome può contenere il trattino fra due lettere.

Senza parentesi gli operatori si applicano secondo questa precedenza, dalla più alta alla più bassa:

| Precedenza | Operatori | Operatori uguali consecutivi |
|---|---|---|
| 1 | `x[i]`, `x.campo` (capitolo 23) | associativi a sinistra |
| 2 | `^` | non ammessi: `a ^ b ^ c` è un errore |
| 3 | `-` davanti a un valore | associativo a destra |
| 4 | `*`, `/` | associativi a sinistra |
| 5 | `+`, `-` | associativi a sinistra |
| 6 | `=`, `<>`, `<`, `<=`, `>`, `>=`, `IN` | non ammessi: `a <= b <= c` è un errore |
| 7 | `NOT` | associativo a destra |
| 8 | `AND`, `OR` | lo stesso operatore si ripete liberamente; `AND` e `OR` mescolati sono un errore |
| 9 | `IMPLIES` | non ammessi: `a IMPLIES b IMPLIES c` è un errore |

Così `NOT a AND b` è `(NOT a) AND b`, `a AND b IMPLIES c` è `(a AND b) IMPLIES c` e `x + y * 2` è `x + (y * 2)`.
Per le combinazioni che la tabella esclude `bcdd` segnala l'errore **E26**; il messaggio indica come scriverle
con le parentesi. `a AND b OR c` si scrive `(a AND b) OR c` oppure `a AND (b OR c)`, a seconda del significato
voluto. Gli esempi del manuale usano le parentesi ogni volta che una condizione combina più di due condizioni.

### Le prime parole chiave delle formule

Una formula si costruisce con quattro parole chiave, che stabiliscono in quali passi deve valere una
condizione. Una quinta, `AT ONCE`, precisa il passo della conseguenza di `WHENEVER`.

**«Sempre»: `ALWAYS p`.** In ogni passo vale `p`. `ALWAYS modo <> in_pulizia` indica che la luce non entra
mai nel modo delle pulizie.

**«Prima o poi»: `EVENTUALLY p`.** In almeno un passo vale `p`. `EVENTUALLY avviso` indica che in qualche
passo accade un avviso. Scritta come promessa a sé, richiederebbe un avviso in ogni traccia. La luce, però, emette
un avviso soltanto dopo una pressione e non è tenuta a emetterne uno se nessuno preme.

**«Ogni volta che… allora»: `WHENEVER p THEN q`.** In ogni passo in cui vale `p`, la condizione `q` deve valere
nello stesso passo o in un passo successivo. La condizione `p` è l'**innesco**, la condizione `q` è la
**conseguenza**. Con `AT ONCE` la conseguenza deve valere **nello stesso passo** dell'innesco, e non dopo:
`WHENEVER p THEN q AT ONCE`.

**«Mentre»: `WHILE c: P`.** La formula `P` deve valere nei passi in cui vale la condizione `c`, detta
**ambito**; gli altri passi non sono considerati. `WHILE modo = spenta: ALWAYS NOT avviso` indica che in nessun passo in cui la
luce è spenta accade un avviso. Una formula senza `WHILE` riguarda tutti i passi della traccia.

Queste parole chiave non si annidano: dopo `ALWAYS`, `EVENTUALLY`, `WHENEVER` e `THEN` si scrive una condizione
sul passo, non un'altra formula. Una formula ha al più un ambito, scritto all'inizio. Per una parola chiave
annidata o per un secondo ambito `bcdd` segnala l'errore **E27**.

### Una formula su più righe

Una formula lunga si può dividere su più righe. Una riga continua sulla riga successiva quando è rimasta
**aperta**: ha una parentesi non chiusa, oppure finisce con un operatore o una parola chiave che richiede un
seguito, come `THEN`, `AND`, `OR`, `IMPLIES`, `WITHIN`, una virgola, un operatore di confronto o di calcolo. Per
esempio:

```
  GUARANTEE g1: WHENEVER premuto THEN
                  modo <> spenta AT ONCE
```

Le due righe sono una sola dichiarazione. Una riga che comincia con una parola chiave che apre una
dichiarazione (`GUARANTEE`, `SCENARIO`, `END`, …) o con `@` non continua mai la precedente: una parentesi
dimenticata non incorpora nella dichiarazione la riga `END` del blocco.

### La CSC della luce con le prime formule

La promessa `g1`, «quando qualcuno preme il pulsante, la luce si accende», diventa:

```
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

Si legge: ogni volta che accade `premuto`, nello stesso passo il modo è diverso da `spenta`. La conseguenza
non è `modo = accesa`: durante le pulizie una pressione lascia il modo `in_pulizia` (promessa `g7`), e la
luce è comunque accesa. La stessa conseguenza si scrive anche `modo IN {accesa, in_pulizia}`.

La promessa `g2`, «la luce si spegne da sola dopo un po'», diventa:

```
  GUARANTEE g2: WHENEVER modo = accesa THEN modo = spenta
```

In ogni passo in cui la luce è accesa, in un passo successivo la luce deve essere spenta. Il tempo resta indeterminato,
come nel testo a parole; il limite di tempo è nel dettaglio `g2a` (capitolo 22).

Si aggiunge inoltre una promessa nuova, `g8`, che usa `WHILE`:

```
  GUARANTEE g8: WHILE modo = spenta: ALWAYS NOT avviso
```

Una promessa scritta come formula **cambia forma, ma conserva il proprio nome**: `g1` resta `g1`, e i
dettagli `g2a` e `g2b` restano dettagli di `g2`. Il cambiamento di forma modifica il testo della CSC
approvata, quindi richiede una versione nuova (capitolo 10): la 0.3, da approvare. Il testo a parole si può
conservare in un commento sopra la formula. Le righe 1-2 e 15-18 della versione 0.3 sono:

```
-- La luce delle scale, vista da chi sta sulle scale e dal custode.
-- VERSION 0.3: g1 e g2 scritte come formule; aggiunta g8. Da approvare.
```

```
  -- g1: «Quando qualcuno preme il pulsante, la luce si accende»
  GUARANTEE g1: WHENEVER premuto THEN modo <> spenta AT ONCE
  -- g2: «La luce si spegne da sola dopo un po'»
  GUARANTEE g2: WHENEVER modo = accesa THEN modo = spenta
```

La riga di `g8` è la 33, subito prima del presupposto `a1`.

### Il grado delle formule e il rapporto

Il **grado** di una promessa (capitolo 2) si ricava dalla forma della riga: nessuna riga lo dichiara. Una
promessa scritta come formula, che `bcdd` riconosce per intero, ha grado **formale**:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
righe: 50 (riconosciute 41, commenti 4, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 8
  formale: 3
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 16: GUARANTEE g1 formale
  riga 18: GUARANTEE g2 formale
  riga 19: GUARANTEE g2a verbale
  riga 21: GUARANTEE g2b verbale
  riga 23: GUARANTEE g3 verbale
  riga 25: GUARANTEE g4 verbale
  riga 27: GUARANTEE g5 verbale
  riga 29: GUARANTEE g6 verbale
  riga 31: GUARANTEE g7 verbale
  riga 33: GUARANTEE g8 formale
  riga 34: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 9
  riga 16: GUARANTEE g1
  riga 18: GUARANTEE g2
  riga 23: GUARANTEE g3
  riga 25: GUARANTEE g4
  riga 27: GUARANTEE g5
  riga 29: GUARANTEE g6
  riga 31: GUARANTEE g7
  riga 33: GUARANTEE g8
  riga 34: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

14. DA GIUDICARE: 2
  riga 19: GUARANTEE g2a DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 21: GUARANTEE g2b DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole

15. CONTROLLI NON ESEGUITI: 3
  storie: righe 37, 42, 45, 47
  copertura degli inneschi: righe 16, 18, 33
  coerenza di presupposti e promesse: righe 16, 18, 33

esito: nessun errore
```

Le tre formule hanno grado formale. Nella sezione 4 compaiono come righe da approvare, perché la versione 0.3 è
da approvare; i dettagli `g2a` e `g2b` hanno invece un proprio `STATUS RATIFIED BY D-12`.

La sezione 14, «da giudicare» (capitolo 8), elenca i due dettagli: sono scritti a parole e precisano una
formula, e la loro coerenza con `g2` va giudicata da una persona.

La sezione 15, «controlli non eseguiti», elenca i controlli sulle formule che `bcdd` non esegue, con le righe a
cui si applicherebbero:

- **storie**: se le storie hanno effettivamente l'esito che dichiarano con `EXPECT`; la voce elenca le storie
  di un blocco che contiene almeno una formula;
- **copertura degli inneschi**: se l'innesco di ogni promessa formale avviene in almeno una storia;
- **coerenza di presupposti e promesse**: se le promesse e i presupposti formali possono valere insieme.

Una riga della sezione 15 non è né rispettata né violata: il controllo non è stato eseguito. Il rapporto lo
riporta perché nessuna formula risulti sottoposta a controlli che non sono stati eseguiti. Il capitolo 24 descrive questi controlli.
La sezione compare soltanto quando ha almeno una voce.

### Riepilogo

- Un **passo** è un istante, con gli eventi che vi accadono e il valore degli stati subito dopo; due passi
  successivi possono avere lo stesso istante, e ogni istante di una storia è un passo.
- Una **formula** è una promessa che un programma può controllare passo per passo; non ha `VERIFY`.
- Le prime parole chiave delle formule sono `ALWAYS` (sempre), `EVENTUALLY` (prima o poi), `WHENEVER … THEN`
  (ogni volta che… allora) e `WHILE` (mentre); `AT ONCE` (nello stesso passo) precisa la conseguenza di
  `WHENEVER`. Le condizioni si combinano con `NOT`, `AND`, `OR`, `IMPLIES`, con gli operatori di confronto e di
  calcolo, con `IN {…}` e con `(IF … THEN … ELSE …)`.
- `AND` e `OR` mescolati richiedono le parentesi; lo stesso vale per due confronti, due `IMPLIES` o due `^`
  consecutivi (E26). Le parole chiave delle formule non si annidano (E27).
- Una formula si divide su più righe lasciando aperta la riga che continua.
- Una promessa scritta come formula conserva il proprio nome; il cambiamento di forma richiede una versione
  nuova.
- Il grado di una formula è **formale**. `bcdd` ne controlla forma, nomi e tipi, e riporta nella sezione 15 i
  controlli che non esegue.

### Casi particolari

**Una riga che comincia con `THEN`.** Se `g1` va a capo prima di `THEN`, la prima riga non richiede un seguito, e
la riga che comincia con `THEN` è una dichiarazione a sé. Nessuna delle due righe è riconosciuta, e `g1` ha grado
«non riconosciuta»:

```
5. RIGHE NON RICONOSCIUTE: 2
  riga 16: GUARANTEE g1: WHENEVER premuto
  riga 17: THEN modo <> spenta AT ONCE
…
esito: nessun errore; righe non riconosciute: 2 (vedi sezione 5)
```

La riga va interrotta dopo `THEN`, come nell'esempio della sezione «Una formula su più righe».

**Nome non dichiarato in una formula.** Con `premuta` al posto di `premuto`, `bcdd` segnala l'errore **E24**, nome
non dichiarato:

```
1. ERRORI: 1
  riga 16: [E24] nome non dichiarato: premuta
```

La riga resta riconosciuta e formale: la forma è corretta, il nome no. Ogni posizione di una formula richiede un
elemento di un certo genere (un evento, uno stato, una richiesta, un valore). Anche per un nome di un genere
diverso `bcdd` segnala l'errore E24.

**`AND` e `OR` senza parentesi.** La conseguenza `modo = accesa OR modo = in_pulizia AND NOT avviso` contiene `AND`
e `OR` senza parentesi:

```
1. ERRORI: 1
  riga 16: [E26] AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)
```

**Una formula dentro un'altra.** `ALWAYS (modo = spenta IMPLIES ALWAYS NOT avviso)` contiene una formula al posto
di una condizione:

```
1. ERRORI: 1
  riga 33: [E27] ALWAYS dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni
```

La forma corretta è quella di `g8`, con l'ambito `WHILE`.

**Approvazione di una CSC con formule.** Il file supera `bcdd check --strict`, e `bcdd ratify` ne registra
l'approvazione come per una CSC che contiene soltanto promesse a parole. Su una copia della versione 0.3:

```
$ bcdd ratify UsoLuce.csc --all D-15
approvate con D-15 nella CSC UsoLuce: 1 riga
  riga 5: CSC UsoLuce
contratto: 11
```

Nel capitolo la versione 0.3 resta da approvare, perché i capitoli 22 e 23 vi aggiungono altre formule.

**La formula come dettaglio.** In alternativa alla sostituzione, la promessa a parole resta e la formula si
aggiunge come suo dettaglio (capitolo 8):

```
  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g1a DETAILS g1: WHENEVER premuto THEN modo <> spenta AT ONCE
```

Le due forme sono ammesse. Con il dettaglio il contratto contiene entrambe le righe, e il dettaglio è da
approvare. Nel rapporto `g1a` è formale, e la sezione 14 elenca la sua coerenza con `g1` fra le righe da
giudicare:

```
14. DA GIUDICARE: 3
  riga 17: GUARANTEE g1a DETAILS g1: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 20: GUARANTEE g2a DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 22: GUARANTEE g2b DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
```

**Formula in un'entità.** Una promessa d'entità si può scrivere come formula. Gli elementi si nominano con il
nome qualificato `Csc.elemento`, come nelle storie d'entità (capitolo 18). Per esempio, nell'entità `LuceScale`
la promessa seguente

```
  GUARANTEE ls1: WHENEVER Pressione.premuto THEN Luce.modo <> spenta WITHIN 1 s
```

ha grado formale:

```
2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 2
  formale: 1
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 15: GUARANTEE ls1 formale
  riga 16: GUARANTEE ls2 verbale
  riga 18: GUARANTEE ls3 verbale
```

`Pressione` e `Luce` devono essere CSC che l'entità offre o usa (in caso contrario: errore E20), e l'elemento
deve essere dichiarato in quella CSC (in caso contrario: errore E24). Anche per un nome semplice, senza la CSC
davanti, `bcdd` segnala l'errore E24. In questa versione `bcdd` non controlla il tipo degli elementi nelle formule
d'entità, ma soltanto il nome e il genere.

---

## Capitolo 22 — Il tempo nelle formule

Il dettaglio `g2a` indica che la luce si spegne 90 secondi dopo l'ultima pressione, con 5 secondi di
tolleranza. Le parole chiave del capitolo 21 non bastano a esprimerlo: stabiliscono in quali passi vale una
condizione, ma non misurano il tempo che passa fra due passi. Il capitolo introduce il limite di tempo, che
misura il tempo da un passo in avanti. Introduce poi le forme che riguardano ciò che è già accaduto nella
traccia: il tempo trascorso, il conteggio e il valore precedente. Introduce infine le storie che si ripetono.

### Entro un certo tempo: WITHIN

Il **limite di tempo** si scrive con `WITHIN` seguito da una durata, e si aggiunge a `EVENTUALLY` o a
`WHENEVER`:

| Forma | Significato |
|---|---|
| `EVENTUALLY p WITHIN d` | `p` vale in qualche passo entro `d` dall'inizio dell'ambito |
| `WHENEVER p THEN q WITHIN d` | in ogni passo in cui vale `p`, `q` deve valere entro `d` dal passo dell'innesco, compreso il passo stesso |

La durata ha sempre un'unità, `s` o `ms`. Con `WITHIN` la promessa ha un termine: se la conseguenza non vale
entro la durata, la promessa è violata. `WITHIN` e `AT ONCE` non possono comparire nella stessa promessa (errore
E27).

Per una formula senza `WHILE` l'inizio dell'ambito è il primo passo della traccia. Con `WHILE` l'ambito può
comprendere più tratti separati della traccia: ogni tratto è un ambito a sé, e la durata decorre dall'inizio di
ciascun tratto. `WHILE modo = in_pulizia: EVENTUALLY avviso WITHIN 5 s` richiede quindi un avviso in ogni tratto
di pulizie, entro 5 s dal suo inizio. Un tratto che termina senza avviso prima che siano trascorsi 5 s viola la
promessa.

Nella CSC della luce si aggiunge un dettaglio della promessa `g4`: una richiesta di pulizie ha una risposta
entro un secondo.

```
  GUARANTEE g4a DETAILS g4: WHENEVER requested(Pulizie) THEN accepted(Pulizie) OR rejected(Pulizie) WITHIN 1 s
```

### Il tempo trascorso: TIME SINCE

`TIME SINCE e` misura il **tempo trascorso** dall'ultimo passo in cui è accaduto l'evento `e`.
`TIME SINCE premuto <= 95 s` vale nei passi in cui l'ultima pressione risale a non più di 95 secondi prima.

Nel passo stesso in cui `e` accade, `TIME SINCE e` vale 0. Prima che `e` sia accaduto almeno una volta il
suo valore è infinito: `TIME SINCE premuto > 90 s` è vera anche se nessuno ha mai premuto, e
`TIME SINCE premuto <= 95 s` è falsa. L'infinito si usa soltanto nei confronti, non nei calcoli. Per escludere
il caso in cui l'evento non è mai accaduto, una condizione come `TIME SINCE premuto >= 85 s` si combina con il
conteggio `COUNT(premuto) > 0`, che vale soltanto se l'evento è già accaduto.

### Il conteggio: COUNT

Il **conteggio** `COUNT(e)` è il numero di passi in cui l'evento `e` è accaduto, dall'inizio della traccia
fino al passo considerato compreso. `COUNT(premuto) > 0` vale dal passo della prima pressione in poi.

`COUNT(e SINCE f)` conta soltanto i passi con `e` successivi all'ultimo passo in cui è accaduto l'evento `f`.
`COUNT(premuto SINCE avviso) = 0` vale nei passi in cui nessuno ha premuto dopo l'ultimo avviso.

`COUNT(e) IN LAST d` conta soltanto i passi in cui `e` è accaduto nell'intervallo di durata `d` che termina con
il passo considerato. Il passo considerato è compreso; il passo che dista esattamente `d` non lo è. Nella CSC
`Comando` del capitolo 13 il pulsante offre il comando `accendi`. La sua promessa `c1` stabilisce che fra due
comandi passano almeno 0,2 secondi. Scritta come formula, la promessa stabilisce che in ogni intervallo di 0,2
secondi non è emesso più di un comando:

```
  GUARANTEE c1a DETAILS c1: ALWAYS COUNT(accendi) IN LAST 0.2 s <= 1
```

Nelle formule i numeri non interi si scrivono con il punto decimale. Due comandi distanti esattamente 0,2 secondi
rispettano la promessa: quando arriva il secondo, il primo è già fuori dall'intervallo.

La durata di `IN LAST` è costituita soltanto dal primo valore che segue la parola chiave: un numero con unità, un
nome, una chiamata o un'espressione fra parentesi. Nessun operatore della tabella del capitolo 21 la estende. La
formula `c1a` si legge quindi `(COUNT(accendi) IN LAST 0.2 s) <= 1`. Una durata calcolata si scrive fra parentesi:
`COUNT(e) IN LAST (2 * d)`.

Nel rapporto la riga `c1a` è formale:

```
1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 11: GUARANTEE c1a formale
```

### Il filtro sugli eventi: WITH

Un evento con parametri si può filtrare sul valore dei parametri: `e WITH c` accade nei passi in cui accade `e`
e i suoi parametri rispettano la condizione `c`. Lo stesso vale per le fasi di una richiesta, con i parametri
della richiesta. La promessa `g4` stabilisce che una richiesta di pulizie più lunga di due ore è rifiutata; la
durata richiesta è il parametro `durata` della richiesta `Pulizie`:

```
  GUARANTEE g4b DETAILS g4: WHENEVER (requested(Pulizie) WITH durata > 7200 s) THEN rejected(Pulizie) WITHIN 1 s
```

Due ore si scrivono `7200 s`, perché le unità sono soltanto `s` e `ms`. La condizione di `WITH` si estende fino
alla fine dell'espressione: per questo l'evento filtrato si scrive fra parentesi quando è seguito da altro, come
in `TIME SINCE (premuto WITH dove = primo) > 5 s`.

### Il valore precedente: PREV

Il **valore precedente** `PREV(x)` è il valore dello stato `x` nel passo precedente. Nel primo passo è il
valore iniziale dichiarato con `INITIAL`.

`PREV` serve perché in un passo uno stato ha il valore che assume dopo gli eventi del passo (capitolo 21). La
promessa `g7` stabilisce che durante le pulizie una pressione non cambia il modo. La condizione «durante le pulizie»
riguarda il modo **prima** della pressione:

```
  GUARANTEE g7a DETAILS g7: WHENEVER premuto AND PREV(modo) = in_pulizia THEN modo = in_pulizia AT ONCE
```

Ogni volta che accade `premuto` e nel passo precedente il modo era `in_pulizia`, nello stesso passo il modo
è ancora `in_pulizia`.

Con `PREV` si individua anche il passo in cui uno stato cambia valore: `PREV(modo) = accesa AND modo = spenta`
vale nel passo in cui la luce si spegne.

### Lo spegnimento e l'avviso come formule

Il dettaglio `g2a` diventa:

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(premuto) > 0 AND TIME SINCE premuto >= 85 s AND TIME SINCE premuto <= 95 s))
```

Si legge: in ogni passo in cui la luce passa da accesa a spenta, c'è stata almeno una pressione e dall'ultima
sono trascorsi da 85 a 95 secondi. La tolleranza di 5 secondi è espressa dai due limiti.

Tre osservazioni sulla formula:

- **azzeramento del tempo**: `TIME SINCE premuto` misura il tempo dall'**ultima** pressione, quindi la
  formula esprime anche il contenuto di `g2b`, cioè che una nuova pressione fa ripartire il tempo dall'inizio.
  `g2b` resta nella CSC, approvata, e non cambia. Nel suo testo approvato resta la parola «conteggio», che
  indica il tempo misurato e non `COUNT`;
- **pulizie**: lo spegnimento al termine delle pulizie è un passaggio da `in_pulizia` a `spenta`, non da
  `accesa` a `spenta`, e la formula non lo riguarda;
- **stato di approvazione**: `g2a` aveva un proprio `STATUS RATIFIED BY D-12`; poiché il testo cambia, la
  promessa torna da approvare, con `STATUS HYPOTHESIS` (capitolo 10).

Nella storia `s2` la luce si spegne all'istante 30: nel passo `@30 s` la formula richiede almeno 85 secondi
dall'ultima pressione, e ne sono trascorsi 30. La storia viola `g2a`, ed è quindi respinta, come dichiara la
sua riga `EXPECT REJECTED`.

Alla promessa `g3`, «poco prima di spegnersi, la luce dà un avviso», si aggiunge un dettaglio formale:

```
  GUARANTEE g3a DETAILS g3: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(avviso) > 0 AND COUNT(premuto SINCE avviso) = 0))
```

In ogni passo in cui la luce si spegne c'è stato almeno un avviso, e nessuno ha premuto dopo l'ultimo avviso.
Una pressione dopo l'avviso, quindi, impedisce lo spegnimento annunciato. Quanto tempo prima dello
spegnimento debba arrivare l'avviso non è espresso dal dettaglio e resta nel testo a parole di `g3`.

### Storie che si ripetono: REPEAT

Una storia può terminare con passi che si ripetono. La riga `REPEAT` si scrive fra i passi e vale fino alla fine
della storia: i passi che la seguono si ripetono a intervalli di durata `d`.

| Forma | Significato |
|---|---|
| `REPEAT m..n EVERY d` | i passi che seguono si ripetono da `m` a `n` volte |
| `REPEAT FOREVER EVERY d` | i passi che seguono si ripetono senza fine |

Ogni ripetizione comincia `d` dopo la precedente, e i tempi `@t` dei passi ripetuti sono misurati dall'inizio
della ripetizione. Nella storia seguente chi sale lentamente preme il pulsante ogni 60 secondi, da una a cinque
volte, e la luce è accesa dopo ogni pressione:

```
  SCENARIO s5 EXPECT ADMITTED
    REPEAT 1..5 EVERY 60 s
    @0 s     premuto    modo = accesa
```

La storia equivale a cinque storie, con una, due, tre, quattro e cinque pressioni distanti 60 secondi. `bcdd`
controlla la forma della ripetizione e segnala l'errore **E30** nei casi seguenti:

- la storia ha due righe `REPEAT`;
- i limiti non sono validi: il massimo deve essere almeno 1 e non minore del minimo;
- dopo `REPEAT` non c'è alcun passo;
- i tempi dei passi della storia sono scritti senza unità;
- un passo ripetuto ha un tempo uguale o maggiore del periodo.

L'ordine dei tempi (errore E12, capitolo 9) si controlla fra i passi ripetuti, con i tempi misurati dall'inizio
della ripetizione.

### La CSC e il rapporto

Il commento in testa diventa:

```
-- VERSION 0.3: g1, g2 e g2a scritte come formule; aggiunte g3a, g4a, g4b, g7a e g8. Da approvare.
```

Il rapporto riporta otto righe formali:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
righe: 57 (riconosciute 47, commenti 5, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 7
  formale: 8
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 16: GUARANTEE g1 formale
  riga 18: GUARANTEE g2 formale
  riga 20: GUARANTEE g2a formale
  riga 21: GUARANTEE g2b verbale
  riga 23: GUARANTEE g3 verbale
  riga 25: GUARANTEE g3a formale
  riga 26: GUARANTEE g4 verbale
  riga 28: GUARANTEE g4a formale
  riga 29: GUARANTEE g4b formale
  riga 30: GUARANTEE g5 verbale
  riga 32: GUARANTEE g6 verbale
  riga 34: GUARANTEE g7 verbale
  riga 36: GUARANTEE g7a formale
  riga 37: GUARANTEE g8 formale
  riga 38: ASSUME a1 verbale
…
14. DA GIUDICARE: 5
  riga 21: GUARANTEE g2b DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 25: GUARANTEE g3a DETAILS g3: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 28: GUARANTEE g4a DETAILS g4: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 29: GUARANTEE g4b DETAILS g4: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 36: GUARANTEE g7a DETAILS g7: coerenza fra la riga e la riga che dettaglia, una delle due a parole

15. CONTROLLI NON ESEGUITI: 4
  storie: righe 41, 46, 49, 51, 54
  copertura degli inneschi: righe 16, 18, 20, 25, 28, 29, 36, 37
  coerenza di presupposti e promesse: righe 16, 18, 20, 25, 28, 29, 36, 37
  coerenza dei dettagli: riga 20

esito: nessun errore
```

La sezione 15 elenca ora cinque storie, compresa `s5`, e otto righe formali per la copertura degli inneschi e per
la coerenza. La voce «coerenza dei dettagli» riguarda `g2a`, che è un dettaglio formale di una formula, `g2`. La
coerenza fra le due righe è un controllo che `bcdd` non esegue. I dettagli formali di una promessa a parole, come `g3a`,
`g4a`, `g4b` e `g7a`, stanno invece nella sezione 14, perché la coerenza con una riga a parole si giudica.

### Riepilogo

- `WITHIN d` aggiunge un **limite di tempo** a `EVENTUALLY` e a `WHENEVER`.
- `TIME SINCE e` è il **tempo trascorso** dall'ultimo `e`; vale 0 nel passo di `e` e infinito prima del
  primo `e`, perciò un confronto come `>= d` si scrive insieme a `COUNT(e) > 0`.
- `COUNT(e)` è il **conteggio** dei passi con `e`; `COUNT(e SINCE f)` conta solo quelli dopo l'ultimo `f`;
  `COUNT(e) IN LAST d` conta solo quelli dell'intervallo di durata `d` che termina con il passo considerato,
  compreso, senza il passo che dista esattamente `d`.
- `e WITH c` filtra un evento, o una fase di una richiesta, sul valore dei suoi parametri.
- `PREV(x)` è il **valore precedente** di uno stato; nel primo passo è il valore iniziale.
- `REPEAT m..n EVERY d` e `REPEAT FOREVER EVERY d` ripetono i passi che seguono la riga `REPEAT`, fino alla fine
  della storia; ogni passo ripetuto ha un tempo minore del periodo.

### Casi particolari

**Il valore dopo la pressione.** Se in `g7a` si scrive `modo = in_pulizia` al posto di
`PREV(modo) = in_pulizia`, la formula diventa: ogni volta che si preme e, dopo la pressione, il modo è
`in_pulizia`, il modo è `in_pulizia`. La formula è sempre rispettata e non esprime alcuna promessa. Anche una
pressione che porta il modo da `in_pulizia` ad `accesa`, vietata da `g7`, rispetta la formula. La forma, i nomi e i
tipi sono corretti, e `bcdd`, che non valuta le formule, non rileva il difetto:

```
1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 36: GUARANTEE g7a formale
…
```

**Luce che non si spegne mai.** `g2a` si valuta nel passo dello spegnimento. Se in una traccia la luce
resta accesa fino alla fine, `g2a` non ha un passo in cui applicarsi. Che lo spegnimento non avvenga è un
caso coperto da `g2`: «in un passo successivo la luce è spenta».

**Valore precedente nel primo passo.** Nel primo passo `PREV(modo)` vale `spenta`, il valore dichiarato con
`INITIAL`. Una pressione nel primo passo ha quindi `PREV(modo) = spenta`, e `g7a` non la riguarda.

**Minuti e durate senza unità.** Le unità delle durate sono soltanto `s` e `ms`, come nelle storie e nelle
costanti con nome: 90 secondi si scrivono `90 s`, e non `1.5 min`. Un numero senza unità dopo `WITHIN` non è una
durata, e `bcdd` segnala l'errore **E25**, tipo incoerente:

```
1. ERRORI: 1
  riga 28: [E25] tipo incoerente: serve Duration, trovato Integer
```

**Un passo ripetuto lungo quanto il periodo.** Nella storia `s5`, un secondo passo ripetuto `@60 s` cadrebbe
nello stesso istante della ripetizione successiva:

```
1. ERRORI: 1
  riga 57: [E30] il passo @60 s non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY 60 s
```

---

## Capitolo 23 — Le abbreviazioni

La promessa «la luce non è mai accesa se nessuno ha premuto» si scrive con le parole chiave dei capitoli 21 e
22, ma nella forma estesa. Il linguaggio prevede forme brevi per i casi frequenti. Il capitolo descrive queste
forme, dette abbreviazioni, e le regole sul loro significato. Descrive poi come si dà un nome a un'espressione, a
una funzione e a un evento derivato, e introduce i tipi con nome, i record e gli stati con indice.

### L'abbreviazione

Un'**abbreviazione** è una **forma breve** che si espande in una formula equivalente, scritta con le parole
chiave dei capitoli 21 e 22 e detta **forma estesa**. Il significato di un'abbreviazione è soltanto quello della
sua forma estesa: le parole inglesi che la compongono servono a ricordarla, ma non la definiscono.

Ne seguono tre regole:

1. una riga scritta con un'abbreviazione ha grado formale, come la sua forma estesa;
2. scrivere un'abbreviazione o la sua forma estesa non cambia il contratto;
3. un programma che valuta le formule valuta un'abbreviazione attraverso la sua forma estesa.

`bcdd` riconosce ogni abbreviazione come una forma a sé, ne controlla i nomi e i tipi, e non produce la forma
estesa.

### La promessa in forma breve e in forma estesa

La forma estesa della promessa è:

```
  GUARANTEE g9: ALWAYS (modo = accesa IMPLIES COUNT(premuto) > 0)
```

In ogni passo in cui la luce è accesa c'è stata almeno una pressione. La forma breve usa `PRECEDES`:

```
  GUARANTEE g9: premuto PRECEDES modo = accesa
```

`e PRECEDES q` si espande in `ALWAYS (q IMPLIES COUNT(e) > 0)`: la forma estesa di
`premuto PRECEDES modo = accesa` è la formula scritta sopra. Il primo elemento, `e`, è un evento, perché la
forma estesa ne conta i passi.

La stessa promessa si scrive anche con altre due abbreviazioni:

```
  GUARANTEE g9: NEVER (modo = accesa AND COUNT(premuto) = 0)
  GUARANTEE g9: BEFORE premuto: NEVER modo = accesa
```

`NEVER p` si espande in `ALWAYS NOT p`. `BEFORE e: P` si espande in `WHILE COUNT(e) = 0: P`, cioè «nei passi
che precedono il primo `e`». Le tre forme brevi hanno quindi tre forme estese, equivalenti fra loro:

| Forma breve | Forma estesa |
|---|---|
| `premuto PRECEDES modo = accesa` | `ALWAYS (modo = accesa IMPLIES COUNT(premuto) > 0)` |
| `NEVER (modo = accesa AND COUNT(premuto) = 0)` | `ALWAYS NOT (modo = accesa AND COUNT(premuto) = 0)` |
| `BEFORE premuto: NEVER modo = accesa` | `WHILE COUNT(premuto) = 0: ALWAYS NOT modo = accesa` |

Nella CSC della luce `g9` si scrive in forma breve, con `PRECEDES`, alla riga 39, dopo `g8`.

### La risposta a una richiesta, in forma breve

Il dettaglio `g4a` del capitolo 22 ha anch'esso una forma breve:

```
  GUARANTEE g4a DETAILS g4: RESOLVES Pulizie WITHIN 1 s
```

`RESOLVES X WITHIN d` si espande in `WHENEVER requested(X) THEN accepted(X) OR rejected(X) WITHIN d`, che è la
riga scritta nel capitolo 22. Le due righe sono la stessa promessa.

### Le abbreviazioni del linguaggio

La tabella riporta le abbreviazioni usate nelle promesse di una CSC, con la forma estesa di ciascuna.

| Forma breve | Forma estesa | Si legge |
|---|---|---|
| `NEVER p` | `ALWAYS NOT p` | mai `p` |
| `ONCE e` | `COUNT(e) > 0` | `e` è accaduto almeno una volta |
| `CHANGED(x)` | `x <> PREV(x)` | lo stato `x` ha cambiato valore in questo passo |
| `e PRECEDES q` | `ALWAYS (q IMPLIES COUNT(e) > 0)` | `q` non vale prima del primo `e` |
| `BEFORE e: P` | `WHILE COUNT(e) = 0: P` | `P` vale prima del primo `e` |
| `AFTER e: P` | `WHILE COUNT(e) > 0: P` | `P` vale dal primo `e` in poi, passo di `e` compreso |
| `ACCEPTS X ONLY WHILE c` | `ALWAYS (accepted(X) IMPLIES c)` | la richiesta `X` è accettata solo se vale `c` |
| `X ENSURES p` | `WHENEVER completed(X) THEN p AT ONCE` | quando `X` si conclude con esito riuscito, vale `p` |
| `RESOLVES X WITHIN d` | `WHENEVER requested(X) THEN accepted(X) OR rejected(X) WITHIN d` | `X` ha una risposta entro `d` |
| `X REQUIRES c` | `ALWAYS (requested(X) IMPLIES c)` | `X` può essere richiesta solo se vale `c`; si scrive soltanto in un presupposto |
| `TRANSITION x: A -> B ON e WHEN c, …` | `ALWAYS (CHANGED(x) IMPLIES ((PREV(x) = A AND x = B AND e AND c) OR …))` | `x` cambia valore soltanto nei modi elencati |

`ONCE` e `CHANGED` si scrivono all'interno di una condizione: `ALWAYS (CHANGED(modo) IMPLIES ONCE premuto)`.
`X REQUIRES c` descrive un obbligo di chi usa e si scrive soltanto in un presupposto (riga `ASSUME`).

### Un insieme chiuso di transizioni: TRANSITION

`TRANSITION` elenca tutti i modi in cui uno stato cambia valore. Ogni voce `A -> B ON e` indica che lo stato passa
dal valore `A` al valore `B` in un passo in cui accade l'evento `e`; con `WHEN c` anche la condizione `c` deve
valere. L'elenco è **chiuso**: un cambiamento che non vi compare viola la promessa. Il tipo dello stato è un
elenco di valori; `A` e `B` ne sono valori.

Il modo della luce passa da `accesa` a `spenta` senza un evento del confine: la luce si spegne allo scadere del
tempo.
Per nominare quel passo come un evento si scrive un **evento derivato**, con `DEFINE EVENT`:

```
  DEFINE     EVENT scadenza := TIME SINCE premuto >= 85 s
```

`scadenza` accade nei passi in cui dall'ultima pressione sono trascorsi almeno 85 secondi. Un evento derivato si
usa in una formula al posto di un evento; non si scrive nei passi delle storie, che contengono soltanto eventi
dichiarati con `EVENT`. La promessa `g10` elenca i cambiamenti del modo:

```
  GUARANTEE g10: TRANSITION modo: spenta -> accesa ON premuto,
                                  accesa -> spenta ON scadenza,
                                  spenta -> in_pulizia ON accepted(Pulizie),
                                  accesa -> in_pulizia ON accepted(Pulizie),
                                  in_pulizia -> spenta ON completed(Pulizie),
                                  in_pulizia -> spenta ON failed(Pulizie)
```

Le righe, tranne l'ultima, finiscono con una virgola e quindi continuano sulla riga successiva (capitolo 21): la
promessa è una dichiarazione sola. Una pressione durante le pulizie non compare nell'elenco, quindi non cambia il modo, come
promette `g7`.

Il commento in testa diventa:

```
-- VERSION 0.3: g1, g2 e g2a scritte come formule; aggiunte g3a, g4a, g4b, g7a, g8, g9 e g10. Da approvare.
```

Nel rapporto le due righe nuove sono formali:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
righe: 65 (riconosciute 55, commenti 5, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 38: GUARANTEE g8 formale
  riga 39: GUARANTEE g9 formale
  riga 40: GUARANTEE g10 formale
…
```

### Dare un nome a un'espressione

Il valore di una costante con nome (capitolo 8) può essere un'espressione:
`DEFINE DURATA_AVVISO := DURATA_LUCE - 5 s` dà un nome a una durata calcolata. Una `DEFINE` può anche avere
**parametri**, ciascuno con il suo tipo: è allora una **funzione**, che si usa con gli argomenti scritti per nome,
come gli argomenti degli eventi nelle storie. Con le tre righe nuove seguenti

```
  DEFINE     DURATA_LUCE := 90 s
  DEFINE     TOLLERANZA := 5 s
  DEFINE     vicino(t: Duration, valore: Duration) := ABS(t - valore) <= TOLLERANZA
```

il dettaglio `g2a` si scrive:

```
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (ONCE premuto AND vicino(t: TIME SINCE premuto, valore: DURATA_LUCE)))
```

`vicino(t: …, valore: …)` vale quando le due durate differiscono di non più di `TOLLERANZA`. La riga è formale:

```
1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 24: GUARANTEE g2a formale
…
```

`bcdd` controlla che ogni argomento sia un parametro della funzione e che nessuno manchi, e ne controlla il tipo.
Per una chiamata senza `valore` `bcdd` segnala l'errore E24:

```
1. ERRORI: 1
  riga 24: [E24] manca l'argomento valore nella chiamata di vicino
```

Le `DEFINE` non possono nominarsi a vicenda in modo circolare: per `DEFINE A := B + 1` con `DEFINE B := A - 1`
`bcdd` segnala l'errore E28. Una `DEFINE` che precisa un'altra `DEFINE` (`DEFINE nome DETAILS padre := …`) è da
approvare come ogni dettaglio, e si approva con `bcdd ratify` come una riga contrattuale.

### Tipi con nome, record e stati con indice

In un edificio a tre piani la luce delle scale ha un pulsante e una lampada per piano. La CSC `LucePiani` usa tre
forme nuove:

```
-- La luce delle scale di un edificio a tre piani: un pulsante e una lampada per piano.

CSC LucePiani VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante del proprio piano e ha luce su quel piano"

  TYPE       Piano := {terra, primo, secondo}
  TYPE       Percentuale := Integer [0 .. 100]
  TYPE       Tocco := Record {piano: Piano, lungo: Boolean}

  EVENT IN   premuto(dove: Piano)
  EVENT IN   toccato(t: Tocco)
  STATE      accesa[Piano] : Boolean INITIAL false
  STATE      ultimo : Piano INITIAL terra FOLLOWS premuto.dove
  STATE      intensita : Percentuale INITIAL 0

  GUARANTEE p1: FOR ALL p IN Piano: WHENEVER (premuto WITH dove = p) THEN accesa[p] AT ONCE
  GUARANTEE p2: ALWAYS (toccato IMPLIES accesa[LAST(toccato).t.piano])
  GUARANTEE p3: ALWAYS (intensita > 0 IMPLIES accesa[ultimo])

  SCENARIO q1 EXPECT ADMITTED
    @0 s     premuto(dove: primo)    accesa[primo] = true
    @1 s     toccato(t: _)
END
```

- **un tipo con nome**: `TYPE Percentuale := Integer [0 .. 100]` dà un nome a un tipo; il nome vale come il tipo
  che nomina, in tutto il blocco. Un limite dell'intervallo si può omettere: `Integer [0 ..]` è un intero non
  negativo senza massimo;
- **un record**: `TYPE Tocco := Record {piano: Piano, lungo: Boolean}` è un tipo con campi; `x.campo` ne nomina un
  campo, e `LAST(e).p` il valore del parametro `p` nell'ultimo passo in cui è accaduto `e`. In una storia il valore
  di un parametro di tipo record si scrive `_`;
- **uno stato con indice**: `STATE accesa[Piano] : Boolean INITIAL false` equivale a uno stato per ogni piano:
  `accesa[terra]`, `accesa[primo]`, `accesa[secondo]`. Il tipo dell'indice è **finito**: un elenco di valori,
  `Boolean`, oppure un tipo con nome definito come uno di questi o come un `Integer` con i due limiti.

`FOR ALL p IN Piano: P` vale per ogni valore del tipo, dove `p` assume a turno ciascun valore: la promessa `p1` è
la stessa promessa scritta tre volte, una per piano. `STATE ultimo : Piano INITIAL terra FOLLOWS premuto.dove`
dichiara uno stato che segue il parametro `dove` dell'ultimo `premuto`. La sua forma estesa è la coppia di formule
`ALWAYS (premuto IMPLIES ultimo = LAST(premuto).dove)` e `ALWAYS (CHANGED(ultimo) IMPLIES premuto)`. `FOR ALL`,
gli indici e `FOLLOWS` sono abbreviazioni.

Il rapporto non ha errori:

```
1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 0
  formale: 3
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 17: GUARANTEE p1 formale
  riga 18: GUARANTEE p2 formale
  riga 19: GUARANTEE p3 formale
```

`bcdd` controlla i campi, gli indici e i valori letterali. Si introducono quattro difetti: una promessa nomina un
campo `stanza` che il record non ha, `ALWAYS accesa` è scritto senza indice, un passo preme il pulsante al piano
`quarto` e lo stesso passo porta l'intensità a 120. Il rapporto segnala quattro errori:

```
1. ERRORI: 4
  riga 20: [E24] nome non dichiarato come campo di Tocco: stanza
  riga 21: [E29] accesa ha un indice: scrivi accesa[valore di Piano]
  riga 26: [E03] nome non dichiarato come valore di TYPE: quarto
  riga 26: [E25] valore non del tipo Percentuale: 120
```

Il valore 120 è fuori dall'intervallo del tipo `Percentuale`: `bcdd` confronta con il tipo dichiarato i valori
letterali della clausola `INITIAL`, della clausola `GIVEN`, delle assegnazioni e degli argomenti dei passi (errore
E25).

### Riepilogo

- Un'**abbreviazione** è una **forma breve** che si espande in una formula equivalente, la **forma estesa**;
  il suo significato è soltanto quello della forma estesa.
- Una riga scritta con un'abbreviazione ha grado formale.
- Più abbreviazioni possono esprimere la stessa promessa: `PRECEDES`, `NEVER` e `BEFORE` nell'esempio di
  `g9`.
- `RESOLVES` esprime in forma breve la risposta a una richiesta entro un tempo; `TRANSITION` elenca l'insieme
  chiuso delle transizioni di uno stato.
- `DEFINE` dà un nome a un'espressione, a una funzione con parametri, oppure, con `DEFINE EVENT`, a un evento
  derivato.
- `TYPE Nome := Tipo` dà un nome a un tipo; `Record {…}` è un tipo con campi; `STATE x[T]` è uno stato con indice
  su un tipo finito; `FOR ALL` e `FOLLOWS` sono abbreviazioni.

### Casi particolari

**Forme brevi con la forma estesa incompleta.** Il linguaggio prevede anche le forme `AFTER e UNTIL f: P`,
`BETWEEN e AND f: P` e `p FOR AT LEAST d`. Le prime due delimitano un intervallo fra due eventi; la terza richiede
che una condizione valga per una durata minima. La forma estesa di `AFTER e UNTIL f: P` è un ambito `WHILE` su una
`DEFINE`. La `DEFINE` vale da un `e` al primo `f` successivo e si calcola con `PREV` sui passi già trascorsi
della traccia. Per `BETWEEN` e `FOR AT LEAST` la forma estesa non è ancora definita per intero. `bcdd` riconosce le tre
forme e ne controlla i nomi e i tipi; il manuale non le usa.

**`REQUIRES` in una promessa.** `X REQUIRES c` descrive ciò che chi usa deve rispettare prima di effettuare la
richiesta. Se la forma è scritta in una promessa (riga `GUARANTEE`), `bcdd` segnala l'errore **E27**, e il
messaggio indica la forma da scrivere:

```
1. ERRORI: 1
  riga 39: [E27] REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)
```

**Le varianti.** Anche `VARIANT` (capitolo 20) si riduce ad altre forme: un'entità con varianti equivale
all'insieme delle sue composizioni, ciascuna scritta come un'entità senza varianti. `VARIANT` non si espande in
una formula, quindi non è un'abbreviazione nel senso di questo capitolo.

**La forma breve nel testo a parole.** In `VERBAL "la luce non si accende mai PRIMA DI una pressione"` le
parole fra virgolette sono testo, e non un'abbreviazione: la riga resta verbale.

```
2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 39: GUARANTEE g9 verbale
…
```

---

## Capitolo 24 — Il significato di «verificato»

Con le formule dei capitoli 21-23 la CSC della luce contiene promesse di due gradi: verbali e formali. Il
capitolo descrive i due momenti della verifica, gli esiti che ciascun grado può avere, le regole con cui
quegli esiti si riportano e la parte della verifica che `bcdd` esegue.

### I due momenti della verifica

La verifica di una CSC avviene in due momenti:

1. la **verifica sul testo** esamina la CSC prima che il sistema sia costruito;
2. la **verifica sulle registrazioni** esamina le registrazioni di un sistema costruito. Una
   **registrazione** è una traccia, cioè una sequenza di passi, osservata sui confini di un sistema
   costruito.

Le due verifiche rispondono a domande diverse. La prima stabilisce se la descrizione è formulata correttamente e se è
possibile rispettarla; la seconda, se un sistema costruito l'ha rispettata nelle situazioni osservate.

### La verifica sul testo

La verifica sul testo comprende i controlli seguenti:

| Controllo | Che cosa si controlla |
|---|---|
| forma | i nomi e i tipi sono coerenti, ogni promessa ha un nome, ogni dettaglio rende precisa una riga esistente |
| coerenza | esiste almeno una traccia che rispetta insieme tutti i presupposti e tutte le promesse |
| storie | ogni storia è ammessa o respinta dalle promesse, come dichiara la sua riga `EXPECT` |
| copertura | per ogni promessa con un innesco esiste una storia ammessa in cui l'innesco vale |
| chi usa trova chi offre | in un'entità con parti, ogni confine usato da una parte è offerto da un'altra parte o è un confine esterno |
| promesse d'entità | le promesse dell'entità sono compatibili con quelle delle parti e dei confini |
| dettagli | ogni dettaglio è compatibile con la riga che rende precisa |

L'innesco di una promessa scritta con `WHENEVER` è la sua prima condizione (capitolo 21). Per le altre forme:

- in `ALWAYS (p IMPLIES q)` l'innesco è `p`: per `g2a` è il passaggio della luce da accesa a spenta;
- in `WHILE c: P` l'innesco è `c`, e se `P` ha a sua volta un innesco devono valere entrambi nello stesso passo;
- `ALWAYS p` senza `IMPLIES` ed `EVENTUALLY p` non hanno innesco;
- un'abbreviazione ha l'innesco della sua forma estesa (capitolo 23): `premuto PRECEDES modo = accesa`
  ha innesco `modo = accesa`.

La copertura segnala quindi le promesse rispettate soltanto perché il loro innesco non si presenta in nessuna
storia.

Sulle righe formali questi controlli si possono eseguire con un programma. Nella CSC della luce un programma
potrebbe stabilire che la storia `s2` viola `g2a` ed è quindi respinta, come dichiara la sua riga `EXPECT`: è un
controllo che nel capitolo 9 restava a chi scrive. Sulle righe verbali la coerenza, le storie e i dettagli restano affidati
al giudizio di una persona.

La coerenza non garantisce che il sistema si possa costruire: indica soltanto che esiste una traccia che
rispetta la CSC. La specifica non prevede un controllo della **realizzabilità**, cioè dell'esistenza di un
sistema che rispetti le promesse qualunque sia il comportamento dell'altro lato.

### I controlli eseguiti da bcdd

`bcdd` esegue due controlli della tabella: la **forma**, compresi i nomi e i tipi delle formule, e la regola
**chi usa trova chi offre** (capitoli 13, 19 e 20). Gli altri controlli non sono eseguiti, e il rapporto lo
riporta. La sezione 15 elenca le righe a cui si applicherebbero i controlli delle storie, della copertura, della
coerenza e dei dettagli formali. La sezione 14 elenca i dettagli la cui coerenza si giudica perché una delle due
righe è a parole. Le promesse d'entità restano affidate al giudizio (capitolo 12). Sulla versione 0.3 della luce:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 65 (riconosciute 55, commenti 5, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.3, STATUS HYPOTHESIS

1. ERRORI: 0
…
14. DA GIUDICARE: 5
  riga 22: GUARANTEE g2b DETAILS g2: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 26: GUARANTEE g3a DETAILS g3: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 29: GUARANTEE g4a DETAILS g4: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 30: GUARANTEE g4b DETAILS g4: coerenza fra la riga e la riga che dettaglia, una delle due a parole
  riga 37: GUARANTEE g7a DETAILS g7: coerenza fra la riga e la riga che dettaglia, una delle due a parole

15. CONTROLLI NON ESEGUITI: 4
  storie: righe 49, 54, 57, 59, 62
  copertura degli inneschi: righe 17, 19, 21, 26, 29, 30, 37, 38, 39, 40
  coerenza di presupposti e promesse: righe 17, 19, 21, 26, 29, 30, 37, 38, 39, 40
  coerenza dei dettagli: riga 21

esito: nessun errore
```

«Nessun errore» riguarda la forma: dieci righe sono formali, e per ciascuna la sezione 15 riporta che cosa non è
stato controllato. Un esito non vale mai più di ciò che è stato controllato effettivamente.

| Controllo | In `bcdd` |
|---|---|
| forma | eseguito: errori nella sezione 1 |
| chi usa trova chi offre | eseguito: errori E14, E16, E17 |
| storie | non eseguito: voce `storie` della sezione 15 |
| copertura | non eseguito: voce `copertura degli inneschi` della sezione 15 |
| coerenza | non eseguito: voce `coerenza di presupposti e promesse` della sezione 15 |
| dettagli | formali: voce `coerenza dei dettagli` della sezione 15; con una riga a parole: sezione 14 |
| promesse d'entità | a giudizio |

### Gli esiti sulle registrazioni

Sulle registrazioni ogni promessa riceve un esito. Gli esiti possibili dipendono dal grado:

| Grado | Esiti |
|---|---|
| formale | rispettata sulla traccia, violata (con il passo), inconclusiva, presupposto non rispettato, non eseguita |
| verbale | conforme a giudizio, non conforme a giudizio, non valutata; ciascuno con chi ha giudicato e su che cosa |

Gli esiti formali hanno questo significato:

- **rispettata sulla traccia**: nella traccia registrata la formula non è mai violata. Nella specifica
  l'esito si chiama `SODDISFATTA SULLA TRACCIA`;
- **violata**: in un passo della traccia la formula non vale; l'esito indica il passo;
- **inconclusiva**: la traccia termina prima che si possa stabilire l'esito. Succede, per esempio, quando una
  conseguenza senza limite di tempo non vale in nessun passo fino alla fine della traccia, o quando la traccia
  termina prima che sia trascorso il limite di tempo. L'esito elenca i passi d'innesco rimasti senza risposta.
  Una conseguenza senza limite di tempo che non si è verificata entro la fine della registrazione non rende
  mai violata la promessa: la risposta potrebbe arrivare dopo la fine;
- **presupposto non rispettato**: l'altro lato non ha rispettato un presupposto da cui la promessa dipende;
- **non eseguita**: il mezzo di registrazione (capitolo 26) non osserva ciò a cui la promessa si riferisce.

Gli esiti verbali registrano un giudizio: chi ha giudicato, su che cosa, e con quale conclusione. Una
promessa verbale che nessuno ha ancora giudicato è **non valutata**.

Nessun programma descritto in questo manuale esegue la verifica sulle registrazioni: gli esiti di questa sezione
sono quelli stabiliti dalla specifica.

### «Rispettata sulla traccia» vale per ciò che è stato osservato

Una registrazione della luce, scritta come una storia, è la seguente:

```
    @0 s     premuto    modo = accesa
    @40 s    premuto    modo = accesa
    @125 s   avviso
    @130 s   modo = spenta
```

Su questa traccia le formule della CSC della luce hanno gli esiti seguenti:

| Promessa | Esito | Motivo |
|---|---|---|
| `g1` | rispettata sulla traccia | dopo ciascuna delle due pressioni il modo è `accesa` |
| `g2` | rispettata sulla traccia | dopo l'accensione la luce si spegne, all'istante 130 |
| `g2a` | rispettata sulla traccia | allo spegnimento sono trascorsi 90 secondi dall'ultima pressione |
| `g3a` | rispettata sulla traccia | prima dello spegnimento c'è un avviso, e dopo l'avviso nessuno ha premuto |
| `g4a` | rispettata sulla traccia | nella traccia non c'è alcuna richiesta di pulizie |
| `g4b` | rispettata sulla traccia | nella traccia non c'è alcuna richiesta di pulizie |
| `g7a` | rispettata sulla traccia | nella traccia non c'è alcuna pressione durante le pulizie |
| `g8` | rispettata sulla traccia | a luce spenta non arriva alcun avviso |
| `g9` | rispettata sulla traccia | la luce si accende soltanto dopo una pressione |
| `g10` | rispettata sulla traccia | il modo cambia due volte: all'istante 0 con una pressione, all'istante 130 a 90 secondi dall'ultima pressione |

Nella versione 0.3 queste righe sono da approvare, e il loro esito si riporta come descritto nel caso
particolare «Una promessa da approvare».

`g4a`, `g4b` e `g7a` sono rispettate sulla traccia perché il loro innesco non vale mai: la traccia non fornisce
alcuna informazione su come risponda la luce a una richiesta di pulizie o a una pressione durante le pulizie.
«Rispettata sulla traccia» vale soltanto per la traccia registrata e per la risoluzione con cui è stata
registrata (capitolo 26): non implica nulla sulle situazioni che non sono state osservate.

Su una registrazione che termina all'istante 60, con la luce ancora accesa, `g2` è **inconclusiva**: lo
spegnimento non è avvenuto entro la fine della registrazione, e nulla consente di stabilire se sarebbe
avvenuto. L'esito indica il passo dell'accensione rimasto senza risposta. Su una registrazione con una sola
pressione all'istante 0 e lo spegnimento all'istante 60, `g2a` è **violata** nel passo `@60 s`.

### Il giudizio di una persona e il risultato di un programma

Il rapporto di una verifica sulle registrazioni riporta gli esiti **per grado**, in sezioni separate: una per
le promesse formali, una per quelle verbali e, per le promesse scritte con un'estensione, una per il grado
estensione dichiarata (capitolo 27). Le righe da approvare compaiono in una sezione a parte, come
nella sezione 4 del rapporto di `bcdd check`: il loro esito non è un esito del contratto.

Un esito dato a giudizio non si somma mai a un esito dato da un programma. Si consideri una versione
approvata della CSC della luce, in cui le dieci formule sono rispettate sulla traccia e una persona con un
cronometro giudica conforme a giudizio la promessa verbale `g3`. Il rapporto riporta dieci promesse formali
rispettate sulla traccia e una promessa verbale conforme a giudizio, in due sezioni distinte; non riporta
undici promesse rispettate. I due risultati hanno un valore diverso: il primo deriva
dall'applicazione della formula a ogni passo della traccia, il secondo dall'osservazione e dalla
valutazione di una persona.

### Il presupposto non rispettato

Una promessa vale finché l'altro lato rispetta i presupposti da cui dipende (capitolo 3). Se una
registrazione mostra che un presupposto formale non è stato rispettato, la verifica lo riporta con l'esito
**presupposto non rispettato**, e non come promessa violata: la promessa vale soltanto se il presupposto è
rispettato.

Il presupposto `a1` della luce, «chi preme il pulsante lo tiene premuto per almeno un decimo di secondo», è
verbale: nessun programma può stabilire se è stato rispettato. Lo stabilisce una persona, e il suo giudizio
compare nella sezione verbale, distinto dall'esito di `g1`. L'esito di `g1` resta quello calcolato dal
programma, perché un giudizio non cambia mai un esito formale. Se `a1` è giudicato non rispettato, la
sezione delle promesse formali contiene una nota che elenca i presupposti verbali giudicati non rispettati e
chi li ha giudicati: la nota segnala così che un esito come «violata» può dipendere da chi ha premuto il
pulsante e non dalla luce. Poiché una promessa non dichiara da quali presupposti dipende, la nota vale per
tutte le promesse formali della CSC.

La specifica non stabilisce ancora che cosa resti promesso dopo che un presupposto non è stato rispettato,
né se ciò riguardi tutte le promesse o soltanto quelle che dipendono da quel presupposto.

### Riepilogo

- La verifica avviene in due momenti: **sul testo**, prima della costruzione, e **sulle registrazioni** di un
  sistema costruito.
- Sul testo si controllano forma, coerenza, storie, copertura, la regola «chi usa trova chi offre», le
  promesse d'entità e i dettagli; la coerenza non garantisce la realizzabilità.
- `bcdd` esegue il controllo della forma e la regola «chi usa trova chi offre»; elenca nella sezione 15 i
  controlli sulle formule che non esegue e nella sezione 14 ciò che resta da giudicare.
- Una promessa formale può essere **rispettata sulla traccia**, **violata**, **inconclusiva**, con
  **presupposto non rispettato** o **non eseguita**; una promessa verbale **conforme a giudizio**, **non
  conforme a giudizio** oppure **non valutata**.
- «Rispettata sulla traccia» vale soltanto per la traccia osservata.
- Gli esiti si riportano per grado, e un giudizio non si somma mai al risultato di un programma.

### Casi particolari

**Una formula con un numero non deciso.** Con la costante `ANTICIPO_AVVISO := UNDECIDED` e il dettaglio
`g3a DETAILS g3: ALWAYS ((PREV(modo) = accesa AND modo = spenta) IMPLIES (COUNT(avviso) > 0 AND COUNT(premuto SINCE avviso) = 0 AND TIME SINCE avviso <= ANTICIPO_AVVISO))`
la promessa non si può verificare, né sul testo né sulle registrazioni, finché il numero non è deciso. `bcdd`
elenca il numero non deciso, ma non indica quali formule lo usano; la riga resta formale, e il valore non deciso
si usa senza controllo del tipo:

```
1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 27: GUARANTEE g3a formale
…

3. UNDECIDED: 1
  riga 14: ANTICIPO_AVVISO
```

**Una promessa che il mezzo di registrazione non osserva.** Se il mezzo di registrazione rileva la pressione e
lo stato della luce ma non l'avviso, `g8` è **non eseguita**: l'esito non indica né il rispetto né la violazione.
Il capitolo 26 descrive come si dichiara che cosa osserva ciascun mezzo.

**Una storia dichiarata respinta ma ammessa.** Nel capitolo 9 una storia dichiarata respinta, ma ammessa
dalle promesse, non era rilevabile, perché le promesse erano a parole. Con `g2a` scritta come formula, in una
storia come `s2` ma con lo spegnimento a `@90 s` il controllo delle storie può stabilire che la storia è
ammessa e che la dichiarazione `EXPECT REJECTED` è errata. `bcdd check` non esegue questo controllo: la
storia compare nella voce `storie` della sezione 15.

**Una promessa da approvare.** L'esito di una promessa con `STATUS HYPOTHESIS` si riporta nella sezione delle
righe da approvare: una violazione indica che la promessa, così scritta, non descrive il sistema registrato,
e non che il sistema non rispetti un contratto.

---

## Capitolo 25 — La forma concreta dei confini

Le CSC dei capitoli precedenti indicano ciò che accade a un confine con nomi scelti da chi scrive: `premuto`,
`accendi`, `modo = accesa`, `avviso`. Il capitolo introduce le forme concrete, cioè il modo in cui ciascuno di
questi elementi si presenta al confine, e il criterio con cui si stabilisce che cosa scrivere, «chi lo vede?».
Introduce infine il blocco `BINDING`, che contiene le forme concrete.

### Le forme concrete

Una **forma concreta** è ciò che chi sta al confine osserva o usa di un elemento di una CSC: un morsetto, un
testo sullo schermo, un colore, un formato di file, un'opzione della riga di comando, un messaggio su una
rete. La CSC stabilisce che un elemento esiste e che cosa promette chi offre; le forme concrete
stabiliscono come quell'elemento si presenta al confine. Nel capitolo 4, per esempio, la riga `EVENT OUT avviso` dichiara che
l'avviso esiste, mentre il suo aspetto, un breve lampeggio o un segnale acustico, è una forma concreta. Allo
stesso modo, in un programma con una finestra la CSC può dichiarare uno stato `allarme : Boolean`, e le forme
concrete stabiliscono che l'allarme si presenta come la scritta «ALLARME» in rosso.

Le forme concrete di un confine si scrivono in un blocco `BINDING … END`, distinto dal blocco `CSC` del
confine. Le forme concrete riguardano:

- ciò che una persona osserva e usa: posizioni, testi, colori, gesti, il formato dei numeri;
- il filo fra due sistemi: il mezzo di trasmissione, la struttura dei messaggi, la codifica dei numeri;
- ciò che un programma legge o scrive: un file d'impostazioni, la riga di comando, un sistema audio;
- un sistema terzo, quando un effetto si osserva soltanto in quel sistema.

Le forme concrete non aggiungono promesse: indicano come si presentano al confine gli elementi a cui le promesse si
riferiscono.

### Il criterio «chi lo vede?»

Per decidere dove si scrive un elemento, la specifica pone un'unica domanda: chi lo vede, e come.

| Situazione | Dove si scrive |
|---|---|
| nessuno, al confine, lo vede | non si scrive: è realizzazione |
| qualcuno lo vede, e la sua forma può cambiare senza cambiare il significato delle promesse | nelle forme concrete |
| qualcuno lo vede, e cambiarlo cambia il significato delle promesse | nella CSC |
| il numero che rende controllabile una promessa si ricava soltanto da una realizzazione esistente | nella CSC, come numero non deciso (`UNDECIDED`), con una domanda a chi approva |
| una realizzazione esistente produce un effetto visibile, ma nulla indica che sia voluto | né nella CSC né nelle forme concrete: si pone la domanda a chi approva |

Una forma concreta è **vincolante** quando la osserva o la usa qualcuno che non fa parte della stessa realizzazione: una
persona, un altro programma, un sistema terzo.

### Le forme concrete della luce

La tabella applica il criterio agli elementi della CSC `UsoLuce` (capitoli 21-23) e della CSC `Comando`, il
confine fra il pulsante e la lampada (capitolo 13).

| CSC | Elemento | Chi lo vede | Forma concreta |
|---|---|---|---|
| `UsoLuce` | `premuto` | chi sta sulle scale | pressione del tasto del pulsante a muro |
| `UsoLuce` | `modo = spenta` | chi sta sulle scale | lampada spenta |
| `UsoLuce` | `modo = accesa`, `modo = in_pulizia` | chi sta sulle scale | lampada accesa |
| `UsoLuce` | `avviso` | chi sta sulle scale | la lampada si spegne per 0,3 s e si riaccende |
| `Comando` | `accendi` | chi realizza la lampada | contatto chiuso fra il morsetto 3 e il morsetto comune per almeno 50 ms |

`accesa` e `in_pulizia` hanno la stessa forma concreta: chi sta sulle scale non li distingue a vista, e ne
osserva la differenza soltanto nel comportamento, perché durante le pulizie una pressione non cambia il modo
(capitolo 6).

**L'avviso.** Con un lampeggio o con un segnale acustico le promesse conservano il loro significato: per
questo l'aspetto dell'avviso è una forma concreta. L'anticipo con cui l'avviso precede lo spegnimento, invece,
cambia ciò che chi sta sulle scale può aspettarsi, e si scrive nella CSC: è la costante con nome
`ANTICIPO_AVVISO` del capitolo 8.

**Il morsetto 3.** `Comando` è un confine interno all'entità `LuceScale` (capitolo 13). Se il pulsante e la
lampada sono realizzati da due fabbricanti diversi, chi realizza la lampada deve
sapere quale contatto rappresenta un `accendi`: il morsetto 3 e la durata minima di 50 ms sono forme concrete
vincolanti. Se invece il pulsante e la lampada sono realizzati insieme, nessuno al di fuori di quella
realizzazione usa il morsetto, che resta una scelta interna. La durata minima stabilisce quale contatto conta
come `accendi`; modificarla non cambia la promessa `c1` di `Comando` né il presupposto `a1` di `UsoLuce`.

**Il relè.** Il relè che chiude il circuito della lampada non è visibile a chi sta sulle scale (capitolo 1): è
realizzazione e non si scrive. La frase «`accesa` significa relè chiuso» escluderebbe una lampada che mantiene
le stesse promesse senza un relè.

**Un numero preso da una realizzazione.** Se l'anticipo dell'avviso si ricava soltanto da un modulo già
installato, che emette l'avviso 5 secondi prima dello spegnimento, il numero non è stato deciso da nessuno: nella
CSC resta `ANTICIPO_AVVISO := UNDECIDED`, e a chi approva si chiede quale valore stabilire.

**Un comportamento che nessuno ha richiesto.** All'accensione il relè del modulo installato produce uno scatto
udibile. Chi sta sulle scale lo sente, ma nessuno lo ha richiesto: non si scrive nella CSC, e si chiede a chi
approva se va mantenuto. In caso affermativo lo scatto diventa un elemento della CSC con la sua forma concreta;
altrimenti resta una caratteristica della realizzazione, che un'altra lampada può non avere.

### Il blocco BINDING

Le forme concrete della luce si scrivono in un file proprio, `FormeLuce.csc`:

```
-- Le forme concrete della luce delle scale, viste da chi sta sulle scale.

BINDING UsoLuce VERSION 0.3
  STATUS HYPOTHESIS
  BIND premuto: VERBAL "pressione del tasto del pulsante a muro"
  BIND modo:    VERBAL "spenta: lampada spenta; accesa e in_pulizia: lampada accesa"
  BIND avviso:  VERBAL "la lampada si spegne per 0,3 s e si riaccende"
END
```

L'intestazione `BINDING UsoLuce VERSION 0.3` nomina la **CSC legata**, con la sua versione. Ogni riga
`BIND elemento: VERBAL "…"` descrive a parole la forma concreta di un elemento della CSC legata: uno stato, un
evento, una richiesta o una costante con nome, oppure il parametro di un evento o di una richiesta, scritto
`evento.parametro`. Più righe `BIND` per lo stesso elemento descrivono aspetti diversi della stessa forma.
Una riga `BIND` non è una promessa: non ha `VERIFY` né `DETAILS`. Il blocco non ha `PURPOSE`; nella sua
intestazione stanno `STATUS` e le righe `IMPORT PROFILE`.

```
$ bcdd check FormeLuce.csc
bcdd check FormeLuce.csc
righe: 8 (riconosciute 6, commenti 1, vuote 1, non riconosciute 0)
blocchi: 1
  riga 3: BINDING UsoLuce VERSION 0.3, STATUS HYPOTHESIS
    riga 3: CSC UsoLuce in UsoLuce.csc alla riga 4: VERSION 0.3, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 0
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 3
  riga 5: BIND premuto
  riga 6: BIND modo
  riga 7: BIND avviso

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

12. FORME CONCRETE MANCANTI: 1
  riga 3: BINDING UsoLuce VERSION 0.3: CAPABILITY Pulizie

esito: nessun errore
```

`bcdd` cerca la CSC legata come cerca una CSC citata da un'entità (capitolo 15): nello stesso file, nel file
`UsoLuce.csc` della stessa cartella, poi nelle cartelle indicate con `--dir`. La CSC trovata compare sotto la riga
del blocco. Per una riga `BIND` che nomina un elemento che la CSC legata non dichiara, `bcdd` segnala l'errore E31.

La sezione 12, «forme concrete mancanti», elenca gli stati, gli eventi e le richieste della CSC legata che
nessuna riga `BIND` del blocco nomina: qui la richiesta `Pulizie`, la cui forma concreta, per esempio il quadro
del custode, non è ancora scritta. Una voce della sezione 12 non è un errore. La sezione compare soltanto quando il
file contiene almeno un blocco `BINDING`.

Un `BINDING` ha uno stato, come una CSC: le sue righe `BIND` sono da approvare e compaiono nella sezione 4.

### Più forme concrete per lo stesso confine

Un confine può avere più blocchi di forme concrete. La CSC `Comando` ne ha due: uno per il pulsante a filo e uno
per il pulsante senza fili del capitolo 14. La CSC resta una sola, e ogni blocco ha un **nome distintivo**, scritto
dopo `AS`, che il piano di prova usa per citarlo (capitolo 26):

```
-- Il comando che il pulsante invia alla lampada, con le forme concrete del pulsante a filo e di quello senza fili.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante comanda alla lampada di accendersi"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "Fra due accendi passano almeno 0,2 s"
                VERIFY BY INSPECTION "i comandi registrati"
END

BINDING Comando VERSION 0.1 AS filo
  STATUS HYPOTHESIS
  BIND accendi: VERBAL "contatto chiuso fra il morsetto 3 e il morsetto comune per almeno 50 ms"
END

BINDING Comando VERSION 0.1 AS radio
  STATUS HYPOTHESIS
  BIND accendi: VERBAL "un messaggio radio ACCENDI con il codice del pulsante, ripetuto tre volte in 30 ms"
END
```

```
$ bcdd check ComandoForme.csc
bcdd check ComandoForme.csc
righe: 21 (riconosciute 15, commenti 1, vuote 5, non riconosciute 0)
blocchi: 3
  riga 3: CSC Comando VERSION 0.1, STATUS HYPOTHESIS
  riga 13: BINDING Comando VERSION 0.1 AS filo, STATUS HYPOTHESIS
    riga 13: CSC Comando in questo file alla riga 3
  riga 18: BINDING Comando VERSION 0.1 AS radio, STATUS HYPOTHESIS
    riga 18: CSC Comando in questo file alla riga 3

1. ERRORI: 0
…
4. DA APPROVARE, NON CONTRATTO: 3
  riga 9: GUARANTEE c1
  riga 15: BIND accendi
  riga 20: BIND accendi
…
12. FORME CONCRETE MANCANTI: 0
  riga 13: BINDING Comando VERSION 0.1 AS filo: nessuna
  riga 18: BINDING Comando VERSION 0.1 AS radio: nessuna

esito: nessun errore
```

Nel file controllato, per due blocchi `BINDING` della stessa CSC e della stessa versione senza nome distintivo, o
con lo stesso nome distintivo, `bcdd` segnala l'errore E40.

### L'approvazione delle forme concrete

`bcdd ratify` approva un `BINDING` come una CSC: l'intestazione oppure, con `--all`, l'intestazione e le righe
`BIND` che hanno uno `STATUS HYPOTHESIS` proprio (`BIND elemento STATUS HYPOTHESIS: VERBAL "…"`). Le righe `BIND` non
hanno un nome breve, quindi non si approvano una per una. Il blocco da approvare si sceglie con `--csc NOME`, dove
`NOME` è il nome distintivo del `BINDING`. Senza `--csc`, in
un file che contiene una CSC, `ratify` sceglie la CSC:

```
$ bcdd ratify ComandoForme.csc --all D-21
approvate con D-21 nella CSC Comando: 1 riga
  riga 4: CSC Comando
contratto: 1
```

```
$ bcdd ratify ComandoForme.csc --csc filo --all D-21
approvate con D-21 nel BINDING Comando VERSION 0.1 AS filo: 1 riga
  riga 14: BINDING Comando VERSION 0.1 AS filo
contratto: 1
```

```
$ bcdd ratify ComandoForme.csc --csc radio accendi D-21
bcdd ratify: nel BINDING si approvano l'intestazione o --all, non una riga
```

Un `BINDING` senza nome distintivo, nello stesso file della sua CSC, non si sceglie con il nome della CSC: quel
nome designa la CSC. Per approvarlo con `ratify` gli si dà un nome con `AS`, oppure lo si scrive in un file
proprio, dove è l'unico blocco da approvare e `ratify` lo sceglie senza `--csc`.

L'approvazione riguarda le forme concrete del blocco, non le promesse della CSC legata, che si approvano a parte.

### Riepilogo

- Una **forma concreta** è ciò che chi sta al confine osserva o usa di un elemento di una CSC: un morsetto, un
  testo, un colore, un formato di file. Le forme concrete di un confine stanno in un blocco
  `BINDING … END`, distinto dalla CSC.
- La CSC stabilisce che un elemento esiste; le forme concrete stabiliscono come si presenta al confine.
- Il criterio è «chi lo vede?»: ciò che nessuno osserva al confine è realizzazione; ciò che si osserva in una
  forma modificabile senza cambiare il significato è forma concreta; ciò che cambia il significato sta nella CSC.
- Una forma concreta è vincolante quando la osserva o la usa qualcuno esterno alla realizzazione.
- Ogni riga `BIND elemento: VERBAL "…"` descrive la forma di un elemento della CSC legata; `bcdd` controlla che
  l'elemento esista (E31) ed elenca nella sezione 12 gli elementi senza forma concreta.
- Più blocchi per lo stesso confine hanno un nome distintivo, `AS nome` (in caso contrario: errore E40); il blocco
  da approvare si sceglie con `--csc nome`.

### Casi particolari

**Lo stesso relè su un altro confine.** Se la lampada è un modulo venduto con i contatti del relè portati sui
morsetti di uscita, a cui l'installatore collega le lampadine, l'installatore osserva e usa quei contatti. Quel
confine, fra il modulo e chi lo installa, è descritto da un'altra CSC, e su di esso il contatto del relè è una
forma concreta. Il criterio si applica confine per confine: lo stesso oggetto può essere realizzazione per chi sta
sulle scale e forma concreta per l'installatore.

**Un elemento che la CSC non dichiara.** Una riga `BIND spia: VERBAL "la spia verde del pulsante"` nomina un elemento
che `UsoLuce` non dichiara:

```
1. ERRORI: 1
  riga 7: [E31] spia non è un elemento della CSC UsoLuce VERSION 0.3
```

Se la CSC legata non si trova, o si trova soltanto in un'altra versione, il controllo degli elementi è sospeso: la
CSC compare nella sezione 7.

**Una riga `VERIFY` dopo una riga `BIND`.** Una forma concreta non si verifica come una promessa. Una riga `VERIFY`
scritta sotto una riga `BIND` è una riga a sé, non riconosciuta:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 8: VERIFY BY INSPECTION "la registrazione della lampada"
…
esito: nessun errore; righe non riconosciute: 1 (--strict)
```

**Una forma concreta scritta come promessa.** La forma concreta di `accendi` si può scrivere nella CSC come
promessa a parole, e `bcdd` la riconosce:

```
  GUARANTEE c2: VERBAL "Ogni accendi è un contatto chiuso fra il morsetto 3 e il morsetto comune per almeno 50 ms"
                VERIFY BY INSPECTION "il contatto registrato sul morsetto 3"
```

```
2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 2
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 9: GUARANTEE c1 verbale
  riga 11: GUARANTEE c2 verbale
```

La riga non va scritta nella CSC. Un pulsante che inviasse l'`accendi` via radio manterrebbe la promessa `c1`
ma non `c2`: per cambiare la forma servirebbe una versione nuova della CSC e una nuova approvazione, anche se il
comportamento resta lo stesso.

**Il blocco all'interno della CSC.** Un `BINDING` sta fuori da ogni altro blocco. Scritto prima della riga `END`
della CSC, interrompe la CSC, che resta senza `END`; la riga `END` della CSC non ha più un blocco aperto da
chiudere:

```
  BINDING Comando VERSION 0.1
  END
END
```

```
1. ERRORI: 2
  riga 3: [E07] blocco non chiuso: manca END di CSC Comando
  riga 14: [E08] END senza un blocco aperto
```

**Due blocchi senza nome distintivo.** Senza `AS filo` e `AS radio` i due blocchi di `Comando` non si distinguono:

```
1. ERRORI: 1
  riga 18: [E40] secondo BINDING senza nome per la CSC Comando VERSION 0.1: il primo è alla riga 13. Con due o più BINDING ognuno ha un nome, AS nome
```

**Forme concrete e realizzazione.** Le forme concrete descrivono soltanto ciò che si osserva a un confine. Il
percorso dei fili dentro la scatola, il tipo di relè o il programma di un temporizzatore elettronico sono
realizzazione e non compaiono in nessun blocco, neppure quando l'elettricista deve conoscerli per costruire
l'impianto.

---

## Capitolo 26 — Il piano di prova

Il capitolo 24 ha descritto gli esiti della verifica sulle registrazioni, il capitolo 25 il modo in cui ogni
elemento di un confine si presenta. Il piano di prova li mette in relazione: indica con quali mezzi si registra
un confine, con quale risoluzione, e quali promesse ciascun mezzo osserva.

`bcdd` legge il piano di prova, ne controlla i nomi e calcola quali promesse ciascun mezzo osserva. Nessun
programma descritto in questo manuale esegue un piano di prova né la verifica sulle registrazioni.

### Il piano di prova

Un **mezzo di registrazione** è uno strumento che registra ciò che accade a un confine attraverso le forme
concrete del confine: un registratore collegato a un morsetto, un sensore, una telecamera, un programma che
registra i messaggi di una rete. Anche uno strumento di prova incorporato nel sistema, come un'opzione di prova
di un programma, è un mezzo di registrazione; il modo di attivarlo è una forma concreta. Un mezzo **osserva**
ciò che registra: un elemento che nessun mezzo registra non è osservato.

La **risoluzione** di un mezzo è il più piccolo intervallo di tempo che il mezzo distingue.

Il **piano di prova** di un confine si scrive in un blocco `VERIFICATION … END`, la cui intestazione nomina la CSC
legata con la sua versione. Contiene:

1. i mezzi di registrazione, ciascuno con gli elementi della CSC che osserva e la sua risoluzione;
2. le storie scritte in forme concrete, ciascuna con la storia della CSC che traduce.

`bcdd` calcola le promesse che ciascun mezzo osserva e quelle che nessun mezzo osserva, che restano non eseguite. Il piano di prova non
contiene promesse e non contiene esiti: stabilisce come si raccolgono le registrazioni su cui le promesse si
verificano.

### I mezzi di registrazione della luce

Per la luce delle scale si usano due mezzi: un sensore di luce davanti alla lampada, con la risoluzione di un
millisecondo, e una telecamera che riprende insieme il pulsante e la lampada a 25 immagini al secondo, con la
risoluzione di 40 ms. Un registratore collegato fra il morsetto 3 e il morsetto comune osserva invece il confine
`Comando`, che ha un proprio piano di prova. Il piano di prova sta in un file proprio, `PianoLuce.csc`:

```
-- Il piano di prova della luce delle scale.

VERIFICATION UsoLuce VERSION 0.3
  MEANS sensore    OBSERVES modo, avviso RESOLUTION 1 ms
  MEANS telecamera OBSERVES premuto, modo RESOLUTION 40 ms
  SCENARIO s1-scale TRANSLATES s1
    @0 s     VERBAL "un dito preme il tasto del pulsante a muro; la lampada si accende"
    @85 s    VERBAL "la lampada si spegne per 0,3 s e si riaccende"
    @90 s    VERBAL "la lampada si spegne"
    @100 s   VERBAL "un dito preme di nuovo il tasto; la lampada si accende"
END

VERIFICATION Comando VERSION 0.1
  MEANS registratore OBSERVES accendi RESOLUTION 1 ms USING filo
END
```

Una riga `MEANS` dichiara un mezzo: il nome, gli elementi della CSC legata che osserva (`OBSERVES`) e la
risoluzione (`RESOLUTION`), una durata con unità. Con `USING` il mezzo nomina il `BINDING` attraverso cui osserva:
il registratore legge gli `accendi` nella forma del pulsante a filo, il blocco `AS filo` del capitolo 25. Il sensore
registra se la lampada è accesa o spenta, e le forme concrete del capitolo 25 stabiliscono come leggere la
registrazione: una lampada spenta per 0,3 s e poi di nuovo accesa è un `avviso`, una lampada spenta è
`modo = spenta`. La specifica lascia a chi realizza il sistema il modo di ottenere le tracce dalle registrazioni.

### Le promesse osservate da ciascun mezzo

Una promessa formale che cita un elemento non registrato ha l'esito **non eseguita** (capitolo 24). `bcdd` calcola,
per ogni mezzo, le promesse e i presupposti formali che quel mezzo osserva per intero: una riga è osservata da un
mezzo se ogni stato, evento e richiesta che nomina è fra i suoi elementi `OBSERVES`. Le righe che nessun mezzo
osserva per intero sono **non eseguite**. Le righe verbali non compaiono in questo calcolo: si verificano a giudizio o per ispezione.

```
$ bcdd check PianoLuce.csc
bcdd check PianoLuce.csc
righe: 15 (riconosciute 12, commenti 1, vuote 2, non riconosciute 0)
blocchi: 2
  riga 3: VERIFICATION UsoLuce VERSION 0.3
    riga 3: CSC UsoLuce in UsoLuce.csc alla riga 4: VERSION 0.3, STATUS HYPOTHESIS, nessun errore
  riga 13: VERIFICATION Comando VERSION 0.1
    riga 13: CSC Comando in Comando.csc alla riga 3: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 14: USING filo in Comando.csc alla riga 13

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 0
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 0

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

13. COPERTURA DEL PIANO DI PROVA: 4
  riga 3: VERIFICATION UsoLuce VERSION 0.3
    sensore (riga 4): g2, g8
    telecamera (riga 5): g1, g2, g2a, g7a, g9
    non eseguite: g3a, g4a, g4b, g10
  riga 13: VERIFICATION Comando VERSION 0.1
    registratore (riga 14): nessuna
    non eseguite: nessuna

esito: nessun errore
```

La sezione 13, «copertura del piano di prova», riporta il calcolo:

- il sensore osserva `g2` e `g8`, che riguardano soltanto il modo e l'avviso;
- la telecamera osserva `g1`, `g2`, `g2a`, `g7a` e `g9`, che riguardano la pressione e il modo;
- `g3a` riguarda la pressione, il modo e l'avviso, e nessun mezzo osserva da solo tutti e tre; `g4a`, `g4b` e
  `g10` riguardano le richieste di pulizie, che nessun mezzo registra. Queste promesse sono non eseguite.

Il conteggio della sezione è il numero delle promesse non eseguite. La sezione compare soltanto quando il file
contiene almeno un blocco `VERIFICATION`, e non è un errore. L'elenco delle promesse osservate non si scrive nel file: `bcdd` lo ricava
ogni volta dalle righe `OBSERVES`.

La sezione 13 elenca anche le promesse non eseguite. Un rapporto della verifica che le omettesse
lascerebbe intendere che sono state verificate.

Con il solo sensore, senza la telecamera, la pressione non è registrata da nessun mezzo:

```
13. COPERTURA DEL PIANO DI PROVA: 8
  riga 3: VERIFICATION UsoLuce VERSION 0.3
    sensore (riga 4): g2, g8
    non eseguite: g1, g2a, g3a, g4a, g4b, g7a, g9, g10
  riga 12: VERIFICATION Comando VERSION 0.1
    registratore (riga 13): nessuna
    non eseguite: nessuna
```

Il registratore rileva gli `accendi`, che seguono le pressioni, ma non le pressioni. Ricavare una pressione da
un `accendi` richiederebbe la promessa `pu1` del pulsante (capitolo 13), e una promessa non sostituisce
un'osservazione: per questo `g1` resta non eseguita finché nessun mezzo registra `premuto`.

### La risoluzione

La risoluzione limita la portata di un esito. «Rispettata sulla traccia» vale con la risoluzione dichiarata
del mezzo (capitolo 24): per `g2a`, che ammette uno spegnimento fra 85 e 95 secondi dopo l'ultima pressione,
una risoluzione di 40 ms è sufficiente. Per `g1`, che richiede la luce accesa nello stesso passo della pressione,
l'esito dipende dal criterio con cui, a partire dalla registrazione, si stabilisce che i due fatti cadono nello
stesso passo. Due
fatti registrati da mezzi diversi si considerano in passi distinti soltanto se la loro distanza supera la
risoluzione meno fine dei due mezzi. Altrimenti la relazione temporale è indeterminata: non si stabilisce se i
fatti stanno nello stesso passo o in passi distinti. Se un mezzo con la risoluzione di
40 ms registra la pressione a 10,000 s e un altro la luce accesa a 10,015 s, i due fatti non si distinguono e `g1` è inconclusiva in
quel passo; se la luce si accende a 10,200 s, `g1` è violata.

Un mezzo che distingue soltanto intervalli più lunghi della durata di una forma concreta non la osserva. Un
sensore di luce che rileva lo stato della lampada una volta al secondo può non rilevare un lampeggio di 0,3 s:
nel piano di prova `avviso` non figura fra gli elementi che quel sensore osserva, e `g8` ha l'esito «non
eseguita». Dichiarare `avviso` fra gli elementi osservati attribuirebbe a `g8` l'esito «rispettata sulla
traccia» anche su una registrazione in cui un avviso è sfuggito fra due rilevazioni. `bcdd` non confronta la
risoluzione con le forme concrete: la scelta degli elementi `OBSERVES` resta a chi scrive il piano.

### Le storie in forme concrete

Una **storia tradotta** riscrive una storia della CSC nelle forme concrete: `SCENARIO s1-scale TRANSLATES s1`
traduce la storia `s1` di `UsoLuce`. I suoi passi hanno i tempi della storia che traduce e contengono asserzioni a
parole (`VERBAL`). Non ha `GIVEN` né `EXPECT`: il suo esito atteso è quello della storia che traduce. Se la CSC
legata non ha la storia nominata, `bcdd` segnala l'errore E31.

Alcuni fatti che si presentano nelle forme concrete non compaiono nella storia della CSC, e su di essi una
realizzazione può comportarsi in modo errato. Un contatto di 30 ms sul morsetto 3, per esempio, non è un `accendi` (capitolo
25), e nella storia della CSC `Comando` non compare. Il piano di prova di `Comando` può allora contenere una storia
tradotta: «contatto chiuso per 30 ms all'istante 0 s, contatto chiuso per 80 ms all'istante 1 s». Questa storia
traduce una storia di `Comando` con un solo `accendi`, quello del secondo contatto. Una lampada che si accende già al primo
contatto tratta come `accendi` un contatto che non lo è: la storia tradotta permette di rilevarlo, mentre la storia
della CSC `Comando`, da sola, non contiene il contatto di 30 ms.

### Riepilogo

- Il **piano di prova** (`VERIFICATION Csc VERSION v … END`) indica i mezzi di registrazione di un confine e le
  storie in forme concrete. Non contiene promesse né esiti, e non si approva.
- Un **mezzo di registrazione** (`MEANS nome OBSERVES elementi RESOLUTION durata [USING forme]`) osserva un confine
  attraverso le forme concrete del confine; la sua **risoluzione** è il più piccolo intervallo di tempo che
  distingue.
- `bcdd` calcola nella sezione 13 le promesse formali che ciascun mezzo osserva per intero e quelle non
  eseguite; una promessa non sostituisce un'osservazione.
- «Rispettata sulla traccia» vale con la risoluzione del mezzo; un mezzo che distingue soltanto intervalli più
  lunghi della durata di una forma concreta non la osserva.
- Una storia tradotta (`SCENARIO id TRANSLATES storia`) riscrive una storia della CSC nelle forme concrete.

### Casi particolari

**Un piano di prova non si approva.** Per una riga `STATUS` in un blocco `VERIFICATION` `bcdd` segnala l'errore E39;
nello stesso file, per una storia tradotta che nomina una storia assente nella CSC segnala l'errore E31:

```
1. ERRORI: 2
  riga 4: [E39] STATUS non può stare in una VERIFICATION: un piano di prova non si approva
  riga 7: [E31] TRANSLATES nomina una storia che la CSC UsoLuce VERSION 0.3 non ha: s9
```

`bcdd ratify` rifiuta un file che contiene soltanto piani di prova:

```
$ bcdd ratify PianoLuce.csc --all D-22
bcdd ratify: il file non contiene nessun blocco da approvare: una VERIFICATION non si approva
```

**Un mezzo collegato all'interno di una parte.** Un registratore collegato ai morsetti che alimentano la
lampadina, dentro la lampada, registra la realizzazione e non un confine: nessuna promessa si può verificare su
quella registrazione. Il piano di prova associa ogni mezzo a un confine, attraverso le forme concrete del
confine.

**Una promessa verbale e il registratore.** La promessa `c1` di `Comando`, «fra due accendi passano almeno
0,2 s», si controlla per ispezione sui «comandi registrati»: la registrazione del registratore è il materiale
dell'ispezione. L'esito resta un giudizio, «conforme a giudizio» o «non conforme a giudizio», con chi ha
giudicato, e si riporta separato dagli esiti delle formule (capitolo 24). Per questo il registratore non osserva
nessuna promessa formale di `Comando`, e la sezione 13 lo riporta con `nessuna`.

**Più registrazioni della stessa promessa.** Una promessa rispettata su dieci registrazioni resta rispettata
su quelle dieci tracce, con la risoluzione dei mezzi usati: il numero delle registrazioni non trasforma l'esito
in una certezza sulle situazioni non osservate.

---

## Capitolo 27 — Estensioni e profili

Si vuole specificare che la luce, allo spegnimento, non si spegne istantaneamente ma si abbassa in due secondi.
Le parole chiave dei capitoli 21-23 non bastano. Il capitolo descrive come si dichiara una forma nuova, l'estensione,
con il suo significato e il modo di verificarla. Descrive poi come le estensioni di un campo d'uso si
raccolgono in un profilo, come una CSC lo importa, e che cosa sono le parole in prova.

### Una promessa che le parole chiave non esprimono

Gli stati di una CSC hanno un valore in ogni passo, e la formula li esamina un passo alla volta (capitolo 21).
«Entro 2 secondi la luce è spenta» si scrive con le parole chiave del capitolo 22. «Si abbassa senza salti», invece,
riguarda anche i valori fra un passo e il successivo, che una formula non esamina: la luminosità varia con
continuità nel tempo.

Una promessa di questo tipo si può scrivere in tre modi.

**A parole.** È sempre possibile:

```
  GUARANTEE g11: VERBAL "Allo spegnimento la luce non si spegne di colpo: si abbassa in due secondi"
                 VERIFY BY JUDGEMENT "una persona sulle scale che osserva lo spegnimento"
```

**Con un'estensione già scritta**, se ne esiste una adatta in un profilo.

**Con un'estensione nuova**, se non ne esiste nessuna.

### L'estensione

Un'**estensione** è una forma nuova del linguaggio, dichiarata in un blocco `EXTENSION Nome … END` insieme al suo
significato e al modo di verificarla; il termine non va confuso con l'estensione `.csc` del nome di un file.
Ha otto campi, uno per riga, in qualunque ordine:

| Campo | Obbligatorio | Contenuto |
|---|---|---|
| `KIND` | sì | dove si usa la forma (tabella seguente) |
| `LEVEL` | sì | in quale tipo di blocco si usa la forma, con la parola che apre il blocco: CSC (`CSC`), entità (`ENTITY`), forme concrete (`BINDING`), piano di prova (`VERIFICATION`); il campo non indica il livello di un dettaglio (capitolo 8) |
| `PARAMS` | sì, anche vuoto | i parametri della forma, fra parentesi, ciascuno con un tipo o una categoria |
| `FORM` | sì | la forma d'uso, fra virgolette: comincia con il nome dell'estensione e contiene ogni parametro una volta |
| `MEANING` | sì | il significato, a parole; se manca `REDUCES TO`, è il significato che vale |
| `REDUCES TO` | no | la forma estesa, scritta con le forme del linguaggio |
| `VERIFY` | sì | il modo di verifica |
| `SOURCE` | sì | da dove viene la forma: la promessa, la prova o la decisione che l'ha richiesta |

Il campo `KIND` ammette sei valori, scritti in maiuscolo:

| `KIND` | La forma si usa |
|---|---|
| `PATTERN` | come forma di una promessa intera, al posto di `ALWAYS` o di `WHENEVER … THEN` |
| `SCOPE` | come ambito, al posto di `WHILE` |
| `FUNCTION` | all'interno di una condizione, come `COUNT` o `PREV`; dopo `PARAMS` si scrive il tipo del risultato, `PARAMS (…) : Tipo` |
| `DECLARATION` | come riga che dichiara un elemento, come `STATE` |
| `RELATION` | come relazione, per esempio fra le CSC citate da un'entità |
| `SCENARIO-FORM` | all'interno di una storia |

Un parametro ha un tipo, come i parametri degli eventi, oppure una **categoria**, che indica che cosa si scrive al
suo posto: `Name` (un nome dichiarato), `Type` (un tipo), `Event` (un evento), `Condition` (una condizione),
`Expression` (un'espressione), `Duration` (una durata con unità), `Property` (una proprietà intera). Nel `FORM` una parola uguale al
nome di un parametro è il posto di quel parametro; ogni altro elemento è fisso e si scrive così com'è.

Nel campo `VERIFY` si scrivono due sigle. `V1` indica la verifica sul testo ed è seguita dalle sigle dei
controlli che si applicano, da `C1` a `C8`. `C1` è il controllo della forma, `C2` la coerenza, `C3` le storie, `C4`
la copertura, `C5` la regola «chi usa trova chi offre», `C6` le promesse d'entità, `C7` la realizzabilità, che la
specifica non prevede (capitolo 24), `C8` i dettagli. `V2`, dopo un punto e virgola, indica la verifica sulle
registrazioni ed è seguita, fra virgolette, da ciò che vale come osservazione. In alternativa il campo contiene `BY JUDGEMENT` o `BY INSPECTION`, come una
promessa verbale.

Un'estensione rispetta le regole seguenti:

- il suo nome è unico nel profilo e diverso da ogni parola chiave del linguaggio;
- non cambia il significato di alcuna parola chiave del linguaggio, e non dà un secondo nome a una forma che il
  linguaggio ha già: ogni termine ha un solo significato, e ogni significato un solo termine;
- `REDUCES TO` usa soltanto parole chiave del linguaggio, parametri o estensioni dello stesso profilo, senza
  rimandi circolari; se `MEANING` e `REDUCES TO` non coincidono, vale `REDUCES TO`;
- il `MEANING` non descrive la realizzazione e non dà a una parte autorità o precedenza su un'altra.

`bcdd` controlla le regole che riguardano la forma:

- un campo mancante, ripetuto o con un valore non ammesso, e un `FORM` non conforme (E33);
- un nome ripetuto o riservato (E34);
- una `REDUCES TO` che nomina ciò che non può nominare o che rimanda a se stessa in modo circolare (E35);
- una `REDUCES TO` che ripete una sola forma del linguaggio o un'altra estensione (E36).

Le regole che riguardano il significato si giudicano: il rapporto le elenca nella sezione 14.

### Il profilo

Un **profilo** è una raccolta di estensioni per un campo d'uso, con un nome e una versione:

```
PROFILE Nome VERSION v
  PURPOSE "il campo d'uso"
  STATUS HYPOTHESIS
  EXTENSION …
  END
  EXTENSION …
  END
END
```

Il profilo ha un `PURPOSE` e uno `STATUS`, in qualunque ordine, e contiene soltanto estensioni. Per un'estensione
scritta fuori da un profilo `bcdd` segnala l'errore E32. Una CSC usa un profilo con la riga
`IMPORT PROFILE Nome VERSION v`, nella sua intestazione. Per una CSC che non importa il profilo, le estensioni del profilo non sono disponibili, anche se il profilo sta nello
stesso file. Un profilo non importa altri profili. Chi possiede un profilo ne cura le versioni, e un'estensione vale
nella versione del profilo che la dichiara: una CSC che importa un'altra versione del profilo usa un'altra
estensione, anche se il nome è lo stesso. Anche un'entità, un `BINDING` e un piano di prova importano i profili,
ciascuno per proprio conto.

La specifica descrive due profili: `Protocollo`, per i protocolli di rete, e `Segnale`, per le grandezze che
variano con continuità. `Segnale` contiene, fra le altre, l'estensione `SIGNAL`, che dichiara una **grandezza
continua**, cioè una grandezza definita in ogni istante e non soltanto nei passi.

`bcdd` cerca il profilo importato come cerca una CSC citata (capitolo 15): nel file controllato, poi nel file
`Segnale.csc` della stessa cartella, poi nelle cartelle indicate con `--dir`. Il profilo è trovato soltanto se ha
la versione scritta nella riga `IMPORT PROFILE`.

### L'abbassamento graduale della luce

Il profilo `Segnale` non contiene una forma per l'abbassamento della luce. La forma nuova si aggiunge a `Segnale`
stesso, in una versione nuova, la 0.3, a cura di chi possiede il profilo:

```
-- Il profilo Segnale: grandezze che variano con continuità.
-- VERSION 0.3: aggiunta l'estensione FADE.

PROFILE Segnale VERSION 0.3
  PURPOSE "Grandezze che variano con continuità, misure sui campioni, risposta nel tempo"
  STATUS HYPOTHESIS

  EXTENSION SIGNAL
    KIND     DECLARATION
    LEVEL    CSC
    PARAMS   (nome: Name, T: Type)
    FORM     "SIGNAL nome : T"
    MEANING  "nome è una grandezza di tipo T, definita in ogni istante e non soltanto nei passi"
    VERIFY   V1 C1 ; V2 "registrazione continua della grandezza"
    SOURCE   "il profilo Segnale, versione 0.1"
  END

  EXTENSION FADE
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (s: Expression, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "In ogni tratto di passi consecutivi dell'ambito, s non risale e non salta, e vale 0
              entro d dal primo passo del tratto; se in quel passo s è maggiore di 0, non vale 0
              prima di 0,9 d"
    VERIFY   V1 C1 ; V2 "registrazione di s nel tempo; il rapporto dichiara la risoluzione del mezzo"
    SOURCE   "UsoLuce 0.4, promessa g11"
  END
END
```

`FADE` è una forma di promessa (`KIND PATTERN`) che si usa in una CSC (`LEVEL CSC`). Il parametro `s` è
un'espressione, `d` una durata. Il significato è scritto a parole e non ha forma estesa, perché «non salta» riguarda
i valori fra un passo e il successivo.

Il profilo, controllato da solo, non ha errori:

```
$ bcdd check Segnale.csc
bcdd check Segnale.csc
righe: 29 (riconosciute 24, commenti 2, vuote 3, non riconosciute 0)
blocchi: 1
  riga 4: PROFILE Segnale VERSION 0.3, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 0
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 2
  riga 8: EXTENSION SIGNAL
  riga 18: EXTENSION FADE

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

14. DA GIUDICARE: 4
  riga 8: EXTENSION SIGNAL: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti
  riga 8: EXTENSION SIGNAL: non ripete una forma che il linguaggio ha già
  riga 18: EXTENSION FADE: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti
  riga 18: EXTENSION FADE: non ripete una forma che il linguaggio ha già

esito: nessun errore
```

Le due estensioni sono da approvare, come il profilo, e compaiono nella sezione 4. La sezione 14 elenca per
ciascuna le regole da giudicare: che il significato non descriva la realizzazione, e che un'estensione senza
`REDUCES TO` non ripeta una forma che il linguaggio ha già.

La CSC `UsoLuce` passa alla versione 0.4, da approvare. Importa il profilo, dichiara la luminosità e aggiunge la
promessa `g11`:

```
CSC UsoLuce VERSION 0.4
  STATUS HYPOTHESIS
  IMPORT PROFILE Segnale VERSION 0.3
…
  STATE      modo : Modo INITIAL spenta
  STATE      luminosita : Real [0.0 .. 1.0] INITIAL 0.0
…
  -- g11: «Allo spegnimento la luce non si spegne di colpo: si abbassa in due secondi»
  GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s
```

Si legge: in ogni tratto in cui la luce è spenta, dal primo passo del tratto la luminosità scende senza salti e
senza risalire, e arriva a 0 fra 1,8 e 2 secondi dopo; se all'inizio del tratto è già 0, resta 0. Con
l'abbassamento cambiano anche le forme concrete del capitolo 25: `modo = spenta` vale dal momento in cui la
luce comincia ad abbassarsi, e la luminosità è il livello della luce emessa dalla lampada, da 0 (spenta) a 1
(piena). La luminosità è dichiarata come uno stato; il caso particolare «Una grandezza dichiarata con `SIGNAL`»
mostra la dichiarazione come grandezza continua.

Nel rapporto il profilo trovato compare sotto la riga della CSC, e `g11` ha un grado nuovo:

```
$ bcdd check UsoLuce.csc
bcdd check UsoLuce.csc
righe: 69 (riconosciute 58, commenti 6, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.4, STATUS HYPOTHESIS
    riga 6: IMPORT PROFILE Segnale in Segnale.csc alla riga 4: VERSION 0.3, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
…
  riga 42: GUARANTEE g10 formale
  riga 49: GUARANTEE g11 estensione dichiarata
  riga 50: ASSUME a1 verbale
```

`bcdd` riconosce l'uso di `FADE` dalla posizione, quella di una forma di promessa, e lo confronta con il `FORM`:
`luminosita` occupa il posto di `s`, `2 s` quello di `d`. Per un uso che non rispetta il `FORM`, o che sta in una
posizione o in un blocco diversi da quelli dichiarati da `KIND` e `LEVEL`, `bcdd` segnala l'errore E37.

### Il grado di una promessa scritta con un'estensione

Il grado di una promessa scritta con un'estensione dipende dall'estensione:

- se l'estensione ha `REDUCES TO`, è un'abbreviazione (capitolo 23): la promessa ha grado **formale**, e il suo
  significato è la forma estesa;
- se l'estensione non ha `REDUCES TO`, la promessa ha grado **estensione dichiarata**: il suo significato è il
  `MEANING`, e si verifica come dichiara il campo `VERIFY`.

Se il `VERIFY` dichiara un'osservazione (`V2`), una promessa di grado estensione dichiarata ha, sulle
registrazioni, esiti dello stesso tipo di quelli delle promesse formali, e gli esiti riportano anche il nome
dell'estensione. Se il `VERIFY` dichiara un giudizio o un'ispezione, ha invece gli esiti delle promesse
verbali. Nel rapporto di una verifica i tre gradi stanno in sezioni separate, e i loro esiti non si sommano
(capitolo 24).

`g11` ha grado estensione dichiarata, e il `VERIFY` di `FADE` dichiara un'osservazione: la registrazione della
luminosità nel tempo. Per osservarla, il piano di prova del capitolo 26 deve comprendere un mezzo che registri
la luminosità, e non soltanto se la lampada è accesa o spenta.

### L'approvazione con un profilo da approvare

Una promessa che usa un'estensione di un profilo da approvare è da approvare, anche in una CSC approvata: il
significato dell'estensione non è ancora stato approvato. `bcdd ratify --all` approva la CSC e lascia da approvare
`g11`, e lo segnala:

```
$ bcdd ratify UsoLuce.csc --all D-23
approvate con D-23 nella CSC UsoLuce: 6 righe
  riga 5: CSC UsoLuce
  riga 23: GUARANTEE g2a
  riga 28: GUARANTEE g3a
  riga 31: GUARANTEE g4a
  riga 32: GUARANTEE g4b
  riga 39: GUARANTEE g7a
contratto: 17
righe ancora da approvare: 1
  riga 49: GUARANTEE g11
```

Il profilo si approva per intero, con le sue estensioni, che non hanno uno stato proprio:

```
$ bcdd ratify Segnale.csc D-24
approvato il PROFILE Segnale VERSION 0.3 (riga 4) con D-24
estensioni: 2
```

Approvato il profilo, `g11` segue lo stato della CSC, che è approvata:

```
bcdd check UsoLuce.csc
righe: 69 (riconosciute 58, commenti 6, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.4, STATUS RATIFIED BY D-23
    riga 6: IMPORT PROFILE Segnale in Segnale.csc alla riga 4: VERSION 0.3, STATUS RATIFIED BY D-24, nessun errore
…
4. DA APPROVARE, NON CONTRATTO: 0
```

Se il profilo sta nello stesso file della CSC, il profilo si sceglie con `--csc Segnale`; senza `--csc`, `ratify`
sceglie la CSC.

### Le parole in prova

Alcune parole chiave del linguaggio sono **in prova**: si usano come le altre, ma una revisione futura del linguaggio
può spostarle in un profilo, come estensioni con lo stesso nome, la stessa forma e lo stesso significato. Fra
quelle descritte in questo manuale sono in prova `TYPE` (capitolo 6), `GIVEN` (capitolo 9), `VARIANT`
(capitolo 20), `PREV` (capitolo 22) e `CHANGED` (capitolo 23).

Se una parola in prova passa in un profilo, una CSC che la usa resta valida con l'aggiunta della
riga `IMPORT PROFILE` di quel profilo. In una CSC approvata l'aggiunta è una modifica come le altre e richiede una
versione nuova (capitolo 10). La parola resta riservata anche nelle CSC che non importano il profilo: non può
diventare il nome di un elemento.

In senso inverso, una forma usata con lo stesso significato in più campi d'uso indipendenti può entrare fra le
parole chiave del linguaggio. La decisione spetta a chi cura il linguaggio.

### Riepilogo

- Un'**estensione** dichiara una forma nuova con otto campi, tutti obbligatori tranne `REDUCES TO`: fra questi
  la forma (`FORM`), il significato (`MEANING`), il modo di verifica (`VERIFY`) e l'origine (`SOURCE`).
- Un'estensione non cambia il significato di alcuna parola chiave del linguaggio, e il suo significato non descrive la
  realizzazione; `bcdd` controlla la forma dei campi (E33-E36) ed elenca nella sezione 14 le regole da giudicare.
- Un **profilo** raccoglie le estensioni di un campo d'uso, con una versione; una CSC lo usa con
  `IMPORT PROFILE`, e `bcdd` lo cerca con la versione scritta.
- `bcdd` riconosce l'uso di un'estensione dalla posizione e lo confronta con il `FORM` (E37).
- Con `REDUCES TO` una promessa scritta con l'estensione è formale; senza, ha grado **estensione dichiarata**,
  e si verifica come dichiara il `VERIFY`.
- Una promessa che usa un profilo da approvare resta da approvare finché il profilo non è approvato.
- Alcune parole chiave sono **in prova**: una revisione può spostarle in un profilo, e una CSC che le usa resta valida
  con `IMPORT PROFILE`.

### Casi particolari

**Una grandezza dichiarata con `SIGNAL`.** Un'estensione di `KIND DECLARATION` si usa come prima parola di una
riga che dichiara un nome. Con l'estensione `SIGNAL` del profilo la luminosità si dichiara come grandezza continua:

```
  SIGNAL     luminosita : Real [0.0 .. 1.0]
```

La riga dichiara il nome `luminosita`, che entra nell'elenco dei nomi della CSC e si usa nelle formule come uno
stato, senza controllo del tipo. Con questa riga al posto della riga `STATE`, il rapporto della versione 0.4 è il
seguente:

```
1. ERRORI: 0
…
5. RIGHE NON RICONOSCIUTE: 0
```

Gli usi delle estensioni di `KIND RELATION` e `KIND SCENARIO-FORM` non sono letti da `bcdd` 1.0-beta: la riga che li
contiene è non riconosciuta e compare nella sezione 5; con `--strict` `bcdd` esce con il codice 3.

**Il profilo in un'altra versione.** Se nella cartella c'è soltanto la versione 0.2 di `Segnale`, il profilo
importato non è trovato. La sezione 7 lo riporta, con la versione trovata, e la promessa che usa `FADE` non è
riconosciuta; il rapporto ne indica il motivo:

```
5. RIGHE NON RICONOSCIUTE: 1
  riga 49: GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s (profilo Segnale VERSION 0.3 non trovato)
…
7. CSC NOMINATE E NON CONTROLLATE: 1
  riga 6: PROFILE Segnale (trovata solo la VERSION 0.2 in Segnale.csc)
…
esito: nessun errore; righe non riconosciute: 1 (vedi sezione 5)
```

Non è un errore: il nome `FADE` potrebbe essere definito proprio nella versione mancante. Con `--strict` `bcdd`
esce con il codice 3.

**L'estensione dentro la CSC.** Un'estensione si dichiara in un profilo. Se è scritta all'interno della CSC,
`bcdd` segnala l'errore E32. Le sue righe, compresa la riga `END`, non sono riconosciute; quella riga `END` chiude
l'estensione e non la CSC. Senza la riga
`IMPORT PROFILE` la promessa che usa `FADE` è anch'essa non riconosciuta:

```
1. ERRORI: 1
  riga 49: [E32] EXTENSION fuori da un PROFILE: un'estensione si dichiara in un profilo
…
5. RIGHE NON RICONOSCIUTE: 10
  riga 48: GUARANTEE g11: WHILE modo = spenta: FADE luminosita WITHIN 2 s
  riga 49: EXTENSION FADE
  riga 50: KIND     PATTERN
  riga 51: LEVEL    CSC
  riga 52: PARAMS   (s: Expression, d: Duration)
  riga 53: FORM     "FADE s WITHIN d"
  riga 54: MEANING  "s scende senza risalire e senza salti, e vale 0 entro d"
  riga 55: VERIFY   V1 C1 ; V2 "registrazione di s nel tempo"
  riga 56: SOURCE   "UsoLuce 0.4, promessa g11"
  riga 57: END
```

**Un campo non conforme.** Il valore di `KIND` si scrive in maiuscolo, e `SOURCE` è obbligatorio:

```
1. ERRORI: 2
  riga 18: [E33] manca il campo SOURCE nell'EXTENSION FADE
  riga 19: [E33] valore di KIND non ammesso: pattern
```

**Un uso che non rispetta la forma.** Senza `WITHIN 2 s` l'uso `GUARANTEE g11: WHILE modo = spenta: FADE luminosita`
non rispetta il `FORM`:

```
1. ERRORI: 1
  riga 49: [E37] uso di FADE che non rispetta FORM "FADE s WITHIN d"
```

**Una forma che il linguaggio già esprime.** Prima di scrivere un'estensione si controlla se la promessa si
può esprimere con le parole chiave del linguaggio. Un'estensione `MAI` con il significato di `NEVER` (capitolo
23) darebbe due nomi alla stessa cosa e non rispetterebbe la seconda regola delle estensioni. Se l'estensione ha
`REDUCES TO`, il controllo è automatico: la forma estesa di `MAI p` è `NEVER p`, e `bcdd` la segnala.

```
    REDUCES TO NEVER p
```

```
1. ERRORI: 1
  riga 36: [E36] l'EXTENSION MAI ripete una forma che il linguaggio ha già: NEVER
```

Se l'estensione non dichiara `REDUCES TO`, il controllo spetta a una persona: è una voce della sezione 14.

**Un'estensione che descrive la realizzazione.** Un `MEANING` come «all'apertura del relè un condensatore
mantiene la lampada accesa per 2 secondi» descrive come la lampada è costruita, non che cosa si osserva, e non
rispetta le regole delle estensioni. `bcdd` non legge il significato: la regola è una voce della sezione 14, che
una persona giudica. La forma nuova descrive la luminosità che chi sta sulle scale osserva, come `FADE`; il modo di
ottenerla resta a chi realizza la lampada.

**`IMPORT PROFILE` prima di `STATUS`.** Le righe `STATUS`, `IMPORT PROFILE` e `PURPOSE` seguono la riga `CSC`,
prima del corpo della CSC, e si possono scrivere in qualunque ordine. In una versione con `IMPORT PROFILE` prima
di `STATUS RATIFIED BY D-20`, la CSC risulta approvata; restano da approvare i dettagli senza uno `STATUS` proprio e
`g11`, che usa il profilo da approvare:

```
bcdd check UsoLuce.csc
righe: 69 (riconosciute 58, commenti 6, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.4, STATUS RATIFIED BY D-20
    riga 5: IMPORT PROFILE Segnale in Segnale.csc alla riga 4: VERSION 0.3, STATUS HYPOTHESIS, nessun errore
…
4. DA APPROVARE, NON CONTRATTO: 6
  riga 23: GUARANTEE g2a
  riga 28: GUARANTEE g3a
  riga 31: GUARANTEE g4a
  riga 32: GUARANTEE g4b
  riga 39: GUARANTEE g7a
  riga 49: GUARANTEE g11
```

Per una seconda riga `STATUS` nell'intestazione `bcdd` segnala invece l'errore E10, come per un secondo `PURPOSE`. Con
`STATUS HYPOTHESIS` subito dopo la riga `CSC` e `STATUS RATIFIED BY D-20` dopo `IMPORT PROFILE`, il rapporto
segnala come errore la seconda e tiene valida la prima:

```
bcdd check UsoLuce.csc
righe: 70 (riconosciute 59, commenti 6, vuote 5, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.4, STATUS HYPOTHESIS
    riga 6: IMPORT PROFILE Segnale in Segnale.csc alla riga 4: VERSION 0.3, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 1
  riga 7: [E10] STATUS ripetuto: il primo è alla riga 5
```

---

## Capitolo 28 — Un caso reale: il kit di misura audio

I capitoli precedenti usano un esempio piccolo, costruito per introdurre una forma alla volta. Questo capitolo
esamina la descrizione di un sistema reale, un kit di misura audio, e il rapporto che `bcdd` produce su di essa.
Non introduce forme nuove: ogni elemento rimanda al capitolo in cui è descritto.

### Il sistema

Il kit si aggiunge a un sistema di ascolto composto da una sorgente, un amplificatore e i diffusori. Il segnale
musicale, che nei file si chiama «programma», passa dalla sorgente al computer del kit e da questo
all'amplificatore. Il computer è un Raspberry Pi 4 con un programma di elaborazione audio, abbreviato AP nei
file. Il kit misura la risposta acustica della stanza e ne ricava una correzione per il segnale musicale; durante
l'ascolto rileva il livello inviato ai diffusori.

AP funziona in tre modalità, Misure, Calcolo e Riproduzione, che si scelgono dalla finestra di AP o dal
telefono. Nel passaggio da una modalità all'altra l'utente sposta a mano i cavi fra i due ingressi della scheda
che cattura i segnali, l'ingresso L e l'ingresso R.

Il kit esiste in due modelli, 1.a e 1.b; il capitolo esamina il modello 1.b, che usa due schede audio. La scheda
del flusso trasporta il segnale di programma; la scheda di cattura riceve i segnali del microfono di misura, del
sensore di livello e del riferimento. Per il sensore di livello le scelte sono due. La prima è una **direct
box** (nei file DI): un piccolo apparecchio che preleva il segnale dai morsetti di uscita
dell'amplificatore, ai quali sono collegati i diffusori, e lo porta alla scheda di cattura. La seconda è lo
stesso microfono di misura, che dopo le misure si sposta vicino a un diffusore. Nella prima scelta la direct box è una
parte facoltativa: senza di essa la funzione Loudness di AP, che dipende dal sensore di livello, non è
utilizzabile, mentre il resto del kit funziona.

### La descrizione

La descrizione è composta da più file, ciascuno con una CSC o un'entità (capitoli 2 e 12). Le CSC descrivono i confini: per
esempio `Modalita`, la scelta della modalità; `Ricablaggio`, i cavi che l'utente sposta fra una modalità e
l'altra; `Morsetti`, l'uscita dell'amplificatore ai morsetti dei diffusori. Le entità descrivono gli apparecchi:
il computer, le due schede, il microfono, la direct box, il cavo che riporta il riferimento. L'entità `Kit1b` descrive
il kit nel suo insieme; l'entità `Impianto1b` descrive il kit insieme agli apparecchi dell'utente.

La direct box è un'entità con un confine usato e uno offerto (capitolo 12):

```
-- La direct box svolge il rilevamento del livello d'uscita ai morsetti di un diffusore passivo.
-- La direct box usata come riferimento in Misure è un'altra funzione, Riferimento: non descritta qui.
-- Rinviati: attacchi, attenuatori, livelli massimi, alimentazione phantom o a pila.
-- Fonti: modello del sistema, sezioni sulla direct box; indicazioni dell'operatore.

ENTITY DirectBox VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La direct box del kit: legge il segnale ai morsetti di un diffusore e lo porta alla scheda di cattura come sensore di livello"
  USES   Morsetti
  OFFERS SegnaleLivello
  GUARANTEE di1 STATUS RATIFIED BY D-20: VERBAL "Il livello d'uscita della DI è il livello ai morsetti meno l'attenuazione scelta: l'attenuatore si sceglie in base all'ingresso che la riceve (fonte: modello del sistema, sezione sulla direct box; indicazione dell'operatore)"
                 VERIFY BY JUDGEMENT "l'operatore, che confronta il livello letto con due posizioni dell'attenuatore"
  GUARANTEE di2 STATUS RATIFIED BY D-20: VERBAL "La DI esce con un segnale sostanzialmente di linea, spesso bilanciato, e può entrare anche in un ingresso di linea (fonte: indicazione dell'operatore)"
                 VERIFY BY INSPECTION "la scheda della DI"
END
```

Il file applica alcune convenzioni adottate in tutta la descrizione del kit. I commenti in testa indicano le
fonti dei fatti e ciò che il file non descrive; nei file riportati qui le fonti sono indicate in forma generica.
Ogni promessa riporta la propria fonte fra parentesi, all'interno del testo fra virgolette. `bcdd` non interpreta
quel testo (capitolo 2): le fonti sono quindi destinate a chi legge e a chi approva.

Le promesse sono approvate una per una con la decisione `D-20`, mentre l'intestazione resta `STATUS
HYPOTHESIS`: in un'entità non si approva l'intestazione, ma soltanto le singole promesse (capitolo 12). Le
CSC del kit seguono lo stesso schema: le promesse hanno uno `STATUS` proprio (capitolo 7).

Gli attacchi, gli attenuatori, i livelli massimi e l'alimentazione della direct box, citati nel terzo commento, sono
elementi che chi sta al confine osserva o usa, cioè forme concrete (capitolo 25); la descrizione del kit non
le contiene ancora.
L'alimentazione può essere phantom (fornita dalla scheda attraverso il cavo) o a pila.

### L'entità del kit

L'estratto seguente riporta le righe principali di `Kit1b.csc`. Le righe omesse sono indicate con `…`; i
numeri di riga del rapporto si riferiscono al file intero.

```
ENTITY Kit1b VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il kit per il passthrough DSP su Raspberry Pi 4 con due schede: una porta il programma, l'altra cattura microfono, sensore di livello e riferimento"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS Ricablaggio
  OFFERS RilevamentoLivello
  USES   Programma
  USES   IngressoAmplificatore
  COMPOSED OF
    computer  : Calcolatore1b
    flusso    : SchedaFlusso
    cattura   : SchedaCattura
    loop      : CavoLoop
  …
  GUARANTEE k4 STATUS RATIFIED BY D-20: VERBAL "Il programma passa dall'ingresso all'uscita con al più 100 ms di ritardo (fonte: requisito del kit, indicato dall'operatore)"
                VERIFY BY JUDGEMENT "l'operatore, che misura il ritardo fra l'ingresso della scheda del flusso e la sua uscita"
  …
  VARIANT sensore = di
    USES   Morsetti
    COMPOSED OF
      microfono : MicrofonoMisura
      di        : DirectBox [0 .. 1]   -- senza DI niente Loudness (rl3)
  …
    SCENARIO k-s2 EXPECT REJECTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.collega(ingresso: ingresso_R, ospite: loop)
      @5 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: di)
      @10 s    Modalita.scegli(modalita: misure)
      @10 s    Modalita.attiva(modalita: misure)
  VARIANT sensore = microfono
    COMPOSED OF
      microfono : MicrofonoMisuraELivello   -- un solo dispositivo, due funzioni in fasi diverse
  …
END
```

Nell'estratto ricompaiono le forme della parte seconda:

| Nel file | Che cosa descrive | Capitolo |
|---|---|---|
| `OFFERS`, `USES` | i confini del kit: cinque offerti, due usati | 12 |
| `COMPOSED OF` | le parti comuni a ogni forma del kit | 13 |
| `VARIANT sensore = di`, `VARIANT sensore = microfono` | il gruppo di scelte del sensore di livello | 20 |
| `di : DirectBox [0 .. 1]` | la direct box, parte facoltativa nella sola scelta `di` | 19 |
| `USES Morsetti` nel segmento `sensore = di` | un confine usato solo con quella scelta | 20 |
| `GUARANTEE k4` | una promessa d'entità, a parole | 12 |
| `SCENARIO k-s2` | una storia d'entità, con il nome della CSC davanti a ogni nome | 18 |

La storia `k-s2` descrive il microfono e la direct box collegati contemporaneamente all'ingresso L, e deve essere
respinta. La regola è espressa dalla promessa `ri1` della CSC `Ricablaggio`: l'ingresso L ospita un solo
dispositivo per volta. La storia è scritta nel segmento `sensore = di` perché nomina la direct box, presente soltanto
con quella scelta.

Nella scelta `microfono` lo stesso microfono svolge due funzioni in modalità diverse: misura la stanza in
Misure e fa da sensore di livello in Riproduzione. Il linguaggio non prevede una forma per una parte che svolge
una funzione soltanto in certe modalità (capitolo 19). La descrizione tratta quindi il microfono di questa scelta
come un'entità a sé, `MicrofonoMisuraELivello`, che offre entrambi i segnali, anche se il dispositivo fisico è
uno solo. La decisione è dichiarata nei commenti del file. Per la stessa ragione il telefono, necessario soltanto nella
Taratura, una procedura della Riproduzione, compare in `Impianto1b` come parte sempre presente.

### Il rapporto

```
$ bcdd check --strict Kit1b.csc
bcdd check --strict Kit1b.csc
righe: 123 (riconosciute 104, commenti 18, vuote 1, non riconosciute 0)
blocchi: 1
  riga 5: ENTITY Kit1b VERSION 0.2, STATUS HYPOTHESIS
    riga 8: OFFERS Modalita in Modalita.csc alla riga 8: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 9: OFFERS Misura in Misura.csc alla riga 5: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 10: OFFERS LetturaLivello in LetturaLivello.csc alla riga 6: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 11: OFFERS Ricablaggio in Ricablaggio.csc alla riga 8: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 12: OFFERS RilevamentoLivello in RilevamentoLivello.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 13: USES Programma in Programma.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 14: USES IngressoAmplificatore in IngressoAmplificatore.csc alla riga 5: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 16: computer : Calcolatore1b in Calcolatore1b.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 17: flusso : SchedaFlusso in SchedaFlusso.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 18: cattura : SchedaCattura in SchedaCattura.csc alla riga 6: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 19: loop : CavoLoop in CavoLoop.csc alla riga 5: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 43: USES Morsetti in Morsetti.csc alla riga 7: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 45: microfono : MicrofonoMisura in MicrofonoMisura.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 46: di : DirectBox in DirectBox.csc alla riga 6: VERSION 0.1, STATUS HYPOTHESIS, nessun errore
    riga 88: microfono : MicrofonoMisuraELivello in MicrofonoMisuraELivello.csc alla riga 7: VERSION 0.1, STATUS HYPOTHESIS, nessun errore

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 5
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 20: GUARANTEE k1 verbale
  riga 22: GUARANTEE k2 verbale
  riga 24: GUARANTEE k4 verbale
  riga 47: GUARANTEE k3 verbale
  riga 89: GUARANTEE km2 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 0

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

8. USI DENTRO LE ENTITÀ: 11
  riga 16: computer usa AudioUsb: la offrono flusso (riga 17), cattura (riga 18)
  riga 17: flusso usa Programma: la usa Kit1b da fuori (riga 13)
  riga 17: flusso usa IngressoAmplificatore: la usa Kit1b da fuori (riga 14)
  riga 18: cattura usa SegnaleMisura: la offre microfono (riga 45) (in: sensore = di)
  riga 18: cattura usa SegnaleMisura: la offre microfono (riga 88) (in: sensore = microfono)
  riga 18: cattura usa SegnaleLivello: la offre di (riga 46) (in: con di)
  riga 18: cattura usa SegnaleLivello: nessuno la offre (in: senza di)
  riga 18: cattura usa SegnaleLivello: la offre microfono (riga 88) (in: sensore = microfono)
  riga 18: cattura usa Riferimento: la offre loop (riga 19)
  riga 19: loop usa UscitaAnalogica: la offre flusso (riga 17)
  riga 46: di usa Morsetti: la usa Kit1b da fuori (riga 43) (in: con di)

9. COMPOSIZIONI: 3
  riga 5: ENTITY Kit1b: 3
    sensore = di, con di
    sensore = di, senza di
    sensore = microfono

10. ASSENZE DICHIARATE: 2
  riga 18: senza di: la parte cattura usa il connettore SegnaleLivello: nessun'altra parte di Kit1b lo offre, né Kit1b lo usa da fuori
  riga 43: senza di: il connettore pubblico Morsetti di Kit1b (usato) non è affidato a nessuna parte

esito: nessun errore
```

Il rapporto si legge con le regole dei capitoli precedenti.

In cima, sotto il blocco `ENTITY Kit1b`, `bcdd` elenca i confini e le parti citati, ciascuno con il
file, la versione, lo `STATUS` e l'esito del controllo (capitoli 12 e 13). Delle parti `bcdd` legge soltanto
le righe `OFFERS` e `USES`; le loro parti e le CSC che citano si controllano nei rispettivi file (capitolo 13).

La sezione 2 elenca cinque promesse d'entità, tutte a parole: la descrizione del kit non usa le formule della
parte terza. La
sezione 4 è vuota perché ogni promessa ha il proprio `STATUS RATIFIED BY D-20`.

La sezione 8 mostra la regola «chi usa trova chi offre» (capitolo 13) applicata a ogni composizione. La prima
voce mostra che la parte `computer` usa `AudioUsb`, offerto da due parti: la scheda del flusso e la scheda di
cattura. La regola richiede che ogni confine usato sia offerto da almeno una parte; che due parti offrano lo
stesso confine non è un errore. Le voci con il suffisso `(in: …)` valgono soltanto nelle composizioni indicate
(capitolo 19).

La sezione 9 elenca tre composizioni, non quattro. Il gruppo `sensore` ha due scelte, e la direct box facoltativa
raddoppia soltanto le composizioni della scelta `di`, perché compare nel segmento di quella scelta (capitoli 19
e 20).

La sezione 10 elenca due assenze dichiarate, entrambe nella composizione senza la direct box. Senza la direct box nessuna parte
offre `SegnaleLivello` alla scheda di cattura, e `Morsetti`, che il kit usa dall'esterno in quella scelta, non è
affidato a nessuna parte. Le due assenze corrispondono agli errori E14 ed E16 del capitolo 13. Qui non sono
segnalate come errori perché la parte mancante è facoltativa; con la direct box presente entrambe scompaiono. Nella
composizione `sensore = microfono` il segnale di livello è offerto dal microfono, e non manca nulla.

### Il kit dentro il sistema di ascolto

L'entità `Impianto1b` contiene il kit come parte, `kit : Kit1b`, insieme alla sorgente, all'amplificatore, ai
diffusori e al telefono. Le scelte del kit compaiono nelle sue composizioni, precedute dal nome della parte
(capitolo 20):

```
8. USI DENTRO LE ENTITÀ: 6
  riga 12: kit usa Programma: la offre sorgente (riga 13)
  riga 12: kit usa IngressoAmplificatore: la offre amplificatore (riga 14)
  riga 12: kit usa Morsetti: la offre amplificatore (riga 14) (in: kit.sensore = di)
  riga 15: diffusori usa Morsetti: la offre amplificatore (riga 14)
  riga 16: telefono usa Modalita: la offre kit (riga 12)
  riga 16: telefono usa LetturaLivello: la offre kit (riga 12)

9. COMPOSIZIONI: 2
  riga 4: ENTITY Impianto1b: 2
    kit.sensore = di
    kit.sensore = microfono

10. ASSENZE DICHIARATE: 0
```

Le composizioni sono due: dall'esterno si distinguono soltanto le scelte del gruppo `sensore` del kit, mentre la
sua parte facoltativa non genera composizioni distinte (capitolo 20).
Il kit usa `Morsetti` solo con la scelta `di`, e nel sistema di ascolto lo offre l'amplificatore.

### I limiti del rapporto

Il rapporto conferma che i file sono scritti correttamente e che, in ogni composizione, ogni confine usato è
offerto da una parte, salvo le assenze dichiarate. Non attesta altro:

- non stabilisce se le storie sono effettivamente ammesse o respinte: per `k-s2` controlla soltanto che i nomi
  usati esistano nelle CSC citate (capitoli 9 e 18);
- non valuta il testo delle promesse né le fonti indicate fra virgolette: la correttezza dei fatti è
  responsabilità di chi ha scritto la descrizione e di chi l'ha approvata (capitolo 7);
- non controlla le promesse sul kit costruito: per farlo servono le forme concrete e un piano di prova
  (capitoli 25 e 26), e la verifica sulle registrazioni (capitolo 24). Nessun programma descritto nel manuale
  esegue questa verifica.

### Riepilogo

- Un sistema reale si descrive con le stesse forme dell'esempio della luce: CSC per i confini, entità per gli
  apparecchi, parti, varianti e parti facoltative.
- Ogni promessa riporta la propria fonte nel testo; `bcdd` non la interpreta.
- Il rapporto controlla ogni composizione, elenca le assenze dichiarate e non giudica i fatti.
- Ciò che il linguaggio non esprime, come una parte che opera soltanto in certe modalità, si risolve con una
  decisione di chi scrive la descrizione, dichiarata nei commenti.

### Casi particolari

**Una scelta con la parte errata.** Se nella scelta `sensore = microfono` si scrive per errore la parte
`microfono : MicrofonoMisura`, che offre soltanto il segnale di misura, nessuna parte offre il segnale di
livello alla scheda di cattura:

```
1. ERRORI: 1
  riga 18: [E14] la parte cattura usa il connettore SegnaleLivello: nessun'altra parte di Kit1b lo offre, né Kit1b lo usa da fuori (in: sensore = microfono)
```

Nella composizione senza la direct box la stessa mancanza resta un'assenza dichiarata, perché è giustificata dalla
parte facoltativa; nella scelta `microfono` nessuna parte facoltativa la giustifica, e la mancanza è un errore.
La sezione 8 riunisce le due composizioni interessate in una sola voce, separandole con `;`:

```
  riga 18: cattura usa SegnaleLivello: nessuno la offre (in: sensore = di, senza di; sensore = microfono)
```

---

## Capitolo 29 — Il procedimento completo, dall'inizio alla fine

Il capitolo scrive dall'inizio la CSC della luce delle scale, usando in sequenza i quattro comandi di `bcdd`:
`new` crea lo scheletro, `check` controlla la forma, `refine` sottopone la CSC a un modello linguistico e
`ratify` registra l'approvazione. Ogni passo rimanda al capitolo che lo descrive. Al termine il capitolo indica
che cosa il programma non fa.

### Lo scheletro

```
$ bcdd new UsoLuce
creato UsoLuce.csc
```

Il file creato contiene l'intestazione con `STATUS HYPOTHESIS`, uno scopo da scrivere, le forme suggerite nei
commenti e `END` (capitolo 7). Lo scheletro supera già il controllo:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 17 (riconosciute 4, commenti 10, vuote 3, non riconosciute 0)
blocchi: 1
  riga 4: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORI: 0
…
esito: nessun errore
```

L'esito attesta che il file è scritto correttamente, non che contenga una descrizione: lo scopo è ancora «da
compilare».

### La prima stesura, a mano

La CSC si scrive a mano, interamente a parole (capitoli 2-4): lo scopo, gli eventi in ingresso e in uscita,
gli stati osservabili al confine, le promesse e i presupposti. I commenti dello scheletro si tolgono.

```
-- La luce delle scale, vista da chi sta sulle scale.

CSC UsoLuce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END
```

### Il controllo

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 19 (riconosciute 15, commenti 1, vuote 3, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORI: 0

2. GRADO DELLE RIGHE CONTRATTUALI
  verbale: 4
  formale: 0
  estensione dichiarata: 0
  non riconosciuta: 0
  riga 11: GUARANTEE g1 verbale
  riga 13: GUARANTEE g2 verbale
  riga 15: GUARANTEE g3 verbale
  riga 17: ASSUME a1 verbale

3. UNDECIDED: 0

4. DA APPROVARE, NON CONTRATTO: 4
  riga 11: GUARANTEE g1
  riga 13: GUARANTEE g2
  riga 15: GUARANTEE g3
  riga 17: ASSUME a1

5. RIGHE NON RICONOSCIUTE: 0

6. TIPI NON DICHIARATI: 0

7. CSC NOMINATE E NON CONTROLLATE: 0

esito: nessun errore
```

Il file è scritto correttamente e le quattro righe contrattuali sono da approvare. Due promesse restano vaghe:
`g2` non precisa dopo quanto tempo la luce si spegne; `g3` non precisa quanto tempo prima arriva l'avviso.

### Le domande del modello linguistico

Con `bcdd refine` il modello linguistico pone domande sui punti vaghi e propone dettagli (capitolo 8). Le righe iniziali, che riportano il
controllo del file e la chiamata al modello, sono omesse; le domande e le proposte variano da un'esecuzione
all'altra.

```
$ bcdd refine UsoLuce.csc
…
DOMANDA 1 di 2
  Quanto tempo dopo l'ultima pressione la luce si deve spegnere, e con quale tolleranza?
  1) 60 secondi, con 5 secondi di tolleranza
  2) 90 secondi, con 5 secondi di tolleranza
  3) 3 minuti, con 10 secondi di tolleranza
risposta (da 1 a 3, oppure scrivi tu; invio vuoto per saltare): 2
  scelta 2: 90 secondi, con 5 secondi di tolleranza

DOMANDA 2 di 2
  Quanto tempo prima dello spegnimento arriva l'avviso?
  1) 5 secondi prima
  2) 10 secondi prima
risposta (da 1 a 2, oppure scrivi tu; invio vuoto per saltare): 1
  scelta 1: 5 secondi prima
…
PROPOSTA 1 di 3, dettaglia g2 (riga 13)
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                              VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
accetti? s = sì, n = no, f = fine (scarta le restanti): s

PROPOSTA 2 di 3, dettaglia g2 (riga 13)
  GUARANTEE g2b DETAILS g2 STATUS HYPOTHESIS: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo i 90 s"
                                              VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
accetti? s = sì, n = no, f = fine (scarta le restanti): s

PROPOSTA 3 di 3, dettaglia g3 (riga 15)
  GUARANTEE g3a DETAILS g3 STATUS HYPOTHESIS: VERBAL "L'avviso arriva tra 15 e 5 s prima dello spegnimento"
                                              VERIFY BY JUDGEMENT "una persona sulle scale con un cronometro"
accetti? s = sì, n = no, f = fine (scarta le restanti): n

riepilogo: accettate 2, scartate da te 1, scartate dal controllo 0
scrivo 2 proposte (4 righe) in UsoLuce.csc e 2 risposte in UsoLuce.csc.dialogo? s = sì, n = no: s
scritto UsoLuce.csc: 2 proposte (4 righe)
scritto UsoLuce.csc.dialogo: 2 risposte
```

La terza proposta non corrisponde alla risposta data, «5 secondi prima», e si scarta. Le proposte si accettano o
si scartano a giudizio di chi scrive la CSC: il modello propone, e nel file entra soltanto ciò che si accetta e si
conferma. Ogni riga scritta in questo modo resta da approvare.

### Le correzioni a mano e le storie

Il dettaglio di `g3` si scrive a mano, come qualunque riga. Si aggiungono anche le storie (capitolo 9), che
vanno scritte prima dell'approvazione: una storia non si aggiunge a una CSC approvata. Le ultime righe del file
diventano:

```
  GUARANTEE g3a DETAILS g3: VERBAL "L'avviso arriva 5 s prima dello spegnimento, con una tolleranza di 1 s"
                            VERIFY BY JUDGEMENT "una persona sulle scale che misura con un cronometro il tempo fra l'avviso e lo spegnimento"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"

  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    accesa = true
    @85 s    avviso
    @90 s    accesa = false
  SCENARIO s2 EXPECT REJECTED
    @0 s     premuto    accesa = true
    @30 s    accesa = false
END
```

La storia `s1` deve essere ammessa: la luce si spegne 90 secondi dopo la pressione, con l'avviso 5 secondi
prima. La storia `s2` deve essere respinta: la luce si spegne dopo 30 secondi, in contrasto con `g2a`.

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 33 (riconosciute 28, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, STATUS HYPOTHESIS

1. ERRORI: 0
…
4. DA APPROVARE, NON CONTRATTO: 7
  riga 11: GUARANTEE g1
  riga 13: GUARANTEE g2
  riga 15: GUARANTEE g2a
  riga 17: GUARANTEE g2b
  riga 19: GUARANTEE g3
  riga 21: GUARANTEE g3a
  riga 23: ASSUME a1
…
esito: nessun errore
```

### L'approvazione

L'amministratore del condominio esamina la CSC e la approva con la decisione `D-1`, annotata nel registro
delle decisioni. `bcdd ratify` registra l'approvazione nel file (capitolo 7):

```
$ bcdd ratify UsoLuce.csc --all D-1
approvate con D-1 nella CSC UsoLuce: 4 righe
  riga 4: CSC UsoLuce
  riga 15: GUARANTEE g2a
  riga 17: GUARANTEE g2b
  riga 21: GUARANTEE g3a
contratto: 7
```

Il comando modifica quattro righe: l'intestazione e i tre dettagli. Un dettaglio non segue lo `STATUS`
dell'intestazione (capitolo 8), quindi a ciascuno è assegnato il proprio, anche a `g3a`, che non ne aveva. Le altre righe
contrattuali assumono quello dell'intestazione. Nell'uscita di `bcdd ratify` il numero di riga è quello della
riga modificata: per l'intestazione è la riga `STATUS` (riga 4), mentre il rapporto di `bcdd check` indica la
riga `CSC` (riga 3). Il rapporto finale conferma l'approvazione:

```
$ bcdd check --strict UsoLuce.csc
bcdd check --strict UsoLuce.csc
righe: 33 (riconosciute 28, commenti 1, vuote 4, non riconosciute 0)
blocchi: 1
  riga 3: CSC UsoLuce VERSION 0.1, STATUS RATIFIED BY D-1

1. ERRORI: 0
…
4. DA APPROVARE, NON CONTRATTO: 0
…
esito: nessun errore
```

La CSC è ora il contratto fra l'amministratore e chi realizza la luce.

### Dopo l'approvazione

Le righe approvate non si modificano. Una modifica successiva, per esempio una durata dell'accensione diversa,
si scrive in una versione nuova, da approvare di nuovo (capitolo 10). Quando il sistema diventa più complesso,
la descrizione si divide in più CSC, una per confine, e si introduce l'entità (capitoli 11-13). Le promesse che
un programma deve poter controllare si scrivono come formule (capitoli 21-23).

### Che cosa il programma non fa

`bcdd` controlla la forma dei file e scrive in un file soltanto quando un comando lo prevede. In particolare:

- **non giudica se una promessa è corretta.** «Nessun errore» indica un file scritto correttamente: lo
  scheletro con lo scopo «da scrivere» supera il controllo come la CSC completa. Il contenuto delle promesse è
  responsabilità di chi le scrive e di chi le approva (capitolo 2);
- **non interpreta il testo fra virgolette.** Se nella storia `s1` la luce si spegne dopo 30 secondi, con
  l'avviso a 25, il rapporto non cambia, anche se la storia contrasta con `g2a`. `bcdd` controlla i nomi usati
  nelle storie e l'ordine e le unità dei loro tempi, ma non confronta le storie con le promesse scritte a parole
  (capitolo 9). Non associa nemmeno il
  nome di una costante al testo delle promesse (capitolo 8);
- **non confronta due versioni della stessa CSC.** Legge un file alla volta e non rileva le differenze
  rispetto alla versione precedente; il confronto si esegue con gli strumenti di gestione delle versioni, prima
  di approvare (capitolo 10);
- **non approva.** `bcdd ratify` registra una decisione già presa da chi ne ha l'autorità; né
  `bcdd` né il modello linguistico approvano una riga (capitolo 7);
- **non scrive senza conferma.** `bcdd refine` modifica il file soltanto con la conferma finale, e non
  sostituisce mai una riga approvata (capitolo 8);
- **non verifica il sistema costruito.** Le promesse si verificano su un sistema reale con le registrazioni e il
  piano di prova (capitoli 24 e 26), che `bcdd` non esegue;
- **non valuta le formule**: ne controlla la forma, i nomi e i tipi, ma non stabilisce se le storie hanno l'esito
  dichiarato né se le promesse possono valere insieme. Il rapporto elenca questi controlli come non eseguiti
  (capitolo 24). L'appendice B elenca ciò che `bcdd` non controlla.

### Riepilogo

- Il procedimento completo è: `bcdd new` per lo scheletro, la stesura a mano, `bcdd check --strict` dopo ogni
  modifica, `bcdd refine` per le domande sui punti vaghi, le storie prima dell'approvazione, `bcdd ratify` dopo
  la decisione.
- Ogni proposta del modello linguistico si accetta o si scarta; nel file entra come riga da approvare.
- Dopo l'approvazione ogni modifica richiede una versione nuova.
- `bcdd` controlla la forma e non giudica il contenuto, non confronta versioni e non approva.

---

## Appendice A — Le parole chiave, nell'ordine in cui sono introdotte

La tabella elenca le parole del linguaggio nell'ordine dei capitoli, con il capitolo in cui ciascuna è
descritta e il suo uso. Comprende le parole chiave, gli operatori, i nomi dei tipi di base, le unità di tempo e
le parole minuscole riservate. `bcdd` riconosce tutte le parole della tabella. L'elenco completo delle
parole riservate segue la tabella.

| Parola | Cap. | Uso |
|---|---|---|
| `CSC` … `END` | 2 | apre e chiude la descrizione di un confine |
| `--` | 2 | commento, ignorato dal programma |
| `VERSION` | 2 | numero di versione di una CSC o di un'entità |
| `PURPOSE` | 2 | scopo: in una frase, a che cosa serve il confine |
| `EVENT IN` | 2 | evento in ingresso: ciò che arriva al confine dall'altro lato |
| `STATE` … `INITIAL` | 2 | stato, cioè ciò che si osserva al confine in ogni istante, con il suo valore iniziale |
| `Boolean`, `true`, `false` | 2 | tipo logico (vero o falso) e i suoi due valori |
| `GUARANTEE` | 2 | promessa |
| `VERBAL` | 2 | promessa scritta a parole |
| `VERIFY BY JUDGEMENT` | 2 | controllo a giudizio di una persona |
| `VERIFY BY INSPECTION` | 2 | controllo per ispezione di un documento o di una registrazione |
| `ASSUME` | 3 | presupposto: condizione sull'altro lato da cui la promessa dipende |
| `EVENT OUT` | 4 | evento in uscita: ciò che esce dal confine verso l'altro lato |
| `CAPABILITY` | 5 | richiesta che l'altro lato può fare |
| `requested`, `accepted`, `rejected`, `completed`, `failed` | 5 | le fasi del ciclo di vita di una richiesta |
| `AUTONOMOUS` | 5 | richiesta avviata da chi offre |
| `TYPE` | 6 | tipo con un nome: elenco di valori o tipo descritto a parole |
| `:=` | 6 | introduce il contenuto di un tipo con nome (`TYPE`) o il valore di una costante con nome (`DEFINE`) |
| `Integer`, `Real`, `String` | 6 | tipi di base: numeri interi, numeri reali, stringhe |
| `[a .. b]` | 6 | intervallo di valori di `Integer` e `Real` |
| `Duration`, `s`, `ms` | 6 | durata, in secondi o millisecondi |
| `Sequence of`, `Optional` | 6 | sequenza di valori; valore che può mancare |
| `Record`, `ABSENT` | 6, 23 | tipo con più campi; assenza di un valore `Optional` |
| `STATUS` | 7 | stato di approvazione della CSC o di una riga |
| `HYPOTHESIS` | 7 | da approvare |
| `RATIFIED BY` | 7 | approvata, con il riferimento della decisione |
| `DETAILS` | 8 | dettaglio: precisa una promessa o un presupposto |
| `DEFINE` | 8, 23 | costante con nome; con parametri, funzione |
| `UNDECIDED` | 8 | numero non deciso |
| `SCENARIO` | 9 | storia descritta istante per istante |
| `@` | 9 | tempo di un istante di una storia |
| `EXPECT ADMITTED`, `EXPECT REJECTED` | 9 | la storia deve essere ammessa, oppure respinta |
| `GIVEN` | 9 | stato di partenza di una storia |
| `ENTITY` | 12 | entità: ciò che sta dietro uno o più confini |
| `OFFERS`, `USES` | 12 | confine che l'entità offre, oppure usa |
| `COMPOSED OF` | 13 | elenco delle parti di un'entità |
| `[m .. n]` | 16 | molteplicità: numero minimo e massimo di copie di una parte |
| `VARIANT` | 20 | variante: una delle alternative di un aspetto dell'entità, dichiarata con `VARIANT gruppo = scelta` |
| `ALWAYS` | 21 | sempre |
| `EVENTUALLY` | 21 | prima o poi |
| `WHENEVER` … `THEN` | 21 | ogni volta che… allora |
| `AT ONCE` | 21 | nello stesso passo |
| `WHILE` | 21 | mentre |
| `NOT`, `AND`, `OR`, `IMPLIES` | 21 | combinazione di condizioni |
| `=` `<>` `<` `<=` `>` `>=` | 21 | confronti |
| `+` `-` `*` `/` `^` | 21 | somma, differenza, prodotto, quoziente, potenza |
| `IN {` … `}` | 21 | il valore è uno di quelli elencati |
| `IF` … `THEN` … `ELSE` | 21 | valore scelto in base a una condizione; l'espressione va fra parentesi |
| `ABS`, `MIN`, `MAX`, `LOG10`, `ROUND`, `FLOOR`, `CEIL` | 21 | funzioni matematiche |
| `WITHIN` | 22 | entro un certo tempo |
| `TIME SINCE` | 22 | tempo trascorso da un evento |
| `COUNT`, `COUNT` … `IN LAST` | 22 | conteggio di un evento, dall'inizio o in un intervallo |
| `SINCE` | 22 | in `COUNT(e SINCE f)`: conteggio dopo l'ultimo `f` |
| `WITH` | 22 | filtro sui parametri di un evento |
| `LAST` | 22, 23 | in `IN LAST`; in `LAST(e)`, l'ultimo `e` accaduto |
| `REPEAT` … `EVERY`, `FOREVER` | 22 | passi di una storia che si ripetono |
| `PREV` | 22 | valore di uno stato nel passo precedente |
| `NEVER` | 23 | mai; abbreviazione |
| `ONCE` | 23 | accaduto almeno una volta; abbreviazione |
| `CHANGED` | 23 | lo stato ha cambiato valore; abbreviazione |
| `PRECEDES` | 23 | un evento precede una condizione; abbreviazione |
| `BEFORE`, `AFTER` | 23 | prima del primo evento, dal primo evento in poi; abbreviazioni |
| `ACCEPTS` … `ONLY WHILE` | 23 | condizione per accettare una richiesta; abbreviazione |
| `ENSURES` | 23 | che cosa vale quando una richiesta riesce; abbreviazione |
| `RESOLVES` … `WITHIN` | 23 | tempo massimo della risposta a una richiesta; abbreviazione |
| `REQUIRES` | 23 | condizione per fare una richiesta, scritta in un presupposto; abbreviazione |
| `AFTER` … `UNTIL`, `BETWEEN` … `AND`, `FOR AT LEAST` | 23 | abbreviazioni che il manuale non usa; per `BETWEEN` e `FOR AT LEAST` la forma estesa non è ancora definita |
| `TRANSITION` … `->` … `ON` … `WHEN` | 23 | insieme chiuso delle transizioni di uno stato; abbreviazione |
| `DEFINE EVENT` | 23 | evento derivato |
| `FOR ALL` … `IN` | 23 | per ogni valore di un tipo finito; abbreviazione |
| `x[T]`, `.` | 23 | stato con indice; campo di un record |
| `FOLLOWS` | 23 | stato che segue il parametro di un evento; abbreviazione |
| `PRESENT` | 23 | un valore `Optional` è presente |
| `BINDING` … `END` | 25 | blocco delle forme concrete di un confine |
| `BIND` | 25 | forma concreta di un elemento |
| `AS` | 25 | nome distintivo di un blocco `BINDING` |
| `VERIFICATION` … `END` | 26 | blocco del piano di prova |
| `MEANS` … `OBSERVES` … `RESOLUTION` | 26 | mezzo di registrazione, con gli elementi che osserva e la risoluzione |
| `USING` | 26 | blocco `BINDING` attraverso cui un mezzo osserva |
| `TRANSLATES` | 26 | storia tradotta nelle forme concrete |
| `EXTENSION` | 27 | estensione: forma nuova del linguaggio, dichiarata in un profilo |
| `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES TO`, `SOURCE` | 27 | campi di un'estensione, con `VERIFY` |
| `PATTERN`, `SCOPE`, `FUNCTION`, `DECLARATION`, `RELATION`, `SCENARIO-FORM` | 27 | valori del campo `KIND` |
| `Name`, `Type`, `Event`, `Condition`, `Expression`, `Duration`, `Property` | 27 | categorie dei parametri di un'estensione |
| `PROFILE`, `IMPORT PROFILE` | 27 | profilo, e la riga con cui un blocco lo importa |

### L'elenco delle parole riservate

Le parole chiave e le parole riservate sono **136**. Nessuna può essere un nome. Il linguaggio distingue
maiuscole e minuscole, quindi `pattern` e `level` sono nomi validi. Le parole della CSC, dell'entità, dei
blocchi e dell'intestazione:

```
CSC VERSION END STATUS HYPOTHESIS RATIFIED BY PURPOSE CAPABILITY AUTONOMOUS
EVENT IN OUT STATE INITIAL DEFINE UNDECIDED GUARANTEE ASSUME DETAILS VERBAL VERIFY
JUDGEMENT INSPECTION SCENARIO GIVEN EXPECT ADMITTED REJECTED COMPOSED OF
TYPE ENTITY OFFERS USES VARIANT
IMPORT PROFILE BINDING VERIFICATION EXTENSION
```

Le parole delle formule e delle storie, con il tipo `Record`:

```
WHILE ALWAYS EVENTUALLY WHENEVER THEN WITHIN AT ONCE REPEAT FOREVER EVERY
AND OR NOT IMPLIES IF ELSE COUNT LAST TIME SINCE PREV WITH ABSENT PRESENT Record
```

Le parole delle abbreviazioni e le funzioni matematiche:

```
NEVER AFTER BEFORE BETWEEN UNTIL PRECEDES FOR LEAST ACCEPTS ONLY REQUIRES ENSURES RESOLVES
CHANGED TRANSITION ON WHEN FOLLOWS ALL
ABS MIN MAX LOG10 ROUND FLOOR CEIL
```

I campi di un'estensione, i valori del campo `KIND` e le categorie dei parametri:

```
KIND LEVEL PARAMS FORM MEANING REDUCES TO SOURCE
PATTERN SCOPE FUNCTION DECLARATION RELATION SCENARIO-FORM
Name Type Event Condition Expression Duration Property
```

Le parole delle forme concrete e del piano di prova:

```
BIND AS MEANS OBSERVES RESOLUTION USING TRANSLATES
```

Le parole di due forme riservate a usi futuri e quelle di forme ritirate:

```
REFINED REFINES
FACE LINK MAP REFINEMENT VIEW
```

Infine, in minuscolo, `true`, `false`, i cinque nomi del ciclo di vita (`requested`, `accepted`, `rejected`,
`completed`, `failed`) e `_`. Le sigle `V1`, `V2` e `C1` … `C8` sono riconosciute come sigle soltanto nel campo
`VERIFY` di un'estensione; altrove sono nomi validi. I nomi delle estensioni di un profilo non sono riservati.

---

## Appendice B — Che cosa controlla `bcdd`

L'appendice descrive i controlli di `bcdd` 1.0-beta, la versione usata per gli esempi del manuale. `bcdd
check` classifica ciò che legge in tre modi:

- un **errore** è una forma che il programma riconosce ma che non è scritta correttamente; compare nella
  sezione 1 del rapporto con un codice fra parentesi quadre, fa terminare il comando con il codice d'uscita 1 e
  impedisce `bcdd ratify`;
- una **riga non riconosciuta** è una riga che non corrisponde ad alcuna forma del linguaggio; compare nella
  sezione 5, non è un errore, e con `--strict` fa fallire il controllo e impedisce `bcdd ratify` (capitolo 2);
- tutto il resto è riconosciuto e compare nelle altre sezioni del rapporto.

### Gli errori

I messaggi riportati provengono da file di prova: i nomi che vi compaiono (`P`, `g1`, `A`, …) sono quelli di quei
file, e nei casi reali cambiano. La colonna «Cap.» indica il capitolo in cui l'errore compare in un esempio; un
trattino indica un errore che il manuale non mostra. Gli errori sono quaranta, da E01 a E40.

| Codice | Quando si presenta | Messaggio | Cap. |
|---|---|---|---|
| E01 | due elementi dello stesso blocco hanno lo stesso nome: due promesse, un valore e uno stato, due parametri, due parti, due campi di un record; due blocchi con lo stesso nome nello stesso file | `nome già usato alla riga 5: g1` | 2 |
| E02 | `DETAILS` nomina una riga che non esiste nel blocco o che non è del tipo previsto: una promessa o un presupposto per una riga contrattuale, una `DEFINE` per una `DEFINE`, una storia per una storia | `DETAILS nomina un id che non è una GUARANTEE né una ASSUME di questa CSC: g9` | 8 |
| E03 | una storia nomina un evento, uno stato, una richiesta o un parametro non dichiarati; un valore che non appartiene a nessun elenco di valori del blocco | `nome non dichiarato come EVENT: f`; `nome non dichiarato come parametro di e: b`; `nome non dichiarato come valore di TYPE: z` | 6, 23 |
| E04 | `STATUS RATIFIED` senza `BY` e il riferimento della decisione | `STATUS RATIFIED senza decisione: serve BY D-numero` | 7 |
| E05 | i dettagli sono circolari, anche quando una riga è dettaglio di se stessa | `DETAILS in modo circolare: g1 -> g1` | 8 |
| E06 | una stringa aperta non si chiude prima della fine del file | `stringa non chiusa: il file finisce dentro la stringa aperta qui` | — |
| E07 | un blocco senza `END`, perché il file termina o comincia un altro blocco | `blocco non chiuso: manca END di CSC P`; `blocco non chiuso: manca END di CSC Comando` | 25 |
| E08 | una riga `END` che non chiude alcun blocco aperto | `END senza un blocco aperto` | 25 |
| E09 | una riga che comincia con `CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`, o con `EXTENSION` in un profilo, e non ha la forma prevista | `intestazione non valida: attesa CSC Nome VERSION numero`; `intestazione non valida: attesa BINDING NomeCSC VERSION numero [AS nome]` | — |
| E10 | una CSC, un'entità o un profilo senza `PURPOSE`, oppure con due; due righe `STATUS` nell'intestazione | `PURPOSE mancante nella CSC P`; `PURPOSE mancante nel PROFILE Senza`; `PURPOSE ripetuto: il primo è alla riga 2`; `STATUS ripetuto: il primo è alla riga 5` | 2, 27 |
| E11 | il file non contiene alcuna CSC, entità, `BINDING`, `VERIFICATION` o profilo; il messaggio è preceduto da `file:` anziché dal numero di riga | `il file non contiene nessuna CSC` | — |
| E12 | in una storia il tempo di un istante diminuisce, oppure la storia mescola istanti con e senza unità di tempo | `il tempo del passo diminuisce: @3 s dopo @5 s`; `passi con e senza unità di tempo nello stesso SCENARIO` | 9 |
| E13 | una promessa o un presupposto a parole senza la riga `VERIFY` | `VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa` | 2 |
| E14 | in un'entità, una parte usa un confine che nessun'altra parte offre e che l'entità non usa dall'esterno | `la parte pb usa il connettore B: nessun'altra parte di E14 lo offre, né E14 lo usa da fuori` | 13 |
| E15 | una riga che comincia con `REFINEMENT`, una forma ritirata | `REFINEMENT VIEW è stata ritirata: una scomposizione si scrive con ENTITY` | — |
| E16 | un confine che l'entità offre e che nessuna parte offre, oppure che l'entità usa e che nessuna parte usa | `il connettore pubblico C di E16 (offre) non è affidato a nessuna parte` | 13 |
| E17 | una parte offre un confine che nessun'altra parte usa e che l'entità non offre dall'esterno | `la parte pa offre il connettore A: nessun'altra parte di E17 lo usa, né E17 lo offre da fuori` | 13 |
| E18 | in un'entità compare una riga `ASSUME`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE` o `TYPE` | `ASSUME non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori` | 12 |
| E19 | il numero di copie di una parte non è valido | `la parte pa ha un numero di copie non valido: [2 .. 1]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo` | 16, 19 |
| E20 | in una storia o in una formula d'entità, un nome preceduto da un confine che l'entità non offre né usa; in una CSC, un nome preceduto da un confine | `B.x: E20 non offre né usa il connettore B; uno scenario può citare solo i connettori di E20`; `B.x: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità` | 11, 18, 21 |
| E21 | `VARIANT` in una CSC, oppure scritto senza `=` o senza scelta; `PURPOSE` dentro un segmento di variante | `VARIANT non può stare in una CSC: le varianti si scrivono in un'entità`; `VARIANT scritto male: serve VARIANT gruppo = scelta`; `PURPOSE non può stare in un segmento VARIANT: scrivilo prima del primo VARIANT` | 20 |
| E22 | un gruppo con una sola scelta, una scelta scritta due volte, un segmento di variante senza righe | `il gruppo di scelte a ha una sola scelta (b): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]`; `la scelta a = b è già scritta alla riga 3`; `il segmento VARIANT a = b è vuoto: una scelta senza righe si scrive con una parte [0 .. 1]` | 20 |
| E23 | un'entità con più di 64 composizioni | `l'entità E23 ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole` | 20 |
| E24 | in una formula, in una `DEFINE`, in una riga `FOLLOWS` o nell'uso di un'estensione: un nome non dichiarato, o di un genere diverso da quello richiesto dalla posizione; un campo che il record non ha; una chiamata di funzione con argomenti errati; in un'entità, un nome senza il confine davanti | `nome non dichiarato: premuta`; `nome non dichiarato come campo di Tocco: stanza`; `manca l'argomento valore nella chiamata di vicino`; `accesa non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY` | 21, 23 |
| E25 | un'espressione di tipo non ammesso nella sua posizione; un valore scritto in `INITIAL`, nel `GIVEN`, in un'assegnazione o in un argomento che non è del tipo dichiarato | `tipo incoerente: serve Duration, trovato Integer`; `valore non del tipo Modo: false`; `valore non del tipo Percentuale: 120` | 6, 22, 23 |
| E26 | `AND` e `OR` mescolati senza parentesi; due `IMPLIES`, due confronti o due `^` di seguito senza parentesi | `AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)`; `confronti in catena: scrivi a <= b AND b <= c` | 21 |
| E27 | una parola chiave di formula annidata in un'altra; due ambiti nella stessa proprietà; `WITHIN` e `AT ONCE` insieme; `REQUIRES` in una promessa | `ALWAYS dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni`; `una proprietà ha un solo ambito: AFTER è il secondo`; `REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)` | 21, 23 |
| E28 | `DEFINE` o tipi con nome che si nominano in modo circolare | `DEFINE in modo circolare: A -> B -> A` | — |
| E29 | il tipo di un indice non è finito; un indice su un nome che non ne ha; uno stato con indice scritto senza indice; un indice di tipo non coerente | `il tipo dell'indice di s non è finito: Real`; `accesa non ha indice`; `accesa ha un indice: scrivi accesa[valore di Piano]`; `indice di clipCount non del tipo Ch: X` | 23 |
| E30 | in una storia, una ripetizione non conforme alla forma prevista | `REPEAT ripetuto nella storia: il primo è alla riga 6`; `il passo @60 s non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY 60 s`; `REPEAT senza passi: i passi ripetuti si scrivono dopo la riga REPEAT` | 22 |
| E31 | in un `BINDING` o in un piano di prova la cui CSC legata è stata trovata, un elemento o una storia che la CSC non dichiara | `spia non è un elemento della CSC UsoLuce VERSION 0.3`; `TRANSLATES nomina una storia che la CSC UsoLuce VERSION 0.3 non ha: s9` | 25, 26 |
| E32 | un'estensione fuori da un profilo | `EXTENSION fuori da un PROFILE: un'estensione si dichiara in un profilo` | 27 |
| E33 | un campo di un'estensione mancante, ripetuto o con un valore non ammesso; un `FORM` non conforme; `KIND FUNCTION` senza il tipo del risultato; in `VERIFY V1`, una sigla diversa da `C1` … `C8` | `manca il campo SOURCE nell'EXTENSION FADE`; `valore di KIND non ammesso: pattern`; `il parametro d deve comparire una volta in FORM` | 27 |
| E34 | due estensioni con lo stesso nome nello stesso profilo; un'estensione con il nome di una parola del linguaggio | `nome di estensione già usato alla riga 3: FADE`; `il nome dell'estensione è una parola del linguaggio: ALWAYS` | — |
| E35 | `REDUCES TO` nomina ciò che non è una parola del linguaggio, un parametro o un'estensione dello stesso profilo; estensioni che si nominano in modo circolare con `REDUCES TO` | `REDUCES TO nomina X: non è una parola del linguaggio, un parametro né un'estensione del PROFILE P`; `REDUCES TO in modo circolare: A -> B -> A` | — |
| E36 | `REDUCES TO` ripete una sola forma del linguaggio o un'altra estensione | `l'EXTENSION MAI ripete una forma che il linguaggio ha già: NEVER` | 27 |
| E37 | un uso di un'estensione che non rispetta il suo `FORM`, il suo `KIND` o il suo `LEVEL` | `uso di FADE che non rispetta FORM "FADE s WITHIN d"` | 27 |
| E38 | un `BINDING` o un piano di prova importa un profilo in una versione diversa da quella della CSC legata | `PROFILE Protocollo importato con VERSION 0.2, ma la CSC Comando lo importa con VERSION 0.3` | — |
| E39 | uno `STATUS` in un piano di prova | `STATUS non può stare in una VERIFICATION: un piano di prova non si approva` | 26 |
| E40 | due `BINDING` per la stessa CSC e la stessa versione senza nome distintivo, o con lo stesso nome distintivo, nello stesso file | `secondo BINDING senza nome per la CSC Comando VERSION 0.1: il primo è alla riga 13. Con due o più BINDING ognuno ha un nome, AS nome` | 25 |

Nei messaggi `bcdd` usa il termine «connettore» per una CSC citata da un'entità e «id» per il nome breve; il
manuale usa «confine» e «nome breve». Negli errori di un'entità con più
composizioni il suffisso `(in: …)` indica le composizioni in cui l'errore vale (capitolo 19).

Alcuni errori rendono non riconosciuta anche la riga in cui si trovano, che è quindi elencata anche nella
sezione 5:
E06, E08, E09, E15, E18, E21 ed E32; con E32 sono non riconosciute anche le righe dell'estensione fuori posto. Gli
errori da E24 a E31 e da E33 a E40 lasciano invece riconosciuta la riga: la forma è letta per intero, e l'errore
indica che cosa non è corretto.

`bcdd` segnala un errore solo quando può stabilirlo con certezza. Se un controllo dipende da un file citato che non si trova (una CSC
legata, la CSC di un nome qualificato, un profilo importato), il controllo è sospeso e la citazione compare nella
sezione 7.

### Ciò che compare nel rapporto senza essere un errore

| Sezione | Che cosa elenca | Cap. |
|---|---|---|
| 2. GRADO DELLE RIGHE CONTRATTUALI | per ogni riga contrattuale, il grado: verbale, formale, estensione dichiarata o non riconosciuta | 2, 21, 27 |
| 3. UNDECIDED | i numeri non decisi | 8 |
| 4. DA APPROVARE, NON CONTRATTO | le righe da approvare: righe contrattuali, dettagli di `DEFINE` e di storie, righe `BIND`, estensioni di un profilo da approvare | 2, 7, 25, 27 |
| 5. RIGHE NON RICONOSCIUTE | le righe che `bcdd` non riconosce, con il motivo se dipende da un profilo non trovato; con `--strict` fanno fallire il controllo | 2, 27 |
| 6. TIPI NON DICHIARATI | i tipi usati senza una riga `TYPE` | 6 |
| 7. CSC NOMINATE E NON CONTROLLATE | le CSC, le parti, i blocchi `BINDING` e i profili citati che `bcdd` non ha trovato | 12, 13, 27 |
| 8. USI DENTRO LE ENTITÀ | per ogni parte, chi offre ciascun confine che la parte usa | 13 |
| 9. COMPOSIZIONI | le composizioni di un'entità che ne ha più di una | 19, 20 |
| 10. ASSENZE DICHIARATE | ciò che manca soltanto perché manca una parte facoltativa | 19 |
| 12. FORME CONCRETE MANCANTI | per ogni `BINDING`, gli elementi della CSC legata senza una riga `BIND` | 25 |
| 13. COPERTURA DEL PIANO DI PROVA | per ogni piano di prova, le promesse formali osservate da ciascun mezzo e quelle non eseguite | 26 |
| 14. DA GIUDICARE | le regole che richiedono un giudizio umano: la coerenza di un dettaglio con una riga a parole, le regole di significato delle estensioni | 8, 21, 27 |
| 15. CONTROLLI NON ESEGUITI | i controlli sulle formule che `bcdd` non esegue, con le righe a cui si applicherebbero | 21, 24 |

Le sezioni 8, 9, 10 e 12-15 compaiono soltanto quando servono. Il numero 11 non si usa.

Con l'opzione `--json`, `bcdd check` scrive al posto del rapporto un oggetto JSON, con `"forma": "bcdd-check"` e
`"versione": 5`, che contiene le stesse informazioni.

### I messaggi dei comandi

Nei casi seguenti il comando si interrompe con un messaggio su una sola riga, senza un codice d'errore fra
parentesi quadre come `[E03]`, termina con un codice d'uscita diverso da 0 e non modifica alcun file:

| Messaggio | Quando | Cap. |
|---|---|---|
| `bcdd check: file non trovato: nessuno.csc` | il file indicato non esiste | — |
| `bcdd new: UsoLuce.csc esiste già: non lo sovrascrivo` | esiste già un file con lo stesso nome | 7 |
| `bcdd ratify: il file non passa bcdd check --strict (errori: 1, righe non riconosciute: 0): non approvo` | il file ha errori o righe non riconosciute | 7 |
| `bcdd ratify: g1 è già contratto (riga 11): non cambio nulla` | la riga indicata è già approvata | 7 |
| `bcdd ratify: decisione non valida: D7 (serve D-numero)` | il riferimento della decisione non ha la forma `D-` seguita da cifre | 7 |
| `bcdd ratify: nel BINDING si approvano l'intestazione o --all, non una riga` | si indica una riga di un `BINDING`; per un profilo il messaggio indica che si approva il profilo intero | 25 |
| `bcdd ratify: il BINDING Comando VERSION 0.1 è già approvato (D-21): non cambio nulla` | il `BINDING` o il profilo scelto è già approvato | 25 |
| `bcdd ratify: nessun blocco da approvare con il nome NOME nel file` | nessuna CSC, entità, profilo o `BINDING` ha il nome indicato con `--csc` | — |
| `bcdd ratify: il file non contiene nessun blocco da approvare: una VERIFICATION non si approva` | il file contiene soltanto piani di prova | 26 |

### Ciò che `bcdd` non controlla

- il significato delle formule: non stabilisce se una storia ha l'esito dichiarato, se ogni innesco avviene in
  una storia, se promesse e presupposti possono valere insieme, se un dettaglio formale è coerente con la riga che
  precisa; sono i controlli della sezione 15 (capitoli 21 e 24);
- le regole a giudizio: la coerenza di un dettaglio con una riga a parole e le regole di significato delle
  estensioni; sono le voci della sezione 14 (capitoli 8 e 27);
- le registrazioni: `bcdd` non legge tracce registrate, e la sezione 13 indica quali promesse un mezzo osserva, non
  se siano rispettate (capitolo 26);
- i valori delle costanti, e che il nome di una costante citato nel testo di una promessa esista (capitolo 8);
- i limiti di un intervallo, che non confronta fra loro (capitolo 6);
- i tipi non noti: un valore di un tipo descritto a parole, di un tipo non dichiarato o di una costante
  `UNDECIDED`; nelle storie d'entità un valore che è un nome; nelle formule d'entità il tipo degli elementi delle
  CSC citate (capitoli 18 e 21);
- gli usi delle estensioni di `KIND RELATION` e `KIND SCENARIO-FORM`, che lascia non riconosciuti (capitolo 27);
- che cosa cambia fra due versioni della stessa CSC (capitolo 10).

Restano inoltre non riconosciute le righe con parole chiave scritte in minuscolo (capitolo 2) e la riga
`STATUS RATIFIED BY` nell'intestazione di un'entità (capitolo 12). Una durata con un'unità diversa da `s` e `ms`,
per esempio `1 min`, non appartiene al linguaggio (capitoli 6 e 8): la riga che la contiene è una riga non
riconosciuta.

Nessun programma descritto nel manuale esegue la verifica sulle registrazioni (capitolo 24) né un piano di prova
(capitolo 26).

---

## Appendice C — Glossario

Questa appendice raccoglie i termini che il manuale usa con un significato particolare. Per ciascuno indica il
capitolo in cui il termine è presentato e la definizione, che vale in tutto il manuale. In fondo sono elencati
i termini della specifica del linguaggio che il manuale non usa, o usa in un senso più ristretto.

| Termine | Cap. | Definizione |
|---|---|---|
| sistema | 1 | ciò che si descrive, di qualunque dimensione: un impianto, un programma, un apparecchio |
| confine | 1 | interfaccia fra un sistema e una persona o un altro sistema, attraverso la quale si osserva ciò che passa fra i due |
| lato | 1 | ciascuno dei due interlocutori di un confine; nell'esempio, chi sta sulle scale e l'impianto |
| scatola nera | 1 | sistema di cui si conosce solo ciò che entra e ciò che esce |
| promessa (`GUARANTEE`) | 1, 2 | ciò che un lato del confine garantisce a chi sta dall'altro lato; riguarda solo ciò che si osserva al confine |
| controllo (`VERIFY`) | 1, 2 | indicazione di chi verifica che una promessa sia rispettata, e in che modo |
| da approvare (`STATUS HYPOTHESIS`) | 1, 7 | stato di una riga contrattuale, o della CSC, non ancora approvata, modificabile liberamente; nel rapporto di `bcdd` compare sotto «DA APPROVARE, NON CONTRATTO» |
| approvata (`STATUS RATIFIED BY`) | 7 | stato di una riga contrattuale, o della CSC, approvata da chi ne ha l'autorità, con il riferimento della decisione; da quel momento non è più modificabile |
| parte | 1, 13 | sistema più piccolo contenuto in un sistema più grande; nel BCDD, entità contenuta in un'altra entità |
| modello linguistico | 1 | programma, addestrato su grandi quantità di testo, che genera testo e codice a partire da istruzioni scritte in linguaggio naturale |
| realizzare, realizzazione | 1 | costruire il sistema che mantiene le promesse; il sistema costruito, con le sue scelte interne |
| comportamento | 1 | ciò che si osserva dall'esterno: che cosa entra, che cosa esce e quando |
| contratto | 1 | insieme delle promesse e dei presupposti approvati su un confine |
| BCDD | 1 | linguaggio per specificare il comportamento di un sistema attraverso i suoi confini; sigla di *Behavioural Contract-Driven Design*, progettazione guidata da contratti sul comportamento |
| CSC | 1, 2 | descrizione scritta di un confine, contenuta in un file `.csc`; sigla di *Capability State Contract* |
| commento (`--`) | 2 | nota per chi legge, ignorata dal programma |
| versione (`VERSION`) | 2, 10 | numero che identifica una stesura della CSC; cambia quando cambia il contratto |
| parola chiave | 2 | parola fissa del linguaggio, in inglese e in maiuscolo |
| scopo (`PURPOSE`) | 2 | frase che indica a che cosa serve il confine |
| evento | 2 | ciò che accade in un istante e poi è concluso |
| evento in ingresso (`EVENT IN`) | 2 | evento che arriva al confine dall'altro lato |
| stato (`STATE`) | 2 | elemento visibile al confine che ha sempre un valore |
| tipo | 2, 6 | insieme dei valori che può assumere uno stato o un dato |
| `Boolean` | 2 | tipo logico, con i valori vero (`true`) e falso (`false`) |
| valore iniziale (`INITIAL`) | 2 | valore di uno stato all'avvio del sistema; obbligatorio |
| nome breve | 2, 3, 9 | nome assegnato a una riga contrattuale o a una storia per citarla (`g1`, `a1`, `s1`) |
| a parole, verbale (`VERBAL`) | 2 | promessa scritta in una lingua naturale, fra virgolette; «verbale» è il nome del grado corrispondente, nel senso di «fatta di parole» |
| stringa | 2 | testo fra virgolette |
| a giudizio (`BY JUDGEMENT`) | 2 | controllo in cui una persona esegue una prova e giudica |
| per ispezione (`BY INSPECTION`) | 2 | controllo che consiste nell'esame di un documento o di una registrazione già esistenti |
| `bcdd` | 2 | programma a riga di comando che crea e controlla i file `.csc`, li sottopone a un modello linguistico e registra l'approvazione delle righe (capitolo 29) |
| `bcdd check` | 2 | comando che controlla la forma di un file senza modificarlo |
| opzione | 2 | aggiunta a un comando che ne modifica il comportamento |
| `--strict` | 2 | opzione che fa fallire il controllo anche per una sola riga non riconosciuta |
| blocco | 2 | descrizione contenuta nel file, dalla riga che la apre (`CSC`, `ENTITY`, `BINDING`, `VERIFICATION`, `PROFILE`) a `END` |
| rapporto | 2 | testo stampato da `bcdd check`, diviso in sezioni numerate |
| errore | 2 | forma che il programma riconosce ma che non è scritta correttamente |
| riga non riconosciuta | 2 | riga che non corrisponde ad alcuna forma del linguaggio; non è un errore, ma viene sempre segnalata |
| riga contrattuale | 2 | riga che entra nel contratto una volta approvata: una promessa e, dal capitolo 3, un presupposto |
| grado | 2, 21, 27 | modo in cui è scritta una promessa, da cui dipende come si verifica: verbale, formale o estensione dichiarata |
| esito | 2, 5, 24 | (1) ultima riga del rapporto di `bcdd check`: «nessun errore» non significa che le promesse siano corrette (capitolo 2); (2) risultato di una richiesta, riuscita o fallita (capitolo 5); (3) risultato della verifica di una promessa (capitolo 24) |
| presupposto (`ASSUME`) | 3 | condizione sull'altro lato da cui la promessa dipende; se non è rispettato, la promessa non è violata |
| chi offre | 4, 12 | lato del confine che mantiene le promesse; la CSC si scrive dal suo lato |
| chi usa | 4, 12 | lato del confine che rispetta i presupposti e si affida alle promesse |
| evento in uscita (`EVENT OUT`) | 4 | evento che chi offre invia verso l'altro lato |
| richiesta (`CAPABILITY`) | 5 | ciò che chi usa può richiedere a chi offre; ha una risposta (accettata o rifiutata) e un esito (riuscita o fallita) |
| risposta | 5 | prima conclusione di una richiesta: accettata o rifiutata |
| ciclo di vita (`requested`, `accepted`, `rejected`, `completed`, `failed`) | 5, 9 | i cinque nomi delle fasi di una richiesta; fissano l'ordine delle fasi, non gli obblighi |
| richiesta autonoma (`AUTONOMOUS`) | 5 | richiesta avviata da chi offre senza che l'altro lato la richieda; non ha `requested` né `rejected` |
| parametro | 5, 6 | valore che accompagna un evento o una richiesta |
| elenco di valori (enumerazione) | 6 | tipo costituito da un elenco di valori con un nome |
| intervallo (`[a .. b]`) | 6 | limiti dei valori ammessi per un tipo `Integer` o `Real` |
| tipo descritto a parole (`TYPE … := VERBAL`) | 6 | tipo con un nome e una descrizione fra virgolette, che il programma non interpreta |
| tipo non dichiarato | 6 | tipo usato senza una riga `TYPE`; non è un errore, ed è elencato nella sezione 6 del rapporto |
| riferimento della decisione | 7 | identificativo con cui è registrata la decisione di approvazione; richiesto da `bcdd ratify` |
| intestazione | 7, 12 | la riga `CSC` o `ENTITY` e le righe che la seguono prima del corpo, in qualunque ordine: `PURPOSE`, l'eventuale `STATUS`, l'eventuale `IMPORT PROFILE`. In una CSC lo `STATUS` dell'intestazione si applica alle righe che non ne hanno uno proprio; in un'entità è ammesso soltanto `STATUS HYPOTHESIS`. Negli altri blocchi (capitoli 25-27) l'intestazione comprende `STATUS` e `IMPORT PROFILE` in un `BINDING`, soltanto `IMPORT PROFILE` in un piano di prova, `PURPOSE` e `STATUS` in un profilo |
| `bcdd new` | 7 | comando che crea lo scheletro di un file `.csc` |
| `bcdd ratify` | 7 | comando che registra l'approvazione di una riga contrattuale o di tutte, di un `BINDING` o di un profilo, modificando soltanto le righe `STATUS` |
| dettaglio (`DETAILS`) | 8 | riga che esprime una promessa o un presupposto in modo più preciso, senza sostituirli né contraddirli |
| costante con nome (`DEFINE`) | 8, 23 | valore, o espressione, a cui si assegna un nome da usare nella CSC |
| da giudicare | 8 | sezione 14 del rapporto: regole che richiedono un giudizio umano, come la coerenza di un dettaglio con una riga a parole; non sono errori |
| numero non deciso (`UNDECIDED`) | 8 | numero mancante; il programma lo elenca finché non viene deciso |
| `bcdd refine` | 8 | comando con cui il modello linguistico pone domande e propone righe, sempre da approvare |
| livello | 8 | numero di passaggi di `DETAILS` che separano una riga da una riga senza `DETAILS`; `bcdd refine` non propone oltre il livello 2 |
| dichiarazione | 8, 9 | riga che dichiara un elemento della CSC (`TYPE`, `CAPABILITY`, `EVENT`, `STATE`, `DEFINE`, `SCENARIO`). Non ha uno `STATUS` proprio e assume quello dell'intestazione. Fanno eccezione i dettagli di `DEFINE` e di storie, che sono da approvare come ogni dettaglio |
| file del dialogo (`.dialogo`) | 8 | file accanto alla CSC in cui `bcdd refine` conserva domande e risposte |
| storia (`SCENARIO`) | 9 | sequenza di istanti che le promesse della CSC devono ammettere o respingere |
| istante di una storia (`@`) | 9 | riga di una storia che indica un tempo e ciò che accade o si osserva in quell'istante |
| asserzione a parole (`VERBAL` in una storia) | 9 | descrizione a parole di un istante; non richiede `VERIFY` |
| ammessa, respinta (`EXPECT ADMITTED`, `EXPECT REJECTED`) | 9 | indicazione che la storia rispetta o viola il contratto |
| stato di partenza (`GIVEN`) | 9 | valori degli stati all'inizio di una storia, quando non sono quelli iniziali |
| versione nuova | 10 | modo di cambiare un contratto approvato: lo si riscrive con un numero nuovo |
| entità (`ENTITY`) | 12 | sistema che sta dietro uno o più confini; è descritta dai confini che offre e da quelli che usa; la descrizione non indica dove si trova |
| promessa d'entità | 12 | promessa che lega due o più confini della stessa entità e che nessuna delle CSC può esprimere da sola |
| connettore | 12 (nota), App. B | termine usato da `bcdd` nei messaggi per una CSC citata da un'entità |
| offre (`OFFERS`) | 12 | riga di un'entità che indica un confine che l'entità offre |
| usa (`USES`) | 12 | riga di un'entità che indica un confine che l'entità usa |
| citazione | 12 | riga di un'entità, di tipo `OFFERS`, `USES` o di parte, che indica una CSC o un'entità; `bcdd` la cerca e ne riporta versione, `STATUS` ed esito |
| chi usa trova chi offre | 13 | regola per cui, dentro un'entità, ogni confine usato da una parte è offerto da un'altra parte oppure è un confine esterno, cioè un confine che l'entità stessa usa |
| elenco delle parti (`COMPOSED OF`) | 13 | la riga `COMPOSED OF` e le righe delle parti che la seguono |
| nome della parte | 13 | nome del ruolo di una parte nell'entità (`pulsante`), distinto dal nome dell'entità che la descrive (`Pulsante`) |
| confine interno | 13 | confine fra due parti di un'entità, che l'entità non offre né usa; non è osservabile dall'esterno |
| confine pubblico | 13 | confine che un'entità offre o usa verso l'esterno |
| confine esterno | 14 | confine che una parte usa e che nessuna parte dell'entità offre; si dichiara sull'entità con `USES` |

| chiusura, entità chiusa | 13 | proprietà di un'entità con parti che rispetta la regola «chi usa trova chi offre» e le due regole che la completano (E16, E17); `bcdd` la controlla con gli errori E14, E16 ed E17 |
| `--dir` | 13, 15 | opzione che indica a `bcdd` una cartella in cui cercare i file citati; si può ripetere, e le cartelle si esaminano nell'ordine in cui sono indicate |
| canale | 14 | mezzo che può perdere, ritardare o alterare l'ordine di ciò che trasporta; il suo comportamento si descrive in un confine con la propria CSC |
| versione indicata | 15 | versione scritta dopo il nome della CSC in una riga `OFFERS` o `USES`. Una riga `USES` senza versione corrisponde a qualunque riga `OFFERS`. Una riga `OFFERS` senza versione non corrisponde a una riga `USES` che ne indica una |
| corrispondenza, corrispondere | 15 | relazione fra una riga `USES` di una parte e una riga `OFFERS` di un'altra parte, o `USES` dell'entità, con lo stesso nome, quando le versioni rispettano le regole del capitolo 15 |
| copia | 16 | esemplare di una parte contenuto in un'entità; ogni copia mantiene tutte le promesse della parte |
| molteplicità (`[m .. n]`) | 16 | indicazione del numero minimo e massimo di copie di una parte; senza molteplicità la parte ha una copia |
| parte vicina | 17 | altra parte della stessa entità che cita una delle stesse CSC |
| divisione eccessiva | 17 | divisione in parti oltre il necessario; ne è segnale un'entità con una sola parte che offre e usa gli stessi confini |
| storia d'entità | 18 | storia scritta su un'entità, in cui ogni nome è preceduto dal nome della CSC da cui proviene |
| nome qualificato (`Csc.nome`) | 18 | nome di un elemento preceduto dal nome della CSC e da un punto, usato nelle storie d'entità |
| parte facoltativa | 19 | parte che chi compone il sistema decide se montare; la scelta si fa prima dell'uso del sistema e non cambia |
| composizione | 19, 20 | ciascuna delle forme complete in cui si può montare un'entità; ognuna si controlla separatamente |
| assenza dichiarata | 19 | ciò che manca solo perché manca una parte facoltativa; non è un errore, e `bcdd` la elenca nella sezione 10 |
| suffisso `(in: …)` | 19 | indicazione, nel rapporto, delle composizioni in cui vale un errore o una voce |
| variante (`VARIANT`) | 20 | una delle alternative di un aspetto dell'entità, dichiarata con `VARIANT gruppo = scelta` |
| scelta | 20 | nome a destra del segno `=` in una riga `VARIANT` |
| segmento | 20 | righe di una variante, dalla riga `VARIANT` alla successiva o a `END`; valgono soltanto con quella scelta |
| righe comuni | 20 | righe di un'entità che precedono il primo `VARIANT`; valgono in ogni composizione |
| gruppo di scelte | 20 | insieme di scelte alternative con lo stesso nome del gruppo (a sinistra del segno `=`), di cui una sola vale in ciascuna composizione |
| formula | 21 | promessa scritta in una forma che un programma può controllare passo per passo; non ha `VERIFY` |
| passo | 21 | unità di osservazione: gli eventi che accadono a un istante e i valori degli stati subito dopo. Più passi successivi possono avere lo stesso istante. Ogni riga di una storia che comincia con `@` è un passo |
| traccia | 9, 21 | sequenza di passi, scritta in una storia o registrata su un sistema costruito |
| condizione sul passo | 21 | espressione che in ogni passo è vera o falsa: un evento, un confronto, una fase di una richiesta, combinati con `NOT`, `AND`, `OR`, `IMPLIES` |
| precedenza | 21 | ordine in cui si applicano gli operatori di una formula senza parentesi; le combinazioni ambigue richiedono le parentesi (errore E26) |
| riga aperta | 21 | riga che finisce con un operatore o una parola chiave che richiede una continuazione, o con una parentesi non chiusa; continua quindi sulla riga successiva |
| controlli non eseguiti | 21, 24 | sezione 15 del rapporto: i controlli sulle formule che `bcdd` non esegue, con le righe a cui si applicherebbero |
| sempre (`ALWAYS`) | 21 | la condizione vale in ogni passo |
| prima o poi (`EVENTUALLY`) | 21 | la condizione vale in almeno un passo |
| ogni volta che… allora (`WHENEVER … THEN`) | 21 | in ogni passo in cui vale l'innesco, la conseguenza deve valere nello stesso passo o in un passo successivo |
| innesco, conseguenza | 21 | le due condizioni di `WHENEVER … THEN`: la prima, quando vale, richiede che valga la seconda; l'innesco è anche la parte `p` di `ALWAYS (p IMPLIES q)` e la condizione che apre `WHILE` (capitolo 24) |
| nello stesso passo (`AT ONCE`) | 21 | la conseguenza vale nel passo stesso dell'innesco |
| mentre (`WHILE`), ambito | 21 | `WHILE c: P`: la formula `P` deve valere nei passi in cui vale `c`, che formano l'ambito di `P`; ogni tratto continuo in cui vale `c` è un ambito a sé; senza `WHILE` l'ambito è l'intera traccia |
| formale | 21 | grado di una promessa scritta come formula o con un'abbreviazione, che `bcdd` legge per intero; indica come la promessa si potrà verificare, non che sia stata verificata |
| limite di tempo (`WITHIN`) | 22 | durata entro cui deve valere la condizione di `EVENTUALLY` o la conseguenza di `WHENEVER` |
| tempo trascorso (`TIME SINCE`) | 22 | tempo passato dall'ultimo passo in cui è accaduto un evento; 0 nel passo dell'evento, infinito prima del primo evento (solo nei confronti) |
| conteggio (`COUNT`, `COUNT … SINCE`, `COUNT … IN LAST`) | 22 | numero dei passi in cui è accaduto un evento. `COUNT` conta dall'inizio della traccia. `COUNT … SINCE` conta dopo l'ultimo passo di un altro evento. `COUNT … IN LAST d` conta nell'intervallo di durata `d` che termina con il passo considerato: questo passo è compreso, il passo a distanza esattamente `d` è escluso |
| filtro (`WITH`) | 22 | condizione sui parametri di un evento o di una fase di una richiesta |
| ripetizione (`REPEAT … EVERY`) | 22 | passi di una storia che seguono la riga `REPEAT` e si ripetono con un periodo, da un minimo a un massimo di volte o senza fine |
| valore precedente (`PREV`) | 22 | valore di uno stato nel passo precedente; nel primo passo, il valore iniziale |
| abbreviazione, forma breve | 23 | forma che si espande in una formula equivalente scritta con le parole chiave dei capitoli 21 e 22, la forma estesa; il suo significato è soltanto quello della forma estesa |
| forma estesa | 23 | formula equivalente a un'abbreviazione, scritta con le parole chiave dei capitoli 21 e 22; si dice che l'abbreviazione «si espande» nella sua forma estesa |
| insieme chiuso di transizioni (`TRANSITION`) | 23 | promessa che elenca tutti i modi in cui uno stato cambia valore |
| evento derivato (`DEFINE EVENT`) | 23 | nome dato a una condizione sul passo, usato in una formula come un evento; non si scrive nei passi delle storie |
| funzione (`DEFINE` con parametri) | 23 | espressione con parametri tipizzati, usata con gli argomenti scritti per nome |
| tipo con nome (`TYPE … := Tipo`) | 23 | nome dato a un tipo, valido in tutto il blocco |
| record (`Record`) | 23 | tipo fatto di campi con un nome; `x.campo` ne nomina un campo |
| stato con indice (`STATE x[T]`) | 23 | uno stato per ogni valore di un tipo finito; si nomina con `x[valore]` |
| verifica sul testo | 24 | controlli eseguiti sulla CSC, prima della costruzione: forma, coerenza, storie, copertura, chi usa trova chi offre, promesse d'entità, dettagli |
| verifica sulle registrazioni | 24 | controlli eseguiti sulle tracce registrate su un sistema costruito; nessun programma descritto nel manuale la esegue |
| registrazione | 24 | traccia osservata sui confini di un sistema costruito |
| coerenza | 24 | esistenza di almeno una traccia che rispetta insieme tutti i presupposti e tutte le promesse |
| copertura | 24 | presenza, per ogni promessa con un innesco, di una storia ammessa in cui l'innesco si verifica |
| realizzabilità | 24 | esistenza di un sistema che rispetti le promesse qualunque sia il comportamento dell'altro lato; nessun controllo la garantisce |
| rispettata sulla traccia | 24 | esito di una promessa formale mai violata nella traccia registrata; non fornisce indicazioni sulle situazioni non osservate (nella specifica `SODDISFATTA SULLA TRACCIA`) |
| violata | 24 | esito di una promessa formale la cui formula non vale in un passo della traccia; l'esito indica il passo |
| inconclusiva | 24 | esito di una promessa formale che la traccia non consente di stabilire, perché termina prima che l'esito sia determinabile |
| non eseguita | 24 | esito di una promessa formale su ciò che il mezzo di registrazione non osserva |
| conforme a giudizio, non conforme a giudizio, non valutata | 24 | esiti di una promessa verbale, con chi ha giudicato e su che cosa; «non valutata» se nessuno ha giudicato |
| presupposto non rispettato | 3, 24 | esito che segnala il mancato rispetto, da parte dell'altro lato, di un presupposto da cui la promessa dipende; la promessa non è violata |
| forma concreta (`BINDING`) | 25 | ciò che chi sta al confine osserva o usa di un elemento di una CSC: un morsetto, un testo, un colore, un formato di file. Le forme concrete di un confine si scrivono in un blocco `BINDING … END`, distinto dalla CSC |
| vincolante (forma concreta) | 25 | detto di una forma concreta osservata o usata da chi è esterno alla realizzazione: una persona, un altro programma, un sistema terzo |
| «chi lo vede?» | 25 | criterio che stabilisce se un elemento entra nella CSC, nelle forme concrete, o resta nella realizzazione |
| CSC legata | 25, 26 | CSC nominata nell'intestazione di un `BINDING` o di un piano di prova, con la sua versione; `bcdd` la cerca come una CSC citata |
| riga `BIND` | 25 | riga di un `BINDING` che descrive a parole la forma concreta di un elemento della CSC legata |
| nome distintivo (`AS`) | 25 | nome che distingue più blocchi `BINDING` della stessa CSC; il piano di prova lo usa con `USING`, `bcdd ratify` con `--csc` |
| forme concrete mancanti | 25 | sezione 12 del rapporto: gli elementi della CSC legata che nessuna riga `BIND` nomina; non sono errori |
| piano di prova (`VERIFICATION`) | 26 | blocco `VERIFICATION … END` che indica i mezzi di registrazione di un confine, con la loro risoluzione, e le storie in forme concrete; non contiene promesse e non si approva |
| copertura del piano di prova | 26 | sezione 13 del rapporto: per ogni mezzo le promesse formali che osserva per intero, e le promesse non eseguite |
| mezzo di registrazione (`MEANS`) | 24, 26 | strumento che registra ciò che accade a un confine attraverso le forme concrete del confine: un registratore, un sensore, una telecamera, un programma |
| osservare (detto di un mezzo) | 26 | registrare un elemento; un elemento che nessun mezzo registra non è osservato, e le promesse formali che lo citano sono non eseguite |
| risoluzione (`RESOLUTION`) | 26 | il più piccolo intervallo di tempo che un mezzo di registrazione distingue; «rispettata sulla traccia» vale con la risoluzione del mezzo |
| storia tradotta (`TRANSLATES`) | 26 | storia del piano di prova scritta con le forme concrete, che traduce una storia della CSC legata |
| estensione (`EXTENSION`) | 27 | forma nuova del linguaggio, da non confondere con l'estensione `.csc` del nome di un file; si dichiara in un profilo, con otto campi: `KIND`, `LEVEL`, `PARAMS`, `FORM`, `MEANING`, `REDUCES TO` (facoltativo), `VERIFY`, `SOURCE` |
| significato (`MEANING`) | 27 | campo di un'estensione che descrive a parole il significato della forma; se manca `REDUCES TO`, vale questa descrizione |
| campo `REDUCES TO` | 27 | campo facoltativo di un'estensione con la sua forma estesa (capitolo 23); se c'è, l'estensione è un'abbreviazione e la promessa che la usa ha grado formale |
| grandezza continua (`SIGNAL`) | 27 | grandezza definita in ogni istante e non soltanto nei passi, dichiarata con l'estensione `SIGNAL` del profilo `Segnale` |
| profilo (`PROFILE`, `IMPORT PROFILE`) | 27 | raccolta di estensioni per un campo d'uso, con un nome e una versione, che una CSC importa con `IMPORT PROFILE`; un profilo non ne importa un altro |
| categoria | 27 | genere dell'elemento che l'uso di un'estensione scrive al posto di un parametro: `Name`, `Type`, `Event`, `Condition`, `Expression`, `Duration`, `Property` |
| posto | 27 | parola del `FORM` uguale al nome di un parametro, dove l'uso dell'estensione scrive l'argomento |
| estensione dichiarata | 27 | grado di una promessa scritta con un'estensione senza `REDUCES TO`; si verifica come dichiara il campo `VERIFY` |
| parola in prova | 27 | parola del linguaggio che una revisione futura può spostare in un profilo, con lo stesso nome e lo stesso significato; resta riservata anche nelle CSC che non importano il profilo |
| direct box (DI) | 28 | apparecchio che preleva il segnale dai morsetti di uscita dell'amplificatore e lo porta alla scheda di cattura; nel kit di misura è una delle due scelte del sensore di livello e, in quella scelta, una parte facoltativa (capitolo 19); nei file è abbreviata in DI |

### Termini che il manuale non usa, e perché

Sono termini della specifica del linguaggio. Il manuale non li usa, o perché chi scrive una
CSC non ne ha bisogno, o perché il manuale li sostituisce con un termine già definito; chi consulta la specifica
li incontra con questi nomi.

- **nucleo, BASE**: dividono le parole del linguaggio secondo il modo in cui le tratta il programma. A chi
  scrive basta sapere che alcune forme sono abbreviazioni (capitolo 23).
- **promozione**, provvisoria o definitiva, e il numero delle prove: riguardano chi fa evolvere il
  linguaggio. A chi scrive basta sapere che alcune parole sono «in prova» (capitolo 27).
- **Core, Binding, Verification, livelli**: i nomi della specifica per il comportamento, le forme concrete e
  il piano di prova. Il manuale usa «comportamento», «forme concrete» e «piano di prova»; `BINDING` e
  `VERIFICATION` compaiono come parole chiave dei blocchi (capitoli 25 e 26) e, con `CSC` ed `ENTITY`, come
  valori del campo `LEVEL` di un'estensione (capitolo 27). Il nome «Core» non compare; «livello» resta riservato
  al numero di passaggi di `DETAILS` (capitolo 8), con l'eccezione del campo `LEVEL` di un'estensione.
- **consolidamento, dettaglio dall'alto in basso**: il manuale usa «rendere precisa una promessa».
- **V1, V2, C1-C8, E1-E7, D1-D6, P1-P9**: sigle dei controlli, delle regole e dei principi della specifica.
  Il manuale descrive a parole che cosa controllano. I codici di errore del rapporto (`E13`…) restano,
  perché compaiono sullo schermo; `V1`, `V2` e `C1`-`C8` compaiono soltanto nel campo `VERIFY` di
  un'estensione (capitolo 27).
- **ipotesi, ratifica**, e **proposta** come stato: il manuale usa «da approvare» e «approvata»; «proposta»
  indica soltanto ciò che il modello linguistico propone (capitolo 8). «Ipotesi» e «ratificare» compaiono solo
  per spiegare le parole chiave `HYPOTHESIS` e `RATIFIED` e il comando `ratify` (capitolo 7).
- **condizione, assunzione**: per `ASSUME` il manuale usa «presupposto».
- **garanzia, garanzia d'entità**: per `GUARANTEE` il manuale usa «promessa» e «promessa d'entità».
  «Garanzia» compare una volta sola, per glossare la parola chiave (capitolo 2).
- **parte** per i due lati di un confine: il manuale usa «lato», «chi offre», «chi usa»; «parte» indica solo
  i componenti di un sistema.
- **collegamento**: il manuale non usa questa parola come termine; per `BINDING` usa «forme concrete», e per
  un mezzo che trasporta segnali o dati usa «canale».
- **cosa**, e **pezzo** nel senso di componente: per ciò che sta dietro un confine il manuale usa «sistema» ed
  «entità», per i componenti «parte».
- **faccia, vista di raffinamento, LINK, MAP, REFINES, REFINED BY**: forme ritirate o riservate a usi
  futuri. Non sono utilizzabili, quindi il manuale non le descrive.
- **composizione** nel senso di `COMPOSED OF`: per non dare due significati alla stessa parola, il manuale
  chiama `COMPOSED OF` «l'elenco delle parti» e usa «composizione» solo per una delle forme complete di
  un'entità con parti facoltative o varianti (capitoli 19 e 20).
- **risposta** per la seconda condizione di `WHENEVER … THEN`: «risposta» indica la prima conclusione di una
  richiesta, accettata o rifiutata (capitolo 5); il manuale usa «conseguenza».
