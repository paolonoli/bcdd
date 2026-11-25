-- L'interfaccia per programmi di bcdd (DESIGN_F4 0.3; D-186, D-187, D-191 … D-193). Un file a parte
-- (F4-14 C, D-191): la offre l'entità StrumentoBcdd di BcddTool.csc, e BcddTool 0.7 non cambia.
-- A parole, ipotesi: l'operatore la ratifica prima del codice (D-187). p-11 viene da F4-13 sì (D-191),
-- Salva e p-12 … p-15 da F4-15 A (D-192), p-16 da F4-16 B (D-193).
-- VERSION 0.1 ratificata per intero con D-196.
-- VERSION 0.2 (D-259, W-60, prova del contratto di confine BCDD_CLI): p-8 e p-10 dicono anche il secondo
-- tempo, come fa bcdd (vettore S17: con il file cambiato GiroRispondi chiude il giro, senza chiamare l'LLM);
-- entrano Annulla, Togli e Rimetti (bcdd save --undo, --remove, --undo --expect nuovo), l'evento tolto e le
-- garanzie p-17 … p-20 (la forma bcdd-save). Nient'altro cambia.

CSC BcddProgrammi VERSION 0.2
  STATUS RATIFIED BY D-260
  PURPOSE "Offre a un altro programma, per primo l'editor, le stesse cose che BcddTool offre alla
           persona, in una forma che un programma legge senza interpretare un testo scritto per
           le persone: il controllo, il giro di affinamento diviso in tempi, il salvataggio di
           un testo cambiato"

  TYPE Testo    := VERBAL "il contenuto di un file, riga per riga"
  TYPE Impronta := VERBAL "un numero calcolato da tutti i byte di un file, che cambia se cambia
                           anche un solo byte"
  TYPE Uscita   := VERBAL "un testo per programmi, che dice il nome e la versione della sua forma"

  CAPABILITY CheckPerProgrammi(file: String, strict: Boolean, cartelle: Sequence of String)
                                                     -- come Check, con l'uscita per programmi
  CAPABILITY GiroInizia(file: String, csc: Optional String)   -- primo tempo: la prima chiamata
  CAPABILITY GiroRispondi(file: String, risposte: Sequence of String)  -- secondo tempo
  CAPABILITY GiroAccetta(file: String, accettate: Sequence of String)  -- ultimo tempo: scrive
  CAPABILITY GiroChiudi(file: String)                -- chiude il giro senza scrivere nel file CSC
  CAPABILITY Salva(file: String, impronta: Impronta, testo: Testo)
  CAPABILITY Annulla(file: String, impronta: Impronta)  -- rimette il testo di prima dell'ultimo Salva
  CAPABILITY Togli(file: String, impronta: Impronta)    -- toglie un file senza righe approvate
  CAPABILITY Rimetti(file: String)                      -- rimette il file tolto da Togli

  EVENT OUT struttura(file: String, uscita: Uscita)  -- esito di CheckPerProgrammi
  EVENT OUT giro(file: String, uscita: Uscita)       -- domande, proposte, sostituzioni, CSC a parte
  EVENT OUT salvato(file: String, righe: Sequence of Integer)  -- le righe cambiate
  EVENT OUT rifiutato(file: String, ragione: String)
  EVENT OUT tolto(file: String)                      -- esito di Togli

  -- ── Il controllo per programmi ─────────────────────────────────────────
  GUARANTEE p-1: VERBAL "CheckPerProgrammi dice le stesse cose del rapporto di Check sullo stesso
                         file con le stesse opzioni: gli stessi errori con gli stessi messaggi, gli
                         stessi conteggi, le stesse ipotesi, UNDECIDED, righe non riconosciute, tipi,
                         citazioni e usi, e lo stesso esito con lo stesso codice"
                 VERIFY BY INSPECTION "le due uscite, sui file di prova di Check"
  GUARANTEE p-2: VERBAL "CheckPerProgrammi dice anche, per ogni riga del file, il numero, il testo e
                         se è riconosciuta, commento, vuota o non riconosciuta; per ogni dichiarazione
                         il blocco, il tipo, il nome, il testo a parole e lo stato; per ogni riga
                         contrattuale il livello di DETAILS, lo stato con la decisione, e se lo stato
                         è suo o segue l'intestazione; e l'impronta del file letto"
                 VERIFY BY INSPECTION "l'uscita e il file"
  GUARANTEE p-3: VERBAL "Le garanzie di Check, da g-c1 a g-c8 di BcddTool, valgono anche per
                         CheckPerProgrammi"
                 VERIFY BY INSPECTION "le prove di Check ripetute con l'uscita per programmi"
  GUARANTEE p-4: VERBAL "Ogni uscita per programmi dice il nome e la versione della sua forma; una
                         forma che toglie un campo, o ne cambia il significato, ha una versione nuova"
                 VERIFY BY INSPECTION "le uscite di due versioni dello strumento"

  -- ── Il giro diviso in tempi ────────────────────────────────────────────
  GUARANTEE p-5: VERBAL "Un giro diviso in tempi segue le regole del giro di Refine: le garanzie da
                         g-r1 a g-r11 di BcddTool e quelle dell'entità Affinamento valgono anche quando
                         il giro si fa con GiroInizia, GiroRispondi e GiroAccetta"
                 VERIFY BY JUDGEMENT "l'operatore, sulle prove di Refine ripetute in tempi"
  GUARANTEE p-6: VERBAL "Un programma dice a bcdd solo a quali domande risponde, con quale testo, e
                         quali proposte e sostituzioni accetta, con il loro numero; le righe le
                         compone bcdd, e nel file non entra una riga che l'LLM non ha proposto in
                         quel giro"
                 VERIFY BY INSPECTION "ciò che il programma passa a bcdd, e il file prima e dopo"
  GUARANTEE p-7: VERBAL "In un giro le chiamate all'LLM sono al più due: una con GiroInizia, e una con
                         GiroRispondi se c'è almeno una risposta; GiroAccetta e GiroChiudi non chiamano
                         l'LLM"
                 VERIFY BY INSPECTION "il registro delle chiamate"
  GUARANTEE p-8: VERBAL "Fra un tempo e l'altro il giro si conserva in un file accanto al file CSC,
                         con lo stesso nome e .giro in fondo, che non è un file CSC; lo tolgono
                         GiroAccetta e GiroChiudi, e GiroRispondi solo quando chiude il giro perché
                         il file CSC è cambiato (p-10); nessun altro"
                 VERIFY BY INSPECTION "i file della cartella prima, durante e dopo un giro"
  GUARANTEE p-9: VERBAL "Se sullo stesso file c'è già un giro aperto, GiroInizia non ne apre un altro
                         e lo dice: il giro aperto si riprende o si chiude"
                 VERIFY BY JUDGEMENT "l'operatore, con un giro lasciato a metà"
  GUARANTEE p-10: VERBAL "Se il file CSC è cambiato dopo GiroInizia, GiroRispondi e GiroAccetta non
                          scrivono niente e non chiamano l'LLM: chiudono il giro e restituiscono le
                          risposte e le righe accettate fino a quel momento, da copiare"
                  VERIFY BY INSPECTION "il file e l'uscita, cambiando il file a metà giro"
  GUARANTEE p-11: VERBAL "Ogni riga che un giro scrive nel file, nel terminale o in tempi, è scritta
                          anche nel dialogo di quel giro, con il suo id, il suo testo e se è una riga
                          aggiunta o una riga sostituita"
                  VERIFY BY INSPECTION "il dialogo e il file dopo un giro con proposte e sostituzioni
                                       accettate"

  -- ── Il salvataggio di un testo cambiato ────────────────────────────────
  GUARANTEE p-12: VERBAL "Salva scrive il testo solo se il file è ancora quello dell'impronta;
                          altrimenti non scrive niente e dice che il file è cambiato"
                  VERIFY BY INSPECTION "il file prima e dopo, cambiandolo fra la lettura e Salva"
  GUARANTEE p-13: VERBAL "Dopo Salva ogni riga che è contratto lo era già prima, con lo stesso testo e
                          la stessa decisione: Salva non scrive mai uno STATUS RATIFIED, e un testo
                          che lo farebbe è rifiutato, con la ragione, e non scritto"
                  VERIFY BY INSPECTION "il file prima e dopo, con testi che aggiungono o cambiano
                                       righe contratto"
  GUARANTEE p-14: VERBAL "In una CSC che ha l'intestazione ratificata prima e dopo Salva, le
                          dichiarazioni che seguono l'intestazione restano identiche e nello stesso
                          ordine: Salva vi aggiunge solo righe contrattuali che sono ipotesi"
                  VERIFY BY INSPECTION "il file prima e dopo, con un evento aggiunto a una CSC
                                       ratificata"
  GUARANTEE p-15: VERBAL "Salva scrive il testo così come lo riceve, tutto o niente, e dice quali
                          righe sono cambiate"
                  VERIFY BY INSPECTION "differenza fra il file prima e dopo, e l'uscita"
  GUARANTEE p-16: VERBAL "Salva scrive anche un testo che Check rifiuterebbe, e dice gli errori: un
                          errore di Check non fa perdere una modifica"
                  VERIFY BY JUDGEMENT "l'operatore, con un DETAILS che nomina una riga che non c'è"

  -- ── Annullare, togliere, rimettere (VERSION 0.2, D-259) ──────────────────
  GUARANTEE p-17: VERBAL "Annulla rimette il testo che il file aveva prima dell'ultimo Salva, solo se
                          il file è ancora quello scritto da quel Salva; altrimenti non scrive niente
                          e dice che il file è cambiato"
                  VERIFY BY INSPECTION "vettore S08 del contratto BCDD_CLI, e il file cambiato fuori"
  GUARANTEE p-18: VERBAL "Togli toglie il file solo se ha ancora l'impronta data e non ha righe
                          approvate, e ne conserva il testo per Rimetti; altrimenti non toglie niente
                          e dice perché"
                  VERIFY BY INSPECTION "il file prima e dopo, con e senza una riga approvata"
  GUARANTEE p-19: VERBAL "Rimetti rimette il file tolto da Togli solo se al suo posto non c'è un
                          file; non scrive mai sopra un file che esiste"
                  VERIFY BY INSPECTION "la cartella prima e dopo, con e senza un file nuovo con
                                       lo stesso nome"
  GUARANTEE p-20: VERBAL "Salva, Annulla, Togli e Rimetti rispondono con la stessa uscita per
                          programmi: il nome e la versione della forma, il file, le righe cambiate,
                          gli errori di Check sul testo scritto e, quando scrivono un testo, la sua
                          impronta; Togli dice in più che il file è tolto"
                  VERIFY BY INSPECTION "vettori S05, S08, S09 del contratto BCDD_CLI"

  SCENARIO rigaNonProposta EXPECT REJECTED
    @0  requested(GiroInizia), accepted(GiroInizia)
    @1  giro(file: "LuceScale.csc", uscita: "proposte p1 e p2")
    @2  completed(GiroInizia)
    @3  requested(GiroAccetta), accepted(GiroAccetta)
    @4  completed(GiroAccetta)                         VERBAL "il file contiene una riga che non è p1 né p2"
                                                       -- viola p-6

  SCENARIO salvaUnaRatifica EXPECT REJECTED
    @0  requested(Salva), accepted(Salva)
    @1  salvato(file: "LuceScale.csc", righe: _)
    @2  completed(Salva)                               VERBAL "g1 ha STATUS RATIFIED BY D-1, prima no"
                                                       -- viola p-13

  SCENARIO salvaSopraUnFileCambiato EXPECT ADMITTED
    @0  requested(Salva), accepted(Salva)
    @1  rifiutato(file: "LuceScale.csc", ragione: "il file è cambiato")
    @2  failed(Salva)                                  VERBAL "il file è quello cambiato fuori"
END
