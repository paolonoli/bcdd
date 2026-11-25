-- Prova 04, errore E03: uno scenario nomina ciò che la CSC non dichiara,
-- o lo usa come la cosa sbagliata.

CSC Nomi VERSION 0.1
  PURPOSE "Prova del nome usato e mai dichiarato"

  CAPABILITY Avvia
  EVENT IN   arrivo(valore: Integer)
  STATE      pronto : Boolean INITIAL false

  SCENARIO s1 GIVEN acceso = true EXPECT ADMITTED
    @0  requested(Avvia), accepted(Partenza)
    @1  arrivo(valore: 3, peso: 2)
    @2  uscita                         pronto = true
    @3  pronto                         arrivo = 1
END
