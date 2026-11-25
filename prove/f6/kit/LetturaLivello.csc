-- Il telefono come fonometro nella Taratura del livello d'ascolto: la lettura Leq(A) che manda ad AP.
-- Corrisponde alla CSC Taratura di caso_remoto (contratto del controllo remoto), ridotta a ciò che serve ai kit.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md (§2 S-TAR, §6 R-TEL); risposta di AudioKits Q-AK-7;
-- contratto del controllo remoto, ratificato (D-302, D-303), come in caso_remoto/Taratura.csc (ta1, ta2).

CSC LetturaLivello VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "In Taratura il telefono misura il livello del rumore di prova al punto d'ascolto e manda la lettura ad AP, che la usa come ancora per il sensore di livello"
  TYPE Lettura := VERBAL "il livello Leq(A) del rumore di prova misurato dal telefono al punto d'ascolto, con la sua provenienza"
  EVENT IN  lettura(valore: Lettura)                  -- spl.reading
  EVENT OUT esito_lettura(accettata: Boolean)
  GUARANTEE le1 STATUS RATIFIED BY D-338: VERBAL "AP usa la lettura accettata come ancora: associa quel livello a ciò che legge nello stesso momento il sensore di livello, e da lì segue il livello con il sensore, senza il telefono (fonte: §2 S-TAR; Q-AK-7, che parlano della DI; il sensore può essere anche il microfono, D-337, supporto di AP da confermare)"
                 VERIFY BY JUDGEMENT "l'operatore, che dopo la Taratura spegne il telefono e cambia il volume"
  GUARANTEE le2 STATUS RATIFIED BY D-338: VERBAL "AP accetta una lettura solo durante la Taratura, quando aspetta il valore con il rumore di prova acceso, e al più una per Taratura; in ogni altro momento la rifiuta (fonte: contratto RC 1.13, caso_remoto Taratura ta1 e ta2)"
                 VERIFY BY JUDGEMENT "l'operatore, che manda una lettura in Misure e due durante la stessa Taratura"
  ASSUME    le-a1 STATUS RATIFIED BY D-338: VERBAL "La lettura è un Leq(A), con ponderazione A secondo IEC 61672-1, del rumore di prova al punto d'ascolto; vale dopo almeno 20 s, e una saturazione la invalida. Non è una misura a 1 kHz (fonte: §6 R-TEL [C], AndroidKit 2026-10-08; Q-AK-7)"
                   VERIFY BY JUDGEMENT "l'operatore, che confronta la lettura con un fonometro di riferimento"
  ASSUME    le-a2 STATUS RATIFIED BY D-338: VERBAL "L'incertezza dichiarata della lettura è ±2-3 dB senza offset di taratura e ±1 dB con l'offset e a 1 kHz (fonte: AndroidKit, nota dell'08/10, secondaria per AudioKits); il contratto del protocollo di AP dichiara ±3 dB assoluti non garantiti, più un possibile controllo automatico del guadagno del telefono (fonte: AP-RC; Q-AK-7)"
                   VERIFY BY JUDGEMENT "l'operatore, che ripete la Taratura con e senza offset e confronta con un fonometro di riferimento"
END
