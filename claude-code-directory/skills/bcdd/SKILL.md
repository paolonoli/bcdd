---
name: bcdd
description: "Use this skill to write, check and review BCDD files (`.csc`), which contain Capability State Contracts (CSCs) and the entities that provide and use them, using the `bcdd` command-line program. Triggers include: BCDD, Behavioural Contract-Driven Design, CSC, capability state contract, .csc files, `bcdd check --strict`, `--dir` for the parts of an entity, `bcdd new`, bcdd exit codes 0/1/2/3, GUARANTEE, ASSUME, VERIFY BY, SCENARIO, ENTITY with OFFERS/USES, 'write a CSC', 'review a CSC', 'make bcdd check pass', 'scrivere una CSC', 'verificare le CSC con bcdd', 'rivedere una CSC', finding or installing bcdd, the bcdd-csc-author and bcdd-csc-reviewer agents. Do NOT use it for Design by Contract annotations inside C++ source code, for linting the acceptance criteria of a prose design contract, or to change the BCDD grammar or add checks to `bcdd` (ask the language maintainers). It runs `bcdd refine` and `bcdd ratify` only when the user explicitly asks."
version: "1.0.0+directory"
---
<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# bcdd

## What BCDD and bcdd are

BCDD (Behavioural Contract-Driven Design) is a language for describing behaviour at the boundaries of a system. A `.csc` file contains blocks: `CSC … END` (each CSC describes one boundary), `ENTITY … END`, and optionally `BINDING`, `VERIFICATION` and `PROFILE`. Entities provide and use CSCs (`ENTITY` with `OFFERS` and `USES`) and can be split into parts that live in several folders.

`bcdd` is the command-line program that reads those files and checks them. `bcdd-editor` is a graphical editor that runs `bcdd`: it is not a second checker.

This skill is written for `bcdd` 1.0-beta and grammar 1.0-beta. The latest release is v1.0-beta.2, which changes only `bcdd-editor`. `references/SOURCES.md` gives the tag, the commit and the checksums of the reference documents.

This edition (1.0.0+directory) contains no scripts and no copy of the manual: `CHANGELOG.md` lists the differences from 1.0.0.

## Finding bcdd

Look for `bcdd` before the first check of a session, in this order, and stop at the first candidate that exists and is executable:

1. the environment variable `BCDD_BIN`, when it is set and not empty: its value is the path of the program;
2. `bcdd` on the `PATH` (`bcdd.exe` on Windows);
3. `bcdd` or `bcdd.exe` in the folder that contains `bcdd-editor`, when `bcdd-editor` is on the `PATH`. If `bcdd-editor` is a link, use the folder of the file it points to.

If `BCDD_BIN` is set and not empty but does not name an existing, executable file, treat it as an error: report it and do not fall back to the next candidate. Report the absolute path you found and which of the three places gave it; if nothing is found, report the places you tried. `bcdd` has no version option, so report no version.

If `bcdd` is not found, **propose** the download to the user. Do not download or install anything without being asked. The release is published at <https://github.com/paolonoli/bcdd/releases/tag/v1.0-beta.2> (packages `bcdd-1.0-beta.2-*`; see also <https://bcdd.nolisoft.it/en/download.html>). Check the package against `SHA256SUMS` before you use it: on Linux, `sha256sum -c --ignore-missing SHA256SUMS`; on Windows, `Get-FileHash -Algorithm SHA256`.

## Checking with bcdd check

```
bcdd check --strict [--dir FOLDER]... FILE
```

One file per run; for many files see "Compact verdict on many files". The folder that contains the file is always searched. A relative `--dir` is resolved from the current folder. The order of the `--dir` options matters: a CSC with the same name in a later folder is not seen. For an entity whose parts are in several folders, pass one `--dir` for each folder.

| Exit code | Meaning |
|---|---|
| 0 | no errors and no unrecognised lines |
| 1 | errors |
| 3 | unrecognised lines only |
| 2 | the file could not be checked, or the command line is incorrect |

Read these sections of the report: 1 (errors), 4 (pending approval), 5 (unrecognised lines), 7 (CSCs named but not checked), 14 (to be judged) and 15 (checks not executed). Section 7 lists what an entity, a `BINDING`, a `VERIFICATION` or an `IMPORT PROFILE` cites and `bcdd` did not find. If one of these is a **part** of an entity, E14, E16 and E17 are suspended for that entity. Add the missing `--dir` and run the check again until section 7 is empty. The last line of the report is `outcome: …` (`esito: …` with `--lang it` or `BCDD_LANG=it`).

`no errors` means that the file is well formed. It does not mean that the contract is correct or complete.

## Compact verdict on many files

When there are many files, run `bcdd check --strict` on each file, one file at a time, and report one line for each file and a final `VERDICT` line. For one file, run `bcdd check` directly.

