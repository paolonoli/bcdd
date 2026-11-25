# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 001:1:1 Lessico di BcddTool: dai byte alle righe e agli elementi (GRAMMATICA_F1 sezioni 1-2).
# 001:1:2 Nessuna perdita di righe: ogni riga del file ha un posto (g-c3 / a-1 di Analizzatore).
import std/unicode

type
  TokKind* = enum
    tkWord, tkNum, tkStr, tkSym, tkForeign

  Tok* = object
    kind*: TokKind
    text*: string      # per tkStr: il testo con le virgolette
    line*: int         # riga (da 1) dove l'elemento comincia
    col*: int          # byte dall'inizio della riga
    endLine*: int      # riga dove finisce (diverso da line solo per le stringhe)
    closed*: bool      # solo tkStr: la stringa si chiude

  Lexed* = object
    lines*: seq[string]   # testo delle righe, senza LF e senza CR prima di LF; indice 0 = riga 1
    toks*: seq[Tok]
    inStr*: seq[bool]     # inStr[n]: la riga n (da 1) comincia dentro una stringa
    unclosedLine*: int    # riga dove si apre la stringa non chiusa, 0 se non ce n'è

proc firstInvalidUtf8*(s: string): int =
  ## 002:1:1 Indice del primo byte che non è UTF-8 valido, -1 se il testo è valido.
  var i = 0
  let n = s.len
  while i < n:
    let b = ord(s[i])
    var need = 0
    var minCp = 0
    var cp = 0
    if b < 0x80:
      inc i
      continue
    elif b >= 0xC2 and b <= 0xDF:
      need = 1; minCp = 0x80; cp = b and 0x1F
    elif b >= 0xE0 and b <= 0xEF:
      need = 2; minCp = 0x800; cp = b and 0x0F
    elif b >= 0xF0 and b <= 0xF4:
      need = 3; minCp = 0x10000; cp = b and 0x07
    else:
      return i
    if i + need >= n: return i
    for k in 1 .. need:
      let c = ord(s[i + k])
      if (c and 0xC0) != 0x80: return i
      cp = (cp shl 6) or (c and 0x3F)
    if cp < minCp or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF): return i
    i += need + 1
  return -1

proc normalizeSource*(s: string): string =
  ## 003:1:1 Toglie il BOM in testa e il CR che precede un LF (sezione 1).
  var start = 0
  if s.len >= 3 and s[0] == '\xEF' and s[1] == '\xBB' and s[2] == '\xBF':
    start = 3
  result = newStringOfCap(s.len)
  var i = start
  while i < s.len:
    if s[i] == '\r' and i + 1 < s.len and s[i + 1] == '\n':
      inc i
      continue
    result.add s[i]
    inc i

proc isWordCont(r: Rune): bool =
  let v = int(r)
  (v >= ord('0') and v <= ord('9')) or v == ord('_') or isAlpha(r) or isCombining(r)

proc isWordStart(r: Rune): bool =
  int(r) == ord('_') or isAlpha(r)

proc runeAt(s: string, i: int): (Rune, int) =
  var r: Rune
  fastRuneAt(s, i, r, false)
  (r, runeLenAt(s, i))

proc prevIsWordChar(s: string, i: int): bool =
  ## 004:2:1 (1.20, L4) Il carattere prima della posizione i è una lettera, un segno diacritico, una cifra o '_'.
  if i == 0: return false
  var k = i - 1
  while k > 0 and (ord(s[k]) and 0xC0) == 0x80: dec k
  isWordCont(runeAt(s, k)[0])

proc splitLinesLf*(s: string): seq[string] =
  ## 004:1:1 Righe separate da LF; l'ultima conta anche senza LF finale; file vuoto = 0 righe.
  if s.len == 0: return @[]
  var cur = ""
  for ch in s:
    if ch == '\n':
      result.add cur
      cur = ""
    else:
      cur.add ch
  if s[^1] != '\n':
    result.add cur

