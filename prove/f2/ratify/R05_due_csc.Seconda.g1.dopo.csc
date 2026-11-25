-- Prova F2 di ratify: due CSC nello stesso file, con gli stessi id.

CSC Prima VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "la prima"
  GUARANTEE g1: VERBAL "della prima" VERIFY BY JUDGEMENT "l'operatore"
END

CSC Seconda VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "la seconda"
  GUARANTEE g1 STATUS RATIFIED BY D-130: VERBAL "della seconda" VERIFY BY JUDGEMENT "l'operatore"
END
