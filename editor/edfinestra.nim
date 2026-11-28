# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 005:1:1 edfinestra: la finestra, la vista web, la pagina, il ponte, le azioni del banco e la regola della rilettura
# . Le azioni scrivono SOLO con `bcdd save` e `bcdd new`, una scrittura per azione; il resto è
# `bcdd check --json`; Approva (pezzo 5) lancia `bcdd ratify`, una volta per riga. Nessun timer e nessun osservatore di file: si rilegge quando la finestra torna attiva.
# I lanci di bcdd sono sincroni (GSubprocess, argomenti uno per uno, senza shell): sono brevi e ogni azione è una sequenza.
import std/[json, os, strutils, times, algorithm, sequtils, tables]
import checksums/sha2
import edfin, edbcdd, edmodello, edazioni, edtesti, edtraccia, edlinea, edrif

const
  paginaHtmlBase = staticRead("pagina/pagina.html").replace("/*STILE*/", staticRead("pagina/pagina.css"))
  paginaJs = staticRead("pagina/testi.js") & "\n" & staticRead("pagina/pagina.js")
  nomeBcdd = (when defined(bcddEditorProva): "bcdd_prova" else: "bcdd") & (when defined(windows): ".exe" else: "")

when defined(bcddEditorProva):
  # 005:1:2 Solo la versione di prova: la traccia, i clic simulati e la sonda di rete.
  const provaJs = """
function bcddProvaStato() {
  return '\n\nstato: ' + document.getElementById('stato-chip').textContent + ' tema=' + document.body.className + ' lingua=' + document.documentElement.getAttribute('lang');
}
function azioniMisura() {
  var a = document.getElementById('azioni');
  var t = {}, w = 0, n = 0;
  Array.prototype.forEach.call(a.children, function (b) { if (b.id === 'menu-altro') return; t[Math.round(b.getBoundingClientRect().top)] = 1; w += b.offsetWidth; n++; });
  var mn = document.getElementById('menu-altro');
  var nm = mn ? mn.children.length : 0;
  return ' azioni_h=' + a.offsetHeight + ' azioni_righe=' + Object.keys(t).length + ' azioni_n=' + n + ' azioni_w=' + w + ' azioni_larg=' + a.clientWidth + ' nel_menu=' + nm;
}
function bcddProvaClic(tok) {
  window.__nim = false;
  if (tok.charAt(0) === '@') {
    var e = document.getElementById(tok.substring(1));
    if (!e) return '0';
    e.click();
    return window.__nim ? '1' : '0';
  }
  if (tok.charAt(0) === '>') {
    // come '@', ma non aspetta la risposta del programma: per cliccare mentre l'LLM lavora
    var g = document.getElementById(tok.substring(1));
    if (!g) return '0';
    g.click();
    return '0';
  }
  if (tok.charAt(0) === '=') {
    var i = tok.indexOf(':');
    var f = document.getElementById(tok.substring(1, i));
    if (!f) return '0';
    f.value = tok.substring(i + 1);
    f.dispatchEvent(new Event('input', {bubbles: true}));
    f.dispatchEvent(new Event('change', {bubbles: true}));
    return '0';
  }
  if (tok.charAt(0) === '?') {
    var q = document.getElementById(tok.substring(1)) || document.querySelector('[data-id="' + tok.substring(1) + '"]');
    if (!q) return 'Q:' + tok.substring(1) + ' assente';
    return 'Q:' + tok.substring(1) + ' ' + (q.hidden ? 'nascosto' : 'visibile') + ' ' + q.textContent;
  }
  if (tok.charAt(0) === '*') {
    // i titoli (tooltip) di tutti gli elementi di un selettore, con il loro testo: `*SELETTORE`
    var ql = document.querySelectorAll(tok.substring(1));
    return 'Q:*' + tok.substring(1) + ' ' + ql.length + ' | ' + Array.prototype.map.call(ql, function (x) { return x.textContent + ' => ' + x.title; }).join(' | ');
  }
  if (tok.charAt(0) === '~') {
    // il titolo (tooltip) di un elemento: perché un comando è spento
    var tq = document.getElementById(tok.substring(1)) || document.querySelector('[data-id="' + tok.substring(1) + '"]');
    if (!tq) return 'Q:' + tok.substring(1) + ' assente';
    return 'Q:' + tok.substring(1) + ' titolo=' + tq.title;
  }
  if (tok.charAt(0) === '!') {
    // lo stato di un bottone o di un campo: acceso/spento, e il valore o la casella
    var d = document.getElementById(tok.substring(1));
    if (!d) return 'Q:' + tok.substring(1) + ' assente';
    var r = 'Q:' + tok.substring(1) + ' ' + (d.disabled ? 'spento' : 'acceso');
    if (d.type === 'text') r += ' valore=' + d.value;
    if (d.type === 'checkbox') r += ' scelto=' + d.checked;
    if (d.tagName === 'TEXTAREA') r += ' valore=' + d.value.replace(/\n/g, '\u00b6');
    return r;
  }
  if (tok.charAt(0) === '%') {
    // la barra in alto: altezza e posizione dei pezzi, e le righe di testo di ognuno
    var hd = document.querySelector('header');
    var rr = 'Q:%barra larghezza=' + window.innerWidth + ' h=' + hd.offsetHeight;
    var ids = ['percorso', 't-fuori', 't-dentro', 'b-tema'];
    var tops = {};
    var nomi = hd.querySelector('.nome-app');
    var els2 = [nomi].concat(ids.map(function (x) { return document.getElementById(x); }));
    var righe = 0;
    els2.forEach(function (e) {
      var rg = document.createRange();
      rg.selectNodeContents(e);
      var seen = {};
      Array.prototype.forEach.call(rg.getClientRects(), function (q) { seen[Math.round(q.top)] = 1; });
      righe = Math.max(righe, Object.keys(seen).length);
      var rc = e.getBoundingClientRect();
      tops[Math.round(rc.top) + ':' + Math.round(rc.bottom)] = 1;
    });
    // «righe» della barra = gruppi di pezzi con altezze che si sovrappongono (con altezze diverse e centrati, i bordi superiori non coincidono)
    var fasce = Object.keys(tops).map(function (k) { var p = k.split(':'); return [parseInt(p[0], 10), parseInt(p[1], 10)]; }).sort(function (a, b) { return a[0] - b[0]; });
    var nfasce = 0, finoA = -1e9;
    fasce.forEach(function (f) { if (f[0] >= finoA) nfasce++; finoA = Math.max(finoA, f[1]); });
    tops = {x: nfasce};
    var sz = Array.prototype.map.call(document.querySelectorAll('.sez-testa'), function (x) { return x.offsetHeight; });
    return rr + ' righe_testo=' + righe + ' tops=' + nfasce + ' sez_testa=' + sz.join(',') + azioniMisura();
  }
  if (tok.charAt(0) === '(') {
    // : il passaggio del mouse su un riferimento interno, `(NOME` o `(NOME#n` (l'n-esimo, da 0); dice la finestrella
    var hv = tok.substring(1).split('#');
    var hl = document.querySelectorAll('#scheda-righe .rif[data-rif="' + hv[0] + '"], #scheda-righe .rife[data-ext="' + hv[0] + '"]');
    var he = hl[hv.length > 1 ? parseInt(hv[1], 10) : 0];
    if (!he) return 'Q:(' + tok.substring(1) + ' assente';
    var hb = he.getBoundingClientRect();
    he.dispatchEvent(new MouseEvent('mouseover', {bubbles: true, clientX: Math.round(hb.left + 2), clientY: Math.round(hb.top + 2)}));
    var ht = document.getElementById('rif-tip');
    var hr = ht.getBoundingClientRect();
    return 'Q:(' + hv[0] + ' ' + (ht.hidden ? 'nascosta' : 'visibile') + ' dentro=' + (hr.left >= 0 && hr.top >= 0 && hr.right <= window.innerWidth && hr.bottom <= window.innerHeight) + ' | ' + ht.textContent.replace(/\n/g, '\u00b6') + ' [elementi=' + ht.querySelectorAll('script,iframe,img,a,b').length + ']';
  }
  if (tok.charAt(0) === ')') {
    // il clic su un riferimento interno, `)NOME` o `)NOME#n`; dice dove si è finiti (la scheda scelta e la riga evidenziata)
    var cv = tok.substring(1).split('#');
    var cl = document.querySelectorAll('#scheda-righe .rif[data-rif="' + cv[0] + '"], #scheda-righe .rife[data-ext="' + cv[0] + '"]');
    var ce = cl[cv.length > 1 ? parseInt(cv[1], 10) : 0];
    if (!ce) return 'Q:)' + tok.substring(1) + ' assente';
    ce.click();
    if (ce.classList.contains('rife')) {
      // il clic su un riferimento esterno lascia la finestrella fissa, con il suo pulsante
      var ft = document.getElementById('rif-tip');
      return 'Q:)' + cv[0] + ' ' + (ft.hidden ? 'nascosta' : 'visibile') + ' fissa=' + ft.classList.contains('fissa') + ' pulsante=' + (document.getElementById('rife-apri') ? document.getElementById('rife-apri').textContent : 'no');
    }
    var ev2 = document.querySelector('#scheda-righe .evidenza');
    return 'Q:)' + cv[0] + ' riga=' + (ev2 ? ev2.getAttribute('data-id') : 'nessuna') + ' scheda=' + document.getElementById('scheda-nome').textContent;
  }
  if (tok.charAt(0) === ':') {
    // un tasto su un elemento: :ID:Enter, :ID:Escape (la ricerca nell'albero)
    var kt = tok.substring(1).split(':');
    var tasto = kt[kt.length - 1], idk = kt.slice(0, -1).join(':');
    var ke = document.getElementById(idk) || document.querySelector('[data-id="' + idk + '"]');
    if (!ke) return '0';
    ke.dispatchEvent(new KeyboardEvent('keydown', {key: tasto, bubbles: true, cancelable: true}));
    return '0';
  }
  if (tok.charAt(0) === '/') {
    // il trascinamento nell'albero: /CHIAVE-DA>CHIAVE-A; dice se la riga d'arrivo accetta (dragover annullato) e lascia lì
    var ft = tok.substring(1).split('>');
    var ra = document.querySelector('[data-id="alb:' + ft[0] + '"]'), rb = ft[1] === 'FUORI' ? document.getElementById('fascia-fuori') : document.querySelector('[data-id="alb:' + ft[1] + '"]');
    if (!ra || !rb) return 'Q:/trascina riga assente';
    var dt = new DataTransfer();
    var mk2 = function (t) { return new DragEvent(t, {bubbles: true, cancelable: true, dataTransfer: dt}); };
    var alt0 = document.getElementById('albero').getBoundingClientRect().top + '/' + ra.getBoundingClientRect().top;
    ra.dispatchEvent(mk2('dragstart'));
    var ff2 = document.getElementById('fascia-fuori');
    var fermo = alt0 === document.getElementById('albero').getBoundingClientRect().top + '/' + ra.getBoundingClientRect().top;
    var fvis = !ff2.hidden;
    var fr0 = ff2.getBoundingClientRect();
    var ov = mk2('dragover');
    rb.dispatchEvent(ov);
    var acc = ov.defaultPrevented;
    rb.dispatchEvent(mk2('drop'));
    ra.dispatchEvent(mk2('dragend'));
    return 'Q:/trascina ' + (acc ? 'accettato' : 'rifiutato') + (ft[1] === 'FUORI' ? ' fascia=' + (fvis ? 'visibile' : 'nascosta') + ' layout=' + (fermo ? 'fermo' : 'spostato') + ' fr=' + Math.round(fr0.left) + ',' + Math.round(fr0.top) + ',' + Math.round(fr0.width) + 'x' + Math.round(fr0.height) + ' albero_top=' + Math.round(document.getElementById('albero').getBoundingClientRect().top) : '');
  }
  if (tok.charAt(0) === '^') {
    // l'albero delle entità: per ogni riga il livello, il testo, '*' se è la scelta, '>' se è aperta, i segni
    var rr2 = Array.prototype.map.call(document.querySelectorAll('#albero .nodo'), function (n) {
      var seg = Array.prototype.map.call(n.querySelectorAll('.segno'), function (x) { return x.textContent + (x.title ? '(' + x.title + ')' : ''); }).join('');
      var pal = n.querySelector('.pallino');
      var ex = n.getAttribute('aria-expanded');
      var mk = Array.prototype.map.call(n.querySelectorAll('mark'), function (x) { return x.textContent; }).join('+');
      return n.getAttribute('aria-level') + ':' + n.querySelector('.nome-nodo').textContent + (n.classList.contains('on') ? '*' : '') +
        (ex === 'true' ? '>' : (ex === 'false' ? '=' : '')) + '[' + (pal ? pal.className.replace('pallino ', '') : '') + ']' + (seg ? '{' + seg + '}' : '') + (mk ? '<' + mk + '>' : '');
    });
    var pn = document.getElementById('entita-pannello');
    return 'Q:^albero ' + (pn.hidden ? 'chiuso' : 'aperto') + ' larg=' + pn.offsetWidth + ' righe=' + rr2.length + ' | ' + rr2.join(' | ');
  }
  if (tok.charAt(0) === '&') {
    // il doppio clic come lo fa il mouse: clic, (la pagina si ridisegna), clic, dblclick sull'elemento com'è adesso
    var idd = tok.substring(1);
    var qd = function () { var l = document.querySelectorAll('[data-id="' + idd + '"]'); return l.length ? l[0] : null; };
    var e1 = qd();
    if (!e1) return 'Q:&' + idd + ' assente';
    e1.dispatchEvent(new MouseEvent('click', {bubbles: true, detail: 1}));
    var e2 = qd();
    if (e2) e2.dispatchEvent(new MouseEvent('click', {bubbles: true, detail: 2}));
    var e3 = qd();
    if (e3) e3.dispatchEvent(new MouseEvent('dblclick', {bubbles: true, detail: 2}));
    return '0';
  }
  if (tok.charAt(0) === '$') {
    // quante righe dell'albero e quante righe della scheda si vedono intere nel loro riquadro, con le altezze usate
    var dentro = function (lista, box) {
      var b = box.getBoundingClientRect(), n = 0;
      Array.prototype.forEach.call(lista, function (x) { var r = x.getBoundingClientRect(); if (r.height > 0 && r.top >= b.top - 1 && r.bottom <= b.bottom + 1) n++; });
      return n;
    };
    var nodi = document.querySelectorAll('#albero .nodo'), rg = document.querySelectorAll('#scheda-righe > div');
    var cs = getComputedStyle(document.body);
    return 'Q:$visibili finestra=' + window.innerWidth + 'x' + window.innerHeight + ' albero=' + dentro(nodi, document.getElementById('albero')) + '/' + nodi.length +
      ' scheda_righe=' + dentro(rg, document.getElementById('scheda')) + '/' + rg.length + ' albero_larg=' + document.getElementById('entita-pannello').offsetWidth +
      ' scheda_larg=' + document.getElementById('scheda').offsetWidth + ' banco_larg=' + document.getElementById('banco').offsetWidth +
      ' riga_albero=' + (nodi.length ? Math.round(nodi[0].getBoundingClientRect().height) : 0) + ' font=' + cs.fontSize;
  }
  if (tok.charAt(0) === '#') {
    var els = document.querySelectorAll('[data-id="' + tok.substring(1) + '"]');
    if (!els.length) return '0';
    els[0].dispatchEvent(new MouseEvent('click', {bubbles: true}));
    return window.__nim ? '1' : '0';
  }
  return '0';
}
"""
  proc sondaReteJs(porta: string): string =
    "(() => { var P = '" & porta & "'; var U = 'http://127.0.0.1:' + P + '/';\n" &
    "var i = new Image(); i.src = U + 'img'; document.body.appendChild(i);\n" &
    "try { fetch(U + 'fetch').catch(() => {}); } catch (e) {}\n" &
    "try { var x = new XMLHttpRequest(); x.open('GET', U + 'xhr'); x.send(); } catch (e) {}\n" &
    "try { new WebSocket('ws://127.0.0.1:' + P + '/ws'); } catch (e) {}\n" &
    "var d = document.createElement('div'); d.style.width = '10px'; d.style.height = '10px'; d.style.backgroundImage = 'url(' + U + 'css)'; document.body.appendChild(d);\n" &
    "try { window.open(U + 'open'); } catch (e) {}\n" &
    "location.href = U + 'nav'; })();\n"
  let portaSonda = getEnv("BCDD_EDITOR_SONDA_RETE")
  var attesaAttiva = false               # il token «~» aspetta il prossimo ritorno del fuoco (senza timer)
  var clicDaFare: seq[string] = (let c = getEnv("BCDD_EDITOR_PROVA_CLIC"); if c.len == 0: @[] else: c.split('|'))

