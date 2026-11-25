CSC T VERSION 0.1
  IMPORT PROFILE Segnale VERSION 0.3
  PURPOSE "p"
  STATE modo : Boolean INITIAL false
  STATE luminosita : Real INITIAL 0.0
  GUARANTEE g10: WHILE modo = true: FADE luminosita WITHIN 2 s
END
