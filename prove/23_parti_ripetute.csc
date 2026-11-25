-- Prova 23, errore E01 (grammatica 1.2, scelta b): due parti con lo stesso nome nella stessa vista.
-- Il nome della vista e il nome di una parte stanno in elenchi diversi: nessun errore.
-- La stessa CSC nominata da due parti diverse non è un errore.

CSC Uno VERSION 0.1
  PURPOSE "la CSC del file"
END

REFINEMENT VIEW Parti
  COMPOSED OF
    archivio : Archivio
    archivio : Controllore
    Parti    : Archivio
END