var
  programma = ""
  cartella = ""
  titoloCartella = ""
  cartelle: seq[string]                  # le cartelle di lavoro, assolute, nell'ordine dell'elenco (tutte uguali)
  cartellaSel = 0                        # l'indice della cartella evidenziata: ci si creano i file nuovi
  dove: Table[string, int]               # il file `.csc` -> la cartella (indice) da cui si legge: il primo nome nell'ordine dell'elenco
  doppi: seq[(string, int, int)]         # (nome, cartella tenuta, cartella lasciata fuori) per i nomi che stanno in più cartelle
  tuttiCsc: seq[(int, string)]           # ogni `.csc` di ogni cartella, anche quelli lasciati fuori
  caricati: seq[(string, JsonNode)]      # l'ultima lettura riuscita: (file, JSON di check)
  ultimoTesto = ""                       # il modello dell'ultimo disegno, per accorgersi se è cambiato
  paginaPronta = false
  uscitaSegnata = false
  numDisegno = 0
  daSelezionare = ""                     # il nome da selezionare nel prossimo disegno (dopo «Nuova entità» o all'apertura)
  scritti: seq[string]                   # i file scritti dall'azione in corso
  notaEsito = ""                         # una parola in più per l'esito dell'azione in corso
  idScritto = ""                         # l'id che l'editor ha scelto per una promessa o ipotesi nuova
  tolti: seq[string]                     # i file tolti dall'azione in corso (Togli l'entità)
  dentroDopo = false                     # dopo l'azione la pagina mostra l'entità scelta da dentro (Metti dentro, Sposta in)

var
  refTempo = 0
  refFermato = false
  completaEsito: JsonNode = nil          # per la pagina: come è finita un'azione di Completa (chiuso, copia, riprova)

type Modifica = object
  file, prima, dopo: string              # `dopo` è l'impronta di quello che si è scritto; `prima` il testo di prima
  creato: bool                           # il file l'ha creato l'azione: non c'è un «prima», e un file non si cancella
  tolto: bool                            # il file l'ha tolto l'azione (`bcdd save --remove`): `prima` è il testo, `dopo` la sua impronta

var
  modifiche: seq[Modifica]               # i file toccati dall'azione in corso
  ultima: seq[Modifica]                  # quelli dell'ultima azione riuscita almeno in parte, solo in questa apertura
  descrUltima = ""
  ultimaVersione = false                 # l'ultima azione è «Nuova versione»: si torna indietro con `bcdd save --undo`

proc improntaDi(s: string): string = "sha256:" & toLowerAscii($secureHash(Sha_256, s))

# 005:2:1 Il lancio di bcdd: gli argomenti uno per uno, senza shell (il livello di piattaforma: edgtkfin, edwebview2)
proc cartellaDi(file: string): int =
  ## L'indice della cartella di un file `.csc` letto; un nome nuovo (o che non c'è) è nella cartella evidenziata.
  if file in dove: dove[file] else: cartellaSel

proc percorso(file: string): string =
  ## Il percorso vero di un file della cartella di lavoro (o del suo `.dialogo`, che sta accanto al `.csc`).
  let base = if file.endsWith(".dialogo"): file[0 ..< file.len - 8] else: file
  cartelle[cartellaDi(base)] / file

proc fileSuDisco(nome: string): bool =
  ## Un file `NOME.csc` esiste in una qualunque delle cartelle (anche se è stato lasciato fuori).
  for d in cartelle:
    if fileExists(d / (nome & ".csc")): return true

proc eseguiBcdd(args: seq[string], input = ""): (string, string, int) =
  traccia("lancio --lang " & $lingua & " " & args.join(" "))
  let v = @[programma, "--lang", $lingua] & args           # ogni lancio porta --lang con la lingua effettiva, mai quella dell'ambiente
  # La cartella corrente del lancio è la cartella del file (il primo argomento `.csc`; per `new` e per un file nuovo, la cartella evidenziata):
  # `save`, `refine` e `new` non hanno `--dir`; `check` e `ratify` ricevono tutte le cartelle e cercano prima nella cartella del file.
  var idx = cartellaSel
  for a in args:
    if a.endsWith(".csc"):
      idx = cartellaDi(a)
      break
  try: setCurrentDir(cartelle[idx])
  except OSError: discard
  lanciaSincrono(v, input)

var memo: MemoCheck                      # i check già letti, validi finché l'impronta di TUTTI i `.csc` di TUTTE le cartelle è la stessa

proc elencoCsc(): seq[(int, string)] =
  ## Tutti i `.csc` (non ricorsivo): cartella per cartella nell'ordine dell'elenco, in ordine di nome dentro ogni cartella.
  ## Una cartella che non si legge (di rete e sparita) non ha file.
  for i, d in cartelle:
    var nomi: seq[string]
    try:
      for k, p in walkDir(d, relative = true):
        if k in {pcFile, pcLinkToFile} and p.endsWith(".csc"): nomi.add p
    except OSError: discard
    nomi.sort()
    for n in nomi: result.add (i, n)

proc digestCartella(): string =
  ## 005:2:8 Impronta di nomi e contenuti di tutti i `.csc` di tutte le cartelle. `check --json --dir ...` di un file guarda anche
  ## gli altri file (chiusura del gruppo, rapporto), quindi un check in memoria vale solo finché tutto è identico: basta un byte diverso in un
  ## file qualsiasi e si rilancia tutto. Leggere i file non lancia niente.
  var tutto = ""
  for (i, f) in elencoCsc():
    try:
      let raw = readFile(cartelle[i] / f)
      tutto.add $i & "/" & f & "\0" & $raw.len & "\0" & raw & "\0"
    except IOError: tutto.add $i & "/" & f & "\0?\0"
  improntaDi($lingua & "\0" & cartelle.join("\1") & "\0" & tutto)          # la lingua è nella chiave: un check letto in un'altra lingua non vale

proc leggiFile(file: string, digest = digestCartella()): (JsonNode, string) =
  ## 005:2:2 `check --json` su un file; (JSON, "") oppure (nil, messaggio). Se tutto è identico a quando il file è stato controllato
  ## l'ultima volta si risponde dalla memoria, senza lanciare bcdd. Il risultato non entra in memoria se qualcosa è cambiato
  ## mentre bcdd lavorava: la memoria non è mai più vecchia delle cartelle.
  let inMemoria = memo.daMemoria(digest, file)
  if inMemoria != nil:
    traccia("check_in_memoria " & file)
    return (inMemoria, "")
  let (o, e, c) = eseguiBcdd(argomentiCheck(file, cartelle, cartellaDi(file)))
  if c != 0 and c != 1:
    return (nil, file & ": " & e.strip(leading = false, chars = {'\n'}) & " (codice " & $c & ")")
  let l = leggiUscita(programma, file, o, c)
  if not l.ok: return (nil, l.messaggio)
  memo.ricorda(digest, digestCartella(), file, l.json)
  (l.json, "")

var ultimaFirma = ""

# 005:2:9 Il giornale di una rinomina interrotta: una voce `.bcdd-rinomina` in una cartella aperta.
# La regola di presenza è quella di bcdd (K2): una voce di qualunque tipo, anche un collegamento rotto, senza seguire i collegamenti; se
# l'interrogazione fallisce per un motivo diverso da «non esiste» si fa come se ci fosse. Il contenuto serve solo a dire quale rinomina era.
const nomeGiornale = ".bcdd-rinomina"

proc giornaleInCartella(i: int): bool =
  if not dirExists(cartelle[i]): return false
  try:
    discard getFileInfo(cartelle[i] / nomeGiornale, followSymlink = false)
    result = true
  except OSError as e:
    result = e.errorCode notin [2'i32, 3'i32]


proc firmaCartella(): string =
  ## 005:2:5 Cartella, nome, data e dimensione di ogni `.csc`: basta a sapere se qualcosa è cambiato fuori, senza lanciare
  ## `bcdd` e senza bloccare la finestra quando torna attiva (con l'inoltro X di SSH il blocco si vede lampeggiare).
  var righe: seq[string]
  for (i, p) in elencoCsc():
    let f = cartelle[i] / p
    try: righe.add $i & "/" & p & "|" & $getLastModificationTime(f).toUnixFloat() & "|" & $getFileSize(f)
    except OSError: righe.add $i & "/" & p & "|?"
  for i in 0 ..< cartelle.len: righe.add $i & "/giornale|" & $giornaleInCartella(i)       # un giornale comparso o sparito da fuori è un cambiamento
  righe.sort()
  righe.join("\n")

proc scansiona(): (seq[(string, JsonNode)], string) =
  ## 005:2:3 Tutti i `.csc` delle cartelle (non ricorsivo): cartella per cartella, in ordine di nome. Il primo che non si legge ferma la scansione.
  ## Un nome che sta in più cartelle si legge una volta sola, dalla prima nell'ordine dell'elenco (come lo trova `bcdd` per le citazioni);
  ## gli altri restano fuori, e si ricordano in `doppi` per dirlo.
  let firma = firmaCartella()
  let digest = digestCartella()
  tuttiCsc = elencoCsc()
  dove = initTable[string, int]()
  doppi = @[]
  var daLeggere: seq[string]
  for (i, n) in tuttiCsc:
    if n in dove: doppi.add (n, dove[n], i)
    else:
      dove[n] = i
      daLeggere.add n
  for f in daLeggere:
    let (j, m) = leggiFile(f, digest)
    if j == nil: return (@[], m)
    result[0].add (f, j)
  ultimaFirma = firma

proc giornali(): seq[(int, string, string)] =
  ## (indice della cartella, nome vecchio, nome nuovo); i nomi sono vuoti se la terza riga del giornale non è `KIND VECCHIO NUOVO`.
  for i in 0 ..< cartelle.len:
    if not giornaleInCartella(i): continue
    var v, n = ""
    try:
      let f = open(cartelle[i] / nomeGiornale)
      defer: f.close()
      discard f.readLine()
      discard f.readLine()
      let c = f.readLine().splitWhitespace()
      if c.len == 3 and c[0] in ["csc", "entity", "part", "id"] and c[1].len in 1 .. 64 and c[2].len in 1 .. 64 and
          c[1].allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '_', '-'}) and c[2].allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '_', '-'}):
        v = c[1]
        n = c[2]
    except CatchableError: discard
    result.add (i, v, n)

proc giornaleBlocca(): string =
  ## Il messaggio che rifiuta una scrittura, o "" se nessuna cartella ha il giornale: bcdd rifiuterebbe comunque (K1), l'editor non lo lancia nemmeno.
  for (i, _, _) in giornali(): return tx(kGiornalePresente, cartelle[i])

