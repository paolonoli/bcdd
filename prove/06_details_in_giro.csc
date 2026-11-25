-- Prova 06, errore E05: i DETAILS formano un giro (anche un giro di una sola riga).

CSC Giri VERSION 0.1
  PURPOSE "Prova del giro di DETAILS"

  GUARANTEE g1 DETAILS g3: VERBAL "uno" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 DETAILS g1: VERBAL "due" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3 DETAILS g2: VERBAL "tre" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g4 DETAILS g4: VERBAL "se stessa" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g5 DETAILS g1: VERBAL "fuori dal giro, nessun errore" VERIFY BY JUDGEMENT "l'operatore"
END
