CSC T VERSION 0.1
  IMPORT PROFILE Segnale VERSION 0.3
  PURPOSE "x"
  STATE modo : Boolean INITIAL false
  STATE luminosita : Real INITIAL 0.0
  GUARANTEE g10: WHILE modo = false: FADE luminosita WITHIN 2 s
  GUARANTEE g11: FADE luminosita
  GUARANTEE g12: ALWAYS FADE(luminosita) > 1
END
