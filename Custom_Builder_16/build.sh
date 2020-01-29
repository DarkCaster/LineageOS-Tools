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

[[ ! -d $lineage_srcdir ]] && echo "lineage source directory is missing :$lineage_srcdir" && show_usage
[[ $target != "ota" ]] && skip_patches="true"
[[ $cleanup_srcdir != true ]] && skip_patches="true" && echo "disable patch-apply stage because source dir cleanup is also disabled"

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

mkdir -p "$self_dir/output/$target_device"

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
elif [[ $target = "keys" ]]; then
  echo "generating new signing-keys and creating encrypted archive for storing it within repo"
  "$self_dir/scripts/generate-keys.sh" "$lineage_srcdir" "$self_dir/private/keys.enc"
elif [[ $target = "ota" ]]; then
  echo "extracting signing-keys"
  "$self_dir/scripts/extract-archive.sh" "$self_dir/private/keys.enc" "$self_dir/temp"
  echo "extracting vendor files"
  "$self_dir/scripts/extract-archive.sh" "$self_dir/private/$target_device.enc" "$lineage_srcdir/vendor"
  echo "preparing build"
  breakfast "$target_device"
  echo "running build"
  mka target-files-package otatools
  echo "generating signed-target_files.zip"
  ./build/tools/releasetools/sign_target_files_apks -o -d "$self_dir/temp/keys" "$OUT/obj/PACKAGING/target_files_intermediates/"*-target_files-*.zip signed-target_files.zip
  echo "generating signed-ota_update.zip"
  ./build/tools/releasetools/ota_from_target_files -k "$self_dir/temp/keys/releasekey" --block signed-target_files.zip signed-ota_update.zip
  echo "saving build results to directory: $self_dir/output/$target_device"
  build_date=$(date +%Y%m%d_%H%M)
  mv signed-target_files.zip "$self_dir/output/$target_device/target_files_${target_device}_${build_date}.zip"
  mv signed-ota_update.zip "$self_dir/output/$target_device/ota_update_${target_device}_${build_date}.zip"
else
  echo "unknown or unimplemented target: $target"
fi

pushd 1>/dev/null

echo "cleaning up"
rm -rf "$self_dir/temp"

