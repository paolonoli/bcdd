-- Il flusso di letture continue (una al secondo) che il computer può chiedere al telefono.
-- Il computer offre il canale e conta ciò che arriva; l'obbligo del telefono è in ComportamentoTelefono (te6).
-- Fonte: contratto 1.13, §6.4 (RC-SM-*).

CSC Flusso VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il computer chiede al telefono un flusso di letture, una al secondo, e lo riceve; oggi nessuna parte del computer lo chiede"
  EVENT OUT chiedi_flusso(avvia: Boolean)
  EVENT IN  apri_flusso
  EVENT IN  campione(livello: Real)
  EVENT IN  chiudi_flusso
  EVENT OUT fermato(motivo: String)
  STATE aperto : Boolean INITIAL false
  GUARANTEE fl1: VERBAL "Il computer chiede il flusso solo quando una sua parte lo usa davvero; oggi nessuna"
                 VERIFY BY INSPECTION "il codice del computer che chiede il flusso"
  GUARANTEE fl2: VERBAL "La richiesta va a tutti i telefoni pronti e vince il primo che apre; una richiesta non raccolta scade dopo 10 s, e apre solo chi è stato chiamato"
                 VERIFY BY JUDGEMENT "l'operatore, con due telefoni collegati"
  GUARANTEE fl3: VERBAL "Un buco è un buco: il computer non riempie, non ripete e non inventa campioni mancanti, li conta"
                 VERIFY BY INSPECTION "il riepilogo di un flusso con campioni persi"
  GUARANTEE fl4: VERBAL "Un campione non riceve mai risposta: ciò che il computer ha scartato o trovato fuori ritmo lo dice solo il riepilogo alla fine del flusso"
                 VERIFY BY INSPECTION "il riepilogo di un flusso con campioni irregolari"
  GUARANTEE fl5: VERBAL "Il flusso finisce se per 5 s non arriva niente, se il collegamento cade o se una delle due parti lo chiude; non riparte mai da solo, ci vuole una richiesta nuova"
                 VERIFY BY JUDGEMENT "l'operatore, che stacca il telefono a metà flusso"
  GUARANTEE fl6: VERBAL "Un campione del flusso non vale mai come lettura della taratura, e la lettura della taratura non vale come campione"
                 VERIFY BY INSPECTION "la taratura durante un flusso aperto"
END
