CSC Canale VERSION 0.3
  PURPOSE "Un canale"
END

ENTITY Versioni VERSION 0.1
  PURPOSE "Citazioni con versione"
  OFFERS Canale VERSION 0.3
  USES Canale VERSION 0.2
  OFFERS Luce VERSION 0.2
  OFFERS Pressione VERSION 0.1
  OFFERS Comando VERSION v1
  COMPOSED OF
    e : Emittente
    r : Ricevente
END
