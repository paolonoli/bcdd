<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# Changelog

## 1.0.0 — 2026-11-26

First release.

- `SKILL.md`: writing, checking and reviewing BCDD files (`.csc`) with the `bcdd` program, version 1.0-beta (release v1.0-beta.2).
- `scripts/UBcddLocate.py`: finds `bcdd` (argument, `BCDD_BIN`, `PATH`, folder of `bcdd-editor`).
- `scripts/UBcddVerdict.py`: compact verdict of `bcdd check --strict` on many files, derived from the exit codes. Duplicate `--dir` options are removed (same folder after `abspath`); the child process does not inherit `BCDD_LANG`.
- `agents/`: the profiles `bcdd-csc-author` and `bcdd-csc-reviewer`.
- `references/`: grammar and manual, in English and Italian, with their provenance in `references/SOURCES.md`.
- Tested on Windows with Python 3.13, before the last change to `scripts/UBcddVerdict.py` (duplicate `--dir` options, `BCDD_LANG`); that change is tested on Linux.
