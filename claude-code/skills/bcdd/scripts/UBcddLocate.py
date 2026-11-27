#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 Noli Paolo
# 001:1:1 UBcddLocate.py - find the `bcdd` program (read only, no network, no download)
# 001:1:2 Execution Mode: Unattended
# 001:1:3 Privilege Level: User
# 001:1:4 Exit codes: 0 found; 4 not found; 5 incorrect arguments.
# 001:1:5 The script never runs `bcdd`, never reads a version and never checks a CSC.

import argparse
import json
import os
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple

# 001:1:6 Constants
SCRIPT_NAME = Path(__file__).name
LOG_FILE = Path(tempfile.gettempdir()) / "{}_{}.log".format(
    SCRIPT_NAME[:-3], datetime.now().strftime("%y%m%d%H%M%S"))
ENV_VAR = "BCDD_BIN"
DOWNLOAD_URLS = [
    "https://github.com/paolonoli/bcdd/releases/tag/v1.0-beta.2",
    "https://bcdd.nolisoft.it/download/",
]
EXIT_OK = 0
EXIT_NOT_FOUND = 4
EXIT_ARGS = 5


class ArgumentError(Exception):
    """001:1:7 Raised instead of the argparse exit code 2, which collides with bcdd."""


class QuietParser(argparse.ArgumentParser):
    def error(self, message):  # 001:1:8 override: argparse would exit with 2
        raise ArgumentError(message)


def write_log(text: str) -> None:
    """001:2:1 Append to the log in the temporary folder; never fail because of it."""
    try:
        with LOG_FILE.open("a", encoding="utf-8", errors="replace") as handle:
            handle.write(text + "\n")
    except OSError:
        pass


def is_runnable(candidate: str) -> bool:
    """001:3:1 True when the candidate is an existing, executable file."""
    return os.path.isfile(candidate) and os.access(candidate, os.X_OK)


def editor_candidates() -> List[str]:
    """001:3:2 bcdd in the folder of bcdd-editor, when bcdd-editor is in the PATH."""
    found = shutil.which("bcdd-editor")
    if not found:
        return []
    folder = Path(found).resolve().parent
    return [str(folder / name) for name in ("bcdd", "bcdd.exe")]


def locate(explicit: Optional[str] = None) -> Tuple[Optional[str], str, List[str]]:
    """001:3:3 Return (absolute path or None, source, candidates tried).

    Order: explicit argument, BCDD_BIN, PATH, folder of bcdd-editor. An explicit
    candidate (argument or BCDD_BIN) that does not exist stops the search.
    """
    tried: List[str] = []
    # 001:3:4 Explicit candidates: no fall-back to the next one
    if explicit:
        tried.append("--bcdd " + explicit)
        if is_runnable(explicit):
            return os.path.abspath(explicit), "arg", tried
        return None, "arg", tried
    env_value = os.environ.get(ENV_VAR)
    if env_value:
        tried.append("{}={}".format(ENV_VAR, env_value))
        if is_runnable(env_value):
            return os.path.abspath(env_value), "env", tried
        return None, "env", tried
    # 001:3:5 PATH (shutil.which honours PATHEXT on Windows)
    tried.append("PATH")
    on_path = shutil.which("bcdd")
    if on_path:
        return os.path.abspath(on_path), "path", tried
    # 001:3:6 Folder of bcdd-editor
    editor = editor_candidates()
    if editor:
        tried.append("folder of bcdd-editor: " + str(Path(editor[0]).parent))
        for candidate in editor:
            if is_runnable(candidate):
                return os.path.abspath(candidate), "editor", tried
    else:
        tried.append("folder of bcdd-editor (bcdd-editor not in PATH)")
    return None, "none", tried


def main(argv: Optional[List[str]] = None) -> int:
    """001:4:1 Command line entry point."""
    parser = QuietParser(description="Find the bcdd program.")
    parser.add_argument("--bcdd", metavar="PATH", help="explicit path of bcdd")
    parser.add_argument("--json", action="store_true", help="JSON output")
    try:
        args = parser.parse_args(argv)
    except ArgumentError as exc:
        print("UBcddLocate.py: incorrect arguments: {}".format(exc), file=sys.stderr)
        return EXIT_ARGS

    path, source, tried = locate(args.bcdd)
    write_log("tried: {}; found: {}; source: {}".format(tried, path, source))
    if path:
        if args.json:
            print(json.dumps({"ok": True, "path": path, "source": source}))
        else:
            print(path)
        return EXIT_OK

    # 001:4:2 Not found: report, take no action
    if args.json:
        print(json.dumps({"ok": False, "tried": tried, "download": DOWNLOAD_URLS}))
    else:
        print("bcdd not found")
        for item in tried:
            print("tried: " + item)
        for url in DOWNLOAD_URLS:
            print("download: " + url)
        print("Propose the download to the user; verify against SHA256SUMS.")
        print("log: " + str(LOG_FILE))
    return EXIT_NOT_FOUND


if __name__ == "__main__":
    sys.exit(main())
