-- FUNZIONE «misura dell'ambiente» (fase Misure), al confine con l'ingresso L della scheda di cattura.
-- La svolge il microfono di misura (D-337). Le proprietà del microfono stanno nell'entità MicrofonoMisura.
-- Fase 2, non qui: uscita XLR, phantom 48 V dalla scheda (§6 R-MIC). Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §2 S-MIS; operatore, D-337.

CSC SegnaleMisura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Misura dell'ambiente: il microfono porta all'ingresso L della scheda di cattura il suono della stanza nel punto di misura"
  GUARANTEE ms1 STATUS RATIFIED BY D-338: VERBAL "In Misure il segnale sull'ingresso L è il suono della stanza raccolto dal microfono di misura, registrato da AP insieme al riferimento (fonte: §2 S-MIS, AP-R §2 [B]; operatore, D-337)"
                 VERIFY BY JUDGEMENT "l'operatore, che esegue una misura e guarda la risposta d'ambiente"
END
