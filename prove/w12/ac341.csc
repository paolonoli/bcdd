CSC T VERSION 0.1
  PURPOSE "p"
  TYPE Fase := {a1, a2}
  TYPE Modo := {m1, m2}
  STATE accesa : Boolean INITIAL "sì"
  STATE n : Integer [0 .. 3] INITIAL 5
  STATE d : Duration INITIAL 0
  STATE fase : Fase INITIAL a1
  SCENARIO s1 GIVEN fase = m1 EXPECT ADMITTED
END
