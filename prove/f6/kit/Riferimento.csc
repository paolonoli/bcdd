-- Il confine fra il cavo di loop e l'ingresso R della scheda di cattura: il riferimento elettrico della misura.
-- Fase 2, non qui: che il livello del riferimento non saturi l'ingresso R (G-09).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-REF, §4 G-03, G-09; risposta di AudioKits Q-AK-5.

CSC Riferimento VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il cavo di loop porta all'ingresso R della scheda di cattura il segnale che alimenta l'amplificatore, come riferimento della misura"
  GUARANTEE rf1 STATUS RATIFIED BY D-338: VERBAL "Il riferimento parte dall'uscita che alimenta l'amplificatore, o dalla sua copia analogica sulla stessa scheda del flusso, mai da una copia generata dalla scheda di cattura (fonte: G-03 [O], D-10; Q-AK-4, Q-AK-5)"
                 VERIFY BY INSPECTION "il percorso del cavo di loop nel kit montato"
END
