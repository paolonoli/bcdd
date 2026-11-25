PROFILE Seg VERSION 0.3
  PURPOSE "p"
  STATUS HYPOTHESIS
  EXTENSION FADE
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (s: Expression, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "m"
    VERIFY   V1 C1, C3 ; V2 "r"
    SOURCE   "s"
  END
  EXTENSION NEAR
    KIND     FUNCTION
    LEVEL    CSC
    PARAMS   (x: Real, a: Real) : Boolean
    FORM     "NEAR x TO a"
    MEANING  "m"
    VERIFY   V1 C2 ; V2 "r"
    SOURCE   "s"
  END
  EXTENSION SIGNAL
    KIND     DECLARATION
    LEVEL    CSC
    PARAMS   (nome: Name, T: Type)
    FORM     "SIGNAL nome : T"
    MEANING  "m"
    VERIFY   BY JUDGEMENT "x"
    SOURCE   "s"
  END
  EXTENSION DURING
    KIND     SCOPE
    LEVEL    CSC
    PARAMS   (c: Condition)
    FORM     "DURING c"
    MEANING  "m"
    VERIFY   V1 C4 ; V2 "r"
    SOURCE   "s"
  END
END

PROFILE Due VERSION 0.1
  PURPOSE "p"
  STATUS HYPOTHESIS
  EXTENSION CONTRO
    KIND     PATTERN
    LEVEL    CSC
    PARAMS   (c: Condition)
    FORM     "CONTRO c"
    MEANING  "m"
    VERIFY   V1 C2 ; V2 "r"
    SOURCE   "s"
  END
END

CSC P VERSION 0.1
  IMPORT PROFILE Seg VERSION 0.3
  IMPORT PROFILE Due VERSION 0.1
  PURPOSE "sonda"
  STATUS HYPOTHESIS
  EVENT IN e(v: Integer)
  STATE s : Boolean INITIAL false
  STATE n : Integer [0 .. 10] INITIAL 0
  GUARANTEE g1: FADE n WITHIN 2 s
  GUARANTEE g2: DURING s: ALWAYS s
  GUARANTEE g3: CONTRO s
  SCENARIO s1 EXPECT ADMITTED
    @0 e(v: 1)
END
