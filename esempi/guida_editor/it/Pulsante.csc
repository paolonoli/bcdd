-- Il pulsante delle scale, una delle due parti della luce.

ENTITY Pulsante VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante riceve la pressione e comanda la lampada"

  OFFERS Pressione
  OFFERS Comando

  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s"
                 VERIFY BY INSPECTION "le pressioni e i comandi registrati"
END
