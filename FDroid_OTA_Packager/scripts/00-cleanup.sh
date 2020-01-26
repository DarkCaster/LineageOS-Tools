#!/bin/bash
#

set -e

workdir="$1"
[[ -z $workdir ]] && echo "usage: cleanup.sh <base dir>" && exit 1

if [[ -d $workdir/workspace ]]; then
  echo "cleaning-up workspace at $workdir"
  rm -rf "$workdir/workspace"/*
fi

if [[ -d $workdir/.pc ]]; then
  echo "cleaning-up quilt '.pc' directory at $workdir"
  rm -rf "$workdir/.pc"
fi
