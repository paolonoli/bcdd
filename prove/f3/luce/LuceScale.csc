ENTITY LuceScale VERSION 0.2
  PURPOSE "La luce delle scale"
  OFFERS Pressione
  OFFERS Luce
  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada
  GUARANTEE g1: VERBAL "Una pressione a luce spenta accende la luce entro 1 s"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
END
