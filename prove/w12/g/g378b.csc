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

CSC P VERSION 0.1
  PURPOSE "sonda"
  STATUS HYPOTHESIS
  IMPORT PROFILE Seg VERSION 0.3
  TYPE Fase := {a, b}
  EVENT IN e(v: Integer)
  EVENT OUT u
  CAPABILITY Cap(f: String)
  STATE s : Boolean INITIAL false
  STATE n : Integer [0 .. 10] INITIAL 0
  STATE r : Real INITIAL 0.0
  STATE f : Fase INITIAL a
  STATE x[Fase] : Integer INITIAL 0
  DEFINE D := 5 s
  GUARANTEE g: DURING (NEAR r TO 1.0): FADE r WITHIN 1 s
END
