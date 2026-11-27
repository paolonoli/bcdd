#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2026 Noli Paolo
# 001:1:1 UBcddVerdict.py - compact verdict of `bcdd check` on many .csc files
# 001:1:2 Execution Mode: Unattended
# 001:1:3 Privilege Level: User
# 001:1:4 The verdict comes ONLY from the exit code of bcdd (0/1/2/3). The last
# 001:1:5 `outcome:`/`esito:` line is copied verbatim and never changes the verdict.
# 001:1:6 The script does not read CSC files and does not count errors.
# 001:1:7 Exit codes: 0/1/2/3 worst per-file code (severity 2 > 1 > 3 > 0);
# 001:1:8 4 bcdd not found; 5 incorrect arguments or no .csc file.

import argparse
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

sys.dont_write_bytecode = True  # 001:1:9 never leave __pycache__ next to the script

# 001:1:10 Constants
SCRIPT_NAME = Path(__file__).name
SCRIPT_DIR = Path(__file__).resolve().parent
LOG_FILE = Path(tempfile.gettempdir()) / "{}_{}.log".format(
    SCRIPT_NAME[:-3], datetime.now().strftime("%y%m%d%H%M%S"))
DEFAULT_TIMEOUT = 120
EXIT_NOT_FOUND = 4
EXIT_ARGS = 5
LABELS = {0: "OK", 1: "ERRORS", 2: "UNCHECKED", 3: "UNRECOGNISED"}
OUTCOME_PREFIXES = ("outcome: ", "esito: ")
SEVERITY = (2, 1, 3, 0)


class ArgumentError(Exception):
    """001:1:11 Raised instead of the argparse exit code 2, which collides with bcdd."""


class QuietParser(argparse.ArgumentParser):
    def error(self, message):  # 001:1:12 override: argparse would exit with 2
        raise ArgumentError(message)


def write_log(text: str) -> None:
    """001:2:1 Append to the log in the temporary folder; never fail because of it."""
    try:
        with LOG_FILE.open("a", encoding="utf-8", errors="replace") as handle:
            handle.write(text + "\n")
    except OSError:
        pass


def import_locator():
    """001:2:2 Import UBcddLocate.py from this folder; None when it is missing."""
    sys.path.insert(0, str(SCRIPT_DIR))
    try:
        import UBcddLocate  # noqa: E402
        return UBcddLocate
    except ImportError:
        return None


def expand_targets(targets: List[str], recursive: bool) -> List[Path]:
    """001:3:1 Files stay as given; folders expand to *.csc in alphabetical order."""
    found: List[Path] = []
    for target in targets:
        path = Path(os.path.abspath(target))
        if path.is_dir():
            pattern = path.rglob("*.csc") if recursive else path.glob("*.csc")
            found.extend(sorted(p for p in pattern if p.is_file()))
        elif path.is_file():
            found.append(path)
        else:
            raise ArgumentError("target not found: {}".format(target))
    unique: List[Path] = []
    for item in found:
        if item not in unique:
            unique.append(item)
    return unique


def build_command(bcdd: str, csc: Path, dirs: List[str], strict: bool,
                  lang: Optional[str]) -> List[str]:
    """001:3:2 bcdd [--lang L] check [--strict] [--dir D]... FILE (only `check`)."""
    command = [bcdd]
    if lang:
        command += ["--lang", lang]
    command.append("check")
    if strict:
        command.append("--strict")
    for folder in dirs:
        command += ["--dir", folder]
    command.append(str(csc))
    return command


def run_bcdd(command: List[str], cwd: Path, timeout: int) -> Tuple[int, str, str, Optional[str]]:
    """001:3:3 Run one check with output on temporary files (no pipes, no hang).

    Returns (code, stdout, stderr, note). Timeout and launch failure give code 2.
    """
    with tempfile.TemporaryFile() as out_file, tempfile.TemporaryFile() as err_file:
        try:
            # 002:3:1 The child never inherits BCDD_LANG: the language comes only from --lang
            child_env = {k: v for k, v in os.environ.items() if k != "BCDD_LANG"}
            proc = subprocess.Popen(command, cwd=str(cwd), stdin=subprocess.DEVNULL,
                                    stdout=out_file, stderr=err_file, env=child_env)
        except OSError as exc:
            return 2, "", "", "cannot run bcdd: {}".format(exc)
        note = None
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                pass
            code = 2
            note = "timeout after {} s".format(timeout)
        out_file.seek(0)
        err_file.seek(0)
        stdout = out_file.read().decode("utf-8", errors="replace")
        stderr = err_file.read().decode("utf-8", errors="replace")
    return code, stdout, stderr, note


