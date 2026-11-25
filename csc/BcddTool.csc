-- F0 di W-51 (D-123): la CSC dello strumento, a parole (P9, SPECIFICA_02 0.2).
-- Scritta dalle indicazioni dell'operatore del 2026-10-16.
-- VERSION 0.1 ratificata per intero il 2026-10-16 (D-125). VERSION 0.2 (D-127): passi degli scenari
-- riscritti con VERBAL, opzione strict di Check (g-c5); ratificata per intero il 2026-10-16 (D-128).
-- VERSION 0.3 (D-134, D-136; DESIGN_F2 1.3): ATTESA_MAX_LLM = 120 s (D-132); ogni domanda porta le
-- sue scelte; Ratify anche di tutte le ipotesi in un comando (g-t2). Ratificata per intero il
-- 2026-10-16 (D-137), commit a4d9e763.
-- VERSION 0.4 (D-138; DESIGN_F2 1.4): Refine si ferma. Al più LIVELLI_MAX livelli di DETAILS sotto
-- una riga base (g-r7); un argomento nuovo diventa una CSC a parte, segnalata e mai creata (g-r8);
-- una riga chiara quando non c'è più niente da chiedere né da proporre (g-r9). Ratificata per
-- intero il 2026-10-17 (D-139), commit ad41d9cb.
-- VERSION 0.5 (D-140; DESIGN_F2 1.5): Refine può sostituire una riga ancora ipotesi, se la persona
-- accetta dopo aver visto la riga di adesso e quella nuova (g-r10); la riga nuova tiene tipo, id,
-- DETAILS e STATUS della vecchia, e i dettagli restano (g-r11). Ratificata per intero il
-- 2026-10-17 (D-141), commit f46d30b1; commento corretto con D-143.
-- VERSION 0.6 (D-156; DESIGN_F3 1.3, B.14): Check cerca le CSC e le entità che le entità del file citano
-- (g-c6, g-c7), senza modificarle (g-c1), e controlla che chi usa trovi chi offre (g-c8). Il contenuto
-- del file passa alla CSC FileCsc. La REFINEMENT VIEW BcddToolParti diventa l'entità StrumentoBcdd;
-- Affinatore esce dalle CSC e le sue garanzie passano all'entità Affinamento. Ratificata per intero il
-- 2026-10-17 (D-157); le entità restano ipotesi.
-- VERSION 0.7 (D-161; DESIGN_F3B 1.0, B.2): Ratify approva anche le garanzie di un'entità (g-t1, g-t2), solo
-- se i confini dell'entità sono stati letti (g-t3, con le cartelle), mai la sua struttura (g-t4); Refine
-- affina anche le garanzie di un'entità (f-1, f-6, f-9, f-10 di Affinamento). Ratificata per intero il
-- 2026-10-17 (D-162).

