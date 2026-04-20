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
import argparse
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
TRANSLATION_SNAPSHOT_FILE = "UnstoppableWallet/UnstoppableWallet/translation_snapshot.json"

STRING_PATTERN = re.compile(r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;')

def parse_strings(content: str) -> dict[str, str]:
    return {m.group(1): m.group(2) for m in STRING_PATTERN.finditer(content)}

def load_snapshot() -> dict[str, str]:
    try:
        with open(TRANSLATION_SNAPSHOT_FILE, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}

def save_snapshot(en_strings: dict[str, str]) -> None:
    os.makedirs(os.path.dirname(TRANSLATION_SNAPSHOT_FILE), exist_ok=True)
    with open(TRANSLATION_SNAPSHOT_FILE, "w", encoding="utf-8") as f:
        json.dump(en_strings, f, indent=2, ensure_ascii=False)

def get_new_strings() -> dict[str, str]:
    """Return EN keys that are new or whose English value changed since last translation."""
    try:
        with open(EN_FILE, encoding="utf-8") as f:
            en_strings = parse_strings(f.read())
    except FileNotFoundError:
        print(f"English strings file not found: {EN_FILE}")
        return {}

    snapshot = load_snapshot()

    return {
        key: value
        for key, value in en_strings.items()
        if key not in snapshot or snapshot[key] != value
    }


def get_deleted_strings() -> set[str]:
    """Return keys that were in the snapshot but are no longer in the EN file."""
    try:
        with open(EN_FILE, encoding="utf-8") as f:
            en_keys = set(parse_strings(f.read()).keys())
    except FileNotFoundError:
        return set()

    snapshot = load_snapshot()
    return set(snapshot.keys()) - en_keys


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

    text_parts = []
    with client.messages.stream(
        model="claude-opus-4-6",
        max_tokens=32000,
        messages=[{"role": "user", "content": prompt}],
    ) as stream:
        for chunk in stream.text_stream:
            text_parts.append(chunk)

    final = stream.get_final_message()
    print(f"stop_reason={final.stop_reason}, output_tokens={final.usage.output_tokens}")

    raw = "".join(text_parts)
    text = re.sub(r"```json\s*|\s*```", "", raw).strip()

    if final.stop_reason == "max_tokens":
        with open("/tmp/translate_raw.txt", "w", encoding="utf-8") as f:
            f.write(raw)
        raise RuntimeError(f"Response truncated at {final.usage.output_tokens} tokens — saved to /tmp/translate_raw.txt")

    return json.loads(text)

def rebuild_translation_file(lang_code: str, translated_lines: list[str], deleted_keys: set[str]) -> None:
    path = STRINGS_FILE.format(lang=lang_code)

    # Load all existing translations for this language
    existing = {}
    try:
        with open(path, encoding="utf-8") as f:
            for line in f.readlines():
                m = STRING_PATTERN.match(line.strip())
                if m:
                    existing[m.group(1)] = line.strip()
    except FileNotFoundError:
        pass

    # Merge in new/updated translations
    for line in translated_lines:
        m = STRING_PATTERN.match(line.strip())
        if m:
            existing[m.group(1)] = line.strip()

    # Remove deleted keys
    for key in deleted_keys:
        existing.pop(key, None)

    # Use EN file as structure template (preserves comments and ordering)
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
            # deleted key — skip line entirely
        else:
            # comment or blank line — copy as-is
            new_content.append(line)

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    print(f"  ✓ {lang_code}")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--init", action="store_true",
                        help="Bootstrap snapshot from current EN file without translating")
    args = parser.parse_args()

    if args.init:
        try:
            with open(EN_FILE, encoding="utf-8") as f:
                en_strings = parse_strings(f.read())
            save_snapshot(en_strings)
            print(f"Snapshot initialized with {len(en_strings)} keys. No translation performed.")
        except FileNotFoundError:
            print(f"EN file not found: {EN_FILE}")
            sys.exit(1)
        sys.exit(0)

    print("Checking for new/changed English strings...")
    new_strings = get_new_strings()
    deleted_keys = get_deleted_strings()

    if not new_strings and not deleted_keys:
        print("No new, changed, or deleted strings found. Nothing to do.")
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

    # Update snapshot to reflect the EN values that are now translated
    try:
        with open(EN_FILE, encoding="utf-8") as f:
            en_strings = parse_strings(f.read())
        save_snapshot(en_strings)
        print("  ✓ translation_snapshot.json")
    except FileNotFoundError:
        print("Warning: could not save snapshot — EN file not found.")

    print("Done.")

if __name__ == "__main__":
    main()
