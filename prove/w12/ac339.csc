CSC T VERSION 0.1
  PURPOSE "p"
  TYPE Fase := {inattiva, armata}
  STATE fase : Fase INITIAL inattiva
  STATE bf : Boolean INITIAL false
  EVENT IN arma
  EVENT IN disarma
  GUARANTEE t1: TRANSITION fase: inattiva -> armata ON arma, armata -> inattiva ON disarma
  GUARANTEE t2: TRANSITION bf: inattiva -> armata ON arma
END
