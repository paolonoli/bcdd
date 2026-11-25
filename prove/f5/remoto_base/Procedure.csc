-- Le due procedure del livello d'ascolto aperte, condotte e chiuse dal telefono.
-- Fonte: contratto 1.13, §10.14, §10.15 (RC-CT-46..56).

CSC Procedure VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono apre «Taratura livello d'ascolto…» e «Verifica livello…», ne preme i pulsanti, conclude la Verifica e chiude la procedura aperta"
  EVENT IN  apri(procedura: String)
  EVENT IN  passo(pulsante: String)
  EVENT IN  chiudi(procedura: String)
  EVENT OUT stato_verifica
  GUARANTEE pc1: VERBAL "Il telefono apre le due procedure solo quando i loro pulsanti si possono premere nella finestra, e solo in Riproduzione; il telefono sa sempre se si possono premere e perché"
                 VERIFY BY JUDGEMENT "l'operatore, che prova ad aprire la Verifica senza taratura"
  GUARANTEE pc2: VERBAL "Il telefono chiude la procedura aperta, anche quando l'ha aperta il PC, come premere Annulla, la X o Chiudi"
                 VERIFY BY JUDGEMENT "l'operatore, che apre la taratura dal PC e la chiude dal telefono"
  GUARANTEE pc3: VERBAL "I passi della procedura non partono da soli: il telefono preme i pulsanti della finestra della procedura, uno per volta, solo quelli che la procedura aspetta in quel momento"
                 VERIFY BY JUDGEMENT "l'operatore, che segue una taratura intera dal telefono"
  GUARANTEE pc4: VERBAL "Il telefono riceve lo stato della Verifica a ogni cambio e, durante la regolazione, quanto manca per centrare il livello; conclude la Verifica, o dice di non riuscire a centrare, e la Verifica non scrive niente"
                 VERIFY BY JUDGEMENT "l'operatore, che centra il livello guardando solo il telefono"
  GUARANTEE pc5: VERBAL "Una procedura aperta da un telefono si chiude quando finisce la sessione di quel telefono"
                 VERIFY BY JUDGEMENT "l'operatore, che apre la taratura dal telefono e lo spegne"
END
