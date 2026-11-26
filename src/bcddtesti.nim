# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 095:1:1 Catalogo dei testi per la persona di bcdd, in italiano e in inglese.
# 095:1:2 Unico luogo dei testi: ogni voce ha la chiave, il testo italiano e il testo inglese, vicini. Segnaposto posizionali
# 095:1:3 `$1`..`$9`; `$$` è un dollaro. Ciò che un programma legge (parole chiave, codici, chiavi del JSON) non sta qui.
# 095:1:4 Completezza a compilazione: la macro `catalogo` esige per ogni voce entrambi i testi (togliere un testo non compila).
import std/[macros, algorithm]

type Lingua* = enum
  lgEn = "en", lgIt = "it"

var lingua*: Lingua = lgEn   # 095:2:1 impostata una volta in bcdd.nim, prima di ogni lettura o analisi

macro catalogo(body: untyped): untyped =
  ## 095:3:1 Costruisce l'enumerato `Chiave` e la tabella `voci` dalle chiamate `voce(kNome, "it", "en")`.
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

  # 095:8:1 file e cartelle (bcddsafe)
  voce kCartellaNonTrovata, "$1: cartella non trovata: $2", "$1: folder not found: $2"
  voce kCartellaNonLeggibile, "$1: cartella non leggibile: $2", "$1: folder not readable: $2"
  voce kNonECartella, "$1: non è una cartella: $2", "$1: not a folder: $2"
  voce kFileNonTrovato, "$1: file non trovato: $2", "$1: file not found: $2"
  voce kFileNonLeggibile, "$1: non leggibile: $2", "$1: not readable: $2"
  voce kNonEFile, "$1: non è un file: $2", "$1: not a file: $2"
  voce kNonUtf8, "$1: il file non è UTF-8 valido (riga $2)",
    "$1: the file is not valid UTF-8 (line $2)"
  voce kNonRiescoScrivere, "$1: non riesco a scrivere $2: $3", "$1: I cannot write $2: $3"
  voce kCambiatoDuranteComando, "$1: $2 è cambiato durante il comando: niente scritto",
    "$1: $2 changed during the command: nothing written"
  voce kPiuCollegamenti, "$1: $2 ha più collegamenti fisici: non lo riscrivo",
    "$1: $2 has more than one hard link: I am not rewriting it"

  # 095:8:1 bcdd new
  voce kScheletro,
    "-- CSC creata da bcdd new. Si scrive a mano; bcdd check controlla la forma.\n" &
      "-- Senza STATUS RATIFIED nessuna riga è contratto: è da approvare finché l'operatore non la approva.\n" &
      "\n" &
      "CSC $1 VERSION 0.1\n" &
      "  STATUS HYPOTHESIS\n" &
      "  PURPOSE \"da scrivere: in una frase, di che cosa è responsabile $1\"\n" &
      "\n" &
      "  -- Ingressi e uscite (togliere il commento e scrivere):\n" &
      "  -- CAPABILITY Nome(parametro: Tipo)        che cosa si può chiedere\n" &
      "  -- EVENT IN   nome(parametro: Tipo)        che cosa arriva da fuori\n" &
      "  -- EVENT OUT  nome(parametro: Tipo)        che cosa esce\n" &
      "  -- STATE      nome : Tipo INITIAL valore   che cosa si vede da fuori\n" &
      "\n" &
      "  -- Promesse a parole:\n" &
      "  -- GUARANTEE g1: VERBAL \"che cosa promette\"\n" &
      "  --               VERIFY BY JUDGEMENT \"chi giudica, e su che cosa\"\n" &
      "END\n",
    "-- CSC created by bcdd new. It is filled in by hand; bcdd check checks the form.\n" &
      "-- Without STATUS RATIFIED no line is part of the contract: it is pending approval until the operator approves it.\n" &
      "\n" &
      "CSC $1 VERSION 0.1\n" &
      "  STATUS HYPOTHESIS\n" &
      "  PURPOSE \"to be filled in: in one sentence, what $1 is responsible for\"\n" &
      "\n" &
      "  -- Inputs and outputs (uncomment and fill in):\n" &
      "  -- CAPABILITY Name(parameter: Type)        what can be requested\n" &
      "  -- EVENT IN   name(parameter: Type)        what arrives from outside\n" &
      "  -- EVENT OUT  name(parameter: Type)        what goes out\n" &
      "  -- STATE      name : Type INITIAL value    what is visible from outside\n" &
      "\n" &
      "  -- Guarantees in words:\n" &
      "  -- GUARANTEE g1: VERBAL \"what it guarantees\"\n" &
      "  --               VERIFY BY JUDGEMENT \"who judges, and on what\"\n" &
      "END\n"
  voce kNewCreato, "creato $1", "created $1"
  voce kNewUso, "uso: bcdd new NOME", "usage: bcdd new NAME"
  voce kNewNomeNonValido, "bcdd new: nome non valido: $1", "bcdd new: invalid name: $1"
  # 095:9:2 su ogni sistema `new` rifiuta i nomi che su Windows indicano un dispositivo
  voce kNewNomeDispositivo, "bcdd new: il nome «$1» non si può usare: Windows lo riserva per sé (nomi riservati: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Scegline un altro",
    "bcdd new: the name “$1” cannot be used: Windows reserves it (reserved names: CON, PRN, AUX, NUL, COM1-9, LPT1-9). Choose another name"
  voce kNewEsiste, "bcdd new: $1 esiste già: non lo sovrascrivo",
    "bcdd new: $1 already exists: I am not overwriting it"
  voce kNewNonRiescoCreare, "bcdd new: non riesco a creare $1: $2", "bcdd new: I cannot create $1: $2"

  # 095:8:1 bcdd: scelta della lingua, uso generale e di check
  voce kUsoGenerale, "uso: bcdd [--lang it|en] COMANDO; comandi: new NOME | check [--strict] [--json] [--dir CARTELLA]... FILE | refine FILE [--csc NOME] | ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero",
    "usage: bcdd [--lang it|en] COMMAND; commands: new NAME | check [--strict] [--json] [--dir FOLDER]... FILE | refine FILE [--csc NAME] | ratify FILE [--csc NAME] [--dir FOLDER]... [ID | --all] D-number"
  voce kUsoCheck, "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE",
    "usage: bcdd check [--strict] [--json] [--dir FOLDER]... FILE"
  voce kLangAccetta, "bcdd: --lang accetta it oppure en: $1", "bcdd: --lang accepts it or en: $1"
  voce kLangEnvNonValida, "bcdd: BCDD_LANG deve essere it o en, non: $1",
    "bcdd: BCDD_LANG must be it or en, not: $1"

  # 095:8:1 check: errori e messaggi di analisi (bcddcheck)
  voce kNomeGiaUsatoAllaRiga, "nome già usato alla riga $1: $2", "name already used at line $1: $2"
  voce kUnPezzoVARIANTScrittoMale, "un segmento VARIANT scritto male", "a badly written VARIANT segment"
  voce kValoreNonDelTipo, "valore non del tipo $1: $2", "value not of type $1: $2"
  voce kInGiro, "$1 in modo circolare: $2 -> $3", "circular $1: $2 -> $3"
  voce kREDUCESTOInGiro, "REDUCES TO in modo circolare: $1 -> $2", "circular REDUCES TO: $1 -> $2"
  voce kNomeNonDichiaratoComeValore, "nome non dichiarato come valore di TYPE: $1",
    "name not declared as a value of TYPE: $1"
  voce kIlTipoDellIndiceDi, "il tipo dell'indice di $1 non è finito: $2",
    "the type of the index of $1 is not finite: $2"
  voce kNomeNonDichiarato, "nome non dichiarato: $1", "name not declared: $1"
  voce kNonEUnEventoServe, "$1 non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY",
    "$1 is not an event: an EVENT, a DEFINE EVENT or a phase of a CAPABILITY is needed"
  voce kNomeNonDichiaratoComeCampo, "nome non dichiarato come campo di $1: $2",
    "name not declared as a field of $1: $2"
  voce kTipoIncoerenteServeTrovato, "tipo incoerente: serve $1, trovato $2",
    "inconsistent type: $1 needed, $2 found"
  voce kHaUnIndiceScriviValore, "$1 ha un indice: scrivi $2[valore di $3]",
    "$1 has an index: write $2[value of $3]"
  voce kIndiceDiNonDelTipo, "indice di $1 non del tipo $2: $3", "index of $1 not of type $2: $3"
  voce kNonHaIndice, "$1 non ha indice", "$1 has no index"
  voce kNomeNonDichiaratoCome, "nome non dichiarato come $1: $2", "name not declared as $1: $2"
  voce kBloccoNonChiusoMancaEND, "blocco non chiuso: manca END di $1 $2",
    "unclosed block: END of $1 $2 is missing"
  voce kLaSceltaEGiaScritta, "la scelta $1 = $2 è già scritta alla riga $3",
    "the choice $1 = $2 is already written at line $3"
  voce kIlPezzoVARIANTEVuoto, "il segmento VARIANT $1 = $2 è vuoto: una scelta senza righe si scrive con una parte [0 .. 1]",
    "the VARIANT segment $1 = $2 is empty: a choice without lines is written with a part [0 .. 1]"
  voce kLaDimensioneHaUnaSola, "il gruppo di scelte $1 ha una sola scelta ($2): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]",
    "choice group $1 has a single choice ($2): at least two are needed; a part that may be missing is written with [0 .. 1]"
  voce kDETAILSNominaUnIdChe, "DETAILS nomina un id che non è una GUARANTEE di questa ENTITY: ",
    "DETAILS names an id that is not a GUARANTEE of this ENTITY: "
  voce kDETAILSNominaUnIdChe2, "DETAILS nomina un id che non è una GUARANTEE né una ASSUME di questa CSC: ",
    "DETAILS names an id that is neither a GUARANTEE nor an ASSUME of this CSC: "
  voce kDETAILSNominaUnaGUARANTEEChe, "DETAILS nomina una GUARANTEE che non vale in tutte le composizioni di questa riga: $1 (sta in $2)",
    "DETAILS names a GUARANTEE that does not hold in all the compositions of this line: $1 (it is in $2)"
  voce kDETAILSInGiro, "DETAILS in modo circolare: $1", "circular DETAILS: $1"
  voce kDETAILSNominaUnNomeChe, "DETAILS nomina un nome che non è una DEFINE di questa CSC: $1",
    "DETAILS names a name that is not a DEFINE of this CSC: $1"
  voce kDETAILSNominaUnIdChe3, "DETAILS nomina un id che non è uno SCENARIO di questo blocco: $1",
    "DETAILS names an id that is not a SCENARIO of this block: $1"
  voce kDETAILSInGiro2, "DETAILS in modo circolare: $1 -> $2", "circular DETAILS: $1 -> $2"
  voce kREPEATSenzaPassiIPassi, "REPEAT senza passi: i passi ripetuti si scrivono dopo la riga REPEAT",
    "REPEAT without steps: the repeated steps are written after the REPEAT line"
  voce kInUnaCSCINomi, "$1: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità",
    "$1: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity"
  voce kNonOffreNeUsaIl, "$1: $2 non offre né usa il connettore $3; uno scenario può citare solo i connettori di $4",
    "$1: $2 neither provides nor uses connector $3; a scenario can cite only the connectors of $4"
  voce kNomeNonDichiaratoComeParametro, "nome non dichiarato come parametro di $1: $2",
    "name not declared as a parameter of $1: $2"
  voce kIntestazioneNonValidaAttesa, "intestazione non valida: attesa $1", "invalid header: $1 expected"
  voce kREFINEMENTVIEWEUscitaDal, "REFINEMENT VIEW è stata ritirata: una scomposizione si scrive con ENTITY",
    "REFINEMENT VIEW has been withdrawn: a decomposition is written with ENTITY"
  voce kSecondoBINDINGSenzaNomePer, "secondo BINDING senza nome per la CSC $1 VERSION $2: il primo è alla riga $3. Con due o più BINDING ognuno ha un nome, AS nome",
    "second BINDING without a name for CSC $1 VERSION $2: the first is at line $3. With two or more BINDINGs, each has a name: AS name"
  voce kNomeDiBINDINGGiaUsato, "nome di BINDING già usato alla riga $1: $2",
    "BINDING name already used at line $1: $2"
  voce kSTATUSRipetutoIlPrimoE, "STATUS ripetuto: il primo è alla riga $1",
    "STATUS repeated: the first is at line $1"
  voce kSTATUSRATIFIEDSenzaDecisioneServe, "STATUS RATIFIED senza decisione: serve BY D-numero",
    "STATUS RATIFIED without a decision: BY D-number is needed"
  voce kREPEATRipetutoNellaStoriaIl, "REPEAT ripetuto nella storia: il primo è alla riga $1",
    "REPEAT repeated in the scenario: the first is at line $1"
  voce kRipetizioniNonValideScriviREPEAT, "ripetizioni non valide: $1..$2. Scrivi REPEAT minimo..massimo, con il massimo almeno 1 e non più piccolo del minimo",
    "invalid repetitions: $1..$2. Write REPEAT minimum..maximum, with the maximum at least 1 and not smaller than the minimum"
  voce kREPEATEVERYVuoleUnaStoria, "REPEAT … EVERY vuole una storia con le unità di tempo",
    "REPEAT … EVERY requires a scenario with time units"
  voce kPURPOSERipetutoIlPrimoE, "PURPOSE ripetuto: il primo è alla riga $1",
    "PURPOSE repeated: the first is at line $1"
  voce kVERBALSenzaVERIFYServeVERIFY, "VERBAL senza VERIFY: serve VERIFY BY JUDGEMENT o INSPECTION e una stringa",
    "VERBAL without VERIFY: VERIFY BY JUDGEMENT or INSPECTION and a string are needed"
  voce kVARIANTNonPuoStareIn, "VARIANT non può stare in una CSC: le varianti si scrivono in un'entità",
    "VARIANT cannot appear in a CSC: variants are written in an entity"
  voce kPassiConESenzaUnita, "passi con e senza unità di tempo nello stesso SCENARIO",
    "steps with and without a time unit in the same SCENARIO"
  voce kIlPassoNonEPiu, "il passo @$1 non è più breve del periodo di REPEAT: ogni passo ripetuto ha un tempo minore di EVERY $2",
    "the step @$1 is not shorter than the period of REPEAT: every repeated step has a time smaller than EVERY $2"
  voce kIlTempoDelPassoDiminuisce, "il tempo del passo diminuisce: @$1 dopo @$2",
    "the time of the step decreases: @$1 after @$2"
  voce kPURPOSENonPuoStareIn, "PURPOSE non può stare in un segmento VARIANT: scrivilo prima del primo VARIANT",
    "PURPOSE cannot appear in a VARIANT segment: write it before the first VARIANT"
  voce kVARIANTScrittoMaleServeVARIANT, "VARIANT scritto male: serve VARIANT gruppo = scelta",
    "VARIANT badly written: VARIANT group = choice is needed"
  voce kNonPuoStareInUn, "$1 non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori",
    "$1 cannot appear in an entity: write it in the CSC of one of its connectors"
  voce kLaParteHaUnNumero, "la parte $1 ha un numero di copie non valido: [$2 .. $3]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo",
    "the part $1 has an invalid number of copies: [$2 .. $3]. Write [minimum .. maximum] with two integers: the minimum 0 or more, the maximum at least 1 and not smaller than the minimum"
  voce kMancaIlCampoNellEXTENSION, "manca il campo $1 nell'EXTENSION $2", "field $1 is missing in EXTENSION $2"
  voce kLEXTENSIONHaKINDFUNCTION, "l'EXTENSION $1 ha KIND FUNCTION: dopo PARAMS serve il tipo del risultato, PARAMS (…) : Tipo",
    "EXTENSION $1 has KIND FUNCTION: after PARAMS the result type is needed, PARAMS (…) : Type"
  voce kFORMDeveCominciareConIl, "FORM deve cominciare con il nome dell'estensione: $1",
    "FORM must begin with the name of the extension: $1"
  voce kIlParametroDeveComparireUna, "il parametro $1 deve comparire una volta in FORM",
    "the parameter $1 must appear once in FORM"
  voce kREDUCESTONominaNonE, "REDUCES TO nomina $1: non è una parola del linguaggio, un parametro né un'estensione del PROFILE $2",
    "REDUCES TO names $1: it is not a word of the language, a parameter or an extension of PROFILE $2"
  voce kLEXTENSIONRipeteUnaForma, "l'EXTENSION $1 ripete una forma che il linguaggio ha già: $2",
    "EXTENSION $1 repeats a form that the language already has: $2"
  voce kValoreDiKINDNonAmmesso, "valore di KIND non ammesso: $1", "value of KIND not admitted: $1"
  voce kValoreDiLEVELNonAmmesso, "valore di LEVEL non ammesso: $1", "value of LEVEL not admitted: $1"
  voce kVERIFYV1NominaUnControllo, "VERIFY V1 nomina un controllo che non esiste: $1",
    "VERIFY V1 names a check that does not exist: $1"
  voce kCampoREDUCESTORipetutoNell, "campo REDUCES TO ripetuto nell'EXTENSION $1: il primo è alla riga $2",
    "field REDUCES TO repeated in EXTENSION $1: the first is at line $2"
  voce kCampoRipetutoNellEXTENSIONIl, "campo $1 ripetuto nell'EXTENSION $2: il primo è alla riga $3",
    "field $1 repeated in EXTENSION $2: the first is at line $3"
  voce kIntestazioneNonValidaAttesaEXTENSION, "intestazione non valida: attesa EXTENSION Nome",
    "invalid header: EXTENSION Name expected"
  voce kIlNomeDellEstensioneE, "il nome dell'estensione è una parola del linguaggio: $1",
    "the name of the extension is a word of the language: $1"
  voce kNomeDiEstensioneGiaUsato, "nome di estensione già usato alla riga $1: $2",
    "extension name already used at line $1: $2"
  voce kSTATUSNonPuoStareIn, "STATUS non può stare in una VERIFICATION: un piano di prova non si approva",
    "STATUS cannot appear in a VERIFICATION: a verification plan is not approved"
  voce kBloccoNonChiusoMancaEND2, "blocco non chiuso: manca END di EXTENSION $1",
    "unclosed block: END of EXTENSION $1 is missing"
  voce kEXTENSIONFuoriDaUnPROFILE, "EXTENSION fuori da un PROFILE: un'estensione si dichiara in un profilo",
    "EXTENSION outside a PROFILE: an extension is declared in a profile"
  voce kENDSenzaUnBloccoAperto, "END senza un blocco aperto", "END without an open block"
  voce kStringaNonChiusaIlFile, "stringa non chiusa: il file finisce dentro la stringa aperta qui",
    "unclosed string: the file ends inside the string opened here"
  voce kIlFileNonContieneNessuna, "il file non contiene nessuna CSC", "the file contains no CSC"
  voce kSTATUSNonValido, "STATUS non valido", "invalid STATUS"
  voce kNonEUnFile, "non è un file: $1", "not a file: $1"
  voce kNonLeggibile, "non leggibile: $1", "not readable: $1"
  voce kNonUtf8Citazione, "non UTF-8: $1", "not UTF-8: $1"
  voce kNonContiene, "$1 non contiene $2", "$1 does not contain $2"
  voce kProfiloVERSIONNonTrovato, "profilo $1 VERSION $2 non trovato", "profile $1 VERSION $2 not found"
  voce kEXTENSIONDelPROFILEConErrori, "EXTENSION $1 del PROFILE $2 con errori",
    "EXTENSION $1 of PROFILE $2 with errors"
  voce kNonEUnElementoDella, "$1 non è un elemento della $2", "$1 is not an element of $2"
  voce kTRANSLATESNominaUnaStoriaChe, "TRANSLATES nomina una storia che la $1 non ha: $2",
    "TRANSLATES names a scenario that $1 does not have: $2"
  voce kPROFILEImportatoConVERSIONMa, "PROFILE $1 importato con VERSION $2, ma la CSC $3 lo importa con VERSION $4",
    "PROFILE $1 imported with VERSION $2, but CSC $3 imports it with VERSION $4"
  voce kCSCNonTrovataElementiNon, "$1: CSC non trovata, elementi non controllati",
    "$1: CSC not found, elements not checked"
  voce kCSCNonTrovataCoperturaNon, "CSC non trovata: copertura non calcolata",
    "CSC not found: coverage not computed"
  voce kLEntitaHaPiuDi, "l'entità $1 ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole",
    "entity $1 has more than 64 compositions: bcdd does not check them one by one. Remove a choice, or divide the entity into smaller entities"
  voce kRiga, "$1 (riga $2)", "$1 (line $2)"
  voce kLaOffre, "la offre $1", "it is provided by $1"
  voce kLaOffrono, "la offrono $1", "it is provided by $1"
  voce kLaUsaDaFuoriRiga, "la usa $1 da fuori (riga $2)", "$1 uses it from outside (line $2)"
  voce kNessunoLaOffre, "nessuno la offre", "nobody provides it"
  voce kLaParteUsaIlConnettore, "la parte $1 usa il connettore $2: nessun'altra parte di $3 lo offre, né $4 lo usa da fuori",
    "the part $1 uses connector $2: no other part of $3 provides it, nor does $4 use it from outside"
  voce kNessunaParteTrovataLaOffre, "nessuna parte trovata la offre (parti non controllate: $1)",
    "no part found provides it (parts not checked: $1)"
  voce kLaParteOffreIlConnettore, "la parte $1 offre il connettore $2: nessun'altra parte di $3 lo usa, né $4 lo offre da fuori",
    "the part $1 provides connector $2: no other part of $3 uses it, nor does $4 provide it from outside"
  voce kNomeNonDichiaratoCome2, "nome non dichiarato come $1: $2.$3", "name not declared as $1: $2.$3"
  voce kNomeNonDichiaratoComeParametro2, "nome non dichiarato come parametro di $1.$2: $3",
    "name not declared as a parameter of $1.$2: $3"

  # 095:8:1 check: intestazioni, stato, chiusura, forme, copertura (bcddcheck)
  voce kHintCSC, "CSC Nome VERSION numero", "CSC Name VERSION number"
  voce kHintENTITY, "ENTITY Nome VERSION numero", "ENTITY Name VERSION number"
  voce kHintBINDING, "BINDING NomeCSC VERSION numero [AS nome]",
    "BINDING CSCName VERSION number [AS name]"
  voce kHintVERIFICATION, "VERIFICATION NomeCSC VERSION numero", "VERIFICATION CSCName VERSION number"
  voce kHintPROFILE, "PROFILE Nome VERSION numero", "PROFILE Name VERSION number"
  voce kSenzaSTATUS, "senza STATUS", "without STATUS"
  voce kPubOffre, " (offre)", " (provided)"
  voce kPubUsato, " (usato)", " (used)"
  voce kQuestoFile, "questo file", "this file"
  voce kTrovataSoloVersion, "trovata solo la VERSION $1 in $2", "only VERSION $1 found in $2"
  voce kNessunaParola, "nessuna", "none"
  voce kIlConnettorePubblico, "il connettore pubblico $1 di $2$3 non è affidato a nessuna parte",
    "the public connector $1 of $2$3 is not assigned to any part"
  voce kNomeNonDichiarato2, "nome non dichiarato: $1.$2", "name not declared: $1.$2"
  voce kVoceCoerenzaDettaglio, "$1 $2 DETAILS $3: coerenza fra la riga e la riga che dettaglia, una delle due a parole",
    "$1 $2 DETAILS $3: consistency between the line and the line that details it, one of the two in words"
  voce kVoceExtMeaning, "EXTENSION $1: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti",
    "EXTENSION $1: the MEANING neither describes the implementation nor gives authority or precedence between parts"
  voce kVoceExtMeaningRiduce, "EXTENSION $1: MEANING e REDUCES TO dicono la stessa cosa",
    "EXTENSION $1: MEANING and REDUCES TO say the same thing"
  voce kVoceExtNonRipete, "EXTENSION $1: non ripete una forma che il linguaggio ha già",
    "EXTENSION $1: does not repeat a form that the language already has"

  # 095:8:1 check: il rapporto (sezione 9 della grammatica)
  voce kRapRigaN, "riga $1: $2", "line $1: $2"
  voce kRapRigaSola, "riga $1:", "line $1:"
  voce kRapRighe, "righe: $1 (riconosciute $2, commenti $3, vuote $4, non riconosciute $5)",
    "lines: $1 (recognised $2, comments $3, blank $4, unrecognised $5)"
  voce kRapBlocchi, "blocchi: $1", "blocks: $1"
  voce kCitInQuestoFile, " in questo file alla riga $1", " in this file at line $1"
  voce kCitVersioneAttesa, ": VERSION $1, attesa VERSION $2", ": VERSION $1, expected VERSION $2"
  voce kCitInAltroFile, " in $1 alla riga $2: VERSION $3, $4, ",
    " in $1 at line $2: VERSION $3, $4, "
  voce kCitAttesa, ", attesa VERSION $1", ", expected VERSION $1"
  voce kCitNonRiconosciute, ", righe non riconosciute: $1", ", unrecognised lines: $1"
  voce kCitUsing, "USING $1 in $2 alla riga $3", "USING $1 in $2 at line $3"
  voce kNessunErrore, "nessun errore", "no errors"
  voce kUnErrore, "1 errore", "1 error"
  voce kNErrori, "$1 errori", "$1 errors"
  voce kIntestazioneNonValidaPar, "(intestazione non valida)", "(invalid header)"
  voce kRapErrori, "1. ERRORI: $1", "1. ERRORS: $1"
  voce kPosFile, "file", "file"
  voce kPosRiga, "riga $1", "line $1"
  voce kRapGrado, "2. GRADO DELLE RIGHE CONTRATTUALI", "2. DEGREE OF THE CONTRACTUAL LINES"
  voce kRapGradoVerbale, "verbale: $1", "verbal: $1"
  voce kRapGradoFormale, "formale: $1", "formal: $1"
  voce kRapGradoEstensione, "estensione dichiarata: $1", "declared extension: $1"
  voce kRapGradoNonRiconosciuta, "non riconosciuta: $1", "unrecognised: $1"
  voce kGradoVerbale, "verbale", "verbal"
  voce kGradoFormale, "formale", "formal"
  voce kGradoEstensione, "estensione dichiarata", "declared extension"
  voce kGradoNonRiconosciuta, "non riconosciuta", "unrecognised"
  voce kRapUndecided, "3. UNDECIDED: $1", "3. UNDECIDED: $1"
  voce kRapIpotesi, "4. DA APPROVARE, NON CONTRATTO: $1", "4. PENDING APPROVAL, NOT CONTRACT: $1"
  voce kRapNonRiconosciute, "5. RIGHE NON RICONOSCIUTE: $1", "5. UNRECOGNISED LINES: $1"
  voce kRapTipiNonDichiarati, "6. TIPI NON DICHIARATI: $1", "6. UNDECLARED TYPES: $1"
  voce kElencoRiga, "riga $1", "line $1"
  voce kElencoRighe, "righe $1", "lines $1"
  voce kRapNominate, "7. CSC NOMINATE E NON CONTROLLATE: $1", "7. CSCs NAMED BUT NOT CHECKED: $1"
  voce kRapUsi, "8. USI DENTRO LE ENTITÀ: $1", "8. USES WITHIN ENTITIES: $1"
  voce kRapComposizioni, "9. COMPOSIZIONI: $1", "9. COMPOSITIONS: $1"
  voce kRapPiuDi64, "ENTITY $1: più di 64, non controllate",
    "ENTITY $1: more than 64, not checked"
  voce kRapAssenze, "10. ASSENZE DICHIARATE: $1", "10. DECLARED ABSENCES: $1"
  voce kAssenzaSenza, "senza $1: $2", "without $1: $2"
  # 095:9:1 0.2: nomi dei valori del fattore di una parte facoltativa (GRAMMATICA_F1 4.10)
  voce kCompCon, "con $1", "with $1"
  voce kCompSenza, "senza $1", "without $1"
  voce kRapForme, "12. FORME CONCRETE MANCANTI: $1", "12. MISSING CONCRETE FORMS: $1"
  voce kRapCopertura, "13. COPERTURA DEL PIANO DI PROVA: $1", "13. VERIFICATION PLAN COVERAGE: $1"
  voce kCoperturaMezzo, "$1 (riga $2): $3", "$1 (line $2): $3"
  voce kCoperturaNonEseguite, "non eseguite: $1", "not executed: $1"
  voce kRapDaGiudicare, "14. DA GIUDICARE: $1", "14. TO BE JUDGED: $1"
  voce kRapNonEseguiti, "15. CONTROLLI NON ESEGUITI: $1", "15. CHECKS NOT EXECUTED: $1"
  voce kNonEsegStorie, "storie", "scenarios"
  voce kNonEsegInneschi, "copertura degli inneschi", "coverage of the triggers"
  voce kNonEsegCoerenza, "coerenza di presupposti e promesse",
    "consistency of assumptions and guarantees"
  voce kNonEsegDettagli, "coerenza dei dettagli", "consistency of the details"
  voce kRapEsito, "esito: $1", "outcome: $1"
  voce kEsitoNonRiconosciute, "; righe non riconosciute: $1$2", "; unrecognised lines: $1$2"
  voce kEsitoStrict, " (--strict)", " (--strict)"
  voce kEsitoVediSezione5, " (vedi sezione 5)", " (see section 5)"
  voce kNcMotivo, "$1 ($2)", "$1 ($2)"

  # 095:8:1 formule (bcddformula)
  voce kUnEvento, "un evento", "an event"
  voce kInUnEntitaINomi, "in un'entità i nomi delle CSC si scrivono con il connettore davanti: $1",
    "in an entity the names of the CSCs are written with the connector in front: $1"
  voce kUnNumero, "un numero", "a number"
  voce kNonEUnValore, "$1 non è un valore", "$1 is not a value"
  voce kEUnaCAPABILITYSiNomina, "$1 è una CAPABILITY: si nomina con una fase (requested(X), …) o in ACCEPTS, REQUIRES, ENSURES, RESOLVES",
    "$1 is a CAPABILITY: it is named with a phase (requested(X), …) or in ACCEPTS, REQUIRES, ENSURES, RESOLVES"
  voce kInUnaCSCINomi2, "$1.$2: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità",
    "$1.$2: in a CSC, names are not written with the connector in front. The order of two connectors is written in a SCENARIO of the entity"
  voce kNonOffreNeUsaIl2, "$1.$2: $3 non offre né usa il connettore $4; una promessa d'entità può citare solo i connettori di $5",
    "$1.$2: $3 neither provides nor uses connector $4; an entity guarantee can cite only the connectors of $5"
  voce kNonEUnaCAPABILITY, "$1 non è una CAPABILITY", "$1 is not a CAPABILITY"
  voce kNonEUnaDEFINECon, "$1 non è una DEFINE con parametri", "$1 is not a DEFINE with parameters"
  voce kMancaLArgomentoNellaChiamata, "manca l'argomento $1 nella chiamata di $2",
    "the argument $1 is missing in the call to $2"
  voce kNonEUnoSTATE, "$1 non è uno STATE", "$1 is not a STATE"
  voce kUnNumeroOUnaDurata, "un numero o una durata", "a number or a duration"
  voce kDentroUnAltraFormaIl, "$1 dentro un'altra forma: il linguaggio non annida ALWAYS, EVENTUALLY, WHENEVER e le loro abbreviazioni",
    "$1 inside another form: the language does not nest ALWAYS, EVENTUALLY, WHENEVER and their shorthands"
  voce kHaKINDNonSiUsa, "$1 ha KIND $2: non si usa in questa posizione",
    "$1 has KIND $2: it is not used in this position"
  voce kDopoSenzaParentesiScriviA, "^ dopo ^ senza parentesi: scrivi (a ^ b) ^ c",
    "^ after ^ without parentheses: write (a ^ b) ^ c"
  voce kConfrontiInCatenaScriviA, "confronti in catena: scrivi a <= b AND b <= c",
    "chained comparisons: write a <= b AND b <= c"
  voce kANDEORInsiemeSenza, "AND e OR insieme senza parentesi: scrivi (a AND b) OR c, oppure a AND (b OR c)",
    "AND and OR together without parentheses: write (a AND b) OR c, or a AND (b OR c)"
  voce kIMPLIESDopoIMPLIESSenzaParentesi, "IMPLIES dopo IMPLIES senza parentesi: scrivi a IMPLIES (b IMPLIES c)",
    "IMPLIES after IMPLIES without parentheses: write a IMPLIES (b IMPLIES c)"
  voce kTipoIncoerenteServeUnElenco, "tipo incoerente: serve un elenco di valori, trovato $1",
    "inconsistent type: a list of values needed, $1 found"
  voce kUnaProprietaHaUnSolo, "una proprietà ha un solo ambito: $1 è il secondo",
    "a property has a single scope: $1 is the second"
  voce kWITHINEATONCENella, "WITHIN e AT ONCE nella stessa proprietà: scegline uno",
    "WITHIN and AT ONCE in the same property: choose one"
  voce kREQUIRESStaSoloInUna, "REQUIRES sta solo in una ASSUME: in una GUARANTEE si scrive ALWAYS (requested(X) IMPLIES c)",
    "REQUIRES is used only in an ASSUME: in a GUARANTEE write ALWAYS (requested(X) IMPLIES c)"
  voce kHaLEVELNonSiUsa, "$1 ha LEVEL $2: non si usa in un blocco $3",
    "$1 has LEVEL $2: it is not used in a $3 block"
  voce kUsoDiCheNonRispetta, "uso di $1 che non rispetta FORM \"$2\"",
    "use of $1 that does not respect FORM \"$2\""

  # 095:8:1 bcdd save (bcddsave)
  voce kEStatoModificatoDaUn, "$1 è stato modificato da un altro programma dopo che l'hai letto: non tolgo niente; ricarica",
    "$1 was modified by another program after you read it: I am removing nothing; reload"
  voce kHaRigheApprovateNonSi, "$1 ha righe approvate: non si toglie",
    "$1 has approved lines: it is not removed"
  voce kNonRiescoAScrivereNon, "non riesco a scrivere $1: non tolgo niente",
    "I cannot write $1: I am removing nothing"
  voce kNonRiescoATogliere, "non riesco a togliere $1", "I cannot remove $1"
  voce kEsisteGiaNonScrivoNiente, "$1 esiste già: non scrivo niente",
    "$1 already exists: I am writing nothing"
  voce kNonCENonC, "$1 non c'è: non c'è niente da rimettere",
    "$1 does not exist: there is nothing to put back"
  voce kNonRiescoALeggere, "non riesco a leggere $1", "I cannot read $1"
  voce kNonENellaFormaAttesa, "$1 non è nella forma attesa: non scrivo niente",
    "$1 is not in the expected form: I am writing nothing"
  voce kNonEQuelloDiUn, "$1 non è quello di un file tolto: per --undo --expect nuovo serve un file tolto con --remove",
    "$1 is not that of a removed file: --undo --expect nuovo needs a file removed with --remove"
  voce kEDiUnFileTolto, "$1 è di un file tolto: per rimetterlo usa --undo --expect nuovo",
    "$1 is that of a removed file: to put it back use --undo --expect nuovo"
  voce kEStatoModificatoDopoL, "$1 è stato modificato dopo l'ultimo salvataggio: non scrivo niente",
    "$1 was modified after the last save: I am writing nothing"
  voce kEStatoModificatoDaUn2, "$1 è stato modificato da un altro programma dopo che l'hai letto: non scrivo niente; ricarica",
    "$1 was modified by another program after you read it: I am writing nothing; reload"
  voce kLaRigaDiDiventerebbeContratto, "la riga $1 $2 di $3 diventerebbe contratto senza un'approvazione. È una riga da approvare: scrivila con STATUS HYPOTHESIS, oppure approvala con bcdd ratify",
    "the line $1 $2 of $3 would become part of the contract without approval. It is a line pending approval: write it with STATUS HYPOTHESIS, or approve it with bcdd ratify"
  voce kLaRigaDiEContratto, "la riga $1 $2 di $3 è contratto: non si cambia (serve una VERSION nuova)",
    "the line $1 $2 of $3 is part of the contract: it cannot be changed (a new VERSION is needed)"
  voce kLaRigaEContrattoNon, "la riga $1, $2 $3, è contratto ($4): non può cambiare segmento VARIANT; per cambiarla serve una VERSION nuova",
    "the line $1, $2 $3, is part of the contract ($4): it cannot change its VARIANT segment; to change it a new VERSION is needed"
  voce kDiventerebbeContrattoSenzaUnaRatifica, "$1 diventerebbe contratto senza un'approvazione. È una riga da approvare: approvala con bcdd ratify",
    "$1 would become part of the contract without approval. It is a line pending approval: approve it with bcdd ratify"
  voce kEApprovataIlNumeroDella, "$1 è approvata: il numero della versione non si cambia; per una versione nuova rimetti l'intestazione da approvare",
    "$1 is approved: the version number cannot be changed; for a new version put the header back to pending approval"
  voce kEApprovatoLIntestazioneNon, "$1 è approvato: l'intestazione non si cambia; per una versione nuova rimetti l'intestazione da approvare",
    "$1 is approved: the header cannot be changed; for a new version put the header back to pending approval"
  voce kIlProfiloEApprovatoLe, "il profilo $1 è approvato: le sue righe non si cambiano (serve una VERSION nuova)",
    "the profile $1 is approved: its lines cannot be changed (a new VERSION is needed)"
  voce kERatificataLeDichiarazioniDopo, "$1 è approvata: le dichiarazioni dopo l'intestazione non si cambiano, si possono solo aggiungere righe da approvare",
    "$1 is approved: the declarations after the header cannot be changed, only lines pending approval can be added"
  voce kNonRiescoACreare, "non riesco a creare $1: $2", "I cannot create $1: $2"

  # 095:8:1 bcdd save: uso e standard input
  voce kUsoSave,
    "uso: bcdd save FILE --expect IMPRONTA|nuovo   (il testo nuovo intero sullo standard input)\n" &
      "     bcdd save FILE --undo --expect IMPRONTA   (rimette il testo di FILE.prima, nessun testo sullo standard input)\n" &
      "     bcdd save FILE --remove --expect IMPRONTA   (toglie FILE se non ha righe approvate; lascia FILE.prima; nessun testo sullo standard input)\n" &
      "     bcdd save FILE --undo --expect nuovo   (dopo un --remove: rimette il file tolto, se FILE non esiste)\n",
    "usage: bcdd save FILE --expect FINGERPRINT|nuovo   (the whole new text on standard input)\n" &
      "       bcdd save FILE --undo --expect FINGERPRINT   (puts back the text of FILE.prima, no text on standard input)\n" &
      "       bcdd save FILE --remove --expect FINGERPRINT   (removes FILE if it has no approved lines; leaves FILE.prima; no text on standard input)\n" &
      "       bcdd save FILE --undo --expect nuovo   (after a --remove: puts back the removed file, if FILE does not exist)\n"
  voce kSaveNonLeggoStdin, "bcdd save: non riesco a leggere lo standard input",
    "bcdd save: I cannot read standard input"
  voce kSaveNonUtf8, "bcdd save: il testo ricevuto non è UTF-8 valido",
    "bcdd save: the text received is not valid UTF-8"

  # 095:8:1 ratify (bcddratify)
  voce kUsoBcddRatifyFILECsc, "uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero",
    "usage: bcdd ratify FILE [--csc NAME] [--dir FOLDER]... [ID | --all] D-number"
  voce kNessunBloccoDaRatificareCon, "$1: nessun blocco da approvare con il nome $2 nel file",
    "$1: no block to approve with the name $2 in the file"
  voce kIlFileContieneCSCIndica, "$1: il file contiene $2 CSC: indica quale con --csc NOME",
    "$1: the file contains $2 CSCs: say which with --csc NAME"
  voce kIlFileContieneENTITYIndica, "$1: il file contiene $2 ENTITY: indica quale con --csc NOME",
    "$1: the file contains $2 ENTITYs: say which with --csc NAME"
  voce kIlFileContieneBlocchiDa, "$1: il file contiene $2 blocchi da approvare: indica quale con --csc NOME",
    "$1: the file contains $2 blocks to approve: say which with --csc NAME"
  voce kIlFileNonContieneNessun, "$1: il file non contiene nessun blocco da approvare: una VERIFICATION non si approva",
    "$1: the file contains no block to approve: a VERIFICATION is not approved"
  voce kIlFileNonContieneNessuna2, "$1: il file non contiene nessuna CSC né ENTITY da approvare",
    "$1: the file contains no CSC or ENTITY to approve"
  voce kNessunaCSCNeENTITYNel, "$1: nessuna CSC né ENTITY $2 nel file",
    "$1: no CSC or ENTITY $2 in the file"
  voce kNessunaCSCNeENTITYNel2, "$1: nessuna CSC né ENTITY nel file", "$1: no CSC or ENTITY in the file"
  voce kENTITYRiga, "$1: ENTITY $2, riga $3: $4", "$1: ENTITY $2, line $3: $4"
  voce kNonRatificoLeSueGaranzie, ": non approvo le sue promesse", ": I am not approving its guarantees"
  voce kNonTrovata, "$1 non trovata$2$3", "$1 not found$2$3"
  voce kTrovataConVERSION, "$1 trovata $2 con VERSION $3$4", "$1 found $2 with VERSION $3$4"
  voce kErroreInternoIlTestoModificato, "$1: errore interno: il testo modificato non passa check; file non toccato",
    "$1: internal error: the modified text does not pass check; file not touched"
  voce kRiga2, "  riga $1: $2 $3", "  line $1: $2 $3"
  voce kRiga3, "  riga $1: $2\n", "  line $1: $2\n"
  voce kContratto, "contratto: $1\n", "contract: $1\n"
  voce kIpotesiCheRestano, "righe ancora da approvare: $1\n", "lines still pending approval: $1\n"
  voce kIlVERSIONEGiaRatificato, "$1: il $2 $3 VERSION $4 è già approvato ($5): non cambio nulla",
    "$1: the $2 $3 VERSION $4 is already approved ($5): I am changing nothing"
  voce kRatificatoIlPROFILEVERSIONRiga, "approvato il PROFILE $1 VERSION $2 (riga $3) con $4\n",
    "approved PROFILE $1 VERSION $2 (line $3) with $4\n"
  voce kEstensioni, "estensioni: $1\n", "extensions: $1\n"
  voce kRigaBIND, "  riga $1: BIND $2", "  line $1: BIND $2"
  voce kRatificatoIlRigaCon, "approvato il $1 (riga $2) con $3\n", "approved $1 (line $2) with $3\n"
  voce kDecisioneNonValidaServeD, "$1: decisione non valida: $2 (serve D-numero)",
    "$1: invalid decision: $2 (D-number is needed)"
  voce kIdNonValido, "$1: id non valido: $2", "$1: invalid id: $2"
  voce kNomeNonValido, "$1: nome non valido: $2", "$1: invalid name: $2"
  voce kIlFileNonPassaBcdd, "$1: il file non passa bcdd check --strict (errori: $2, righe non riconosciute: $3): non approvo",
    "$1: the file does not pass bcdd check --strict (errors: $2, unrecognised lines: $3): I am not approving"
  voce kLIntestazioneDellaNonSi, "$1: l'intestazione della $2 non si approva: indica una GUARANTEE oppure --all",
    "$1: the header of the $2 is not approved: say a GUARANTEE or --all"
  voce kLaNonHaGaranzieAncora, "$1: la $2 non ha promesse ancora da approvare: non cambio nulla",
    "$1: the $2 has no guarantees still pending approval: I am changing nothing"
  voce kNessunaGUARANTEEConIdNella, "$1: nessuna GUARANTEE con id $2 nella $3",
    "$1: no GUARANTEE with id $2 in the $3"
  voce kNonEUnaGUARANTEEIn, "$1: $2 non è una GUARANTEE: in una ENTITY si approvano solo promesse",
    "$1: $2 is not a GUARANTEE: in an ENTITY only guarantees are approved"
  voce kEGiaContrattoRigaNon, "$1: $2 è già contratto (riga $3): non cambio nulla",
    "$1: $2 is already part of the contract (line $3): I am changing nothing"
  voce kLaCSCEGiaRatificata, "$1: la CSC $2 è già approvata ($3): non cambio nulla",
    "$1: the CSC $2 is already approved ($3): I am changing nothing"
  voce kNessunaGUARANTEENeASSUMECon, "$1: nessuna GUARANTEE né ASSUME con id $2 nella CSC $3",
    "$1: no GUARANTEE or ASSUME with id $2 in the CSC $3"
  voce kNonEUnaGUARANTEENe, "$1: $2 non è una GUARANTEE né una ASSUME: si approvano solo righe contrattuali e dettagli",
    "$1: $2 is neither a GUARANTEE nor an ASSUME: only contractual lines and details are approved"
  voce kRatificataLaCSCRigaCon, "approvata la CSC $1 (riga $2) con $3\n",
    "approved CSC $1 (line $2) with $3\n"
  voce kRatificataLaRigaCon, "approvata la riga $1: $2 $3 con $4\n", "approved line $1: $2 $3 with $4\n"

  # 095:8:1 ratify: composizioni a mano (bcddratify)
  voce kRatInQuestoFile, "in questo file", "in this file"
  voce kRatDoveRiga, "$1 alla riga $2", "$1 at line $2"
  voce kRatTrovataCheHa, "$1 trovata $2, che ha $3$4", "$1 found $2, which has $3$4"
  voce kRatEntitySenzaIpotesi, "$1: la ENTITY $2 non ha promesse ancora da approvare: non cambio nulla",
    "$1: ENTITY $2 has no guarantees still pending approval: I am changing nothing"
  voce kRatCscTuttaContratto, "$1: la CSC $2 è già tutta contratto: non cambio nulla",
    "$1: CSC $2 is already entirely part of the contract: I am changing nothing"
  voce kRatApprovateEntity, "approvate con $1 nella ENTITY $2: $3", "approved with $1 in ENTITY $2: $3"
  voce kRatApprovateCsc, "approvate con $1 nella CSC $2: $3", "approved with $1 in CSC $2: $3"
  voce kRatApprovateNel, "approvate con $1 nel $2: $3", "approved with $1 in $2: $3"
  voce kNRiga, "$1 riga", "$1 line"
  voce kNRighe, "$1 righe", "$1 lines"

  # 095:8:1 refine (bcddrefine)
  voce kUsoBcddRefineFILECsc, "uso: bcdd refine FILE [--csc NOME] [--modello veloce|accurato]",
    "usage: bcdd refine FILE [--csc NAME] [--modello veloce|accurato]"
  voce kNonEUTF8Valido, "non è UTF-8 valido", "is not valid UTF-8"
  voce kNonEUnOggettoJSON, "non è un oggetto JSON", "is not a JSON object"
  voce kChiaveRipetuta, "chiave ripetuta: $1", "repeated key: $1"
  voce kChiaveSconosciuta, "chiave sconosciuta: $1", "unknown key: $1"
  voce kMancaLaChiave, "manca la chiave: $1", "missing key: $1"
  voce kFormatoDiversoDa, "formato diverso da $1", "format different from $1"
  voce kTipoSbagliatoPerDomande, "tipo sbagliato per domande", "wrong type for domande"
  voce kTipoSbagliatoPerDomande2, "tipo sbagliato per domande[$1]", "wrong type for domande[$1]"
  voce kTroppeDomandeAlPiu5, "troppe domande: $1, al più 5", "too many questions: $1, at most 5"
  voce kTipoSbagliatoPer, "tipo sbagliato per $1", "wrong type for $1"
  voce kTipoSbagliatoPerScelte, "tipo sbagliato per $1.scelte[$2]", "wrong type for $1.scelte[$2]"
  voce kPocheScelteInAlmeno2, "poche scelte in $1: $2, almeno 2", "too few choices in $1: $2, at least 2"
  voce kTroppeScelteInAlPiu, "troppe scelte in $1: $2, al più 5", "too many choices in $1: $2, at most 5"
  voce kSceltaVuotaScelte, "scelta vuota: $1.scelte[$2]", "empty choice: $1.scelte[$2]"
  voce kSceltaSuPiuRigheScelte, "scelta su più righe: $1.scelte[$2]",
    "choice on more than one line: $1.scelte[$2]"
  voce kSceltaRipetutaScelte, "scelta ripetuta: $1.scelte[$2]", "repeated choice: $1.scelte[$2]"
  voce kTipoSbagliatoPerProposte, "tipo sbagliato per proposte", "wrong type for proposte"
  voce kTipoSbagliatoPerProposte2, "tipo sbagliato per proposte[$1]", "wrong type for proposte[$1]"
  voce kTroppeProposteAlPiu10, "troppe proposte: $1, al più 10", "too many proposals: $1, at most 10"
  voce kTipoSbagliatoPerNuoveCsc, "tipo sbagliato per nuove_csc", "wrong type for nuove_csc"
  voce kTipoSbagliatoPerNuoveCsc2, "tipo sbagliato per nuove_csc[$1]", "wrong type for nuove_csc[$1]"
  voce kTroppeCSCAParteAl, "troppe CSC a parte: $1, al più 3", "too many separate CSCs: $1, at most 3"
  voce kNomeNonValido2, "nome non valido: $1", "invalid name: $1"
  voce kMotivoVuoto, "motivo vuoto: $1", "empty reason: $1"
  voce kMotivoSuPiuRighe, "motivo su più righe: $1", "reason on more than one line: $1"
  voce kMotivoTroppoLungoInCaratteri, "motivo troppo lungo in $1: $2 caratteri, al più 300",
    "reason too long in $1: $2 characters, at most 300"
  voce kNomeRipetuto, "nome ripetuto: $1", "repeated name: $1"
  voce kTipoSbagliatoPerSostituzioni, "tipo sbagliato per sostituzioni", "wrong type for sostituzioni"
  voce kTipoSbagliatoPerSostituzioni2, "tipo sbagliato per sostituzioni[$1]", "wrong type for sostituzioni[$1]"
  voce kTroppeSostituzioniAlPiu10, "troppe sostituzioni: $1, al più 10",
    "too many replacements: $1, at most 10"
  voce kTipoSbagliatoPerInterfaccia, "tipo sbagliato per interfaccia", "wrong type for interfaccia"
  voce kTipoSbagliatoPerInterfaccia2, "tipo sbagliato per interfaccia[$1]", "wrong type for interfaccia[$1]"
  voce kTroppeRigheDInterfacciaAl, "troppe righe d'interfaccia: $1, al più 10",
    "too many interface lines: $1, at most 10"
  voce kCarattereDiControlloInTesto, "carattere di controllo in $1.testo", "control character in $1.testo"
  voce kCarattereDiControlloInScelte, "carattere di controllo in $1.scelte[$2]",
    "control character in $1.scelte[$2]"
  voce kCarattereDiControlloIn, "carattere di controllo in $1", "control character in $1"
  voce kRegistroDelleChiamateNonScritto, "$1: registro delle chiamate non scritto: $2\n",
    "$1: call log not written: $2\n"
  voce kMessaggioDellLLM, "\n  messaggio dell'LLM: $1", "\n  message from the language model: $1"
  voce kSostituzioniAccettateENonScritte, "sostituzioni accettate e non scritte, da copiare a mano se servono:",
    "replacements accepted but not written, to be copied by hand if needed:"
  voce kAlPostoDiRiga, "  al posto di $1 (riga $2):", "  in place of $1 (line $2):"
  voce kRigheDInterfacciaAccettateE, "righe d'interfaccia accettate e non scritte, da copiare a mano se servono:",
    "interface lines accepted but not written, to be copied by hand if needed:"
  voce kProposteAccettateENonScritte, "proposte accettate e non scritte, da copiare a mano se servono:",
    "proposals accepted but not written, to be copied by hand if needed:"
  voce kRisposteNonSalvate, "risposte non salvate:", "answers not saved:"
  voce kModelloNonValidoVeloceOppure, "$1: modello non valido: $2 (veloce oppure accurato)",
    "$1: invalid model: $2 (veloce or accurato)"
  voce kSecondaChiamata, "$1: seconda chiamata: ", "$1: second call: "
  voce kNessunaPropostaNonCambia, ": nessuna proposta, $1 non cambia", ": no proposals, $1 does not change"
  voce kNienteScrittoIlFileE, ": niente scritto, il file è com'era",
    ": nothing written, the file is unchanged"
  voce kNonRiescoACreareLa, "non riesco a creare la cartella temporanea",
    "I cannot create the temporary folder"
  voce kNonRiescoAdAvviareL, "$1non riesco ad avviare l'LLM ($2): $3$4",
    "$1I cannot start the language model ($2): $3$4"
  voce kClaudeCodeNonTrovato, "$1non trovo Claude Code (il programma `claude`), che bcdd usa per completare i file: installalo, accedi con il tuo account e riprova. Ho cercato in: $2",
    "$1I cannot find Claude Code (the `claude` program), which bcdd uses to complete files: install it, sign in with your account and try again. Searched in: $2"
  voce kLLLMNonHaRisposto, "$1l'LLM non ha risposto entro $2 s$3$4",
    "$1the language model did not answer within $2 s$3$4"
  voce kRispostaDellLLMNonLeggibile, "$1risposta dell'LLM non leggibile (risposta oltre 1 MiB)$2",
    "$1the answer from the language model is unreadable (answer over 1 MiB)$2"
  voce kLLLMETerminatoSenza, "$1l'LLM è terminato senza successo (codice $2)$3$4",
    "$1the language model ended unsuccessfully (exit code $2)$3$4"
  voce kLLLMNonHaDato, "$1l'LLM non ha dato nessuna risposta$2",
    "$1the language model gave no answer$2"
  voce kRispostaDellLLMNonLeggibile2, "$1risposta dell'LLM non leggibile ($2)$3",
    "$1the answer from the language model is unreadable ($2)$3"
  voce kRispostaLetta, "risposta letta: ", "answer read: "
  voce kScartateDalControllo, " (scartate dal controllo: $1)", " (discarded by the check: $1)"
  voce kDomandeIgnorate, ", domande ignorate: $1", ", questions ignored: $1"
  voce kRigaDInterfaccia, "riga d'interfaccia", "interface line"
  voce kRigheDInterfaccia, "righe d'interfaccia", "interface lines"
  voce kBcddRefineDomandeDellLLM, "-- bcdd refine: domande dell'LLM e risposte della persona. Si può modificare o cancellare a mano.\n",
    "-- bcdd refine: questions from the language model and answers from the person. It can be edited or deleted by hand.\n"
  voce kIlFileNonPassaBcdd2, "$1: il file non passa bcdd check (errori: $2): correggilo prima di affinare",
    "$1: the file does not pass bcdd check (errors: $2): correct it before refining"
  voce kNonEUTF8Valido2, "$1: $2 non è UTF-8 valido", "$1: $2 is not valid UTF-8"
  voce kNessuna, "(nessuna)", "(none)"
  voce kAllaRiga, "- $1: $2 alla riga $3\n", "- $1: $2 at line $3\n"
  voce kRiga4, "- riga $1: $2: ", "- line $1: $2: "
  voce kNonTrovata2, "$1non trovata$2\n", "$1not found$2\n"
  voce kInQuestoFileAllaRiga, "$1in questo file alla riga $2, VERSION $3\n",
    "$1in this file at line $2, VERSION $3\n"
  voce kInAllaRigaVERSION, "$1in $2 alla riga $3, VERSION $4", "$1in $2 at line $3, VERSION $4"
  voce kTestoQuiSopra, "$1 (testo qui sopra)\n", "$1 (text above)\n"
  voce kScriviPrimaLoScopoDi, "$1: scrivi prima lo scopo di $2: Completa parte da lì (niente scritto)",
    "$1: write the purpose of $2 first: Complete starts from there (nothing written)"
  voce kBCDDATTESALLMNonValida, "$1: BCDD_ATTESA_LLM non valida: $2 (serve un numero intero di secondi da 1 a 3600)",
    "$1: BCDD_ATTESA_LLM not valid: $2 (a whole number of seconds from 1 to 3600 is needed)"
  voce kBCDDORANonValidaServe, "$1: BCDD_ORA non valida: $2 (serve AAAA-MM-GGTHH:MM:SS+HH:MM)",
    "$1: BCDD_ORA not valid: $2 (YYYY-MM-DDTHH:MM:SS+HH:MM is needed)"
  voce kUsoBcddRefineJsonFILE, "uso: bcdd refine --json FILE [--csc NOME] [--modello veloce|accurato] | bcdd refine --json --answers FILE | bcdd refine --json --accept FILE | bcdd refine --json --cancel FILE | bcdd refine --json FILE [--csc NOME] --show",
    "usage: bcdd refine --json FILE [--csc NAME] [--modello veloce|accurato] | bcdd refine --json --answers FILE | bcdd refine --json --accept FILE | bcdd refine --json --cancel FILE | bcdd refine --json FILE [--csc NAME] --show"
  voce kNessunGiroApertoSuManca, "$1: nessun giro aperto su $2 (manca $3.giro)",
    "$1: no round open on $2 ($3.giro is missing)"
  voce kGiroNonEUnGiro, "$1: $2.giro non è un giro di bcdd: lo chiudo con --cancel",
    "$1: $2.giro is not a bcdd round: close it with --cancel"
  voce kNonRiescoALeggereLo, "$1: non riesco a leggere lo standard input",
    "$1: I cannot read standard input"
  voce kLoStandardInputNonE, "$1: lo standard input non è UTF-8 valido",
    "$1: standard input is not valid UTF-8"
  voce kLoStandardInputNonE2, "$1: lo standard input non è un oggetto JSON ($2)",
    "$1: standard input is not a JSON object ($2)"
  voce kChiaveRipetutaNelloStandardInput, "$1: chiave ripetuta nello standard input: $2",
    "$1: repeated key in standard input: $2"
  voce kChiaveSconosciuta2, "$1: chiave sconosciuta: $2", "$1: unknown key: $2"
  voce kMancaRisposteUnaLista, "$1: manca \"risposte\" (una lista)", "$1: \"risposte\" is missing (a list)"
  voce kUnaRispostaNonEUn, "$1: una risposta non è un oggetto", "$1: an answer is not an object"
  voce kChiaveSconosciutaInUnaRisposta, "$1: chiave sconosciuta in una risposta: $2",
    "$1: unknown key in an answer: $2"
  voce kUnaRispostaSenzaNIntero, "$1: una risposta senza \"n\" intero", "$1: an answer without an integer \"n\""
  voce kNessunaDomanda, "$1: nessuna domanda $2", "$1: no question $2"
  voce kDueRisposteAllaDomanda, "$1: due risposte alla domanda $2", "$1: two answers to question $2"
  voce kLaRispostaVuoleTestoOppure, "$1: la risposta $2 vuole \"testo\" oppure \"scelta\", non tutti e due",
    "$1: answer $2 requires either \"testo\" or \"scelta\", not both"
  voce kSceltaNonEUnIntero, "$1: \"scelta\" non è un intero", "$1: \"scelta\" is not an integer"
  voce kLaDomandaNonHaLa, "$1: la domanda $2 non ha la scelta $3", "$1: question $2 has no choice $3"
  voce kTestoNonEUnaStringa, "$1: \"testo\" non è una stringa", "$1: \"testo\" is not a string"
  voce kMancaAccettateUnaLista, "$1: manca \"accettate\" (una lista)", "$1: \"accettate\" is missing (a list)"
  voce kUnElementoDiAccettateNon, "$1: un elemento di \"accettate\" non è una stringa",
    "$1: an element of \"accettate\" is not a string"
  voce kENominataDueVolte, "$1: $2 è nominata due volte", "$1: $2 is named twice"
  voce kNessunaPropostaSostituzioneORiga, "$1: nessuna proposta, sostituzione o riga d'interfaccia $2 (niente scritto, il giro resta aperto)",
    "$1: no proposal, replacement or interface line $2 (nothing written, the round stays open)"
  voce kCEGiaUnGiro, "$1: c'è già un giro aperto su $2 ($3.giro): riprendilo oppure chiudilo con --cancel",
    "$1: a round is already open on $2 ($3.giro): resume it or close it with --cancel"
  voce kIlGiroDiNonAspetta, "$1: il giro di $2 non aspetta risposte (fase $3): accetta con --accept o chiudi con --cancel",
    "$1: the round of $2 is not waiting for answers (phase $3): accept with --accept or close with --cancel"
  voce kIlGiroDiHaLe, "$1: il giro di $2 ha le risposte ma non le proposte (la seconda chiamata non è andata): salvale con --accept o chiudi con --cancel",
    "$1: the round of $2 has the answers but not the proposals (the second call failed): save them with --accept or close with --cancel"
  voce kIlGiroDiESu, "$1: il giro di $2 è su $3, non su $4",
    "$1: the round of $2 is on $3, not on $4"
  voce kIlGiroDiAspettaAncora, "$1: il giro di $2 aspetta ancora le risposte: dalle con --answers o chiudi con --cancel",
    "$1: the round of $2 is still waiting for the answers: give them with --answers or close with --cancel"
  voce kLaSecondaChiamataNonE, "$1: la seconda chiamata non è andata: non ci sono proposte da accettare (niente scritto, il giro resta aperto)",
    "$1: the second call failed: there are no proposals to accept (nothing written, the round stays open)"
  voce kLaRigaDInterfacciaI, "$1: la riga d'interfaccia i$2 è scartata dal controllo ($3): non si accetta (niente scritto, il giro resta aperto)",
    "$1: interface line i$2 was discarded by the check ($3): it cannot be accepted (nothing written, the round stays open)"
  voce kLaPropostaPEScartata, "$1: la proposta p$2 è scartata dal controllo ($3): non si accetta (niente scritto, il giro resta aperto)",
    "$1: proposal p$2 was discarded by the check ($3): it cannot be accepted (nothing written, the round stays open)"
  voce kLaSostituzioneSEScartata, "$1: la sostituzione s$2 è scartata dal controllo ($3): non si accetta (niente scritto, il giro resta aperto)",
    "$1: replacement s$2 was discarded by the check ($3): it cannot be accepted (nothing written, the round stays open)"
  voce kECambiatoDuranteIlComando, "$1: $2 è cambiato durante il comando: risposte non salvate",
    "$1: $2 changed during the command: answers not saved"
  voce kChiedoAllLLMLimiteS, "chiedo all'LLM: $1, limite $2 s ($3)",
    "asking the language model: $1, limit $2 s ($3)"
  voce kNessunErroreRigheNonRiconosciute, "$1$2: nessun errore, righe non riconosciute: $3",
    "$1$2: no errors, unrecognised lines: $3"
  voce kLaEPrecisaAbbastanzaNessuna, "la $1$2 è precisa abbastanza: nessuna domanda e nessuna proposta, $3 non cambia",
    "the $1$2 is precise enough: no questions and no proposals, $3 does not change"
  voce kPerRispondereScriviIlNumero, "per rispondere: scrivi il numero di una scelta, oppure la tua risposta; un numero da solo vale come scelta (per dire 60 secondi scrivi 60 s)",
    "to answer: write the number of a choice, or your own answer; a number on its own counts as a choice (to say 60 seconds write 60 s)"
  voce kRispostaDa1AOppure, "risposta (da 1 a $1, oppure scrivi tu; invio vuoto per saltare): ",
    "answer (1 to $1, or write your own; press Enter alone to skip): "
  voce kNessunaSceltaScriviUnNumero, "nessuna scelta $1: scrivi un numero da 1 a $2, oppure la tua risposta (per dire 60 secondi scrivi 60 s)",
    "no choice $1: write a number from 1 to $2, or your own answer (to say 60 seconds write 60 s)"
  voce kNienteScrittoRisposteNonSalvate, "niente scritto: risposte non salvate", "nothing written: answers not saved"
  voce kSOSTITUZIONEDiSCARTATADalControllo, "SOSTITUZIONE $1 di $2: SCARTATA dal controllo",
    "REPLACEMENT $1 of $2: DISCARDED by the check"
  voce kRagione, "  ragione: $1", "  discarded because: $1"
  voce kTesto, "  testo: $1", "  text: $1"
  voce kVerificaVerificaTesto, "  verifica: $1, verifica_testo: $2",
    "  verification: $1, verification text: $2"
  voce kSOSTITUZIONEDiAlPostoDi, "SOSTITUZIONE $1 di $2, al posto di $3 (riga $4)",
    "REPLACEMENT $1 of $2, in place of $3 (line $4)"
  voce kAdesso, "  adesso:", "  now:"
  voce kDiventa, "  diventa:", "  becomes:"
  voce kRestanoIDettagliDiDa, "  restano i dettagli di $1, da rileggere: $2",
    "  the details of $1 remain, to be re-read: $2"
  voce kAccettiSSiNNo, "accetti? s = sì, n = no, f = fine (scarta le restanti): ",
    "accept? y = yes, n = no, q = quit (discards the rest): "
  voce kRIGADINTERFACCIADiSCARTATA, "RIGA D'INTERFACCIA $1 di $2: SCARTATA dal controllo",
    "INTERFACE LINE $1 of $2: DISCARDED by the check"
  voce kRiga5, "  riga: $1", "  line: $1"
  voce kMotivo, "  motivo: $1", "  reason: $1"
  voce kPROPOSTADiSCARTATADalControllo, "PROPOSTA $1 di $2: SCARTATA dal controllo",
    "PROPOSAL $1 of $2: DISCARDED by the check"
  voce kTipoIdDettaglia, "  tipo: $1, id: $2, dettaglia: $3", "  type: $1, id: $2, details: $3"
  voce kPROPOSTADiPromessaNuova, "PROPOSTA $1 di $2, promessa nuova", "PROPOSAL $1 of $2, new guarantee"
  voce kPROPOSTADiDettagliaRiga, "PROPOSTA $1 di $2, dettaglia $3 (riga $4)",
    "PROPOSAL $1 of $2, details $3 (line $4)"
  voce kSeVuoiScriverlaBcddNew, "  se vuoi scriverla: bcdd new $1", "  if you want to write it: bcdd new $1"
  voce kNienteDaScrivereNonCambia, "niente da scrivere: $1 non cambia", "nothing to write: $1 does not change"
  voce kScrivoSSiNNo, "scrivo $1? s = sì, n = no: ", "write $1? y = yes, n = no: "
  voce kNienteScrittoNonCambia, "niente scritto: $1 non cambia", "nothing written: $1 does not change"

  # 095:8:1 refine: interruzioni
  voce kRefInterrotto, "bcdd refine: interrotto: niente scritto, il file è com'era",
    "bcdd refine: interrupted: nothing written, the file is unchanged"
  voce kRefIngressoFinito, "bcdd refine: ingresso finito prima delle risposte: niente scritto, il file è com'era",
    "bcdd refine: input ended before the answers: nothing written, the file is unchanged"

  # 095:8:1 refine: ragioni di scarto di proposte, sostituzioni e righe d'interfaccia (chiavi stabili in ragione_chiave)
  voce kRgTestoVuoto, "testo vuoto", "empty text"
  voce kRgTestoVirgolette, "testo con virgolette doppie: una stringa BCDD non le può contenere",
    "text with double quotation marks: a BCDD string cannot contain them"
  voce kRgTestoPiuRighe, "testo su più righe", "text on more than one line"
  voce kRgTestoLungo, "testo troppo lungo: $1 caratteri, al più 1000",
    "text too long: $1 characters, at most 1000"
  voce kRgVerificaNonValida, "verifica non valida: $1 (serve JUDGEMENT o INSPECTION)",
    "invalid verification: $1 (JUDGEMENT or INSPECTION is needed)"
  voce kRgVerificaTestoVuoto, "testo della verifica vuoto", "empty verification text"
  voce kRgVerificaTestoVirgolette, "testo della verifica con virgolette doppie: una stringa BCDD non le può contenere",
    "verification text with double quotation marks: a BCDD string cannot contain them"
  voce kRgVerificaTestoPiuRighe, "testo della verifica su più righe",
    "verification text on more than one line"
  voce kRgVerificaTestoLungo, "testo della verifica troppo lungo: $1 caratteri, al più 300",
    "verification text too long: $1 characters, at most 300"
  voce kRgIdNonValido, "id non valido: $1", "invalid id: $1"
  voce kRgSostituisceNonGaranziaEntita, "sostituisce una riga che non è una GUARANTEE della ENTITY $1: $2",
    "replaces a line that is not a GUARANTEE of ENTITY $1: $2"
  voce kRgSostituisceNonGaranziaCsc, "sostituisce una riga che non è una GUARANTEE né una ASSUME della CSC $1: $2",
    "replaces a line that is neither a GUARANTEE nor an ASSUME of CSC $1: $2"
  voce kRgSostituisceContratto, "sostituisce $1, che è contratto (riga $2): una riga approvata non si sostituisce",
    "replaces $1, which is part of the contract (line $2): an approved line is not replaced"
  voce kRgSostituisceNonVerbale, "sostituisce $1, che non è una riga verbale (riga $2): si sostituiscono solo righe verbali",
    "replaces $1, which is not a verbal line (line $2): only verbal lines are replaced"
  voce kRgIdGiaSostituito, "id già sostituito dalla sostituzione $1: $2",
    "id already replaced by replacement $1: $2"
  voce kRgRigaCompostaNonRiconosciuta, "check: la riga composta non è riconosciuta",
    "check: the composed line is not recognised"
  voce kRgRigaUguale, "la riga nuova è uguale a quella di adesso",
    "the new line is the same as the current one"
  voce kRgCheckRifiuta, "check rifiuta la riga: [$1] $2", "check refuses the line: [$1] $2"
  voce kRgRigaVuota, "riga vuota", "empty line"
  voce kRgRigaPiuRighe, "riga su più righe", "line spread over more than one line"
  voce kRgDichiarazioneNonAmmessa, "dichiarazione non ammessa: $1 (serve CAPABILITY, EVENT IN, EVENT OUT, STATE, TYPE o DEFINE)",
    "declaration not admitted: $1 (CAPABILITY, EVENT IN, EVENT OUT, STATE, TYPE or DEFINE is needed)"
  voce kRgRigaNonRiconosciuta, "check: la riga non è riconosciuta", "check: the line is not recognised"
  voce kRgNomeGiaUsatoInterfaccia, "nome già usato dalla riga d'interfaccia $1: $2",
    "name already used by interface line $1: $2"
  voce kRgTipoNonDichiarato, "tipo non dichiarato: $1 (né di base, né dichiarato nella CSC, né con una TYPE prima, in questa risposta)",
    "undeclared type: $1 (neither a base type, nor declared in the CSC, nor by a TYPE before it, in this answer)"
  voce kRgTipoAssumeInEntita, "tipo ASSUME: un'entità non ha ASSUME (serve GUARANTEE)",
    "type ASSUME: an entity has no ASSUME (GUARANTEE is needed)"
  voce kRgTipoNonValidoEntita, "tipo non valido: $1 (serve GUARANTEE)",
    "invalid type: $1 (GUARANTEE is needed)"
  voce kRgTipoNonValido, "tipo non valido: $1 (serve GUARANTEE o ASSUME)",
    "invalid type: $1 (GUARANTEE or ASSUME is needed)"
  voce kRgDettagliaNonGaranziaEntita, "dettaglia una riga che non è una GUARANTEE della ENTITY $1: $2",
    "details a line that is not a GUARANTEE of ENTITY $1: $2"
  voce kRgDettagliaNonGaranziaCsc, "dettaglia una riga che non è una GUARANTEE né una ASSUME della CSC $1: $2",
    "details a line that is neither a GUARANTEE nor an ASSUME of CSC $1: $2"
  voce kRgDettagliaLivello, "dettaglia $1, già al livello $2 sotto la riga base $3: al più due livelli di DETAILS",
    "details $1, already at level $2 below the base line $3: at most two levels of DETAILS"
  voce kRgIdGiaUsatoRiga, "id già usato alla riga $1: $2", "id already used at line $1: $2"
  voce kRgIdGiaUsatoInterfaccia, "id già usato dalla riga d'interfaccia $1: $2",
    "id already used by interface line $1: $2"
  voce kRgIdGiaUsatoProposta, "id già usato dalla proposta $1: $2", "id already used by proposal $1: $2"

  # 095:8:1 refine: terminale, giro, richiesta
  voce kDomandaSing, "domanda", "question"
  voce kDomandaPlur, "domande", "questions"
  voce kPropostaSing, "proposta", "proposal"
  voce kPropostaPlur, "proposte", "proposals"
  voce kSostituzioneSing, "sostituzione", "replacement"
  voce kSostituzionePlur, "sostituzioni", "replacements"
  voce kRispostaSing, "risposta", "answer"
  voce kRispostaPlur, "risposte", "answers"
  voce kRigaSing, "riga", "line"
  voce kRighePlur, "righe", "lines"
  voce kCscAParteTesto, "CSC a parte", "separate CSC"
  voce kEParola, "$1 e $2", "$1 and $2"
  voce kInDove, "$1 in $2", "$1 in $2"
  voce kInDoveE, "$1 in $2 e $3 in $4", "$1 in $2 and $3 in $4"
  voce kScrittoDove, "scritto $1: $2", "written $1: $2"
  voce kScelta, "  scelta $1: $2", "  choice $1: $2"
  voce kDomandaNdiM, "DOMANDA $1 di $2", "QUESTION $1 of $2"
  voce kRigaInterfacciaNdiM, "RIGA D'INTERFACCIA $1 di $2", "INTERFACE LINE $1 of $2"
  voce kCscAParteNdiM, "CSC A PARTE $1 di $2: $3", "SEPARATE CSC $1 of $2: $3"
  voce kId2, "  id: $1", "  id: $1"
  voce kHaiRisposto, "hai risposto a $1: chiedo a $2 proposte che ne tengano conto",
    "you answered $1: I am asking $2 for proposals that take this into account"
  voce kScrivoRisposte, "scrivo $1 in $2? s = sì, n = no: ", "write $1 in $2? y = yes, n = no: "
  voce kRispondiSN, "rispondi s oppure n", "answer y or n"
  voce kRispondiSNF, "rispondi s, n oppure f", "answer y, n or q"
  voce kRiepilogo, "riepilogo: accettate $1$2$3, scartate da te $4, scartate dal controllo $5",
    "summary: accepted $1$2$3, discarded by you $4, discarded by the check $5"
  voce kRiepSostituzioni, " (sostituzioni: $1)", " (replacements: $1)"
  voce kRiepInterfaccia, " (righe d'interfaccia: $1)", " (interface lines: $1)"
  voce kNessuno, "(nessuno)", "(none)"
  voce kDaBcddAttesa, "da BCDD_ATTESA_LLM", "from BCDD_ATTESA_LLM"
  voce kContrattoParola, "contratto", "contract"
  voce kIpotesiParola, "ipotesi", "pending approval"
  voce kRigaConfine, "$1 alla riga $2", "$1 at line $2"
  voce kInizioFile, "----- inizio $1 -----", "----- start of $1 -----"
  voce kFineFile, "----- fine $1 -----", "----- end of $1 -----"
  voce kRigheRichiesta, "- $1: $2 alla riga $3, $4, $5", "- $1: $2 at line $3, $4, $5"

  # 095:8:1 check e ratify: ultimi testi
  voce kPurposeMancanteNel, "PURPOSE mancante nel $1 $2", "PURPOSE missing in $1 $2"
  voce kPurposeMancanteNella, "PURPOSE mancante nella $1 $2", "PURPOSE missing in $1 $2"
  voce kExtRipeteExt, "l'EXTENSION $1 ripete l'EXTENSION $2", "EXTENSION $1 repeats EXTENSION $2"
  voce kUsoTesto, "$1 usa $2: $3", "$1 uses $2: $3"
  voce kRatBindingNonRiga, "nel BINDING si approvano l'intestazione o --all, non una riga",
    "in a BINDING the header or --all is approved, not a line"
  voce kRatProfileNonRiga, "nel PROFILE si approva il profilo intero, non una riga",
    "in a PROFILE the whole profile is approved, not a line"
  # 095:9:9 fine del catalogo

