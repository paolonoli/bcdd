# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 076:1:1 Il sistema operativo sotto bcdd: le sole chiamate che dipendono dalla piattaforma, in un posto.
# 076:1:2 Su Linux (e sugli altri POSIX) sono le chiamate di sempre, spostate qui senza cambiare comportamento. Su Windows
# 076:1:3 sono gli equivalenti di `winlean`. Gli altri moduli non importano `posix` né `winlean`.
# 076:1:4 Limite dichiarato: la parte Windows è controllata solo dal compilatore (`nim check --os:windows`), mai eseguita
# 076:1:5 su Windows da chi l'ha scritta.
import std/[os, strutils]
when defined(windows):
  import std/[winlean, terminal, exitprocs]
else:
  import std/posix

type
  PathInfo* = object
    ok*: bool          # il percorso esiste e si risolve (stat riuscita)
    absent*: bool      # non ok perché il file o un pezzo del percorso non esiste (ENOENT o ENOTDIR)
    noent*: bool       # non ok e proprio ENOENT
    isDir*, isFile*: bool
    nlink*: int        # collegamenti fisici (1 se non si sa)
    mode*: int         # bit di permesso (-1 se la piattaforma non li ha)

  TempResult* = enum
    trOk, trFailed

  LinkResult* = enum
    lkCreated, lkExists, lkFailed

  StdinResult* = enum
    sdData, sdTimeout, sdEof

# ---------------------------------------------------------------- percorsi

proc isSepChar*(c: char): bool =
  ## 076:2:1 Un separatore accettato dal sistema: `/` ovunque, anche `\` e l'unità (`:`) su Windows (W-R4, W-R5).
  when defined(windows): c in {'/', '\\', ':'}
  else: c == '/'

proc folderOfArg*(fileArg: string): string =
  ## 076:2:2 La cartella del percorso scritto dalla persona, com'è scritta e con il separatore finale; "" se non ne ha (W-R5).
  var i = fileArg.len - 1
  while i >= 0 and not isSepChar(fileArg[i]): dec i
  if i < 0: "" else: fileArg[0 .. i]

proc joinShown*(d, name: string): string =
  ## 076:2:3 W-R4: la cartella com'è scritta, il separatore del sistema se non finisce già con uno accettato, poi il nome.
  if d.len > 0 and isSepChar(d[^1]): d & name
  else: d & $DirSep & name

proc isDeviceName*(name: string): bool =
  ## 076:2:4 su Windows questi nomi, con o senza estensione, indicano un dispositivo e non un file.
  ## Il confronto non distingue maiuscole e minuscole, come Windows.
  var base = name
  let dot = base.find('.')
  if dot >= 0: base = base[0 ..< dot]
  base = base.toUpperAscii
  if base in ["CON", "PRN", "AUX", "NUL"]: return true
  base.len == 4 and (base.startsWith("COM") or base.startsWith("LPT")) and base[3] in {'1' .. '9'}

proc nameIsExact*(path: string): bool =
  ## 076:2:5 W-R6: il nome sul disco è esattamente quello scritto (stesse maiuscole e minuscole). Su Linux lo è sempre.
  when defined(windows):
    let (dir, base) = splitPath(path)
    try:
      for _, p in walkDir(if dir.len > 0: dir else: ".", relative = true):
        if p == base: return true
      false
    except OSError:
      true      # la cartella non si elenca: decide l'apertura del file, come per ogni altro errore
  else:
    true

# ---------------------------------------------------------------- stato di un percorso

