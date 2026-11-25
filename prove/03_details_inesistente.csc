-- Prova 03, errore E02: DETAILS nomina una riga che non c'è, o che non è una garanzia.

CSC Dettagli VERSION 0.1
  PURPOSE "Prova del DETAILS senza padre"

  EVENT IN  arrivo

  GUARANTEE g1: VERBAL "padre" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1a DETAILS g1: VERBAL "figlio corretto" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2a DETAILS g2: VERBAL "il padre g2 non esiste" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3a DETAILS arrivo: VERBAL "arrivo è un evento" VERIFY BY JUDGEMENT "l'operatore"
END
