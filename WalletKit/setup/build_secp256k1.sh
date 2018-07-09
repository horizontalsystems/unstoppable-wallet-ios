#!/bin/sh
set -ex

SCRIPT_DIR=`dirname "$0"`

TDIR=`mktemp -d`
trap "{ cd - ; rm -rf $TDIR; exit 255; }" SIGINT

cd $TDIR

git clone https://github.com/bitcoin-core/secp256k1.git src

CURRENTPATH=`pwd`

TARGETDIR_IPHONEOS="$CURRENTPATH/.build/iphoneos"
mkdir -p "$TARGETDIR_IPHONEOS"

TARGETDIR_SIMULATOR="$CURRENTPATH/.build/iphonesimulator"
mkdir -p "$TARGETDIR_SIMULATOR"

(cd src && ./autogen.sh)
(cd src && ./configure --host=x86_64-apple-darwin CC=`xcrun -find clang` CFLAGS="-O3 -arch i386 -arch x86_64 -isysroot `xcrun -sdk iphonesimulator --show-sdk-path` -fembed-bitcode-marker -mios-simulator-version-min=8.0" CXX=`xcrun -find clang++` CXXFLAGS="-O3 -arch i386 -arch x86_64 -isysroot `xcrun -sdk iphonesimulator --show-sdk-path` -fembed-bitcode-marker -mios-simulator-version-min=8.0" --prefix="$TARGETDIR_IPHONEOS" && make install)
(cd src && ./configure --host=arm-apple-darwin CC=`xcrun -find clang` CFLAGS="-O3 -arch armv7 -arch armv7s -arch arm64 -isysroot `xcrun -sdk iphoneos --show-sdk-path` -fembed-bitcode -mios-version-min=8.0" CXX=`xcrun -find clang++` CXXFLAGS="-O3 -arch armv7 -arch armv7s -arch arm64 -isysroot `xcrun -sdk iphoneos --show-sdk-path` -fembed-bitcode -mios-version-min=8.0" --prefix="$TARGETDIR_SIMULATOR" && make install)

cd -

mkdir -p "$SCRIPT_DIR/../Libraries/secp256k1/lib"
xcrun lipo -create "$TARGETDIR_IPHONEOS/lib/libsecp256k1.a" \
                   "$TARGETDIR_SIMULATOR/lib/libsecp256k1.a" \
                   -o "$SCRIPT_DIR/../Libraries/secp256k1/lib/libsecp256k1.a"
cp -rf $TDIR/src/include "$SCRIPT_DIR/../Libraries/secp256k1"

rm -rf $TDIR

exit 0
