# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 007:3:1 edgtkfin: il livello di piattaforma di Linux: la finestra GTK3, la vista WebKit2GTK 4.1, il ponte pagina-Nim e i processi
# con GSubprocess. Il codice è quello che prima stava in `edfinestra`, spostato qui senza cambiare comportamento; l'interfaccia
# (`apri`, `valuta`, `lanciaSincrono`, `avviaAsincrono`, `fermaAsincrono`, `asincronoInCorso`, `remoto`) è la stessa di `edwebview2`.
# Le procedure `cdecl` non catturano niente: lo stato sta in variabili globali del modulo.
import std/os
when defined(bcddEditorProva): import std/strutils
import edgtk, edbcdd, edtesti, edtraccia, edfintipi
export edfintipi

var
  remoto*: bool                          ## i pixel viaggiano su una rete (ssh -X): la pagina lo sa dalla classe `remoto` di body
  gest: Gestori
  finestra, vista: pointer
  primaNavigazione = true
  asSub: pointer = nil                   # il processo asincrono in corso (il `bcdd refine --json` che chiama l'LLM)
  asInb: pointer = nil
  asFine: FineProcesso = nil

# 007:3:2 I lanci: g_subprocess_newv con gli argomenti uno per uno, senza shell
proc lanciaSincrono*(argv: seq[string], input = ""): (string, string, int) =
  ## Lancia e aspetta: (standard output, standard error, codice). Se non parte: ("", messaggio, 255).
  var av = allocCStringArray(argv)
  var err: ptr GError
  let sub = g_subprocess_newv(av, G_SUBPROCESS_FLAGS_STDIN_PIPE or G_SUBPROCESS_FLAGS_STDOUT_PIPE or G_SUBPROCESS_FLAGS_STDERR_PIPE,
    addr err)
  deallocCStringArray(av)
  if sub == nil:
    var m = tx(kImpossibileLanciare, argv[0])
    if err != nil:
      m = $err.message
      g_error_free(err)
    return ("", m, 255)
  var bo, be: pointer
  # con STDIN_PIPE il buffer non può essere NULL: per nessun input ne basta uno vuoto
  let inb = if input.len > 0: g_bytes_new(unsafeAddr input[0], csize_t(input.len)) else: g_bytes_new(nil, 0)
  let ok = g_subprocess_communicate(sub, inb, nil, addr bo, addr be, addr err)
  g_bytes_unref(inb)
  var o, e = ""
  var codice = 255
  if ok != 0:
    var n: csize_t
    if bo != nil:
      let p = g_bytes_get_data(bo, addr n)
      if p != nil and n > 0:
        o = newString(int(n))
        copyMem(addr o[0], p, int(n))
      g_bytes_unref(bo)
    if be != nil:
      let p = g_bytes_get_data(be, addr n)
      if p != nil and n > 0:
        e = newString(int(n))
        copyMem(addr e[0], p, int(n))
      g_bytes_unref(be)
    if g_subprocess_get_if_exited(sub) != 0: codice = int(g_subprocess_get_exit_status(sub))
  else:
    if err != nil:
      e = $err.message
      g_error_free(err)
  g_object_unref(sub)
  (o, e, codice)

proc cbAsincrono(src, res, data: pointer) {.cdecl.} =
  var bo, be: pointer
  var err: ptr GError
  let ok = g_subprocess_communicate_finish(src, res, addr bo, addr be, addr err)
  var o, e = ""
  var codice = 255
  var segnalato = false
  if ok != 0:
    var n: csize_t
    if bo != nil:
      let p = g_bytes_get_data(bo, addr n)
      if p != nil and n > 0:
        o = newString(int(n))
        copyMem(addr o[0], p, int(n))
      g_bytes_unref(bo)
    if be != nil:
      let p = g_bytes_get_data(be, addr n)
      if p != nil and n > 0:
        e = newString(int(n))
        copyMem(addr e[0], p, int(n))
      g_bytes_unref(be)
    if g_subprocess_get_if_exited(src) != 0: codice = int(g_subprocess_get_exit_status(src))
    elif g_subprocess_get_if_signaled(src) != 0: segnalato = true
  elif err != nil:
    e = $err.message
    g_error_free(err)
  if asInb != nil:
    g_bytes_unref(asInb)
    asInb = nil
  g_object_unref(src)
  asSub = nil
  let f = asFine
  asFine = nil
  if f != nil: f(o, e, codice, segnalato)