def last_outcome(stdout: str) -> str:
    """001:3:4 Last line starting with `outcome: ` or `esito: `, verbatim; '-' if none."""
    result = "-"
    for line in stdout.splitlines():
        if line.startswith(OUTCOME_PREFIXES):
            result = line
    return result


def classify(code: int) -> Tuple[int, str]:
    """001:3:5 Severity bucket and label from the exit code alone."""
    if code in LABELS:
        return code, LABELS[code]
    return 2, "UNCHECKED"


def worst_exit(counts: Dict[int, int]) -> int:
    """001:3:6 Severity 2 > 1 > 3 > 0."""
    for code in SEVERITY:
        if counts.get(code, 0):
            return code
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    """001:4:1 Command line entry point."""
    parser = QuietParser(description="Compact verdict of `bcdd check` on many .csc files.")
    parser.add_argument("--bcdd", metavar="PATH")
    parser.add_argument("--dir", action="append", default=[], metavar="FOLDER")
    parser.add_argument("--no-strict", action="store_true")
    parser.add_argument("--lang", metavar="LANG",
                        help="message language for bcdd; BCDD_LANG of the parent is NOT passed to bcdd")  # 002:4:2
    parser.add_argument("--recursive", action="store_true")
    parser.add_argument("--details", choices=("full", "none"), default="full")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT, metavar="SEC")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("targets", nargs="+", metavar="TARGET")
    try:
        args = parser.parse_args(argv)
        if args.timeout < 1:
            raise ArgumentError("--timeout must be at least 1")
    except ArgumentError as exc:
        print("UBcddVerdict.py: incorrect arguments: {}".format(exc), file=sys.stderr)
        return EXIT_ARGS

    # 001:4:2 Locate bcdd (UBcddLocate.py is a sibling script)
    locator = import_locator()
    if locator is None:
        print("bcdd not found: UBcddLocate.py is missing next to this script; "
              "fetch both scripts together", file=sys.stderr)
        return EXIT_NOT_FOUND
    bcdd, source, tried = locator.locate(args.bcdd)
    if not bcdd:
        print("bcdd not found (tried: {}). Run UBcddLocate.py for the details."
              .format("; ".join(tried)), file=sys.stderr)
        return EXIT_NOT_FOUND

    # 001:4:3 Targets
    try:
        files = expand_targets(args.targets, args.recursive)
    except ArgumentError as exc:
        print("UBcddVerdict.py: incorrect arguments: {}".format(exc), file=sys.stderr)
        return EXIT_ARGS
    if not files:
        print("UBcddVerdict.py: no .csc file found", file=sys.stderr)
        return EXIT_ARGS
    # 002:4:1 Drop duplicate --dir after abspath, keeping the first occurrence order
    dirs = list(dict.fromkeys(os.path.abspath(d) for d in args.dir))

    # 001:4:4 One process per file
    counts: Dict[int, int] = {0: 0, 1: 0, 2: 0, 3: 0}
    rows: List[Dict[str, object]] = []
    details: List[str] = []
    for csc in files:
        command = build_command(bcdd, csc, dirs, not args.no_strict, args.lang)
        code, stdout, stderr, note = run_bcdd(command, csc.parent, args.timeout)
        bucket, label = classify(code)
        counts[bucket] += 1
        outcome = note if note else last_outcome(stdout)
        write_log("{} -> exit {}\n--stdout--\n{}\n--stderr--\n{}".format(
            command, code, stdout, stderr))
        rows.append({"file": str(csc), "code": code, "label": label,
                     "outcome": outcome, "command": command})
        if code != 0:
            details.append("--- {} (exit {}): {}\n{}{}".format(
                csc, code, " ".join(command), stdout, stderr))

    final = worst_exit(counts)
    # 001:4:5 Output
    if args.json:
        print(json.dumps({"files": [{k: r[k] for k in ("file", "code", "outcome", "command")}
                                    for r in rows], "exit": final}))
        return final
    for row in rows:
        print("{}  {}  {}  {}".format(row["code"], row["label"], row["file"], row["outcome"]))
    if details and args.details == "full":
        print("")
        for block in details:
            print(block.rstrip("\n"))
        print("log: " + str(LOG_FILE))
        print("")
    print("VERDICT {} files={} exit0={} exit1={} exit2={} exit3={} -> exit {}".format(
        "PASS" if final == 0 else "FAIL", len(files),
        counts[0], counts[1], counts[2], counts[3], final))
    return final


if __name__ == "__main__":
    sys.exit(main())
