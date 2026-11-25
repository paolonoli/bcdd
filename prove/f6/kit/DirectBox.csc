-- R-DI: svolge il rilevamento del livello d'uscita ai morsetti di un diffusore passivo.
-- La DI come riferimento in Misure (AP-W94; A-02 residuo) è un'altra funzione, Riferimento: non modellata qui.
-- Fase 2, non qui: connettori, attenuatori, livelli massimi, phantom o pila (§6 R-DI).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1, §6 R-DI; operatore, D-336 e D-337.

ENTITY DirectBox VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La direct box del kit: legge il segnale ai morsetti di un diffusore e lo porta alla scheda di cattura come sensore di livello"
  USES   Morsetti
  OFFERS SegnaleLivello
  GUARANTEE di1 STATUS RATIFIED BY D-338: VERBAL "Il livello d'uscita della DI è il livello ai morsetti meno l'attenuazione scelta: l'attenuatore si sceglie in base all'ingresso che la riceve (fonte: §1 e §6 R-DI [C], AP-R §5; [O] operatore 2026-11-16)"
                 VERIFY BY JUDGEMENT "l'operatore, che confronta il livello letto con due posizioni dell'attenuatore"
  GUARANTEE di2 STATUS RATIFIED BY D-338: VERBAL "La DI esce con un segnale sostanzialmente di linea, spesso bilanciato, e può entrare anche in un ingresso di linea (fonte: operatore, D-336)"
                 VERIFY BY INSPECTION "la scheda della DI"
END
