# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 009:1:1 edprocwin: i processi di Windows per `edwebview2`: `bcdd.exe` lanciato con CreateProcessW, senza console che lampeggia
# (CREATE_NO_WINDOW), con gli argomenti uno per uno (la riga è costruita da `lineaComando`, mai passata a una shell).
# Standard input, output ed errore sono file temporanei ereditati dal figlio, aperti in binario: i byte non cambiano (W-R1, W-R2: nessun CR LF
# aggiunto o tolto), un'uscita grande non può bloccare il figlio e il lancio sincrono non ha bisogno di thread. I file spariscono alla chiusura
# degli handle (FILE_FLAG_DELETE_ON_CLOSE). Solo Windows.
import std/[os, widestrs]
import std/winlean
import edlinea, edtraccia

type
  Esito* = object
    uscita*, errori*: string
    codice*: int
    segnalato*: bool           ## morto per Ctrl-C non gestito (STATUS_CONTROL_C_EXIT)
  Lancio* = object
    hProc, hIn, hOut, hErr: Handle
    pid*: int32
    ok*: bool
    errore*: string

const
  statusCtrlC = 0xC000013A'i32
  fileShareAll = 1'i32 or 2'i32 or 4'i32
  genericWrite = 0x40000000'i32
  fileCreateNew = 1'i32

proc setFilePointerEx(h: Handle, dist: int64, nuovo: ptr int64, metodo: DWORD): WINBOOL {.stdcall, dynlib: "kernel32", importc: "SetFilePointerEx".}
proc attachConsole(pid: int32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "AttachConsole".}
proc freeConsole(): WINBOOL {.stdcall, dynlib: "kernel32", importc: "FreeConsole".}
proc setConsoleCtrlHandler(h: pointer, aggiungi: WINBOOL): WINBOOL {.stdcall, dynlib: "kernel32", importc: "SetConsoleCtrlHandler".}
proc generateConsoleCtrlEvent(evento, gruppo: int32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "GenerateConsoleCtrlEvent".}

var contatore = 0

proc messaggioSistema(prefisso: string): string = prefisso & " (errore " & $getLastError() & ")"

proc apriTemporaneo(nome: string, dati: string, errore: var string): Handle =
  ## Un file temporaneo ereditabile, letto e scritto in binario, che sparisce alla chiusura; se `dati` non è vuoto ci si scrive e si torna all'inizio.
  var sa = SECURITY_ATTRIBUTES(nLength: int32(sizeof(SECURITY_ATTRIBUTES)), lpSecurityDescriptor: nil, bInheritHandle: 1)
  let h = createFileW(newWideCString(nome), GENERIC_READ or genericWrite, fileShareAll, addr sa, fileCreateNew,
    FILE_ATTRIBUTE_NORMAL or FILE_FLAG_DELETE_ON_CLOSE, 0)
  if h == INVALID_HANDLE_VALUE:
    errore = messaggioSistema("file temporaneo " & nome)
    return INVALID_HANDLE_VALUE
  if dati.len > 0:
    var scritti: int32
    var resto = dati.len
    var p = 0
    while resto > 0:
      let n = int32(min(resto, 1 shl 20))
      if writeFile(h, unsafeAddr dati[p], n, addr scritti, nil) == 0 or scritti <= 0:
        errore = messaggioSistema("scrittura del file temporaneo")
        discard closeHandle(h)
        return INVALID_HANDLE_VALUE
      p += scritti
      resto -= scritti
    discard setFilePointerEx(h, 0, nil, FILE_BEGIN)
  h

proc leggiTutto(h: Handle): string =
  discard setFilePointerEx(h, 0, nil, FILE_BEGIN)
  var buf = newString(65536)
  var letti: int32
  while readFile(h, addr buf[0], int32(buf.len), addr letti, nil) != 0 and letti > 0:
    result.add buf[0 ..< letti]

