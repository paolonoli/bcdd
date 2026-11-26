# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 010:2:1 edwebview2: il livello di piattaforma di Windows: la finestra e la vista WebView2 (attraverso la libreria `webview`, MIT, e il
# piccolo `windows/edwv2.cc`), il ponte pagina-Nim e i processi con CreateProcessW (`edprocwin`). Stessa interfaccia di `edgtkfin`
# (`apri`, `valuta`, `lanciaSincrono`, `avviaAsincrono`, `fermaAsincrono`, `asincronoInCorso`, `remoto`). Solo Windows.
# Lo stato sta in variabili globali del modulo; le procedure `cdecl` non catturano niente.
import std/[os, json, strutils, tables, winlean]
import edtesti, edtraccia, edfintipi, edprocwin
export edfintipi

const dirWin = currentSourcePath().parentDir / "windows"

# la libreria `webview` e `edwv2.cc` sono in C++: `editor/windows/costruisci.sh` le compila in `windows/build/libedwv.a` prima di `nim c`
{.passL: dirWin / "build" / "libedwv.a".}
# -lstdc++ è esplicito perché Nim linka con gcc; libstdc++ e libgcc sono statiche: a runtime non servono libstdc++-6.dll né libgcc_s_seh-1.dll
{.passL: "-Wl,-Bstatic -lstdc++ -lgcc_eh -lgcc -lwinpthread -Wl,-Bdynamic -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32 -ladvapi32 -lshell32 -lshlwapi -lversion -luser32 -lkernel32 -ldwmapi".}

type Vista = pointer
type FnBind = proc(id: cstring, req: cstring, arg: pointer) {.cdecl.}
type FnDispatch = proc(w: Vista, arg: pointer) {.cdecl.}
type FnAttiva = proc(attiva: cint) {.cdecl.}

proc webview_create(debug: cint, window: pointer): Vista {.importc, cdecl.}
proc webview_destroy(w: Vista): cint {.importc, cdecl.}
proc webview_get_window(w: Vista): pointer {.importc, cdecl.}
proc webview_run(w: Vista): cint {.importc, cdecl.}
proc webview_terminate(w: Vista): cint {.importc, cdecl.}
proc webview_dispatch(w: Vista, fn: FnDispatch, arg: pointer): cint {.importc, cdecl.}
proc webview_set_title(w: Vista, titolo: cstring): cint {.importc, cdecl.}
proc webview_set_size(w: Vista, l, a, hint: cint): cint {.importc, cdecl.}
proc webview_set_html(w: Vista, html: cstring): cint {.importc, cdecl.}
proc webview_init(w: Vista, js: cstring): cint {.importc, cdecl.}
proc webview_eval(w: Vista, js: cstring): cint {.importc, cdecl.}
proc webview_bind(w: Vista, nome: cstring, fn: FnBind, arg: pointer): cint {.importc, cdecl.}
proc webview_return(w: Vista, id: cstring, stato: cint, risultato: cstring): cint {.importc, cdecl.}
proc bcdd_wv2_configura(w: Vista): cint {.importc, cdecl.}
proc bcdd_wv2_finestra(w: Vista, cb: FnAttiva, massimizza: cint) {.importc, cdecl.}
proc bcdd_wv2_stato(w: Vista, r: ptr cint): cint {.importc, cdecl.}

const
  # l'unica forma in cui la pagina parla con Nim: la stessa chiamata di WebKit (`window.webkit.messageHandlers.nimBridge.postMessage`), che porta
  # un oggetto; qui il ponte della libreria porta solo testo, perciò l'oggetto viaggia come JSON. Il segnale `__nimPronta` dice che il documento è costruito.
  shimJs = """
(function () {
  if (window.webkit) return;
  window.webkit = { messageHandlers: { nimBridge: { postMessage: function (m) { window.__nimPost(JSON.stringify(m)); } } } };
  document.addEventListener('DOMContentLoaded', function () { window.__nimPronta(''); });
})();
"""

var
  remoto*: bool                          ## sempre falso su Windows: la pagina non ha niente da fare in più
  gest: Gestori
  vista: Vista
  sch: Scheda
  paginaPronta = false
  asPid: int32 = 0
  asLancio: Lancio
  asFine: FineProcesso = nil
  rispInCorso: Table[int, (RispostaJs, int)]
  numRisposta = 0

