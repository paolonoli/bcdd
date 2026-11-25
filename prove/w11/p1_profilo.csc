-- profilo in un file
PROFILE Segnale VERSION 0.3
  PURPOSE "Grandezze che variano con continuità"

  EXTENSION FADE
    KIND     pattern
    LEVEL    Core
    PARAMS   (s: SIGNAL, d: Duration)
    FORM     "FADE s WITHIN d"
    MEANING  "s scende senza risalire e arriva a 0 entro d"
    VERIFY   V1 C1 ; V2 "misura di s nel tempo"
    SOURCE   "LuceScale, g10"
  END
END
