<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# Sources of the bundled files

Written for `bcdd` 1.0-beta and grammar 1.0-beta (release v1.0-beta.2 changes only `bcdd-editor`).

| File | Source | Tag | Commit | Checksum |
|---|---|---|---|---|
| `references/GRAMMATICA_F1.en.md` | root of `paolonoli/bcdd` | `v1.0-beta.2` | `302b4a35fc10985695b18da135d844546f5efce7` | sha256 `3e528ae9958140628e9a1c2f026d0b1770d269c86cd97368c08fa0c6db78f6ad` |
| `references/GRAMMATICA_F1.md` | same as above | same as above | same as above | sha256 `60f219df90a08b079aae6d2cdbfe4346fa8b063bf0ccb0acb45eeb9a9f8a76f3` |
| `references/MANUALE_BCDD.en.md` | same as above | same as above | same as above | sha256 `c1e3ca9a366774b06b55e92c2371c42dfb4cf3a41330f36074fc61a58ec29e6f` |
| `references/MANUALE_BCDD.md` | same as above | same as above | same as above | sha256 `c6da53c2d66a328b09d3a50a103fde7126f178bf359f72edd5ba62d2b3a77dea` |
| `agents/bcdd-csc-author.md` | `claude-code/agents/` of `paolonoli/bcdd` | none (see note) | `013f7092e08e71cfe60ea7b57f264a74224351cc` | md5 `98c3df8551d80a998b94c0e7a5c573db` |
| `agents/bcdd-csc-reviewer.md` | same as above | same as above | same as above | md5 `813fee1c4d29e1c9f07ae17aca3d1b1a` |

The two agent profiles come from commit `013f7092e08e71cfe60ea7b57f264a74224351cc` of `paolonoli/bcdd`, published on 2026-11-26. No tag contains this commit: the tag `v1.0-beta.2` has the earlier profiles.

The reference documents are declared by the `bcdd` project with sha256 and the agent profiles with md5, so each row uses the algorithm of its source. The md5 sums only check that a copy is intact.

Licences: documents and profiles CC BY 4.0, scripts BSD-3-Clause; see `LICENSE.md`.
