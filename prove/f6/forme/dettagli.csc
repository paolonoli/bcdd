ENTITY Dettagli VERSION 0.1
  PURPOSE "prova"
  GUARANTEE c1: VERBAL "una promessa"
    VERIFY BY JUDGEMENT "l'operatore"
  VARIANT modo = uno
    GUARANTEE u1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
    GUARANTEE u1a DETAILS u1: VERBAL "dettaglio nella stessa scelta"
      VERIFY BY JUDGEMENT "l'operatore"
    GUARANTEE u1b DETAILS c1: VERBAL "dettaglio di una riga comune"
      VERIFY BY JUDGEMENT "l'operatore"
  VARIANT modo = due
    GUARANTEE d1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
    GUARANTEE d1a DETAILS u1: VERBAL "dettaglio di un'altra scelta"
      VERIFY BY JUDGEMENT "l'operatore"
END
