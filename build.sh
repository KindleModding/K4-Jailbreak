#!/bin/sh
HACKNAME="jailbreak"
HACKDIR="K4_JailBreak"
PKGNAME="${HACKNAME}"
PKGVER="1.8.N"
PKGREV="$(git rev-parse --short HEAD)"

rm -rf build_tmp
rm -rf build

echo "=============================="
echo "=     K4 JB Build Script     ="
echo "=============================="

mkdir build_tmp
mkdir build

echo "[*] Copying data directory"
cp -r src/data build_tmp/data

echo "[*] Copying additional files"
cp -r src/diagnostic_logs build/diagnostic_logs
cp -r src/ENABLE_DIAGS build/

echo "[*] Building main..."
cd build_tmp
    tar --hard-dereference --owner root --group root --transform 's/data//' --show-transformed -cvzf data.tar.gz data/*
cd ..
mv build_tmp/data.tar.gz build/data.tar.gz

echo "[*] Building uninstaller..."
cd src
    kindletool create ota2 -xPackageName="${HACKDIR}" -xPackageVersion="${PKGVER}-r${PKGREV}" -xPackageAuthor="yifanlu, NiLuJe" -xPackageMaintainer="Hackerdude, NiLuJe" -X -d kindle4 libotautils uninstall.sh ../build/Update_${PKGNAME}_${PKGVER}_uninstall.bin
cd ..
cd build
    zip -r build.zip .
cd ..

echo "[*] Done."