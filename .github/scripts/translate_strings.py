#!/usr/bin/env python3
"""
Auto-translate new iOS .strings entries on PRs.
Detects new/changed English keys and translates to all supported languages.
"""

import os
import re
import sys
import json
import subprocess

import anthropic

LANGUAGES = {
    "de": "German",
    "es": "Spanish",
    "fr": "French",
    "ko": "Korean",
    "pt-BR": "Brazilian Portuguese",
    "ru": "Russian",
    "tr": "Turkish",
    "zh": "Chinese (Simplified)",
}

STRINGS_FILE = "UnstoppableWallet/UnstoppableWallet/{lang}.lproj/Localizable.strings"
EN_FILE = STRINGS_FILE.format(lang="en")

STRING_PATTERN = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')


def parse_strings(content: str) -> dict[str, str]:
    return {m.group(1): m.group(2) for m in STRING_PATTERN.finditer(content)}


def get_new_strings() -> dict[str, str]:
    base_ref = os.environ.get("GITHUB_BASE_REF", "master")

    result = subprocess.run(
        ["git", "show", f"origin/{base_ref}:{EN_FILE}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    base_strings = parse_strings(result.stdout) if result.returncode == 0 else {}

    try:
        with open(EN_FILE, encoding="utf-8") as f:
            current_strings = parse_strings(f.read())
    except FileNotFoundError:
        print(f"English strings file not found: {EN_FILE}")
        return {}

    return {
        key: value
        for key, value in current_strings.items()
        if key not in base_strings or base_strings[key] != value
    }


def translate_all(new_strings: dict[str, str]) -> dict[str, list[str]]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    strings_block = "\n".join(
        f'"{k}" = "{v}";' for k, v in new_strings.items()
    )
    lang_list = "\n".join(f"- {code}: {name}" for code, name in LANGUAGES.items())

    prompt = f"""You are a professional iOS app localizer. Translate the following iOS .strings entries from English into each language listed below.

Target languages:
{lang_list}

English strings:
{strings_block}

Rules:
- Keep key names exactly as-is (never translate keys)
- Preserve all placeholders: %@, %d, %1$@, %2$s, \\n, etc.
- Return ONLY valid JSON — no markdown, no explanation
- JSON format:
{{
  "de": ["\\\"key\\\" = \\\"translation\\\";", ...],
  "es": [...],
  ...
}}"""

    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=8192,
        messages=[{"role": "user", "content": prompt}],
    )

    text = re.sub(r"```json\s*|\s*```", "", message.content[0].text).strip()

    return json.loads(text)


def get_en_block_for_new_keys(new_keys: set[str]) -> list[str]:
    """Extract lines from EN file for new keys, including their preceding comments/blanks."""
    try:
        with open(EN_FILE, encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        return []

    # First, find which line indices contain new keys
    key_line_indices = set()
    for i, line in enumerate(lines):
        m = STRING_PATTERN.match(line.strip())
        if m and m.group(1) in new_keys:
            key_line_indices.add(i)

    # For each key line, walk backwards to grab preceding comments/blanks
    # that belong to its block (stop at another key line)
    included_indices = set()
    for ki in key_line_indices:
        included_indices.add(ki)
        j = ki - 1
        while j >= 0:
            prev = lines[j].strip()
            if STRING_PATTERN.match(prev):
                break  # hit another key, stop
            if prev.startswith("//") or prev == "":
                included_indices.add(j)
                j -= 1
            else:
                break

    # Return lines in original order
    return [lines[i] for i in sorted(included_indices)]

def update_strings_file(lang_code: str, translated_lines: list[str], new_keys: set[str]) -> None:
    path = STRINGS_FILE.format(lang=lang_code)

    try:
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        lines = []

    # Build a map of key -> new translation line
    updates = {}
    for line in translated_lines:
        m = STRING_PATTERN.match(line.strip())
        if m:
            updates[m.group(1)] = line.strip()

    # Rewrite file line by line, replacing only matched key lines
    new_content = []
    updated_keys = set()

    for line in lines:
        m = STRING_PATTERN.match(line.strip())
        if m and m.group(1) in updates:
            key = m.group(1)
            new_content.append(updates[key] + "\n")
            updated_keys.add(key)
        else:
            new_content.append(line)

    # Append truly new keys, preserving EN file structure (comments, blank lines)
    truly_new = {k for k in updates if k not in updated_keys}
    if truly_new:
        if new_content and not new_content[-1].endswith("\n"):
            new_content.append("\n")

        en_block = get_en_block_for_new_keys(truly_new)
        for line in en_block:
            m = STRING_PATTERN.match(line.strip())
            if m and m.group(1) in updates:
                new_content.append(updates[m.group(1)] + "\n")  # translated line
            else:
                new_content.append(line)  # comment or blank line as-is

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    print(f"  ✓ {lang_code}")

def main() -> None:
    print("Checking for new English strings...")
    new_strings = get_new_strings()

    if not new_strings:
        print("No new strings found. Nothing to do.")
        sys.exit(0)

    print(f"Found {len(new_strings)} new/changed string(s). Translating...")
    translations = translate_all(new_strings)
    new_keys = set(new_strings.keys())  # <-- add this

    print("Writing translations:")
    for lang_code, lines in translations.items():
        if lang_code in LANGUAGES:
            update_strings_file(lang_code, lines, new_keys)  # <-- pass new_keys

    print("Done.")

if __name__ == "__main__":
    main()