proc avviaAsincrono*(argv: seq[string], input: string, fine: FineProcesso, errore: var string): bool =
  ## Lancia senza aspettare (il ciclo di GTK resta libero); `fine` è chiamata dal ciclo a processo finito. Se non parte: false e `errore`.
  var av = allocCStringArray(argv)
  var err: ptr GError
  let sub = g_subprocess_newv(av, G_SUBPROCESS_FLAGS_STDIN_PIPE or G_SUBPROCESS_FLAGS_STDOUT_PIPE or G_SUBPROCESS_FLAGS_STDERR_PIPE,
    addr err)
  deallocCStringArray(av)
  if sub == nil:
    errore = tx(kImpossibileLanciare, argv[0])
    if err != nil:
      errore = $err.message
      g_error_free(err)
    return false
  asSub = sub
  asFine = fine
  asInb = if input.len > 0: g_bytes_new(unsafeAddr input[0], csize_t(input.len)) else: g_bytes_new(nil, 0)
  g_subprocess_communicate_async(sub, asInb, nil, cbAsincrono, nil)
  true

proc asincronoInCorso*(): bool = asSub != nil

proc fermaAsincrono*() =
  ## SIGINT al processo asincrono, se c'è: `bcdd` esce con 130 e lascia il giro com'è.
  if asSub != nil: g_subprocess_send_signal(asSub, 2)

# 007:3:3 Nim -> pagina
type Chiamata = object
  cb: RispostaJs
  dato: int

proc cbValuta(src, res, data: pointer) {.cdecl.} =
  let ch = cast[ptr Chiamata](data)
  var err: ptr GError
  let v = webkit_web_view_evaluate_javascript_finish(src, res, addr err)
  var r = ""
  var ha = false
  if v != nil:
    let c = jsc_value_to_string(v)
    if c != nil:
      r = $c
      ha = true
      g_free(c)
    g_object_unref(v)
  var e = ""
  if err != nil:
    e = $err.message
    g_error_free(err)
  let cb = ch.cb
  let dato = ch.dato
  dealloc(ch)
  if cb != nil: cb(r, ha, e, dato)

proc valuta*(js: string, espr: string, cb: RispostaJs, dato = 0) =
  ## Esegue `js` nella pagina e poi valuta l'espressione `espr` (può essere vuota); `cb` riceve il valore di `espr` in testo.
  let tutto = if espr.len > 0: js & " " & espr & ";" else: js
  let ch = cast[ptr Chiamata](alloc0(sizeof(Chiamata)))
  ch.cb = cb
  ch.dato = dato
  webkit_web_view_evaluate_javascript(vista, cstring(tutto), tutto.len, nil, nil, nil, cbValuta, ch)

# 007:3:4 Pagina -> Nim e gli eventi della finestra
proc cbMessaggio(mgr, valore, data: pointer) {.cdecl.} =
  # in WebKit2GTK 4.1 il valore del segnale è sempre un WebKitJavascriptResult: nessun controllo di tipo a runtime
  let c = jsc_value_to_json(webkit_javascript_result_get_js_value(valore), 0)
  if c == nil: return
  let testo = $c
  g_free(c)
  if gest.messaggio != nil: gest.messaggio(testo)

proc cbAttiva(obj, pspec, data: pointer) {.cdecl.} =
  if gest.attiva != nil: gest.attiva(gtk_window_is_active(finestra) != 0)

proc cbCaricata(v: pointer, evento: cint, data: pointer) {.cdecl.} =
  if evento == WEBKIT_LOAD_FINISHED and gest.caricata != nil: gest.caricata()

proc cbPolicy(v, decisione: pointer, tipo: cint, data: pointer): cint {.cdecl.} =
  ## Passa solo la prima navigazione (il caricamento di load_html); tutto il resto si ignora.
  if tipo == WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION and primaNavigazione:
    primaNavigazione = false
    webkit_policy_decision_use(decisione)
  else:
    webkit_policy_decision_ignore(decisione)
  result = 1

proc cbMenu(v, menu, evento, hit, data: pointer): cint {.cdecl.} = 1

