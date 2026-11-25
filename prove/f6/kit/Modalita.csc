-- Le modalità di AudioProcessor (AP) e le due procedure del livello d'ascolto, viste da chi comanda:
-- l'operatore alla finestra di AP oppure il telefono (ctl.mode, ctl.calibrate, ctl.check).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md (§2, §3, §4) e la risposta di AudioKits (Q-AK-3, Q-AK-7);
-- fonti/MODELLO_SISTEMA_FATTI_v0.4.md, risposta di AP «AP-R2» D3 (D-341).
-- Lo stato della modalità ha ora il suo valore iniziale: AP parte sempre in Riproduzione (AP-R2 D3), quindi
-- per questo caso la lacuna L1 dell'ESITO è chiusa. Gli eventi restano: dicono chi chiede e che cosa fa AP.

CSC Modalita VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi comanda sceglie la modalità di AP e, solo in Riproduzione, avvia e chiude la Taratura e la Verifica del livello d'ascolto"
  TYPE Modalita := {misure, calcolo, riproduzione}
  TYPE Procedura := {taratura, verifica}
  STATE modalita : Modalita INITIAL riproduzione   -- la modalità in cui AP si trova; cambia con attiva
  EVENT IN  scegli(modalita: Modalita)          -- dalla finestra di AP o dal telefono (ctl.mode)
  EVENT OUT attiva(modalita: Modalita)          -- AP è passato a quella modalità
  EVENT IN  avvia(procedura: Procedura)         -- dalla finestra o dal telefono (ctl.calibrate, ctl.check)
  EVENT OUT avviata(procedura: Procedura)
  EVENT OUT rifiutata(procedura: Procedura)
  EVENT IN  chiudi(procedura: Procedura)
  GUARANTEE mo1 STATUS RATIFIED BY D-338: VERBAL "Le modalità sono tre, Misure Ambientali, Calcolo Correzione e Riproduzione, ed esclusive: AP è sempre in una sola (fonte: §2, AP-W155 [C])"
                 VERIFY BY JUDGEMENT "l'operatore, che passa da una modalità all'altra e guarda la finestra"
  GUARANTEE mo2 STATUS RATIFIED BY D-338: VERBAL "Un cambio di modalità chiesto dal telefono segue lo stesso cammino del clic nella finestra e ha lo stesso effetto (fonte: §2, AP-W155 e AP-RC [C]; Q-AK-3)"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia modalità una volta dalla finestra e una dal telefono"
  GUARANTEE mo3 STATUS RATIFIED BY D-338: VERBAL "AP non cambia modalità da solo: la cambia solo l'utente, dalla finestra o dal telefono (fonte: Q-AK-3; confermato dall'operatore nel file il 2026-11-16, «Utente: confermo»)"
                 VERIFY BY INSPECTION "il registro dei cambi di modalità di AP in una sessione senza gesti dell'utente"
  GUARANTEE mo4 STATUS RATIFIED BY D-338: VERBAL "Taratura e Verifica del livello d'ascolto si avviano solo in Riproduzione; fuori dalla Riproduzione AP le rifiuta, anche quando l'avvio arriva dal telefono (fonte: §2, AP-W155 e AP-RC [C]; Q-AK-3)"
                 VERIFY BY JUDGEMENT "l'operatore, che chiede la Taratura dal telefono in Misure e poi in Riproduzione"
  GUARANTEE mo5 STATUS RATIFIED BY D-338: VERBAL "Loudness e Livello d'ascolto funzionano solo in Riproduzione; senza un sensore di livello, la DI o il microfono che ne fa le veci, il Loudness non si usa e il resto funziona (fonte: §2 AP-W155 [C]; G-06 [C], che oggi lo dice della DI; generalizzato dall'operatore nel file e da D-337, supporto di AP al microfono da confermare)"
                 VERIFY BY JUDGEMENT "l'operatore, che prova il Loudness in Misure, in Riproduzione e in Riproduzione senza sensore di livello"
  GUARANTEE mo6 STATUS RATIFIED BY D-338: VERBAL "Fuori dalla Riproduzione AP non cattura il sensore di livello (fonte: §3, AP una nota tecnica [C], che oggi lo dice della DI; esteso al sensore da D-337)"
                 VERIFY BY INSPECTION "l'indicatore del livello del sensore in Misure e in Calcolo"
  GUARANTEE mo7 STATUS RATIFIED BY D-338: VERBAL "In Taratura AP emette il rumore di prova; in Verifica emette rumore rosa e riporta il guadagno del sensore di livello al riferimento dell'ultima taratura, senza il telefono (fonte: §2 S-TAR e S-VER; AP history 2026-10-04 e 2026-10-24, che oggi parlano della DI)"
                 VERIFY BY JUDGEMENT "l'operatore, che fa una Taratura e poi una Verifica con il telefono spento"
  GUARANTEE mo8 STATUS RATIFIED BY D-338: VERBAL "La procedura aperta si chiude dalla finestra o dal telefono (fonte: Q-AK-7, «chiusura della procedura»)"
                 VERIFY BY JUDGEMENT "l'operatore, che apre la Taratura dalla finestra e la chiude dal telefono"
  GUARANTEE mo9 STATUS RATIFIED BY D-341: VERBAL "All'avvio AP è sempre in Riproduzione, non nell'ultima modalità usata: è una regola fissa del codice di AP (fonte: AP-R2 D3 [C], MODELLO_SISTEMA_FATTI v0.4)"
                 VERIFY BY JUDGEMENT "l'operatore, che chiude AP in Misure e lo riavvia"
  ASSUME    mo-a1 STATUS RATIFIED BY D-338: VERBAL "Il telefono manda un comando solo per un gesto esplicito dell'utente, mai da solo e mai alla connessione (fonte: G-11, RC-CT-21 [C]); mo3 ne dipende"
                   VERIFY BY INSPECTION "il registro del telefono dopo una riconnessione"
  -- Taratura in Riproduzione: avviata e poi chiusa (mo4, mo8).
  SCENARIO mo-s1 EXPECT ADMITTED
    @0 s    scegli(modalita: riproduzione)
    @0 s    attiva(modalita: riproduzione)
    @10 s   avvia(procedura: taratura)
    @10 s   avviata(procedura: taratura)
    @60 s   chiudi(procedura: taratura)
  -- Taratura chiesta in Misure e avviata: viola mo4.
  SCENARIO mo-s2 EXPECT REJECTED
    @0 s    scegli(modalita: misure)
    @0 s    attiva(modalita: misure)
    @10 s   avvia(procedura: taratura)
    @10 s   avviata(procedura: taratura)
  -- Verifica chiesta in Calcolo: AP la rifiuta, come vuole mo4.
  SCENARIO mo-s3 EXPECT ADMITTED
    @0 s    scegli(modalita: calcolo)
    @0 s    attiva(modalita: calcolo)
    @5 s    avvia(procedura: verifica)
    @5 s    rifiutata(procedura: verifica)
END