proc modelloTesto(): string =
  ## Il banco più le cartelle: per ognuna il percorso, i suoi file (quelli lasciati fuori sono segnati) e se è l'evidenziata;
  ## e i nomi che stanno in più cartelle (la cartella tenuta e quella lasciata fuori).
  var m = buildBanco(titoloCartella, caricati)
  var cs = newJArray()
  for i, d in cartelle:
    var fs = newJArray()
    for (k, n) in tuttiCsc:
      if k != i: continue
      fs.add %*{"nome": n, "fuori": dove.getOrDefault(n, -1) != i}
    cs.add %*{"percorso": d, "selezionata": i == cartellaSel, "file": fs}
  m["cartelle"] = cs
  # : i riferimenti a documenti esterni, le decisioni e il primo D-nnn libero, per file `.csc`
  var fin: seq[FileIn]
  for (f, j) in caricati: fin.add (f, absolutePath(cartelle[dove.getOrDefault(f, cartellaSel)]), j)
  let (ext, registri) = analisiRiferimenti(fin, paroleRiservate)
  m["ext"] = ext
  m["registri"] = registri
  for o in m["nomi"]:                   # : di quale cartella è la dichiarazione (il percorso: l'etichetta la calcola la pagina) (i file sono unici fra le cartelle lette)
    let i = dove.getOrDefault(o["file"].getStr, cartellaSel)
    o["cartella"] = %cartelle[i]
  var dd = newJArray()
  for (n, t, f) in doppi: dd.add %*{"nome": n, "tenuta": cartelle[t], "fuori": cartelle[f]}
  m["doppi"] = dd
  var gj = newJArray()
  for (i, v, n) in giornali(): gj.add %*{"indice": i, "cartella": cartelle[i], "vecchio": v, "nuovo": n}
  m["giornali"] = gj                    # le cartelle con una rinomina interrotta (la striscia «Ripristina», le azioni che scrivono spente)
  $m

# 005:2:4 Nim -> pagina
when defined(bcddEditorProva):
  proc prossimoClic()

proc cbEsito(valore: string, haValore: bool, errore: string, dato: int) {.nimcall.} =
  if errore.len > 0: traccia("errore_js " & errore)

when defined(bcddEditorProva):
  proc cbClic(valore: string, haValore: bool, errore: string, dato: int) {.nimcall.} =
    var r = "0"
    if haValore: r = valore
    if errore.len > 0: traccia("errore_js " & errore)
    if r.startsWith("Q:"):
      traccia("sonda " & r)
      r = "0"
    if r == "0": prossimoClic()

  proc prossimoClic() =
    if clicDaFare.len == 0: return
    let t = clicDaFare[0]
    clicDaFare.delete(0)
    if t == "~":
      traccia("attesa_fuoco")
      attesaAttiva = true
      return
    traccia("clic " & t)
    valuta("", "bcddProvaClic(" & escapeJson(t) & ")", cbClic)

proc cbDisegno(valore: string, haValore: bool, errore: string, dato: int) {.nimcall.} =
  when defined(bcddEditorProva):
    if haValore and fileTraccia.len > 0:
      writeFile(fileTraccia & ".pagina." & $dato, valore)
      traccia("pagina " & $dato)
  if errore.len > 0: traccia("errore_js " & errore)
  when defined(bcddEditorProva):
    prossimoClic()

proc disegna(testo: string, esito: JsonNode) =
  inc numDisegno
  traccia("disegno " & $numDisegno & " sha256:" & toLowerAscii($secureHash(Sha_256, testo)))
  ultimoTesto = testo
  let ora = now().format("HH:mm:ss")
  let chiamata = "bcddDisegna(" & escapeJson(testo) & ", " & escapeJson(ora) & ", " & escapeJson($esito) & ", " &
    escapeJson(daSelezionare) & ");"
  daSelezionare = ""
  when defined(bcddEditorProva):
    valuta(chiamata, "document.body.textContent + bcddProvaStato()", cbDisegno, numDisegno)
  else:
    valuta(chiamata, "", cbDisegno, numDisegno)

proc esitoJson(ok: bool, testo: string): JsonNode =
  result = newJObject()
  result["ok"] = %ok
  result["testo"] = %testo
  result["annulla"] = %(if ultima.len > 0: descrUltima else: "")
  if dentroDopo: result["dentro"] = %true
  if completaEsito != nil: result["completa"] = completaEsito
  # 005:2:7 (pezzo 6) Se l'errore parla di righe precise, la pagina apre la casella di testo su di esse
  if not ok and rifCasella.da > 0:
    result["casella"] = %*{"tipo": rifCasella.tipo, "nome": rifCasella.nome, "da": rifCasella.da, "a": rifCasella.a}

# 005:2:6 Completa: i tempi 1 e 2 di `bcdd refine --json` chiamano l'LLM e durano. Si lanciano con
# g_subprocess_communicate_async: il ciclo di GTK resta libero e «Ferma» manda SIGINT a bcdd (che esce con 130). Il tempo 3
# e `--cancel` non chiamano l'LLM e sono azioni come le altre (eseguiAzione).
proc aggiornaCompleta(payload: JsonNode) =
  inc numDisegno
  traccia("disegno " & $numDisegno & " completa")
  let chiamata = "bcddCompleta(" & escapeJson($payload) & ");"
  when defined(bcddEditorProva):
    valuta(chiamata, "document.body.textContent + bcddProvaStato()", cbDisegno, numDisegno)
  else:
    valuta(chiamata, "", cbDisegno, numDisegno)

proc consegnaRefine(tempo, codice: int, o, e: string) =
  var p = newJObject()
  p["tempo"] = %tempo
  p["codice"] = %codice
  p["errore"] = %e.strip(leading = false, chars = {'\n'})
  p["fermato"] = %refFermato
  var u: JsonNode = newJNull()
  try:
    let j = parseJson(o)
    if j.kind == JObject and j.hasKey("forma") and j["forma"].kind == JString and j["forma"].getStr == "bcdd-giro": u = j
  except CatchableError: discard
  p["uscita"] = u
  aggiornaCompleta(p)

proc fineRefine(o, e: string, codice: int, segnalato: bool) {.nimcall.} =
  let c = if segnalato and refFermato: 130 else: codice
  traccia("fine refine tempo " & $refTempo & " codice " & $c)
  consegnaRefine(refTempo, c, o, e)

proc avviaRefine(tempo: int, args: seq[string], input: string) =
  ## Lancia il tempo 1 o 2; se non parte, lo dice alla pagina come un errore di bcdd (codice 255).
  traccia("lancio --lang " & $lingua & " " & args.join(" "))
  refTempo = tempo
  refFermato = false
  let v = @[programma, "--lang", $lingua] & args           # ogni lancio porta --lang con la lingua effettiva, mai quella dell'ambiente
  var m = ""
  if not avviaAsincrono(v, input, fineRefine, m): consegnaRefine(tempo, 255, "", m)

# 005:3:1 Le azioni del banco: una scrittura per volta, con `bcdd save` o `bcdd new`
proc fileDiEntita(nome: string): string =
  for (f, j) in caricati:
    if bloccoEntita(j, nome) != nil: return f

proc esisteCsc(nome: string): bool =
  for (_, j) in caricati:
    for b in j["blocchi"]:
      if b["tipo"].getStr == "CSC" and b["intestazione_valida"].getBool and b["nome"].getStr == nome: return true

proc nomeLibero(nome: string): bool =
  ## Nessuna entità né CSC della cartella ha già questo nome, e nessun file si chiama così.
  if fileSuDisco(nome) or esisteCsc(nome): return false
  for (_, j) in caricati:
    if bloccoEntita(j, nome) != nil: return false
  true

proc salva(file, expect, testo: string): string =
  var prima = ""
  if expect != "nuovo":
    try: prima = readFile(percorso(file))
    except IOError: discard
  let (_, e, c) = eseguiBcdd(@["save", file, "--expect", expect], testo)
  if c != 0: return e.strip(leading = false, chars = {'\n'})
  scritti.add file
  modifiche.add Modifica(file: file, prima: prima, dopo: improntaDi(testo), creato: expect == "nuovo")

proc creaCsc(nome: string): string =
  let (_, e, c) = eseguiBcdd(@["new", nome])
  if c != 0: return e.strip(leading = false, chars = {'\n'})
  scritti.add nome & ".csc"
  modifiche.add Modifica(file: nome & ".csc", creato: true)

proc togliFile(file: string): string =
  ## 005:3:7 Il file di un'entità si toglie solo con `bcdd save --remove --expect IMPRONTA`, che lascia FILE.prima.
  var prima = ""
  try: prima = readFile(percorso(file))
  except IOError: return tx(kNonRiescoLeggere, file)
  let imp = improntaDi(prima)
  let (_, e, c) = eseguiBcdd(@["save", file, "--remove", "--expect", imp])
  if c != 0: return e.strip(leading = false, chars = {'\n'})
  tolti.add file
  modifiche.add Modifica(file: file, prima: prima, dopo: imp, tolto: true)

proc creaEntita(nome, scopo: string): string =
  if not nomeValido(nome): return tx(kNomeNonValidoMin, nome)
  if nomeDispositivoWindows(nome): return tx(kNomeDispositivo, nome)     # su ogni sistema, come `bcdd new`: la CSC deve poter passare a Windows
  if not scopoValido(scopo): return tx(kScopoUnaFrase)
  if not nomeLibero(nome): return tx(kNomeGiaUsatoCartella, nome)
  salva(nome & ".csc", "nuovo", nuovaEntita(nome, scopo))

proc assicuraCsc(nome: string): string =
  if not nomeValido(nome): return tx(kNomeNonValidoMin, nome)
  if nomeDispositivoWindows(nome) and not esisteCsc(nome): return tx(kNomeDispositivo, nome)
  if esisteCsc(nome): return ""
  if fileSuDisco(nome): return tx(kCscEsisteNonContiene, nome)
  creaCsc(nome)

type Composizione = proc(raw: string, j: JsonNode, errore: var string): string

proc modificaFile(file: string, comp: Composizione): string =
  ## Legge il file, lo ricontrolla (deve essere ancora quello), compone il testo nuovo e lo salva con la sua impronta.
  var raw: string
  try: raw = readFile(percorso(file))
  except IOError: return tx(kNonRiescoLeggere, file)
  let imp = "sha256:" & toLowerAscii($secureHash(Sha_256, raw))
  let (j, m) = leggiFile(file)
  if j == nil: return m
  if j["impronta"].getStr != imp: return tx(kFileCambiatoLeggevo, file)
  var errore = ""
  let nuovo = comp(raw, j, errore)
  if errore.len > 0: return errore
  salva(file, imp, nuovo)

proc modificaEntita(entita: string, comp: Composizione): string =
  let file = fileDiEntita(entita)
  if file.len == 0: return tx(kNonTrovoEntitaCartella, entita)
  modificaFile(file, comp)

proc fileDiCsc(nome: string): string =
  for (f, j) in caricati:
    if bloccoDi(j, "CSC", nome) != nil: return f

proc modificaScheda(tipo, nome: string, comp: Composizione): string =
  ## L'entità o la CSC `nome` della scheda: il suo file, in un'unica scrittura.
  let file = if tipo == "entita": fileDiEntita(nome) else: fileDiCsc(nome)
  if file.len == 0: return tx(kNonTrovoCartella, nome)
  modificaFile(file, comp)

proc entitaJ(nome: string): JsonNode =
  ## Il banco si costruisce una volta e si legge com'è: niente `$` e parseJson di mezzo.
  let m = buildBanco(titoloCartella, caricati)
  for e in m["entita"]:
    if e["nome"].getStr == nome: return e

proc parteDi(e: JsonNode, parte: string): JsonNode =
  if e == nil: return nil
  for p in e["parti"]:
    if p["parte"].getStr == parte: return p

proc rileggi(): string =
  let (c, m) = scansiona()
  if m.len > 0: return m
  caricati = c

proc annullaUltima(): string =
  ## 005:3:3 Riscrive i file dell'ultima azione com'erano prima, ognuno con `bcdd save` e l'impronta di adesso. Se uno è cambiato
  ## da un altro programma dopo l'azione non si torna indietro. I file che l'azione ha creato restano: un `.csc` non si cancella.
  if ultima.len == 0: return tx(kNienteTornare)
  var daRiscrivere: seq[Modifica]
  var restano: seq[string]
  for m in ultima:
    if m.creato:
      restano.add m.file
      continue
    if m.tolto:
      if fileExists(percorso(m.file)): return tx(kFileTornatoAltro, m.file)
      daRiscrivere.add m
      continue
    var ora: string
    try: ora = readFile(percorso(m.file))
    except IOError: return tx(kFileNonSiLegge, m.file)
    if improntaDi(ora) != m.dopo: return tx(kFileModificatoAltro, m.file)
    daRiscrivere.add m
  if daRiscrivere.len == 0:
    return tx(kUltimaSoloCreato, restano.join(", "))
  for i in countdown(daRiscrivere.high, 0):
    let m = daRiscrivere[i]
    if m.tolto:
      # 005:3:3 il file tolto torna con `save --undo --expect nuovo`, che toglie FILE.prima
      let (_, e, c) = eseguiBcdd(@["save", m.file, "--undo", "--expect", "nuovo"])
      if c != 0: return e.strip(leading = false, chars = {'\n'})
      scritti.add m.file
    elif ultimaVersione:
      # 005:3:3 dopo «Nuova versione» la save normale rifiuterebbe di rimettere righe approvate: `save --undo` rimette il testo
      # esatto di prima (e toglie FILE.prima), solo se il file è ancora quello scritto dall'azione
      let (_, e, c) = eseguiBcdd(@["save", m.file, "--undo", "--expect", m.dopo])
      if c != 0: return e.strip(leading = false, chars = {'\n'})
      scritti.add m.file
    else:
      result = salva(m.file, m.dopo, m.prima)
      if result.len > 0: return
  if restano.len > 0: notaEsito = if restano.len == 1: tx(kRestaUnFile, restano[0]) else: tx(kRestanoFile, restano.join(", "))
  ultima = @[]
  descrUltima = ""

proc contiene(radice, cercata: string): bool =
  ## 005:3:8 `cercata` è `radice` o sta dentro di lei, anche alla lontana (per le parti dichiarate nei file letti).
  let m = buildBanco(titoloCartella, caricati)
  var visti: seq[string]
  var pila = @[radice]
  while pila.len > 0:
    let x = pila.pop
    if x == cercata: return true
    if x in visti: continue
    visti.add x
    for e in m["entita"]:
      if e["nome"].getStr == x:
        for p in e["parti"]: pila.add p["entita"].getStr

