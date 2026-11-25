# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 100:1:1 Chiamata al fornitore LLM (Affinatore f-1, ModelloLinguistico m-1).
# 100:1:2 Interfaccia: un programma che legge la richiesta dallo standard input, scrive la risposta sullo standard
# 100:1:3 output e finisce con 0. Argomenti sempre come vettore (nessuna shell), cartella di lavoro vuota,
# 100:1:4 limite di tempo, arresto dell'intero gruppo di processi. L'uscita non è affidabile: la valuta il chiamante.
# 100:1:5 Unico processo esterno di BcddTool. `BCDD_LLM` vale solo se il binario è compilato con -d:bcddProva.
import std/[os, monotimes, times]
import std/strutils
import bcddsys
when defined(windows):
  import std/winlean
else:
  import std/posix

const
  MaxResponse* = 1_048_576      # sezione 6.4, controllo 1
  MaxStderr = 65_536            # sezione 9.4

type
  LlmOutcome* = enum
    loOk, loStartFailed, loNotFound, loTimeout, loInterrupted, loExitCode, loTooBig

  LlmResult* = object
    outcome*: LlmOutcome
    output*: string          # standard output letto (al più MaxResponse + 1 byte)
    errout*: string          # standard error, al più 64 KiB
    exitCode*: int           # codice, o 128 + segnale
    cause*: string           # solo loStartFailed
    searched*: string        # solo loNotFound: dove si è cercato `claude`
    durationMs*: int

var gInterrupted: bool

when defined(windows):
  proc onCtrl(ctrlType: int32): int32 {.stdcall.} =
    ## 101:1:2 Windows: Ctrl-C e Ctrl-Break diventano un'indicazione da leggere (il gestore gira su un altro thread).
    if ctrlType == 0 or ctrlType == 1:
      {.cast(gcsafe).}:
        gInterrupted = true
      return 1
    0

  proc setConsoleCtrlHandler(h: pointer, add: int32): int32 {.stdcall, dynlib: "kernel32", importc: "SetConsoleCtrlHandler".}

  proc installSigint*() =
    discard setConsoleCtrlHandler(cast[pointer](onCtrl), 1)
else:
  proc onSigint(sig: cint) {.noconv.} =
    gInterrupted = true

  proc installSigint*() =
    ## 101:1:1 Ctrl-C diventa un'indicazione da leggere, senza SA_RESTART: le letture bloccate si interrompono.
    var act: Sigaction
    act.sa_handler = onSigint
    discard sigemptyset(act.sa_mask)
    act.sa_flags = 0
    discard sigaction(SIGINT, act, nil)
    var ign: Sigaction
    ign.sa_handler = SIG_IGN
    discard sigemptyset(ign.sa_mask)
    discard sigaction(SIGPIPE, ign, nil)

proc interrupted*(): bool = gInterrupted

const DefaultVector = ["claude", "-p", "--tools", "", "--output-format", "text", "--no-session-persistence"]

proc modelId*(modello: string): string =
  ## 102:0:1: l'elenco chiuso dei modelli. `veloce` è Sonnet, `accurato` è Opus; altro non c'è.
  if modello == "accurato": "opus" else: "sonnet"

proc providerVector*(modello: string = "veloce"): seq[string] =
  ## 102:1:1 Il vettore del fornitore. Nell'eseguibile normale è sempre quello della sezione 9.2: la variabile
  ## BCDD_LLM non si legge nemmeno. Nell'eseguibile di prova (-d:bcddProva) sostituisce il vettore con un
  ## programma solo, senza argomenti.
  when defined(bcddProva):
    let v = getEnv("BCDD_LLM")
    if v.len > 0: return @[v]
  @DefaultVector & @["--model", modelId(modello)]

proc providerName*(v: seq[string]): string =
  ## 102:2:1 F della sezione 7.2 riga 3: `claude`, oppure il nome senza cartelle del programma.
  extractFilename(v[0])

