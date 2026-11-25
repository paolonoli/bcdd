-- F0 di W-51: il vicino esterno di BcddTool, l'LLM. Non lo realizziamo: ne scriviamo
-- solo l'interfaccia, cioè quello che BcddTool può aspettarsi. A parole, ipotesi.

CSC ModelloLinguistico VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Riceve una richiesta in testo e restituisce un testo. È il primo LLM previsto
           (claude -p, D-123), ma l'interfaccia vale per qualunque LLM"

  EVENT IN   richiesta(testo: Testo)
  EVENT OUT  replica(testo: Testo)

  GUARANTEE m-1: VERBAL "A una richiesta segue al più una replica"
                 VERIFY BY INSPECTION "il registro delle chiamate"

  -- Ciò che NON garantisce, scritto perché nessuno ci conti:
  --   che la replica arrivi; che arrivi in tempo; che rispetti il formato chiesto;
  --   che sia corretta; che due richieste uguali diano la stessa replica.
  -- Per questo BcddTool non ha nessuna ASSUME su ModelloLinguistico (g-r6).
END
