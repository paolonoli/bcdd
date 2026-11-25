# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 100:1:1 L'uscita di `bcdd check --json` (BcddProgrammi p-1 … p-4, F4a).
# 100:1:2 Il modulo legge un Report e scrive un solo oggetto JSON: non tocca file, non chiama processi.
# 100:1:3 (1.23: tipo di riga non_letta, conteggi.non_lette e blocchi_non_letti[] sono aggiunti: la versione resta 4)
# 100:1:3 (1.21: i campi varianti, variante, in, ha_composizioni, composizioni, assenze sono aggiunti: la versione resta 4)
# 100:1:3 Forma "bcdd-check", versione 3 (garanzie e ipotesi solo in `garanzie[]`, mai in `dichiarazioni[]`). Aggiungere un campo non cambia la versione; toglierlo o cambiarne
# 100:1:4 il significato sì (p-4). Le chiavi escono sempre nello stesso ordine: la stessa lettura, la stessa uscita (p-3).
import std/[strutils, tables, algorithm]
import checksums/sha2
import bcddcheck, bcddtesti

const
  FormaCheck* = "bcdd-check"
  VersioneCheck* = 5

proc jstr*(s: string): string =
  ## 100:2:1 Stringa JSON (RFC 8259): escape di virgolette, barra e controlli; il resto UTF-8 com'è.
  result = "\""
  for c in s:
    case c
    of '"': result.add "\\\""
    of '\\': result.add "\\\\"
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    of '\b': result.add "\\b"
    of '\f': result.add "\\f"
    of '\0' .. '\7', '\v', '\14' .. '\31', '\127':
      result.add "\\u00" & toHex(ord(c), 2).toLowerAscii
    else: result.add c
  result.add "\""

proc jnum(n: int): string = $n
proc jbool(b: bool): string = (if b: "true" else: "false")
proc jlevel(n: int): string = (if n < 0: "null" else: $n)
proc jnullStr(s: string): string = (if s.len == 0: "null" else: jstr(s))
proc jobj(fields: openArray[(string, string)]): string =
  var parts: seq[string]
  for (k, v) in fields: parts.add jstr(k) & ": " & v
  "{" & parts.join(", ") & "}"
proc jarr(items: seq[string]): string =
  if items.len == 0: "[]" else: "[\n    " & items.join(",\n    ") & "\n  ]"
proc jarrInline(items: seq[string]): string = "[" & items.join(", ") & "]"

proc jvariante(b: BlockInfo, piece: int): string =
  ## 100:2:5 (1.21) Il pezzo VARIANT di una riga: null per una riga comune; un pezzo scritto male ha dimensione e scelta null.
  if piece == 0: return "null"
  let p = b.pieces[piece - 1]
  if p.valid: jobj({"dimensione": jstr(p.dim), "scelta": jstr(p.choice)})
  else: jobj({"dimensione": "null", "scelta": "null"})

proc fingerprint*(raw: string): string =
  ## 100:2:2 L'impronta di tutti i byte del file letto, prima di ogni normalizzazione.
  "sha256:" & $secureHash(Sha_256, raw)

proc statoBlocco(b: BlockInfo): string = statusCode(b)

proc jstatoBlocco(f: Found): string =
  ## 100:2:6 Il codice dello stato del blocco trovato, uguale in ogni lingua; null per una VERIFICATION.
  if f.blk.bk == "VERIFICATION": "null" else: jstr(f.statoBlocco)

proc lineText(rep: Report, a, b: int): string =
  ## 100:2:3 Il testo di una dichiarazione: le sue righe, come nel file, unite da LF.
  var ls: seq[string]
  for n in a .. b:
    if n >= 1 and n <= rep.srcLines.len: ls.add rep.srcLines[n - 1]
  ls.join("\n")