proc rimettiScritti(): string =
  ## 005:3:9 Un'azione a più scritture che si ferma a metà rimette da sola com'erano i file già scritti (come «Torna indietro»).
  ## Ritorna la frase da aggiungere all'errore; l'ultima azione riuscita di prima resta quella che era.
  if modifiche.len == 0: return ""
  let precedente = (ultima, descrUltima, ultimaVersione)
  ultima = modifiche
  ultimaVersione = false
  let r = annullaUltima()
  (ultima, descrUltima, ultimaVersione) = precedente
  modifiche = @[]
  scritti = @[]
  tolti = @[]
  if r.len == 0: tx(kRimessiScritti)
  else: tx(kNonRimessiScritti, r)

proc scriviPosto(c, posto, entita: string, molt = ""): string =
  modificaEntita(c, proc(raw: string, j: JsonNode, errore: var string): string =
    aggiungiParte(raw, j, c, posto, entita, errore, molt))

proc controlliInterno(eC: JsonNode, posto, entita, c: string): string =
  ## Le regole di «Metti dentro» e «Sposta in» per l'entità `entita` che va in `c` al posto `posto`.
  if not nomeValido(posto): return tx(kNomeNonValidoMin, posto)
  if posto in paroleRiservate: return tx(kParolaRiservataMin, posto)
  if eC == nil: return tx(kNonTrovoEntitaCartella, c)
  if entita == c: return tx(kNonDentroSeStessa, entita)
  if contiene(entita, c): return tx(kGiaDentroGiro, c, entita)
  if parteDi(eC, posto) != nil: return tx(kHaGiaPosto, c, posto)

proc scriviCompleta(a: JsonNode): string =
  ## 005:3:4 Il tempo 3 di Completa: bcdd compone e scrive CSC e dialogo; qui si ricordano i file toccati (per «Torna indietro di
  ## un'azione»: riscrive tutti e due com'erano; un dialogo che prima non c'era non si cancella, resta) e si ricava l'esito.
  let file = if a["tipo"].getStr == "entita": fileDiEntita(a["nome"].getStr) else: fileDiCsc(a["nome"].getStr)
  if file.len == 0: return tx(kNonTrovoCartella, a["nome"].getStr)
  let dlg = file & ".dialogo"
  var cscPrima, dlgPrima = ""
  let dlgEsisteva = fileExists(percorso(dlg))
  try:
    cscPrima = readFile(percorso(file))
    if dlgEsisteva: dlgPrima = readFile(percorso(dlg))
  except IOError: return tx(kNonRiescoLeggere, file)
  var acc = newJArray()
  for x in a["accettate"]: acc.add x
  let (o, e, c) = eseguiBcdd(@["refine", "--json", "--accept", file], $(%*{"accettate": acc}))
  # ciò che è cambiato davvero, anche se il comando è finito male a metà (il CSC scritto e il dialogo no)
  try:
    let cscDopo = readFile(percorso(file))
    if cscDopo != cscPrima:
      scritti.add file
      modifiche.add Modifica(file: file, prima: cscPrima, dopo: improntaDi(cscDopo))
    if fileExists(percorso(dlg)):
      let dlgDopo = readFile(percorso(dlg))
      if not dlgEsisteva or dlgDopo != dlgPrima:
        scritti.add dlg
        modifiche.add Modifica(file: dlg, prima: dlgPrima, dopo: improntaDi(dlgDopo), creato: not dlgEsisteva)
  except IOError: discard
  var j: JsonNode = nil
  try: j = parseJson(o)
  except CatchableError: discard
  if c == 0 and j != nil and j.kind == JObject and j.hasKey("scritto") and j["scritto"].kind == JObject:
    var parti: seq[string]
    for k in ["csc", "dialogo"]:
      if j["scritto"].hasKey(k) and j["scritto"][k].kind == JString:
        parti.add tx(if k == "csc": kRigheScritte else: kDialogoScritto, j["scritto"][k].getStr)
    notaEsito = if parti.len > 0: parti.join("; ") else: tx(kNienteDaScrivere)
    completaEsito = %*{"stato": "chiuso"}
    return ""
  if c == 1 and j != nil and j.kind == JObject and j.hasKey("errore") and j["errore"].kind == JString and
      j["errore"].getStr in ["file_cambiato", "dialogo_non_scritto"]:
    completaEsito = %*{"stato": "copia", "uscita": j}
  else:
    completaEsito = %*{"stato": "riprova"}
  e.strip(leading = false, chars = {'\n'})

proc restaPerProfilo(file, tipo, nome: string): string =
  ## 005:3:15 A-12 dopo `ratify` restano righe da approvare perché il connettore importa un profilo ancora da approvare.
  let (j, m) = leggiFile(file)
  if j == nil or m.len > 0: return ""
  let b = bloccoDi(j, (if tipo == "entita": "ENTITY" else: "CSC"), nome)
  if b == nil: return ""
  var gialle = false
  for g in b["garanzie"]:
    if g["stato"].getStr != "contratto": gialle = true
  if not gialle: return ""
  for c in b["citazioni"]:
    if c["tipo"].getStr == "IMPORT" and c.hasKey("trovata") and c["trovata"].kind == JObject and "HYPOTHESIS" in c["trovata"]{"stato"}.getStr(""):
      return tx(kRestanoDaApprovareProfilo, c["nome"].getStr)

proc approva(a: JsonNode, interoCsc: bool, improntaVista: string): string =
  ## 005:3:5 Approva: `bcdd ratify` una volta per riga scelta (nell'ordine dell'elenco), o una volta sola per il
  ## connettore intero. `ratify` non prende l'impronta: la controlla questa funzione, contro la lettura che la persona aveva davanti.
  ## Se un `ratify` a metà fallisce ci si ferma e si dice quali righe sono approvate e quale no; il file prima è uno solo, per
  ## «Torna indietro di un'azione».
  let tipo = a["tipo"].getStr
  let nome = a["nome"].getStr
  let decisione = a["decisione"].getStr
  let file = if tipo == "entita": fileDiEntita(nome) else: fileDiCsc(nome)
  if file.len == 0: return tx(kNonTrovoCartella, nome)
  var raw: string
  try: raw = readFile(percorso(file))
  except IOError: return tx(kNonRiescoLeggere, file)
  if improntaVista.len > 0 and improntaDi(raw) != improntaVista:
    return tx(kFileCambiatoLetto, file)
  let (j, m) = leggiFile(file)
  if j == nil: return m
  if j["impronta"].getStr != improntaDi(raw): return tx(kFileCambiatoLeggevo, file)
  if j["rapporto"]["errori"].len > 0 or j["rapporto"]["non_riconosciute"].len > 0:
    return tx(kPrimaErrori)
  let b = bloccoDi(j, (if tipo == "entita": "ENTITY" else: "CSC"), nome)
  if b == nil: return tx(kNonTrovoNelFile, nome)
  var base = @["ratify", file] & argomentiDir(cartelle, cartellaDi(file)) & @["--csc", nome]    # A-12: `--csc` sempre, il comando non dipende dagli altri blocchi del file
  var ids: seq[string]
  var quante = 0
  var resto = 0
  if interoCsc:
    let iv = intero(b)
    if iv.kind != JObject: return tx(kIntestGiaApprovata, nome)
    quante = iv["diventano"].len
    resto = iv["restano"].len
  else:
    for x in a["righe"]:
      if x.getStr notin ids: ids.add x.getStr
    for id in ids:
      var trovata = false
      for g in b["garanzie"]:
        if g["id"].getStr == id and g["stato"].getStr != "contratto": trovata = true
      for x in j["rapporto"]["ipotesi"]:       # un dettaglio di storia o di DEFINE da approvare (14.3.2)
        if x["id"].getStr == id and x["tipo"].getStr in ["DEFINE", "SCENARIO"]: trovata = true
      if not trovata: return tx(kRigaNonCEPiu, id, nome)
  proc registra() =
    ## ciò che è cambiato davvero, anche se un ratify a metà è fallito
    try:
      let dopo = readFile(percorso(file))
      if dopo != raw:
        scritti.add file
        modifiche.add Modifica(file: file, prima: raw, dopo: improntaDi(dopo))
    except IOError: discard
  if interoCsc:
    let (_, e, c) = eseguiBcdd(base & @[decisione])
    registra()
    if c != 0: return e.strip(leading = false, chars = {'\n'})
    notaEsito = (if quante == 1: tx(kUnaRigaApprovata) else: tx(kNRigheApprovate, quante)) & tx(kDecisioneFraParentesi, decisione) &
      (if resto == 1: tx(kUnaRigaResta) elif resto > 1: tx(kNRigheRestano, resto) else: "")
    let r0a = restaPerProfilo(file, tipo, nome)
    if r0a.len > 0: notaEsito.add "; " & r0a
    return
  var fatte: seq[string]
  for id in ids:
    let (_, e, c) = eseguiBcdd(base & @[id, decisione])
    if c != 0:
      registra()
      let msg = e.strip(leading = false, chars = {'\n'})
      if fatte.len == 0: return msg
      return tx(kApprovateNonApprovata, fatte.join(", "), id, msg)
    fatte.add id
  registra()
  notaEsito = (if fatte.len == 1: tx(kUnaRigaApprovata) else: tx(kNRigheApprovate, fatte.len)) & tx(kDecisioneFraParentesi, decisione)
  let r0b = restaPerProfilo(file, tipo, nome)
  if r0b.len > 0: notaEsito.add "; " & r0b

proc fileNoto(file: string): bool =
  ## Un nome di file che sta nella cartella, già letto: niente percorsi, niente nomi inventati.
  if file.len > 120 or not nomeFileAccettabile(file) or not file.endsWith(".csc"): return false      # né `\` né `:` né un nome di dispositivo di Windows
  for (f, _) in caricati:
    if f == file: return true

proc approvaBlocco(a: JsonNode, improntaVista: string): string =
  ## 005:3:16 A-12 `bcdd ratify FILE --csc NOME [--all] D-n` per le forme concrete (`--all`) e per il profilo (con le sue estensioni).
  let file = a["file"].getStr
  let arg = a["csc"].getStr
  let modo = a["modo"].getStr
  let decisione = a["decisione"].getStr
  if not fileNoto(file): return tx(kNonTrovoFileCartella, file)
  var raw: string
  try: raw = readFile(percorso(file))
  except IOError: return tx(kNonRiescoLeggere, file)
  if improntaVista.len > 0 and improntaDi(raw) != improntaVista:
    return tx(kFileCambiatoLetto, file)
  let (j, m) = leggiFile(file)
  if j == nil: return m
  if j["impronta"].getStr != improntaDi(raw): return tx(kFileCambiatoLeggevo, file)
  if j["rapporto"]["errori"].len > 0 or j["rapporto"]["non_riconosciute"].len > 0:
    return tx(kPrimaErrori)
  var args = @["ratify", file] & argomentiDir(cartelle, cartellaDi(file)) & @["--csc", arg]
  if modo == "forme": args.add "--all"
  args.add decisione
  let (_, e, c) = eseguiBcdd(args)
  try:
    let dopo = readFile(percorso(file))
    if dopo != raw:
      scritti.add file
      modifiche.add Modifica(file: file, prima: raw, dopo: improntaDi(dopo))
  except IOError: discard
  if c != 0: return e.strip(leading = false, chars = {'\n'})
  notaEsito = if modo == "forme": tx(kFormeApprovate, decisione) else: tx(kProfiloApprovatoEst, decisione)

proc scriviBlocco(a: JsonNode): string =
  ## 005:3:17 La casella e i moduli dei blocchi BINDING, VERIFICATION e PROFILE: righe `da`..`a` di FILE (come `sostituisciTesto`).
  let file = a["file"].getStr
  if not fileNoto(file): return tx(kNonTrovoFileCartella, file)
  let da = parseInt(a["da"].getStr)
  let fino = parseInt(a["a"].getStr)
  modificaFile(file, proc(raw: string, j: JsonNode, errore: var string): string =
    sostituisciTesto(raw, da, fino, a["prima"].getStr, a["testo"].getStr, errore))

proc nomeBlocco(nome: string): string =
  if not nomeValido(nome) or nome in paroleRiservate: return tx(kNomeNonValidoRiservataMin, nome)

proc creaBlocco(a: JsonNode): string =
  ## 005:3:18 A-9 «+ Forme concrete» e «+ Piano di prova»: lo scheletro in fondo al file del connettore, con una save.
  let cscN = a["csc"].getStr
  let cosa = a["cosa"].getStr
  let file = fileDiCsc(cscN)
  if file.len == 0: return tx(kNonTrovoConnettoreCartella, cscN)
  var versione = ""
  for (f, j) in caricati:
    if f == file:
      let b = bloccoDi(j, "CSC", cscN)
      if b != nil: versione = b["versione"].getStr
  if versione.len == 0: return tx(kNonTrovoVersione, cscN)
  var nome = ""
  if cosa == "forme":
    nome = a["nome"].getStr
    let e = nomeBlocco(nome)
    if e.len > 0: return e
    for (_, j) in caricati:
      for b in j["blocchi"]:
        if b["tipo"].getStr == "BINDING" and b["nome"].getStr == cscN and b.hasKey("nome_proprio") and b["nome_proprio"].getStr("") == nome:
          return tx(kFormeGiaNome, nome)
  modificaFile(file, proc(raw: string, j: JsonNode, errore: var string): string =
    var testo = raw
    if testo.len > 0 and testo[^1] != '\n': testo.add "\n"
    if cosa == "forme":
      testo.add "BINDING " & cscN & " VERSION " & versione & " AS " & nome & "\n  STATUS HYPOTHESIS\nEND\n"
    else:
      testo.add "VERIFICATION " & cscN & " VERSION " & versione & "\nEND\n"
    testo)

