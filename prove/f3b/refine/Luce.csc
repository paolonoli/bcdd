CSC Luce VERSION 0.1
  PURPOSE "Il confine fra la lampada e chi sta sulle scale: la luce che si vede"
  STATE accesa : Boolean INITIAL false
  GUARANTEE l1: VERBAL "La luce è piena, ridotta a circa metà o spenta: nient'altro"
                VERIFY BY JUDGEMENT "l'operatore, guardando"
END