when defined(windows):
  const
    ErrFileNotFound = 2'i32
    ErrPathNotFound = 3'i32
    ErrInvalidName = 123'i32
    ErrDirectory = 267'i32
    ErrFileExists = 80'i32
    ErrAlreadyExists = 183'i32
    InvalidAttr = -1'i32

  # 076:3:0 Misurato su Windows: una `proc` che restituisce il WideCString dà un puntatore già liberato (GetFileAttributesW
  # 076:3:0 falliva con ERROR_PATH_NOT_FOUND); con un `template` il buffer vive fino alla fine della chiamata.
  template wide(s: string): WideCString = newWideCString(s)

  proc lastErrText(): string = osErrorMsg(osLastError()).strip()   # 076:3:0b il testo di Windows finisce con CR LF

  proc hardLinkCount(path: string): int =
    ## 076:3:1 Il numero di collegamenti fisici di un file (GetFileInformationByHandle); 1 se non si riesce a saperlo.
    let h = createFileW(wide(path), 0'i32, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS, 0)
    if h == INVALID_HANDLE_VALUE: return 1
    var info: BY_HANDLE_FILE_INFORMATION
    let ok = getFileInformationByHandle(h, addr info)
    discard closeHandle(h)
    if ok == 0: 1 else: int(info.nNumberOfLinks)

proc pathInfo*(path: string): PathInfo =
  ## 076:3:2 Stato di un percorso, seguendo i collegamenti simbolici (stat).
  result.nlink = 1
  result.mode = -1
  when defined(windows):
    # 076:3:2b Misurato su Windows: `bcdd check CON` restava bloccato a leggere la console. Un nome di dispositivo
    # 076:3:2c non è un file di nessuna cartella (W-R7): vale «non esiste», come per i candidati delle citazioni.
    if isDeviceName(extractFilename(path)):
      result.absent = true
      result.noent = true
      return
    let a = getFileAttributesW(wide(path))
    if a == InvalidAttr:
      let e = getLastError()
      result.absent = e in [ErrFileNotFound, ErrPathNotFound, ErrInvalidName, ErrDirectory]
      result.noent = e in [ErrFileNotFound, ErrPathNotFound]
      return
    result.ok = true
    result.isDir = (a and FILE_ATTRIBUTE_DIRECTORY) != 0
    result.isFile = not result.isDir
    if result.isFile: result.nlink = hardLinkCount(path)
  else:
    var st: Stat
    if stat(path.cstring, st) != 0:
      let e = errno
      result.absent = e == ENOENT or e == ENOTDIR
      result.noent = e == ENOENT
      return
    result.ok = true
    result.isDir = S_ISDIR(st.st_mode)
    result.isFile = S_ISREG(st.st_mode)
    result.nlink = int(st.st_nlink)
    result.mode = int(st.st_mode and 0o7777)

proc pathExistsNoFollow*(path: string): bool =
  ## 076:3:3 Il nome esiste, anche se è un collegamento simbolico rotto (lstat).
  when defined(windows):
    getFileAttributesW(wide(path)) != InvalidAttr
  else:
    var st: Stat
    lstat(path.cstring, st) == 0

type EntryProbe* = enum
  epAbsent, epPresent, epUnknown

proc probeEntry*(path: string): EntryProbe =
  ## 076:3:5 la voce c'è, di qualunque tipo e senza seguire i collegamenti (lstat); assente solo se il sistema dice
  ## «il nome non esiste» (ENOENT, ENOTDIR); ogni altro errore dà epUnknown e chi chiama si comporta come se la voce ci fosse.
  when defined(windows):
    let a = getFileAttributesW(wide(path))
    if a != InvalidAttr: return epPresent
    let e = getLastError()
    if e in [ErrFileNotFound, ErrPathNotFound, ErrInvalidName, ErrDirectory]: epAbsent else: epUnknown
  else:
    var st: Stat
    if lstat(path.cstring, st) == 0: return epPresent
    let e = errno
    if e == ENOENT or e == ENOTDIR: epAbsent else: epUnknown

proc dirOpenable*(path: string): bool =
  ## 076:3:4 La cartella si può aprire per elencarla.
  when defined(windows):
    try:
      for _ in walkDir(path): break
      true
    except OSError:
      false
  else:
    let h = opendir(path.cstring)
    if h == nil: return false
    discard closedir(h)
    true

proc processId*(): int =
  when defined(windows):
    proc getCurrentProcessId(): int32 {.stdcall, dynlib: "kernel32", importc: "GetCurrentProcessId".}
    int(getCurrentProcessId())
  else:
    int(getpid())

# ---------------------------------------------------------------- file temporaneo, sostituzione, collegamento

proc removeTemp*(path: string) =
  ## 076:4:1 Toglie un file temporaneo; un errore non interessa.
  when defined(windows): discard deleteFileW(wide(path))
  else: discard unlink(path.cstring)

proc writeTempFile*(prefix, content: string, existingMode: int, tmp: var string, why: var string): TempResult =
  ## 076:4:2 Crea un file nuovo nella stessa cartella del bersaglio (nome `prefix` + pid, poi con un numero se esiste già),
  ## ci scrive `content` per intero, lo porta sul disco e lo chiude. `existingMode` >= 0: il file sostituito esisteva e i suoi
  ## permessi si ricopiano (Linux); -1: file nuovo. Su errore il temporaneo non resta e `why` dice perché.
  when defined(windows):
    let pid = processId()
    var h: Handle = INVALID_HANDLE_VALUE
    for attempt in 0 .. 20:
      tmp = prefix & $pid & (if attempt == 0: "" else: $attempt)
      h = createFileW(wide(tmp), GENERIC_WRITE, 0'i32, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0)
      if h != INVALID_HANDLE_VALUE: break
      if getLastError() != ErrFileExists: break
    if h == INVALID_HANDLE_VALUE:
      why = lastErrText()
      return trFailed
    var okW = true
    var done = 0
    while done < content.len:
      var n: int32 = 0
      let chunk = int32(min(content.len - done, 1 shl 20))
      if writeFile(h, unsafeAddr content[done], chunk, addr n, nil) == 0 or n <= 0:
        okW = false
        why = lastErrText()
        break
      done += int(n)
    if okW and flushFileBuffers(h) == 0:
      okW = false
      why = lastErrText()
    discard closeHandle(h)
    if not okW:
      removeTemp(tmp)
      return trFailed
    trOk
  else:
    let pid = getpid()
    var fd: cint = -1
    for attempt in 0 .. 20:
      tmp = prefix & $pid & (if attempt == 0: "" else: $attempt)
      fd = posix.open(tmp.cstring, O_WRONLY or O_CREAT or O_EXCL, if existingMode >= 0: 0o600.Mode else: 0o666.Mode)
      if fd >= 0 or errno != EEXIST: break
    if fd < 0:
      why = $strerror(errno)
      return trFailed
    var okW = true
    var done = 0
    while done < content.len:
      let n = posix.write(fd, unsafeAddr content[done], content.len - done)
      if n < 0:
        if errno == EINTR: continue
        okW = false
        why = $strerror(errno)
        break
      done += n
    if okW and existingMode >= 0 and fchmod(fd, Mode(existingMode)) != 0:
      okW = false
      why = $strerror(errno)
    if okW and fsync(fd) != 0:
      okW = false
      why = $strerror(errno)
    discard posix.close(fd)
    if not okW:
      removeTemp(tmp)
      return trFailed
    trOk

when not defined(windows):
  proc cRename(a, b: cstring): cint {.importc: "rename", header: "<stdio.h>".}

proc replaceFile*(tmp, target: string, why: var string): bool =
  ## 076:4:3 Mette `tmp` al posto di `target` in un colpo solo (rename; su Windows MoveFileEx con sostituzione e scrittura su disco).
  when defined(windows):
    if moveFileExW(wide(tmp), wide(target), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) == 0:
      why = lastErrText()
      return false
    true
  else:
    if cRename(tmp.cstring, target.cstring) != 0:
      why = $strerror(errno)
      return false
    true

proc syncDirectory*(dir: string) =
  ## 076:4:4 La cartella sul disco, per quanto possibile (su Windows lo fa già MOVEFILE_WRITE_THROUGH).
  when defined(windows):
    discard
  else:
    let dfd = posix.open((if dir.len > 0: dir else: ".").cstring, O_RDONLY)
    if dfd >= 0:
      discard fsync(dfd)
      discard posix.close(dfd)

proc linkNewFile*(tmp, path: string, why: var string): LinkResult =
  ## 076:4:5 Dà a `tmp` il nome definitivo `path` solo se `path` non esiste: nessuna sovrascrittura. Su Linux è link(): `tmp` resta
  ## e lo toglie il chiamante; su Windows `tmp` si sposta (MoveFileEx senza sostituzione, atomica).
  when defined(windows):
    if moveFileExW(wide(tmp), wide(path), MOVEFILE_WRITE_THROUGH) != 0: return lkCreated
    let e = getLastError()
    if e == ErrFileExists or e == ErrAlreadyExists: return lkExists
    why = lastErrText()
    lkFailed
  else:
    if posix.link(tmp.cstring, path.cstring) == 0: return lkCreated
    let e = errno
    if e == EEXIST: return lkExists
    if e == EPERM or e == ENOTSUP or e == EMLINK:
      # file system senza collegamenti fisici: si ricade su rename dopo il controllo di esistenza
      if pathExistsNoFollow(path) or dirExists(path): return lkExists
      try:
        moveFile(tmp, path)
        return lkCreated
      except OSError as ex:
        why = ex.msg
        return lkFailed
    why = $strerror(e)
    lkFailed

# ---------------------------------------------------------------- Ctrl-C rimandato durante la scrittura

when defined(windows):
  proc setCtrlHandler(h: pointer, add: int32): int32 {.stdcall, dynlib: "kernel32", importc: "SetConsoleCtrlHandler".}

type InterruptGuard* = object
  when not defined(windows):
    old: Sigaction

proc deferInterrupt*(): InterruptGuard =
  ## 076:5:1 Da qui alla sostituzione Ctrl-C è rimandato: finisce la scrittura, nessun temporaneo orfano (W-R9).
  when defined(windows):
    discard setCtrlHandler(nil, 1)      # nil + TRUE: il processo ignora Ctrl-C
  else:
    var ign: Sigaction
    ign.sa_handler = SIG_IGN
    discard sigemptyset(ign.sa_mask)
    discard sigaction(SIGINT, ign, result.old)

proc restoreInterrupt*(g: var InterruptGuard) =
  when defined(windows):
    discard setCtrlHandler(nil, 0)
  else:
    var ign: Sigaction
    discard sigaction(SIGINT, g.old, ign)

# ---------------------------------------------------------------- cartella temporanea

proc makeTempDir*(): string =
  ## 076:6:1 Cartella temporanea vuota (sezione 9.1 del design di refine); "" se non si riesce a crearla.
  when defined(windows):
    let base = getTempDir() / ("bcdd" & $processId() & "_")
    for i in 0 .. 50:
      let d = base & $i
      if createDirectoryW(wide(d), nil) != 0: return d
    ""
  else:
    var t = getTempDir() / "bcddXXXXXX"
    if mkdtemp(t.cstring) == nil: return ""
    t

# ---------------------------------------------------------------- registro delle chiamate (append)

proc appendToFile*(path, header, line: string): string =
  ## 076:7:1 Aggiunge `line` in fondo a `path` (lo crea; se è vuoto prima scrive `header`). "" se riuscito, altrimenti il perché.
  when defined(windows):
    var f: File
    if not open(f, path, fmAppend): return lastErrText()
    try:
      if getFileSize(f) == 0: f.write header
      f.write line
      f.flushFile()
      ""
    except IOError as ex:
      ex.msg
    finally:
      close(f)
  else:
    let fd = posix.open(path.cstring, O_WRONLY or O_APPEND or O_CREAT, 0o666.Mode)
    if fd < 0: return $strerror(errno)
    var st: Stat
    discard fstat(fd, st)
    let text = (if st.st_size == 0: header else: "") & line
    let w = posix.write(fd, unsafeAddr text[0], text.len)
    let e = errno
    discard posix.close(fd)
    if w != text.len: return $strerror(e)
    ""

# ---------------------------------------------------------------- flussi standard e console (W-R2, W-R3)

when defined(windows):
  proc cSetMode(fd: cint, mode: cint): cint {.importc: "_setmode", header: "<io.h>".}
  proc cFileno(f: File): cint {.importc: "_fileno", header: "<stdio.h>".}
  proc consoleModeOf(h: Handle, mode: ptr int32): int32 {.stdcall, dynlib: "kernel32", importc: "GetConsoleMode".}
  proc getConsoleCP(): uint32 {.stdcall, dynlib: "kernel32", importc: "GetConsoleCP".}
  proc getConsoleOutputCP(): uint32 {.stdcall, dynlib: "kernel32", importc: "GetConsoleOutputCP".}
  proc setConsoleCP(cp: uint32): int32 {.stdcall, dynlib: "kernel32", importc: "SetConsoleCP".}
  proc setConsoleOutputCP(cp: uint32): int32 {.stdcall, dynlib: "kernel32", importc: "SetConsoleOutputCP".}
  var
    savedInCp, savedOutCp: uint32
    consoleChanged = false

proc restoreConsole*() =
  ## 076:8:1 Rimette la tabella codici della console com'era (Windows); su Linux non fa niente.
  when defined(windows):
    if consoleChanged:
      consoleChanged = false
      discard setConsoleCP(savedInCp)
      discard setConsoleOutputCP(savedOutCp)

proc prepareStreams*() =
  ## 076:8:2 W-R2 e W-R3, una volta all'avvio. Windows: standard input, output ed error in binario (nessun CR aggiunto o tolto dal
  ## sistema) e, se output o error sono una console, la console in UTF-8 per la durata del comando. Linux: niente da fare.
  when defined(windows):
    const OBinary = 0x8000.cint
    discard cSetMode(cFileno(stdin), OBinary)
    discard cSetMode(cFileno(stdout), OBinary)
    discard cSetMode(cFileno(stderr), OBinary)
    var mode: int32
    let hOut = getStdHandle(STD_OUTPUT_HANDLE)
    let hErr = getStdHandle(STD_ERROR_HANDLE)
    let hIn = getStdHandle(STD_INPUT_HANDLE)
    let console = consoleModeOf(hOut, addr mode) != 0 or consoleModeOf(hErr, addr mode) != 0 or consoleModeOf(hIn, addr mode) != 0
    if console:
      savedInCp = getConsoleCP()
      savedOutCp = getConsoleOutputCP()
      consoleChanged = true
      discard setConsoleCP(65001)
      discard setConsoleOutputCP(65001)
      addExitProc(restoreConsole)
  else:
    discard

proc stdinIsTty*(): bool =
  when defined(windows): isatty(stdin)
  else: isatty(0) != 0

# ---------------------------------------------------------------- lettura dello standard input con attesa a scatti

when defined(windows):
  import std/locks
  var
    stdinLock: Lock
    stdinBuf: string
    stdinEof = false
    stdinStarted = false
    stdinThread: Thread[void]

  proc stdinReader() {.thread.} =
    {.cast(gcsafe).}:
      let h = getStdHandle(STD_INPUT_HANDLE)
      var chunk = newString(4096)
      while true:
        var n: int32 = 0
        let ok = readFile(h, addr chunk[0], 4096'i32, addr n, nil)
        acquire(stdinLock)
        if ok == 0 or n <= 0:
          stdinEof = true
          release(stdinLock)
          break
        stdinBuf.add chunk[0 ..< int(n)]
        release(stdinLock)

proc waitStdin*(buf: var string, timeoutMs: int): StdinResult =
  ## 076:9:1 Aspetta al più `timeoutMs` dei byte dallo standard input e li aggiunge a `buf`. Serve a chi legge una riga e intanto
  ## deve accorgersi di Ctrl-C (sezione 7.6): sdData con dei byte, sdEof a fine ingresso, sdTimeout se non è arrivato niente.
  when defined(windows):
    if not stdinStarted:
      stdinStarted = true
      initLock(stdinLock)
      createThread(stdinThread, stdinReader)
    var waited = 0
    while true:
      acquire(stdinLock)
      let have = stdinBuf.len
      let eof = stdinEof
      if have > 0:
        buf.add stdinBuf
        stdinBuf = ""
      release(stdinLock)
      if have > 0: return sdData
      if eof: return sdEof
      if waited >= timeoutMs: return sdTimeout
      sleep(10)
      waited += 10
  else:
    var fd = TPollfd(fd: 0, events: POLLIN)
    let pr = poll(addr fd, 1, cint(timeoutMs))
    if pr <= 0: return sdTimeout
    var chunk = newString(4096)
    let r = posix.read(0, addr chunk[0], chunk.len)
    if r > 0:
      buf.add chunk[0 ..< r]
      return sdData
    if r == 0: return sdEof
    if errno != EINTR and errno != EAGAIN: return sdEof
    sdTimeout