proc creaProfilo(a: JsonNode): string =
  ## 005:3:19 A-9 «+ Profilo»: un file nuovo `Nome.csc` con l'intestazione, lo scopo e `END` (`save --expect nuovo`).
  let nome = a["nome"].getStr
  let scopo = a["scopo"].getStr.strip
  let e = nomeBlocco(nome)
  if e.len > 0: return e
  if not scopoValido(scopo): return tx(kScopoUnaFrase)
  for (_, j) in caricati:
    for b in j["blocchi"]:
      if b["tipo"].getStr == "PROFILE" and b["nome"].getStr == nome: return tx(kProfiloEsiste, nome)
  if fileSuDisco(nome): return tx(kFileEsiste, nome)
  salva(nome & ".csc", "nuovo", "PROFILE " & nome & " VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"" & scopo & "\"\nEND\n")

proc togliProfilo(a: JsonNode): string =
  ## 005:3:20 A-9 Un profilo si toglie con il suo file, solo se nessun blocco della cartella lo importa e il file non ha altro.
  let nome = a["nome"].getStr
  var file = ""
  for (f, j) in caricati:
    for b in j["blocchi"]:
      if b["tipo"].getStr == "PROFILE" and b["nome"].getStr == nome: file = f
      for c in b["citazioni"]:
        if c["tipo"].getStr == "IMPORT" and c["nome"].getStr == nome: return tx(kProfiloImportato, nome, b["tipo"].getStr, b["nome"].getStr)
  if file.len == 0: return tx(kNonTrovoProfilo, nome)
  for (f, j) in caricati:
    if f == file:
      for b in j["blocchi"]:
        if b["tipo"].getStr != "PROFILE": return tx(kFileHaAltroProfilo, file)
        if b["stato"].getStr == "contratto": return tx(kProfiloApprovatoNo, nome)
      if j["rapporto"]["ipotesi"].len == 0 and j["blocchi"].len > 0 and j["blocchi"][0]["stato"].getStr == "contratto": return tx(kProfiloApprovatoBreve)
  togliFile(file)

proc eseguiAzione(a: JsonNode): string =
  ## 005:3:2 Ritorna il messaggio d'errore, o "" se l'azione è riuscita. Si ferma al primo passo che non riesce.
  let az = a["azione"].getStr
  var vista = ""                           # l'impronta del file di Approva come la persona lo aveva davanti (prima della rilettura)
  if az in ["approva_righe", "approva_intero"]:
    let f0 = if a["tipo"].getStr == "entita": fileDiEntita(a["nome"].getStr) else: fileDiCsc(a["nome"].getStr)
    for (f, j) in caricati:
      if f == f0: vista = j["impronta"].getStr
  elif az == "approva_blocco":
    for (f, j) in caricati:
      if f == a["file"].getStr: vista = j["impronta"].getStr
  let e0 = rileggi()
  if e0.len > 0: return e0
  case az
  of "nuova_entita":
    result = creaEntita(a["nome"].getStr, a["scopo"].getStr)
    if result.len == 0: daSelezionare = a["nome"].getStr
  of "pubblico":
    let ent = a["entita"].getStr
    let csc = a["csc"].getStr
    let lato = a["lato"].getStr
    result = assicuraCsc(csc)
    if result.len > 0: return
    result = modificaEntita(ent, proc(raw: string, j: JsonNode, errore: var string): string =
      aggiungiPubblico(raw, j, ent, csc, lato, errore))
  of "parte":
    let ent = a["entita"].getStr
    let parte = a["parte"].getStr
    let tipo = a["tipo"].getStr
    let scopo = a["scopo"].getStr
    if not nomeValido(parte): return tx(kNomeNonValidoMin, parte)
    if not nomeValido(tipo): return tx(kNomeNonValidoMin, tipo)
    if tipo == ent: return tx(kNonParteDiSe, ent)
    if scopo.len > 0:
      result = creaEntita(tipo, scopo)
      if result.len > 0: return
      let r = rileggi()
      if r.len > 0: return r
    elif fileDiEntita(tipo).len == 0: return tx(kNonCEEntitaCartella, tipo)
    result = modificaEntita(ent, proc(raw: string, j: JsonNode, errore: var string): string =
      aggiungiParte(raw, j, ent, parte, tipo, errore))
  of "passa":
    let ent = a["entita"].getStr
    let csc = a["csc"].getStr
    let lato = a["lato"].getStr
    let e = entitaJ(ent)
    let p = parteDi(e, a["parte"].getStr)
    if p == nil: return tx(kNonTrovoParteIn, a["parte"].getStr, ent)
    let tipo = p["entita"].getStr
    result = modificaEntita(tipo, proc(raw: string, j: JsonNode, errore: var string): string =
      aggiungiPubblico(raw, j, tipo, csc, lato, errore))
  of "connettore":
    let ent = a["entita"].getStr
    let csc = a["csc"].getStr
    let e = entitaJ(ent)
    let po = parteDi(e, a["offre"].getStr)
    let pu = parteDi(e, a["usa"].getStr)
    if po == nil or pu == nil: return tx(kDuePartiDi, ent)
    if po["parte"].getStr == pu["parte"].getStr: return tx(kOffreUsaDiverse)
    result = assicuraCsc(csc)
    if result.len > 0: return
    let tOff = po["entita"].getStr
    let tu = pu["entita"].getStr
    result = modificaEntita(tOff, proc(raw: string, j: JsonNode, errore: var string): string =
      aggiungiPubblico(raw, j, tOff, csc, "OFFERS", errore))
    if result.len > 0: return
    let r = rileggi()
    if r.len > 0: return r
    result = modificaEntita(tu, proc(raw: string, j: JsonNode, errore: var string): string =
      aggiungiPubblico(raw, j, tu, csc, "USES", errore))
  of "collega":
    # 005:3:6 due entità libere: la stessa CSC da lati opposti. Scrive la riga che manca a chi non l'ha
    # (una o due, `bcdd new` se la CSC non c'è), un `bcdd save` per file; la regola dei lati vale qui, non solo nella pagina.
    let ent = a["entita"].getStr
    let altra = a["altra"].getStr
    let csc = a["csc"].getStr
    let offre = a["offre"].getStr
    if altra == ent: return tx(kScegliDueEntita)
    if offre notin [ent, altra]: return tx(kOffreUnaDelleDue)
    let usa = if offre == ent: altra else: ent
    let eO = entitaJ(offre)
    let eU = entitaJ(usa)
    if eO == nil: return tx(kNonTrovoEntitaCartella, offre)
    if eU == nil: return tx(kNonTrovoEntitaCartella, usa)
    proc ha(e: JsonNode, lato: string): bool =
      for x in e[lato]:
        if x.getStr == csc: return true
    let oO = ha(eO, "offre")
    let uU = ha(eU, "usa")
    if oO and uU: return tx(kGiaCollegate, offre, usa, csc)
    if ha(eU, "offre"): return tx(kOffreGia, usa, csc)
    if ha(eO, "usa"): return tx(kUsaGia, offre, csc)
    result = assicuraCsc(csc)
    if result.len > 0: return
    if not oO:
      result = modificaEntita(offre, proc(raw: string, j: JsonNode, errore: var string): string =
        aggiungiPubblico(raw, j, offre, csc, "OFFERS", errore))
      if result.len > 0: return
    if not uU:
      if not oO:
        let r = rileggi()
        if r.len > 0: return r
      result = modificaEntita(usa, proc(raw: string, j: JsonNode, errore: var string): string =
        aggiungiPubblico(raw, j, usa, csc, "USES", errore))
  of "scollega_passaggio":
    let ent = a["entita"].getStr
    let p = parteDi(entitaJ(ent), a["parte"].getStr)
    if p == nil: return tx(kNonTrovoParteIn, a["parte"].getStr, ent)
    let tipo = p["entita"].getStr
    let csc = a["csc"].getStr
    let lato = a["lato"].getStr
    result = modificaEntita(tipo, proc(raw: string, j: JsonNode, errore: var string): string =
      togliPubblico(raw, j, tipo, csc, lato, errore))
  of "scollega_accoppiamento":
    let ent = a["entita"].getStr
    let csc = a["csc"].getStr
    let e = entitaJ(ent)
    let po = parteDi(e, a["offre"].getStr)
    let pu = parteDi(e, a["usa"].getStr)
    if po == nil or pu == nil: return tx(kDuePartiDi, ent)
    let tOff = po["entita"].getStr
    let tu = pu["entita"].getStr
    result = modificaEntita(tOff, proc(raw: string, j: JsonNode, errore: var string): string =
      togliPubblico(raw, j, tOff, csc, "OFFERS", errore))
    if result.len > 0: return
    let r = rileggi()
    if r.len > 0: return r
    result = modificaEntita(tu, proc(raw: string, j: JsonNode, errore: var string): string =
      togliPubblico(raw, j, tu, csc, "USES", errore))
  of "togli_parte":
    let ent = a["entita"].getStr
    let parte = a["parte"].getStr
    result = modificaEntita(ent, proc(raw: string, j: JsonNode, errore: var string): string =
      togliParte(raw, j, ent, parte, errore))
  of "porta_fuori":
    # 005:3:13 Portare fuori un posto è togliere la sua riga dall'entità che lo contiene (una save); poi si sceglie l'entità portata fuori
    let ent = a["entita"].getStr
    let parte = a["parte"].getStr
    let p = parteDi(entitaJ(ent), parte)
    if p == nil: return tx(kNonTrovoPostoIn, parte, ent)
    let portata = p["entita"].getStr
    result = modificaEntita(ent, proc(raw: string, j: JsonNode, errore: var string): string =
      togliParte(raw, j, ent, parte, errore))
    if result.len == 0 and entitaJ(portata) != nil: daSelezionare = portata
  of "togli_pubblico":
    let ent = a["entita"].getStr
    let csc = a["csc"].getStr
    let lato = a["lato"].getStr
    result = modificaEntita(ent, proc(raw: string, j: JsonNode, errore: var string): string =
      togliPubblico(raw, j, ent, csc, lato, errore))
  of "metti_dentro":
    # 005:3:10 Il posto nuovo di un'entità dentro un'altra: `COMPOSED OF` se manca e la riga `posto : Entità`, una save
    let ent = a["entita"].getStr
    let dentro = a["dentro"].getStr
    let posto = a["posto"].getStr
    if fileDiEntita(ent).len == 0: return tx(kNonTrovoEntitaCartella, ent)
    let errC = controlliInterno(entitaJ(dentro), posto, ent, dentro)
    if errC.len > 0: return errC
    result = scriviPosto(dentro, posto, ent)
    if result.len == 0:
      daSelezionare = dentro
      dentroDopo = true
  of "sposta":
    # 005:3:11 Il posto passa da un'entità a un'altra: prima si scrive nell'arrivo (non toglie niente), poi si toglie da dove stava;
    # se la seconda scrittura non riesce, la prima si rimette
    let da = a["da"].getStr
    let posto = a["posto"].getStr
    let verso = a["a"].getStr
    let nuovo = a["nuovo"].getStr
    let eDa = entitaJ(da)
    let p = parteDi(eDa, posto)
    if p == nil: return tx(kNonTrovoPostoIn, posto, da)
    let ent = p["entita"].getStr
    if verso == da: return tx(kPostoGiaIn, posto, da)
    if eDa["approvata"].getBool: return tx(kRigheApprovatePosto, da, posto)
    let errC = controlliInterno(entitaJ(verso), nuovo, ent, verso)
    if errC.len > 0: return errC
    # la molteplicità del posto, se c'è, va con lui
    result = scriviPosto(verso, nuovo, ent, (if p.hasKey("molteplicita"): p["molteplicita"].getStr else: ""))
    if result.len > 0: return
    result = rileggi()
    if result.len == 0:
      result = modificaEntita(da, proc(raw: string, j: JsonNode, errore: var string): string =
        togliParte(raw, j, da, posto, errore))
    if result.len > 0:
      result = result & rimettiScritti()
      return
    daSelezionare = verso
    dentroDopo = true
  of "togli_entita":
    # 005:3:12 Prima le righe dei posti (una save per entità che contiene), poi il file con `save --remove`; ogni passo che
    # non riesce rimette quelli già fatti. Niente si scrive se l'entità o una che la contiene ha righe approvate.
    let ent = a["entita"].getStr
    let file = fileDiEntita(ent)
    if file.len == 0: return tx(kNonTrovoEntitaCartella, ent)
    for (f, j) in caricati:
      if f == file and j["blocchi"].len > 1: return tx(kFileContieneAltro, file)
    let m = buildBanco(titoloCartella, caricati)
    var contenitori: seq[string]
    var posti: seq[seq[string]]
    for e in m["entita"]:
      var mie: seq[string]
      for p in e["parti"]:
        if p["entita"].getStr == ent: mie.add p["parte"].getStr
      if e["nome"].getStr == ent:
        if e["approvata"].getBool: return tx(kRigheApprovateNonSiToglie, ent)
        continue
      if mie.len > 0:
        if e["approvata"].getBool: return tx(kRigheApprovatePostoQuindi, e["nome"].getStr, mie[0], ent)
        contenitori.add e["nome"].getStr
        posti.add mie
    for i, c in contenitori:
      let r0 = rileggi()
      if r0.len > 0: return r0 & rimettiScritti()
      let mie = posti[i]
      result = modificaEntita(c, proc(raw: string, j: JsonNode, errore: var string): string =
        togliParti(raw, j, c, mie, errore))
      if result.len > 0:
        result = result & rimettiScritti()
        return
    result = togliFile(file)
    if result.len > 0:
      result = result & rimettiScritti()
      return
    notaEsito = if contenitori.len > 0: tx(kPostiToltiConnettoriRestano) else: tx(kConnettoriRestano)
  of "scheda_scopo", "scheda_aggiungi", "scheda_cambia", "scheda_togli":
    let tipo = a["tipo"].getStr
    let nome = a["nome"].getStr
    let tipoB = if tipo == "entita": "ENTITY" else: "CSC"
    var d = Dich(genere: a{"genere"}.getStr(""), id: a{"nomeD"}.getStr(""), frase: a{"frase"}.getStr("").strip, come: a{"come"}.getStr(""),
      chi: a{"chi"}.getStr("").strip, verso: a{"verso"}.getStr(""), tipoDato: a{"tipoD"}.getStr(""), valore: a{"valore"}.getStr(""),
      unita: a{"unita"}.getStr(""))
    let riga = if a{"riga"}.getStr("").len > 0: parseInt(a["riga"].getStr) else: 0
    let vecchio = a{"vecchio"}.getStr("")
    if d.genere == "stato" and d.tipoDato == "String": d.valore = d.valore.strip(chars = {'\t', '\n', '\r'})
    result = modificaScheda(tipo, nome, proc(raw: string, j: JsonNode, errore: var string): string =
      case az
      of "scheda_scopo": cambiaScopo(raw, j, tipoB, nome, a["frase"].getStr, errore)
      of "scheda_aggiungi":
        var idScelto = ""
        let r = aggiungiDich(raw, j, tipoB, nome, d, errore, idScelto)
        if errore.len == 0 and idScelto.len > 0: idScritto = idScelto
        r
      of "scheda_cambia": cambiaDich(raw, j, tipoB, nome, riga, vecchio, d, errore)
      else: togliDich(raw, j, tipoB, nome, riga, d.genere, vecchio, errore))
  of "casella_scrivi":
    let tipo = a["tipo"].getStr
    let nome = a["nome"].getStr
    let da = parseInt(a["da"].getStr)
    let fino = parseInt(a["a"].getStr)
    let prima = a["prima"].getStr
    let testo = a["testo"].getStr
    result = modificaScheda(tipo, nome, proc(raw: string, j: JsonNode, errore: var string): string =
      sostituisciTesto(raw, da, fino, prima, testo, errore))
  of "blocco_scrivi": result = scriviBlocco(a)
  of "blocco_crea": result = creaBlocco(a)
  of "profilo_crea": result = creaProfilo(a)
  of "profilo_togli": result = togliProfilo(a)
  of "approva_blocco": result = approvaBlocco(a, vista)
  of "nuova_versione":
    let tipo = a["tipo"].getStr
    let nome = a["nome"].getStr
    let tipoB = if tipo == "entita": "ENTITY" else: "CSC"
    var ids: seq[string]
    for x in a["righe"]: ids.add x.getStr
    result = modificaScheda(tipo, nome, proc(raw: string, j: JsonNode, errore: var string): string =
      nuovaVersione(raw, j, tipoB, nome, a["versione"].getStr, a["frase"].getStr.strip, ids, errore))
  of "annulla":
    result = annullaUltima()
  of "csc_nuova":
    # 005:3:14 Con `scopo` (la frase del motivo, modificata dall'operatore) il file nasce con `bcdd new` e subito dopo lo scopo
    # si scrive con una save: due file-azioni dentro la stessa azione per «Torna indietro» (che rimette lo scopo di `new`; il file resta).
    let nomeC = a["nome"].getStr
    let scopoC = a{"scopo"}.getStr("").strip
    let c0 = esisteCsc(nomeC)
    if scopoC.len > 0 and not scopoValido(scopoC): return tx(kScopoUnaFrase200)
    result = assicuraCsc(nomeC)
    if result.len == 0 and scopoC.len > 0 and not c0:
      let r = rileggi()
      if r.len > 0: return r
      result = modificaScheda("csc", nomeC, proc(raw: string, j: JsonNode, errore: var string): string =
        cambiaScopo(raw, j, "CSC", nomeC, scopoC, errore))
      if result.len > 0: result = tx(kCreatoScopoNo, nomeC, result)
  of "togli_csc":
    # 005:3:15 Un connettore che nessuna entità nomina si toglie con `save --remove`; niente si scrive se ha righe approvate
    let nomeC = a["nome"].getStr
    let file = fileDiCsc(nomeC)
    if file.len == 0: return tx(kNonTrovoConnettoreCartella, nomeC)
    for (f, j) in caricati:
      if f == file and j["blocchi"].len > 1: return tx(kFileContieneAltro, file)
    let m = buildBanco(titoloCartella, caricati)
    for c in m["csc"]:
      if c["nome"].getStr == nomeC:
        if c["approvata"].getBool: return tx(kRigheApprovateNonSiToglie, nomeC)
        var usi: seq[string]
        for x in c["offerta_da"]: usi.add x.getStr
        for x in c["usata_da"]: (if x.getStr notin usi: usi.add x.getStr)
        if usi.len > 0: return tx(kCscUsatoDa, nomeC, usi.join(", "))
    result = togliFile(file)
    if result.len == 0: notaEsito = tx(kNessunaEntitaLoUsava)
  of "completa_chiudi":
    let file = if a["tipo"].getStr == "entita": fileDiEntita(a["nome"].getStr) else: fileDiCsc(a["nome"].getStr)
    if file.len == 0: return tx(kNonTrovoCartella, a["nome"].getStr)
    let (_, e, c) = eseguiBcdd(@["refine", "--json", "--cancel", file])
    completaEsito = %*{"stato": "chiuso"}
    if c != 0: return e.strip(leading = false, chars = {'\n'})
    notaEsito = tx(kGiroChiuso)
  of "completa_scrivi":
    result = scriviCompleta(a)
  of "approva_righe":
    result = approva(a, false, vista)
  of "approva_intero":
    result = approva(a, true, vista)
  else:
    result = tx(kAzioneSconosciuta)

