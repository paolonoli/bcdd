# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 001:1:1 edbcdd: gli argomenti dell'editor e la lettura di `bcdd check --json`. Puro: nessun GTK.
import std/[json, strutils, tables, os]
import edtesti

const
  formaAttesa* = "bcdd-check"
  versioneAttesa* = 5
  statiDiNoti* = ["suo", "dettaglio", "intestazione", "intestazione_non_valida", "profilo"]
  tipiBloccoNoti* = ["CSC", "ENTITY", "BINDING", "VERIFICATION", "PROFILE"]

proc usoEditor*(): string = tx(kUsoEditor)

type
  Argomenti* = object
    ok*: bool
    lingua*: string         # "it" | "en" se c'è `--lang` valido come primo argomento, altrimenti ""
    linguaErrata*: bool     # `--lang` con un valore che non è it né en (anche vuoto)
    erroreLingua*: string   # quel valore
    dir*: string
    nome*: string           # l'entità da aprire; vuoto = il banco mostra le entità della cartella

  Lettura* = object
    ## Esito della lettura di un'uscita di `bcdd check --json`.
    ok*: bool               # l'uscita si può leggere
    json*: JsonNode
    codice*: int            # il codice d'uscita di bcdd
    forma*, versione*: string
    messaggio*: string      # se non ok

proc nomeValido*(s: string): bool =
  ## 001:2:4 Un nome di entità o di CSC come lo scrive l'editor: lettera, poi lettere, cifre, trattino basso (L7 senza il trattino).
  if s.len == 0 or s.len > 64 or not (s[0] in {'A'..'Z', 'a'..'z'}): return false
  for c in s:
    if c notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}: return false
  true

proc leggiArgomenti*(args: seq[string]): Argomenti =
  ## 001:2:1 `[--lang it|en] --dir CARTELLA [NOME]`; --lang solo come primi due argomenti (come per `bcdd`);
  ## --dir una volta sola e con la cartella dopo; NOME al più uno.
  var i = 0
  if args.len > 0 and args[0] == "--lang":
    if args.len < 2 or args[1] notin ["it", "en"]:
      if args.len >= 2:
        result.linguaErrata = true
        result.erroreLingua = args[1]
      return
    result.lingua = args[1]
    i = 2
  var haDir, haNome = false
  while i < args.len:
    let a = args[i]
    if a == "--dir":
      if haDir or i + 1 >= args.len: return
      haDir = true
      result.dir = args[i + 1]
      i += 2
    elif a.startsWith("-"):
      return
    else:
      if haNome or not nomeValido(a): return
      haNome = true
      result.nome = a
      inc i
  if not haDir or result.dir.len == 0: return
  result.ok = true

proc argomentiCheck*(file: string): seq[string] =
  ## 001:2:2 Gli argomenti di `check` per un file della cartella di lavoro (l'editor ci entra con chdir): check --json --dir . FILE.
  @["check", "--json", "--dir", ".", file]

proc messaggioVersione*(bcdd, forma, versione, file: string): string =
  tx(kVersioneNonLetta, formaAttesa, versioneAttesa, bcdd, forma, versione, file)

proc sceltaLingua*(arg, ricordata, ambiente: string): Lingua =
  ## 001:5:1 Precedenza: `--lang` > scelta ricordata > BCDD_LANG > inglese. Un valore che non è `it` o `en` vale come assente.
  for v in [arg, ricordata, ambiente]:
    if v == "it": return lgIt
    if v == "en": return lgEn
  lgEn

proc cartellaConfigurazione*(): string =
  ## 001:5:2 La cartella di configurazione dell'utente: `$XDG_CONFIG_HOME` o `~/.config` (su Windows, `%APPDATA%`, nel giro Windows). Un solo posto.
  when defined(windows):
    getEnv("APPDATA")
  else:
    let x = getEnv("XDG_CONFIG_HOME")
    if x.len > 0: x else: getEnv("HOME") / ".config"

proc fileLingua*(): string = cartellaConfigurazione() / "bcdd-editor" / "lingua"

proc leggiLinguaRicordata*(): string =
  ## 001:5:3 `it` o `en` dal file; assente, illeggibile o con altro contenuto: "" (come assente).
  try:
    let s = readFile(fileLingua()).strip
    if s in ["it", "en"]: s else: ""
  except CatchableError:
    ""

proc ricordaLingua*(l: Lingua): bool =
  ## 001:5:4 Scrive `it` o `en` + LF con un file temporaneo e la sostituzione; false se non ci riesce (la scelta vale per la finestra aperta).
  try:
    let f = fileLingua()
    createDir(parentDir(f))
    let tmp = f & ".tmp"
    writeFile(tmp, $l & "\n")
    moveFile(tmp, f)
    true
  except CatchableError:
    false

