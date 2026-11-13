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
interpolation matches any text, so a typo inside it passes. A selector holding
a flow variable or a regex wildcard is matched both ways: as a sample against
every declaration, and as a pattern against the literal names. So it selects a
literal name its pattern covers.

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
from typing import NamedTuple

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
PLATFORM = re.compile(r"^\s*platform:\s*(.*)$")
COMMENT = re.compile(r"\s+#.*$")
APP_ID = re.compile(r"^appId:\s*(.*)$")
# ${expression} in a flow, or a regex wildcard: Maestro matches id as a regex
FLOW_VARIABLE = re.compile(r"\$\{.*?\}|\.[*+]")
FLOW_EXPRESSION = re.compile(r"\$\{.*?\}")
SAMPLE = "x1"


class SetupError(Exception):
    """The check cannot run; main reports it and returns 2."""


class Declarations(NamedTuple):
    literals: list[str]
    patterns: list[re.Pattern]


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_declarations(source: str) -> Declarations:
    literals = LET.findall(source)
    patterns = [re.compile(re.escape(value)) for value in literals]
    for template in FUNCTION.findall(source):
        parts = SWIFT_INTERPOLATION.split(template)
        patterns.append(re.compile(".+".join(re.escape(part) for part in parts)))
    return Declarations(literals, patterns)


def tree_declarations() -> Declarations:
    try:
        with open(TEST_TAGS, encoding="utf-8") as file:
            source = file.read()
    except OSError as error:
        raise SetupError(f"cannot read {TEST_TAGS}: {error}")
    declarations = parse_declarations(source)
    if not declarations.patterns:
        raise SetupError(f"{TEST_TAGS} declares no test tag")
    return declarations


def base_declarations(ref: str) -> Declarations:
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
        return Declarations([], [])
    return parse_declarations(show.stdout)


def platform_of(line: str) -> str | None:
    """The platform a `platform:` line names, or None when it names none."""
    match = PLATFORM.match(line)
    if not match:
        return None
    return unquote(COMMENT.sub("", match.group(1)).strip()) or None


def run_flow_platforms(lines: list[str]) -> dict[int, str | None]:
    """The platform of each `- runFlow:` block, keyed by its line index.

    A block's platform is its first non-empty `platform:` line, so it is known
    before any selector inside the block is judged, whatever the order of keys.
    """
    platforms: dict[int, str | None] = {}
    # (indent of the "- runFlow:" line, index of that line)
    stack: list[tuple[int, int]] = []
    for index, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        while stack and indent <= stack[-1][0]:
            stack.pop()
        if match := RUN_FLOW.match(line):
            platforms[index] = None
            stack.append((len(match.group(1)), index))
            continue
        if stack and platforms[stack[-1][1]] is None:
            platforms[stack[-1][1]] = platform_of(line)
    return platforms


def selectors(path: str):
    with open(path, encoding="utf-8") as file:
        lines = file.readlines()
    platforms = run_flow_platforms(lines)
    # (indent of the "- runFlow:" line, platform its when names, or None); a
    # branch is skipped as a whole, so its commands may precede its when
    run_flows: list[tuple[int, str | None]] = []
    for index, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        while run_flows and indent <= run_flows[-1][0]:
            run_flows.pop()
        if match := RUN_FLOW.match(line):
            run_flows.append((len(match.group(1)), platforms[index]))
            continue
        if run_flows and PLATFORM.match(line):
            continue
        if any(platform not in (None, "iOS") for _, platform in run_flows):
            continue
        match = SELECTOR.search(line)
        if not match:
            continue
        value = unquote(COMMENT.sub("", match.group(1)).strip().rstrip(",}").strip())
        yield index + 1, value


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
                value = unquote(COMMENT.sub("", match.group(1)).strip())
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


def selector_pattern(value: str) -> re.Pattern | None:
    """The selector read as a regular expression, or None for a plain id.

    Maestro reads `id` as a regular expression, so the text is kept as written
    and each `${...}` stands for any text.
    """
    if not FLOW_VARIABLE.search(value):
        return None
    try:
        return re.compile(".*".join(FLOW_EXPRESSION.split(value)))
    except re.error:
        return None


def selects(declarations: Declarations, sample: str, pattern: re.Pattern | None) -> bool:
    if matches(declarations.patterns, sample):
        return True
    return pattern is not None and any(
        pattern.fullmatch(literal) for literal in declarations.literals
    )


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
        base = base_declarations(args.base) if args.base else Declarations([], [])
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
            pattern = selector_pattern(value)
            if selects(tree, sample, pattern):
                continue
            if args.base and selects(base, sample, pattern):
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
        f"{checked} id selectors in {flows_read} flows checked against {len(tree.patterns)} "
        f"test tags: {errors} removed by the pull request, {notices} undeclared"
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
