<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# Changelog

## 1.0.1 — 2026-11-27

- `SKILL.md` and `scripts/UBcddLocate.py`: the download page of the site is <https://bcdd.nolisoft.it/en/download.html>; the old address `https://bcdd.nolisoft.it/download/` answers 404.
- `agents/`: the profiles of commit `4f5f2d4` of `paolonoli/bcdd`. When a file is missing under `references/`, the agents use the file with the same name in the root of the repository and, for the manual, also <https://bcdd.nolisoft.it/en/manual/>.
- `SKILL.md`, "The two agents": when the skill is installed as the `bcdd` plugin, the agents are already loaded and are not copied.
- `SKILL.md`, "References": the manual of the site is <https://bcdd.nolisoft.it/en/manual/>.
- `references/SOURCES.md`: commit and checksums of the new profiles.

## 1.0.0 — 2026-11-26

First release.

- `SKILL.md`: writing, checking and reviewing BCDD files (`.csc`) with the `bcdd` program, version 1.0-beta (release v1.0-beta.2).
- `scripts/UBcddLocate.py`: finds `bcdd` (argument, `BCDD_BIN`, `PATH`, folder of `bcdd-editor`).
- `scripts/UBcddVerdict.py`: compact verdict of `bcdd check --strict` on many files, derived from the exit codes. Duplicate `--dir` options are removed (same folder after `abspath`); the child process does not inherit `BCDD_LANG`.
- `agents/`: the profiles `bcdd-csc-author` and `bcdd-csc-reviewer`.
- `references/`: grammar and manual, in English and Italian, with their provenance in `references/SOURCES.md`.
- Tested on Windows with Python 3.13, before the last change to `scripts/UBcddVerdict.py` (duplicate `--dir` options, `BCDD_LANG`); that change is tested on Linux.
