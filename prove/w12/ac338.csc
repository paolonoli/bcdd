CSC T VERSION 0.1
  PURPOSE "p"
  STATE accesa : Boolean INITIAL false
  EVENT IN pressione
  GUARANTEE g1: ALWAYS COUNT(accesa) > 0
  GUARANTEE g2: ALWAYS requested(pressione)
END
