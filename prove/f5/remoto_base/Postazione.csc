-- La postazione dell'operatore al computer: che cosa vede e che cosa fa lui, sul controllo remoto.
-- È il confine che nella prova 1.5.1 mancava (lacuna 4): qui è una CSC pubblica del gruppo.
-- Fonte: contratto 1.13, RC-SE-1, RC-SE-5, RC-SE-6, RC-LE-16, RC-PR-3, RC-PR-5, RC-CT-17, RC-CT-19.

CSC Postazione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Che cosa l'operatore vede e decide al computer sul controllo remoto, e che cosa resta suo anche con il telefono collegato"
  EVENT IN  accendi_servizio(acceso: Boolean)
  EVENT IN  rigenera_codice
  STATE servizio_acceso : Boolean INITIAL false
  GUARANTEE po1: VERBAL "Il controllo remoto è spento finché l'operatore non lo accende, e resta come l'operatore l'ha lasciato anche dopo un riavvio"
                 VERIFY BY JUDGEMENT "l'operatore, che riavvia il programma e guarda l'impostazione"
  GUARANTEE po2: VERBAL "L'operatore vede il codice d'abbinamento nella finestra e lo può rigenerare; rigenerarlo chiude tutti i telefoni collegati, che devono abbinarsi di nuovo"
                 VERIFY BY JUDGEMENT "l'operatore, che rigenera il codice con il telefono collegato"
  GUARANTEE po3: VERBAL "Il valore della taratura si può sempre scrivere a mano: il telefono è un'alternativa, non un sostituto"
                 VERIFY BY JUDGEMENT "l'operatore, con il telefono spento"
  GUARANTEE po4: VERBAL "I pulsanti della finestra hanno sempre la loro abilitazione, con o senza telefono, e un comando del telefono vale come il clic dell'operatore"
                 VERIFY BY JUDGEMENT "l'operatore, che confronta la finestra con e senza telefono collegato"
  GUARANTEE po5: VERBAL "Per ogni lettura arrivata dal telefono l'operatore vede da dove viene: quale microfono, che taratura, gli avvisi"
                 VERIFY BY INSPECTION "la pagina di esito della taratura dopo una lettura dal telefono"
  GUARANTEE po6: VERBAL "L'operatore decide se accettare le letture di un telefono tarato solo con i valori di fabbrica: accettate con un avviso, oppure rifiutate"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia l'impostazione e manda una lettura di un telefono non tarato"
END
