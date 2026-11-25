ENTITY Nomi VERSION 0.1
  PURPOSE "prova"
  OFFERS Comune
  VARIANT modo = uno
    OFFERS X
    OFFERS Comune
    COMPOSED OF
      p : A
    GUARANTEE g1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
  VARIANT modo = due
    OFFERS X
    COMPOSED OF
      p : B
    GUARANTEE g1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
  VARIANT colore = rosso
    COMPOSED OF
      p : C
    GUARANTEE g3: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
  VARIANT colore = verde
    GUARANTEE g4: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
END
