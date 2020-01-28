#!/bin/bash
#

### settings

#lineage source directory
lineage_scrdir="$1"
[[ -z $lineage_scrdir ]] && lineage_scrdir="$HOME/android/lineage"

#device
target_device="$2"
[[ -z $target_device ]] && target_device="river"

#embed su addon
export WITH_SU="true"

#embed fdroid
with_fdroid="true"

### end of settings

set -e

[[ ! -d $lineage_scrdir ]] && echo "lineage source directory is missing :$lineage_scrdir" && exit 1

self_dir="$( cd "$( dirname "$0" )" && pwd )"
scripts_dir="$self_dir/scripts"

#TODO: apply device specific patches
source "$self_dir/quilt_set.sh.in"
pushd 1>/dev/null "$lineage_scrdir"
[[ -d $QUILT_PATCHES ]] && echo "applying patches from directory $patches_dir" && quilt push -a
popd 1>/dev/null
source "$self_dir/quilt_unset.sh.in"

#TODO: fdroid setup
if [[ $with_fdroid = true ]]; then
  patches_dir="fdroid"
  source "$self_dir/quilt_set.sh.in"
  pushd 1>/dev/null "$lineage_scrdir"
  [[ -d $QUILT_PATCHES ]] && echo "applying patches from directory $patches_dir" && quilt push -a
  popd 1>/dev/null
  source "$self_dir/quilt_unset.sh.in"
fi
