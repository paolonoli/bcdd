-- Prova D-168 (grammatica 1.10): i campi di EXTENSION sono riservati, in ogni posto di un nome.

CSC CampiEstensione VERSION 0.1
  PURPOSE "I campi di EXTENSION non si usano come nomi"
  EVENT IN KIND
  STATE LEVEL : Boolean INITIAL false
  DEFINE PARAMS := 3
  CAPABILITY Scrivi(FORM: String)
  STATE testo : MEANING INITIAL ""
  GUARANTEE REDUCES: VERBAL "un campo come id" VERIFY BY JUDGEMENT "l'operatore"
  EVENT OUT arrivo(da: String)
  SCENARIO TO EXPECT ADMITTED
  SCENARIO s1 EXPECT ADMITTED
    @0 arrivo(SOURCE: "x")
END
