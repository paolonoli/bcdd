ENTITY E VERSION 0.1
  PURPOSE "e"
  OFFERS Flusso
  SCENARIO s1 EXPECT ADMITTED
    @0 s Flusso.campione(livello: "alto")
    @1 s Flusso.lettura(livello: "alto")
END
