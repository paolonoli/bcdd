CSC Prova VERSION 0.1
  PURPOSE "prova"
  STATE modo : Boolean INITIAL false
  GUARANTEE g4: VERBAL "x"
                VERIFY BY JUDGEMENT "y"
  EXTENSION FADE
    KIND     pattern
    LEVEL    Core
    PARAMS   (s: SIGNAL, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "m"
    VERIFY   BY JUDGEMENT "una persona che guarda"
    SOURCE   "g10"
  END
END
