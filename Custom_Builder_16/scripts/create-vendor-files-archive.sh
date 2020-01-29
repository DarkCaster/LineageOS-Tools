#!/bin/bash
#

set -e

show_usage() {
  echo "usage: archive-vendor-files.sh <lineage os source dir> <vendor> <archive>"
  exit 1
}

lineage_srcdir="$1"
[[ -z $lineage_srcdir ]] && show_usage

vendor="$2"
[[ -z $vendor ]] && show_usage

target_file="$3"
[[ -z $target_file ]] && show_usage
target_file=$(readlink -f "$target_file")

self_dir="$( cd "$( dirname "$0" )" && pwd )"

rm -fv "$target_file"

echo "Creating archive with vendor files for vendor: $vendor"
"$self_dir/create-archive.sh" "$lineage_srcdir/vendor/$vendor" "$target_file"
