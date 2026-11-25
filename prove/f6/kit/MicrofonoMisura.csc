-- R-MIC nel kit con la DI come sensore di livello: il microfono svolge la sola misura dell'ambiente.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1, §6 R-MIC.

ENTITY MicrofonoMisura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il microfono di misura del kit, usato solo per la misura dell'ambiente"
  OFFERS SegnaleMisura
  GUARANTEE mm1 STATUS RATIFIED BY D-338: VERBAL "Il microfono di misura è omnidirezionale; il suo file di calibrazione è facoltativo, in testo «frequenza, dB», normalizzato fra 200 e 2000 Hz (fonte: §6 R-MIC [B], AP-R §5, D-14)"
                 VERIFY BY INSPECTION "la scheda del microfono e il suo file di calibrazione"
  GUARANTEE mm1b DETAILS mm1 STATUS RATIFIED BY D-338: VERBAL "Quando il file di calibrazione del microfono di misura manca, la misura procede senza alcuna correzione e senza alcun avviso alla persona."
                                                VERIFY BY JUDGEMENT "l'operatore, che esegue una misura senza file di calibrazione e verifica che la misura si completi senza correzione e senza alcun messaggio di avviso"
END
