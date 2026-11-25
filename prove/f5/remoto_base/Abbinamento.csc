-- L'abbinamento con il codice.
-- Fonte: contratto 1.13, §4 (RC-SE-*) e RC-SS-5.

CSC Abbinamento VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono si fa riconoscere dal computer giusto con il codice che l'operatore vede nella finestra"
  EVENT IN  abbina(codice: String)
  EVENT OUT esito(abbinato: Boolean)
  EVENT OUT identita(nome: String)
  STATE abbinato : Boolean INITIAL false
  GUARANTEE ab1: VERBAL "Il codice non viaggia mai sulla rete: il telefono dimostra di conoscerlo senza mandarlo"
                 VERIFY BY INSPECTION "il traffico registrato durante un abbinamento"
  GUARANTEE ab2: VERBAL "Dopo cinque codici sbagliati in un minuto dallo stesso apparecchio, il computer lo respinge per trenta secondi"
                 VERIFY BY JUDGEMENT "l'operatore, che sbaglia il codice sei volte e misura con un cronometro"
  GUARANTEE ab3: VERBAL "Il codice serve a non collegarsi per errore all'impianto sbagliato, non a difendersi da chi è sulla rete di casa; lo si dice all'operatore"
                 VERIFY BY INSPECTION "il testo mostrato all'operatore accanto al codice"
  GUARANTEE ab4: VERBAL "Al momento dell'abbinamento il computer dice al telefono il suo nome, lo stesso della ricerca, anche quando l'indirizzo è stato scritto a mano"
                 VERIFY BY JUDGEMENT "l'operatore, che si collega scrivendo l'indirizzo e guarda il nome sul telefono"
  GUARANTEE ab5: VERBAL "Il codice resta lo stesso finché l'operatore non lo rigenera: non scade da solo e sopravvive al riavvio"
                 VERIFY BY INSPECTION "il codice prima e dopo un riavvio"
END