proc isUsable(p: string): bool =
  ## 106:1:1 Un file che si può avviare: esiste e, fuori da Windows, ha un bit di esecuzione.
  try:
    if not fileExists(p): return false
    when defined(windows): return true
    else: return getFilePermissions(p) * {fpUserExec, fpGroupExec, fpOthersExec} != {}
  except OSError: return false

proc standardClaude*(): string =
  ## 106:1:2 la posizione standard dell'installatore nativo di Claude Code (Windows `%USERPROFILE%\\.local\\bin\\claude.exe`,
  ## Linux e macOS `$HOME/.local/bin/claude`). "" se la cartella personale non è nota. Nessun'altra posizione.
  let home = when defined(windows): getEnv("USERPROFILE") else: getEnv("HOME")
  if home.len == 0: return ""
  home / ".local" / "bin" / (when defined(windows): "claude.exe" else: "claude")

proc findClaude*(): string =
  ## 106:1:3 Prima il PATH (a Windows, in ogni cartella `claude.exe` poi `claude.cmd`, come PATHEXT), poi la posizione standard.
  ## "" se non si trova. Le cartelle vuote del PATH si saltano.
  for raw in getEnv("PATH").split(PathSep):
    var d = raw
    when defined(windows): d = d.strip(chars = {'"', ' '})
    if d.len == 0: continue
    when defined(windows):
      for n in ["claude.exe", "claude.cmd"]:
        if isUsable(d / n): return d / n
    else:
      if isUsable(d / "claude"): return d / "claude"
  let st = standardClaude()
  if st.len > 0 and isUsable(st): return st
  ""

proc claudeSearched*(): string =
  ## 106:1:4 Dove si è cercato, per il messaggio di assenza.
  let st = standardClaude()
  if st.len > 0: "PATH, " & st else: "PATH"

proc nowMs(t0: MonoTime): int = int((getMonoTime() - t0).inMilliseconds)

