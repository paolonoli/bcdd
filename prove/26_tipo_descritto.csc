-- Prova 26 (F2, decisione D-127 (1)): tipi descritti a parole con TYPE Nome := VERBAL "…".
-- Un tipo descritto esce dalla sezione 6 del rapporto; restano lì solo i tipi senza descrizione.

CSC Tipi VERSION 0.1
  PURPOSE "Prova dei tipi descritti a parole"

  CAPABILITY Leggi(t: Testo, r: Rapporto, s: Struttura)
  TYPE Testo    := VERBAL "il contenuto di un file, riga per riga"
  TYPE Rapporto := VERBAL "il rapporto di bcdd check"
  TYPE Colore   := {rosso, verde}
  TYPE Boolean  := VERBAL "un tipo di base non si descrive di nuovo"
  EVENT IN Testo
  TYPE Ritardo  := VERBAL "una durata"
                   VERIFY BY JUDGEMENT "un tipo non è una proprietà: niente VERIFY"
END
