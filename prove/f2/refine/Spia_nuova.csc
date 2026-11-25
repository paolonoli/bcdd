-- CSC creata da bcdd new. Si compila a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga è contratto: è un'ipotesi finché l'operatore non ratifica.

CSC Spia VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "da compilare: in una frase, di che cosa è responsabile Spia"

  -- Ingressi e uscite (togliere il commento e compilare):
  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere
  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori
  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce
  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori

  -- Promesse a parole:
  -- GUARANTEE g1: VERBAL "che cosa promette"
  --               VERIFY BY JUDGEMENT "chi giudica, e su che cosa"
END
