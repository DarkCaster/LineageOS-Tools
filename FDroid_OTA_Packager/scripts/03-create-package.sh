#!/bin/bash
#

set -e

workdir="$1"
[[ -z $workdir ]] && workdir="$PWD"

echo "creating package from files at $workdir/workspace"
pushd 1>/dev/null "$workdir/workspace"
7z a -tzip "$workdir/fdroid.ota.zip" *
popd 1>/dev/null
