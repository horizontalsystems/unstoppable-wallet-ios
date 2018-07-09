#!/bin/sh
set -ex

SCRIPT_DIR="`pwd`/`dirname $0`"
OPENSSL_VERSION=1.0.2n

TDIR=`mktemp -d`
trap "{ cd - ; rm -rf $TDIR; exit 255; }" SIGINT

cd $TDIR

curl -O https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
tar zxf openssl-$OPENSSL_VERSION.tar.gz

cd openssl-$OPENSSL_VERSION

sh "$SCRIPT_DIR/build_crypto_impl.sh" iphoneos arm64
sh "$SCRIPT_DIR/build_crypto_impl.sh" iphoneos armv7s
sh "$SCRIPT_DIR/build_crypto_impl.sh" iphoneos armv7
sh "$SCRIPT_DIR/build_crypto_impl.sh" iphonesimulator x86_64
sh "$SCRIPT_DIR/build_crypto_impl.sh" iphonesimulator i386


mkdir -p "$SCRIPT_DIR/../Libraries/openssl/lib"
xcrun lipo -create .build/iphoneos/arm64/libcrypto.a \
                   .build/iphoneos/armv7s/libcrypto.a \
                   .build/iphoneos/armv7/libcrypto.a \
                   .build/iphonesimulator/x86_64/libcrypto.a \
                   .build/iphonesimulator/i386/libcrypto.a \
                   -o "$SCRIPT_DIR/../Libraries/openssl/lib/libcrypto.a"
cp -rf $TDIR/openssl-$OPENSSL_VERSION/include "$SCRIPT_DIR/../Libraries/openssl/"

cd -
rm -rf $TDIR

exit 0
