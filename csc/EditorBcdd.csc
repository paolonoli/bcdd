-- La CSC dell'editor (DESIGN_F4 0.3; D-179 … D-194). A parole, ipotesi: l'operatore la ratifica prima
-- del codice (D-187). e-8 … e-10 vengono da D-192 (nessun controllo a tempo), e-11 da F4-15 A (D-192),
-- e-25 da F4-13 sì (D-191), e-26 da F4-16 B (D-193), e-21 ed e-27 da F4-17 B (D-194).

CSC EditorBcdd VERSION 0.1
  STATUS RATIFIED BY D-196
  PURPOSE "Una finestra in cui una persona crea e cambia le CSC: vede il disegno del file, lo
           modifica, lo affina con l'LLM e ne approva le garanzie, mentre il controllo,
           l'affinamento, l'approvazione e ogni scrittura del file li fa bcdd"

  TYPE Cambiamento := VERBAL "ciò che la persona cambia nella finestra: il testo di una riga
                              ipotesi, una dichiarazione nuova, una riga ipotesi tolta"

  CAPABILITY Apri(file: String, cartelle: Sequence of String)  -- mostra il disegno di un file
  CAPABILITY Nuova(nome: String, cartella: String)   -- un file nuovo, con lo scheletro di bcdd new
  CAPABILITY Modifica(file: String, cambiamento: Cambiamento)  -- cambia il file nella finestra
  CAPABILITY Salva(file: String)                     -- scrive le modifiche, attraverso bcdd
  CAPABILITY Affina(file: String)                    -- un giro di refine, attraverso bcdd
  CAPABILITY Approva(file: String, righe: Sequence of String, decisione: String)
                                                     -- una o più garanzie, attraverso bcdd ratify
  CAPABILITY ApprovaCsc(file: String, csc: String, decisione: String)
                                                     -- la CSC intera, attraverso bcdd ratify
  CAPABILITY Chiudi(file: String)

  EVENT OUT disegno(file: String)                    -- il quadro e le schede, aggiornati
  EVENT OUT avviso(testo: String)                    -- il file è cambiato fuori: scegli
  EVENT IN  scelta(ricarica: Boolean)                -- vero: ricarica e perdi la modifica
  EVENT IN  attiva                                   -- la finestra torna attiva
  EVENT OUT domanda(testo: String, scelte: Sequence of String)
  EVENT OUT proposta(riga: String)
  EVENT IN  risposta(proposta: String, accettata: Boolean)
  EVENT OUT elenco(righe: Sequence of String)        -- le righe che con la CSC diventano contratto
  EVENT OUT messaggio(testo: String)                 -- ciò che bcdd ha detto, così com'è

  STATE nonSalvata : Boolean INITIAL false           -- c'è una modifica non ancora scritta

  -- ── Vedere (D-181, D-183) ──────────────────────────────────────────────
  GUARANTEE e-1: VERBAL "Ciò che la finestra sa del file viene da bcdd: il disegno usa il controllo
                         per programmi di bcdd, e la finestra non legge il file con regole sue"
                 VERIFY BY INSPECTION "il disegno e l'uscita del controllo per programmi sullo
                                      stesso file"
  GUARANTEE e-2: VERBAL "Ogni CSC, entità, parte, garanzia e condizione del file compare nel
                         disegno con il nome breve, il testo a parole e lo stato che il controllo
                         le dà: ipotesi, oppure contratto con la decisione che l'ha approvata"
                 VERIFY BY INSPECTION "il disegno e il rapporto di bcdd check sullo stesso file"
  GUARANTEE e-3: VERBAL "Nel disegno non c'è niente che non sia nel file: nessuna garanzia, parte o
                         collegamento aggiunto"
                 VERIFY BY INSPECTION "il disegno e il file"
  GUARANTEE e-4: VERBAL "Gli errori e le righe che bcdd non sa leggere, comprese le righe formali,
                         compaiono nel disegno con il numero di riga: non sono mai taciuti"
                 VERIFY BY JUDGEMENT "l'operatore, con un file che ha un errore e una riga inventata"
  GUARANTEE e-5: VERBAL "Il quadro collega ogni parte che usa un confine a chi lo offre; un confine
                         che nessuno offre si vede come scoperto"
                 VERIFY BY JUDGEMENT "l'operatore, sulla luce delle scale con e senza il pulsante"
  GUARANTEE e-6: VERBAL "Lo stesso file, con gli stessi file citati e le stesse cartelle, dà sempre
                         lo stesso disegno, con i riquadri negli stessi posti: le posizioni si
                         calcolano dal file e non si salvano"
                 VERIFY BY INSPECTION "due disegni dello stesso file"
  GUARANTEE e-7: VERBAL "Il disegno dice da quale file viene e a che ora il file è stato letto"
                 VERIFY BY JUDGEMENT "l'operatore"

  -- ── Il file cambiato fuori (D-188, D-192) ──────────────────────────────
  GUARANTEE e-8: VERBAL "La finestra guarda se il file è cambiato fuori solo quando torna attiva e
                         quando salva, mai a intervalli di tempo; se torna attiva, il file è cambiato
                         e non ci sono modifiche non salvate, rilancia il controllo e rifà il disegno"
                 VERIFY BY JUDGEMENT "l'operatore, cambiando il file con l'editor di testo e tornando
                                     alla finestra"
  GUARANTEE e-9: VERBAL "Con una modifica non salvata, se la finestra torna attiva e il file è
                         cambiato fuori, la finestra non ricarica e non salva sopra: avvisa e fa
                         scegliere fra ricaricare, perdendo la modifica, e annullare, tenendola"
                 VERIFY BY JUDGEMENT "l'operatore, cambiando il file con l'editor di testo"
  GUARANTEE e-10: VERBAL "Un salvataggio non scrive mai sopra un file cambiato fuori dopo l'ultima
                          lettura della finestra: la persona vede il rifiuto, la modifica resta nella
                          finestra, e ritrova la scelta fra ricaricare e annullare"
                  VERIFY BY INSPECTION "il file prima e dopo il tentativo"

  -- ── Modificare (D-179, D-180, D-193) ───────────────────────────────────
  GUARANTEE e-11: VERBAL "Ogni scrittura di un file CSC la fa bcdd: la finestra non scrive mai un
                          file CSC da sé"
                  VERIFY BY INSPECTION "le scritture del programma della finestra"
  GUARANTEE e-12: VERBAL "Una modifica salvata cambia solo le righe che la persona ha toccato; ogni
                          altra riga resta identica, carattere per carattere"
                  VERIFY BY INSPECTION "differenza fra il file prima e dopo"
  GUARANTEE e-13: VERBAL "La finestra non scrive mai STATUS RATIFIED, e non cambia né toglie una riga
                          che è contratto; se in una VERSION nuova la persona cambia il testo di una
                          riga che ha un suo STATUS RATIFIED BY, la riga passa a STATUS HYPOTHESIS
                          nella stessa modifica"
                  VERIFY BY INSPECTION "le righe contratto prima e dopo"
  GUARANTEE e-14: VERBAL "Una modifica non salvata non si perde in silenzio: chiudere la finestra, o
                          aprire un altro file, con una modifica non salvata chiede che cosa fare"
                  VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE e-15: VERBAL "Nuova crea il file con New di bcdd, che non scrive mai sopra un file che
                          esiste già"
                  VERIFY BY JUDGEMENT "l'operatore, con un nome già usato"
  GUARANTEE e-26: VERBAL "Salva scrive anche un file in cui il controllo trova errori, e subito dopo
                          la finestra mostra gli errori in rosso, con il numero di riga; finché il
                          file ha errori, Affina, Approva e ApprovaCsc non partono"
                  VERIFY BY JUDGEMENT "l'operatore, salvando un DETAILS che nomina una riga che non c'è"

  -- ── Affinare (D-184) ───────────────────────────────────────────────────
  GUARANTEE e-16: VERBAL "Affina fa un giro di affinamento con bcdd, senza chiedere conferma prima
                          della chiamata all'LLM; domande, proposte, sostituzioni, CSC a parte e la
                          riga che dice che la CSC è precisa abbastanza si vedono nella finestra
                          come bcdd le dà"
                  VERIFY BY JUDGEMENT "l'operatore, sui giri delle prove di refine"
  GUARANTEE e-17: VERBAL "Affina, Approva e ApprovaCsc non partono se c'è una modifica non salvata:
                          la finestra dice di salvare prima"
                  VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE e-18: VERBAL "Del giro entrano nel file solo le proposte e le sostituzioni che la persona
                          ha accettato nella finestra; la finestra dice a bcdd solo quali, mai il
                          testo delle righe"
                  VERIFY BY INSPECTION "ciò che la finestra passa a bcdd, e il file prima e dopo"
  GUARANTEE e-19: VERBAL "Dalla finestra non parte nessuna chiamata all'LLM se non con Affina"
                  VERIFY BY INSPECTION "il registro delle chiamate"

  -- ── Approvare (D-185, D-194) ───────────────────────────────────────────
  GUARANTEE e-20: VERBAL "Approva e ApprovaCsc chiedono il numero della decisione, scritto a mano
                          dalla persona; senza numero non succede niente, e la finestra non propone
                          né ricorda un numero"
                  VERIFY BY JUDGEMENT "l'operatore, con il campo del numero vuoto"
  GUARANTEE e-21: VERBAL "Approva vale per una garanzia o per quelle selezionate, e per ciascuna
                          chiama Ratify di bcdd; l'unico altro modo di approvare dalla finestra è
                          ApprovaCsc, e nessuno dei due approva righe che la persona non ha visto
                          elencate o selezionate"
                  VERIFY BY INSPECTION "i comandi che la finestra lancia"
  GUARANTEE e-22: VERBAL "Dalla finestra nessuna riga diventa contratto se non con Ratify di bcdd,
                          con la decisione scritta dalla persona"
                  VERIFY BY INSPECTION "le righe contratto prima e dopo, e i comandi lanciati"
  GUARANTEE e-27: VERBAL "ApprovaCsc approva l'intestazione di una CSC con una sola chiamata a Ratify
                          di bcdd; prima di chiedere il numero elenca tutte le righe che con
                          l'intestazione diventano contratto (l'intestazione, le dichiarazioni, le
                          garanzie e le condizioni senza STATUS suo e senza DETAILS) e quelle che
                          restano ipotesi; dopo, le righe diventate contratto sono quelle elencate"
                  VERIFY BY INSPECTION "l'elenco, il comando lanciato e le righe contratto prima e
                                       dopo"

  -- ── In generale ────────────────────────────────────────────────────────
  GUARANTEE e-23: VERBAL "Quando bcdd rifiuta o non riesce, la persona vede il messaggio di bcdd
                          così com'è, e il file resta come bcdd l'ha lasciato"
                  VERIFY BY JUDGEMENT "l'operatore, con l'LLM che non risponde e con un file
                                       cambiato a metà giro"
  GUARANTEE e-24: VERBAL "La finestra non apre pagine né scarica niente dalla rete, e non accetta
                          collegamenti da altre macchine"
                  VERIFY BY INSPECTION "il programma e le connessioni aperte mentre lavora"
  GUARANTEE e-25: VERBAL "Per ogni riga il disegno dice se l'ha scritta un giro di refine, e se dopo
                          è stata cambiata, leggendolo dal dialogo; per le altre righe dice solo che
                          non vengono da refine"
                  VERIFY BY JUDGEMENT "l'operatore, su una CSC affinata e poi cambiata a mano"

  SCENARIO fileCambiatoConModificaNonSalvata GIVEN nonSalvata = true EXPECT ADMITTED
    @0  attiva
    @1  avviso(testo: "il file è cambiato fuori dalla finestra")
    @2  scelta(ricarica: false)
    @3  requested(Salva), rejected(Salva)              VERBAL "il file è quello cambiato fuori"

  SCENARIO salvareSopraIlFileCambiato GIVEN nonSalvata = true EXPECT REJECTED
    @0  attiva
    @1  avviso(testo: "il file è cambiato fuori dalla finestra")
    @2  scelta(ricarica: false)
    @3  requested(Salva), accepted(Salva), completed(Salva)  VERBAL "il file contiene la modifica della finestra"
                                                       -- viola e-10

  SCENARIO approvareSenzaNumero EXPECT REJECTED
    @0  requested(Approva), accepted(Approva)
    @1  completed(Approva)                             VERBAL "g1 è contratto, e la persona non ha scritto un numero"
                                                       -- viola e-20

  SCENARIO approvareLaCscSenzaElenco EXPECT REJECTED
    @0  requested(ApprovaCsc), accepted(ApprovaCsc)
    @1  completed(ApprovaCsc)                          VERBAL "l'intestazione è contratto, e la finestra non ha mostrato l'elenco"
                                                       -- viola e-27

  SCENARIO approvareLaCscConElenco EXPECT ADMITTED
    @0  requested(ApprovaCsc)
    @1  elenco(righe: _)
    @2  accepted(ApprovaCsc)
    @3  completed(ApprovaCsc)                          VERBAL "sono contratto le righe dell'elenco, e nessun'altra"
END


-- Chi offre EditorBcdd: un programma a parte, che usa bcdd (D-186). Ipotesi.
ENTITY ProgrammaEditor VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il programma bcdd-editor: una finestra a parte, che usa bcdd per controllare,
           affinare, approvare e scrivere i file CSC"
  OFFERS EditorBcdd VERSION 0.1
  USES   BcddTool VERSION 0.7
  USES   BcddProgrammi VERSION 0.2
  USES   FileCsc VERSION 0.1
END
