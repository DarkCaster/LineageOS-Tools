#!/bin/bash
#

set -e

zip="$1"
[[ -z $zip ]] && echo "usage: download.sh <fdroid original ota zip url> [workspace dir]"

workdir="$2"
[[ -z $workdir ]] && workdir="$PWD"
workdir="$workdir/workspace"

echo "preparing workspace at $workdir"
mkdir -p "$workdir"

echo "downloading original FDroid OTA from: $zip"
pushd 1>/dev/null "$workdir"
wget -nv --show-progress -O fdroid.zip "$zip"
7z 1>/dev/null x fdroid.zip
rm fdroid.zip
find "META-INF" -type f -exec dos2unix "{}" \;
find . -maxdepth 1 -type f -name "*.sh" -exec dos2unix "{}" \;
popd 1>/dev/null
