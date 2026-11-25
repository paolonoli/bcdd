CSC P VERSION 0.1
  PURPOSE "sonda"
  STATUS HYPOTHESIS
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
  GUARANTEE g1: ALWAYS x[a][a] > 0
  GUARANTEE g2: ALWAYS x[a] > 0
END
