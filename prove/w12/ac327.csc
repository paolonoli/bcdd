CSC T VERSION 0.1
  PURPOSE "p"
  TYPE Ch := {L, R}
  STATE s[Real] : Boolean INITIAL false
  STATE clipCount[Ch] : Integer [0 ..] INITIAL 0
  STATE accesa : Boolean INITIAL false
  GUARANTEE g1: ALWAYS accesa[L]
  GUARANTEE g3: ALWAYS clipCount[X] > 1
END