CSC BcddTool VERSION 0.7
  STATUS RATIFIED BY D-162
  PURPOSE "Aiuta una persona a scrivere CSC BCDD partendo dalle parole: crea lo scheletro,
           controlla la forma, chiede a un LLM domande e proposte di dettaglio, e trasforma
           in contratto solo ciò che la persona ratifica"

  -- Che cosa la persona può chiedere
  CAPABILITY New(nome: String)                       -- crea lo scheletro di una CSC minima
  CAPABILITY Check(file: String, strict: Boolean, cartelle: Sequence of String)
                                                     -- controlla un file CSC, senza modificarlo
  CAPABILITY Refine(file: String)                    -- un giro di domande e proposte con l'LLM
  CAPABILITY Ratify(file: String, riga: Optional String, tutte: Boolean, decisione: String, cartelle: Sequence of String)
                                                     -- senza riga: l'intestazione; con tutte: anche ogni ipotesi

  -- Che cosa la persona riceve
  EVENT OUT rapporto(file: String)                   -- esito di Check
  EVENT OUT domanda(testo: String, scelte: Sequence of String)  -- domanda dell'LLM, con le risposte possibili
  EVENT OUT proposta(riga: String)                   -- riga proposta, da accettare o scartare
  EVENT OUT sostituzione(adesso: String, nuova: String)  -- riga ipotesi da sostituire, e la nuova
  EVENT OUT cscAParte(nome: String, motivo: String)  -- argomento nuovo: segnalato, mai creato
  EVENT OUT precisa(file: String)                    -- niente da chiedere né da proporre
  EVENT IN  risposta(proposta: String, accettata: Boolean)  -- anche per una sostituzione

  DEFINE ATTESA_MAX_LLM := 120 s                     -- quanto aspettare l'LLM prima di rinunciare (D-132)
  DEFINE LIVELLI_MAX := 2                            -- livelli di DETAILS sotto una riga base (D-138)

  -- ── New ────────────────────────────────────────────────────────────────
  GUARANTEE g-n1: VERBAL "New crea un file con una CSC minima (CSC, VERSION, PURPOSE da
                          compilare, END) che Check accetta senza errori"
                  VERIFY BY JUDGEMENT "l'operatore, eseguendo New e poi Check"
  GUARANTEE g-n2: VERBAL "New non sovrascrive mai un file che esiste già: rifiuta e dice perché"
                  VERIFY BY JUDGEMENT "l'operatore, su un file esistente"

  -- ── Check ──────────────────────────────────────────────────────────────
  GUARANTEE g-c1: VERBAL "Check non modifica mai il file, né i file che legge per le CSC e le entità
                          citate"
                  VERIFY BY INSPECTION "contenuto dei file prima e dopo"
  GUARANTEE g-c2: VERBAL "Il rapporto dice, per ogni riga contrattuale, il suo grado: verbale,
                          formale o non riconosciuta; ed elenca ogni UNDECIDED e ogni ipotesi"
                  VERIFY BY JUDGEMENT "l'operatore, sui file di prova"
  GUARANTEE g-c3: VERBAL "Una riga che lo strumento non sa leggere non viene mai ignorata in
                          silenzio: compare nel rapporto come non riconosciuta, con il numero
                          di riga"
                  VERIFY BY JUDGEMENT "l'operatore, con una riga inventata"
  GUARANTEE g-c4: VERBAL "Lo stesso file, con gli stessi file citati e le stesse cartelle, dà sempre
                          lo stesso rapporto"
                  VERIFY BY INSPECTION "due esecuzioni sullo stesso file"
  GUARANTEE g-c5: VERBAL "Con strict, Check finisce con un esito di errore se il file ha anche
                          una sola riga non riconosciuta; senza strict, una riga non
                          riconosciuta non cambia l'esito"
                  VERIFY BY JUDGEMENT "l'operatore, con e senza strict sullo stesso file"
  GUARANTEE g-c6: VERBAL "Per ogni CSC o entità che un'entità del file cita, il rapporto dice dove
                          l'ha trovata, con versione, stato ed esito, oppure che non l'ha controllata
                          e perché: una citazione non è mai taciuta. Una citazione mancante, o un file
                          citato con errori, non cambia l'esito del file controllato"
                  VERIFY BY INSPECTION "il rapporto, con citazioni trovate, mancanti e illeggibili"
  GUARANTEE g-c7: VERBAL "Se una citazione dichiara una versione e la CSC o l'entità trovata ne ha
                          un'altra, il rapporto lo dice"
                  VERIFY BY INSPECTION "il rapporto, con una versione diversa"
  GUARANTEE g-c8: VERBAL "Dentro un'entità fatta di parti, tutte trovate, una CSC che una parte usa e
                          che nessun'altra parte offre, né l'entità usa da fuori, è un errore del file"
                  VERIFY BY INSPECTION "il rapporto, con una parte che usa una CSC che nessuno offre"

  -- ── Refine ─────────────────────────────────────────────────────────────
  GUARANTEE g-r1: VERBAL "Refine non scrive mai nel file una riga che la persona non ha
                          accettato"
                  VERIFY BY INSPECTION "contenuto del file prima e dopo, con proposte scartate"
  GUARANTEE g-r2: VERBAL "Ogni riga proposta dettaglia una riga che esiste già (DETAILS) ed
                          entra nel file come ipotesi (STATUS HYPOTHESIS), mai come contratto"
                  VERIFY BY JUDGEMENT "l'operatore, sulle righe accettate"
  GUARANTEE g-r3: VERBAL "Una proposta che Check rifiuterebbe non viene presentata come
                          valida: la persona la vede come scartata, con la ragione"
                  VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g-r4: VERBAL "Le domande e le proposte non descrivono la realizzazione: niente
                          algoritmi, strutture dati, linguaggi o piattaforme (P2)"
                  VERIFY BY JUDGEMENT "l'operatore, su ogni giro"
  GUARANTEE g-r5: VERBAL "Se l'LLM non risponde entro ATTESA_MAX_LLM, o risponde in una forma
                          che lo strumento non sa leggere, Refine finisce con un messaggio
                          chiaro e il file resta com'era"
                  VERIFY BY JUDGEMENT "l'operatore, con l'LLM non raggiungibile"
  GUARANTEE g-r6: VERBAL "Nessuna garanzia di BcddTool dipende dalla correttezza delle
                          risposte dell'LLM: qualunque cosa risponda, le garanzie qui sopra
                          restano vere"
                  VERIFY BY JUDGEMENT "l'operatore, sul disegno; poi con risposte sbagliate
                                       di proposito"
  GUARANTEE g-r7: VERBAL "Una proposta che dettaglia una riga già al livello LIVELLI_MAX di
                          DETAILS sotto una riga base, o più in basso, non viene presentata come
                          valida: la persona la vede come scartata, con la ragione. Check accetta
                          lo stesso le righe che sono già più in basso"
                  VERIFY BY INSPECTION "il testo a schermo, con proposte su righe di ogni livello"
  GUARANTEE g-r8: VERBAL "Refine non crea mai un file CSC: un argomento nuovo che l'LLM propone
                          come CSC a parte arriva alla persona solo come segnalazione, con il nome
                          e il motivo"
                  VERIFY BY INSPECTION "i file della cartella prima e dopo un giro con una CSC a parte"
  GUARANTEE g-r9: VERBAL "Quando l'LLM non ha domande, proposte né CSC a parte, Refine lo dice
                          alla persona con una riga chiara, e il file resta com'era"
                  VERIFY BY JUDGEMENT "l'operatore, su una CSC già precisa"
  GUARANTEE g-r10: VERBAL "Refine sostituisce una riga solo se è ancora un'ipotesi e se la
                           persona accetta dopo aver visto la riga di adesso e quella nuova; una
                           riga contratto non si sostituisce mai: una sostituzione così arriva
                           alla persona come scartata, con la ragione"
                   VERIFY BY INSPECTION "il testo a schermo e il file prima e dopo, con sostituzioni
                                        di righe ipotesi e di righe contratto"
  GUARANTEE g-r11: VERBAL "La riga che prende il posto di un'altra ne tiene il tipo, l'id, la riga
                           che dettaglia e lo STATUS, e resta un'ipotesi; i dettagli della riga
                           sostituita restano dove sono, e la persona li vede elencati da rileggere"
                   VERIFY BY INSPECTION "differenza fra il file prima e dopo, e il testo a schermo"

  -- ── Ratify ─────────────────────────────────────────────────────────────
  GUARANTEE g-t1: VERBAL "Solo Ratify trasforma un'ipotesi in contratto: una riga o l'intera CSC,
                          oppure una garanzia di un'entità, e solo con un riferimento a una decisione
                          (STATUS RATIFIED BY D-nnn). Lo strumento non ratifica mai da solo"
                  VERIFY BY INSPECTION "le righe RATIFIED e i comandi eseguiti"
  GUARANTEE g-t2: VERBAL "Ratify cambia solo lo stato della riga indicata, o quello nell'intestazione
                          della CSC, o con tutte quello dell'intestazione e di ogni riga ancora ipotesi
                          della CSC, oppure di ogni garanzia ancora ipotesi dell'entità: il resto del
                          file resta identico, carattere per carattere"
                  VERIFY BY INSPECTION "differenza fra il file prima e dopo"
  GUARANTEE g-t3: VERBAL "Una garanzia di un'entità diventa contratto solo se ogni CSC che l'entità
                          offre o usa è stata trovata, nella versione che l'entità chiede, in un file
                          senza errori; altrimenti Ratify non cambia niente e dice quale CSC manca e
                          perché"
                  VERIFY BY INSPECTION "il file e il messaggio, con una CSC citata mancante, di
                                       un'altra versione e con errori"
  GUARANTEE g-t4: VERBAL "Ratify non rende mai contratto l'intestazione di un'entità, né le sue
                          offerte, i suoi usi o le sue parti"
                  VERIFY BY INSPECTION "le righe dell'entità prima e dopo"

  -- ── In generale ────────────────────────────────────────────────────────
  GUARANTEE g-x1: VERBAL "Nessun comando riformatta o riordina il testo della persona: cambia
                          solo le righe che il comando dichiara di cambiare"
                  VERIFY BY INSPECTION "differenza fra il file prima e dopo"

  SCENARIO propostaScartata EXPECT ADMITTED
    @0  requested(Refine), accepted(Refine)
    @1  proposta(riga: "g2a DETAILS g2 ...")
    @2  risposta(proposta: "g2a DETAILS g2 ...", accettata: false)
    @3  completed(Refine)                              VERBAL "il file è identico a com'era a @0"

  SCENARIO propostaAccettataComeContratto EXPECT REJECTED
    @0  requested(Refine), accepted(Refine)
    @1  proposta(riga: "g2a DETAILS g2 ...")
    @2  risposta(proposta: "g2a DETAILS g2 ...", accettata: true)
    @3  completed(Refine)                              VERBAL "il file contiene g2a già ratificata"
                                                       -- viola g-r2 e g-t1

  SCENARIO sostituzioneDiUnContratto EXPECT REJECTED
    @0  requested(Refine), accepted(Refine)
    @1  sostituzione(adesso: "g1 STATUS RATIFIED BY D-1 ...", nuova: "g1 ...")
    @2  risposta(proposta: "g1 ...", accettata: true)
    @3  completed(Refine)                              VERBAL "il file contiene la riga nuova al posto di g1"
                                                       -- viola g-r10