# 005:4:1 I segnali di GTK e di WebKit
proc rinfresca(esito: JsonNode) =
  let (c, m) = scansiona()
  if m.len > 0:
    # la lettura non è riuscita: si tiene il disegno di prima e si dice perché
    valuta("bcddAvviso(" & escapeJson(m) & ");", "", cbEsito)
    return
  caricati = c
  let t = modelloTesto()
  if t != ultimoTesto or esito != nil: disegna(t, if esito == nil: esitoJson(true, "") else: esito)
  else:
    traccia("controllato")
    valuta("bcddControllato(" & escapeJson(now().format("HH:mm:ss")) & ");", "", cbEsito)

proc titoloDa(prima: string): string =
  ## Il nome dell'insieme: la prima cartella, e «+N» per le altre.
  if cartelle.len > 1: prima & " +" & $(cartelle.len - 1) else: prima

proc gestisciCartelle(j: JsonNode) =
  ## Le tre azioni sull'insieme delle cartelle (nessuna scrive un `.csc`): scegliere la cartella dei file nuovi, aggiungerne (con la finestra
  ## di scelta), toglierne. Ogni cambio dell'insieme è ricordato; dopo, tutto si rilegge.
  let az = j["azione"].getStr
  var esito: JsonNode = nil
  azzeraRif()                                  # E4: i file `.md` e il registro si rileggono quando cambia l'insieme delle cartelle
  let i = parseInt(j["indice"].getStr)
  case az
  of "cartella_scegli":
    if i < cartelle.len: cartellaSel = i
  of "cartella_togli":
    if cartelle.len <= 1: esito = esitoJson(false, tx(kCartellaUltima))
    elif i < cartelle.len:
      let nome = cartelle[i]
      cartelle.delete(i)
      if i < cartellaSel: dec cartellaSel
      cartellaSel = min(cartellaSel, cartelle.len - 1)
      discard ricordaCartelle(cartelle)
      titoloCartella = titoloDa(cartelle[0])
      esito = esitoJson(true, tx(kCartellaTolta, nome))
  else:
    let sc = scegliCartelle(tx(kScegliCartella), tx(kScegliAnnulla), tx(kScegliApri), cartelle[cartellaSel], aggiungi = true)
    if not sc.ok:
      esito = esitoJson(false, tx(kEsciDisplay))
    else:
      var errori, aggiunte: seq[string]
      for r in sc.rifiutate: errori.add tx(kCartellaSenzaPercorso, r)
      for c in sc.cartelle:
        let a = percorsoPulito(c)
        if a in cartelle or a in aggiunte: errori.add tx(kCartellaGiaNellElenco, a)
        elif not dirExists(a): errori.add tx(kCartellaNonSiTrova, a)
        else: aggiunte.add a
      if aggiunte.len > 0:
        cartellaSel = cartelle.len
        cartelle.add aggiunte
        discard ricordaCartelle(cartelle)
        titoloCartella = titoloDa(cartelle[0])
        esito = esitoJson(true, (if aggiunte.len == 1: tx(kCartellaAggiunta, aggiunte[0]) else: tx(kCartelleAggiunte, aggiunte.join(", "))) &
          (if errori.len > 0: "; " & errori.join(" ") else: ""))
      elif errori.len > 0: esito = esitoJson(false, errori.join(" "))
      else: return                                   # annullata: niente cambia
  rinfresca(esito)

# 005:4:5 La rinomina. Nessuna regola è calcolata qui: l'anteprima e la scrittura sono `bcdd rename`
# (`--dry-run --json`, poi `--expect IMPRONTA`, con le `--dir` come per `check` e `ratify`); la pagina riceve l'oggetto `bcdd-rename` versione 1 com'è.
# Solo la scrittura riuscita rilegge tutto (come Ricarica) e svuota «Torna indietro» (E3): la rinomina tocca più file e i `.prima` non le corrispondono.
proc aggiornaRinomina(payload: JsonNode) =
  inc numDisegno
  traccia("disegno " & $numDisegno & " rinomina")
  let chiamata = "bcddRinomina(" & escapeJson($payload) & ");"
  when defined(bcddEditorProva):
    valuta(chiamata, "document.body.textContent + bcddProvaStato()", cbDisegno, numDisegno)
  else:
    valuta(chiamata, "", cbDisegno, numDisegno)

proc pluraleRin(n: int, uno, molti: Chiave): string = (if n == 1: tx(uno) else: tx(molti, n))

proc esitoScrittoRin(r: JsonNode, kind, vecchio, nuovo: string): string =
  ## «Rinominato Luce in Lampadina: 6 righe in 4 file, 1 file rinominato; 1 testo resta con il nome vecchio.» e come tornare indietro (E3).
  var righe, file, rinominati, restano = 0
  for f in r["file"]:
    if f["modifiche"].len > 0 or f["nome_nuovo"].kind == JString: inc file
    righe += f["modifiche"].len
    if f["nome_nuovo"].kind == JString: inc rinominati
  for t in r["testi"]:
    if not t["scelto"].getBool: inc restano
  tx(kRinomEsito, vecchio, nuovo, pluraleRin(righe, kRinomRiga1, kRinomRighe), pluraleRin(file, kRinomFile1, kRinomFile),
    (if rinominati == 0: "" else: pluraleRin(rinominati, kRinomFileRin1, kRinomFileRin)),
    (if restano == 0: "" else: pluraleRin(restano, kRinomTestiResta1, kRinomTestiResta)),
    tx(kRinomTornare, nuovo, vecchio))

proc eseguiRinomina(j: JsonNode, scrivi: bool) =
  let kind = j["kind"].getStr
  let vecchio = j["vecchio"].getStr
  let nuovo = j["nuovo"].getStr
  let blocco = j["blocco"].getStr
  let dove = j["dove"].getStr
  var p = %*{"kind": kind, "vecchio": vecchio, "nuovo": nuovo, "blocco": blocco, "dove": dove, "fase": (if scrivi: "scrittura" else: "anteprima"),
    "codice": 0, "errore": "", "r": newJNull()}
  if scrivi:
    let gb = giornaleBlocca()
    if gb.len > 0:
      p["codice"] = %1
      p["errore"] = %gb
      aggiornaRinomina(p)
      return
  var file, csc = ""
  case kind
  of "csc": file = fileDiCsc(vecchio)
  of "entity": file = fileDiEntita(vecchio)
  of "part":
    file = fileDiEntita(blocco)
    csc = blocco
  else:
    file = if dove == "csc": fileDiCsc(blocco) else: fileDiEntita(blocco)
    csc = blocco
  if file.len == 0:
    p["codice"] = %2
    p["errore"] = %tx(kNonTrovoCartella, if blocco.len > 0: blocco else: vecchio)
    aggiornaRinomina(p)
    return
  var args = @["rename", file]
  if csc.len > 0: args.add @["--csc", csc]
  args.add argomentiDir(cartelle, cartellaDi(file))
  if scrivi:
    args.add @["--expect", j["impronta"].getStr]
    if j["testi"].len == 0: args.add @["--text", "none"]
    else:
      for t in j["testi"]: args.add @["--text-at", t.getStr]
  else: args.add "--dry-run"
  args.add @["--json", kind, vecchio, nuovo]
  let (o, e, c) = eseguiBcdd(args)
  var r: JsonNode = nil
  try:
    let x = parseJson(o)
    if x.kind == JObject and x{"forma"}.getStr == "bcdd-rename" and x{"versione"}.getInt == 1 and x{"esito"}.kind == JString: r = x
  except CatchableError: discard
  p["codice"] = %c
  p["errore"] = %e.strip(leading = false, chars = {'\n'})
  if r == nil:
    if c in [0, 1]: p["errore"] = %tx(kRinomRisposta, (if e.strip.len > 0: e.strip else: o.strip))
  else:
    # bcdd scrive `.` per la cartella del file e il percorso dato per le altre: alla pagina si dà sempre il percorso intero (poi mostra l'ultimo pezzo)
    let propria = cartelle[cartellaDi(file)]
    for k in ["file", "compagni", "testi", "bloccanti"]:
      if r.hasKey(k) and r[k].kind == JArray:
        for x in r[k]:
          if x.kind == JObject and x.hasKey("cartella") and x["cartella"].kind == JString and x["cartella"].getStr == ".": x["cartella"] = %propria
    p["r"] = r
  if scrivi and r != nil and r["esito"].getStr == "scritto" and c == 0:
    ultima = @[]
    descrUltima = ""
    ultimaVersione = false
    azzeraRif()
    memo.voci.clear()
    memo.digest = ""
    let es = esitoJson(true, esitoScrittoRin(r, kind, vecchio, nuovo))
    es["rinomina"] = %*{"kind": kind, "vecchio": vecchio, "nuovo": nuovo, "blocco": blocco, "dove": dove}
    rinfresca(es)
    return
  aggiornaRinomina(p)

