#!/usr/bin/env python3
"""Check the ids that appkb's Maestro flows select against TestTags.swift.

Why: Maestro skips a conditional step (`when: visible`, `optional: true`) whose
id exists nowhere, and the flow still passes, so a name that a pull request
removes or renames breaks a flow unseen. In a plain step the same missing id
fails the run, which is loud and needs no check.

What it reads: every `*.yaml` under the given directories, line by line, with
no YAML library. A flow whose header `appId` is another app is skipped, and so
are the `when: platform` branches of any platform but iOS. A name built by a
function in TestTags.swift is checked only up to its variable part: the
interpolation matches any text, so a typo inside it passes.

Outcomes:
  ::error  (exit 1)  with --base: an id the base declared and the tree no
                     longer declares.
  ::notice (exit 0)  every other undeclared id: a name the code has not
                     reached yet, or an identifier that is not the app's own.

Usage, from the repository root:
  python3 .github/scripts/check_test_tags.py [--base <git ref>] [<flows dir> ...]

Exit 2 is a setup error: an unreadable or empty TestTags.swift, an unresolved
base ref, or a flows directory without flows.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

TEST_TAGS = "packages/WalletCore/Sources/WalletCore/UserInterface/TestTags.swift"
DEFAULT_FLOWS = ["maestro/appkb/flows"]

LET = re.compile(r'^\s*static\s+let\s+\w+\s*=\s*"([^"]*)"', re.MULTILINE)
FUNCTION = re.compile(
    r'^\s*static\s+func\s+\w+\s*\([^)]*\)\s*->\s*String\s*\{\s*(?:return\s+)?"([^"]*)"',
    re.MULTILINE,
)
# A Swift interpolation ends at its matching parenthesis, one nested level deep.
SWIFT_INTERPOLATION = re.compile(r"\\\((?:[^()]|\([^()]*\))*\)")

SELECTOR = re.compile(r"(?<![\w-])id:\s*(.+)$")
RUN_FLOW = re.compile(r"^(\s*)- runFlow:")
PLATFORM = re.compile(r"^\s*platform:\s*(\w+)")
APP_ID = re.compile(r"^appId:\s*(.*)$")
# ${expression} in a flow, or a regex wildcard: Maestro matches id as a regex
FLOW_VARIABLE = re.compile(r"\$\{.*?\}|\.[*+]")
SAMPLE = "x1"


class SetupError(Exception):
    """The check cannot run; main reports it and returns 2."""


def parse_declarations(source: str) -> list[re.Pattern]:
    patterns = [re.compile(re.escape(value)) for value in LET.findall(source)]
    for template in FUNCTION.findall(source):
        parts = SWIFT_INTERPOLATION.split(template)
        patterns.append(re.compile(".+".join(re.escape(part) for part in parts)))
    return patterns


def tree_declarations() -> list[re.Pattern]:
    try:
        with open(TEST_TAGS, encoding="utf-8") as file:
            source = file.read()
    except OSError as error:
        raise SetupError(f"cannot read {TEST_TAGS}: {error}")
    patterns = parse_declarations(source)
    if not patterns:
        raise SetupError(f"{TEST_TAGS} declares no test tag")
    return patterns


def base_declarations(ref: str) -> list[re.Pattern]:
    try:
        verify = subprocess.run(
            ["git", "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        raise SetupError(f"base ref '{ref}' does not resolve: git is not available")
    if verify.returncode != 0:
        raise SetupError(f"base ref '{ref}' does not resolve to a commit")
    show = subprocess.run(
        ["git", "show", f"{ref}:{TEST_TAGS}"], capture_output=True, text=True
    )
    if show.returncode != 0:
        return []
    return parse_declarations(show.stdout)


def selectors(path: str):
    # (indent of the "- runFlow:" line, platform its when names, or None)
    run_flows: list[list] = []
    with open(path, encoding="utf-8") as file:
        for number, line in enumerate(file, start=1):
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            indent = len(line) - len(line.lstrip())
            while run_flows and indent <= run_flows[-1][0]:
                run_flows.pop()
            if match := RUN_FLOW.match(line):
                run_flows.append([len(match.group(1)), None])
                continue
            if run_flows and (match := PLATFORM.match(line)):
                run_flows[-1][1] = match.group(1)
                continue
            if any(platform not in (None, "iOS") for _, platform in run_flows):
                continue
            match = SELECTOR.search(line)
            if not match:
                continue
            value = re.sub(r"\s+#.*$", "", match.group(1)).strip().rstrip(",}").strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            yield number, value


def drives_wallet(path: str) -> bool:
    """True when the flow's header `appId` is the wallet's own.

    A file with no `appId` line, such as a Maestro config.yaml, names no
    wallet and is skipped; it holds no selectors either way.
    """
    with open(path, encoding="utf-8") as file:
        for line in file:
            if line.strip() == "---":
                break
            if match := APP_ID.match(line):
                value = re.sub(r"\s+#.*$", "", match.group(1)).strip()
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                return "APP_ID" in value or value.startswith("io.horizontalsystems.")
    return False


def collect_flows(dirs: list[str]) -> list[str]:
    flows: list[str] = []
    for directory in dirs:
        found = sorted(glob.glob(os.path.join(directory, "**/*.yaml"), recursive=True))
        if not found:
            raise SetupError(f"no *.yaml flow under {directory}")
        flows.extend(found)
    return flows


def matches(patterns: list[re.Pattern], sample: str) -> bool:
    return any(pattern.fullmatch(sample) for pattern in patterns)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Check the ids that the Maestro flows select against TestTags.swift."
    )
    parser.add_argument(
        "--base",
        metavar="REF",
        help="the pull request's base commit; a name it declared and the tree dropped fails",
    )
    parser.add_argument(
        "flows",
        nargs="*",
        default=DEFAULT_FLOWS,
        help="flow directories (default: %s)" % " ".join(DEFAULT_FLOWS),
    )
    args = parser.parse_args(argv)

    try:
        tree = tree_declarations()
        base = base_declarations(args.base) if args.base else []
        paths = collect_flows(args.flows)
    except SetupError as error:
        print(error, file=sys.stderr)
        return 2

    checked = flows_read = errors = notices = 0
    for path in paths:
        if not drives_wallet(path):
            continue
        flows_read += 1
        for number, value in selectors(path):
            sample = FLOW_VARIABLE.sub(SAMPLE, value)
            if sample.replace(SAMPLE, "") == "":
                continue
            checked += 1
            if matches(tree, sample):
                continue
            if args.base and matches(base, sample):
                print(
                    f"::error file={path},line={number}::Test tag '{value}' was "
                    "declared by the base and the pull request removed it from TestTags.swift"
                )
                errors += 1
            else:
                print(
                    f"::notice file={path},line={number}::Test tag '{value}' "
                    "is not declared in TestTags.swift"
                )
                notices += 1

    print(
        f"{checked} id selectors in {flows_read} flows checked against {len(tree)} "
        f"test tags: {errors} removed by the pull request, {notices} undeclared"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
