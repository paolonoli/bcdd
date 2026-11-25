-- Prova 13, errore E12: il tempo dei passi diminuisce, o mescola passi con e senza unità.

CSC Tempi VERSION 0.1
  PURPOSE "Prova del tempo dei passi"

  EVENT IN arrivo

  SCENARIO indietro EXPECT ADMITTED
    @0 s    arrivo
    @5 s    arrivo
    @3 s    arrivo
    @4000 ms arrivo
    @6 s    arrivo

  SCENARIO misto EXPECT ADMITTED
    @0      arrivo
    @1 s    arrivo
    @2      arrivo
END
