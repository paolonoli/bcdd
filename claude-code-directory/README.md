<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Noli Paolo. Distributed under the Creative Commons Attribution 4.0 International licence. -->

# bcdd — Claude Code plugin

This plugin helps Claude write, check and review BCDD files (`.csc`). A BCDD file contains Capability State Contracts (CSCs) and the entities that provide and use them. BCDD (Behavioural Contract-Driven Design) is described at <https://bcdd.nolisoft.it/en/>.

The plugin contains:

- the `bcdd` skill, which explains how to run `bcdd check`, `bcdd new` and, only on explicit request, `bcdd refine` and `bcdd ratify`, and how to read their output;
- the `bcdd:bcdd-csc-author` subagent, which writes and corrects CSCs and checks them with `bcdd`;
- the `bcdd:bcdd-csc-reviewer` subagent, which reviews CSCs without changing them.

## Requirements

The plugin uses the `bcdd` program from release v1.0-beta.2 (`bcdd` 1.0-beta). It looks for `bcdd` in `BCDD_BIN`, on the `PATH`, then next to `bcdd-editor`. If `bcdd` is not found, the skill proposes the download; it downloads or installs nothing unless the user asks. The release is published at <https://github.com/paolonoli/bcdd/releases/tag/v1.0-beta.2>. `bcdd refine` also needs the `claude` program.

This plugin does not include the manual or scripts. The manual is at <https://bcdd.nolisoft.it/en/manual/>.

## Licence

The documents (including this file) and the agent profiles are under CC BY 4.0. See `skills/bcdd/LICENSE.md`. The BCDD and CSC logos are not covered by this licence.
