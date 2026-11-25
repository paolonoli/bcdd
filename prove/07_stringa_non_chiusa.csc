-- Prova 07, errore E06: una virgoletta aperta e mai chiusa si porta via il resto del file.
-- Conseguenze attese: PURPOSE non è riconosciuto (E10) e anche END finisce dentro la
-- stringa, quindi il blocco non è chiuso (E07).

CSC Stringhe VERSION 0.1
  PURPOSE "la stringa si apre qui e non si chiude

  EVENT IN arrivo
END
