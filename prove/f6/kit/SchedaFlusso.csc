-- R-FLX, la scheda del flusso (solo 1.b a due schede): porta il programma dalla sorgente all'amplificatore.
-- Che cosa una scheda reale deve avere per questo ruolo è la fase 2 (§6 R-FLX). Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1, §5, §6 R-FLX.

ENTITY SchedaFlusso VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La scheda che porta il programma dalla sorgente al calcolatore e dal calcolatore all'amplificatore, con un'uscita analogica per il loop"
  USES   Programma
  USES   IngressoAmplificatore
  OFFERS UscitaAnalogica
  OFFERS AudioUsb
END
