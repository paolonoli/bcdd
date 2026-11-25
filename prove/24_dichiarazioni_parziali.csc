-- Prova 24 (grammatica 1.2, scelta c): che cosa registra una dichiarazione non riconosciuta.
-- GUARANTEE e ASSUME con intestazione valida, e DEFINE fino a ":=", registrano il nome.
-- CAPABILITY, EVENT, STATE e SCENARIO non riconosciuti non registrano nulla.

CSC Parziali VERSION 0.1
  PURPOSE "Prova delle dichiarazioni parziali"

  GUARANTEE g1: ALWAYS accesa
  GUARANTEE g1: VERBAL "stesso id di una riga formale: E01" VERIFY BY JUDGEMENT "l'operatore"
  DEFINE LIMITE := DURATA * 2
  STATE LIMITE : Boolean INITIAL false
  CAPABILITY Accendi(quando: )
  EVENT IN   Accendi
  STATE      accesa Boolean INITIAL false
  SCENARIO   s1 EXPECT FORSE
    @0 requested(Accendi)
  SCENARIO   s1 GIVEN accesa = false EXPECT ADMITTED
    @0 Accendi
END