proc detailLevel(b: BlockInfo, rows: seq[RowInfo], bi: int, r: RowInfo): int =
  ## 100:2:4 Livello di DETAILS: 0 per una riga che non dettaglia, 1 per un dettaglio di una riga di livello 0, …
  ## : -1 ("senza livello", `null` nel JSON) se la risalita non arriva a una riga senza DETAILS
  ## dello stesso blocco: riga nominata inesistente (E02) o giro (E05), anche indiretto.
  var cur = r
  var steps = 0
  while cur.detailsOf.len > 0:
    if steps > rows.len: return -1
    inc steps
    var found = false
    for x in rows:
      if x.blockIdx == bi and x.id == cur.detailsOf:
        cur = x
        found = true
        break
    if not found: return -1
  steps

proc gradeJson(g: Grade): string =
  case g
  of grVerbal: "verbale"
  of grFormal: "formale"
  of grExt: "estensione_dichiarata"
  of grUnrec: "non_riconosciuta"

proc renderJson*(rep: Report, fileName, raw: string, strict: bool, code: int): string =
  ## 100:1:5 Un solo oggetto JSON, con un LF in fondo. `code` è il codice d'uscita già calcolato dal chiamante.
  var o = "{\n"
  proc field(k, v: string, last = false) =
    o.add "  " & jstr(k) & ": " & v & (if last: "\n" else: ",\n")
  field "forma", jstr(FormaCheck)
  field "versione", jnum(VersioneCheck)
  field "lingua", jstr($lingua)
  field "file", jstr(fileName)
  field "impronta", jstr(fingerprint(raw))
  var dirs: seq[string]
  for d in rep.dirs: dirs.add jstr(d)
  field "opzioni", jobj({"strict": jbool(strict), "dir": jarrInline(dirs)})
  # 100:1:6 Le righe
  var rows: seq[string]
  for i, t in rep.srcLines:
    let tipo = case rep.lineClass[i]
      of 'r': "riconosciuta"
      of 'c': "commento"
      of 'v': "vuota"
      else: "non_riconosciuta"
    rows.add jobj({"n": jnum(i + 1), "tipo": jstr(tipo), "testo": jstr(t)})
  field "righe", jarr(rows)
  # 100:1:7 I blocchi
  var blocks: seq[string]
  for bi, b in rep.blocks:
    var decls, guars, cites: seq[string]
    var citeKey: seq[int]
    for k, c in b.xcites:
      if k >= b.xfound.len or not b.xfound[k].ok: continue
      let f = b.xfound[k]
      let tipoC = case c.kind
        of ckImport: "IMPORT"
        of ckLegata: "LEGATA"
        else: "USING"
      cites.add jobj({"riga": jnum(c.line), "tipo": jstr(tipoC), "parte": jnullStr(if c.kind == ckUsing: c.part else: ""), "nome": jstr(c.name),
        "versione_citata": jnullStr(c.version),
        "trovata": jobj({"dove": jnullStr(f.where), "percorso": jnullStr(f.path), "riga": jnum(f.line), "versione": jstr(f.version),
          "stato": jstr(f.statusText), "stato_blocco": jstatoBlocco(f), "errori": jnum(f.errCount), "non_riconosciute": jnum(f.unrec)}),
        "variante": "null"})
      citeKey.add c.line
    for n in b.names:
      # 100:1:9 il tipo interno ROW sono le GUARANTEE e le ASSUME, già in `garanzie[]`: qui non compare.
      if n.kind == "ROW": continue
      let last = rep.spans.getOrDefault(n.line, n.line)
      decls.add jobj({"riga": jnum(n.line), "fino": jnum(last), "tipo": jstr(n.kind), "nome": jstr(n.name),
        "testo": jstr(lineText(rep, n.line, last)), "variante": jvariante(b, n.piece)})
    for r in rep.rows:
      if r.blockIdx != bi: continue
      let dec = if r.contract: (if r.own == skRat: r.decision else: b.decision) else: ""
      # 022:2:1 in un blocco con E09 lo stato segue l'intestazione, che non è valida (prima dello STATUS della riga)
      let stato_di = if not b.headerOk: "intestazione_non_valida" elif r.profHyp: "profilo" elif r.own != skNone: "suo" elif r.detailsOf.len > 0: "dettaglio" else: "intestazione"
      guars.add jobj({"da": jnum(r.line), "a": jnum(r.lastLine), "tipo": jstr(r.kw), "id": jstr(r.id),
        "dettaglia": jnullStr(r.detailsOf), "livello": jlevel(detailLevel(b, rep.rows, bi, r)),
        "grado": jstr(gradeJson(r.grade)),
        "stato": jstr(if r.contract: "contratto" else: "ipotesi"), "decisione": jnullStr(dec),
        "stato_di": jstr(stato_di), "testo": jstr(lineText(rep, r.line, r.lastLine)), "variante": jvariante(b, r.piece)})
    if b.isEntity:
      for k, c in b.cites:
        if c.dup or k >= b.found.len or not b.found[k].ok: continue
        let f = b.found[k]
        let tipo = case c.kind
          of ckOffers: "OFFERS"
          of ckUses: "USES"
          of ckPart: "PART"
          of ckImport: "IMPORT"
          of ckLegata: "LEGATA"
          of ckUsing: "USING"
        var fields = @[("riga", jnum(c.line)), ("tipo", jstr(tipo)), ("parte", jnullStr(c.part)), ("nome", jstr(c.name)),
          ("versione_citata", jnullStr(c.version))]
        # 100:1:11 (1.20, G35) solo le parti: la molteplicità scritta, {"min": m, "max": n}, oppure null
        if c.kind == ckPart:
          fields.add ("molteplicita", (if c.hasMult: jobj({"min": c.multMin, "max": c.multMax}) else: "null"))
        fields.add ("trovata", jobj({"dove": jnullStr(f.where), "percorso": jnullStr(f.path), "riga": jnum(f.line), "versione": jstr(f.version),
          "stato": jstr(f.statusText), "stato_blocco": jstatoBlocco(f), "errori": jnum(f.errCount), "non_riconosciute": jnum(f.unrec)}))
        fields.add ("variante", jvariante(b, c.piece))
        cites.add jobj(fields)
        citeKey.add c.line
    block:
      var ordc = newSeq[int](cites.len)
      for i in 0 ..< ordc.len: ordc[i] = i
      ordc.sort(proc(x, y: int): int =
        result = cmp(citeKey[x], citeKey[y])
        if result == 0: result = cmp(x, y))
      var sorted: seq[string]
      for i in ordc: sorted.add cites[i]
      cites = sorted
    # 100:1:10 Il PURPOSE del blocco: righe da `riga` a `fino` come nel file, null senza PURPOSE
    let scopo = if b.purposeLine == 0: "null" else:
      let last = rep.spans.getOrDefault(b.purposeLine, b.purposeLine)
      jobj({"riga": jnum(b.purposeLine), "fino": jnum(last), "testo": jstr(lineText(rep, b.purposeLine, last)),
        "da_compilare": jbool(purposeDaCompilare(lineText(rep, b.purposeLine, b.purposeLine)))})
    let tipo = if b.isView: "REFINEMENT VIEW" else: b.bk
    var bf = @[("tipo", jstr(tipo)), ("nome", jstr(b.name)), ("versione", jnullStr(b.version)),
      ("intestazione_valida", jbool(b.headerOk)), ("da", jnum(b.line)), ("a", jnum(b.endLine)),
      ("stato", (if b.bk == "VERIFICATION": "null" else: jstr(statoBlocco(b)))), ("decisione", jnullStr(b.decision)), ("scopo", scopo),
      ("dichiarazioni", jarrInline(decls)), ("garanzie", jarrInline(guars)), ("citazioni", jarrInline(cites))]
    if b.bk in ["BINDING", "VERIFICATION"]:
      bf.add ("legata", jobj({"nome": jstr(b.legataName), "versione": jstr(b.legataVer)}))
      if b.bk == "BINDING": bf.add ("nome_proprio", jnullStr(b.ownName))
    if b.bk == "PROFILE":
      var es: seq[string]
      for e in b.exts:
        if e.def.name.len == 0: continue
        es.add jobj({"nome": jstr(e.def.name), "da": jnum(e.line), "a": jnum(rep.spans.getOrDefault(e.line, e.line)),
          "kind": jnullStr(e.def.kind), "level": jnullStr(e.def.level), "riduzione": jbool(e.def.hasRed)})
      bf.add ("estensioni", jarrInline(es))
    if b.isEntity:
      # 100:1:12 (1.21) le righe VARIANT riconosciute (G38), in ordine di riga
      var vs: seq[string]
      for pc in b.pieces:
        if pc.valid: vs.add jobj({"riga": jnum(pc.line), "dimensione": jstr(pc.dim), "scelta": jstr(pc.choice)})
      bf.add ("varianti", jarrInline(vs))
    blocks.add jobj(bf)
  field "blocchi", jarr(blocks)
  # 100:1:8 Il rapporto: le stesse cose del rapporto per le persone (p-1)
  var nv, nu, nf, nx = 0
  for g in rep.grades:
    case g.grade
    of grVerbal: inc nv
    of grFormal: inc nf
    of grExt: inc nx
    of grUnrec: inc nu
  var errs, grades, und, hyps, unrec, undecl, nom, usi: seq[string]
  for e in rep.errs:
    errs.add jobj({"riga": jnum(e.line), "codice": jstr(e.code), "messaggio": jstr(e.msg), "in": jnullStr(e.inn)})
  for g in rep.grades:
    grades.add jobj({"riga": jnum(g.line), "tipo": jstr(g.kw), "id": jstr(g.id),
      "grado": jstr(gradeJson(g.grade))})
  for (l, n) in rep.undecided: und.add jobj({"riga": jnum(l), "nome": jstr(n)})
  for (l, k, id) in rep.hyps: hyps.add jobj({"riga": jnum(l), "tipo": jstr(k), "id": jstr(id)})
  for (l, t) in rep.unrecText:
    var mot = ""
    var tx = t
    if l in rep.unrecMotive and tx.endsWith(" (" & rep.unrecMotive[l] & ")"):
      mot = rep.unrecMotive[l]
      tx = tx[0 ..< tx.len - mot.len - 3]
    unrec.add jobj({"riga": jnum(l), "testo": jstr(tx), "motivo": jnullStr(mot)})
  for n in rep.undeclOrder:
    var ls: seq[string]
    for l in rep.undeclLines[n]: ls.add jnum(l)
    undecl.add jobj({"nome": jstr(n), "righe": jarrInline(ls)})
  var nm = rep.notFound
  nm.sort(proc(a, b: NonControllata): int = cmp(a.line, b.line))
  for n in nm:
    nom.add jobj({"riga": jnum(n.line), "testo": jstr(ncTesto(n)), "tipo": jstr(n.tipo), "nome": jstr(n.nome),
      "motivo": jnullStr(n.motivo)})
  for u in rep.usi:
    var off: seq[string]
    for (pt, rg) in u.offeredBy: off.add jobj({"parte": jstr(pt), "riga": jnum(rg)})
    usi.add jobj({"riga": jnum(u.line), "testo": jstr(u.text), "parte": jstr(u.part), "nome": jstr(u.name),
      "versione": jnullStr(u.version), "esito": jstr(u.esito), "offerta_da": jarrInline(off),
      "da_fuori": (if u.fromOutside > 0: jnum(u.fromOutside) else: "null"),
      "parti_non_controllate": jnum(u.unchecked), "in": jnullStr(u.inn)})
  var comps, assenze, formeM, coperta, daGiud, nonEseg: seq[string]
  for fm in rep.forme:
    var es: seq[string]
    for x in fm.elementi: es.add jstr(x)
    formeM.add jobj({"riga": jnum(fm.line), "testo": jstr(formaTesto(fm)), "blocco": jstr(fm.head),
      "csc_trovata": jbool(fm.cscTrovata), "elementi": jarrInline(es)})
  for c in rep.copertura:
    var xs, ms, ne: seq[string]
    for x in coperturaRighe(c): xs.add jstr(x)
    for m in c.mezzi:
      var ps: seq[string]
      for p in m.promesse: ps.add jstr(p)
      ms.add jobj({"nome": jstr(m.name), "riga": jnum(m.line), "promesse": jarrInline(ps)})
    for x in c.nonEseguite: ne.add jstr(x)
    coperta.add jobj({"riga": jnum(c.line), "blocco": jstr(c.head), "righe": jarrInline(xs), "csc_trovata": jbool(c.cscTrovata),
      "mezzi": jarrInline(ms), "non_eseguite": jarrInline(ne)})
  for (l, v) in rep.daGiudicare: daGiud.add jobj({"riga": jnum(l), "testo": jstr(daGiudicareTesto(l, v)), "voce": jstr(v)})
  for (n, ls) in rep.nonEseg:
    var xs: seq[string]
    for l in ls: xs.add jnum(l)
    nonEseg.add jobj({"nome": jstr(nonEsegNome(n)), "righe": jarrInline(xs), "codice": jstr(n)})
  for c in rep.comps:
    var ns: seq[string]
    for n in c.names: ns.add jstr(n)
    comps.add jobj({"riga": jnum(c.line), "entita": jstr(c.name), "nomi": (if c.tooMany: "null" else: jarrInline(ns))})
  for a in rep.assenze:
    assenze.add jobj({"riga": jnum(a.line), "codice": jstr(a.code), "senza": jstr(a.senza), "messaggio": jstr(a.msg), "in": jnullStr(a.inn)})
  var e = esitoErrori(rep.errs.len)
  e.add esitoUnrec(rep, strict)
  let rapporto = "{\n    " & [
    jstr("conteggi") & ": " & jobj({"righe": jnum(rep.total), "riconosciute": jnum(rep.recLines),
      "commenti": jnum(rep.comLines), "vuote": jnum(rep.blankLines), "non_riconosciute": jnum(rep.unrecLines),
      "verbale": jnum(nv), "formale": jnum(nf), "estensione_dichiarata": jnum(nx), "non_riconosciuta": jnum(nu),
      "forme_mancanti": jnum(rep.nonEsegFormeCount), "non_eseguite_piano": jnum(rep.nonEseguite)}),
    jstr("errori") & ": " & jarrInline(errs),
    jstr("gradi") & ": " & jarrInline(grades),
    jstr("undecided") & ": " & jarrInline(und),
    jstr("ipotesi") & ": " & jarrInline(hyps),
    jstr("non_riconosciute") & ": " & jarrInline(unrec),
    jstr("tipi_non_dichiarati") & ": " & jarrInline(undecl),
    jstr("non_controllate") & ": " & jarrInline(nom),
    jstr("ha_entita") & ": " & jbool(rep.hasEntity),
    jstr("usi") & ": " & jarrInline(usi),
    jstr("ha_composizioni") & ": " & jbool(rep.comps.len > 0),
    jstr("composizioni") & ": " & jarrInline(comps),
    jstr("assenze") & ": " & jarrInline(assenze),
    jstr("ha_binding") & ": " & jbool(rep.hasBinding),
    jstr("ha_verification") & ": " & jbool(rep.hasVerification),
    jstr("forme_mancanti") & ": " & jarrInline(formeM),
    jstr("copertura") & ": " & jarrInline(coperta),
    jstr("da_giudicare") & ": " & jarrInline(daGiud),
    jstr("non_eseguiti") & ": " & jarrInline(nonEseg)].join(",\n    ") & "\n  }"
  field "rapporto", rapporto
  field "esito", jobj({"errori": jnum(rep.errs.len), "codice": jnum(code), "riga": jstr(testo(kRapEsito, e))}), true
  o.add "}\n"
  o