proc cbChiusa(obj, data: pointer) {.cdecl.} =
  # una finestra chiusa mentre l'LLM lavora ferma anche bcdd; il giro resta aperto e alla prossima apertura si riprende o si chiude
  if gest.chiusa != nil: gest.chiusa()
  gtk_main_quit()

proc impostazioni(s: pointer, politica: PoliticaGrafica) =
  # 005:5:2 Lo scorrimento animato di WebKit costa un fotogramma intero per passo (62 contro 15 MB per tre tacche via ssh -X)
  webkit_settings_set_enable_smooth_scrolling(s, 0)
  case politica
  of pgSpenta: webkit_settings_set_hardware_acceleration_policy(s, WEBKIT_HW_POLICY_NEVER)
  of pgAccesa: webkit_settings_set_hardware_acceleration_policy(s, WEBKIT_HW_POLICY_ALWAYS)
  of pgPredefinita: discard
  webkit_settings_set_enable_developer_extras(s, 0)
  webkit_settings_set_javascript_can_open_windows_automatically(s, 0)
  webkit_settings_set_enable_html5_local_storage(s, 0)
  webkit_settings_set_enable_html5_database(s, 0)
  webkit_settings_set_enable_page_cache(s, 0)
  webkit_settings_set_allow_file_access_from_file_urls(s, 0)
  webkit_settings_set_allow_universal_access_from_file_urls(s, 0)
  webkit_settings_set_enable_webgl(s, 0)
  webkit_settings_set_enable_webaudio(s, 0)

var gtkIniziato = false

proc iniziaGtk(): bool =
  ## Una sola volta: la finestra di scelta della cartella e la finestra dell'editor condividono l'inizializzazione.
  if gtkIniziato: return true
  # 005:6:1 Tastiera con GTK_IM_MODULE=xim senza server XIM (minthome): si passa al contesto semplice prima di gtk_init
  let im = metodoInput(getEnv("GTK_IM_MODULE"), getEnv("XMODIFIERS"))
  if im.len > 0:
    putEnv("GTK_IM_MODULE", im)
    traccia("input " & im)
  var argc: cint = 0
  if gtk_init_check(addr argc, nil) == 0: return false
  gtkIniziato = true
  true

proc scegliCartella*(titolo, annulla, scegli, iniziale: string): tuple[ok: bool, cartella: string] =
  ## la finestra di scelta della cartella del sistema (GTK, SELECT_FOLDER), che parte da `iniziale` se non è vuota.
  ## ok=false: GTK non apre il display. ok=true e cartella "": annullato.
  when defined(bcddEditorProva):
    # solo la versione di prova: BCDD_EDITOR_PROVA_CARTELLA=<cartella> sceglie senza finestra, `-` annulla
    let finta = getEnv("BCDD_EDITOR_PROVA_CARTELLA")
    if finta.len > 0:
      traccia("scelta finta " & finta)
      return (true, if finta == "-": "" else: finta)
  if not iniziaGtk(): return (false, "")
  traccia("scelta cartella iniziale=" & iniziale)
  let d = gtk_file_chooser_dialog_new(cstring(titolo), nil, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
    cstring(annulla), GTK_RESPONSE_CANCEL, cstring(scegli), GTK_RESPONSE_ACCEPT, nil)
  if iniziale.len > 0: discard gtk_file_chooser_set_current_folder(d, cstring(iniziale))
  var cartella = ""
  if gtk_dialog_run(d) == GTK_RESPONSE_ACCEPT:
    let f = gtk_file_chooser_get_filename(d)
    if f != nil:
      cartella = $f
      g_free(f)
  gtk_widget_destroy(d)
  while gtk_events_pending() != 0: discard gtk_main_iteration()    # la finestra sparisce prima che l'editor ne apra un'altra
  (true, cartella)

proc mostraErrore*(titolo, testo: string) =
  ## su Linux gli errori d'avvio vanno solo sullo standard error (già scritti da chi chiama); su Windows anche in una finestra.
  discard

