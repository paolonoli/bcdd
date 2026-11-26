-- CSC creata da bcdd new. Si scrive a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga è contratto: è un'ipotesi finché l'operatore non ratifica.

CSC Spia VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La spia dice all'operatore se l'apparecchio è acceso"

  STATE accesa : Boolean INITIAL false
  TYPE Colore := VERBAL "verde oppure rosso"
  EVENT OUT cambio(colore: Colore)

  -- Ingressi e uscite (togliere il commento e scrivere):
  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere
  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori
  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce
  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori

  -- Promesse a parole:
  -- GUARANTEE g1: VERBAL "che cosa promette"
  --               VERIFY BY JUDGEMENT "chi giudica, e su che cosa"

  GUARANTEE g1 STATUS HYPOTHESIS: VERBAL "La spia è accesa quando l'apparecchio è acceso"
                                  VERIFY BY JUDGEMENT "l'operatore, guardando la spia"
  ASSUME a1 STATUS HYPOTHESIS: VERBAL "L'apparecchio è alimentato"
                               VERIFY BY INSPECTION "la presa di corrente"
END