proc avvia*(argv: seq[string], input: string): Lancio =
  ## Fa partire il processo e ritorna subito. `ok` falso e `errore` pieno se non parte.
  inc contatore
  let base = getTempDir() / ("bcdd-editor-" & $getCurrentProcessId() & "-" & $contatore)
  var err = ""
  result.hIn = apriTemporaneo(base & ".in", input, err)
  if result.hIn != INVALID_HANDLE_VALUE: result.hOut = apriTemporaneo(base & ".out", "", err)
  if result.hOut != INVALID_HANDLE_VALUE and result.hIn != INVALID_HANDLE_VALUE: result.hErr = apriTemporaneo(base & ".err", "", err)
  if result.hIn == INVALID_HANDLE_VALUE or result.hOut == INVALID_HANDLE_VALUE or result.hErr == INVALID_HANDLE_VALUE:
    for h in [result.hIn, result.hOut, result.hErr]:
      if h != 0 and h != INVALID_HANDLE_VALUE: discard closeHandle(h)
    result.errore = err
    return
  var si: STARTUPINFO
  si.cb = int32(sizeof(STARTUPINFO))
  si.dwFlags = STARTF_USESTDHANDLES
  si.hStdInput = result.hIn
  si.hStdOutput = result.hOut
  si.hStdError = result.hErr
  var pi: PROCESS_INFORMATION
  let riga = newWideCString(lineaComando(argv))
  if createProcessW(newWideCString(argv[0]), riga, nil, nil, 1, CREATE_NO_WINDOW or CREATE_UNICODE_ENVIRONMENT, nil, nil, si, pi) == 0:
    result.errore = messaggioSistema(argv[0])
    for h in [result.hIn, result.hOut, result.hErr]: discard closeHandle(h)
    return
  discard closeHandle(pi.hThread)
  result.hProc = pi.hProcess
  result.pid = pi.dwProcessId
  result.ok = true

proc raccogli*(l: var Lancio): Esito =
  ## A processo finito: legge le uscite, il codice, e chiude tutto (i file temporanei spariscono).
  var c: int32 = 255
  discard getExitCodeProcess(l.hProc, c)
  result.uscita = leggiTutto(l.hOut)
  result.errori = leggiTutto(l.hErr)
  if c == statusCtrlC:
    result.segnalato = true
    result.codice = 255
  else:
    result.codice = int(c)
  for h in [l.hProc, l.hIn, l.hOut, l.hErr]: discard closeHandle(h)
  l.ok = false

proc aspetta*(l: Lancio) =
  discard waitForSingleObject(l.hProc, INFINITE)

proc handleProcesso*(l: Lancio): Handle = l.hProc

proc interrompi*(pid: int32, processo: Handle) =
  ## Ctrl-C a `bcdd`, come lo riceverebbe da una console: ci si aggancia alla console del figlio (CREATE_NO_WINDOW gliene dà una senza finestra),
  ## si manda l'evento al gruppo e ci si stacca. Il processo dell'editor ignora Ctrl-C per tutto il resto della vita (non ha console sua).
  if pid == 0: return
  let l = freeConsole()
  var a = attachConsole(pid)
  var giri = 0
  while a == 0 and giri < 40 and getLastError() == 6:
    # il processo è appena nato e non ha ancora la sua console: ERROR_INVALID_HANDLE; si riprova, al più 40 volte, aspettando il processo stesso
    # (che se finisce nel frattempo ferma il giro: l'attesa non è un timer ma l'attesa del processo)
    if waitForSingleObject(processo, 50) == 0: break
    inc giri
    a = attachConsole(pid)
  traccia("interrompi pid=" & $pid & " free=" & $l & " attach=" & $a & " err=" & $getLastError())
  if a != 0:
    discard setConsoleCtrlHandler(nil, 1)
    let g = generateConsoleCtrlEvent(0, 0)
    traccia("interrompi evento=" & $g)
    discard freeConsole()

proc attachConsolePadre(pid: int32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "AttachConsole".}
proc getConsoleOutputCP(): uint32 {.stdcall, dynlib: "kernel32", importc: "GetConsoleOutputCP".}
proc setConsoleOutputCP(cp: uint32): WINBOOL {.stdcall, dynlib: "kernel32", importc: "SetConsoleOutputCP".}

var cpPrima: uint32

proc ripristinaCp() {.noconv.} =
  if cpPrima != 0: discard setConsoleOutputCP(cpPrima)

