-- FUNZIONE «rilevamento del livello d'uscita» (fase Riproduzione), al confine con l'ingresso L della scheda di cattura.
-- La svolge la DI ai morsetti (oggi in AP: AP-W94, G-06) OPPURE lo stesso microfono di misura, fermo vicino al
-- diffusore: scelta di progetto dell'operatore (D-337), con il supporto di AP DA CONFERMARE (domanda D6
-- dell'ESITO). Chi la svolge lo dice la composizione del kit: DirectBox o MicrofonoMisuraELivello la offrono.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §2 S-RIP, S-TAR, §3; operatore, D-337.

CSC SegnaleLivello VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Rilevamento del livello d'uscita: il sensore di livello porta all'ingresso L della scheda di cattura un segnale che segue il livello mandato ai diffusori"
  GUARANTEE sl1 STATUS RATIFIED BY D-338: VERBAL "Il segnale del sensore cambia con il livello mandato ai diffusori, così che AP ne segua il volume dopo la Taratura (fonte: §2 S-RIP e S-TAR, AP-W155 [C]; operatore, D-337)"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia il volume dopo la Taratura e guarda il livello seguito da AP"
END
