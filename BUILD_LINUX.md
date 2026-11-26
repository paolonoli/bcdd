# Building BCDD on Linux

This file describes how to build and test the `bcdd` command-line tool on Linux.
The `bcdd-editor` window has its own section, added separately below.

Tested on Debian 13 (x86-64) with Nim 2.2.10 and 2.4.x. The same steps apply to Ubuntu.

## `bcdd` (command line)

### Prerequisites

- A C compiler and the C library headers.
- Git (nimble uses it to fetch the dependency).
- Nim 2.0 or later. Versions 2.2.10 and 2.4.x have been used.
- The nimble package manager (installed together with Nim).
- A POSIX shell (`sh`, `bash`) and the usual coreutils: the test suite uses small shell scripts as a fake language model.

On Debian or Ubuntu:

```sh
sudo apt install build-essential git curl xz-utils
```

Install Nim with `choosenim` or from <https://nim-lang.org/install_unix.html>, then make sure `~/.nimble/bin` is in `PATH`:

```sh
export PATH="$HOME/.nimble/bin:$PATH"
nim --version
nimble --version
```

### Build

From the folder that contains `BcddTool.nimble`:

```sh
nimble install --depsOnly -y     # installs the only dependency, `checksums`
nimble build -d:release
```

The result is a single executable, `./bcdd`.

### Test

```sh
nimble test
```

`nimble test` builds `bcdd` and a test build of it, then runs the whole suite.
Judge the result only by the line that the suite prints at the end, for example:

```
controlli: 6743/6743 PASS; criteri non riusciti: 0
```

The numbers are `passed/total`. The suite is correct when every check passes and `criteri non riusciti` (failed criteria) is `0`.
Do not rely on the exit code of `nimble test` alone.

The test build reads the variable `BCDD_LLM` to replace the real language model with a fake one.
The release build (`./bcdd`) never reads it and always calls `claude -p`.

### Language model (`bcdd refine`, Complete)

`bcdd refine`, and the Complete button of the editor that uses it, call Claude Code. It must be installed and signed in
(subscription or API key, at the user's own cost); `bcdd` does not install it and does not ask for the sign-in.

- The exact command (the request goes in on standard input, the answer is read from standard output; no other program is started):
  `claude -p --tools "" --output-format text --no-session-persistence --model sonnet` (`veloce`) or `--model opus` (`accurato`).
- `claude` is looked for in `PATH`, then in the standard place of the native installer of Claude Code: `$HOME/.local/bin/claude`. Nowhere else, and the command is not configurable in the release build.
  When it is not found, `bcdd refine` says so, names the places searched and exits with code 4; the file is not changed.

### Minimal check

```sh
./bcdd --lang it check prove/01_minima.csc
./bcdd --lang en check prove/01_minima.csc
```

Both commands must end with a line saying that there are no errors (`esito: nessun errore` in Italian, `outcome: no errors` in English)
and exit with code 0. Without `--lang` and without the variable `BCDD_LANG`, the output is in English.

If `bcdd` is also installed in `~/.nimble/bin`, that copy may be older than the one just built.
Always run the new one with an explicit path (`./bcdd`).

## `bcdd-editor` (window)

`bcdd-editor` is a GTK3 window that contains a WebKit2GTK 4.1 view. The page (HTML, CSS, JavaScript) is compiled into the executable.
The editor writes nothing by itself: every change goes through `bcdd` (`check --json`, `save`, `new`), started as a separate process.
The Windows build uses the same page and the same logic with WebView2 instead of GTK and WebKit (see `BUILD_WINDOWS.md`); only
`editor/edgtkfin.nim` (Linux) and `editor/edwebview2.nim` (Windows) differ.

### Prerequisites

The prerequisites of `bcdd`, plus the development files of GTK 3 and WebKit2GTK **4.1** (4.0 is not used) and `pkg-config`:

```sh
sudo apt install libgtk-3-dev libwebkit2gtk-4.1-dev pkg-config
```

To run the editor test suite, also `xvfb` and `xdotool` (the windows are opened on a virtual display, never on the real one).

### Build

```sh
nimble editor
```

This builds `./bcdd-editor` and, for the tests, `tests/bcdd-editor_prova`. Put `bcdd-editor` in the same folder as `bcdd`: the editor looks for `bcdd` next to itself.

### Run

```sh
./bcdd-editor                         # asks for the folder containing the .csc files and remembers it
./bcdd-editor --dir FOLDER            # opens FOLDER directly
./bcdd-editor --lang it --dir FOLDER  # Italian; without --lang or BCDD_LANG the system language is used; the choice in the window is remembered
```

### Test

```sh
BCDD_LANG=it nimble testeditor
```

The suite builds everything, opens the editor under Xvfb, clicks through it and prints a last line `controlli: N/N PASS`.
Judge the result from that line: `nimble` may return 0 even when a check fails.
