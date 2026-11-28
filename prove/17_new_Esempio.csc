-- CSC creata da bcdd new. Si scrive a mano; bcdd check controlla la forma.
-- Senza STATUS RATIFIED nessuna riga fa parte del contratto: è da approvare finché l'operatore non la approva.

CSC Esempio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "da scrivere: in una frase, di che cosa è responsabile Esempio"

  -- Ingressi e uscite (togliere il commento e scrivere):
  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere
  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori
  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce
  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori

  -- Promesse a parole:
  -- GUARANTEE g1: VERBAL "che cosa promette"
  --               VERIFY BY JUDGEMENT "chi giudica, e su che cosa"
END
