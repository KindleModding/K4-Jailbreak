#!/bin/bash -e
#
# $Id: build-updates.sh 16160 2019-07-12 02:33:13Z NiLuJe $
#

HACKNAME="jailbreak"
HACKDIR="K4_JailBreak"
PKGNAME="${HACKNAME}"
PKGVER="1.8.N"

# Setup KindleTool packaging metadata flags to avoid cluttering the invocations
PKGREV="$(svnversion -c .. | awk '{print $NF}' FS=':' | tr -d 'P')"
KT_PM_FLAGS=( "-xPackageName=${HACKDIR}" "-xPackageVersion=${PKGVER}-r${PKGREV}" "-xPackageAuthor=yifanlu, NiLuJe" "-xPackageMaintainer=NiLuJe" "-X" )

# We need kindletool (https://github.com/NiLuJe/KindleTool) in $PATH
if (( $(kindletool version | wc -l) == 1 )) ; then
	HAS_KINDLETOOL="true"
fi

if [[ "${HAS_KINDLETOOL}" != "true" ]] ; then
	echo "You need KindleTool (https://github.com/NiLuJe/KindleTool) to build this package."
	exit 1
fi

# We also need GNU tar
if [[ "$(uname -s)" == "Darwin" ]] ; then
	TAR_BIN="gtar"
else
	TAR_BIN="tar"
fi
if ! ${TAR_BIN} --version | grep -q "GNU tar" ; then
	echo "You need GNU tar to build this package."
	exit 1
fi

# Pickup our common stuff...
if [[ ! -d "../../../Hacks/Common" ]] ; then
        echo "The tree isn't checked out in full, missing the (legacy) Common directory..."
        exit 1
fi
# LibOTAUtils
ln -f ../../../Hacks/Common/lib/libotautils ./libotautils

### FW 4.0.0-4.1.1
# By yifanlu & ixtab (http://yifan.lu/p/kindle-touch-jailbreak/)
###

## Install
# Prepare the directory layout for our data.tar.gz...
mkdir -p ../src/system ../src/wan

# Copy our payload
ln -f ../src/install.sh ../src/system/mntus.params
ln -f ../src/install.sh ../src/wan/info

# Craft our data.tar.gz...
${TAR_BIN} --hard-dereference --owner root --group root --transform 's,^src/,,S' --transform 's,^,/var/local/,S' -cvzf data.tar.gz ../src/system ../src/wan ../src/payload

# Remove package specific temp stuff
rm -rf ../src/system ../src/wan

# Move our data package
mv -f *.tar.gz ../

## Uninstall
# Copy the script to our working directory, to avoid storing crappy paths in the update package
ln -f ../src/uninstall.sh ./

# Build the uninstall package
kindletool create ota2 "${KT_PM_FLAGS[@]}" -d kindle4 libotautils uninstall.sh Update_${PKGNAME}_${PKGVER}_uninstall.bin

# Remove package specific temp stuff
rm -f ./uninstall.sh

# Move our update
mv -f *.bin ../