- **Files.** A folder stands for the `.csc` files directly inside it, in alphabetical order; include its subfolders only when the user asks. Check each file once.
- **Folders of the parts.** Pass the same `--dir` options, in the same order, to every file. Write them as absolute paths, resolved from the current folder before you change folder, and drop a folder that appears twice, keeping the first. Run each check from the folder that contains the file.
- **Language.** For the verdict, pass the language only with `--lang` before the subcommand (`bcdd --lang it check --strict ...`), and run `bcdd` without `BCDD_LANG` set.
- **One line per file:** `<code>  <label>  <file>  <outcome line>`. The label is `OK` for 0, `ERRORS` for 1, `UNRECOGNISED` for 3 and `UNCHECKED` for 2. Any other code, a run that does not start, or a run that does not finish within 120 seconds (stop it) counts as 2. The outcome line is the last line that starts with `outcome: ` or `esito: `, copied unchanged, or `-` if there is none (for a timeout or a run that did not start, say which instead).
- **Nothing to check.** If a file or folder named by the user does not exist, or no `.csc` file is found, report it and give no verdict: never write `VERDICT PASS` with `files=0`.
- **Final line:** `VERDICT PASS files=3 exit0=3 exit1=0 exit2=0 exit3=0 -> exit 0`, with `FAIL` instead of `PASS` when any file has a code other than 0. The final code is the most severe code found, in the order 2, 1, 3, 0.

`VERDICT PASS` means only that every file exited 0. A citation that is not found does not change the exit code, so a file whose closure was suspended (a part in section 7) passes. The verdict does not show sections 4, 7, 14 and 15: for files with entities, read section 7 with `bcdd check`.

The verdict comes from the exit code of `bcdd` only. The `outcome` line is copied unchanged and never changes the verdict. For each file with a code other than 0, report the output of `bcdd` verbatim.

## Creating with bcdd new

`bcdd new NAME` creates `NAME.csc` in the current folder. `NAME` is one word: it contains no `-` and no path, is not a keyword, and is not a name that Windows reserves (`CON`, `PRN`, `AUX`, `NUL`, `COM1`–`COM9`, `LPT1`–`LPT9`). If the file already exists, `bcdd` exits with code 1 and does not touch it. Run `bcdd check` on the skeleton immediately.

## Commands that need the user

- `bcdd refine` uses a real language model through `claude` and asks interactive questions. Run it only when the user asks. Never run it in automated tests. Never answer its questions on behalf of the user.
- `bcdd ratify` approves lines. Run it only after the user has explicitly approved those lines in the conversation, and only with the decision reference (`D-` followed by digits) that the user gave. Never run it on your own initiative, never "as a test", and never propose a reference yourself.
- `STATUS RATIFIED BY` is never written by hand. An approved CSC is not modified. To change it, write a new `VERSION` of the CSC in the same file, in place of the old one, with `STATUS HYPOTHESIS` in the header. A line whose text changes goes back to `STATUS HYPOTHESIS`. A comment can be corrected without a new `VERSION` (grammar §7.2).

## Message language

`bcdd` writes its messages in English by default. Put `--lang it` before the subcommand (`bcdd --lang it check ...`), or set `BCDD_LANG=it` when you run `bcdd` directly. The compact verdict copies the `outcome:` or `esito:` line unchanged, so the verdict does not depend on the language.

## What bcdd does not check

`bcdd` checks form, names, types and the closure of entities. The grammar document, section 14, lists what it leaves to a reviewer, for example whether a verbal line is vague and whether a guarantee is verifiable in practice. That is the task of the reviewer agent. Read that section instead of keeping a copy of the list here.

## The two agents

| Agent | Role | Tools |
|---|---|---|
| `bcdd:bcdd-csc-author` | writes CSCs and entities from requirements and runs `bcdd check --strict` until the exit code is 0 | Read, Write, Edit, Bash, Glob, Grep, WebFetch |
| `bcdd:bcdd-csc-reviewer` | independent reviewer: reports what `bcdd check` cannot see and never modifies the reviewed files | Read, Bash, Glob, Grep, WebFetch |

The normal flow is: the author writes, `check` reaches 0, the reviewer reports, the user decides, and only then does `bcdd ratify` run.

The `bcdd` plugin loads the two agents together with this skill, as `bcdd:bcdd-csc-author` and `bcdd:bcdd-csc-reviewer`: there is nothing to copy. When an agent runs as a subagent, its questions go back to the caller.

In the `bcdd` repository the two profiles are in `claude-code/agents/`.

## References

The grammar, in English and Italian, is in `references/` next to this file, and in the root of the `bcdd` repository. `references/SOURCES.md` gives the tag, commit and checksums it corresponds to.

The manual is not included in this edition: read it on the site (<https://bcdd.nolisoft.it/en/manual/>) or in the root of the `bcdd` repository (<https://github.com/paolonoli/bcdd>). If a file is missing, use the root of the `bcdd` repository or the site, and say which source you used.

## Licence and citation

Licence terms are in `LICENSE.md`: documents, agent profiles and this file CC BY 4.0. This edition contains no scripts. The BCDD and CSC logos are excluded.

To cite BCDD, use the DOI 10.5281/zenodo.24571473.
