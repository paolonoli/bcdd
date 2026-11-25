ENTITY SistemaFacoltativo VERSION 0.1
  PURPOSE "Il modulo, con l'alimentatore se si vuole"
  OFFERS Uscita
  COMPOSED OF
    modulo : Modulo
    alim   : Alimentatore [0 .. 1]
END
