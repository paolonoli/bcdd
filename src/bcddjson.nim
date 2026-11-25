# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 090:1:1 Lettore JSON stretto (RFC 8259) per la risposta dell'LLM.
# 090:1:2 Si scrive qui perché std/json tiene in silenzio l'ultimo valore di una chiave ripetuta
# 090:1:3 (controllo 5) e non dà l'ordine delle chiavi nel testo. Nessuna tolleranza oltre la RFC.
import std/[strutils]

type
  JKind* = enum
    jNull, jBool, jNum, jStr, jArr, jObj

  JNode* = ref object
    kind*: JKind
    s*: string               # jStr: il testo decodificato (UTF-8)
    items*: seq[JNode]       # jArr
    keys*: seq[string]       # jObj: chiavi nell'ordine del testo
    vals*: seq[JNode]

  JResult* = object
    ok*: bool
    root*: JNode
    dupPath*: string         # percorso della prima chiave ripetuta nel testo; "" se nessuna

const MaxDepth = 64

type P = object
  s: string
  i: int
  dup: string

proc fail(): JNode = nil

proc skipWs(p: var P) =
  while p.i < p.s.len and p.s[p.i] in {' ', '\t', '\n', '\r'}: inc p.i

proc addUtf8(o: var string, cp: int) =
  if cp < 0x80: o.add char(cp)
  elif cp < 0x800:
    o.add char(0xC0 or (cp shr 6))
    o.add char(0x80 or (cp and 0x3F))
  elif cp < 0x10000:
    o.add char(0xE0 or (cp shr 12))
    o.add char(0x80 or ((cp shr 6) and 0x3F))
    o.add char(0x80 or (cp and 0x3F))
  else:
    o.add char(0xF0 or (cp shr 18))
    o.add char(0x80 or ((cp shr 12) and 0x3F))
    o.add char(0x80 or ((cp shr 6) and 0x3F))
    o.add char(0x80 or (cp and 0x3F))

proc hex4(p: var P, v: var int): bool =
  if p.i + 4 > p.s.len: return false
  v = 0
  for k in 0 ..< 4:
    let c = p.s[p.i + k]
    var d: int
    if c in {'0' .. '9'}: d = ord(c) - ord('0')
    elif c in {'a' .. 'f'}: d = ord(c) - ord('a') + 10
    elif c in {'A' .. 'F'}: d = ord(c) - ord('A') + 10
    else: return false
    v = v * 16 + d
  p.i += 4
  true

proc parseString(p: var P, o: var string): bool =
  ## 091:1:1 Da p.i sul '"' iniziale; decodifica le sequenze di escape; i codici sotto 0x20 non ammessi.
  inc p.i
  while true:
    if p.i >= p.s.len: return false
    let c = p.s[p.i]
    if c == '"':
      inc p.i
      return true
    if ord(c) < 0x20: return false
    if c != '\\':
      o.add c
      inc p.i
      continue
    inc p.i
    if p.i >= p.s.len: return false
    let e = p.s[p.i]
    inc p.i
    case e
    of '"': o.add '"'
    of '\\': o.add '\\'
    of '/': o.add '/'
    of 'b': o.add '\b'
    of 'f': o.add '\f'
    of 'n': o.add '\n'
    of 'r': o.add '\r'
    of 't': o.add '\t'
    of 'u':
      var v: int
      if not hex4(p, v): return false
      if v >= 0xD800 and v <= 0xDBFF:
        if not (p.i + 1 < p.s.len and p.s[p.i] == '\\' and p.s[p.i + 1] == 'u'): return false
        p.i += 2
        var lo: int
        if not hex4(p, lo): return false
        if lo < 0xDC00 or lo > 0xDFFF: return false
        addUtf8(o, 0x10000 + ((v - 0xD800) shl 10) + (lo - 0xDC00))
      elif v >= 0xDC00 and v <= 0xDFFF:
        return false
      else:
        addUtf8(o, v)
    else: return false

proc parseNumber(p: var P, txt: var string): bool =
  let s = p.s
  let start = p.i
  var i = p.i
  if i < s.len and s[i] == '-': inc i
  if i >= s.len: return false
  if s[i] == '0': inc i
  elif s[i] in {'1' .. '9'}:
    while i < s.len and s[i] in {'0' .. '9'}: inc i
  else: return false
  if i < s.len and s[i] == '.':
    inc i
    if not (i < s.len and s[i] in {'0' .. '9'}): return false
    while i < s.len and s[i] in {'0' .. '9'}: inc i
  if i < s.len and s[i] in {'e', 'E'}:
    inc i
    if i < s.len and s[i] in {'+', '-'}: inc i
    if not (i < s.len and s[i] in {'0' .. '9'}): return false
    while i < s.len and s[i] in {'0' .. '9'}: inc i
  p.i = i
  txt = s[start ..< i]       # 091:2:1 il testo del numero, per chi deve leggerlo (bcdd refine --json)
  true

proc parseValue(p: var P, path: string, depth: int): JNode =
  if depth > MaxDepth: return fail()
  skipWs(p)
  if p.i >= p.s.len: return fail()
  let c = p.s[p.i]
  case c
  of '{':
    inc p.i
    var n = JNode(kind: jObj)
    skipWs(p)
    if p.i < p.s.len and p.s[p.i] == '}':
      inc p.i
      return n
    while true:
      skipWs(p)
      if p.i >= p.s.len or p.s[p.i] != '"': return fail()
      var k = ""
      if not parseString(p, k): return fail()
      skipWs(p)
      if p.i >= p.s.len or p.s[p.i] != ':': return fail()
      inc p.i
      let kp = if path.len == 0: k else: path & "." & k
      if k in n.keys and p.dup.len == 0: p.dup = kp
      let v = parseValue(p, kp, depth + 1)
      if v == nil: return fail()
      n.keys.add k
      n.vals.add v
      skipWs(p)
      if p.i >= p.s.len: return fail()
      if p.s[p.i] == ',':
        inc p.i
        continue
      if p.s[p.i] == '}':
        inc p.i
        return n
      return fail()
  of '[':
    inc p.i
    var n = JNode(kind: jArr)
    skipWs(p)
    if p.i < p.s.len and p.s[p.i] == ']':
      inc p.i
      return n
    while true:
      let v = parseValue(p, path & "[" & $(n.items.len + 1) & "]", depth + 1)
      if v == nil: return fail()
      n.items.add v
      skipWs(p)
      if p.i >= p.s.len: return fail()
      if p.s[p.i] == ',':
        inc p.i
        continue
      if p.s[p.i] == ']':
        inc p.i
        return n
      return fail()
  of '"':
    var t = ""
    if not parseString(p, t): return fail()
    return JNode(kind: jStr, s: t)
  of 't':
    if p.s.continuesWith("true", p.i):
      p.i += 4
      return JNode(kind: jBool)
    return fail()
  of 'f':
    if p.s.continuesWith("false", p.i):
      p.i += 5
      return JNode(kind: jBool)
    return fail()
  of 'n':
    if p.s.continuesWith("null", p.i):
      p.i += 4
      return JNode(kind: jNull)
    return fail()
  else:
    if c == '-' or c in {'0' .. '9'}:
      var nt = ""
      if parseNumber(p, nt): return JNode(kind: jNum, s: nt)
    return fail()

proc parseStrict*(text: string): JResult =
  ## 092:1:1 Un solo valore JSON, nient'altro prima o dopo (spazi a parte).
  var p = P(s: text)
  let v = parseValue(p, "", 0)
  if v == nil: return
  skipWs(p)
  if p.i != p.s.len: return
  result.ok = true
  result.root = v
  result.dupPath = p.dup