proc ripristinaRinomina(indice: int) =
  ## `bcdd rename --recover CARTELLA` (R4), poi Ricarica: l'esito di bcdd (anche «estraneo», con i percorsi delle copie) è il messaggio di stato.
  if indice >= cartelle.len: return
  let (o, e, c) = eseguiBcdd(@["rename", "--recover", cartelle[indice], "--json"])
  var msg = ""
  try:
    let x = parseJson(o)
    if x.kind == JObject and x{"forma"}.getStr == "bcdd-rename" and x{"messaggio"}.kind == JString: msg = x["messaggio"].getStr
  except CatchableError: discard
  if msg.len == 0: msg = e.strip(leading = false, chars = {'\n'})
  if msg.len == 0 and c == 0: msg = tx(kRipristinoFatto)
  azzeraRif()
  memo.voci.clear()
  memo.digest = ""
  rinfresca(esitoJson(c == 0, msg))

proc alCambioFuoco(attiva: bool) {.nimcall.} =
  if attiva:
    traccia("attiva")
    if not uscitaSegnata or not paginaPronta: return
    uscitaSegnata = false
    let n0 = numDisegno
    if firmaCartella() == ultimaFirma:
      # niente è cambiato fuori: non si lancia bcdd e non si tocca la pagina
      traccia("controllato")
    else: rinfresca(nil)
    when defined(bcddEditorProva):
      if attesaAttiva:
        attesaAttiva = false
        if numDisegno == n0: prossimoClic()
  else:
    traccia("non_attiva")
    uscitaSegnata = true

proc allaCaricata() {.nimcall.} =
  if not paginaPronta:
    paginaPronta = true
    if remoto: valuta("document.body.classList.add('remoto');", "", cbEsito)
    disegna(modelloTesto(), esitoJson(true, ""))

proc campiEsatti(j: JsonNode, chiavi: openArray[string]): bool =
  if j.len != chiavi.len: return false
  for k in chiavi:
    if not (j.hasKey(k) and j[k].kind == JString): return false
  true

const campiScheda = ["azione", "tipo", "nome", "genere", "riga", "vecchio", "frase", "come", "chi", "nomeD", "verso", "tipoD", "valore", "unita"]

proc campiBase(j: JsonNode, extra: string): bool =
  ## azione, tipo, nome (stringhe) più un solo campo `extra` di altro tipo.
  if j.len != 4 or not j.hasKey(extra): return false
  for k in ["azione", "tipo", "nome"]:
    if not (j.hasKey(k) and j[k].kind == JString): return false
  true

proc decisioneOk(s: string): bool =
  ## 005:4:2 Il numero di una decisione come lo scrive la persona: `D-` e cifre. Che esista nel registro non lo controlla l'editor.
  s.len in 3 .. 8 and s.startsWith("D-") and s[2 .. ^1].allCharsInSet({'0'..'9'})

proc idRigaOk(s: string): bool =
  ## 005:4:3 L'id di una promessa o di un presupposto: lettera, poi lettere, cifre, `_` e `-`.
  if s.len == 0 or s.len > 64 or not (s[0] in {'A'..'Z', 'a'..'z'}): return false
  s.allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '_', '-'})

proc cifre(s: string): bool = s.len in 1 .. 6 and s.allCharsInSet({'0'..'9'})

proc schedaBase(j: JsonNode): bool =
  ## Le scritture della scheda: di una entità o di una CSC, con un nome che l'editor accetta.
  j["tipo"].getStr in ["entita", "csc"] and nomeValido(j["nome"].getStr)

proc campiDichOk(j: JsonNode): bool =
  ## I campi del modulo hanno una misura ragionevole (il merito lo controlla `validaDich`, nel compositore).
  for k in ["frase", "chi", "valore"]:
    if j[k].getStr.len > maxFrase: return false
  for k in ["nomeD", "come", "verso", "tipoD", "unita"]:
    if j[k].getStr.len > 64: return false
  true

proc nomeRin(s: string): bool =
  ## Un nome della rinomina com'arriva dalla pagina: lettera, poi lettere, cifre, `_` e `-`, al massimo 64 caratteri. Se è un nome valido per
  ## il linguaggio lo decide bcdd (N1-N7): qui basta che non possa essere un'opzione né contenere altro.
  s.len in 1 .. 64 and s[0] in {'A'..'Z', 'a'..'z'} and s.allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '_', '-'})

proc rinomValido(j: JsonNode, scrivi: bool): bool =
  ## 005:4:4 `rinomina_anteprima`: tutte stringhe; `rinomina_scrivi` in più l'impronta dell'anteprima e l'elenco dei testi scelti (`tN`).
  var base = newJObject()
  for k, v in j:
    if k != "testi": base[k] = v
  if scrivi:
    if not (j.hasKey("testi") and j["testi"].kind == JArray and j["testi"].len <= 500): return false
    for x in j["testi"]:
      if x.kind != JString or x.getStr.len notin 2 .. 7 or x.getStr[0] != 't' or not cifre(x.getStr[1 .. ^1]): return false
    if not campiEsatti(base, ["azione", "kind", "vecchio", "nuovo", "blocco", "dove", "impronta"]): return false
    let im = base["impronta"].getStr
    if not (im.len == 71 and im.startsWith("sha256:") and im[7 .. ^1].allCharsInSet({'0'..'9', 'a'..'f'})): return false
  elif not campiEsatti(base, ["azione", "kind", "vecchio", "nuovo", "blocco", "dove"]): return false
  let kind = j["kind"].getStr
  if kind notin ["csc", "entity", "part", "id"] or not nomeRin(j["vecchio"].getStr) or not nomeRin(j["nuovo"].getStr): return false
  case kind
  of "csc", "entity": result = j["blocco"].getStr == "" and j["dove"].getStr == ""
  of "part": result = nomeRin(j["blocco"].getStr) and j["dove"].getStr == "entita"
  else: result = nomeRin(j["blocco"].getStr) and j["dove"].getStr in ["csc", "entita"]

proc messaggioValido(j: JsonNode): bool =
  ## Il ponte accetta solo le cinque azioni del banco, con i campi esatti, tutti stringhe e di forma ammessa.
  if j.kind != JObject or not (j.hasKey("azione") and j["azione"].kind == JString): return false
  proc nome(k: string): bool = nomeValido(j[k].getStr)
  case j["azione"].getStr
  of "cartella_scegli", "cartella_togli":
    result = campiEsatti(j, ["azione", "indice"]) and cifre(j["indice"].getStr)
  of "cartella_aggiungi":
    result = campiEsatti(j, ["azione", "indice"]) and j["indice"].getStr == "0"
  of "ricarica":
    result = campiEsatti(j, ["azione"])
  of "apri_rif":
    result = campiEsatti(j, ["azione", "file", "chiave"]) and j["file"].getStr.len in 1 .. 255 and j["chiave"].getStr.len in 1 .. 400
  of "nuova_entita":
    result = campiEsatti(j, ["azione", "nome", "scopo"]) and nome("nome") and j["scopo"].getStr.len <= 200
  of "pubblico":
    result = campiEsatti(j, ["azione", "entita", "csc", "lato"]) and nome("entita") and nome("csc") and j["lato"].getStr in ["OFFERS", "USES"]
  of "collega":
    result = campiEsatti(j, ["azione", "entita", "altra", "csc", "offre"]) and nome("entita") and nome("altra") and nome("csc") and nome("offre") and
      j["offre"].getStr in [j["entita"].getStr, j["altra"].getStr]
  of "parte":
    result = campiEsatti(j, ["azione", "entita", "parte", "tipo", "scopo"]) and nome("entita") and nome("parte") and nome("tipo") and
      j["scopo"].getStr.len <= 200
  of "passa":
    result = campiEsatti(j, ["azione", "entita", "csc", "lato", "parte"]) and nome("entita") and nome("csc") and nome("parte") and
      j["lato"].getStr in ["OFFERS", "USES"]
  of "connettore":
    result = campiEsatti(j, ["azione", "entita", "csc", "offre", "usa"]) and nome("entita") and nome("csc") and nome("offre") and nome("usa")
  of "scollega_passaggio":
    result = campiEsatti(j, ["azione", "entita", "csc", "lato", "parte"]) and nome("entita") and nome("csc") and nome("parte") and
      j["lato"].getStr in ["OFFERS", "USES"]
  of "scollega_accoppiamento":
    result = campiEsatti(j, ["azione", "entita", "csc", "offre", "usa"]) and nome("entita") and nome("csc") and nome("offre") and nome("usa")
  of "togli_parte":
    result = campiEsatti(j, ["azione", "entita", "parte"]) and nome("entita") and nome("parte")
  of "porta_fuori":
    result = campiEsatti(j, ["azione", "entita", "parte"]) and nome("entita") and nome("parte")
  of "metti_dentro":
    result = campiEsatti(j, ["azione", "entita", "dentro", "posto"]) and nome("entita") and nome("dentro") and nome("posto")
  of "sposta":
    result = campiEsatti(j, ["azione", "da", "posto", "a", "nuovo"]) and nome("da") and nome("posto") and nome("a") and nome("nuovo")
  of "togli_entita":
    result = campiEsatti(j, ["azione", "entita"]) and nome("entita")
  of "togli_pubblico":
    result = campiEsatti(j, ["azione", "entita", "csc", "lato"]) and nome("entita") and nome("csc") and j["lato"].getStr in ["OFFERS", "USES"]
  of "scheda_scopo":
    result = campiEsatti(j, ["azione", "tipo", "nome", "frase"]) and schedaBase(j) and j["frase"].getStr.len <= 200
  of "scheda_aggiungi", "scheda_cambia":
    result = campiEsatti(j, campiScheda) and schedaBase(j) and j["genere"].getStr in ["promessa", "ipotesi", "evento", "stato"] and
      campiDichOk(j) and (j["azione"].getStr == "scheda_aggiungi" or (cifre(j["riga"].getStr) and j["vecchio"].getStr.len in 1 .. 64))
  of "scheda_togli":
    result = campiEsatti(j, ["azione", "tipo", "nome", "genere", "riga", "vecchio"]) and schedaBase(j) and
      j["genere"].getStr in ["promessa", "ipotesi", "evento", "stato"] and cifre(j["riga"].getStr) and j["vecchio"].getStr.len in 1 .. 64
  of "casella_scrivi":
    result = campiEsatti(j, ["azione", "tipo", "nome", "da", "a", "prima", "testo"]) and schedaBase(j) and cifre(j["da"].getStr) and
      cifre(j["a"].getStr) and j["prima"].getStr.len <= maxTestoCasella and j["testo"].getStr.len <= maxTestoCasella
  of "blocco_scrivi":
    result = campiEsatti(j, ["azione", "file", "da", "a", "prima", "testo"]) and j["file"].getStr.len in 5 .. 120 and cifre(j["da"].getStr) and
      cifre(j["a"].getStr) and j["prima"].getStr.len <= maxTestoCasella and j["testo"].getStr.len <= maxTestoCasella
  of "blocco_crea":
    result = campiEsatti(j, ["azione", "cosa", "csc", "nome"]) and j["cosa"].getStr in ["forme", "piano"] and nome("csc") and j["nome"].getStr.len <= 64
  of "profilo_crea":
    result = campiEsatti(j, ["azione", "nome", "scopo"]) and nome("nome") and j["scopo"].getStr.len <= 200
  of "profilo_togli":
    result = campiEsatti(j, ["azione", "nome"]) and nome("nome")
  of "approva_blocco":
    result = campiEsatti(j, ["azione", "file", "csc", "modo", "decisione"]) and j["file"].getStr.len in 5 .. 120 and nome("csc") and
      j["modo"].getStr in ["forme", "profilo"] and decisioneOk(j["decisione"].getStr)
  of "nuova_versione":
    result = j.len == 6 and j.hasKey("righe") and j["righe"].kind == JArray and j["righe"].len <= 60
    if result:
      var senzaRighe = newJObject()
      for k, v in j:
        if k != "righe": senzaRighe[k] = v
      result = campiEsatti(senzaRighe, ["azione", "tipo", "nome", "versione", "frase"]) and schedaBase(j) and
        j["versione"].getStr.len <= 24 and j["frase"].getStr.len <= 800
    if result:
      for x in j["righe"]:
        if x.kind != JString or not idRigaOk(x.getStr): return false
  of "rinomina_anteprima":
    result = rinomValido(j, false)
  of "rinomina_scrivi":
    result = rinomValido(j, true)
  of "rinomina_ripristina":
    result = campiEsatti(j, ["azione", "indice"]) and cifre(j["indice"].getStr)
  of "lingua":
    result = campiEsatti(j, ["azione", "lingua"]) and j["lingua"].kind == JString and j["lingua"].getStr in ["it", "en"]
  of "annulla":
    result = campiEsatti(j, ["azione"])
  of "csc_nuova":
    result = (campiEsatti(j, ["azione", "nome"]) or campiEsatti(j, ["azione", "nome", "scopo"])) and nome("nome") and
      (not j.hasKey("scopo") or (j["scopo"].kind == JString and j["scopo"].getStr.len <= 1000))
  of "togli_csc":
    result = campiEsatti(j, ["azione", "nome"]) and nome("nome")
  of "completa_avvia":
    # 005:2:8 con `modello` (veloce o accurato) solo al tempo 1; un altro valore non passa
    result = (campiEsatti(j, ["azione", "tipo", "nome"]) or (campiEsatti(j, ["azione", "tipo", "nome", "modello"]) and j["modello"].getStr in ["veloce", "accurato"])) and schedaBase(j)
  of "completa_riprendi", "completa_chiudi":
    result = campiEsatti(j, ["azione", "tipo", "nome"]) and schedaBase(j)
  of "completa_ferma":
    result = campiEsatti(j, ["azione"])
  of "approva_intero":
    result = campiEsatti(j, ["azione", "tipo", "nome", "decisione"]) and j["tipo"].getStr == "csc" and schedaBase(j) and
      decisioneOk(j["decisione"].getStr)
  of "approva_righe":
    result = j.len == 5 and j.hasKey("righe") and j["righe"].kind == JArray and j["righe"].len in 1 .. 60
    if result:
      var senzaRighe = newJObject()
      for k, v in j:
        if k != "righe": senzaRighe[k] = v
      result = campiEsatti(senzaRighe, ["azione", "tipo", "nome", "decisione"]) and schedaBase(j) and decisioneOk(j["decisione"].getStr)
    if result:
      for x in j["righe"]:
        if x.kind != JString or not idRigaOk(x.getStr): return false
  of "completa_risposte":
    result = campiBase(j, "risposte") and j["risposte"].kind == JArray and j["risposte"].len <= 20 and schedaBase(j)
    if result:
      for r in j["risposte"]:
        if r.kind != JObject or r.len != 2 or not r.hasKey("n") or r["n"].kind != JInt or r["n"].getInt notin 1 .. 20: return false
        if r.hasKey("scelta"):
          if r["scelta"].kind != JInt or r["scelta"].getInt notin 1 .. 20: return false
        elif r.hasKey("testo"):
          if r["testo"].kind != JString or r["testo"].getStr.len notin 1 .. 1200: return false
        else: return false
  of "completa_scrivi":
    result = campiBase(j, "accettate") and j["accettate"].kind == JArray and j["accettate"].len <= 60 and schedaBase(j)
    if result:
      for x in j["accettate"]:
        if x.kind != JString: return false
        let t = x.getStr
        if t.len notin 2 .. 5 or t[0] notin {'p', 's', 'i'} or t[1] notin {'1' .. '9'} or not t[1 .. ^1].allCharsInSet({'0' .. '9'}): return false
  else: result = false

