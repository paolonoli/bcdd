-- Il controllo remoto di AudioProcessor dal telefono, visto per intero (livello 1 della 1.13).
-- Fonte: il contratto del controllo remoto 1.13, ratificata (D-302, D-303). Scritta all'indietro dal
-- livello 2. Tutto ipotesi: niente ratify, niente refine.

ENTITY ControlloRemoto VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il computer con AudioProcessor e il telefono con LevelMeter: il telefono porta al computer la lettura del livello per la taratura e fa da telecomando di alcuni pulsanti della finestra"
  OFFERS Postazione
  COMPOSED OF
    computer : AudioProcessor
    telefono : LevelMeter
  GUARANTEE cr1: VERBAL "Con il controllo remoto spento sul computer, il telefono non trova il computer e non può comandare niente"
                 VERIFY BY JUDGEMENT "l'operatore, che spegne il servizio e prova a collegarsi dal telefono"
  GUARANTEE cr2: VERBAL "Qualunque cosa succeda al collegamento, la taratura e i pulsanti della finestra restano come sono: cadere o chiudere non li cambia mai"
                 VERIFY BY JUDGEMENT "l'operatore, che spegne il Wi-Fi del telefono a metà taratura e guarda la finestra"
  GUARANTEE cr3: VERBAL "Il telefono non diventa mai un secondo padrone: il computer decide sempre con le sue regole, e il mouse resta sempre utilizzabile"
                 VERIFY BY JUDGEMENT "l'operatore, che usa telefono e mouse insieme"
  GUARANTEE cr4: VERBAL "Il telefono non porta mai un volume, un taglio o un guadagno, salvo quelli che l'operatore ha deciso uno per uno: i guadagni dei controlli creativi, il livello voluto, il richiamo e la corsa del volume"
                 VERIFY BY INSPECTION "l'elenco delle cose che il telefono può chiedere"
  GUARANTEE cr5: VERBAL "Il rischio che resta è detto all'operatore: chi è sulla rete di casa e si è già abbinato può mandare una lettura o un comando falsi; l'effetto peggiore è un ascolto al livello sbagliato o un suono alterato entro i limiti delle caselle, non un danno all'impianto"
                 VERIFY BY INSPECTION "il testo del rischio residuo, confrontato con le misure del lato computer"
END
