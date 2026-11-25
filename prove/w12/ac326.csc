CSC T VERSION 0.1
  PURPOSE "p"
  TYPE Ch := {L, R}
  STATE clipCount[Ch] : Integer [0 ..] INITIAL 0
  SCENARIO s1 GIVEN clipCount[L] = 2 EXPECT ADMITTED
END