proc modello*(k: Chiave, lg: Lingua): string =
  ## 095:4:1 Il modello di testo della voce nella lingua data, con i segnaposto non ancora sostituiti.
  if lg == lgIt: voci[k].it else: voci[k].en

proc compone*(m: string, a: openArray[string]): string =
  ## 095:4:2 Sostituisce `$1`..`$9` in un solo passaggio: il testo inserito non si rilegge (un nome che contiene `$1` resta com'è).
  result = newStringOfCap(m.len + 32)
  var i = 0
  while i < m.len:
    if m[i] == '$' and i + 1 < m.len:
      let c = m[i + 1]
      if c == '$':
        result.add '$'
        i += 2
        continue
      if c in {'1' .. '9'}:
        let n = ord(c) - ord('1')
        if n < a.len: result.add a[n]
        i += 2
        continue
    result.add m[i]
    inc i

proc testo*(k: Chiave, a: varargs[string, `$`]): string =
  ## 095:4:3 Il testo della voce nella lingua corrente, con gli argomenti ai segnaposto.
  compone(modello(k, lingua), a)

proc segnaposti*(m: string): seq[string] =
  ## 095:4:4 L'insieme ordinato dei segnaposto `$n` di un modello (per la prova di parità dei cataloghi).
  var i = 0
  while i < m.len:
    if m[i] == '$' and i + 1 < m.len:
      if m[i + 1] == '$':
        i += 2
        continue
      if m[i + 1] in {'1' .. '9'}:
        let p = m[i .. i + 1]
        if p notin result: result.add p
        i += 2
        continue
    inc i
  result.sort()
