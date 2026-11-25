ENTITY LampadaWiFi VERSION 0.1
  PURPOSE "La lampada comandata senza fili"
  USES Trasmissione
  OFFERS Luce
  COMPOSED OF
    ricevitore : Ricevitore
    lampada    : Lampada
END
