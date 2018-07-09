#!/bin/sh
set -ex

SCRIPT_DIR=`dirname "$0"`

(cd "$SCRIPT_DIR" && sh build_secp256k1.sh)
(cd "$SCRIPT_DIR" && sh build_crypto.sh)

exit 0