proc lato(j: JsonNode): string =
  ## La parola dell'interfaccia per il lato di un connettore pubblico: (offerto) o (usato).
  tx(if j["lato"].getStr == "OFFERS": kLatoOfferto else: kLatoUsato)

proc descrivi(j: JsonNode): string =
  ## Una frase breve per dire a quale azione si torna indietro (nella lingua corrente: il catalogo dell'editor).
  let s = proc (x: string): string = j[x].getStr
  case s("azione")
  of "nuova_entita": tx(kDNuovaEntita, s("nome"))
  of "pubblico": tx(kDPubblico, s("csc"), lato(j), s("entita"))
  of "parte": tx(kDParte, s("parte"), s("entita"))
  of "passa": tx(kDPassa, s("csc"), lato(j), s("parte"))
  of "connettore": tx(kDConnettore, s("csc"), s("entita"))
  of "collega": tx(kDCollega, s("entita"), s("altra"), s("csc"))
  of "scollega_passaggio": tx(kDScollegaPassaggio, s("csc"), s("parte"))
  of "scollega_accoppiamento": tx(kDScollegaAccoppiamento, s("csc"), s("offre"), s("usa"))
  of "togli_parte": tx(kDTogliParte, s("parte"), s("entita"))
  of "porta_fuori": tx(kDPortaFuori, s("parte"), s("entita"))
  of "metti_dentro": tx(kDMettiDentro, s("entita"), s("dentro"), s("posto"))
  of "sposta": tx(kDSposta, s("posto"), s("da"), s("a"))
  of "togli_entita": tx(kDTogliEntita, s("entita"))
  of "togli_pubblico": tx(kDTogliPubblico, s("csc"), lato(j), s("entita"))
  of "csc_nuova": tx(kDCscNuova, s("nome"))
  of "togli_csc": tx(kDTogliCsc, s("nome"))
  of "completa_scrivi": tx(kDCompletaScrivi, s("nome"))
  of "approva_righe": tx(kDApprovaRighe, j["righe"].getElems.mapIt(it.getStr).join(", "), s("nome"))
  of "approva_intero": tx(kDApprovaIntero, s("nome"))
  of "casella_scrivi":
    let n1 = s("da")
    let n2 = s("a")
    let tolta = s("testo").strip.len == 0
    if n1 == n2: tx(if tolta: kDCasellaRigaTolta else: kDCasellaRigaCambiata, n1, s("nome"))
    else: tx(if tolta: kDCasellaRigheTolte else: kDCasellaRigheCambiate, n1, n2, s("nome"))
  of "nuova_versione": tx(kDNuovaVersione, s("versione"), s("nome"))
  of "blocco_scrivi":
    let n1 = s("da")
    let n2 = s("a")
    let tolta = s("testo").strip.len == 0
    if n1 == n2: tx(if tolta: kDBloccoRigaTolta else: kDBloccoRigaCambiata, n1, s("file"))
    else: tx(if tolta: kDBloccoRigheTolte else: kDBloccoRigheCambiate, n1, n2, s("file"))
  of "blocco_crea": tx(if s("cosa") == "forme": kDBloccoCreaForme else: kDBloccoCreaPiano, s("csc"))
  of "profilo_crea": tx(kDProfiloCrea, s("nome"))
  of "profilo_togli": tx(kDProfiloTogli, s("nome"))
  of "approva_blocco": tx(if s("modo") == "forme": kDApprovaBloccoForme else: kDApprovaBloccoProfilo, s("csc"))
  of "scheda_scopo": tx(kDSchedaScopo, s("nome"))
  of "scheda_aggiungi", "scheda_cambia", "scheda_togli":
    let id = if s("azione") == "scheda_aggiungi": (if idScritto.len > 0: " " & idScritto else: "") else: " " & s("vecchio")
    case s("genere")
    of "promessa":
      case s("azione")
      of "scheda_aggiungi": tx(kDSchedaPromessaAggiungi, id, s("nome"))
      of "scheda_cambia": tx(kDSchedaPromessaCambia, id, s("nome"))
      else: tx(kDSchedaPromessaTogli, id, s("nome"))
    of "ipotesi":
      case s("azione")
      of "scheda_aggiungi": tx(kDSchedaIpotesiAggiungi, id, s("nome"))
      of "scheda_cambia": tx(kDSchedaIpotesiCambia, id, s("nome"))
      else: tx(kDSchedaIpotesiTogli, id, s("nome"))
    of "evento":
      case s("azione")
      of "scheda_aggiungi": tx(kDSchedaEventoAggiungi, id, s("nome"))
      of "scheda_cambia": tx(kDSchedaEventoCambia, id, s("nome"))
      else: tx(kDSchedaEventoTogli, id, s("nome"))
    else:
      case s("azione")
      of "scheda_aggiungi": tx(kDSchedaStatoAggiungi, id, s("nome"))
      of "scheda_cambia": tx(kDSchedaStatoCambia, id, s("nome"))
      else: tx(kDSchedaStatoTogli, id, s("nome"))
  else: s("azione")

proc alMessaggio(testo: string) {.nimcall.} =
  var j: JsonNode
  try: j = parseJson(testo)
  except CatchableError: return
  if not messaggioValido(j): return
  traccia("azione " & j["azione"].getStr)
  let az = j["azione"].getStr
  if az == "completa_ferma":
    if asincronoInCorso():
      refFermato = true
      fermaAsincrono()
    return
  if asincronoInCorso(): return                 # mentre l'LLM lavora si può solo fermarlo
  if az == "rinomina_anteprima":
    eseguiRinomina(j, false)
    return
  if az == "rinomina_scrivi":
    eseguiRinomina(j, true)
    return
  if az == "rinomina_ripristina":
    ripristinaRinomina(parseInt(j["indice"].getStr))
    return
  if az in ["completa_avvia", "completa_risposte"]:
    let gb0 = giornaleBlocca()                   # `refine` con un giornale presente non scrive e non chiama il modello; l'editor non lo lancia
    if gb0.len > 0:
      consegnaRefine(1, 255, "", gb0)
      return
  if az in ["completa_avvia", "completa_riprendi", "completa_risposte"]:
    let file = if j["tipo"].getStr == "entita": fileDiEntita(j["nome"].getStr) else: fileDiCsc(j["nome"].getStr)
    if file.len == 0:
      refFermato = false
      consegnaRefine(1, 255, "", tx(kNonTrovoCartella, j["nome"].getStr))
    elif az == "completa_avvia":
      avviaRefine(1, @["refine", "--json", file, "--csc", j["nome"].getStr] & (if j.hasKey("modello"): @["--modello", j["modello"].getStr] else: @[]), "")
    elif az == "completa_riprendi":
      avviaRefine(0, @["refine", "--json", file, "--csc", j["nome"].getStr, "--show"], "")   # tempo 0: rimostra, nessuna chiamata all'LLM
    else:
      avviaRefine(2, @["refine", "--json", "--answers", file], $(%*{"risposte": j["risposte"]}))
    return
  if az in ["cartella_scegli", "cartella_togli", "cartella_aggiungi"]:
    gestisciCartelle(j)
    return
  if az == "apri_rif":
    # : «Apri il file» e «Apri nel browser». Si apre solo ciò che il modello ha risolto (un `.md` letto o un
    # indirizzo http(s) di una definizione): la pagina manda la chiave, mai un percorso. Niente `rinfresca`: non cambia niente.
    let bersaglio = apribili.getOrDefault(j["file"].getStr & "\0" & j["chiave"].getStr)
    if bersaglio.len == 0: traccia("apri_rif unknown")
    else:
      when defined(bcddEditorProva):
        traccia("apri_rif " & bersaglio)               # la versione di prova non lancia niente
      else:
        if not apriEsterno(bersaglio): traccia("apri_rif failed")
    return
  if az == "ricarica":
    azzeraRif()
    # : comando manuale, sempre: si butta la memoria dei controlli, si rilegge tutto e si ridisegna (aggiorna `ultimaFirma`).
    # Nessun timer: parte solo dal clic. Con una modifica non salvata la scelta l'ha già fatta la pagina (garanzia e-9).
    memo.voci.clear()
    memo.digest = ""
    rinfresca(esitoJson(true, tx(kRicaricato)))
    return
  if az == "lingua":
    # : la scelta è subito applicata (bcdd rilanciato con la lingua nuova su tutti i file, pagina ridisegnata col dizionario
    # nuovo), ricordata nel file di configurazione; se non si riesce a scrivere vale per la finestra aperta e lo Stato lo dice.
    lingua = if j["lingua"].getStr == "it": lgIt else: lgEn
    let ricordata = ricordaLingua(lingua)
    rinfresca(esitoJson(true, tx(kLinguaCambiata, if lingua == lgIt: "Italiano" else: "English") & (if ricordata: "" else: "; " & tx(kLinguaRicordataNo))))
    return
  let gb = giornaleBlocca()                       # : con un giornale presente nessuna azione scrive
  if gb.len > 0:
    rinfresca(esitoJson(false, gb))
    return
  completaEsito = nil
  scritti = @[]
  tolti = @[]
  dentroDopo = false
  modifiche = @[]
  notaEsito = ""
  idScritto = ""
  rifCasella = RifCasella()
  let errore = eseguiAzione(j)
  if j["azione"].getStr != "annulla" and modifiche.len > 0:
    # anche un'azione fermata a metà ha scritto dei file: l'annullamento li riguarda
    ultima = modifiche
    descrUltima = descrivi(j)
    ultimaVersione = az == "nuova_versione"
  let esito = if errore.len > 0: esitoJson(false, errore)
    else: esitoJson(true, (if scritti.len > 0: tx(kEsitoScrittiIFile, scritti.join(", ")) else: (if tolti.len > 0: "" else: tx(kEsitoFatto))) &
      (if tolti.len > 0: (if scritti.len > 0: "; " else: "") & (if tolti.len == 1: tx(kEsitoToltoIlFile, tolti[0]) else: tx(kEsitoToltiIFile, tolti.join(", "))) else: "") &
      (if notaEsito.len > 0: "; " & notaEsito else: ""))
  rinfresca(esito)

proc allaChiusa() {.nimcall.} =
  # una finestra chiusa mentre l'LLM lavora ferma anche bcdd; il giro resta aperto e alla prossima apertura si riprende o si chiude
  fermaAsincrono()

proc esci(msg: string, codice = 2) =
  segnalaErrore msg
  quit(codice)

proc apriFinestra*(a: Argomenti) =
  ## 005:5:1 Il programma: prima scansione (senza finestra), poi GTK. Codici d'uscita: 2 per ogni caso che non apre.
  ## Le cartelle sono quelle di `a.dirs`, rese assolute prima di ogni cambio di cartella corrente.
  for d in a.dirs: cartelle.add percorsoPulito(d)
  titoloCartella = titoloDa(a.dirs[0])
  programma = getAppDir() / nomeBcdd
  var eseguibile = fileExists(programma)
  when not defined(windows):
    if eseguibile:
      try: eseguibile = fpUserExec in getFilePermissions(programma)
      except OSError: eseguibile = false
  if not eseguibile: esci(tx(kEsciNonTrovoBcdd, getAppDir()) & "\n")
  for k, d in a.dirs:
    if not dirExists(cartelle[k]): esci(tx(kEsciCartellaNonTrovata, d) & "\n")
    try: setCurrentDir(cartelle[k])
    except OSError: esci(tx(kEsciCartellaNonLeggibile, d) & "\n")
  cartellaSel = 0
  traccia("apertura cartelle=" & $cartelle.len)
  let (c, m) = scansiona()
  if m.len > 0: esci(m & "\n")
  caricati = c
  if a.nome.len > 0:
    if fileDiEntita(a.nome).len == 0: esci(tx(kEsciNessunaEntita, a.nome, titoloCartella) & "\n")
    daSelezionare = a.nome
  var sc = Scheda(titolo: "bcdd-editor: " & titoloCartella, html: paginaHtmlBase.replace("/*LINGUA*/", $lingua), script: @[paginaJs])
  when defined(bcddEditorProva):
    sc.dimensioniProva = getEnv("BCDD_EDITOR_PROVA_DIM")
    sc.script.add provaJs
    if portaSonda.len > 0: sc.script.add sondaReteJs(portaSonda)
  var g: Gestori
  g.messaggio = alMessaggio
  g.attiva = alCambioFuoco
  g.caricata = allaCaricata
  g.chiusa = allaChiusa
  if apri(sc, g) == "display": esci(tx(kEsciDisplay) & "\n")
