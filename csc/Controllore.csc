-- F0 di W-51: parte di BcddTool (REFINEMENT VIEW BcddToolParti). A parole, ipotesi.

CSC Controllore VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Controlla la forma di una CSC già analizzata e produce il rapporto per la persona"

  CAPABILITY Controlla(s: Struttura)
  EVENT OUT  rapporto(r: Rapporto)

  GUARANTEE k-1: VERBAL "Il rapporto contiene: gli errori con il numero di riga; il grado di
                         ogni riga contrattuale; ogni UNDECIDED; ogni ipotesi; ogni riga non
                         riconosciuta. In questo ordine, sempre"
                 VERIFY BY JUDGEMENT "l'operatore, sui file di prova"
  GUARANTEE k-2: VERBAL "Sono errori almeno: due righe con lo stesso id; un DETAILS che nomina
                         una riga che non esiste; un nome usato e mai dichiarato, salvo i
                         nomi di tipo, che il rapporto elenca a parte; un
                         STATUS RATIFIED senza riferimento a una decisione"
                 VERIFY BY JUDGEMENT "l'operatore, con un file di prova per ciascun errore"
  GUARANTEE k-3: VERBAL "I conteggi per grado sono separati e non si sommano (P4, R14)"
                 VERIFY BY INSPECTION "il rapporto"
  GUARANTEE k-4: VERBAL "Una riga non riconosciuta non è un errore, ma non è mai taciuta"
                 VERIFY BY JUDGEMENT "l'operatore"
END
