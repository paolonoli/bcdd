ENTITY Posizioni VERSION 0.1
  PURPOSE "Una parte vale dovunque stia nell'entità"
    prima : Pulsante
  GUARANTEE g1: VERBAL "La prima garanzia"
                VERIFY BY JUDGEMENT "l'operatore"
    fraGaranzie : Pulsante
  GUARANTEE g2: VERBAL "La seconda garanzia,
su due righe"
                VERIFY BY JUDGEMENT "l'operatore"
    dopoStringa : Pulsante
  OFFERS Luce
    dopoOffers : Pulsante
  COMPOSED OF
    FOO bar
    dopoRigaInventata : Pulsante
    VERIFY BY INSPECTION "dopo una parte"
    dopoVerify : Pulsante
  COMPOSED OF
    dopoSecondaComposed : Pulsante
  GUARANTEE g3: VERBAL "Una stringa che contiene
    dentro : Lampada
e non è una parte"
                VERIFY BY JUDGEMENT "l'operatore"
    lampada : Lampada
END

ENTITY SenzaComposed VERSION 0.1
  PURPOSE "Una entità con una parte e senza COMPOSED OF"
  lampada : Lampada
END
