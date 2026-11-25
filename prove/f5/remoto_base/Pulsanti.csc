-- I pulsanti remotizzati: il telefono preme da lontano alcuni pulsanti della finestra.
-- Fonte: contratto 1.13, §10.1-§10.7, §10.10, §10.18 (RC-CT-1..24, RC-CT-36, RC-CT-69..72).

CSC Pulsanti VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono preme da lontano Flat Mode, Loudness, il modo del Volume, i cinque controlli creativi, la Vista e il MUTE della finestra, e vede sempre il loro stato vero, CLIP compreso"
  EVENT IN  premi(pulsante: String, acceso: Boolean)
  EVENT IN  scegli_vista(creativa: Boolean)
  EVENT IN  silenzia(acceso: Boolean)
  EVENT IN  chiedi_stato
  EVENT OUT stato_pulsanti
  GUARANTEE pu1: VERBAL "Un comando del telefono vale quanto la stessa azione fatta col mouse: si accetta solo se in quel momento il pulsante si può premere, lo decide il computer, e un rifiuto dice il perché"
                 VERIFY BY JUDGEMENT "l'operatore, che prova un comando con il pulsante disabilitato nella finestra"
  GUARANTEE pu2: VERBAL "Telefoni e mouse possono comandare insieme: i comandi si valutano uno alla volta nell'ordine di arrivo, vale l'ultimo, e nessuno prende il controllo per sé"
                 VERIFY BY JUDGEMENT "l'operatore, con due telefoni e il mouse"
  GUARANTEE pu3: VERBAL "A ogni cambio, da qualunque parte arrivi, tutti i telefoni ricevono una volta sola lo stato vero dei pulsanti, come si vede nella finestra, e lo possono chiedere quando vogliono"
                 VERIFY BY JUDGEMENT "l'operatore, che preme col mouse e guarda i telefoni"
  GUARANTEE pu4: VERBAL "Il telefono comanda solo i pulsanti dell'elenco, e per ciascuno chiede lo stato voluto, non un inverti: chiedere lo stato che c'è già non fa niente"
                 VERIFY BY INSPECTION "l'elenco dei comandi accettati"
  GUARANTEE pu5: VERBAL "Il telefono sceglie la Vista, correzioni o creativa, solo in Riproduzione e mai dentro o fuori da una misura; la Vista non cambia mai il suono"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia vista dal telefono in Riproduzione e fuori"
  GUARANTEE pu6: VERBAL "Il MUTE si preme dal telefono sempre, anche quando gli altri pulsanti sono inattivi; silenzia l'uscita intera e nient'altro, e non si salva"
                 VERIFY BY JUDGEMENT "l'operatore, che preme MUTE dal telefono con una finestra modale aperta"
  GUARANTEE pu7: VERBAL "Il telefono vede il CLIP dell'ingresso e quello dell'elaborazione, ciascuno per conto suo, come li mostra la finestra, e non lo può azzerare"
                 VERIFY BY JUDGEMENT "l'operatore, che manda un segnale troppo forte e guarda finestra e telefono"
END
