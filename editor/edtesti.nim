# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 008:1:1 Catalogo dei testi per la persona composti in Nim dall'editor, in italiano e in inglese.
# 008:1:2 Come `src/bcddtesti.nim`: ogni voce ha la chiave, il testo italiano e il testo inglese; segnaposto posizionali `$1`..`$9`, `$$` è un
# 008:1:3 dollaro. Completezza a compilazione: la macro esige per ogni voce entrambi i testi. I testi che la pagina compone da dati stanno in
# 008:1:4 `pagina/testi.js`; qui restano solo quelli che nascono da azioni in Nim (rifiuti, esiti, riga d'uso, messaggi dell'avvio).
import std/macros

type Lingua* = enum
  lgEn = "en", lgIt = "it"

var lingua*: Lingua = lgEn   # 008:2:1 impostata all'avvio (e dal comando della barra), mai dalle azioni

macro catalogo(body: untyped): untyped =
  ## 008:3:1 Costruisce l'enumerato `Chiave` e la tabella `voci` dalle chiamate `voce(kNome, "it", "en")`.
  var enumFields = newNimNode(nnkEnumTy).add(newEmptyNode())
  var rows = newNimNode(nnkBracket)
  for st in body:
    if st.kind in {nnkCommentStmt, nnkEmpty}: continue
    st.expectKind nnkCommand
    if st.len != 4 or $st[0] != "voce":
      error("catalogo: attesa la forma voce(kNome, \"italiano\", \"inglese\")", st)
    enumFields.add st[1]
    rows.add newNimNode(nnkTupleConstr).add(
      newNimNode(nnkExprColonExpr).add(ident("it"), st[2]),
      newNimNode(nnkExprColonExpr).add(ident("en"), st[3]))
  let typeDef = newNimNode(nnkTypeSection).add(
    newNimNode(nnkTypeDef).add(newNimNode(nnkPostfix).add(ident("*"), ident("Chiave")), newEmptyNode(), enumFields))
  let tabName = newNimNode(nnkPostfix).add(ident("*"), ident("voci"))
  let tabType = newNimNode(nnkBracketExpr).add(ident("array"), ident("Chiave"),
    newNimNode(nnkTupleTy).add(newIdentDefs(ident("it"), ident("string")), newIdentDefs(ident("en"), ident("string"))))
  let tabDef = newNimNode(nnkConstSection).add(newNimNode(nnkConstDef).add(tabName, tabType, rows))
  result = newStmtList(typeDef, tabDef)

