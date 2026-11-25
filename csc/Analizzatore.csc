-- F0 di W-51: parte di BcddTool (REFINEMENT VIEW BcddToolParti). A parole, ipotesi.

CSC Analizzatore VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Legge il testo di un file CSC e ne ricava la struttura: blocchi, dichiarazioni,
           righe contrattuali con il loro grado, e le righe che non sa leggere"

  CAPABILITY Analizza(testo: Testo)
  EVENT OUT  struttura(s: Struttura)          -- risultato di Analizza

  GUARANTEE a-1: VERBAL "Ogni riga del testo finisce in uno e un solo posto della struttura:
                         riconosciuta, commento, vuota o non riconosciuta. Nessuna riga si perde"
                 VERIFY BY INSPECTION "conteggio delle righe in ingresso e nella struttura"
  GUARANTEE a-2: VERBAL "Ogni elemento della struttura porta il numero della riga da cui viene"
                 VERIFY BY JUDGEMENT "l'operatore, sui file di prova"
  GUARANTEE a-3: VERBAL "Lo stesso testo dà sempre la stessa struttura"
                 VERIFY BY INSPECTION "due esecuzioni sullo stesso testo"
  GUARANTEE a-4: VERBAL "Il grado di una riga si legge dalla forma (SPECIFICA_02 §6.3):
                         VERBAL è verbale, una forma riconosciuta del nucleo o di BASE è
                         formale, il resto è non riconosciuto"
                 VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE a-4a DETAILS a-4: VERBAL "In F1 nessuna forma formale è riconosciuta: una riga
                         formale risulta non riconosciuta, e il grado formale vale 0
                         (GRAMMATICA_F1, D-127)"
                 VERIFY BY INSPECTION "il rapporto delle prove di F1"
END
