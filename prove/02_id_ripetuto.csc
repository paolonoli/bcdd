-- Prova 02, errore E01: lo stesso nome o id usato due volte nella stessa CSC.
-- Quattro casi: due garanzie g1; uno stato con il nome di un evento; un parametro ripetuto;
-- due CSC con lo stesso nome nello stesso file.

CSC Ripetizioni VERSION 0.1
  PURPOSE "Prova del nome ripetuto"

  EVENT IN  arrivo(valore: Integer, valore: Integer)
  STATE     arrivo : Boolean INITIAL false

  GUARANTEE g1: VERBAL "prima" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1: VERBAL "seconda, stesso id" VERIFY BY JUDGEMENT "l'operatore"
END

CSC Ripetizioni VERSION 0.2
  PURPOSE "stesso nome della CSC sopra"
END
