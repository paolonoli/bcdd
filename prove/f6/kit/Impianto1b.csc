-- Prova della SPECIFICA_02 0.6 (BCDD/W-09), sintassi ILLUSTRATIVA: bcdd non conosce VARIANT ne' [0 .. 1].
-- Prende il posto di Impianto1bDueSchede e Impianto1bDueSchedeMicrofono.

ENTITY Impianto1b VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "L'impianto di ascolto con il kit 1.b a due schede: l'utente sceglie le modalità dalla finestra di AP, ricabla o sposta il microfono fra le fasi e misura"
  OFFERS Modalita
  OFFERS Misura
  OFFERS Ricablaggio
  OFFERS RilevamentoLivello
  COMPOSED OF
    kit           : Kit1b          -- porta con se' la scelta sensore (kit.sensore)
    sorgente      : Sorgente
    amplificatore : Amplificatore
    diffusori     : Diffusori
    telefono      : Telefono       -- c'e' sempre: serve in Taratura; 'solo in certe fasi' non e' [0 .. 1] (L3)
END