proc collegaConsolePadre*() =
  ## 009:1:2 L'eseguibile è del sottosistema grafico (nessuna finestra di console quando si apre dal menu): se è lanciato da una console e lo standard
  ## error non è già rediretto (file o pipe), gli errori d'uso vanno alla console, come per un programma a riga di comando; il testo è UTF-8 e la
  ## tabella della console passa a UTF-8 finché il programma vive. Senza console padre, o con la redirezione, non cambia niente.
  let e = getStdHandle(STD_ERROR_HANDLE)
  if e != 0 and e != INVALID_HANDLE_VALUE: return
  if attachConsolePadre(-1) != 0:
    try:
      discard stderr.reopen("CONOUT$", fmWrite)
      discard stdout.reopen("CONOUT$", fmWrite)
      cpPrima = getConsoleOutputCP()
      if setConsoleOutputCP(65001) != 0: addQuitProc(ripristinaCp)
      else: cpPrima = 0
    except CatchableError: discard

# 009:2:1 la scelta delle cartelle e i messaggi d'avvio di un programma senza console. Funzioni di ole32/shell32/user32 già collegate
# (-lole32 -lshell32 -luser32). La scelta è la finestra moderna di Esplora file (`IFileOpenDialog`, solo cartelle, anche di rete, anche più d'una),
# dichiarata qui a mano (interfacce COM per tabella di funzioni; nessuna libreria): ogni interfaccia è un puntatore a un puntatore alla tabella.
type
  Guid = object
    d1: uint32
    d2, d3: uint16
    d4: array[8, uint8]
  Com = ptr ptr UncheckedArray[pointer]       # un'interfaccia COM: `com[][i]` è la i-esima funzione della tabella

const
  clsidFileOpenDialog = Guid(d1: 0xDC1C5A9C'u32, d2: 0xE88A'u16, d3: 0x4DDE'u16, d4: [0xA5'u8, 0xA1, 0x60, 0xF8, 0x2A, 0x20, 0xAE, 0xF7])
  iidFileOpenDialog = Guid(d1: 0xD57C7288'u32, d2: 0xD4AD'u16, d3: 0x4768'u16, d4: [0xBE'u8, 0x02, 0x9D, 0x96, 0x95, 0x32, 0xD9, 0x60])
  iidShellItem = Guid(d1: 0x43826D1E'u32, d2: 0xE718'u16, d3: 0x42EE'u16, d4: [0xBC'u8, 0x55, 0xA1, 0xE2, 0x61, 0xC3, 0x7B, 0xFE])
  fosPickFolders = 0x20'u32
  fosForceFileSystem = 0x40'u32
  fosAllowMultiSelect = 0x200'u32
  fosPathMustExist = 0x800'u32
  sigdnFileSysPath = 0x80058000'u32
  clsctxInprocServer = 1'u32

type
  FnQI = proc(self: Com, iid: ptr Guid, ris: ptr pointer): int32 {.stdcall.}
  FnRelease = proc(self: Com): uint32 {.stdcall.}
  FnShow = proc(self: Com, owner: Handle): int32 {.stdcall.}
  FnGetOptions = proc(self: Com, o: ptr uint32): int32 {.stdcall.}
  FnSetOptions = proc(self: Com, o: uint32): int32 {.stdcall.}
  FnSetFolder = proc(self: Com, item: Com): int32 {.stdcall.}
  FnSetStringa = proc(self: Com, s: ptr Utf16Char): int32 {.stdcall.}
  FnGetResults = proc(self: Com, ris: ptr Com): int32 {.stdcall.}
  FnGetCount = proc(self: Com, n: ptr uint32): int32 {.stdcall.}
  FnGetItemAt = proc(self: Com, i: uint32, ris: ptr Com): int32 {.stdcall.}
  FnGetDisplayName = proc(self: Com, sigdn: uint32, ris: ptr ptr Utf16Char): int32 {.stdcall.}

