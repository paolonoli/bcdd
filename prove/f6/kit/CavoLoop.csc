-- R-REF, il cavo di loop: è una parte perché porta il riferimento della misura. Asta e altri cavi (XLR del
-- microfono e della DI, cavo dai morsetti, cavo ottico o coassiale) sono nel kit (Q-AK-2) ma non hanno un
-- comportamento proprio: non sono parti di questo esempio. Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-REF, G-03.

ENTITY CavoLoop VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il cavo che porta all'ingresso R della scheda di cattura il segnale che alimenta l'amplificatore"
  USES   UscitaAnalogica
  OFFERS Riferimento
END
