ENTITY DettaglioComune VERSION 0.1
  PURPOSE "prova"
  GUARANTEE c1 DETAILS u1: VERBAL "riga comune che dettaglia una scelta"
    VERIFY BY JUDGEMENT "l'operatore"
  VARIANT modo = uno
    GUARANTEE u1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
  VARIANT modo = due
    GUARANTEE d1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
END
