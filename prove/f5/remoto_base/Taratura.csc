-- La taratura del livello d'ascolto vista dal telefono, con la lettura che il telefono consegna.
-- Gli obblighi del telefono sulla lettura sono ASSUME: chi usa la CSC rispetta le sue ASSUME (D-147 (1)).
-- Fonte: contratto 1.13, §6.1-§6.3, §8, §9 (RC-ST-*, RC-LE-*, RC-PR-*, RC-ER-*), RC-LC-6.

CSC Taratura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il computer dice al telefono a che punto è la taratura, e accetta la sua lettura una volta sola, quando è pronto a riceverla e se la lettura è credibile"
  TYPE Lettura := VERBAL "la misura del livello del suono fatta dal telefono, con la sua durata e la sua provenienza"
  EVENT OUT stato(fase: String)
  EVENT IN  consegna(lettura: Lettura)
  EVENT OUT risposta(accettata: Boolean, motivo: String)
  STATE pronta_a_ricevere : Boolean INITIAL false
  GUARANTEE ta1: VERBAL "La lettura si accetta solo mentre la taratura aspetta il valore con il rumore di prova acceso; in ogni altro momento si rifiuta, dicendo il perché e a che punto è la taratura"
                 VERIFY BY JUDGEMENT "l'operatore, che manda una lettura prima, durante e dopo l'attesa"
  GUARANTEE ta2: VERBAL "In ogni taratura si accetta al più una lettura; le successive si rifiutano, e un rifiuto non consuma la lettura e non cambia niente"
                 VERIFY BY JUDGEMENT "l'operatore, che manda una lettura sbagliata, poi una giusta, poi un'altra"
  GUARANTEE ta3: VERBAL "Il telefono sa sempre a che punto è la taratura: il computer glielo dice a ogni cambio, appena è pronto, e quando lo chiede"
                 VERIFY BY INSPECTION "le fasi mostrate dal telefono confrontate con la finestra"
  GUARANTEE ta4: VERBAL "Una lettura che non è credibile si rifiuta, dicendo il perché: non pesata A o non mediata, troppo corta, più lunga del rumore di prova, fuori da 50-100 dB(A), saturata, o che non torna con la sua provenienza"
                 VERIFY BY JUDGEMENT "l'operatore, che manda una lettura per ciascun difetto"
  GUARANTEE ta5: VERBAL "La lettura del telefono vale come quella scritta a mano; se operatore e telefono la danno insieme vale la prima, e l'altra trova la taratura già andata avanti"
                 VERIFY BY JUDGEMENT "l'operatore, che scrive il valore mentre il telefono lo manda"
  GUARANTEE ta6: VERBAL "Il livello del suono istante per istante non viaggia: il telefono misura da sé, e conta solo la lettura finale"
                 VERIFY BY INSPECTION "il traffico durante una taratura"
  ASSUME    ta-a1: VERBAL "La lettura è la media del livello pesato A dall'ultimo azzeramento, non un valore istantaneo, e dura almeno 20 s"
                   VERIFY BY JUDGEMENT "l'operatore, confrontando con un fonometro di riferimento"
  ASSUME    ta-a2: VERBAL "Con la lettura il telefono manda la sua provenienza: quale microfono, quale correzione, che tipo di taratura e di quando, e se il microfono è andato in saturazione"
                   VERIFY BY INSPECTION "le letture ricevute dal computer"
END
