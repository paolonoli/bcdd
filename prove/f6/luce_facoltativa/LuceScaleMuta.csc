ENTITY LuceScaleMuta VERSION 0.3
  PURPOSE "La luce delle scale, con o senza crepuscolare"
  OFFERS Pressione
  OFFERS Luce
  COMPOSED OF
    pulsante     : Pulsante
    lampada      : Lampada
    crepuscolare : CrepuscolareMuto [0 .. 1]
  GUARANTEE g1: VERBAL "Una pressione a luce spenta accende la luce entro 1 s, se e' buio o se il crepuscolare non c'e'"
                VERIFY BY JUDGEMENT "l'operatore"
END
