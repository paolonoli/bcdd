-- Prova D-168 (grammatica 1.10): le parole uscite dal linguaggio restano riservate.

CSC ParoleUscite VERSION 0.1
  PURPOSE "FACE, LINK, MAP, REFINEMENT e VIEW non si usano come nomi"
  CAPABILITY FACE
  EVENT IN LINK
  STATE MAP : Boolean INITIAL false
  EVENT OUT VIEW
  CAPABILITY Vista(REFINEMENT: String)
END
