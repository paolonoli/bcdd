-- R-TEL, dell'utente: il telefono Android con la sua app (LevelMeter nel caso di controllo remoto),
-- come telecomando (Modalita) e come fonometro in Taratura (LetturaLivello). È la parte «telefono : LevelMeter»
-- di caso_remoto vista solo per ciò che serve ai kit; spl.stream è fuori (Q-AK-7, A-01).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1, §6 R-TEL; Q-AK-7.

ENTITY Telefono VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono dell'utente: cambia modalità, avvia e chiude Taratura e Verifica, e in Taratura misura il livello"
  USES   Modalita
  USES   LetturaLivello
  GUARANTEE te1 STATUS RATIFIED BY D-338: VERBAL "Il telefono offre anche l'intero controllo remoto di AudioProcessor (parametri e filtri creativi, mute, Loudness, trasporto dei documenti di licenza), secondo il contratto remote control 1.15; quelle funzioni non cambiano la scelta dell'hardware e restano fuori dal modello dei kit (fonte: operatore, 2026-11-16; contratto remote control 1.15)"
                 VERIFY BY INSPECTION "il contratto remote control 1.15, §10 e §10.20"
  GUARANTEE te2 STATUS RATIFIED BY D-338: VERBAL "Il telefono e il Raspberry Pi stanno nella stessa rete WiFi; per le licenze il telefono fa da corriere fra impianto e servizio e ha bisogno anche di un accesso a Internet: è un requisito dell'impianto, non del kit (fonte: Q-AK-2; D-318; operatore, 2026-11-16)"
                 VERIFY BY INSPECTION "la rete dell'impianto: telefono e Raspberry Pi nella stessa LAN WiFi, telefono con accesso a Internet"
END
