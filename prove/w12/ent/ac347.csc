ENTITY LuceScale VERSION 0.1
  PURPOSE "l"
  OFFERS Pressione
  OFFERS Luce
  GUARANTEE g1: WHENEVER Pressione.pressione AND NOT Luce.accesa THEN Luce.accesa WITHIN 1 s
END
