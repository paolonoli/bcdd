# Building BCDD on Windows

This file describes how to build the `bcdd` command-line tool as a native Windows x86-64 program.
The `bcdd-editor` window has its own section, added separately below.

**Status.** `bcdd` was built and run on a real Windows 11 x86-64 machine (MSYS2 MinGW64, Nim 2.2.8, GCC 16.1.0).
The commands in this file are the ones that were actually typed there; what could not be tried is listed under "Not verified".
The editor `bcdd-editor` has its own section below.

## `bcdd` (command line)

### Prerequisites

- Windows 10 or 11, x86-64.
- [MSYS2](https://www.msys2.org/) installed in `C:\msys64`. All commands below are typed in the **MSYS2 MinGW64** shell
  (Start menu: "MSYS2 MinGW x64"), not in `cmd` or PowerShell.
- The MinGW-w64 GCC toolchain, and Git:

  ```sh
  pacman -S mingw-w64-x86_64-gcc git unzip
  ```

- Nim 2.2.8 or later for Windows x64 (the same toolchain pair, MSYS2 MinGW64 plus Nim 2.2.x, is used by another Nim project of the same group).
  Download the "x86_64 zip" from <https://nim-lang.org/install_windows.html>, unpack it, and put its `bin` folder in `PATH`:

  ```sh
  cd /c/Users/$USER
  curl -L -o nim.zip "https://nim-lang.org/download/nim-2.2.8_x64.zip"
  unzip nim.zip
  export PATH="/c/Users/$USER/nim-2.2.8/bin:$HOME/.nimble/bin:$PATH"
  nim --version        # must say: [Windows: amd64]
  ```

  Repeat the `export` line every time a new MinGW64 shell is opened.

- Work in a local folder or on a mapped drive letter, not in a UNC path (`\\server\share`): Nim and MinGW do not support a UNC path as the working folder.

### Build

From the folder that contains `BcddTool.nimble`, in the MinGW64 shell:

```sh
nimble install --depsOnly -y
nimble build -d:release
```

The result is `bcdd.exe` (about 2.4 MB). It is linked to `KERNEL32.dll` and `msvcrt.dll` only, which every Windows has, so it runs
from `cmd.exe` and PowerShell without `/mingw64/bin` in `PATH`. (The same applies to the one-file test programs below.)

The dependency `checksums` is downloaded by `nimble`, which needs the CA certificates of the machine. Where nimble answers
`No SSL/TLS CA certificates found` (the test machine was like that), copy the package folder
`~/.nimble/pkgs2/checksums-0.2.2-*` from another machine into the same place and compile with Nim directly. This is the
command that was used on the test machine (it does not need nimble):

```sh
export PATH=/mingw64/bin:/usr/bin:$PATH
nim c -d:release --hints:off --path:$(echo ~/.nimble/pkgs2/checksums-*) -o:bcdd.exe src/bcdd.nim
```

The first compilation took 38 s. A binary with the language-model replacement used by the tests is built with the extra
option `-d:bcddProva` (never distribute it): `nim c -d:release -d:bcddProva --nimcache:nimcache/prova -o:bcdd_prova.exe src/bcdd.nim`.

### Language model (`bcdd refine`, Complete)

`bcdd refine`, and the Complete button of the editor that uses it, call Claude Code. It must be installed and signed in
(subscription or API key, at the user's own cost); `bcdd` does not install it and does not ask for the sign-in.

- The exact command (the request goes in on standard input, the answer is read from standard output; no other program is started):
  `claude -p --tools "" --output-format text --no-session-persistence --model sonnet` (`veloce`) or `--model opus` (`accurato`).
- `claude` is looked for in `PATH` (`claude.exe`, then `claude.cmd`, folder by folder), then in the standard place of the native installer of Claude Code: `%USERPROFILE%\.local\bin\claude.exe`. Nowhere else, and the command is not configurable in the release build.
  When it is not found, `bcdd refine` says so, names the places searched and exits with code 4; the file is not changed.
- A `claude.cmd` (installation through npm) is started with `cmd.exe /d /s /c`. When the time limit expires or Ctrl-C is pressed,
  the whole tree of processes is stopped (a Windows Job Object), not only `claude`.

### Minimal check

In the MinGW64 shell, then also in `cmd.exe` and in PowerShell:

```sh
./bcdd.exe --lang it check prove/01_minima.csc
./bcdd.exe --lang en check prove/01_minima.csc
```

Both commands must end with a line saying that there are no errors (`esito: nessun errore` in Italian, `outcome: no errors` in English)
and exit with code 0. Accented letters in the Italian output (for example `è`) must be shown correctly in the console.

Other checks worth doing once on Windows:

- `bcdd check` of a file with CR LF line ends gives the same report as the same file with LF.
- `bcdd new Luce` creates `Luce.csc` as UTF-8 without a byte-order mark, with LF line ends.
- `bcdd new CON` is refused on every system, because `CON`, `PRN`, `AUX`, `NUL`, `COM1`..`COM9` and `LPT1`..`LPT9` are device names on Windows.
- A citation such as `OFFERS luce` does not find the file `Luce.csc` (the file name must match exactly, upper and lower case included).

### What was checked on Windows

Criteria W-1 to W-10 (W-11 belongs to the editor), run with the scripts in `tests/windows/`.
The same scripts run on Linux; the output folders are compared byte by byte with `UConfrontoCartelle.sh`.

| Criterion | How | Result |
|---|---|---|
| W-1 | `UConfrontoCheck.sh`: `check`, `check --strict`, `check --json`, `--lang it` and `--lang en`, on every `.csc` of `prove/` (369 files, 2214 runs; stdout, stderr and exit code of each) | 6642 files compared with the Linux ones, 0 differences, no CR byte in any output |
| W-2 | `UProvaScrittura.sh`: `new`, and `ratify` on an LF file and on a CR LF file | same bytes as Linux |
| W-3 | `UProvaScrittura.sh`: `save` of a CR LF text, of a text with BOM and `è`; replacement of an existing file; `--undo` | same bytes, same fingerprint as Linux |
| W-4 | `cmd.exe` through a pseudo console (`ssh -tt`): the message with `è` arrives as UTF-8, the code page is 850 before and after the command; to a file: UTF-8 without BOM, LF | checked on the byte stream; not on a visible screen, not in PowerShell |
| W-5 | `UProvaPercorsi.sh`: `Città.csc`, `Città Uso/Perché è.csc`, `--dir "Città Uso"` | same output as Linux |
| W-6 | `UProvaPercorsi.sh`: relative path with `/` and with `\`, `--dir` with and without final separator; in `cmd.exe` an absolute path with `\` and with `/` | same output as Linux once `\` is read as `/` in the paths written by the person |
| W-7, W-8 | `prove/w397/`: citation `luce` with `Luce.csc` on disk; citation `CON`; `bcdd check CON`; `bcdd check nul.csc`; `bcdd new CON` | same report as Linux; `check CON` answers "file not found" |
| W-9 | `UProvaRefine.sh` (answers from a file) and `rconsole.bat` through a pseudo console (answers typed in the console), with the fake model `ULlmFinto.exe` built from `tests/windows/llmfinto.nim` | `Luce.csc`, dialogue, requests and log identical to Linux; also the time limit (`BCDD_ATTESA_LLM=1`, exit code 4) and Ctrl-C during the wait (nothing written) |
| W-10 | `blocca.exe` (from `tests/windows/blocca.nim`) keeps `R01_Luce.csc` open without sharing for writing; `ratify` | `bcdd ratify: non riesco a scrivere R01_Luce.csc: Accesso negato.`, exit code 1, file unchanged, no temporary file left; after the lock is released the same command writes the same bytes as Linux |

Two differences from Linux are not errors: `bcdd new luce` is refused when `Luce.csc` exists (Windows file names do not
distinguish upper and lower case, so the second file cannot be created), and the text of a system error is in the language of Windows.

### Known limits of the Windows build

- The test suite (`nimble test`) runs on Linux only: it uses POSIX shell scripts as a fake language model. On Windows use the scripts in `tests/windows/`.
- `bcdd refine` starts the program `claude` with `CreateProcessW` (see "Language model" above). A `claude.cmd` is started through `cmd.exe`;
  its path must not contain `%`, `"`, `^` or `!`. If the Job Object cannot be assigned to the process, only `claude` is stopped at the time limit.
- The log of the language-model calls is written to `%USERPROFILE%\.local\state\bcdd\chiamate.tsv` unless `BCDD_REGISTRO` or `XDG_STATE_HOME` is set.

### Not verified

- `nimble build` itself (the test machine has no CA certificates, so nimble could not fetch `checksums`); the `nim c` command above is the verified one.
- The real `claude` program, Claude Code 2.1.330 (`%USERPROFILE%\.local\bin\claude.exe`), was called on Windows 11 with the build of
  commit 9cc71864: three `refine --json` steps in Italian on a copy of `prove/f2/refine/Luce.csc` (questions, answers, `--accept` of p1, s1, s2:
  file written correctly with LF, `check` without errors, dialogue written) and step 1 in English on a `Light.csc` (five relevant English questions).
  The search for `claude`, `claude.cmd` and the standard place, the message when it is missing and the stop of the process tree at the time limit
  were tried only with a fake `claude` (`tests/windows/UProvaClaude.bat`), never with the real one.
- PowerShell and a visible console screen (W-4); a disk with a case-sensitive directory.
- Windows 10, and any x86-64 machine other than the test one.

## `bcdd-editor` (window)

`bcdd-editor.exe` shows the same page as the Linux editor (HTML, CSS and JavaScript compiled into the executable) in a **WebView2** window.
It needs `bcdd.exe` in its own folder: every read and every write goes through `bcdd.exe`, started without a console window.

**Status.** Built and run on Windows 11 x86-64 (MSYS2 MinGW64, Nim 2.2.8, GCC 16.1.0, WebView2 Runtime 158). Under Windows the window
cannot be built from Linux: the commands below are the ones typed on the test machine.

### Prerequisites

- Everything required for `bcdd` (above), plus `g++` (it comes with `mingw-w64-x86_64-gcc`), `windres` (binutils), `curl` and `unzip`.
- The **WebView2 Runtime** (Evergreen). Windows 11 has it; on Windows 10 install the Evergreen Bootstrapper from Microsoft.
- The Nim package `checksums` already present in `~/.nimble/pkgs2` (as for `bcdd`: nimble cannot fetch packages on a machine without CA certificates).

### Build

From the folder that contains `BcddTool.nimble`, in the **MSYS2 MinGW64** shell:

```sh
export PATH="/c/Users/$USER/nim-2.2.8/bin:$PATH"
bash editor/windows/costruisci.sh
```

The script does four things and nothing else:

1. downloads `Microsoft.Web.WebView2` 1.0.2739.15 from nuget.org once and extracts only the header `WebView2.h` into `editor/windows/include/`
   (the header is not in the repository);
2. compiles the `webview` library (MIT, `editor/windows/webview/`) and `editor/windows/edwv2.cc` with `g++ -std=c++17` into `editor/windows/build/libedwv.a`;
3. compiles the icon and version resource `editor/windows/edicona.rc` with `windres`;
4. runs `nim c -d:release --app:gui --dynlibOverrideAll --path:<checksums> --passL:editor/windows/edicona.res --out:bcdd-editor.exe editor/bcddeditor.nim`
   and, for the tests, the same with `-d:bcddEditorProva` into `tests/bcdd-editor_prova.exe`.
   Use `--solo-rilascio` to skip the test version.

The result is one executable of about 3 MB. It imports only system DLLs (`kernel32`, `user32`, `ole32`, `shell32`, `shlwapi`, `comctl32`, `advapi32`, `msvcrt`);
`libstdc++` and `libgcc` are linked statically. `WebView2Loader.dll` is **not** needed: the library is built with its own loader, which finds the installed Runtime.

### Run

Copy `bcdd-editor.exe` and `bcdd.exe` into the same folder, then:

```sh
bcdd-editor.exe --dir C:\path\to\csc-folder
bcdd-editor.exe --lang it --dir C:\path\to\csc-folder    # Italian; the default is English
```

The window opens maximized. The language chosen in the window is remembered in `%APPDATA%\bcdd-editor\lingua`; the WebView2 profile is
`%LOCALAPPDATA%\bcdd-editor` (local, never roaming). Messages for a wrong command line (exit code 2) go to the console that started the program, or to the redirected
standard error. A new entity named `CON`, `PRN`, `AUX`, `NUL`, `COM1`-`COM9` or `LPT1`-`LPT9` is refused on every system, as `bcdd new` does.

### What was checked on Windows

The test version writes a trace file (`BCDD_EDITOR_TRACCIA`) and clicks buttons on the page (`BCDD_EDITOR_PROVA_CLIC`), as in the Linux suite.

| What | How | Result |
|---|---|---|
| The page loads and the bridge works in both directions | clicks from the trace, one drawing per click | nine drawings for the nine actions that build a three-entity folder |
| The files written are those of Linux | the same nine clicks on Windows (folder name with spaces and accents) and on Linux under Xvfb | the six `.csc` files are byte-identical, no CR LF |
| `bcdd.exe` is started without a console window and with `--lang` first | trace of every launch | yes |
| Stop while the language model works (Ctrl-C to `bcdd`) | slow fake model (25 s), click on Stop | `bcdd` ends with 130 within a fraction of a second, nothing written |
| Window active or not (the folder is read again on return) | another window in front, then back | both events seen |
| Maximized window, icon, release build in Italian | screenshot taken in the interactive session | as expected |
| Wrong command line | exit codes and messages, redirected and in a pseudo console | code 2 and the message |

### Known limits and not verified

- The editor tests replace the language model with the fake `llmfinto.exe` (see `tests/windows/`); the real `claude` was called through `bcdd refine` only (see the `bcdd` section).
- Windows 10, a second monitor with another DPI scale, and keyboard layouts other than the one of the test machine were not tried.
- The window title bar follows the accent colour chosen in Windows.
- With the WebView2 Runtime missing the window cannot be created: the program is written to report it and exit with code 2, but this case was not tried.