END



-- ── Le entità (F3, D-146): chi offre e chi usa queste CSC. A parole, ipotesi ──
ENTITY StrumentoBcdd VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Lo strumento bcdd: offre BcddTool alla persona, scrive i file CSC e usa un modello
           linguistico"
  OFFERS BcddTool VERSION 0.7
  OFFERS FileCsc VERSION 0.1
  OFFERS BcddProgrammi VERSION 0.2
  USES   ModelloLinguistico VERSION 0.1
  COMPOSED OF
    analisi     : Analisi
    controllo   : Controllo
    affinamento : Affinamento
    scrittura   : Scrittura
    comando     : RigaDiComando
END

ENTITY RigaDiComando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il programma bcdd che la persona e l'editor lanciano: riceve i comandi e si serve
           delle altre parti"
  OFFERS BcddTool VERSION 0.7
  OFFERS BcddProgrammi VERSION 0.2
  USES   Analizzatore VERSION 0.1
  USES   Controllore VERSION 0.1
  USES   Archivio VERSION 0.4
END

ENTITY Analisi VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Legge il testo di un file CSC e ne ricava la struttura"
  OFFERS Analizzatore VERSION 0.1
END

ENTITY Controllo VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Controlla la forma di una CSC già analizzata e prepara il rapporto"
  OFFERS Controllore VERSION 0.1