proc leggiUscita*(bcdd, file, output: string, codice: int): Lettura =
  ## 001:2:3 Controlla forma, versione e i valori di `stato_di`. Con codice 0 o 1 l'uscita è un oggetto JSON.
  result.codice = codice
  var j: JsonNode
  try:
    j = parseJson(output)
  except CatchableError:
    j = nil
  if j == nil or j.kind != JObject:
    result.forma = "?"
    result.versione = "?"
    result.messaggio = messaggioVersione(bcdd, "?", "?", file)
    return
  result.forma = if j.hasKey("forma") and j["forma"].kind == JString: j["forma"].getStr else: "?"
  result.versione = if j.hasKey("versione"): $j["versione"] else: "?"
  var ok = result.forma == formaAttesa and j.hasKey("versione") and j["versione"].kind == JInt and
    j["versione"].getInt == versioneAttesa
  if ok and not j.hasKey("lingua"):
    # 001:2:6 un `bcdd` che non dice la lingua è un `bcdd` precedente al bilinguismo
    result.messaggio = tx(kVersioneSenzaLingua, formaAttesa, versioneAttesa, bcdd, file)
    return
  if ok:
    for k in ["blocchi", "rapporto", "file", "impronta", "righe", "lingua"]:
      if not j.hasKey(k): ok = false
  if ok and (j["blocchi"].kind != JArray or j["rapporto"].kind != JObject or j["righe"].kind != JArray):
    ok = false
  if ok:
    for b in j["blocchi"]:
      if b.kind != JObject: ok = false; break
      # 001:2:5 A-4: un tipo di blocco che l'editor non conosce non ferma la finestra; per i tipi noti la forma
      # si controlla, e uno `stato_di` mai visto non è un rifiuto: la riga resta una riga «non nostra» (non si approva da sola).
      if b.hasKey("tipo") and b["tipo"].getStr notin tipiBloccoNoti: continue
      if not b.hasKey("garanzie") or b["garanzie"].kind != JArray or not b.hasKey("citazioni") or b["citazioni"].kind != JArray:
        ok = false
        break
      for g in b["garanzie"]:
        if g.kind != JObject or not g.hasKey("stato_di") or g["stato_di"].kind != JString: ok = false
  if not ok:
    result.messaggio = messaggioVersione(bcdd, result.forma, result.versione, file)
    return
  result.ok = true
  result.json = j

type
  PoliticaGrafica* = enum
    pgPredefinita    ## non si tocca niente: decide WebKit (o la variabile d'ambiente WEBKIT_DISABLE_COMPOSITING_MODE, se c'è)
    pgAccesa         ## composizione accesa, forzata
    pgSpenta         ## composizione spenta (WEBKIT_HW_POLICY_NEVER)

  ScelteGrafiche* = object
    politica*: PoliticaGrafica
    remoto*: bool    ## i pixel viaggiano su una rete (DISPLAY nella forma host:N)
    perche*: string  ## la regola che ha deciso, per la traccia

proc displayRemoto*(display: string): bool =
  ## 001:3:1 `ssh -X` e `-Y` danno sempre `host:N` (di solito `localhost:10.0`); un display locale è `:N` o `unix:N`.
  ## Vuoto (nessun display, Wayland puro) è locale. Non si guarda SSH_CONNECTION: una variabile ereditata e vecchia (tmux) o
  ## un `DISPLAY=:0` lanciato dopo `ssh host` darebbero un falso positivo (RAPPORTO P1).
  display.len > 0 and display[0] != ':' and not display.startsWith("unix:")

proc metodoInput*(gtkImModule, xmodifiers: string): string =
  ## 001:4:1 Metodo di input da impostare prima di gtk_init, o "" se non si tocca niente. Con GTK_IM_MODULE=xim e nessun server XIM
  ## (XMODIFIERS vuota, assente o @im=none) la finestra non riceve la tastiera: misurato su minthome (Mint 21.3 in VMware, WebKitGTK 2.50.4).
  if gtkImModule == "xim" and xmodifiers.strip in ["", "@im=none"]: "gtk-im-context-simple" else: ""

proc sceltaGrafica*(webkitDisable, edCompositing, display: string): ScelteGrafiche =
  ## 001:3:2 Precedenza: (1) WEBKIT_DISABLE_COMPOSITING_MODE già nell'ambiente: non si tocca niente;
  ## (2) BCDD_EDITOR_COMPOSITING=on|off: vince sulla rilevazione; (3) auto (o vuota, o un valore sconosciuto): remoto = acceso
  ## (il lampo di ogni ridisegno senza composizione si vede solo via rete), locale = spento (in VM senza GPU la finestra
  ## altrimenti non si ridimensiona e perde parti: misurato dall'operatore). `remoto` vale in ogni caso.
  result.remoto = displayRemoto(display)
  if webkitDisable.len > 0:
    result.politica = pgPredefinita
    result.perche = "variabile WEBKIT_DISABLE_COMPOSITING_MODE"
    return
  case edCompositing.toLowerAscii
  of "on":
    result.politica = pgAccesa
    result.perche = "BCDD_EDITOR_COMPOSITING=on"
  of "off":
    result.politica = pgSpenta
    result.perche = "BCDD_EDITOR_COMPOSITING=off"
  else:
    if result.remoto:
      result.politica = pgPredefinita
      result.perche = "auto, display remoto"
    else:
      result.politica = pgSpenta
      result.perche = "auto, display locale"

type
  MemoCheck* = object
    ## 001:3:3 I `check --json` già letti, validi finché la cartella intera ha la stessa impronta.
    digest*: string
    voci*: Table[string, JsonNode]

proc daMemoria*(m: var MemoCheck, digest, file: string): JsonNode =
  ## Il check di `file` se la cartella è identica a quando è stato letto; nil altrimenti. Con un'impronta diversa si butta tutto:
  ## la memoria non serve mai un risultato più vecchio della cartella.
  if digest != m.digest:
    m.voci.clear()
    m.digest = digest
  m.voci.getOrDefault(file, nil)

proc ricorda*(m: var MemoCheck, digestPrima, digestDopo, file: string, j: JsonNode) =
  ## Si ricorda solo se la cartella non è cambiata mentre `bcdd` lavorava (digestPrima == digestDopo).
  if digestPrima == digestDopo and digestPrima == m.digest: m.voci[file] = j
