#!/bin/bash
#

set -e

workdir="$1"
[[ -z $workdir ]] && echo "usage: cleanup.sh <dest dir>" && exit 1 
[[ ! -d $workdir ]] && exit 0

echo "cleaning-up workspace at $workdir"
rm -rf "$workdir"/*
