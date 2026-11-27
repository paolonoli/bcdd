<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# Sources of the bundled files

Written for `bcdd` 1.0-beta and grammar 1.0-beta (release v1.0-beta.2 changes only `bcdd-editor`).

| File | Source | Tag | Commit | Checksum |
|---|---|---|---|---|
| `references/GRAMMATICA_F1.en.md` | root of `paolonoli/bcdd` | `v1.0-beta.2` | `302b4a35fc10985695b18da135d844546f5efce7` | sha256 `3e528ae9958140628e9a1c2f026d0b1770d269c86cd97368c08fa0c6db78f6ad` |
| `references/GRAMMATICA_F1.md` | same as above | same as above | same as above | sha256 `60f219df90a08b079aae6d2cdbfe4346fa8b063bf0ccb0acb45eeb9a9f8a76f3` |

This edition (1.0.0+directory) does not include the manual (`MANUALE_BCDD.en.md`, `MANUALE_BCDD.md`), the agent profiles or the scripts of 1.0.0. The manual is in the root of `paolonoli/bcdd` at the same tag and commit, and on <https://bcdd.nolisoft.it/>. The `bcdd` plugin provides the agent profiles from `claude-code/agents/` of `paolonoli/bcdd` (commit `4f5f2d4`: `bcdd-csc-author.md` md5 `a2753ba65902b68014482a2398e70a98`, `bcdd-csc-reviewer.md` md5 `39c5f40945d66fd9572711333cdaf38d`, as declared by the `bcdd` project).

The reference documents are declared by the `bcdd` project with sha256.

Licences: documents and profiles CC BY 4.0; see `LICENSE.md`.
