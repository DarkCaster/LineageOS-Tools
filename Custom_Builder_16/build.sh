#!/bin/bash
#

set -e

show_usage() {
  echo "usage: build.sh <lineage os srcdir> <device> <target (see below)> [additional parameters for target]"
  exit 1
}

#lineage source directory
lineage_srcdir="$1"
[[ -z $lineage_srcdir ]] && show_usage

#device
target_device="$2"
[[ -z $target_device ]] && show_usage

#what to build: ota - signed OTA update archive; vendor - populate vendor archive; keys - (re)create sign keys
target="$3"
[[ -z $target ]] && show_usage

shift 3

### other settings

cleanup_srcdir="false"
skip_patches="false"

#embed su addon
export WITH_SU="true"

#embed fdroid
with_fdroid="true"

### end of settings

[[ $target != "ota" ]] && skip_patches="true"

[[ ! -d $lineage_srcdir ]] && echo "lineage source directory is missing :$lineage_srcdir" && exit 1

self_dir="$(cd "$(dirname "$0")" && pwd)"
scripts_dir="$self_dir/scripts"

#TODO: cleanup src dir
if [[ $cleanup_srcdir = true ]]; then
  #TODO: clean src dir
  #TODO: repo sync
  echo "TODO"
  exit 1
fi

if [[ $skip_patches != true ]]; then

  #TODO: apply device specific patches
  patches_dir="patches-common"
  source "$self_dir/quilt_set.sh.in"
  pushd 1>/dev/null "$lineage_srcdir"
  [[ -d $QUILT_PATCHES ]] && echo "applying patches from directory $patches_dir" && quilt push -a
  popd 1>/dev/null
  source "$self_dir/quilt_unset.sh.in"

  #TODO: fdroid setup
  if [[ $with_fdroid = true ]]; then
    patches_dir="fdroid"
    source "$self_dir/quilt_set.sh.in"
    pushd 1>/dev/null "$lineage_srcdir"
    [[ -d $QUILT_PATCHES ]] && echo "applying patches from directory $patches_dir" && quilt push -a
    popd 1>/dev/null
    source "$self_dir/quilt_unset.sh.in"
  fi
else
  echo "skipping applying patches"
fi

pushd 1>/dev/null "$lineage_srcdir"

echo "preparing build env"
source build/envsetup.sh

echo "running $target target"
if [[ $target = "vendor" ]]; then
  vendor="$1"
  [[ -z $vendor ]] && echo "please provide device vendor name as the last parameter" && show_usage
  breakfast "$target_device" || echo "fail was expected at this stage..."
  pushd 1>/dev/null "device/$vendor/$target_device"
  echo "extracting vendor files"
  ./extract-files.sh
  popd 1>/dev/null
  echo "creating new vendor-files archive"
  "$self_dir/scripts/create-vendor-files-archive.sh" "$lineage_srcdir" "$vendor" "$self_dir/private/$target_device.enc"
else
  echo "unknown or unimplemented target: $target"
fi

pushd 1>/dev/null