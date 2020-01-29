#!/bin/bash

set -e

show_usage() {
  echo "usage: apply_patches.sh <lineage os scrdir> <direction: push|pop> <device>"
  exit 1
}

lineage_srcdir="$1"
[[ -z $lineage_srcdir ]] && show_usage
[[ ! -d $lineage_srcdir ]] && echo "lineage source directory not provided, or not exist" && show_usage

direction="$2"
[[ -z $direction ]] && show_usage

device="$3"
[[ -z $device ]] && show_usage

### settings

with_fdroid="true"

### end of settings

self_dir="$(cd "$(dirname "$0")" && pwd)"
scripts_dir="$self_dir/scripts"

#common patches
patches_dir="patches/common"
source "$self_dir/quilt_set.sh.in"
pushd 1>/dev/null "$lineage_srcdir"
[[ -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt $direction -a
popd 1>/dev/null
source "$self_dir/quilt_unset.sh.in"

#device patches
patches_dir="patches/$device"
source "$self_dir/quilt_set.sh.in"
pushd 1>/dev/null "$lineage_srcdir"
[[ -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt $direction -a
popd 1>/dev/null
source "$self_dir/quilt_unset.sh.in"

#fdroid patches
if [[ $with_fdroid = true ]]; then
  patches_dir="patches/fdroid"
  source "$self_dir/quilt_set.sh.in"
  pushd 1>/dev/null "$lineage_srcdir"
  [[ -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt $direction -a
  popd 1>/dev/null
  source "$self_dir/quilt_unset.sh.in"
fi
