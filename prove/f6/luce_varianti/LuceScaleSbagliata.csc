ENTITY LuceScaleSbagliata VERSION 0.3
  PURPOSE "La luce delle scale: due lampade possibili, due comandi possibili"
  OFFERS Luce
  VARIANT lampada = soffitto
    COMPOSED OF
      lampada : Plafoniera
  VARIANT lampada = parete
    COMPOSED OF
      lampada : Applique
  VARIANT comando = pulsante
    OFFERS Pressione
    COMPOSED OF
      pulsante : Pulsante
  VARIANT comando = presenza
    OFFERS Presenza
    COMPOSED OF
      presenza : SensoreMuto
END
