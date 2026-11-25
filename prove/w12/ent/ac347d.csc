ENTITY LuceScale VERSION 0.1
  PURPOSE "l"
  OFFERS Pressione
  OFFERS Manca
  GUARANTEE g1: WHENEVER Pressione.pressione THEN Manca.x WITHIN 1 s
END
