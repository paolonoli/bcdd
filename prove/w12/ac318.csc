CSC T VERSION 0.1
  PURPOSE "p"
  EVENT IN pressione
  STATE accesa : Boolean INITIAL false
  GUARANTEE g1: WHENEVER pressione THEN
                  accesa WITHIN 1 s
END
