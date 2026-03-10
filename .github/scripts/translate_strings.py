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

def get_strings_at_ref(ref: str) -> dict[str, str]:
    """Get parsed strings from EN_FILE at a given git ref. Returns empty dict if not found."""
    result = subprocess.run(
        ["git", "show", f"{ref}:{EN_FILE}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return parse_strings(result.stdout) if result.returncode == 0 else {}

def get_previous_ref() -> str:
    """
    Return the ref to diff against.
    - On the first commit of a PR (no HEAD~1), fall back to origin/<base>.
    - On subsequent pushes, use HEAD~1 so only the latest commit's changes are detected.
    """
    # Check whether HEAD~1 exists (i.e. there is a parent commit)
    result = subprocess.run(
        ["git", "rev-parse", "--verify", "HEAD~1"],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return "HEAD~1"
    # Fallback: very first commit — diff against the PR base branch
    base_ref = os.environ.get("GITHUB_BASE_REF", "master")
    return f"origin/{base_ref}"

def get_new_strings() -> dict[str, str]:
    prev_ref = get_previous_ref()
    base_strings = get_strings_at_ref(prev_ref)

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

def get_deleted_strings() -> set[str]:
    prev_ref = get_previous_ref()
    base_strings = get_strings_at_ref(prev_ref)

    try:
        with open(EN_FILE, encoding="utf-8") as f:
            current_strings = parse_strings(f.read())
    except FileNotFoundError:
        return set()

    return set(base_strings.keys()) - set(current_strings.keys())


def translate_all(new_strings: dict[str, str]) -> dict[str, list[str]]:
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    strings_block = "\n".join(
        f'"{k}" = "{v}";' for k, v in new_strings.items()
    )
    lang_list = "\n".join(f"- {code}: {name}" for code, name in LANGUAGES.items())

    prompt = f"""You are a professional technical translator and iOS app localizer with experience working on cryptocurrency wallets and exchanges. Translate the following iOS .strings entries from English into the target languages, preserving technical meaning, formatting, and placeholders. Use industry-standard blockchain and crypto terminology (wallet, token, blockchain, swap, gas fee, private key, DeFi, NFT, dApp).

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
}}

Return ONLY a valid JSON object.
- No markdown, no code fences, no explanation.
- Escape ALL double quotes inside string values as \"
- Do NOT use curly/smart quotes (" ") anywhere.
"""

    message = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=8192,
        messages=[{"role": "user", "content": prompt}],
    )

    text = re.sub(r"```json\s*|\s*```", "", message.content[0].text).strip()

    return json.loads(text)

def rebuild_translation_file(lang_code: str, translated_lines: list[str], deleted_keys: set[str]) -> None:
    path = STRINGS_FILE.format(lang=lang_code)

    # Get all existing translations for this language
    existing = {}
    try:
        with open(path, encoding="utf-8") as f:
            for line in f.readlines():
                m = STRING_PATTERN.match(line.strip())
                if m:
                    existing[m.group(1)] = line.strip()
    except FileNotFoundError:
        pass

    # Apply new translations on top
    for line in translated_lines:
        m = STRING_PATTERN.match(line.strip())
        if m:
            existing[m.group(1)] = line.strip()

    # Remove deleted keys
    for key in deleted_keys:
        existing.pop(key, None)

    # Read EN file as-is and use it as the exact template
    try:
        with open(EN_FILE, encoding="utf-8") as f:
            en_lines = f.readlines()
    except FileNotFoundError:
        return

    new_content = []
    for line in en_lines:
        m = STRING_PATTERN.match(line.strip())
        if m:
            key = m.group(1)
            if key in existing:
                new_content.append(existing[key] + "\n")
            # deleted key - skip line entirely
        else:
            # comment, blank line - copy as-is
            new_content.append(line)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    print(f"  ✓ {lang_code}")

def main() -> None:
    print("Checking for new English strings...")
    new_strings = get_new_strings()
    deleted_keys = get_deleted_strings()

    if not new_strings and not deleted_keys:
        print("No new or deleted strings found. Nothing to do.")
        sys.exit(0)

    if deleted_keys:
        print(f"Found {len(deleted_keys)} deleted string(s): {', '.join(deleted_keys)}")

    translations = {}
    if new_strings:
        print(f"Found {len(new_strings)} new/changed string(s). Translating...")
        translations = translate_all(new_strings)

    print("Writing translations:")
    for lang_code in LANGUAGES:
        rebuild_translation_file(lang_code, translations.get(lang_code, []), deleted_keys)

    print("Done.")

if __name__ == "__main__":
    main()
