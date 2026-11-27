<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# Changelog

## 1.0.0+directory — 2026-11-27

Edition of 1.0.0 for the Claude plugin directory. The rules for writing, checking and reviewing BCDD files are those of 1.0.0; only the following changes.

- No scripts. `SKILL.md` describes in words how to find `bcdd` (`BCDD_BIN`, `PATH`, folder of `bcdd-editor`; there is no `--bcdd` argument) and how to build the compact verdict on many files (`bcdd check --strict` on each file, verdict from the exit codes only, same reading rules as `scripts/UBcddVerdict.py` of 1.0.0).
- `references/`: the grammar in English and Italian, identical to 1.0.0, and `SOURCES.md`. The manual is not included: `SKILL.md` refers to <https://bcdd.nolisoft.it/> and to the root of the `bcdd` repository.
- The agents are named `bcdd:bcdd-csc-author` and `bcdd:bcdd-csc-reviewer`, as the `bcdd` plugin loads them. This edition has no `agents/` folder: the plugin provides the profiles.
- No `README.md` and no `site/` folder.

## 1.0.0 — 2026-11-26

First release.

- `SKILL.md`: writing, checking and reviewing BCDD files (`.csc`) with the `bcdd` program, version 1.0-beta (release v1.0-beta.2).
- `scripts/UBcddLocate.py`: finds `bcdd` (argument, `BCDD_BIN`, `PATH`, folder of `bcdd-editor`).
- `scripts/UBcddVerdict.py`: compact verdict of `bcdd check --strict` on many files, derived from the exit codes. Duplicate `--dir` options are removed (same folder after `abspath`); the child process does not inherit `BCDD_LANG`.
- `agents/`: the profiles `bcdd-csc-author` and `bcdd-csc-reviewer`.
- `references/`: grammar and manual, in English and Italian, with their provenance in `references/SOURCES.md`.
- Tested on Windows with Python 3.13, before the last change to `scripts/UBcddVerdict.py` (duplicate `--dir` options, `BCDD_LANG`); that change is tested on Linux.
