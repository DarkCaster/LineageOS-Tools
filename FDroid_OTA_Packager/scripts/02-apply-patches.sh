#!/bin/bash
#

set -e

workdir="$1"
[[ -z $workdir ]] && workdir="$PWD"

echo "applying patches at $workdir"
pushd 1>/dev/null "$workdir"
quilt push -a
popd 1>/dev/null
