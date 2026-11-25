ENTITY Pulsante VERSION 0.1
  PURPOSE "Il pulsante di un piano"
  OFFERS Pressione
  OFFERS Comando
  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s"
                 VERIFY BY INSPECTION "pressioni e comandi registrati"
END
