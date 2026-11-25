ENTITY Pulsante VERSION 0.2
  PURPOSE "Il pulsante di un piano"
  OFFERS Pressione
  OFFERS Comando
  USES   Buio
  GUARANTEE pu1: VERBAL "A ogni pressione segue un accendi entro 0,1 s, se e' buio o se il crepuscolare non c'e'"
                VERIFY BY JUDGEMENT "l'operatore"
END
