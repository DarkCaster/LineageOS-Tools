#!/bin/bash

set -e

show_usage() {
  echo "usage: apply_patches.sh <lineage os scrdir> <device>"
  exit 1
}

lineage_srcdir="$1"
[[ -z $lineage_srcdir ]] && show_usage
[[ ! -d $lineage_srcdir ]] && echo "lineage source directory not provided, or not exist" && show_usage

device="$2"
[[ -z $device ]] && show_usage

### settings

fdroid_url="https://f-droid.org/repo/org.fdroid.fdroid.privileged.ota_2110.zip"
fdroid_url_standalone="https://f-droid.org/repo/org.fdroid.fdroid_1007051.apk"
with_fdroid="true"
with_fdroid_priv="false"

### end of settings

self_dir="$(cd "$(dirname "$0")" && pwd)"
scripts_dir="$self_dir/scripts"

#common patches
pushd 1>/dev/null "$lineage_srcdir"
patches_dir="patches/common"
source "$self_dir/quilt_set.sh.in"
[[ -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt push -a
source "$self_dir/quilt_unset.sh.in"
popd 1>/dev/null

#device patches
pushd 1>/dev/null "$lineage_srcdir"
patches_dir="patches/$device"
source "$self_dir/quilt_set.sh.in"
[[ -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt push -a
source "$self_dir/quilt_unset.sh.in"
popd 1>/dev/null


#fdroid patches
if [[ $with_fdroid = true ]]; then
  mkdir -p "$lineage_srcdir/packages/apps/F-Droid"
  [[ $with_fdroid_priv = true ]] && mkdir -p "$lineage_srcdir/packages/apps/F-DroidPrivilegedExtension"

  #patch makefiles to include fdroid into build
  pushd 1>/dev/null "$lineage_srcdir"
  patches_dir="patches/fdroid"
  source "$self_dir/quilt_set.sh.in"
  [[ $with_fdroid_priv = true && -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt push -a
  [[ $with_fdroid_priv != true && -d $QUILT_PATCHES ]] && echo "processing patches from directory $patches_dir" && quilt push 1
  source "$self_dir/quilt_unset.sh.in"
  popd 1>/dev/null

  #download and install fdroid files
  if [[ $with_fdroid_priv = true ]]; then
    rm -rf "$self_dir/temp/workspace"
    "$self_dir/../FDroid_OTA_Packager/scripts/01-download.sh" "$fdroid_url" "$self_dir/temp"
    mv "$self_dir/temp/workspace/F-Droid.apk" "$lineage_srcdir/packages/apps/F-Droid"
    mv "$self_dir/temp/workspace/F-DroidPrivilegedExtension.apk" "$lineage_srcdir/packages/apps/F-DroidPrivilegedExtension"
    mv "$self_dir/temp/workspace/permissions_org.fdroid.fdroid.privileged.xml" "$lineage_srcdir/packages/apps/F-DroidPrivilegedExtension"
  else
    rm -fv "$lineage_srcdir/packages/apps/F-Droid/F-Droid.apk"
    wget -O "$lineage_srcdir/packages/apps/F-Droid/F-Droid.apk" "$fdroid_url_standalone"
  fi
fi
