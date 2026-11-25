-- Prova 14: righe che F1 non sa leggere. Nessuna è un errore, nessuna è taciuta.
riga fuori da ogni blocco

CSC Estranee VERSION 0.1
  PURPOSE "Prova delle righe non riconosciute"
  STATUS HYPOTHESIS
  TYPE Colore := {}
  EVENT IN  pressione FACE utente
  STATE     accesa : Boolean INITIAL false
  DEFINE    DURATA := 180 s
  DEFINE    LIMITE := DURATA * 2
  VERIFY BY JUDGEMENT "VERIFY da sola, dopo una riga che non è una garanzia"
  questa riga è inventata
  guarantee g6: VERBAL "parola chiave in minuscolo" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1: WHENEVER accesa THEN NOT accesa WITHIN DURATA
  GUARANTEE g2: VERBAL "verificata in un modo che F1 non conosce"
                VERIFY BY MAGIC "nessuno"
  GUARANTEE g3 : VERBAL "spazio prima dei due punti: va bene" VERIFY BY INSPECTION "il file"
  GUARANTEE g4: VERBAL "una seconda verifica rende la riga non riconosciuta"
                VERIFY BY JUDGEMENT "l'operatore"
                VERIFY BY INSPECTION "il registro"
  GUARANTEE g5 DETAILS g1: VERBAL "figlio di una riga formale: il padre esiste"
                           VERIFY BY JUDGEMENT "l'operatore"
  ASSUME a1: ALWAYS NOT accesa
  @0 pressione
END