# 010:2:2 I lanci: CreateProcessW con gli argomenti uno per uno, senza shell (edprocwin)
proc lanciaSincrono*(argv: seq[string], input = ""): (string, string, int) =
  ## Lancia e aspetta: (standard output, standard error, codice). Se non parte: ("", messaggio, 255).
  var l = avvia(argv, input)
  if not l.ok:
    return ("", (if l.errore.len > 0: l.errore else: tx(kImpossibileLanciare, argv[0])), 255)
  l.aspetta()
  let e = l.raccogli()
  (e.uscita, e.errori, e.codice)

type Attesa = object
  processo: Handle
  vista: Vista

proc fineSulCiclo(w: Vista, arg: pointer) {.cdecl.} =
  ## Sul ciclo principale: il processo è finito, si raccolgono le uscite e si avvisa la finestra.
  let e = asLancio.raccogli()
  asPid = 0
  let f = asFine
  asFine = nil
  if f != nil: f(e.uscita, e.errori, e.codice, e.segnalato)

proc attendi(a: ptr Attesa) {.thread.} =
  ## Il filo che aspetta la fine del processo asincrono (la finestra resta libera) e poi lo dice al ciclo principale.
  discard waitForSingleObject(a.processo, INFINITE)
  let v = a.vista
  dealloc(a)
  discard webview_dispatch(v, fineSulCiclo, nil)

var filoAttesa: Thread[ptr Attesa]

proc avviaAsincrono*(argv: seq[string], input: string, fine: FineProcesso, errore: var string): bool =
  ## Lancia senza aspettare; `fine` è chiamata dal ciclo principale a processo finito. Se non parte: false e `errore`.
  asLancio = avvia(argv, input)
  if not asLancio.ok:
    errore = if asLancio.errore.len > 0: asLancio.errore else: tx(kImpossibileLanciare, argv[0])
    return false
  asPid = asLancio.pid
  asFine = fine
  let a = cast[ptr Attesa](alloc0(sizeof(Attesa)))
  a.processo = asLancio.handleProcesso
  a.vista = vista
  createThread(filoAttesa, attendi, a)
  true

proc asincronoInCorso*(): bool = asPid != 0

proc fermaAsincrono*() =
  ## Ctrl-C al processo asincrono, se c'è: `bcdd` esce con 130 e lascia il giro com'è.
  if asPid != 0: interrompi(asPid, asLancio.handleProcesso)

# 010:2:3 Nim -> pagina. webview_eval non restituisce niente: la risposta torna dalla pagina attraverso `__nimRisp`.
proc valuta*(js: string, espr: string, cb: RispostaJs, dato = 0) =
  ## Esegue `js` nella pagina e poi valuta l'espressione `espr` (può essere vuota); `cb` riceve il valore di `espr` in testo.
  inc numRisposta
  let n = numRisposta
  rispInCorso[n] = (cb, dato)
  let ris = if espr.len > 0: "window.__nimRisp(" & $n & ",1,String(" & espr & "));" else: "window.__nimRisp(" & $n & ",2,'');"
  let tutto = "try {\n" & js & "\n;" & ris & "\n} catch (e) { window.__nimRisp(" & $n & ",0,String(e && e.message ? e.message : e)); }"
  discard webview_eval(vista, cstring(tutto))

# 010:2:4 Pagina -> Nim e gli eventi della finestra
proc elementi(req: cstring): JsonNode =
  try: result = parseJson($req)
  except CatchableError: result = newJArray()

proc cbPost(id: cstring, req: cstring, arg: pointer) {.cdecl.} =
  let j = elementi(req)
  if j.kind == JArray and j.len == 1 and j[0].kind == JString and gest.messaggio != nil: gest.messaggio(j[0].getStr)
  discard webview_return(vista, id, 0, "null")

proc cbPronta(id: cstring, req: cstring, arg: pointer) {.cdecl.} =
  discard webview_return(vista, id, 0, "null")
  if paginaPronta: return
  paginaPronta = true
  for s in sch.script: discard webview_eval(vista, cstring(s))     # i programmi della pagina: dopo il documento, nell'ambito globale
  if gest.caricata != nil: gest.caricata()

