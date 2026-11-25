# BCDD

BCDD (Behavioural Contract-Driven Design) is a language for writing the behaviour of a system as contracts, one *capability
state contract* (CSC) per file. This repository holds the source of the two programs that read and help write those files.
This is version **1.0-beta**: the language and the programs work, but they have not had the field use of a final release.

Manual and grammar, in English and in Italian: <https://bcdd.nolisoft.it/>

## The programs

- `bcdd`, the command-line tool: `new`, `check`, `refine`, `ratify`. Written in Nim, source in `src/`.
- `bcdd-editor`, a window around `bcdd` for editing CSC files: GTK 3 and WebKit2GTK on Linux, WebView2 on Windows
  (work in progress). Source in `editor/`.

## Build

You need Nim 2.0 or later and a C compiler. In short:

```sh
nimble build -d:release        # builds ./bcdd
nimble test                    # builds and runs the test suite of bcdd
nimble editor                  # builds ./bcdd-editor
```

The complete steps, with the dependencies and the tested versions, are in [`BUILD_LINUX.md`](BUILD_LINUX.md) and
[`BUILD_WINDOWS.md`](BUILD_WINDOWS.md).

## Use

```sh
bcdd check FILE.csc              # check a CSC file and print the report
bcdd --lang it check FILE.csc    # the same, with messages in Italian
bcdd new Name                    # create Name.csc from a skeleton
```

The messages are in English by default; `--lang it` (before the command) or the variable `BCDD_LANG=it` switches `bcdd`
and `bcdd-editor` to Italian. `bcdd refine` runs a round of questions through a language model and needs the `claude`
command; `check` and `new` do not. `bcdd ratify` records an approved contract line.

The folders `prove/`, `esempi/` and `tests/` hold the test material: small CSC files with the expected report of
`bcdd`, and the test programs that run them.

## Licence

Source code: BSD 3-Clause, see [`LICENSE`](LICENSE). The documentation published on the site has its own licence, stated
in each document. Third-party code under `editor/windows/webview` and the notices in `editor/THIRD_PARTY.md` keep their
own licences.

## Contact

<bcdd@nolisoft.it>
