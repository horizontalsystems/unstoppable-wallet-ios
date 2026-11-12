#!/bin/bash
# Prepares a booted iOS simulator for a test run by setting its locale to
# English (US) and its preferred languages to English (US), then German. The
# flows assert English text and formatted amounts such as "€0", while a new
# simulator takes the host's locale and region and shows e.g. "€0,00". The
# second language is there because iOS shows an app's Language row in
# Settings only while the device has more than one preferred language, and
# the flow that changes the app's language goes through it.
#
# The values reach only processes launched afterwards, so this hook must
# return before the app's first launch. It never reboots the simulator and
# never installs, builds, records, runs Maestro or reads a secret.
# "--requirements" prints the simulator the station must create.
#
# Usage: device-prepare.sh --requirements | <udid>
set -euo pipefail

DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-27-2"
LOCALE="en_US"
LANGUAGES=(en-US de)
EXPECTED_LANGUAGES="($(IFS=,; echo "${LANGUAGES[*]}"))"

if [ "${1:-}" = "--requirements" ]; then
  printf '{"device_type":"%s","runtime":"%s"}\n' "$DEVICE_TYPE" "$RUNTIME"
  exit 0
fi

UDID="${1:?usage: device-prepare.sh --requirements | <udid>}"
trap 'echo "device-prepare.sh failed on $UDID at line $LINENO" >&2' ERR

state="$(xcrun simctl list -j devices | jq -r --arg u "$UDID" '.devices[][] | select(.udid==$u) | .state')"
if [ "$state" != "Booted" ]; then
  echo "$UDID is not booted (state: ${state:-unknown})" >&2
  exit 1
fi
xcrun simctl bootstatus "$UDID" >/dev/null

read_locale() {
  xcrun simctl spawn "$UDID" defaults read -g AppleLocale 2>/dev/null || true
}

read_languages() {
  local raw
  raw="$(xcrun simctl spawn "$UDID" defaults read -g AppleLanguages 2>/dev/null || true)"
  printf '%s' "$raw" | tr -d ' \n"'
}

if [ "$(read_locale)" != "$LOCALE" ]; then
  xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string "$LOCALE"
fi
if [ "$(read_languages)" != "$EXPECTED_LANGUAGES" ]; then
  xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array "${LANGUAGES[@]}"
fi

got_locale="$(read_locale)"
got_languages="$(read_languages)"
if [ "$got_locale" != "$LOCALE" ] || [ "$got_languages" != "$EXPECTED_LANGUAGES" ]; then
  echo "$UDID locale is ${got_locale:-unset}, languages ${got_languages:-unset}; expected $LOCALE, $EXPECTED_LANGUAGES" >&2
  exit 1
fi

echo "Prepared $UDID"
