-- Lo STESSO microfono di MicrofonoMisura, che nel kit senza DI svolge due funzioni in fasi diverse: misura
-- dell'ambiente in Misure, rilevamento del livello in Riproduzione (D-337). In AP sarà una «DI virtuale»
-- (W-207 di AP, non iniziato): deciso dall'operatore il 16/11, [A] fino alla prova al banco (AP-R2 D6).
-- È un'entità a parte solo perché la composizione non sa dire quale funzione svolge una parte in quale fase
-- (lacune L3 e L4 dell'ESITO): non è un dispositivo diverso. Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §6 R-MIC; operatore, D-337.

ENTITY MicrofonoMisuraELivello VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il microfono di misura del kit senza DI: misura l'ambiente in Misure e, fermo vicino al diffusore, rileva il livello d'uscita in Riproduzione"
  OFFERS SegnaleMisura
  OFFERS SegnaleLivello
  GUARANTEE ml1 STATUS RATIFIED BY D-338: VERBAL "Il microfono di misura è omnidirezionale; il suo file di calibrazione è facoltativo, in testo «frequenza, dB», normalizzato fra 200 e 2000 Hz (fonte: §6 R-MIC [B], AP-R §5, D-14)"
                 VERIFY BY INSPECTION "la scheda del microfono e il suo file di calibrazione"
END