END

ENTITY Scrittura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "È l'unica parte che scrive i file CSC"
  OFFERS Archivio VERSION 0.4
  OFFERS FileCsc VERSION 0.1
END

ENTITY Affinamento VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Conduce un giro di affinamento con il modello linguistico: prepara la richiesta, ne legge
           la risposta, scarta ciò che non regge e gira alla persona domande e proposte"
  USES Analizzatore VERSION 0.1
  USES Controllore VERSION 0.1
  USES Archivio VERSION 0.4
  USES ModelloLinguistico VERSION 0.1
  -- le garanzie f-1 … f-9 di Affinatore.csc 0.4; con D-161 f-1, f-6, f-9 parlano anche delle entità, f-10 è nuova
  GUARANTEE f-1: VERBAL "La richiesta contiene la CSC o l'entità scelta e, per un'entità, le CSC dei
                         suoi confini trovate, il rapporto di Check, le regole della
                         grammatica in uso, il divieto di descrivere la realizzazione, le regole
                         per fermarsi (riga finita, due livelli, CSC a parte, conflitti) e le
                         righe che si possono sostituire, con la regola di sostituirle invece di
                         aggiungere una riga accanto"
                 VERIFY BY INSPECTION "il testo della richiesta"
  GUARANTEE f-2: VERBAL "Ogni proposta passa da Analizzatore e Controllore prima di arrivare
                         alla persona; se non regge, arriva come scartata con la ragione"
                 VERIFY BY JUDGEMENT "l'operatore, con risposte dell'LLM sbagliate di proposito"
  GUARANTEE f-3: VERBAL "Ad Archivio arrivano solo le proposte che la persona ha accettato,
                         ciascuna come DETAILS con STATUS HYPOTHESIS, e le sostituzioni che ha
                         accettato, ciascuna con l'id della riga che sostituisce"
                 VERIFY BY INSPECTION "l'elenco passato ad Archivio"
  GUARANTEE f-4: VERBAL "Una replica che non si sa leggere chiude il giro senza proposte e
                         con un messaggio chiaro"
                 VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE f-5: VERBAL "Se la persona risponde ad almeno una domanda, l'LLM riceve le risposte
                         nello stesso giro con una seconda richiesta, e alla persona arrivano solo
                         le proposte della seconda replica; in un giro ci sono al più due richieste"
                 VERIFY BY INSPECTION "le due richieste del giro e il testo a schermo"
  GUARANTEE f-6: VERBAL "La richiesta elenca come righe da dettagliare solo le righe base e i loro
                         dettagli di primo livello del blocco scelto, CSC o entità; una proposta
                         che dettaglia un'altra riga arriva come scartata, con la ragione"
                 VERIFY BY INSPECTION "la richiesta e il testo a schermo, su una CSC con tre livelli"
  GUARANTEE f-7: VERBAL "Una CSC a parte proposta dall'LLM arriva alla persona con il nome e il
                         motivo, e con la conferma va nel dialogo; nessuna diventa un file"
                 VERIFY BY INSPECTION "il testo a schermo, il dialogo e i file della cartella"
  GUARANTEE f-8: VERBAL "Una replica senza domande, senza proposte, senza sostituzioni e senza CSC
                         a parte chiude il giro con la riga che dice che la CSC è precisa abbastanza"
                 VERIFY BY INSPECTION "il testo a schermo"
  GUARANTEE f-9: VERBAL "Una sostituzione arriva alla persona come valida solo se la riga da
                         sostituire è un'ipotesi verbale del blocco scelto, CSC o entità, e la riga
                         nuova passa da Analizzatore e Controllore; altrimenti arriva come scartata, con la
                         ragione. La persona vede la riga di adesso, la nuova e i dettagli che
                         restano"
                 VERIFY BY INSPECTION "il testo a schermo, con sostituzioni di righe ipotesi, contratto,
                                      inesistenti e non verbali"
  GUARANTEE f-10: VERBAL "Per un'entità la richiesta vieta anche di descrivere ordine, priorità e
                          autorità fra le parti, e il luogo dell'entità"
                  VERIFY BY INSPECTION "il testo della richiesta per un'entità"
END
