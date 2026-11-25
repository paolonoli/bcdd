ENTITY Scale VERSION 0.1
  PURPOSE "La luce delle scale, vista da chi sta sulle scale"
  OFFERS Pressione
  OFFERS Luce VERSION 0.1
  GUARANTEE g1 STATUS RATIFIED BY D-200: VERBAL "Una pressione a luce spenta accende la luce entro 1 s"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS RATIFIED BY D-200: VERBAL "La luce accesa da una pressione è piena"
                                              VERIFY BY JUDGEMENT "l'operatore, guardando"
  GUARANTEE g2 STATUS RATIFIED BY D-5: VERBAL "Senza pressioni la luce non si accende da sola"
                                       VERIFY BY JUDGEMENT "l'operatore, per dieci minuti"
END
