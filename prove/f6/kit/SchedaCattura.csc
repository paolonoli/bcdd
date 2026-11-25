-- R-CAP, la scheda di cattura (1.b a due schede): ingresso L (XLR con phantom) e ingresso R (linea).
-- Usa insieme le tre funzioni SegnaleMisura, SegnaleLivello e Riferimento: la riga USES non dice in quale fase
-- (lacuna L3); l'alternanza delle due funzioni su L sta in Ricablaggio e nella garanzia k3 del kit. Che cosa una scheda reale deve avere è la fase 2 (§6 R-CAP).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1, §3, §6 R-CAP.

ENTITY SchedaCattura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La scheda che riceve sull'ingresso L la misura dell'ambiente o il sensore di livello e il riferimento sull'ingresso R, e li porta al calcolatore"
  USES   SegnaleMisura
  USES   SegnaleLivello
  USES   Riferimento
  OFFERS Ricablaggio
  OFFERS AudioUsb
END