proc lex*(src: string): Lexed =
  ## 005:1:1 Divide il testo (già normalizzato) in elementi, secondo le regole L1-L6.
  result.lines = splitLinesLf(src)
  let total = result.lines.len
  result.inStr = newSeq[bool](total + 2)
  let n = src.len
  var i = 0
  var ln = 1
  var lineStart = 0
  while i < n:
    let c = src[i]
    if c == ' ' or c == '\t':
      inc i
    elif c == '\n':
      inc i
      inc ln
      lineStart = i
    elif c == '-' and i + 1 < n and src[i + 1] == '-':
      while i < n and src[i] != '\n': inc i          # L1: commento
    elif c == '"':
      var t = Tok(kind: tkStr, line: ln, col: i - lineStart)
      var j = i + 1
      while j < n and src[j] != '"':
        if src[j] == '\n':
          inc ln
          lineStart = j + 1
        inc j
      if j < n:
        t.closed = true
        t.text = src[i .. j]
        t.endLine = ln
        i = j + 1
      else:
        t.closed = false
        t.text = src[i ..< n]
        t.endLine = min(ln, total)
        if result.unclosedLine == 0: result.unclosedLine = t.line
        i = n
      for l in t.line + 1 .. t.endLine:
        if l <= total: result.inStr[l] = true
      result.toks.add t
    elif (c >= '0' and c <= '9') or (c == '-' and i + 1 < n and src[i + 1] >= '0' and src[i + 1] <= '9' and
        not prevIsWordChar(src, i)):
      # 005:1:2 (1.20, L4) il '-' attaccato alla prima cifra è del numero se prima non c'è un carattere di parola
      var j = i
      if c == '-': inc j
      while j < n and src[j] >= '0' and src[j] <= '9': inc j
      while j + 1 < n and src[j] == '.' and src[j + 1] >= '0' and src[j + 1] <= '9':
        inc j
        while j < n and src[j] >= '0' and src[j] <= '9': inc j
      result.toks.add Tok(kind: tkNum, text: src[i ..< j], line: ln, col: i - lineStart, endLine: ln)
      i = j
    else:
      let (r, rl) = runeAt(src, i)
      if isWordStart(r):
        var j = i + rl
        while j < n:
          let (r2, l2) = runeAt(src, j)
          if isWordCont(r2):
            j += l2
          elif src[j] == '-' and j + 1 < n and isWordCont(runeAt(src, j + 1)[0]):
            inc j                                    # L3: il '-' vale solo fra due caratteri di parola
          else:
            break
        result.toks.add Tok(kind: tkWord, text: src[i ..< j], line: ln, col: i - lineStart, endLine: ln)
        i = j
      elif c == ':' and i + 1 < n and src[i + 1] == '=':
        result.toks.add Tok(kind: tkSym, text: ":=", line: ln, col: i - lineStart, endLine: ln)
        i += 2
      elif c == '.' and i + 1 < n and src[i + 1] == '.':
        result.toks.add Tok(kind: tkSym, text: "..", line: ln, col: i - lineStart, endLine: ln)
        i += 2
      elif (c == '<' or c == '>') and i + 1 < n and (src[i + 1] == '=' or (c == '<' and src[i + 1] == '>')):
        # 005:2:1 (1.0-beta, L5) i segni a due caratteri <= >= <> sono un segno solo
        result.toks.add Tok(kind: tkSym, text: src[i .. i + 1], line: ln, col: i - lineStart, endLine: ln)
        i += 2
      elif c == '-' and i + 1 < n and src[i + 1] == '>':
        result.toks.add Tok(kind: tkSym, text: "->", line: ln, col: i - lineStart, endLine: ln)
        i += 2
      elif c in {'(', ')', ',', ':', '=', '[', ']', '@', '.', '{', '}', '<', '>', '+', '-', '*', '/', '^', ';'}:
        # 005:1:3 (1.20, L5) anche '.', '{' e '}'; 005:2:2 (1.0-beta, L5) i segni delle formule
        # (il '-' arriva qui solo se non è commento, parte di parola o di numero)
        result.toks.add Tok(kind: tkSym, text: $c, line: ln, col: i - lineStart, endLine: ln)
        inc i
      else:
        result.toks.add Tok(kind: tkForeign, text: src[i ..< i + rl], line: ln, col: i - lineStart, endLine: ln)
        i += rl
