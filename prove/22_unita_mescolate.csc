-- Prova 22, errore E12 (grammatica 1.2, scelta a): con unità mescolate c'è un E12 per ogni passo che
-- non segue il primo passo dello scenario, e quel passo non conta nel confronto dei tempi.

CSC Unita VERSION 0.1
  PURPOSE "Prova delle unità mescolate"

  EVENT IN arrivo

  SCENARIO misto EXPECT ADMITTED
    @0 s    arrivo
    @5      arrivo
    @3 s    arrivo
    @2 s    arrivo
    @7      arrivo
    @250 ms arrivo
END