proc coCreateInstance(clsid: ptr Guid, esterno: pointer, ctx: uint32, iid: ptr Guid, ris: ptr pointer): int32 {.stdcall, dynlib: "ole32", importc: "CoCreateInstance".}
proc shCreateItemFromParsingName(percorso: ptr Utf16Char, pbc: pointer, iid: ptr Guid, ris: ptr pointer): int32 {.stdcall, dynlib: "shell32", importc: "SHCreateItemFromParsingName".}
proc coTaskMemFree(p: pointer) {.stdcall, dynlib: "ole32", importc: "CoTaskMemFree".}
proc oleInitialize(r: pointer): int32 {.stdcall, dynlib: "ole32", importc: "OleInitialize".}
proc messageBoxW(h: Handle, testo, titolo: ptr Utf16Char, tipo: uint32): int32 {.stdcall, dynlib: "user32", importc: "MessageBoxW".}

proc fn[T](c: Com, i: int): T = cast[T](c[][i])
proc rilascia(c: Com) =
  if c != nil: discard fn[FnRelease](c, 2)(c)

proc sceltaCartelleWin*(titolo, scegli, iniziale: string, padre: Handle): tuple[ok: bool, cartelle: seq[string]] =
  ## La finestra di scelta delle cartelle di Esplora file: solo cartelle del file system (anche `\\server\share\...`, scritte nella barra
  ## dell'indirizzo), scelta multipla, parte da `iniziale` se non è vuota. `ok` falso: la finestra non si crea. Annullata: ok e nessuna cartella.
  ## Nomi dei percorsi con `SIGDN_FILESYSPATH`: un elemento che non è del file system non entra (FOS_FORCEFILESYSTEM lo esclude già).
  discard oleInitialize(nil)
  var clsid = clsidFileOpenDialog
  var iid = iidFileOpenDialog
  var pd: pointer
  if coCreateInstance(addr clsid, nil, clsctxInprocServer, addr iid, addr pd) < 0 or pd == nil: return (false, @[])
  let d = cast[Com](pd)
  result.ok = true
  try:
    var opz: uint32
    if fn[FnGetOptions](d, 10)(d, addr opz) >= 0:
      discard fn[FnSetOptions](d, 9)(d, opz or fosPickFolders or fosForceFileSystem or fosAllowMultiSelect or fosPathMustExist)
    let t = newWideCString(titolo)
    discard fn[FnSetStringa](d, 17)(d, addr t[0])             # SetTitle
    let b = newWideCString(scegli)
    discard fn[FnSetStringa](d, 18)(d, addr b[0])             # SetOkButtonLabel
    if iniziale.len > 0:
      var iidItem = iidShellItem
      var pit: pointer
      let w = newWideCString(iniziale)
      if shCreateItemFromParsingName(addr w[0], nil, addr iidItem, addr pit) >= 0 and pit != nil:
        discard fn[FnSetFolder](d, 12)(d, cast[Com](pit))      # SetFolder
        rilascia(cast[Com](pit))
    if fn[FnShow](d, 3)(d, padre) < 0: return                  # annullata (HRESULT_FROM_WIN32(ERROR_CANCELLED)) o non riuscita: nessuna cartella
    var pr: Com
    if fn[FnGetResults](d, 27)(d, addr pr) < 0 or pr == nil: return
    var n: uint32
    if fn[FnGetCount](pr, 7)(pr, addr n) >= 0:
      for k in 0'u32 ..< n:
        var item: Com
        if fn[FnGetItemAt](pr, 8)(pr, k, addr item) < 0 or item == nil: continue
        var nome: ptr Utf16Char
        if fn[FnGetDisplayName](item, 5)(item, sigdnFileSysPath, addr nome) >= 0 and nome != nil:
          result.cartelle.add $cast[WideCString](nome)
          coTaskMemFree(nome)
        rilascia(item)
    rilascia(pr)
  finally:
    rilascia(d)

proc messaggioWin*(titolo, testo: string) =
  ## Una finestra con il testo e il pulsante OK (MB_OK | MB_ICONERROR): un programma grafico non ha la console dove scrivere l'errore.
  let t = newWideCString(testo)
  let ti = newWideCString(titolo)
  discard messageBoxW(0, addr t[0], addr ti[0], 0x10'u32)