when not defined(windows):
  proc cExit(c: cint) {.importc: "_exit", header: "<unistd.h>", noreturn.}

  proc reap(pid: Pid, status: var cint, block0: bool): bool =
    while true:
      let r = waitpid(pid, status, if block0: 0.cint else: WNOHANG)
      if r == pid: return true
      if r == 0: return false
      if errno == EINTR: continue
      return true     # ECHILD: già raccolto

  proc statusToCode(status: cint): int =
    if WIFEXITED(status): int(WEXITSTATUS(status))
    elif WIFSIGNALED(status): 128 + int(WTERMSIG(status))
    else: 0

  proc stopGroup(pid: Pid, status: var cint, reaped: var bool) =
    ## 103:1:1 Sezione 9.3: terminazione al gruppo, 2 s di attesa, poi arresto forzato.
    discard kill(-pid, SIGTERM)
    discard kill(pid, SIGTERM)
    let t0 = getMonoTime()
    while not reaped and nowMs(t0) < 2000:
      reaped = reap(pid, status, false)
      if not reaped: discard poll(nil, 0, 20)
    if kill(-pid, 0) == 0: discard kill(-pid, SIGKILL)
    if not reaped:
      discard kill(pid, SIGKILL)
      reaped = reap(pid, status, true)

  proc setNonBlock(fd: cint) =
    let fl = fcntl(fd, F_GETFL)
    discard fcntl(fd, F_SETFL, fl or O_NONBLOCK)

  proc setCloexec(fd: cint) =
    discard fcntl(fd, F_SETFD, FD_CLOEXEC)

  proc callProvider*(argv: seq[string], request: string, limitSec: int, cwd: string): LlmResult =
    ## 104:1:1 Avvia il fornitore e raccoglie l'uscita. Tutto o niente non riguarda questa parte: non scrive file.
    var inP, outP, errP, exP: array[2, cint]
    var argv = argv
    if argv[0] == "claude":
      let f = findClaude()
      if f.len == 0:
        result.outcome = loNotFound
        result.searched = claudeSearched()
        return
      argv[0] = f
    if pipe(inP) != 0 or pipe(outP) != 0 or pipe(errP) != 0 or pipe(exP) != 0:
      result.outcome = loStartFailed
      result.cause = $strerror(errno)
      return
    let av = allocCStringArray(argv)
    let t0 = getMonoTime()
    let pid = fork()
    if pid < 0:
      result.outcome = loStartFailed
      result.cause = $strerror(errno)
      for fd in [inP[0], inP[1], outP[0], outP[1], errP[0], errP[1], exP[0], exP[1]]: discard posix.close(fd)
      deallocCStringArray(av)
      return
    if pid == 0:
      # figlio: solo chiamate di sistema
      discard setpgid(0, 0)
      discard dup2(inP[0], 0)
      discard dup2(outP[1], 1)
      discard dup2(errP[1], 2)
      for fd in [inP[0], inP[1], outP[0], outP[1], errP[0], errP[1], exP[0]]: discard posix.close(fd)
      setCloexec(exP[1])
      var dfl: Sigaction
      dfl.sa_handler = SIG_DFL
      discard sigemptyset(dfl.sa_mask)
      discard sigaction(SIGINT, dfl, nil)
      discard sigaction(SIGPIPE, dfl, nil)
      discard chdir(cwd.cstring)
      discard execvp(av[0], av)
      var e: cint = errno
      discard posix.write(exP[1], addr e, sizeof(e))
      cExit(127)
    # genitore
    discard setpgid(pid, pid)
    deallocCStringArray(av)
    discard posix.close(inP[0])
    discard posix.close(outP[1])
    discard posix.close(errP[1])
    discard posix.close(exP[1])
    setCloexec(inP[1]); setCloexec(outP[0]); setCloexec(errP[0])
    var status: cint = 0
    var reaped = false
    # avvio riuscito? L'estremo di scrittura si chiude da solo all'exec; se invece arriva un errno, l'avvio è fallito.
    var ecode: cint = 0
    var got = 0
    while true:
      got = posix.read(exP[0], addr ecode, sizeof(ecode))
      if got < 0 and errno == EINTR: continue
      break
    discard posix.close(exP[0])
    if got == sizeof(ecode):
      discard reap(pid, status, true)
      discard posix.close(inP[1]); discard posix.close(outP[0]); discard posix.close(errP[0])
      result.outcome = loStartFailed
      result.cause = $strerror(ecode)
      result.durationMs = nowMs(t0)
      return
    setNonBlock(inP[1]); setNonBlock(outP[0]); setNonBlock(errP[0])
    var inOpen = true
    var outOpen = true
    var errOpen = true
    var written = 0
    if request.len == 0:
      discard posix.close(inP[1])
      inOpen = false
    let deadline = limitSec * 1000
    var buf = newString(65536)
    var outcome = loOk
    while true:
      if gInterrupted:
        outcome = loInterrupted
        break
      let el = nowMs(t0)
      if el >= deadline:
        outcome = loTimeout
        break
      if not reaped: reaped = reap(pid, status, false)
      if not outOpen and reaped: break
      var fds: array[3, TPollfd]
      var n = 0
      var iIn, iOut, iErr = -1
      if inOpen:
        iIn = n
        fds[n] = TPollfd(fd: inP[1], events: POLLOUT)
        inc n
      if outOpen:
        iOut = n
        fds[n] = TPollfd(fd: outP[0], events: POLLIN)
        inc n
      if errOpen and not reaped:
        iErr = n
        fds[n] = TPollfd(fd: errP[0], events: POLLIN)
        inc n
      let wait = if not outOpen: 10 else: min(100, deadline - el)
      let pr = poll(if n > 0: addr fds[0] else: nil, Tnfds(n), cint(wait))
      if pr < 0:
        if errno == EINTR: continue
        continue
      if iIn >= 0 and (fds[iIn].revents and (POLLOUT or POLLERR or POLLHUP)) != 0:
        let chunk = min(65536, request.len - written)
        let w = posix.write(inP[1], unsafeAddr request[written], chunk)
        if w >= 0:
          written += w
        elif errno != EAGAIN and errno != EINTR:
          written = request.len     # EPIPE: il fornitore non legge più
        if written >= request.len:
          discard posix.close(inP[1])
          inOpen = false
      if iOut >= 0 and (fds[iOut].revents and (POLLIN or POLLHUP or POLLERR)) != 0:
        let r = posix.read(outP[0], addr buf[0], buf.len)
        if r > 0:
          result.output.add buf[0 ..< r]
          if result.output.len > MaxResponse:
            outcome = loTooBig
            break
        elif r == 0:
          outOpen = false
        elif errno != EAGAIN and errno != EINTR:
          outOpen = false
      if iErr >= 0 and (fds[iErr].revents and (POLLIN or POLLHUP or POLLERR)) != 0:
        let r = posix.read(errP[0], addr buf[0], buf.len)
        if r > 0:
          if result.errout.len < MaxStderr:
            result.errout.add buf[0 ..< min(r, MaxStderr - result.errout.len)]
        elif r == 0:
          errOpen = false
        elif errno != EAGAIN and errno != EINTR:
          errOpen = false
    if outcome != loOk:
      stopGroup(pid, status, reaped)
    # ciò che lo standard error aveva già pronto
    if errOpen:
      while true:
        let r = posix.read(errP[0], addr buf[0], buf.len)
        if r <= 0: break
        if result.errout.len < MaxStderr:
          result.errout.add buf[0 ..< min(r, MaxStderr - result.errout.len)]
    result.durationMs = nowMs(t0)
    discard posix.close(outP[0]); discard posix.close(errP[0])
    if inOpen: discard posix.close(inP[1])
    result.exitCode = statusToCode(status)
    case outcome
    of loOk:
      result.outcome = if result.exitCode != 0: loExitCode else: loOk
    else:
      result.outcome = outcome

