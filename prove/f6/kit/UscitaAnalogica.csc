-- Il confine fra la scheda che porta il programma all'amplificatore e il cavo di loop.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §5 (varianti), §6 R-FLX e «R-CAP nell'1.a e scheda unica».

CSC UscitaAnalogica VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Un'uscita analogica della scheda che alimenta l'amplificatore, da cui si preleva il loop"
  GUARANTEE ua1 STATUS RATIFIED BY D-338: VERBAL "L'uscita porta lo stesso segnale che va all'amplificatore: con amplificatore analogico è la stessa uscita, con amplificatore digitale è la copia analogica dello S/PDIF sulla stessa scheda (fonte: §5 varianti, AP-R §6 [B]; §6 R-FLX)"
                 VERIFY BY JUDGEMENT "l'operatore, che confronta l'uscita del loop con quella verso l'amplificatore"
END
