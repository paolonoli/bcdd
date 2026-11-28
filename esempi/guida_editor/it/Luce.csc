-- La luce delle scale, vista da chi sta sulle scale.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale vede la luce accesa per il tempo necessario a salire o scendere"

  STATE      accesa : Boolean INITIAL false

  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
END