proc apri*(sc: Scheda, g: Gestori): string =
  ## Apre la finestra e gira finché non è chiusa. Ritorna "" a chiusura normale, altrimenti il codice del messaggio di errore da dire
  ## ("display": GTK non apre il display).
  gest = g
  # La composizione si decide per caso, mai con putEnv: via ssh -X resta accesa (senza, ogni ridisegno lascia vedere
  # lo sfondo di GTK: lampo misurato il 2026-10-19), in locale è spenta (in VM senza GPU, macchina-prova, con la composizione accesa la
  # finestra non si ridimensiona e perde parti). Precedenza e rilevazione: sceltaGrafica in edbcdd.nim.
  let scelta = sceltaGrafica(getEnv("WEBKIT_DISABLE_COMPOSITING_MODE"), getEnv("BCDD_EDITOR_COMPOSITING"), getEnv("DISPLAY"))
  remoto = scelta.remoto
  traccia("grafica remoto=" & $scelta.remoto & " politica=" & $scelta.politica & " (" & scelta.perche & ")")
  if not iniziaGtk(): return "display"
  # Il cursore che lampeggia ridisegna la vista intera a ogni lampo: 54 MB in 4 s via ssh -X con un campo di testo con il fuoco (P2)
  g_object_set(gtk_settings_get_default(), "gtk-cursor-blink", 0.cint, nil)
  finestra = gtk_window_new(GTK_WINDOW_TOPLEVEL)
  gtk_window_set_title(finestra, cstring(sc.titolo))
  when defined(bcddEditorProva):
    # solo la versione di prova: la misura a larghezze diverse (BCDD_EDITOR_PROVA_DIM=1024x700)
    let dimP = sc.dimensioniProva.split('x')
    if dimP.len == 2: gtk_window_set_default_size(finestra, parseInt(dimP[0]).cint, parseInt(dimP[1]).cint)
    else: gtk_window_set_default_size(finestra, 1200, 800)
  else:
    # la finestra si apre massimizzata, nell'area di lavoro (non a schermo intero); senza gestore di finestre, che non
    # può massimizzare, la dimensione di partenza è quella dello schermo meno un margine per i pannelli
    let scr = gdk_screen_get_default()
    let sw = if scr != nil: int(gdk_screen_get_width(scr)) else: 1200
    let sh = if scr != nil: int(gdk_screen_get_height(scr)) else: 800
    gtk_window_set_default_size(finestra, max(640, sw - 8).cint, max(480, sh - 48).cint)
    gtk_window_maximize(finestra)
  let ctx = webkit_web_context_new_ephemeral()
  vista = webkit_web_view_new_with_context(ctx)
  impostazioni(webkit_web_view_get_settings(vista), scelta.politica)
  # Lo sfondo della vista prima che la pagina sia disegnata: il tema di partenza è «notte» (--bg #0D1117); senza,
  # all'apertura la finestra resta bianca per un istante (misurato via ssh -X su Xvfb).
  var sfondo = GdkRGBA(red: 13.0 / 255, green: 17.0 / 255, blue: 23.0 / 255, alpha: 1.0)
  webkit_web_view_set_background_color(vista, addr sfondo)
  gtk_widget_override_background_color(finestra, 0, addr sfondo)
  let ucm = webkit_web_view_get_user_content_manager(vista)
  discard g_signal_connect_data(ucm, "script-message-received::nimBridge", cast[GCallback](cbMessaggio), nil, nil, 0)
  discard webkit_user_content_manager_register_script_message_handler(ucm, "nimBridge")
  for s in sc.script:
    webkit_user_content_manager_add_script(ucm, webkit_user_script_new(cstring(s),
      WEBKIT_USER_CONTENT_INJECT_TOP_FRAME, WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_END, nil, nil))
  discard g_signal_connect_data(vista, "decide-policy", cast[GCallback](cbPolicy), nil, nil, 0)
  discard g_signal_connect_data(vista, "context-menu", cast[GCallback](cbMenu), nil, nil, 0)
  discard g_signal_connect_data(vista, "load-changed", cast[GCallback](cbCaricata), nil, nil, 0)
  gtk_container_add(finestra, vista)
  discard g_signal_connect_data(finestra, "notify::is-active", cast[GCallback](cbAttiva), nil, nil, 0)
  discard g_signal_connect_data(finestra, "destroy", cast[GCallback](cbChiusa), nil, nil, 0)
  gtk_widget_show_all(finestra)
  webkit_web_view_load_html(vista, cstring(sc.html), nil)
  gtk_main()
  ""
