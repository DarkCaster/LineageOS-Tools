#!/bin/bash
#

set -e

show_usage() {
  echo "usage: build.sh <lineage os srcdir> <device> <target (see below)> [additional parameters for target]"
  exit 1
}

#lineage source directory
__lineage_srcdir="$1"
[[ -z $__lineage_srcdir ]] && show_usage

#device
__target_device="$2"
[[ -z $__target_device ]] && show_usage

#what to build: ota - signed OTA update archive; vendor - populate vendor archive; keys - (re)create sign keys
__target="$3"
[[ -z $__target ]] && show_usage

shift 3

### other settings

__cleanup_srcdir="true"
__skip_patches="false"

### end of settings

[[ ! -d $__lineage_srcdir ]] && echo "lineage source directory is missing :$__lineage_srcdir" && show_usage
[[ $__target = "keys" ]] && __cleanup_srcdir="false"
[[ $__target != "ota" ]] && __skip_patches="true"
[[ $__cleanup_srcdir != true ]] && __skip_patches="true"

self_dir="$(cd "$(dirname "$0")" && pwd)"
scripts_dir="$self_dir/scripts"

clear_srcdir() {
  echo "cleaning up sources directory"
  pushd 1>/dev/null "$__lineage_srcdir"
  for victim in * .*; do
    [[ $victim = "*" || $victim = "." || $victim = ".." || $victim = ".repo" ]] && continue
    rm -rf "$victim"
  done
  popd 1>/dev/null
}

if [[ $__cleanup_srcdir = true ]]; then
  clear_srcdir
  pushd 1>/dev/null "$__lineage_srcdir"
  repo sync -l
  popd 1>/dev/null
fi

export BUILDER_VENDOR_DIR_BASE="vendor"

if [[ -f "$self_dir/patches/$__target_device.sh.in" ]]; then
  echo "sourcing $self_dir/patches/$__target_device.sh.in"
  . "$self_dir/patches/$__target_device.sh.in"
fi
[[ $__skip_patches != true ]] && "$self_dir/apply_patches.sh" "$__lineage_srcdir" "$__target_device"
mkdir -p "$self_dir/output/$__target_device"

pushd 1>/dev/null "$__lineage_srcdir"

check_errors() {
  local status="$?"
  local msg="$@"
  if [[ $status != 0 ]]; then
    echo "ERROR: operation finished with error code $status"
    exit "$status"
  fi
}

echo "running $__target target"
if [[ $__target = "vendor" ]]; then
  vendor="$1"
  [[ -z $vendor ]] && echo "please provide device vendor name as the last parameter" && show_usage
  mnt_dir="$2"
  [[ ! -z $mnt_dir ]] && echo "trying to get vendor files from directory: $mnt_dir"
  echo "preparing build env"
  set +e
  source build/envsetup.sh
  breakfast "$__target_device" || echo "fail was expected at this stage..."
  pushd 1>/dev/null "device/$vendor/$__target_device"
  check_errors
  echo "extracting vendor files"
  if [[ -z $mnt_dir ]]; then
    ./extract-files.sh
    check_errors
  else
    ./extract-files.sh "$mnt_dir"
    check_errors
  fi
  popd 1>/dev/null
  set -e
  echo "creating new vendor-files archive"
  "$self_dir/scripts/create-vendor-files-archive.sh" "$__lineage_srcdir" "$vendor" "$self_dir/private/$__target_device.enc"
elif [[ $__target = "keys" ]]; then
  echo "generating new signing-keys and creating encrypted archive for storing it within repo"
  "$self_dir/scripts/generate-keys.sh" "$__lineage_srcdir" "$self_dir/private/keys.enc"
elif [[ $__target = "ota" ]]; then
  echo "preparing build env"
  set +e
  source build/envsetup.sh
  echo "extracting signing-keys"
  "$self_dir/scripts/extract-archive.sh" "$self_dir/private/keys.enc" "$self_dir/temp"
  check_errors
  echo "extracting vendor files from $__target_device.enc archive to $__lineage_srcdir/$BUILDER_VENDOR_DIR_BASE"
  mkdir -p "$__lineage_srcdir/$BUILDER_VENDOR_DIR_BASE"
  "$self_dir/scripts/extract-archive.sh" "$self_dir/private/$__target_device.enc" "$__lineage_srcdir/$BUILDER_VENDOR_DIR_BASE"
  check_errors
  echo "preparing build"
  breakfast "$__target_device"
  check_errors
  echo "running build"
  mka target-files-package otatools
  check_errors
  echo "generating signed-target_files.zip"
  ./build/tools/releasetools/sign_target_files_apks -o -d "$self_dir/temp/keys" "$OUT/obj/PACKAGING/target_files_intermediates/"*-target_files-*.zip signed-target_files.zip
  check_errors
  echo "generating signed-ota_update.zip"
  ./build/tools/releasetools/ota_from_target_files -k "$self_dir/temp/keys/releasekey" --block signed-target_files.zip signed-ota_update.zip
  check_errors
  set -e
  echo "saving build results to directory: $self_dir/output/$__target_device"
  build_date=$(date +%Y%m%d_%H%M)
  mv signed-target_files.zip "$self_dir/output/$__target_device/target_files_${__target_device}_${build_date}.zip"
  mv signed-ota_update.zip "$self_dir/output/$__target_device/ota_update_${__target_device}_${build_date}.zip"
else
  echo "unknown or unimplemented target: $__target"
fi

pushd 1>/dev/null

echo "cleaning up"
rm -rf "$self_dir/temp"