proc cbRisp(id: cstring, req: cstring, arg: pointer) {.cdecl.} =
  discard webview_return(vista, id, 0, "null")
  let j = elementi(req)
  if j.kind != JArray or j.len != 3 or j[0].kind != JInt: return
  let n = int(j[0].getInt)
  if not rispInCorso.hasKey(n): return
  let (cb, dato) = rispInCorso[n]
  rispInCorso.del n
  let tipo = int(j[1].getInt)
  let testo = if j[2].kind == JString: j[2].getStr else: ""
  if cb == nil: return
  case tipo
  of 1: cb(testo, true, "", dato)
  of 2: cb("", false, "", dato)
  else: cb("", false, (if testo.len > 0: testo else: "errore JavaScript"), dato)

proc cbAttiva(attiva: cint) {.cdecl.} =
  traccia("wm_activate " & $attiva)
  if gest.attiva != nil: gest.attiva(attiva != 0)

proc scegliCartelle*(titolo, annulla, scegli, iniziale: string, aggiungi = false): Scelta =
  ## la finestra moderna di Esplora file per scegliere una o più cartelle (anche di rete, anche scritte nella barra dell'indirizzo).
  ## I titoli e i pulsanti sono quelli del catalogo (`annulla` è quello del sistema). `ok` falso: la finestra non si crea. Annullata: nessuna cartella.
  ## Con `FOS_FORCEFILESYSTEM` ogni scelta ha un percorso: `rifiutate` resta vuoto.
  when defined(bcddEditorProva):
    let finta = getEnv(if aggiungi: "BCDD_EDITOR_PROVA_AGGIUNGI" else: "BCDD_EDITOR_PROVA_CARTELLA")   # nomi solo nella versione di prova
    if finta.len > 0:
      traccia("scelta finta " & finta)
      return sceltaDaGancio(finta)
  traccia("scelta cartella iniziale=" & iniziale)
  let padre = if vista != nil: cast[Handle](webview_get_window(vista)) else: Handle(0)
  let (ok, c) = sceltaCartelleWin(titolo, scegli, iniziale, padre)
  Scelta(ok: ok, cartelle: c)

proc mostraErrore*(titolo, testo: string) = messaggioWin(titolo, testo)

proc apri*(sc: Scheda, g: Gestori): string =
  ## Apre la finestra e gira finché non è chiusa. Ritorna "" a chiusura normale, altrimenti il codice del messaggio di errore da dire
  ## ("display": la finestra o WebView2 non si aprono).
  gest = g
  sch = sc
  remoto = false
  traccia("grafica webview2")
  let debug = when defined(bcddEditorProva): getEnv("BCDD_EDITOR_DEVTOOLS").len > 0 else: false
  vista = webview_create(cint(debug), nil)
  if vista == nil: return "display"
  discard webview_set_title(vista, cstring(sc.titolo))
  var l, a = 0
  when defined(bcddEditorProva):
    let dimP = sc.dimensioniProva.split('x')
    if dimP.len == 2: (l, a) = (parseInt(dimP[0]), parseInt(dimP[1]))
  if l == 0: (l, a) = (1200, 800)
  discard webview_set_size(vista, cint(l), cint(a), 0)
  discard webview_bind(vista, "__nimPost", cbPost, nil)
  discard webview_bind(vista, "__nimPronta", cbPronta, nil)
  discard webview_bind(vista, "__nimRisp", cbRisp, nil)
  discard webview_init(vista, cstring(shimJs))
  let rc = bcdd_wv2_configura(vista)
  traccia("configura " & $rc)
  # la finestra si apre massimizzata (nell'area di lavoro); la versione di prova con una dimensione data resta a quella
  bcdd_wv2_finestra(vista, cbAttiva, cint(if sc.dimensioniProva.len == 0: 1 else: 0))
  discard webview_set_html(vista, cstring(sc.html))
  discard webview_run(vista)
  if gest.chiusa != nil: gest.chiusa()
  if asPid != 0: discard waitForSingleObject(asLancio.handleProcesso, 3000)     # la finestra è chiusa mentre l'LLM lavora: bcdd ha ricevuto Ctrl-C, gli si dà il tempo di uscire
  discard webview_destroy(vista)
  ""
