ENTITY LuceScale VERSION 0.2
  PURPOSE "La luce delle scale"
  OFFERS Pressione
  OFFERS Luce
  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada
  GUARANTEE ls1 STATUS RATIFIED BY D-6: VERBAL "Una pressione a Luce spenta la accende"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  SCENARIO ls-s1 EXPECT ADMITTED
    @0 s   Pressione.premuto
    @1 s   Luce.accesa = true
END