else:
  proc closeH(h: var Handle) =
    if h != 0 and h != INVALID_HANDLE_VALUE:
      discard closeHandle(h)
    h = 0

  proc createJobObjectW(attrs: pointer, name: pointer): Handle {.stdcall, dynlib: "kernel32", importc: "CreateJobObjectW".}
  proc setInformationJobObject(job: Handle, cls: int32, info: pointer, len: int32): int32 {.stdcall, dynlib: "kernel32", importc: "SetInformationJobObject".}
  proc assignProcessToJobObject(job: Handle, p: Handle): int32 {.stdcall, dynlib: "kernel32", importc: "AssignProcessToJobObject".}
  proc terminateJobObject(job: Handle, code: uint32): int32 {.stdcall, dynlib: "kernel32", importc: "TerminateJobObject".}
  proc resumeThread(t: Handle): int32 {.stdcall, dynlib: "kernel32", importc: "ResumeThread".}

  var gReqText: string
  var gReqHandle: Handle
  var gReqThread: Thread[void]

  proc requestWriter() {.thread.} =
    ## 104:2:1 Windows: la richiesta si scrive da un thread a parte, perché una scrittura su un tubo pieno si blocca e il
    ## ciclo principale deve restare libero di guardare il tempo e Ctrl-C.
    {.cast(gcsafe).}:
      var done = 0
      while done < gReqText.len:
        var n: int32 = 0
        let chunk = int32(min(65536, gReqText.len - done))
        if writeFile(gReqHandle, unsafeAddr gReqText[done], chunk, addr n, nil) == 0 or n <= 0: break
        done += int(n)
      closeH(gReqHandle)

  proc drain(h: Handle, dest: var string, cap: int, buf: var string): int =
    ## 104:2:2 Legge ciò che c'è già nel tubo, senza bloccarsi. Restituisce i byte letti, 0 se non c'è niente, -1 se il tubo è chiuso.
    var avail: int32 = 0
    if not peekNamedPipe(h, nil, 0, nil, addr avail, nil): return -1
    if avail <= 0: return 0
    var n: int32 = 0
    if readFile(h, addr buf[0], int32(min(avail, int32(buf.len))), addr n, nil) == 0 or n <= 0: return -1
    if dest.len < cap:
      dest.add buf[0 ..< min(int(n), cap - dest.len)]
    int(n)

  proc callProvider*(argv: seq[string], request: string, limitSec: int, cwd: string): LlmResult =
    ## 104:1:1 Windows: CreateProcessW con tre tubi, vettore d'argomenti citato una parola alla volta (nessuna shell), cartella
    ## di lavoro vuota, limite di tempo. Allo scadere si ferma l'intero albero (Job Object); un fornitore `.cmd` si avvia tramite `cmd.exe /d /s /c`.
    var sa = SECURITY_ATTRIBUTES(nLength: int32(sizeof(SECURITY_ATTRIBUTES)), lpSecurityDescriptor: nil, bInheritHandle: 1)
    var inR, inW, outR, outW, errR, errW: Handle
    if createPipe(inR, inW, sa, 0) == 0 or createPipe(outR, outW, sa, 0) == 0 or createPipe(errR, errW, sa, 0) == 0:
      result.outcome = loStartFailed
      result.cause = osErrorMsg(osLastError()).strip()
      return
    # gli estremi che restano a noi non si ereditano
    discard setHandleInformation(inW, HANDLE_FLAG_INHERIT, 0)
    discard setHandleInformation(outR, HANDLE_FLAG_INHERIT, 0)
    discard setHandleInformation(errR, HANDLE_FLAG_INHERIT, 0)
    var exe = argv[0]
    if exe == "claude":
      let f = findClaude()
      if f.len == 0:
        result.outcome = loNotFound
        result.searched = claudeSearched()
        closeH(inR); closeH(inW); closeH(outR); closeH(outW); closeH(errR); closeH(errW)
        return
      exe = f
    elif exe.find({'/', '\\'}) < 0:
      let found = findExe(exe)
      if found.len > 0: exe = found
    var cmd = ""
    let low = exe.toLowerAscii()
    if low.endsWith(".cmd") or low.endsWith(".bat"):
      # 107:1:1 lo shim di npm (`claude.cmd`) si avvia con `cmd.exe /d /s /c "<shim>" argomenti`. Gli argomenti del
      # fornitore sono fissi (nessun metacarattere di cmd); il percorso dello shim non deve contenere ciò che cmd espande
      # anche fra virgolette.
      if exe.find({'%', '"', '^', '!', '\n', '\r'}) >= 0:
        result.outcome = loStartFailed
        result.cause = exe
        closeH(inR); closeH(inW); closeH(outR); closeH(outW); closeH(errR); closeH(errW)
        return
      var comspec = getEnv("ComSpec")
      if comspec.len == 0: comspec = "cmd.exe"
      cmd = "\"" & comspec & "\" /d /s /c \"\"" & exe & "\""
      for k in 1 ..< argv.len: cmd.add " " & quoteShellWindows(argv[k])
      cmd.add "\""
    else:
      cmd = quoteShellWindows(exe)
      for k in 1 ..< argv.len: cmd.add " " & quoteShellWindows(argv[k])
    var si: STARTUPINFO
    si.cb = int32(sizeof(STARTUPINFO))
    si.dwFlags = STARTF_USESTDHANDLES
    si.hStdInput = inR
    si.hStdOutput = outW
    si.hStdError = errW
    var pi: PROCESS_INFORMATION
    # 107:1:2 Job Object: il processo parte sospeso, entra nel job, poi riparte; allo scadere o a Ctrl-C si ferma l'intero albero,
    # e chiudere il job (anche se bcdd muore) ferma ciò che resta. Se l'assegnazione fallisce si procede senza job.
    var job = createJobObjectW(nil, nil)
    if job != 0:
      var info: array[160, byte]
      var flags: uint32 = 0x2000        # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
      copyMem(addr info[16], addr flags, 4)
      let infoLen = if sizeof(pointer) == 8: 144'i32 else: 112'i32
      if setInformationJobObject(job, 9, addr info[0], infoLen) == 0:
        discard closeHandle(job)
        job = 0
    let t0 = getMonoTime()
    let okP = createProcessW(nil, newWideCString(cmd), nil, nil, 1,
      CREATE_NO_WINDOW or CREATE_UNICODE_ENVIRONMENT or (if job != 0: 0x4'i32 else: 0'i32), nil, newWideCString(cwd), si, pi)
    closeH(inR); closeH(outW); closeH(errW)
    if okP == 0:
      result.outcome = loStartFailed
      result.cause = osErrorMsg(osLastError()).strip()
      closeH(inW); closeH(outR); closeH(errR)
      if job != 0: discard closeHandle(job)
      return
    if job != 0:
      if assignProcessToJobObject(job, pi.hProcess) == 0:
        discard closeHandle(job)
        job = 0
      discard resumeThread(pi.hThread)
    closeH(pi.hThread)
    var writer = false
    if request.len == 0:
      closeH(inW)
    else:
      gReqText = request
      gReqHandle = inW
      createThread(gReqThread, requestWriter)
      writer = true
    let deadline = limitSec * 1000
    var buf = newString(65536)
    var outcome = loOk
    var outOpen = true
    var errOpen = true
    var exited = false
    var code: int32 = 0
    while true:
      if gInterrupted:
        outcome = loInterrupted
        break
      if nowMs(t0) >= deadline:
        outcome = loTimeout
        break
      var got = 0
      if outOpen:
        let r = drain(outR, result.output, MaxResponse + 1, buf)
        if r < 0: outOpen = false
        elif r > 0:
          got += r
          if result.output.len > MaxResponse:
            outcome = loTooBig
            break
      if errOpen:
        let r = drain(errR, result.errout, MaxStderr, buf)
        if r < 0: errOpen = false
        elif r > 0: got += r
      if not exited and waitForSingleObject(pi.hProcess, 0) == WAIT_OBJECT_0:
        exited = true
        discard getExitCodeProcess(pi.hProcess, code)
      if exited and got == 0: break          # finito e tubi vuoti: tutto letto
      if not outOpen and not errOpen and exited: break
      if got == 0: sleep(10)
    if outcome != loOk:
      if job != 0: discard terminateJobObject(job, 1)
      discard terminateProcess(pi.hProcess, 1)
      discard waitForSingleObject(pi.hProcess, 2000)
      discard getExitCodeProcess(pi.hProcess, code)
    # ciò che lo standard error aveva già pronto
    if errOpen:
      while drain(errR, result.errout, MaxStderr, buf) > 0: discard
    result.durationMs = nowMs(t0)
    closeH(pi.hProcess); closeH(outR); closeH(errR)
    if job != 0: discard closeHandle(job)
    if writer:
      # il fornitore è finito o fermato: la scrittura si sblocca da sola (tubo rotto) e il thread termina
      joinThread(gReqThread)
    result.exitCode = int(code)
    case outcome
    of loOk:
      result.outcome = if result.exitCode != 0: loExitCode else: loOk
    else:
      result.outcome = outcome

proc makeWorkDir*(): string =
  ## 105:1:1 Cartella temporanea vuota per la chiamata (sezione 9.1); "" se non si riesce a crearla.
  makeTempDir()

proc removeWorkDir*(d: string) =
  if d.len > 0:
    try: removeDir(d)
    except OSError: discard