catalogo:

  voce kUsoEditor,
    "uso: bcdd-editor [--lang it|en] [--dir CARTELLA]... [NOME]",
    "usage: bcdd-editor [--lang it|en] [--dir FOLDER]... [NAME]"
  voce kScegliCartella,
    "Scegli una o più cartelle con i file CSC",
    "Choose one or more folders with the CSC files"
  voce kScegliAnnulla,
    "Annulla",
    "Cancel"
  voce kScegliApri,
    "Scegli",
    "Choose"
  voce kTitoloErrore,
    "bcdd-editor: avvio non riuscito",
    "bcdd-editor: cannot start"
  voce kLangNonValida,
    "bcdd-editor: --lang accetta it oppure en: $1",
    "bcdd-editor: --lang accepts it or en: $1"
  voce kVersioneNonLetta,
    "bcdd-editor conosce $1 versione $2; $3 risponde con forma $4, versione $5: non apro $6",
    "bcdd-editor knows $1 version $2; $3 answers with form $4, version $5: I am not opening $6"
  voce kVersioneSenzaLingua,
    "bcdd-editor conosce $1 versione $2; $3 non dice in che lingua parla (è un bcdd precedente): non apro $4",
    "bcdd-editor knows $1 version $2; $3 does not say which language it speaks (it is an earlier bcdd): I am not opening $4"
  voce kRigaMsg,
    "riga $1: $2",
    "line $1: $2"
  voce kRigaNonRiconosciuta,
    "riga $1: riga non riconosciuta: $2",
    "line $1: unrecognised line: $2"
  voce kPubNonAffidatoOfferto,
    "il connettore pubblico $1 (offerto) di $2 non è affidato a nessuna parte",
    "the public connector $1 (provided) of $2 is not assigned to any part"
  voce kPubNonAffidatoUsato,
    "il connettore pubblico $1 (usato) di $2 non è affidato a nessuna parte",
    "the public connector $1 (used) of $2 is not assigned to any part"
  voce kParteOffreNessuno,
    "la parte $1 offre il connettore $2, ma nessun'altra parte di $3 lo usa e $3 non lo mostra fra i suoi connettori pubblici",
    "the part $1 provides the connector $2, but no other part of $3 uses it and $3 does not show it among its public connectors"
  voce kParteUsaNessuno,
    "la parte $1 usa il connettore $2, ma nessun'altra parte di $3 lo offre e $3 non lo mostra fra i suoi connettori pubblici",
    "the part $1 uses the connector $2, but no other part of $3 provides it and $3 does not show it among its public connectors"
  voce kNonTrovoEntitaFile,
    "non trovo l'entità $1 nel suo file",
    "I cannot find the entity $1 in its file"
  voce kLatoNonValido,
    "lato non valido: $1",
    "invalid side: $1"
  voce kHaGiaParte,
    "$1 ha già una parte $2",
    "$1 already has a part $2"
  voce kNonHaParte,
    "$1 non ha una parte $2",
    "$1 does not have a part $2"
  voce kRigaNonTogliere,
    "la riga $1 di $2 è scritta in un modo che qui non so togliere: cambiala nella casella di testo",
    "the line $1 of $2 is written in a way that I cannot remove here: change it in the text box"
  voce kScriviFrase,
    "Scrivi una frase.",
    "Write a sentence."
  voce kTroppoLungaMax,
    "È troppo lunga: al massimo $1 caratteri.",
    "It is too long: at most $1 characters."
  voce kVVirgolette,
    "Non può contenere virgolette (\"): usa l'apostrofo.",
    "It cannot contain quotation marks (\"): use the apostrophe."
  voce kVUnaRiga,
    "Deve stare su una riga.",
    "It must fit on one line."
  voce kScriviNome,
    "Scrivi un nome.",
    "Write a name."
  voce kNomeNonValido,
    "Il nome «$1» non è valido: usa lettere, cifre e il trattino basso (_), comincia con una lettera, al massimo 64 caratteri.",
    "The name “$1” is not valid: use letters, digits and the underscore (_), start with a letter, at most 64 characters."
  voce kNomeNonValidoMin,
    "il nome «$1» non è valido: usa lettere, cifre e il trattino basso (_), comincia con una lettera, al massimo 64 caratteri",
    "the name “$1” is not valid: use letters, digits and the underscore (_), start with a letter, at most 64 characters"
  voce kNomeDispositivo,
    "il nome «$1» non si può usare: Windows lo riserva per sé (nomi riservati: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Scegline un altro",
    "the name “$1” cannot be used: Windows reserves it (reserved names: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Choose another name"
  voce kNomeNonValidoRiservataMin,
    "il nome «$1» non è valido: usa lettere, cifre e il trattino basso (_), comincia con una lettera, al massimo 64 caratteri, e non usare una parola del linguaggio",
    "the name “$1” is not valid: use letters, digits and the underscore (_), start with a letter, at most 64 characters, and do not use a word of the language"
  voce kParolaRiservata,
    "«$1» è una parola riservata del linguaggio.",
    "“$1” is a keyword of the language."
  voce kParolaRiservataMin,
    "«$1» è una parola riservata del linguaggio",
    "“$1” is a keyword of the language"
  voce kUnitaTempo,
    "«$1» è un'unità di tempo.",
    "“$1” is a unit of time."
  voce kNomeGiaEsiste,
    "Esiste già un nome uguale, di un evento o di uno stato.",
    "This name is already used by an event or a state."
  voce kVScegliSiNo,
    "Scegli sì o no.",
    "Choose yes or no."
  voce kVIntero,
    "Scrivi un numero intero, per esempio 3 oppure -3.",
    "Write a whole number, for example 3 or -3."
  voce kVReale,
    "Scrivi un numero, per esempio 0.5 oppure -20.0 (con il punto, non con la virgola).",
    "Write a number, for example 0.5 or -20.0 (with a point, not a comma)."
  voce kVNumero60,
    "Scrivi un numero, per esempio 60.",
    "Write a number, for example 60."
  voce kVScegliUnita,
    "Scegli secondi o millisecondi.",
    "Choose seconds or milliseconds."
  voce kVScegliTipo,
    "Scegli un tipo.",
    "Choose a type."
  voce kVScriviFormula,
    "Scrivi la formula.",
    "Write the formula."
  voce kVFormulaCarattere,
    "Ha un carattere che non si può scrivere nel file.",
    "It has a character that cannot be written in the file."
  voce kVOttoRighe,
    "Al massimo otto righe.",
    "At most eight lines."
  voce kVFormulaVuote,
    "Niente righe vuote dentro la formula.",
    "No empty lines inside the formula."
  voce kVScegliCome,
    "Scegli come si controlla.",
    "Choose how it is checked."
  voce kVScegliVerso,
    "Scegli se entra o esce.",
    "Choose input or output."
  voce kVGenereSconosciuto,
    "genere sconosciuto",
    "unknown kind"
  voce kNonTrovoNelFile,
    "non trovo $1 nel suo file",
    "I cannot find $1 in its file"
  voce kSoloInCsc,
    "presupposti, eventi e stati si scrivono solo nei connettori (file CSC), non nelle entità",
    "assumptions, events and states are written only in connectors (CSC files), not in entities"
  voce kScopoInCasella,
    "lo scopo di $1 si cambia nella casella di testo",
    "the purpose of $1 is changed in the text box"
  voce kMancaEnd,
    "non trovo la riga END che chiude $1: aggiungila in fondo, nella casella di testo",
    "I cannot find the END line that closes $1: add it at the bottom, in the text box"
  voce kRigaGiaApprovataCambia,
    "questa riga è già approvata (è un contratto): per cambiarla usa Nuova versione",
    "this line is already approved (it is a contract): to change it use New version"
  voce kRigaCambiataNelFrattempo,
    "la riga $1 di $2 è cambiata nel frattempo: richiudi e riapri la scheda",
    "the line $1 of $2 has changed in the meantime: close and reopen the card"
  voce kScopoNonSiToglie,
    "lo scopo non si toglie: si cambia",
    "the purpose cannot be removed: it is changed"
  voce kRigaGiaApprovataTogli,
    "questa riga è già approvata (è un contratto): per toglierla usa Nuova versione",
    "this line is already approved (it is a contract): to remove it use New version"
  voce kRigheNonCiSono,
    "le righe $1-$2 non ci sono più: chiudi la casella e riaprila",
    "the lines $1-$2 are no longer there: close the box and reopen it"
  voce kRigheCambiate,
    "le righe $1-$2 sono cambiate nel frattempo: chiudi la casella e riaprila",
    "the lines $1-$2 have changed in the meantime: close the box and reopen it"
  voce kTestoCarattere,
    "il testo ha un carattere che non si può scrivere nel file: toglilo e riprova",
    "the text has a character that cannot be written in the file: remove it and try again"
  voce kComScrivi,
    "scrivi che cosa cambia, in una frase",
    "write what changes, in one sentence"
  voce kComLunga,
    "è troppo lunga: al massimo 200 caratteri",
    "it is too long: at most 200 characters"
  voce kComUnaRiga,
    "deve stare su una riga",
    "it must fit on one line"
  voce kVersioneCifre,
    "il numero della versione si scrive con cifre e punti, per esempio 0.2",
    "the version number is written with digits and points, for example 0.2"
  voce kVersioneAdesso,
    "è il numero di adesso ($1): scrivine uno diverso",
    "it is the current number ($1): write a different one"
  voce kRigaNonApprovataDecisione,
    "la riga $1 di $2 non è approvata con una sua decisione, o non c'è più: guarda com'è adesso e riprova",
    "the line $1 of $2 is not approved with its own decision, or is no longer there: look at it as it is now and try again"
  voce kMancaIntestazione,
    "non trovo l'intestazione di $1: guarda il file e riprova",
    "I cannot find the header of $1: look at the file and try again"
  voce kMancaVersioneIntest,
    "non trovo la versione nell'intestazione di $1: guarda il file e riprova",
    "I cannot find the version in the header of $1: look at the file and try again"
  voce kMancaStatusIntest,
    "non trovo la riga STATUS dell'intestazione di $1: guarda il file e riprova",
    "I cannot find the STATUS line of the header of $1: look at the file and try again"
  voce kMancaStatusRiga,
    "non trovo lo STATUS nella riga $1 di $2: guarda il file e riprova",
    "I cannot find the STATUS in the line $1 of $2: look at the file and try again"
  voce kImpossibileLanciare,
    "impossibile lanciare $1",
    "cannot launch $1"
  voce kNonRiescoLeggere,
    "non riesco a leggere $1",
    "I cannot read $1"
  voce kScopoUnaFrase,
    "lo scopo dev'essere una frase su una riga, senza virgolette",
    "the purpose must be a sentence on one line, without quotation marks"
  voce kNomeGiaUsatoCartella,
    "il nome «$1» è già usato nella cartella",
    "the name “$1” is already used in the folder"
  voce kCscEsisteNonContiene,
    "$1.csc esiste già e non contiene la CSC $1",
    "$1.csc already exists and does not contain the CSC $1"
  voce kFileCambiatoLeggevo,
    "$1 è cambiato mentre lo leggevo: riprova",
    "$1 changed while I was reading it: try again"
  voce kNonTrovoEntitaCartella,
    "non trovo l'entità $1 nella cartella",
    "I cannot find the entity $1 in the folder"
  voce kNonTrovoCartella,
    "non trovo $1 nella cartella",
    "I cannot find $1 in the folder"
  voce kNienteTornare,
    "non c'è niente a cui tornare indietro",
    "there is nothing to undo"
  voce kFileTornatoAltro,
    "$1 è stato ricreato da un altro programma dopo l'ultima azione: non torno indietro",
    "$1 was recreated by another program after the last action: I am not undoing it"
  voce kFileNonSiLegge,
    "$1 non si legge più: non torno indietro",
    "$1 can no longer be read: I am not undoing it"
  voce kFileModificatoAltro,
    "$1 è stato modificato da un altro programma dopo l'ultima azione: non torno indietro",
    "$1 was modified by another program after the last action: I am not undoing it"
  voce kUltimaSoloCreato,
    "l'ultima azione ha solo creato $1, e un file .csc non si cancella: cancellalo tu",
    "the last action only created $1, and a .csc file is not deleted: delete it yourself"
  voce kRestaUnFile,
    "il file $1 resta: un file .csc non si cancella",
    "the file $1 stays: a .csc file is not deleted"
  voce kRestanoFile,
    "restano i file $1: un file .csc non si cancella",
    "the files $1 stay: a .csc file is not deleted"
  voce kRimessiScritti,
    " Ho rimesso com'erano i file già scritti.",
    " I restored the files already written."
  voce kNonRimessiScritti,
    " Non sono riuscito a rimettere com'erano i file già scritti: $1",
    " I could not restore the files already written: $1"
  voce kPostoNonVa,
    "il posto $1 non va bene",
    "the place $1 is not valid"
  voce kNonDentroSeStessa,
    "$1 non si mette dentro se stessa",
    "$1 cannot be put inside itself"
  voce kGiaDentroGiro,
    "$1 sta già dentro $2: mettere $2 dentro $1 farebbe un ciclo",
    "$1 is already inside $2: putting $2 inside $1 would make the composition circular"
  voce kHaGiaPosto,
    "$1 ha già un posto che si chiama $2",
    "$1 already has a place called $2"
  voce kRigheScritte,
    "righe: $1",
    "lines: $1"
  voce kDialogoScritto,
    "dialogo: $1",
    "dialogue: $1"
  voce kNienteDaScrivere,
    "niente da scrivere",
    "nothing to write"
  voce kRestanoDaApprovareProfilo,
    "restano da approvare finché il profilo $1 non è approvato",
    "they stay pending approval until the profile $1 is approved"
  voce kFileCambiatoLetto,
    "$1 è cambiato dopo che l'hai letto: guarda com'è adesso e riprova",
    "$1 changed after you read it: look at it as it is now and try again"
  voce kPrimaErrori,
    "Prima correggi gli errori: un file con errori non si approva",
    "Correct the errors first: a file with errors cannot be approved"
  voce kIntestGiaApprovata,
    "l'intestazione di $1 è già approvata",
    "the header of $1 is already approved"
  voce kRigaNonCEPiu,
    "la riga $1 di $2 non c'è più o è già approvata: guarda com'è adesso e riprova",
    "the line $1 of $2 is no longer there or is already approved: look at it as it is now and try again"
  voce kUnaRigaApprovata,
    "1 riga approvata",
    "1 line approved"
  voce kNRigheApprovate,
    "$1 righe approvate",
    "$1 lines approved"
  voce kUnaRigaResta,
    "; 1 riga resta da approvare",
    "; 1 line stays pending approval"
  voce kNRigheRestano,
    "; $1 righe restano da approvare",
    "; $1 lines stay pending approval"
  voce kApprovateNonApprovata,
    "Approvate: $1. Non approvata: $2 ($3). Con «Torna indietro di un'azione» tornano tutte come prima.",
    "Approved: $1. Not approved: $2 ($3). “Undo the last action” puts them all back as before."
  voce kDecisioneFraParentesi,
    " ($1)",
    " ($1)"
  voce kNonTrovoFileCartella,
    "non trovo il file $1 nella cartella",
    "I cannot find the file $1 in the folder"
  voce kFormeApprovate,
    "forme concrete approvate ($1)",
    "concrete forms approved ($1)"
  voce kProfiloApprovatoEst,
    "profilo approvato, con le sue estensioni ($1)",
    "profile approved, with its extensions ($1)"
  voce kNonTrovoConnettoreCartella,
    "non trovo il connettore $1 nella cartella",
    "I cannot find the connector $1 in the folder"
  voce kNonTrovoVersione,
    "non trovo la versione di $1",
    "I cannot find the version of $1"
  voce kFormeGiaNome,
    "queste forme concrete hanno già il nome «$1»: scegline un altro",
    "these concrete forms already have the name “$1”: choose another one"
  voce kProfiloEsiste,
    "c'è già un profilo $1 nella cartella",
    "there is already a profile $1 in the folder"
  voce kFileEsiste,
    "il file $1.csc esiste già",
    "the file $1.csc already exists"
  voce kProfiloImportato,
    "il profilo $1 è importato da $2 $3: non si toglie",
    "the profile $1 is imported by $2 $3: it cannot be removed"
  voce kNonTrovoProfilo,
    "non trovo il profilo $1",
    "I cannot find the profile $1"
  voce kFileHaAltroProfilo,
    "$1 contiene anche altro, oltre al profilo: non lo tolgo",
    "$1 contains something else besides the profile: I am not removing it"
  voce kProfiloApprovatoNo,
    "il profilo $1 è approvato: non si toglie",
    "the profile $1 is approved: it cannot be removed"
  voce kProfiloApprovatoBreve,
    "il profilo è approvato",
    "the profile is approved"
  voce kNonParteDiSe,
    "$1 non può essere parte di se stessa",
    "$1 cannot be a part of itself"
  voce kNonCEEntitaCartella,
    "non c'è un'entità $1 nella cartella",
    "there is no entity $1 in the folder"
  voce kNonTrovoParteIn,
    "non trovo la parte $1 in $2",
    "I cannot find the part $1 in $2"
  voce kDuePartiDi,
    "le due parti devono essere parti di $1",
    "the two parts must be parts of $1"
  voce kOffreUsaDiverse,
    "chi offre e chi usa devono essere due parti diverse",
    "whoever provides and whoever uses must be two different parts"
  voce kScegliDueEntita,
    "scegli due entità diverse",
    "choose two different entities"
  voce kOffreUnaDelleDue,
    "chi offre deve essere una delle due entità",
    "whoever provides must be one of the two entities"
  voce kGiaCollegate,
    "$1 e $2 sono già collegate su $3: non scrivo niente",
    "$1 and $2 are already connected on $3: nothing is written"
  voce kOffreGia,
    "$1 offre già $2: due entità che offrono non si collegano, una delle due deve usarlo",
    "$1 already provides $2: two entities that provide it cannot be connected, one of them must use it"
  voce kUsaGia,
    "$1 usa già $2: due entità che usano non si collegano, una delle due deve offrirlo",
    "$1 already uses $2: two entities that use it cannot be connected, one of them must provide it"
  voce kNonTrovoPostoIn,
    "non trovo il posto $1 in $2",
    "I cannot find the place $1 in $2"
  voce kPostoGiaIn,
    "$1 sta già in $2",
    "$1 is already in $2"
  voce kRigheApprovatePosto,
    "$1 ha righe approvate: il posto $2 non si toglie",
    "$1 has approved lines: the place $2 cannot be removed"
  voce kFileContieneAltro,
    "$1 contiene anche altro: non lo tolgo",
    "$1 contains something else too: I am not removing it"
  voce kRigheApprovateNonSiToglie,
    "$1 ha righe approvate: non si toglie",
    "$1 has approved lines: it cannot be removed"
  voce kRigheApprovatePostoQuindi,
    "$1 ha righe approvate: il posto $2 non si toglie, quindi non tolgo $3",
    "$1 has approved lines: the place $2 cannot be removed, so I am not removing $3"
  voce kPostiToltiConnettoriRestano,
    "i posti sono tolti, i connettori restano",
    "the places are removed, the connectors stay"
  voce kConnettoriRestano,
    "i connettori restano",
    "the connectors stay"
  voce kScopoUnaFrase200,
    "lo scopo dev'essere una frase su una riga, senza virgolette, al più 200 caratteri",
    "the purpose must be a sentence on one line, without quotation marks, at most 200 characters"
  voce kCreatoScopoNo,
    "il file $1.csc è stato creato, ma lo scopo non si è scritto: $2",
    "the file $1.csc was created, but the purpose was not written: $2"
  voce kCscUsatoDa,
    "$1 è usato da $2: prima si scollega",
    "$1 is used by $2: disconnect it first"
  voce kNessunaEntitaLoUsava,
    "nessuna entità lo usava",
    "no entity used it"
  voce kGiroChiuso,
    "il giro è chiuso, non è stato scritto niente",
    "the round is closed, nothing was written"
  voce kAzioneSconosciuta,
    "azione sconosciuta",
    "unknown action"
  voce kDNuovaEntita,
    "nuova entità $1",
    "new entity $1"
  voce kDPubblico,
    "connettore $1$2 di $3",
    "connector $1$2 of $3"
  voce kDParte,
    "parte $1 di $2",
    "part $1 of $2"
  voce kDPassa,
    "$1$2 affidato a $3",
    "$1$2 assigned to $3"
  voce kDConnettore,
    "connettore $1 in $2",
    "connector $1 in $2"
  voce kDCollega,
    "collegate $1 e $2 su $3",
    "connected $1 and $2 on $3"
  voce kDScollegaPassaggio,
    "scollegato $1 da $2",
    "disconnected $1 from $2"
  voce kDScollegaAccoppiamento,
    "scollegato $1 fra $2 e $3",
    "disconnected $1 between $2 and $3"
  voce kDTogliParte,
    "tolta la parte $1 da $2",
    "removed the part $1 from $2"
  voce kDPortaFuori,
    "portato fuori il posto $1 da $2",
    "moved the place $1 out of $2 to the top level of the tree"
  voce kDMettiDentro,
    "messa $1 dentro $2, al posto $3",
    "put $1 inside $2, as the place $3"
  voce kDSposta,
    "spostato il posto $1 da $2 a $3",
    "moved the place $1 from $2 to $3"
  voce kDTogliEntita,
    "tolta l'entità $1",
    "removed the entity $1"
  voce kDTogliPubblico,
    "tolto il connettore $1$2 da $3",
    "removed the connector $1$2 from $3"
  voce kDCscNuova,
    "connettore $1 creato",
    "connector $1 created"
  voce kDTogliCsc,
    "tolto il connettore $1",
    "removed the connector $1"
  voce kDCompletaScrivi,
    "Completa di $1: righe e dialogo scritti",
    "Complete $1: lines and dialogue written"
  voce kDApprovaRighe,
    "approvate $1 di $2",
    "approved $1 of $2"
  voce kDApprovaIntero,
    "approvato il connettore $1",
    "approved the connector $1"
  voce kDCasellaRigaTolta,
    "riga $1 di $2: tolta",
    "line $1 of $2: removed"
  voce kDCasellaRigheTolte,
    "righe $1-$2 di $3: tolte",
    "lines $1-$2 of $3: removed"
  voce kDCasellaRigaCambiata,
    "riga $1 di $2: cambiata",
    "line $1 of $2: changed"
  voce kDCasellaRigheCambiate,
    "righe $1-$2 di $3: cambiate",
    "lines $1-$2 of $3: changed"
  voce kDNuovaVersione,
    "versione $1 di $2 preparata",
    "version $1 of $2 prepared"
  voce kDBloccoRigaTolta,
    "riga $1 di $2: tolta",
    "line $1 of $2: removed"
  voce kDBloccoRigheTolte,
    "righe $1-$2 di $3: tolte",
    "lines $1-$2 of $3: removed"
  voce kDBloccoRigaCambiata,
    "riga $1 di $2: cambiata",
    "line $1 of $2: changed"
  voce kDBloccoRigheCambiate,
    "righe $1-$2 di $3: cambiate",
    "lines $1-$2 of $3: changed"
  voce kDBloccoCreaForme,
    "forme concrete di $1 create",
    "concrete forms of $1 created"
  voce kDBloccoCreaPiano,
    "piano di prova di $1 creato",
    "verification plan of $1 created"
  voce kDProfiloCrea,
    "profilo $1 creato",
    "profile $1 created"
  voce kDProfiloTogli,
    "tolto il profilo $1",
    "removed the profile $1"
  voce kDApprovaBloccoForme,
    "approvate le forme concrete «$1»",
    "approved the concrete forms “$1”"
  voce kDApprovaBloccoProfilo,
    "approvato il profilo $1",
    "approved the profile $1"
  voce kDSchedaScopo,
    "scopo di $1 cambiato",
    "purpose of $1 changed"
  voce kDSchedaPromessaAggiungi,
    "promessa$1 di $2: aggiunta",
    "guarantee$1 of $2: added"
  voce kDSchedaPromessaCambia,
    "promessa$1 di $2: cambiata",
    "guarantee$1 of $2: changed"
  voce kDSchedaPromessaTogli,
    "promessa$1 di $2: tolta",
    "guarantee$1 of $2: removed"
  voce kDSchedaIpotesiAggiungi,
    "presupposto$1 di $2: aggiunto",
    "assumption$1 of $2: added"
  voce kDSchedaIpotesiCambia,
    "presupposto$1 di $2: cambiato",
    "assumption$1 of $2: changed"
  voce kDSchedaIpotesiTogli,
    "presupposto$1 di $2: tolto",
    "assumption$1 of $2: removed"
  voce kDSchedaEventoAggiungi,
    "evento$1 di $2: aggiunto",
    "event$1 of $2: added"
  voce kDSchedaEventoCambia,
    "evento$1 di $2: cambiato",
    "event$1 of $2: changed"
  voce kDSchedaEventoTogli,
    "evento$1 di $2: tolto",
    "event$1 of $2: removed"
  voce kDSchedaStatoAggiungi,
    "stato$1 di $2: aggiunto",
    "state$1 of $2: added"
  voce kDSchedaStatoCambia,
    "stato$1 di $2: cambiato",
    "state$1 of $2: changed"
  voce kDSchedaStatoTogli,
    "stato$1 di $2: tolto",
    "state$1 of $2: removed"
  voce kDAzione,
    "$1",
    "$1"
  voce kEsitoScrittiIFile,
    "Scritti i file: $1",
    "Files written: $1"
  voce kEsitoFatto,
    "Fatto.",
    "Done."
  voce kEsitoToltoIlFile,
    "tolto il file $1",
    "removed the file $1"
  voce kEsitoToltiIFile,
    "tolti i file $1",
    "removed the files $1"
  voce kEsciNonTrovoBcdd,
    "bcdd-editor: non trovo bcdd in $1",
    "bcdd-editor: I cannot find bcdd in $1"
  voce kEsciCartellaNonTrovata,
    "bcdd-editor: cartella non trovata: $1",
    "bcdd-editor: folder not found: $1"
  voce kEsciCartellaNonLeggibile,
    "bcdd-editor: cartella non leggibile: $1",
    "bcdd-editor: folder not readable: $1"
  voce kEsciNessunaEntita,
    "bcdd-editor: nessuna entità $1 in $2",
    "bcdd-editor: no entity $1 in $2"
  voce kCartellaSenzaPercorso,
    "La cartella «$1» non si può usare perché questo computer non la raggiunge come una cartella sua. Di solito è una cartella di rete non collegata: collegala come unità o come cartella di rete, poi scegli di nuovo la cartella.",
    "The folder “$1” cannot be used because this computer cannot reach it as one of its own folders. It is usually a network folder that is not connected: connect it as a drive or as a network folder, then choose the folder again."
  voce kCartellaGiaNellElenco,
    "La cartella «$1» è già nell'elenco.",
    "The folder \"$1\" is already in the list."
  voce kCartellaNonSiTrova,
    "La cartella «$1» non si trova: controlla che esista e sia collegata.",
    "The folder “$1” cannot be found: check that it exists and is connected."
  voce kCartelleAggiunte,
    "aggiunte le cartelle: $1",
    "folders added: $1"
  voce kCartellaAggiunta,
    "aggiunta la cartella $1",
    "folder added: $1"
  voce kCartellaTolta,
    "tolta la cartella $1 (i suoi file restano dove sono)",
    "folder removed: $1 (its files stay where they are)"
  voce kCartellaUltima,
    "Deve restare almeno una cartella.",
    "At least one folder must remain."
  voce kEsciDisplay,
    "bcdd-editor: non riesco ad aprire il display",
    "bcdd-editor: I cannot open the display"
  voce kLinguaRicordataNo,
    "la lingua non è stata ricordata: la scelta vale per questa finestra",
    "the language could not be saved: the choice applies to this window only"
  voce kLinguaCambiata,
    "lingua: $1",
    "language: $1"
  voce kLatoOfferto,
    " (offerto)",
    " (provided)"
  voce kLatoUsato,
    " (usato)",
    " (used)"
  voce kHaGiaOffre,
    "$1 offre già $2",
    "$1 already provides $2"
  voce kHaGiaUsa,
    "$1 usa già $2",
    "$1 already uses $2"
  voce kNonHaOffre,
    "$1 non offre $2",
    "$1 does not provide $2"
  voce kNonHaUsa,
    "$1 non usa $2",
    "$1 does not use $2"

proc componi(modello: string, a: openArray[string]): string =
  ## 008:4:1 Sostituzione dei segnaposto in un solo passaggio: il testo inserito non si rilegge.
  var i = 0
  while i < modello.len:
    let c = modello[i]
    if c == '$' and i + 1 < modello.len:
      let d = modello[i + 1]
      if d == '$':
        result.add '$'
        i += 2
        continue
      if d in {'1'..'9'}:
        let k = ord(d) - ord('1')
        if k < a.len: result.add a[k]
        i += 2
        continue
    result.add c
    inc i

proc testoIn*(l: Lingua, k: Chiave, a: varargs[string, `$`]): string =
  componi(if l == lgIt: voci[k].it else: voci[k].en, a)

proc tx*(k: Chiave, a: varargs[string, `$`]): string =
  ## 008:4:2 Il testo della chiave nella lingua corrente.
  testoIn(lingua, k, a)
