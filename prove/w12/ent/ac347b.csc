ENTITY LuceScale VERSION 0.1
  PURPOSE "l"
  OFFERS Pressione
  GUARANTEE g1: WHENEVER Pressione.pressione AND NOT Luce.accesa THEN Luce.accesa WITHIN 1 s
  GUARANTEE g2: ALWAYS Pressione.zzz
  GUARANTEE g3: WHENEVER Pressione.pressione THEN accesa WITHIN 1 s
END
