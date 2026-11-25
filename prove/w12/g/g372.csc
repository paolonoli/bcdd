PROFILE Seg VERSION 0.3
  PURPOSE "p"
  STATUS HYPOTHESIS
  EXTENSION SIGNAL
    KIND     DECLARATION
    LEVEL    CSC
    PARAMS   (nome: Name, I: Type, T: Type)
    FORM     "SIGNAL nome[I] : T"
    MEANING  "m"
    VERIFY   BY JUDGEMENT "x"
    SOURCE   "s"
  END
  EXTENSION LAMP
    KIND     DECLARATION
    LEVEL    BINDING
    PARAMS   (nome: Name, T: Type)
    FORM     "LAMP nome : T"
    MEANING  "m"
    VERIFY   BY JUDGEMENT "x"
    SOURCE   "s"
  END
END

CSC P VERSION 0.1
  IMPORT PROFILE Seg VERSION 0.3
  PURPOSE "sonda"
  STATUS HYPOTHESIS
  TYPE Fase := {a, b}
  STATE s : Boolean INITIAL false
  SIGNAL ago[Fase] : Real
  GUARANTEE g: ALWAYS ago[a] > 1
  SIGNAL s[Fase] : Real
END

BINDING P VERSION 0.1
  IMPORT PROFILE Seg VERSION 0.3
  BIND s: VERBAL "x"
  LAMP luce : Boolean
  LAMP luce : Boolean
END
