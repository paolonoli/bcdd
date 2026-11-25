-- F0 di W-51: parte di BcddTool (REFINEMENT VIEW BcddToolParti). A parole, ipotesi.
-- VERSION 0.2 (D-134 (a2), D-136 (2); DESIGN_F2 1.3): w-4 sul posto delle righe aggiunte; CambiaStato
-- su più righe in una sola scrittura.
-- VERSION 0.3 (D-140; DESIGN_F2 1.5): Sostituisci, la riga nuova al posto della vecchia (w-2, w-5).
-- VERSION 0.4 (D-156; DESIGN_F3 1.3): il contenuto del file passa alla CSC FileCsc.

CSC Archivio VERSION 0.4
  STATUS HYPOTHESIS
  PURPOSE "È l'unica parte che scrive i file CSC: crea gli scheletri, aggiunge le righe
           accettate, sostituisce le righe ipotesi accettate, cambia lo stato delle righe
           ratificate"

  CAPABILITY Crea(nome: String)
  CAPABILITY Aggiungi(file: String, righe: Sequence of String)
  CAPABILITY Sostituisci(file: String, righe: Sequence of String)  -- ogni voce: l'id e le righe nuove
  CAPABILITY CambiaStato(file: String, righe: Sequence of String, decisione: String)  -- nessuna riga: l'intestazione

  GUARANTEE w-1: VERBAL "Crea non sovrascrive un file esistente"
                 VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE w-2: VERBAL "Aggiungi, Sostituisci e CambiaStato cambiano solo le righe indicate, o lo stato
                         nell'intestazione della CSC; il resto del file resta identico,
                         carattere per carattere"
                 VERIFY BY INSPECTION "differenza fra il file prima e dopo"
  GUARANTEE w-3: VERBAL "Una scrittura o riesce per intero o lascia il file com'era: mai un
                         file scritto a metà"
                 VERIFY BY JUDGEMENT "l'operatore, interrompendo il comando"
  GUARANTEE w-4: VERBAL "Aggiungi mette ogni riga nuova dopo l'ultimo dettaglio già presente della
                         riga che dettaglia, contando anche i dettagli dei dettagli, e le righe
                         nuove nell'ordine in cui arrivano: un dettaglio non si stacca mai dalla
                         riga che dettaglia"
                 VERIFY BY INSPECTION "il file prima e dopo, con dettagli già presenti su due livelli"
  GUARANTEE w-5: VERBAL "Sostituisci mette le righe nuove al posto della dichiarazione indicata,
                         nello stesso punto: l'inizio della prima riga fino ai due punti (tipo, id,
                         DETAILS, STATUS) resta identico, e restano identiche tutte le altre righe,
                         compresi i dettagli della riga sostituita"
                 VERIFY BY INSPECTION "il file prima e dopo, con una sostituzione di una riga che ha dettagli"
END
